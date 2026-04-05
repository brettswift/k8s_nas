#!/usr/bin/env python3
"""
F1 Mock API - Ergast-compatible mock for testing and simulation.
Seeds from real Ergast API on startup if empty.
Admin UI for controlling race state: start times, finish, podium.
"""

import json
import os
import sqlite3
import requests
from datetime import datetime, timezone
from urllib.parse import urljoin

from flask import Flask, g, jsonify, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['DATABASE'] = os.environ.get('DATABASE_PATH', '/data/f1_mock.db')
app.config['ERGAST_BASE'] = os.environ.get('ERGAST_BASE', 'https://api.jolpi.ca/ergast/f1/')
app.config['DEFAULT_SEASON'] = int(os.environ.get('DEFAULT_SEASON', '2024'))
app.config['USE_FIXTURES'] = os.environ.get('USE_FIXTURES', 'false').lower() in ('true', '1', 'yes')

# Placeholder constructor for admin-set podium results (no constructor in drivers API)
PLACEHOLDER_CONSTRUCTOR = {
    "constructorId": "mock",
    "url": "https://en.wikipedia.org/wiki/Formula_1",
    "name": "Mock",
    "nationality": "",
}


def get_db():
    """Get database connection for current request."""
    if 'db' not in g:
        g.db = sqlite3.connect(app.config['DATABASE'])
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(e=None):
    """Close database connection at end of request."""
    db = g.pop('db', None)
    if db is not None:
        db.close()


def init_db():
    """Create database schema."""
    db = get_db()
    db.executescript("""
        CREATE TABLE IF NOT EXISTS seasons (
            season TEXT PRIMARY KEY
        );

        CREATE TABLE IF NOT EXISTS races (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            season TEXT NOT NULL,
            round TEXT NOT NULL,
            race_name TEXT,
            circuit_id TEXT,
            circuit_name TEXT,
            circuit_url TEXT,
            locality TEXT,
            country TEXT,
            lat TEXT,
            long TEXT,
            race_url TEXT,
            date TEXT,
            time TEXT,
            start_override TEXT,
            finish_override TEXT,
            has_results INTEGER DEFAULT 0,
            p1_driver_id TEXT,
            p2_driver_id TEXT,
            p3_driver_id TEXT,
            raw_json TEXT,
            UNIQUE(season, round),
            FOREIGN KEY (season) REFERENCES seasons(season)
        );

        CREATE TABLE IF NOT EXISTS drivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            season TEXT NOT NULL,
            driver_id TEXT NOT NULL,
            permanent_number TEXT,
            code TEXT,
            url TEXT,
            given_name TEXT,
            family_name TEXT,
            date_of_birth TEXT,
            nationality TEXT,
            raw_json TEXT,
            UNIQUE(season, driver_id),
            FOREIGN KEY (season) REFERENCES seasons(season)
        );

        CREATE INDEX IF NOT EXISTS idx_races_season ON races(season);
        CREATE INDEX IF NOT EXISTS idx_drivers_season ON drivers(season);
    """)
    db.commit()


def _fetch_ergast(path: str) -> dict | None:
    """Fetch JSON from Ergast API."""
    url = urljoin(app.config['ERGAST_BASE'], path.lstrip('/'))
    if not path.endswith('.json'):
        url = url.rstrip('/') + '.json'
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        app.logger.warning("Ergast fetch failed %s: %s", url, e)
        return None


def _is_empty() -> bool:
    """Check if database has no races."""
    db = get_db()
    cur = db.execute("SELECT COUNT(*) FROM races")
    return cur.fetchone()[0] == 0


