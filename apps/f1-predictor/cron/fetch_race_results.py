#!/usr/bin/env python3
"""
F1 Race Results Fetcher - Cron job (hourly in cluster).
Fetches race results from Jolpica Ergast mirror (same as the web app).
Ergast.com is deprecated; use F1_API_URL (default https://api.jolpi.ca/ergast/f1).
"""

import argparse
import os
import sys
import sqlite3
import requests
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database path (matches the app's config)
DATABASE_PATH = os.environ.get('DATABASE_PATH', '/data/f1_predictions.db')
F1_API_BASE = os.environ.get('F1_API_URL', 'https://api.jolpi.ca/ergast/f1').rstrip('/')
F1_SEASON = int(os.environ.get('F1_SEASON', '2026'))


def get_db():
    """Get database connection."""
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def auto_lock_past_races():
    """Lock races whose start time has passed (same logic as app auto_lock_races)."""
    db = get_db()
    try:
        cur = db.execute('''
            UPDATE races SET status = 'locked'
            WHERE status = 'open' AND datetime(date) < datetime('now')
        ''')
        db.commit()
        if cur.rowcount:
            logger.info(f"Auto-locked {cur.rowcount} race(s) whose start time has passed")
    finally:
        db.close()


def get_locked_races_without_results():
    """Get races that are locked but don't have results yet."""
    db = get_db()
    try:
        races = db.execute('''
            SELECT r.id, r.name, r.round, r.date
            FROM races r
            LEFT JOIN results res ON r.id = res.race_id
            WHERE r.status = 'locked' AND res.race_id IS NULL
            ORDER BY r.date ASC
        ''').fetchall()
        return [dict(race) for race in races]
    finally:
        db.close()


def _driver_display_name(result_row):
    d = result_row.get('Driver') or {}
    given = (d.get('givenName') or '').strip()
    family = (d.get('familyName') or '').strip()
    if given and family:
        return f"{given} {family}"
    return family or given or 'Unknown'


def fetch_race_results_from_api(season, round_num):
    """Fetch race results from Jolpica / Ergast-compatible API."""
    url = f"{F1_API_BASE}/{season}/{round_num}/results.json"
    
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        races = data.get('MRData', {}).get('RaceTable', {}).get('Races', [])
        if not races:
            logger.info(f"No race data available yet for season {season}, round {round_num}")
            return None
        
        race = races[0]
        results = race.get('Results', [])
        
        if len(results) < 3:
            logger.info(f"Race not complete yet - only {len(results)} results available")
            return None
        
        # Extract P1, P2, P3
        podium = {
            'p1': {
                'position': results[0]['position'],
                'driver_name': _driver_display_name(results[0]),
                'driver_code': (results[0].get('Driver') or {}).get('code') or '',
                'constructor': (results[0].get('Constructor') or {}).get('name') or ''
            },
            'p2': {
                'position': results[1]['position'],
                'driver_name': _driver_display_name(results[1]),
                'driver_code': (results[1].get('Driver') or {}).get('code') or '',
                'constructor': (results[1].get('Constructor') or {}).get('name') or ''
            },
            'p3': {
                'position': results[2]['position'],
                'driver_name': _driver_display_name(results[2]),
                'driver_code': (results[2].get('Driver') or {}).get('code') or '',
                'constructor': (results[2].get('Constructor') or {}).get('name') or ''
            }
        }
        
        logger.info(f"Fetched podium: P1={podium['p1']['driver_name']}, "
                   f"P2={podium['p2']['driver_name']}, "
                   f"P3={podium['p3']['driver_name']}")
        return podium
        
    except requests.exceptions.RequestException as e:
        logger.error(f"API request failed: {e}")
        return None
    except (KeyError, IndexError) as e:
        logger.error(f"Unexpected API response format: {e}")
        return None


def get_driver_id_by_name(driver_name):
    """Get driver ID from database by name (fuzzy match)."""
    db = get_db()
    try:
        # Try exact match first
        driver = db.execute(
            'SELECT id FROM drivers WHERE name = ?',
            (driver_name,)
        ).fetchone()
        
        if driver:
            return driver['id']
        
        # Try matching by last name only
        last_name = driver_name.split()[-1]
        driver = db.execute(
            'SELECT id FROM drivers WHERE name LIKE ?',
            (f'%{last_name}%',)
        ).fetchone()
        
        if driver:
            return driver['id']
        
        return None
    finally:
        db.close()


def calculate_score(prediction, result):
    """Calculate score for a prediction against actual results."""
    points = 0
    
    # Exact positions
    if prediction['p1_driver_id'] == result['p1_driver_id']:
        points += 10
    if prediction['p2_driver_id'] == result['p2_driver_id']:
        points += 6
    if prediction['p3_driver_id'] == result['p3_driver_id']:
        points += 4
    
    # Driver in top 3 but wrong position (1 point each)
    pred_drivers = {prediction['p1_driver_id'], prediction['p2_driver_id'], prediction['p3_driver_id']}
    result_drivers = {result['p1_driver_id'], result['p2_driver_id'], result['p3_driver_id']}
    
    for driver_id in pred_drivers:
        if driver_id in result_drivers:
            # Check if exact position was already counted
            is_exact = (
                (driver_id == prediction['p1_driver_id'] and driver_id == result['p1_driver_id']) or
                (driver_id == prediction['p2_driver_id'] and driver_id == result['p2_driver_id']) or
                (driver_id == prediction['p3_driver_id'] and driver_id == result['p3_driver_id'])
            )
            if not is_exact:
                points += 1
    
    return points


def update_race_results(race_id, podium):
    """Update database with race results and calculate scores."""
    db = get_db()
    try:
        # Get driver IDs
        p1_id = get_driver_id_by_name(podium['p1']['driver_name'])
        p2_id = get_driver_id_by_name(podium['p2']['driver_name'])
        p3_id = get_driver_id_by_name(podium['p3']['driver_name'])
        
        if not all([p1_id, p2_id, p3_id]):
            logger.error("Could not match all drivers from API to database")
            return False
        
        # Insert results
        db.execute('''
            INSERT INTO results (race_id, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(race_id) DO UPDATE SET
                p1_driver_id = excluded.p1_driver_id,
                p2_driver_id = excluded.p2_driver_id,
                p3_driver_id = excluded.p3_driver_id
        ''', (race_id, p1_id, p2_id, p3_id))
        
        # Update race status to completed
        db.execute(
            "UPDATE races SET status = 'completed' WHERE id = ?",
            (race_id,)
        )
        
        # Calculate scores for all predictions
        predictions = db.execute(
            'SELECT * FROM predictions WHERE race_id = ?',
            (race_id,)
        ).fetchall()
        
        result_data = {
            'p1_driver_id': p1_id,
            'p2_driver_id': p2_id,
            'p3_driver_id': p3_id
        }
        
        for pred in predictions:
            pred_dict = dict(pred)
            points = calculate_score(pred_dict, result_data)
            
            db.execute('''
                INSERT INTO scores (user_id, race_id, points)
                VALUES (?, ?, ?)
                ON CONFLICT(user_id, race_id) DO UPDATE SET
                    points = excluded.points
            ''', (pred['user_id'], race_id, points))
            
            logger.info(f"User {pred['user_id']} scored {points} points for race {race_id}")
        
        db.commit()
        logger.info(f"Race {race_id} completed and scores calculated")
        return True
        
    except Exception as e:
        logger.error(f"Failed to update race results: {e}")
        db.rollback()
        return False
    finally:
        db.close()


def run_test_api_fetch():
    """Hit the results API (2025 Abu Dhabi) to verify connectivity and parsing."""
    season, rnd = 2025, 24
    logger.info(f"Test fetch: {F1_API_BASE}/{season}/{rnd}/results.json")
    podium = fetch_race_results_from_api(season, rnd)
    if podium:
        logger.info(
            f"OK P1={podium['p1']['driver_name']} P2={podium['p2']['driver_name']} "
            f"P3={podium['p3']['driver_name']}"
        )
        return 0
    logger.error("Test fetch failed or incomplete results")
    return 1


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Fetch F1 race results into predictor DB')
    parser.add_argument(
        '--test-api',
        action='store_true',
        help='Only verify API (2025 R24); no database access',
    )
    args = parser.parse_args()
    if args.test_api:
        sys.exit(run_test_api_fetch())

    logger.info("Starting race results fetcher (API base %s, season %s)", F1_API_BASE, F1_SEASON)

    # Check if database exists
    if not os.path.exists(DATABASE_PATH):
        logger.error(f"Database not found at {DATABASE_PATH}")
        sys.exit(1)

    # Lock past races first so hourly job can fetch even if nobody opened the site
    auto_lock_past_races()

    # Get locked races without results
    races = get_locked_races_without_results()

    if not races:
        logger.info("No locked races awaiting results")
        sys.exit(0)

    season = F1_SEASON

    for race in races:
        logger.info(f"Checking race {race['round']}: {race['name']}")
        
        podium = fetch_race_results_from_api(season, race['round'])
        
        if podium:
            success = update_race_results(race['id'], podium)
            if success:
                logger.info(f"✅ Successfully updated results for {race['name']}")
            else:
                logger.error(f"❌ Failed to update results for {race['name']}")
        else:
            logger.info(f"⏳ Results not available yet for {race['name']}")
    
    logger.info("Race results fetcher completed")


if __name__ == '__main__':
    main()
