#!/usr/bin/env python3
"""
F1 Race Manager — state-machine cron for race-weekend automation.

Run via K8s CronJob every 5 min on Fri/Sat/Sun/Mon.
When no races are active the script exits in < 1 s.

Stages per race (tracked in the race_stages table):

    (no entry) → watching   race is open and starts within 12 h
    watching   → locked     race start ≤ 6 min away (or already past)
    locked     → polling    1 h 30 min since lock
    polling    → completed  API returns full podium → scores calculated

Between race weekends nothing is active, so the script does two quick
DB queries and exits.
"""

import argparse
import os
import sys
import sqlite3
import requests
import logging
from datetime import datetime, timezone, timedelta

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
logger = logging.getLogger('race_manager')

DATABASE_PATH = os.environ.get('DATABASE_PATH', '/data/f1_predictions.db')
F1_API_BASE = os.environ.get('F1_API_URL', 'https://api.jolpi.ca/ergast/f1').rstrip('/')
F1_SEASON = int(os.environ.get('F1_SEASON', '2026'))

WATCH_WINDOW = timedelta(hours=12)
LOCK_LEAD = timedelta(minutes=6)
POLL_DELAY = timedelta(hours=1, minutes=30)
POLL_INTERVAL = timedelta(minutes=5)
MAX_POLL_DURATION = timedelta(hours=6)

ISO_FMT = '%Y-%m-%dT%H:%M:%SZ'


# ── helpers ─────────────────────────────────────────────────────────

def get_db():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _utcnow():
    return datetime.now(timezone.utc)