def _seed_season(season: str) -> bool:
    """Seed one season from Ergast API. Returns True on success."""
    # Races
    data = _fetch_ergast(f"/{season}.json")
    if not data:
        return False

    mrd = data.get("MRData", {})
    rt = mrd.get("RaceTable", {})
    races = rt.get("Races", [])

    db = get_db()
    db.execute("INSERT OR IGNORE INTO seasons (season) VALUES (?)", (season,))

    for race in races:
        circuit = race.get("Circuit", {}) or {}
        loc = circuit.get("Location", {}) or {}
        raw = json.dumps(race)
        db.execute("""
            INSERT OR REPLACE INTO races (
                season, round, race_name, circuit_id, circuit_name, circuit_url,
                locality, country, lat, long, race_url, date, time, raw_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            race.get("season", season),
            race.get("round", ""),
            race.get("raceName", ""),
            circuit.get("circuitId", ""),
            circuit.get("circuitName", ""),
            circuit.get("url", ""),
            loc.get("locality", ""),
            loc.get("country", ""),
            loc.get("lat", ""),
            loc.get("long", ""),
            race.get("url", ""),
            race.get("date", ""),
            race.get("time", ""),
            raw,
        ))

    # Drivers
    drv_data = _fetch_ergast(f"/{season}/drivers.json")
    if drv_data:
        dt = drv_data.get("MRData", {}).get("DriverTable", {})
        for d in dt.get("Drivers", []):
            raw = json.dumps(d)
            db.execute("""
                INSERT OR REPLACE INTO drivers (
                    season, driver_id, permanent_number, code, url,
                    given_name, family_name, date_of_birth, nationality, raw_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                season,
                d.get("driverId", ""),
                d.get("permanentNumber", ""),
                d.get("code", ""),
                d.get("url", ""),
                d.get("givenName", ""),
                d.get("familyName", ""),
                d.get("dateOfBirth", ""),
                d.get("nationality", ""),
                raw,
            ))

    db.commit()
    return True


def _seed_fixtures(season: str = "2026"):
    """Seed hardcoded test fixture races into the given season."""
    db = get_db()
    races = [
        {"round": "1", "raceName": "Test Race 1", "circuitId": "albert_park", "circuitName": "Albert Park Circuit", "locality": "Melbourne", "country": "Australia", "date": "2026-04-05", "time": "13:30:00", "start_override": "2026-04-05T13:30:00", "finish_override": "2026-04-05T13:45:00", "p1": "max_verstappen", "p2": "lando_norris", "p3": "george_russell"},
        {"round": "2", "raceName": "Test Race 2", "circuitId": "shanghai", "circuitName": "Shanghai International Circuit", "locality": "Shanghai", "country": "China", "date": "2026-04-05", "time": "14:00:00", "start_override": "2026-04-05T14:00:00", "finish_override": "2026-04-05T14:15:00", "p1": "charles_leclerc", "p2": "oscar_piastri", "p3": "carlos_sainz"},
        {"round": "3", "raceName": "Test Race 3", "circuitId": "suzuka", "circuitName": "Suzuka International Racing Course", "locality": "Suzuka", "country": "Japan", "date": "2026-04-05", "time": "14:30:00", "start_override": "2026-04-05T14:30:00", "finish_override": "2026-04-05T14:45:00", "p1": "lewis_hamilton", "p2": "fernando_alonso", "p3": "lando_norris"},
        {"round": "4", "raceName": "Test Race 4", "circuitId": "bahrain", "circuitName": "Bahrain International Circuit", "locality": "Sakhir", "country": "Bahrain", "date": "2026-04-05", "time": "15:00:00", "start_override": "2026-04-05T15:00:00", "finish_override": "2026-04-05T15:15:00", "p1": "max_verstappen", "p2": "charles_leclerc", "p3": "oscar_piastri"},
    ]
    drivers = {
        "max_verstappen": ("VER", "Max", "Verstappen", "Netherlands"),
        "lando_norris": ("NOR", "Lando", "Norris", "United Kingdom"),
        "george_russell": ("RUS", "George", "Russell", "United Kingdom"),
        "charles_leclerc": ("LEC", "Charles", "Leclerc", "Monaco"),
        "oscar_piastri": ("PIA", "Oscar", "Piastri", "Australia"),
        "carlos_sainz": ("SAI", "Carlos", "Sainz", "Spain"),
        "lewis_hamilton": ("HAM", "Lewis", "Hamilton", "United Kingdom"),
        "fernando_alonso": ("ALO", "Fernando", "Alonso", "Spain"),
    }
    db.execute("INSERT OR IGNORE INTO seasons (season) VALUES (?)", (season,))
    for did, (code, given, family, nat) in drivers.items():
        db.execute("INSERT OR IGNORE INTO drivers (season, driver_id, code, given_name, family_name, nationality) VALUES (?, ?, ?, ?, ?, ?)", (season, did, code, given, family, nat))
    for r in races:
        db.execute("""
            INSERT OR REPLACE INTO races
            (season, round, race_name, circuit_id, circuit_name, locality, country, lat, long, race_url, date, time, start_override, finish_override, has_results, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, '', '', '', ?, ?, ?, ?, 1, ?, ?, ?)
        """, (season, r["round"], r["raceName"], r["circuitId"], r["circuitName"], r["locality"], r["country"], r["date"], r["time"], r["start_override"], r["finish_override"], r["p1"], r["p2"], r["p3"]))
    db.commit()
    app.logger.info("Seeded %d fixture races for season %s", len(races), season)

def seed_if_empty():
    """Seed from Ergast if database is empty, or from fixtures if USE_FIXTURES is set."""
    if _is_empty():
        if app.config['USE_FIXTURES']:
            _seed_fixtures(str(app.config['DEFAULT_SEASON']))
        else:
            season = str(app.config['DEFAULT_SEASON'])
            if _seed_season(season):
                app.logger.info("Seeded season %s from Ergast", season)
            else:
                app.logger.warning("Seed failed for season %s", season)


def _race_to_ergast(race_row, include_results=False):
    """Convert a race row to Ergast Race object. Use raw_json when available for full structure."""
    r = dict(race_row)
    raw = r.get("raw_json")
    if raw:
        try:
            out = json.loads(raw)
            # Override date/time with start_override if set
            if r.get("start_override"):
                try:
                    dt = datetime.fromisoformat(r["start_override"].replace("Z", "+00:00"))
                    out["date"] = dt.strftime("%Y-%m-%d")
                    out["time"] = dt.strftime("%H:%M:%SZ")
                except Exception:
                    pass
        except json.JSONDecodeError:
            out = _race_to_ergast_minimal(r)
    else:
        out = _race_to_ergast_minimal(r)

    if include_results and r.get("has_results"):
        results = _get_results_for_race(r.get("season"), r.get("round"))
        if results:
            out["Results"] = results
    return out


def _race_to_ergast_minimal(r):
    """Build minimal Ergast Race from columns."""
    circuit = {
        "circuitId": r.get("circuit_id") or "",
        "url": r.get("circuit_url") or "",
        "circuitName": r.get("circuit_name") or "",
        "Location": {
            "lat": r.get("lat") or "",
            "long": r.get("long") or "",
            "locality": r.get("locality") or "",
            "country": r.get("country") or "",
        },
    }
    date = r.get("date") or ""
    time_part = r.get("time") or ""
    if r.get("start_override"):
        try:
            dt = datetime.fromisoformat(r["start_override"].replace("Z", "+00:00"))
            date = dt.strftime("%Y-%m-%d")
            time_part = dt.strftime("%H:%M:%SZ")
        except Exception:
            pass
    return {
        "season": r.get("season", ""),
        "round": r.get("round", ""),
        "url": r.get("race_url") or "",
        "raceName": r.get("race_name") or "",
        "Circuit": circuit,
        "date": date,
        "time": time_part,
    }


def _driver_to_ergast(drv_row):
    """Convert a driver row to Ergast Driver object."""
    return {
        "driverId": drv_row.get("driver_id", ""),
        "permanentNumber": drv_row.get("permanent_number") or "",
        "code": drv_row.get("code") or "",
        "url": drv_row.get("url") or "",
        "givenName": drv_row.get("given_name") or "",
        "familyName": drv_row.get("family_name") or "",
        "dateOfBirth": drv_row.get("date_of_birth") or "",
        "nationality": drv_row.get("nationality") or "",
    }


def _get_results_for_race(season, round_no):
    """Build Ergast Results array for a race from podium (p1,p2,p3).
    
    Results are only returned if:
    1. has_results=1 AND
    2. finish_override is null (immediate) OR now >= finish_override
    """
    from datetime import datetime, timezone
    db = get_db()
    race = db.execute(
        "SELECT * FROM races WHERE season = ? AND round = ?",
        (season, round_no),
    ).fetchone()
    if not race or not race["has_results"]:
        return []
    
    # Check finish_override — results delayed until this time
    finish_override = race.get("finish_override")
    if finish_override:
        finish_dt = datetime.fromisoformat(finish_override.replace("Z", "+00:00"))
        if datetime.now(timezone.utc) < finish_dt:
            return []  # Too early, results not yet available

    p1, p2, p3 = race["p1_driver_id"], race["p2_driver_id"], race["p3_driver_id"]
    if not any((p1, p2, p3)):
        return []

    drivers_by_id = {}
    for did in (p1, p2, p3):
        if did:
            cur = db.execute(
                "SELECT * FROM drivers WHERE season = ? AND driver_id = ?",
                (season, did),
            )
            row = cur.fetchone()
            if row:
                drivers_by_id[did] = dict(row)

    points_map = {"1": "26", "2": "18", "3": "15"}
    results = []
    for pos, did in enumerate([p1, p2, p3], 1):
        if not did or did not in drivers_by_id:
            continue
        drv = drivers_by_id[did]
        results.append({
            "number": drv.get("permanent_number") or str(pos),
            "position": str(pos),
            "positionText": str(pos),
            "points": points_map.get(str(pos), "0"),
            "Driver": _driver_to_ergast(drv),
            "Constructor": PLACEHOLDER_CONSTRUCTOR,
            "grid": str(pos),
            "laps": "57",
            "status": "Finished",
            "Time": {"millis": "", "time": f"+{pos}.000"} if pos > 1 else {"millis": "0", "time": "1:30:00.000"},
        })
    return results