def _parse_dt(s):
    if not s:
        return None
    s = s.strip().replace('Z', '')
    for fmt in ('%Y-%m-%d %H:%M:%S', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d'):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def _now_iso(now):
    return now.strftime(ISO_FMT)


def ensure_stage_table(db):
    db.execute('''
        CREATE TABLE IF NOT EXISTS race_stages (
            race_id      INTEGER PRIMARY KEY,
            stage        TEXT    NOT NULL
                         CHECK (stage IN ('watching','locked','polling','completed')),
            entered_at   TEXT    NOT NULL,
            last_poll_at TEXT,
            poll_count   INTEGER DEFAULT 0,
            FOREIGN KEY (race_id) REFERENCES races(id)
        )
    ''')
    db.commit()


# ── (no entry) → watching ──────────────────────────────────────────

def promote_to_watching(db, now):
    """Detect open races starting within WATCH_WINDOW."""
    cutoff = now + WATCH_WINDOW
    rows = db.execute('''
        SELECT r.id, r.name, r.date
        FROM races r
        LEFT JOIN race_stages rs ON r.id = rs.race_id
        WHERE r.status = 'open' AND rs.race_id IS NULL
        ORDER BY r.date
    ''').fetchall()
    for r in rows:
        race_dt = _parse_dt(r['date'])
        if race_dt and race_dt <= cutoff:
            db.execute(
                'INSERT OR IGNORE INTO race_stages (race_id, stage, entered_at) VALUES (?, ?, ?)',
                (r['id'], 'watching', _now_iso(now)),
            )
            logger.info("→ watching  %s (starts %s)", r['name'], r['date'])
    db.commit()


# ── watching → locked ───────────────────────────────────────────────

def promote_to_locked(db, now):
    """Lock voting when race start is ≤ LOCK_LEAD away (or already past)."""
    rows = db.execute('''
        SELECT rs.race_id, r.name, r.date
        FROM race_stages rs
        JOIN races r ON r.id = rs.race_id
        WHERE rs.stage = 'watching'
    ''').fetchall()
    for r in rows:
        race_dt = _parse_dt(r['date'])
        if not race_dt:
            continue
        if race_dt - LOCK_LEAD <= now:
            db.execute(
                "UPDATE races SET status = 'locked' WHERE id = ? AND status = 'open'",
                (r['race_id'],),
            )
            db.execute(
                "UPDATE race_stages SET stage = 'locked', entered_at = ? WHERE race_id = ?",
                (_now_iso(now), r['race_id']),
            )
            logger.info("→ locked    %s (started %s)", r['name'], r['date'])
    db.commit()


# ── locked → polling ────────────────────────────────────────────────

def promote_to_polling(db, now):
    """Begin polling once POLL_DELAY has elapsed since lock."""
    rows = db.execute('''
        SELECT rs.race_id, r.name, rs.entered_at
        FROM race_stages rs
        JOIN races r ON r.id = rs.race_id
        WHERE rs.stage = 'locked'
    ''').fetchall()
    for r in rows:
        locked_at = _parse_dt(r['entered_at'])
        if locked_at and now >= locked_at + POLL_DELAY:
            db.execute('''
                UPDATE race_stages
                SET stage = 'polling', entered_at = ?, last_poll_at = NULL, poll_count = 0
                WHERE race_id = ?
            ''', (_now_iso(now), r['race_id']))
            logger.info("→ polling   %s (locked at %s)", r['name'], r['entered_at'])
    db.commit()


# ── polling → completed ────────────────────────────────────────────

def _driver_display_name(result_row):
    d = result_row.get('Driver') or {}
    given = (d.get('givenName') or '').strip()
    family = (d.get('familyName') or '').strip()
    return f"{given} {family}".strip() or 'Unknown'


def _fetch_podium(season, round_num):
    url = f"{F1_API_BASE}/{season}/{round_num}/results.json"
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        races = resp.json().get('MRData', {}).get('RaceTable', {}).get('Races', [])
        if not races:
            return None
        results = races[0].get('Results', [])
        if len(results) < 3:
            return None
        podium = {}
        for i, key in enumerate(('p1', 'p2', 'p3')):
            podium[key] = {
                'driver_name': _driver_display_name(results[i]),
                'driver_code': (results[i].get('Driver') or {}).get('code', ''),
                'constructor': (results[i].get('Constructor') or {}).get('name', ''),
            }
        return podium
    except Exception as e:
        logger.error("API error round %s: %s", round_num, e)
        return None


def _get_driver_id(db, name):
    row = db.execute('SELECT id FROM drivers WHERE name = ?', (name,)).fetchone()
    if row:
        return row['id']
    last = name.split()[-1]
    row = db.execute('SELECT id FROM drivers WHERE name LIKE ?', (f'%{last}%',)).fetchone()
    return row['id'] if row else None


def _calculate_score(pred, res):
    pts = 0
    if pred['p1_driver_id'] == res['p1_driver_id']:
        pts += 10
    if pred['p2_driver_id'] == res['p2_driver_id']:
        pts += 6
    if pred['p3_driver_id'] == res['p3_driver_id']:
        pts += 4
    pred_set = {pred['p1_driver_id'], pred['p2_driver_id'], pred['p3_driver_id']}
    res_set = {res['p1_driver_id'], res['p2_driver_id'], res['p3_driver_id']}
    for did in pred_set & res_set:
        exact = (
            (did == pred['p1_driver_id'] and did == res['p1_driver_id'])
            or (did == pred['p2_driver_id'] and did == res['p2_driver_id'])
            or (did == pred['p3_driver_id'] and did == res['p3_driver_id'])
        )
        if not exact:
            pts += 1
    return pts


def _save_results_and_score(db, race_id, podium):
    p1 = _get_driver_id(db, podium['p1']['driver_name'])
    p2 = _get_driver_id(db, podium['p2']['driver_name'])
    p3 = _get_driver_id(db, podium['p3']['driver_name'])
    if not all((p1, p2, p3)):
        logger.error("Could not resolve all podium drivers for race %d", race_id)
        return False

    db.execute('''
        INSERT INTO results (race_id, p1_driver_id, p2_driver_id, p3_driver_id)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(race_id) DO UPDATE SET
            p1_driver_id = excluded.p1_driver_id,
            p2_driver_id = excluded.p2_driver_id,
            p3_driver_id = excluded.p3_driver_id
    ''', (race_id, p1, p2, p3))

    db.execute("UPDATE races SET status = 'completed' WHERE id = ?", (race_id,))

    res = {'p1_driver_id': p1, 'p2_driver_id': p2, 'p3_driver_id': p3}
    for pred in db.execute('SELECT * FROM predictions WHERE race_id = ?', (race_id,)).fetchall():
        pts = _calculate_score(dict(pred), res)
        db.execute('''
            INSERT INTO scores (user_id, race_id, points) VALUES (?, ?, ?)
            ON CONFLICT(user_id, race_id) DO UPDATE SET points = excluded.points
        ''', (pred['user_id'], race_id, pts))
        logger.info("  user %s → %d pts", pred['user_id'][:8], pts)

    db.commit()
    return True


def poll_for_results(db, now):
    rows = db.execute('''
        SELECT rs.race_id, rs.entered_at, rs.last_poll_at, rs.poll_count,
               r.name, r.round
        FROM race_stages rs
        JOIN races r ON r.id = rs.race_id
        WHERE rs.stage = 'polling'
    ''').fetchall()

    for r in rows:
        started = _parse_dt(r['entered_at'])
        if started and now > started + MAX_POLL_DURATION:
            logger.warning("max poll time exceeded for %s — giving up", r['name'])
            db.execute(
                "UPDATE race_stages SET stage = 'completed', entered_at = ? WHERE race_id = ?",
                (_now_iso(now), r['race_id']),
            )
            db.commit()
            continue

        last = _parse_dt(r['last_poll_at'])
        if last and now < last + POLL_INTERVAL:
            continue

        logger.info("poll #%d   %s (round %d)", r['poll_count'] + 1, r['name'], r['round'])
        podium = _fetch_podium(F1_SEASON, r['round'])

        if podium:
            ok = _save_results_and_score(db, r['race_id'], podium)
            if ok:
                db.execute('''
                    UPDATE race_stages
                    SET stage = 'completed', entered_at = ?, last_poll_at = ?, poll_count = poll_count + 1
                    WHERE race_id = ?
                ''', (_now_iso(now), _now_iso(now), r['race_id']))
                logger.info("→ completed %s", r['name'])
        else:
            db.execute('''
                UPDATE race_stages SET last_poll_at = ?, poll_count = poll_count + 1
                WHERE race_id = ?
            ''', (_now_iso(now), r['race_id']))
            logger.info("  no results yet for %s", r['name'])
        db.commit()


# ── status command ──────────────────────────────────────────────────

def show_status(db):
    ensure_stage_table(db)
    rows = db.execute('''
        SELECT rs.*, r.name, r.round, r.date, r.status AS race_status
        FROM race_stages rs
        JOIN races r ON r.id = rs.race_id
        ORDER BY r.date
    ''').fetchall()
    if not rows:
        print("No race stages tracked yet.")
        return
    for r in rows:
        print(f"  round {r['round']:>2}  {r['name']:<30}  stage={r['stage']:<10}  "
              f"entered={r['entered_at']}  polls={r['poll_count']}")


# ── main ────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='F1 race weekend state machine')
    parser.add_argument('--status', action='store_true', help='Show current race stages')
    parser.add_argument('--test-api', action='store_true',
                        help='Smoke-test the results API (2025 R24)')
    args = parser.parse_args()

    if args.test_api:
        podium = _fetch_podium(2025, 24)
        if podium:
            logger.info(
                "OK P1=%s P2=%s P3=%s",
                podium['p1']['driver_name'],
                podium['p2']['driver_name'],
                podium['p3']['driver_name'],
            )
            sys.exit(0)
        logger.error("Test fetch failed")
        sys.exit(1)

    if not os.path.exists(DATABASE_PATH):
        logger.error("DB not found at %s", DATABASE_PATH)
        sys.exit(1)

    db = get_db()
    ensure_stage_table(db)

    if args.status:
        show_status(db)
        db.close()
        return

    now = _utcnow()

    promote_to_watching(db, now)
    promote_to_locked(db, now)
    promote_to_polling(db, now)
    poll_for_results(db, now)

    db.close()


if __name__ == '__main__':
    main()