# --- API routes (Ergast format) ---

def _mrdata_wrapper(race_table_key: str, content: dict, season: str = "", round_no: str = ""):
    """Wrap content in MRData.RaceTable/DriverTable structure."""
    path_parts = [season]
    if round_no:
        path_parts.append(round_no)
    path = "/".join(path_parts)
    url = urljoin(app.config['ERGAST_BASE'], f"{path}.json") if path else ""
    total = len(content.get("Races", content.get("Drivers", [])))
    return {
        "MRData": {
            "xmlns": "",
            "series": "f1",
            "url": url,
            "limit": "30",
            "offset": "0",
            "total": str(total),
            race_table_key: {"season": season, **content} if season else content,
        },
    }


@app.route("/")
def index():
    """Redirect to API or admin."""
    return redirect(url_for("admin"))


@app.route("/health")
def health():
    """Health check."""
    return jsonify({"status": "ok"})


@app.route("/<season>.json")
def api_season_races(season: str):
    """GET /{season}.json - List all races for season."""
    db = get_db()
    rows = db.execute(
        "SELECT * FROM races WHERE season = ? ORDER BY round",
        (season,),
    ).fetchall()
    races = [_race_to_ergast(dict(r), include_results=False) for r in rows]
    wrap = _mrdata_wrapper("RaceTable", {"Races": races}, season=season)
    return jsonify(wrap)


@app.route("/<season>/drivers.json")
def api_season_drivers(season: str):
    """GET /{season}/drivers.json - List all drivers for season."""
    db = get_db()
    rows = db.execute(
        "SELECT * FROM drivers WHERE season = ? ORDER BY family_name",
        (season,),
    ).fetchall()
    drivers = [_driver_to_ergast(dict(r)) for r in rows]
    wrap = {"MRData": {"DriverTable": {"season": season, "Drivers": drivers}}}
    wrap["MRData"]["xmlns"] = ""
    wrap["MRData"]["series"] = "f1"
    wrap["MRData"]["url"] = urljoin(app.config['ERGAST_BASE'], f"{season}/drivers.json")
    wrap["MRData"]["limit"] = "30"
    wrap["MRData"]["offset"] = "0"
    wrap["MRData"]["total"] = str(len(drivers))
    return jsonify(wrap)


@app.route("/<season>/<round_no>/results.json")
def api_race_results(season: str, round_no: str):
    """GET /{season}/{round}/results.json - Race results (if finished)."""
    db = get_db()
    race = db.execute(
        "SELECT * FROM races WHERE season = ? AND round = ?",
        (season, round_no),
    ).fetchone()
    if not race:
        race_dict = {"season": season, "round": round_no, "Races": []}
    else:
        race_dict = _race_to_ergast(dict(race), include_results=True)
        race_dict = {"season": season, "round": round_no, "Races": [race_dict]}
    wrap = {"MRData": {"RaceTable": race_dict}}
    wrap["MRData"]["xmlns"] = ""
    wrap["MRData"]["series"] = "f1"
    wrap["MRData"]["url"] = urljoin(app.config['ERGAST_BASE'], f"{season}/{round_no}/results.json")
    wrap["MRData"]["limit"] = "30"
    wrap["MRData"]["offset"] = "0"
    wrap["MRData"]["total"] = str(len(race_dict.get("Races", [])))
    return jsonify(wrap)


# --- Admin routes ---

@app.route("/admin")
def admin():
    """Admin UI - list races with controls."""
    db = get_db()
    seasons = [r[0] for r in db.execute("SELECT season FROM seasons ORDER BY season DESC").fetchall()]
    if not seasons:
        seasons = [str(app.config['DEFAULT_SEASON'])]
    season = request.args.get("season", seasons[0])

    races = db.execute(
        "SELECT * FROM races WHERE season = ? ORDER BY round",
        (season,),
    ).fetchall()
    drivers = db.execute(
        "SELECT * FROM drivers WHERE season = ? ORDER BY family_name",
        (season,),
    ).fetchall()

    # Format start_override and finish_override for datetime-local input (YYYY-MM-DDTHH:mm)
    race_list = []
    for r in races:
        d = dict(r)
        for field in ("start_override", "finish_override"):
            val = d.get(field)
            if val:
                try:
                    dt = datetime.fromisoformat(val.replace("Z", "+00:00"))
                    d[field + "_input"] = dt.strftime("%Y-%m-%dT%H:%M")
                except Exception:
                    d[field + "_input"] = val[:16] if len(val) >= 16 else val
            else:
                d[field + "_input"] = ""
        race_list.append(d)

    return render_template(
        "admin.html",
        races=race_list,
        drivers=[dict(d) for d in drivers],
        seasons=seasons,
        current_season=season,
    )


@app.route("/admin/race/<int:race_id>/start", methods=["POST"])
def admin_set_start(race_id: int):
    """Set race start time (datetime)."""
    override = request.form.get("start_override", "").strip()
    db = get_db()
    db.execute("UPDATE races SET start_override = ? WHERE id = ?", (override or None, race_id))
    db.commit()
    flash("Start time updated" if override else "Start time cleared")
    return redirect(url_for("admin", season=request.form.get("season", "")))


@app.route("/admin/race/<int:race_id>/finish", methods=["POST"])
def admin_set_finish(race_id: int):
    """Set race finish time — results only visible after this datetime.
    
    Also sets has_results=1 so f1-predictor knows results are coming.
    """
    override = request.form.get("finish_override", "").strip()
    db = get_db()
    if override:
        db.execute(
            "UPDATE races SET finish_override = ?, has_results = 1 WHERE id = ?",
            (override, race_id),
        )
        flash(f"Finish scheduled: {override}")
    else:
        db.execute("UPDATE races SET finish_override = NULL WHERE id = ?", (race_id,))
        flash("Finish time cleared")
    db.commit()
    return redirect(url_for("admin", season=request.form.get("season", "")))


@app.route("/admin/race/<int:race_id>/finish", methods=["POST"])
def admin_finish_race(race_id: int):
    """Mark race as finished (results endpoint will return data)."""
    db = get_db()
    db.execute("UPDATE races SET has_results = 1 WHERE id = ?", (race_id,))
    db.commit()
    flash("Race marked as finished")
    return redirect(url_for("admin", season=request.form.get("season", "")))


@app.route("/admin/race/<int:race_id>/unfinish", methods=["POST"])
def admin_unfinish_race(race_id: int):
    """Clear results so results endpoint returns no data."""
    db = get_db()
    db.execute(
        "UPDATE races SET has_results = 0, p1_driver_id = NULL, p2_driver_id = NULL, p3_driver_id = NULL WHERE id = ?",
        (race_id,),
    )
    db.commit()
    flash("Race results cleared")
    return redirect(url_for("admin", season=request.form.get("season", "")))


@app.route("/admin/seed-test-races", methods=["POST"])
def admin_seed_test_races():
    """Replace rounds 1-4 of 2026 season with 4 test races on Apr 5 MDT.
    
    Each race: 15-min window. Start → lock → (15 min) → results visible.
    Times (MDT = UTC-6):
      Race 1: 7:30  → 7:45 MDT  (13:30 → 13:45 UTC)
      Race 2: 8:00  → 8:15 MDT  (14:00 → 14:15 UTC)
      Race 3: 8:30  → 8:45 MDT  (14:30 → 14:45 UTC)
      Race 4: 9:00  → 9:15 MDT  (15:00 → 15:15 UTC)
    """
    db = get_db()
    
    races = [
        {
            "round": "1", "race_name": "Test Race 1",
            "circuit_id": "albert_park", "circuit_name": "Albert Park Circuit",
            "locality": "Melbourne", "country": "Australia",
            "date": "2026-04-05", "time": "13:30:00",
            "start_override": "2026-04-05T13:30:00",
            "finish_override": "2026-04-05T13:45:00",
            "p1": "max_verstappen", "p2": "lando_norris", "p3": "george_russell",
        },
        {
            "round": "2", "race_name": "Test Race 2",
            "circuit_id": "shanghai", "circuit_name": "Shanghai International Circuit",
            "locality": "Shanghai", "country": "China",
            "date": "2026-04-05", "time": "14:00:00",
            "start_override": "2026-04-05T14:00:00",
            "finish_override": "2026-04-05T14:15:00",
            "p1": "charles_leclerc", "p2": "oscar_piastri", "p3": "carlos_sainz",
        },
        {
            "round": "3", "race_name": "Test Race 3",
            "circuit_id": "suzuka", "circuit_name": "Suzuka International Racing Course",
            "locality": "Suzuka", "country": "Japan",
            "date": "2026-04-05", "time": "14:30:00",
            "start_override": "2026-04-05T14:30:00",
            "finish_override": "2026-04-05T14:45:00",
            "p1": "lewis_hamilton", "p2": "fernando_alonso", "p3": "lando_norris",
        },
        {
            "round": "4", "race_name": "Test Race 4",
            "circuit_id": "bahrain", "circuit_name": "Bahrain International Circuit",
            "locality": "Sakhir", "country": "Bahrain",
            "date": "2026-04-05", "time": "15:00:00",
            "start_override": "2026-04-05T15:00:00",
            "finish_override": "2026-04-05T15:15:00",
            "p1": "max_verstappen", "p2": "charles_leclerc", "p3": "oscar_piastri",
        },
    ]
    
    # Ensure all needed drivers exist for 2026
    needed_drivers = {
        "max_verstappen": ("VER", "Max", "Verstappen", "Netherlands"),
        "lando_norris": ("NOR", "Lando", "Norris", "United Kingdom"),
        "george_russell": ("RUS", "George", "Russell", "United Kingdom"),
        "charles_leclerc": ("LEC", "Charles", "Leclerc", "Monaco"),
        "oscar_piastri": ("PIA", "Oscar", "Piastri", "Australia"),
        "carlos_sainz": ("SAI", "Carlos", "Sainz", "Spain"),
        "lewis_hamilton": ("HAM", "Lewis", "Hamilton", "United Kingdom"),
        "fernando_alonso": ("ALO", "Fernando", "Alonso", "Spain"),
    }
    for did, (code, given, family, nat) in needed_drivers.items():
        db.execute("""
            INSERT OR IGNORE INTO drivers
            (season, driver_id, code, given_name, family_name, nationality)
            VALUES (?, ?, ?, ?, ?, ?)
        """, ("2026", did, code, given, family, nat))
    
    for r in races:
        db.execute("""
            INSERT OR REPLACE INTO races
            (season, round, race_name, circuit_id, circuit_name,
             locality, country, lat, long, race_url,
             date, time, start_override, finish_override,
             has_results, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, '', '', '', ?, ?, ?, ?, 1, ?, ?, ?)
        """, ("2026", r["round"], r["race_name"], r["circuit_id"], r["circuit_name"],
              r["locality"], r["country"], r["date"], r["time"],
              r["start_override"], r["finish_override"],
              r["p1"], r["p2"], r["p3"]))
    
    db.commit()
    flash("Seeded 4 x 15-min test races for Apr 5 2026 (all MDT)")
    return redirect(url_for("admin", season="2026"))


@app.route("/admin/reseed", methods=["POST"])
def admin_reseed():
    """Clear DB and re-seed from real Ergast API."""
    db = get_db()
    db.execute("DELETE FROM races")
    db.execute("DELETE FROM drivers")
    db.execute("DELETE FROM seasons")
    db.commit()
    season = str(app.config['DEFAULT_SEASON'])
    if _seed_season(season):
        flash(f"Reseeded season {season} from real API")
    else:
        flash("Reseed failed", "error")
    return redirect(url_for("admin", season=season))


@app.route("/admin/seed-test-races", methods=["POST"])
def admin_seed_test_races():
    """Insert 4 test races for today with 15-min race windows.
    
    Sets start_override and finish_override for each.
    Also sets has_results=1 with random podium so results appear after finish.
    """
    db = get_db()
    
    # Clear existing test races (season = 'test')
    db.execute("DELETE FROM races WHERE season = 'test'")
    db.commit()
    
    # 4 races: start at 7:30, 8:00, 8:30, 9:00 MDT (13:00, 14:00, 14:30, 15:00 UTC)
    # Each runs 15 min, results visible after finish
    races = [
        {
            "round": "1", "race_name": "Test Race 1 - Morning Sprint",
            "circuit_name": "Test Circuit A",
            "date": "2026-04-05", "time": "13:30:00",
            "start_override": "2026-04-05T13:30:00",
            "finish_override": "2026-04-05T13:45:00",
            "p1": "max_verstappen", "p2": "lando_norris", "p3": "george_russell",
        },
        {
            "round": "2", "race_name": "Test Race 2 - Mid Morning",
            "circuit_name": "Test Circuit B",
            "date": "2026-04-05", "time": "14:00:00",
            "start_override": "2026-04-05T14:00:00",
            "finish_override": "2026-04-05T14:15:00",
            "p1": "charles_leclerc", "p2": "oscar_piastri", "p3": "carlos_sainz",
        },
        {
            "round": "3", "race_name": "Test Race 3 - Late Morning",
            "circuit_name": "Test Circuit C",
            "date": "2026-04-05", "time": "14:30:00",
            "start_override": "2026-04-05T14:30:00",
            "finish_override": "2026-04-05T14:45:00",
            "p1": "lewis_hamilton", "p2": "fernando_alonso", "p3": "lando_norris",
        },
        {
            "round": "4", "race_name": "Test Race 4 - Before Noon",
            "circuit_name": "Test Circuit D",
            "date": "2026-04-05", "time": "15:00:00",
            "start_override": "2026-04-05T15:00:00",
            "finish_override": "2026-04-05T15:15:00",
            "p1": "max_verstappen", "p2": "charles_leclerc", "p3": "oscar_piastri",
        },
    ]
    
    # Seed season 'test'
    db.execute("INSERT OR IGNORE INTO seasons (season) VALUES ('test')")
    
    # Ensure test drivers exist
    drivers = [
        ("max_verstappen", "VER", "Max", "Verstappen", "Netherlands"),
        ("lando_norris", "NOR", "Lando", "Norris", "United Kingdom"),
        ("george_russell", "RUS", "George", "Russell", "United Kingdom"),
        ("charles_leclerc", "LEC", "Charles", "Leclerc", "Monaco"),
        ("oscar_piastri", "PIA", "Oscar", "Piastri", "Australia"),
        ("carlos_sainz", "SAI", "Carlos", "Sainz", "Spain"),
        ("lewis_hamilton", "HAM", "Lewis", "Hamilton", "United Kingdom"),
        ("fernando_alonso", "ALO", "Fernando", "Alonso", "Spain"),
    ]
    for did, code, given, family, nat in drivers:
        db.execute(
            "INSERT OR IGNORE INTO drivers (season, driver_id, code, given_name, family_name, nationality) VALUES (?, ?, ?, ?, ?, ?)",
            ("test", did, code, given, family, nat)
        )
    
    # Insert races
    for r in races:
        db.execute("""
            INSERT INTO races (season, round, race_name, circuit_name, date, time,
                               start_override, finish_override, has_results,
                               p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
        """, ("test", r["round"], r["race_name"], r["circuit_name"],
              r["date"], r["time"], r["start_override"], r["finish_override"],
              r["p1"], r["p2"], r["p3"]))
    
    db.commit()
    flash(f"Seeded 4 test races for Apr 5, 2026 MDT")
    return redirect(url_for("admin", season="test"))


@app.route("/admin/race/<int:race_id>/podium", methods=["POST"])
def admin_set_podium(race_id: int):
    """Set P1, P2, P3 from driver dropdowns."""
    p1 = request.form.get("p1_driver_id", "").strip() or None
    p2 = request.form.get("p2_driver_id", "").strip() or None
    p3 = request.form.get("p3_driver_id", "").strip() or None
    db = get_db()
    db.execute(
        "UPDATE races SET p1_driver_id = ?, p2_driver_id = ?, p3_driver_id = ? WHERE id = ?",
        (p1, p2, p3, race_id),
    )
    db.commit()
    flash("Podium updated")
    return redirect(url_for("admin", season=request.form.get("season", "")))


# --- Startup ---

with app.app_context():
    init_db()
    seed_if_empty()
