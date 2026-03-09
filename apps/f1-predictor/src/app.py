#!/usr/bin/env python3
"""
F1 Prediction App - A no-signup F1 prediction web app
Users enter a username, pick P1/P2/P3 for each race, and accumulate points.

All data (drivers, races, results) is pulled from the F1 API.
Votes lock when the race starts. Results are user-triggered via a button with browser auto-retry.
"""

import os
import uuid
import sqlite3
import requests
from datetime import datetime, timezone, timedelta

from flask import Flask, render_template, request, redirect, url_for, session, g, flash, jsonify

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['DATABASE'] = os.environ.get('DATABASE_PATH', '/data/f1_predictions.db')

# Environment configuration
app.config['ENVIRONMENT'] = os.environ.get('ENVIRONMENT', 'dev')
app.config['API_BASE_URL'] = os.environ.get('API_BASE_URL', '')
app.config['USE_STUB_API'] = os.environ.get('USE_STUB_API', 'false').lower() == 'true'
app.config['F1_API_URL'] = os.environ.get('F1_API_URL', 'https://api.jolpi.ca/ergast/f1')
app.config['F1_SEASON'] = int(os.environ.get('F1_SEASON', '2026'))
app.config['DRIVER_REFRESH_SECRET'] = os.environ.get('DRIVER_REFRESH_SECRET', '')
RESULTS_CHECK_DELAY_MIN = 90  # Only check races that started 90+ min ago
MAX_RETRIES = 10
RETRY_INTERVAL_SEC = 120

# Context processor to make environment available to all templates
@app.context_processor
def inject_environment():
    return dict(
        environment=app.config['ENVIRONMENT'],
        api_base_url=app.config['API_BASE_URL'],
        use_stub_api=app.config['USE_STUB_API'],
        app_version=os.environ.get('APP_VERSION', ''),
        f1_season=app.config['F1_SEASON']
    )

# Database helpers
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

def _parse_race_datetime(date_str):
    """Parse race date string (YYYY-MM-DD HH:MM:SS or with Z) to timezone-aware UTC datetime."""
    if not date_str:
        return None
    try:
        s = str(date_str).strip().replace('Z', '').strip()[:19]
        dt = datetime.strptime(s, "%Y-%m-%d %H:%M:%S")
        return dt.replace(tzinfo=timezone.utc)
    except (ValueError, TypeError):
        return None

def _now_utc():
    return datetime.now(timezone.utc)

def compute_race_status(race, has_results):
    """
    Compute race status from race start time and results.
    Votes lock the minute the race starts (race_start <= now).
    """
    if has_results:
        return 'completed'
    stored = race.get('status') or ''
    if stored == 'locked':
        return 'locked'
    race_start = _parse_race_datetime(race.get('date', ''))
    if race_start and race_start <= _now_utc():
        return 'locked'
    return 'open'

def enrich_race_with_status(race_dict, has_results):
    """Add computed status to a race dict."""
    r = dict(race_dict)
    r['status'] = compute_race_status(r, has_results)
    return r

def init_db():
    """Initialize database with schema."""
    db = get_db()

    # Users table
    db.execute('''
        CREATE TABLE IF NOT EXISTS users (
            session_id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Drivers table - populated from API
    db.execute('''
        CREATE TABLE IF NOT EXISTS drivers (
            id INTEGER PRIMARY KEY,
            driver_id TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            team TEXT,
            number INTEGER NOT NULL,
            code TEXT,
            nationality TEXT
        )
    ''')

    # Metadata table for tracking refreshes
    db.execute('''
        CREATE TABLE IF NOT EXISTS metadata (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Races table - date is race start (UTC)
    db.execute('''
        CREATE TABLE IF NOT EXISTS races (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            round INTEGER NOT NULL,
            date TIMESTAMP NOT NULL,
            status TEXT DEFAULT 'open' CHECK (status IN ('upcoming', 'open', 'locked', 'completed'))
        )
    ''')

    # Predictions table
    db.execute('''
        CREATE TABLE IF NOT EXISTS predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            race_id INTEGER NOT NULL,
            p1_driver_id INTEGER NOT NULL,
            p2_driver_id INTEGER NOT NULL,
            p3_driver_id INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(session_id),
            FOREIGN KEY (race_id) REFERENCES races(id),
            UNIQUE(user_id, race_id)
        )
    ''')

    # Results table
    db.execute('''
        CREATE TABLE IF NOT EXISTS results (
            race_id INTEGER PRIMARY KEY,
            p1_driver_id INTEGER NOT NULL,
            p2_driver_id INTEGER NOT NULL,
            p3_driver_id INTEGER NOT NULL,
            FOREIGN KEY (race_id) REFERENCES races(id)
        )
    ''')

    # Scores table
    db.execute('''
        CREATE TABLE IF NOT EXISTS scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            race_id INTEGER NOT NULL,
            points INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(session_id),
            FOREIGN KEY (race_id) REFERENCES races(id),
            UNIQUE(user_id, race_id)
        )
    ''')

    db.commit()

    # Lazy load from API on first startup
    ensure_drivers_loaded(db)
    ensure_races_loaded(db)

# --- API fetching ---

def fetch_drivers_from_api():
    """Fetch drivers from F1 API."""
    season = app.config['F1_SEASON']
    api_url = f"{app.config['F1_API_URL']}/{season}/drivers.json"

    try:
        response = requests.get(api_url, timeout=30)
        response.raise_for_status()
        data = response.json()

        drivers = []
        driver_list = data.get('MRData', {}).get('DriverTable', {}).get('Drivers', [])

        for idx, driver in enumerate(driver_list, start=1):
            drivers.append({
                'id': idx,
                'driver_id': driver.get('driverId'),
                'name': f"{driver.get('givenName')} {driver.get('familyName')}",
                'number': int(driver.get('permanentNumber', 0)),
                'code': driver.get('code'),
                'nationality': driver.get('nationality'),
                'team': None
            })

        return drivers
    except Exception as e:
        app.logger.error(f"Failed to fetch drivers from API: {e}")
        return None

def ensure_drivers_loaded(db):
    """Ensure drivers are loaded from API. Called on startup if empty."""
    count = db.execute('SELECT COUNT(*) FROM drivers').fetchone()[0]

    if count == 0:
        app.logger.info("No drivers found - fetching from API...")
        drivers = fetch_drivers_from_api()

        if drivers:
            for driver in drivers:
                db.execute('''
                    INSERT INTO drivers (id, driver_id, name, team, number, code, nationality)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (driver['id'], driver['driver_id'], driver['name'],
                      driver['team'], driver['number'], driver['code'], driver['nationality']))

            db.execute('''
                INSERT INTO metadata (key, value, updated_at)
                VALUES ('drivers_last_refresh', ?, CURRENT_TIMESTAMP)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP
            ''', (datetime.now().isoformat(),))

            db.commit()
            app.logger.info(f"Loaded {len(drivers)} drivers from API")
        else:
            app.logger.error("Failed to load drivers from API - app may not function correctly")

def fetch_races_from_api():
    """Fetch race calendar from F1 API."""
    season = app.config['F1_SEASON']
    api_url = f"{app.config['F1_API_URL']}/{season}.json"

    try:
        response = requests.get(api_url, timeout=30)
        response.raise_for_status()
        data = response.json()

        races = []
        race_list = data.get('MRData', {}).get('RaceTable', {}).get('Races', [])

        for race in race_list:
            race_name = race.get('raceName', 'Unknown')
            round_num = int(race.get('round', 0))
            date = race.get('date', '')
            time = race.get('time', '12:00:00Z').replace('Z', '').strip()

            if date:
                date_str = f"{date} {time}" if time else f"{date} 12:00:00"
                races.append((race_name, round_num, date_str))

        return races
    except Exception as e:
        app.logger.error(f"Failed to fetch races from API: {e}")
        return None

def ensure_races_loaded(db):
    """Ensure races are loaded from API. Called on startup if empty. No fallback."""
    count = db.execute('SELECT COUNT(*) FROM races').fetchone()[0]

    if count > 0:
        return

    app.logger.info("No races found - fetching from API...")
    races = fetch_races_from_api()

    if not races:
        app.logger.error("Failed to fetch races from API - race table will remain empty")
        return

    for name, round_num, date_str in races:
        db.execute(
            'INSERT INTO races (name, round, date, status) VALUES (?, ?, ?, ?)',
            (name, round_num, date_str, 'open')
        )

    db.commit()
    app.logger.info(f"Loaded {len(races)} races from API")

def refresh_drivers_from_api(db):
    """Refresh drivers from API. Called by CronJob."""
    app.logger.info("Refreshing drivers from API...")

    drivers = fetch_drivers_from_api()
    if not drivers:
        return False, "Failed to fetch from API"

    old_drivers = {r['driver_id']: r['id'] for r in db.execute('SELECT driver_id, id FROM drivers').fetchall()}
    id_mapping = {}
    new_id = 1

    for driver in drivers:
        old_id = old_drivers.get(driver['driver_id'])
        if old_id:
            id_mapping[old_id] = new_id
        driver['new_id'] = new_id
        new_id += 1

    db.execute('DELETE FROM drivers')

    for driver in drivers:
        db.execute('''
            INSERT INTO drivers (id, driver_id, name, team, number, code, nationality)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (driver['new_id'], driver['driver_id'], driver['name'],
              driver['team'], driver['number'], driver['code'], driver['nationality']))

    db.execute('''
        INSERT INTO metadata (key, value, updated_at)
        VALUES ('drivers_last_refresh', ?, CURRENT_TIMESTAMP)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP
    ''', (datetime.now().isoformat(),))

    db.commit()
    app.logger.info(f"Refreshed {len(drivers)} drivers")
    return True, f"Refreshed {len(drivers)} drivers"

# --- Results checking (user-triggered with browser auto-retry) ---

def fetch_race_results_from_api(season, round_num):
    """Fetch race results from F1 API. Returns dict with p1/p2/p3 driver_ids or None."""
    api_url = f"{app.config['F1_API_URL']}/{season}/{round_num}/results.json"

    try:
        response = requests.get(api_url, timeout=30)
        response.raise_for_status()
        data = response.json()

        races = data.get('MRData', {}).get('RaceTable', {}).get('Races', [])
        if not races:
            return None

        results = races[0].get('Results', [])
        if len(results) < 3:
            return None

        return {
            'p1_driver_id': results[0]['Driver']['driverId'],
            'p2_driver_id': results[1]['Driver']['driverId'],
            'p3_driver_id': results[2]['Driver']['driverId']
        }
    except Exception:
        return None

def get_driver_db_id_by_api_id(db, api_driver_id):
    """Get our DB driver id from API driverId."""
    row = db.execute('SELECT id FROM drivers WHERE driver_id = ?', (api_driver_id,)).fetchone()
    return row['id'] if row else None

def get_races_pending_results(db, min_minutes_after_start=RESULTS_CHECK_DELAY_MIN):
    """Races that started min_minutes_after_start+ ago, no results in DB."""
    cutoff = _now_utc() - timedelta(minutes=min_minutes_after_start)
    cutoff_str = cutoff.strftime('%Y-%m-%d %H:%M:%S')
    return db.execute('''
        SELECT r.id, r.name, r.round, r.date
        FROM races r
        LEFT JOIN results res ON r.id = res.race_id
        WHERE res.race_id IS NULL AND r.date <= ?
        ORDER BY r.round
    ''', (cutoff_str,)).fetchall()

def check_and_ingest_results(db):
    """
    Check F1 API for races pending results and ingest if available.
    Returns (updated_races, error_message).
    """
    season = app.config['F1_SEASON']
    pending = get_races_pending_results(db)
    updated = []

    for race in pending:
        podium = fetch_race_results_from_api(season, race['round'])
        if not podium:
            continue

        p1_id = get_driver_db_id_by_api_id(db, podium['p1_driver_id'])
        p2_id = get_driver_db_id_by_api_id(db, podium['p2_driver_id'])
        p3_id = get_driver_db_id_by_api_id(db, podium['p3_driver_id'])

        if not all([p1_id, p2_id, p3_id]):
            continue

        db.execute('''
            INSERT INTO results (race_id, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?)
        ''', (race['id'], p1_id, p2_id, p3_id))

        predictions = db.execute('SELECT * FROM predictions WHERE race_id = ?', (race['id'],)).fetchall()
        result_data = {'p1_driver_id': p1_id, 'p2_driver_id': p2_id, 'p3_driver_id': p3_id}

        for pred in predictions:
            points = calculate_score(dict(pred), result_data)
            db.execute('''
                INSERT INTO scores (user_id, race_id, points)
                VALUES (?, ?, ?)
                ON CONFLICT(user_id, race_id) DO UPDATE SET points = excluded.points
            ''', (pred['user_id'], race['id'], points))

        updated.append(race['name'])

    if updated:
        db.commit()

    return updated, None

def has_races_pending_results(db):
    """True if any race is eligible for results check (started 90+ min ago, no results)."""
    return len(get_races_pending_results(db)) > 0

def get_current_user():
    """Get current user from session."""
    session_id = session.get('session_id')
    if not session_id:
        return None

    db = get_db()
    user = db.execute(
        'SELECT * FROM users WHERE session_id = ?', (session_id,)
    ).fetchone()
    return user

def calculate_score(prediction, result):
    """Calculate score for a prediction."""
    points = 0

    if prediction['p1_driver_id'] == result['p1_driver_id']:
        points += 10
    if prediction['p2_driver_id'] == result['p2_driver_id']:
        points += 6
    if prediction['p3_driver_id'] == result['p3_driver_id']:
        points += 4

    predicted_drivers = {prediction['p1_driver_id'], prediction['p2_driver_id'], prediction['p3_driver_id']}
    result_drivers = {result['p1_driver_id'], result['p2_driver_id'], result['p3_driver_id']}

    for driver_id in predicted_drivers:
        if driver_id in result_drivers:
            exact = (
                (driver_id == prediction['p1_driver_id'] and driver_id == result['p1_driver_id']) or
                (driver_id == prediction['p2_driver_id'] and driver_id == result['p2_driver_id']) or
                (driver_id == prediction['p3_driver_id'] and driver_id == result['p3_driver_id'])
            )
            if not exact:
                points += 1

    return points

def get_races_with_computed_status(db):
    """Fetch all races and enrich with computed status."""
    races = db.execute('''
        SELECT r.*, res.p1_driver_id, res.p2_driver_id, res.p3_driver_id,
               d1.name as p1_name, d2.name as p2_name, d3.name as p3_name
        FROM races r
        LEFT JOIN results res ON r.id = res.race_id
        LEFT JOIN drivers d1 ON res.p1_driver_id = d1.id
        LEFT JOIN drivers d2 ON res.p2_driver_id = d2.id
        LEFT JOIN drivers d3 ON res.p3_driver_id = d3.id
        ORDER BY r.round
    ''').fetchall()

    return [enrich_race_with_status(dict(r), r['p1_driver_id'] is not None) for r in races]

def get_next_open_race(db):
    """Get the next race that is open for predictions (future, no results)."""
    races = get_races_with_computed_status(db)
    for r in races:
        if r['status'] == 'open':
            return r
    return None

# --- Routes ---

@app.route('/')
def index():
    """Landing page - redirect to home if logged in, else show username form."""
    user = get_current_user()
    if user:
        return redirect(url_for('home'))
    return render_template('index.html')

@app.route('/set-username', methods=['POST'])
def set_username():
    """Set username and create session."""
    username = request.form.get('username', '').strip()
    if not username:
        flash('Please enter a username', 'error')
        return redirect(url_for('index'))

    session_id = str(uuid.uuid4())
    db = get_db()
    db.execute(
        'INSERT INTO users (session_id, username) VALUES (?, ?)',
        (session_id, username)
    )
    db.commit()

    session['session_id'] = session_id
    return redirect(url_for('home'))

@app.route('/home')
def home():
    """Home page showing upcoming race and user's predictions."""
    user = get_current_user()
    if not user:
        return redirect(url_for('index'))

    db = get_db()
    next_race = get_next_open_race(db)
    if not next_race:
        races = get_races_with_computed_status(db)
        next_race = races[0] if races else None
        if next_race and next_race['status'] != 'open':
            next_race = next((r for r in races if r['status'] in ('open', 'locked')), next_race)

    user_prediction = None
    if next_race:
        try:
            user_prediction = db.execute('''
                SELECT p.*, d1.name as p1_name, d2.name as p2_name, d3.name as p3_name
                FROM predictions p
                JOIN drivers d1 ON p.p1_driver_id = d1.id
                JOIN drivers d2 ON p.p2_driver_id = d2.id
                JOIN drivers d3 ON p.p3_driver_id = d3.id
                WHERE p.user_id = ? AND p.race_id = ?
            ''', (user['session_id'], next_race['id'])).fetchone()
        except Exception:
            user_prediction = None

    total_score = db.execute(
        'SELECT COALESCE(SUM(points), 0) as total FROM scores WHERE user_id = ?',
        (user['session_id'],)
    ).fetchone()['total']

    has_pending = has_races_pending_results(db)

    return render_template('home.html',
                          user=user,
                          next_race=next_race,
                          user_prediction=user_prediction,
                          total_score=total_score,
                          has_pending_results=has_pending)

@app.route('/predict/<int:race_id>', methods=['GET', 'POST'])
def predict(race_id):
    """Make or update prediction for a race. Rejects if race has started."""
    user = get_current_user()
    if not user:
        return redirect(url_for('index'))

    db = get_db()
    race_row = db.execute('SELECT * FROM races WHERE id = ?', (race_id,)).fetchone()
    if not race_row:
        flash('Race not found', 'error')
        return redirect(url_for('home'))

    has_results = db.execute('SELECT 1 FROM results WHERE race_id = ?', (race_id,)).fetchone() is not None
    race = enrich_race_with_status(dict(race_row), has_results)

    if race['status'] == 'locked':
        flash('Predictions are locked - the race has started.', 'error')
        return redirect(url_for('home'))

    if race['status'] == 'completed':
        flash('This race has already been completed.', 'error')
        return redirect(url_for('home'))

    drivers = db.execute('SELECT * FROM drivers ORDER BY name').fetchall()

    if request.method == 'POST':
        p1 = request.form.get('p1')
        p2 = request.form.get('p2')
        p3 = request.form.get('p3')

        if not all([p1, p2, p3]):
            flash('Please select all three positions', 'error')
            return redirect(url_for('predict', race_id=race_id))

        if len(set([p1, p2, p3])) != 3:
            flash('Please select three different drivers', 'error')
            return redirect(url_for('predict', race_id=race_id))

        db.execute('''
            INSERT INTO predictions (user_id, race_id, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(user_id, race_id) DO UPDATE SET
                p1_driver_id = excluded.p1_driver_id,
                p2_driver_id = excluded.p2_driver_id,
                p3_driver_id = excluded.p3_driver_id,
                created_at = CURRENT_TIMESTAMP
        ''', (user['session_id'], race_id, p1, p2, p3))
        db.commit()

        flash('Prediction saved!', 'success')
        return redirect(url_for('home'))

    existing = db.execute('''
        SELECT p1_driver_id, p2_driver_id, p3_driver_id
        FROM predictions WHERE user_id = ? AND race_id = ?
    ''', (user['session_id'], race_id)).fetchone()

    return render_template('predict.html', race=race, drivers=drivers, existing=existing)

@app.route('/leaderboard')
def leaderboard():
    """Show leaderboard with all users and their scores."""
    user = get_current_user()
    if not user:
        return redirect(url_for('index'))

    db = get_db()
    users = db.execute('''
        SELECT u.*, COALESCE(SUM(s.points), 0) as total_score
        FROM users u
        LEFT JOIN scores s ON u.session_id = s.user_id
        GROUP BY u.session_id
        ORDER BY total_score DESC
    ''').fetchall()

    races = get_races_with_computed_status(db)
    score_matrix = {}
    for u in users:
        score_matrix[u['session_id']] = {}
        for race in races:
            score = db.execute(
                'SELECT points FROM scores WHERE user_id = ? AND race_id = ?',
                (u['session_id'], race['id'])
            ).fetchone()
            score_matrix[u['session_id']][race['id']] = score['points'] if score else '-'

    return render_template('leaderboard.html',
                          users=users,
                          races=races,
                          score_matrix=score_matrix,
                          current_user=user)

@app.route('/races')
def races():
    """Show all races and their status."""
    user = get_current_user()
    if not user:
        return redirect(url_for('index'))

    db = get_db()
    all_races = get_races_with_computed_status(db)

    predictions = {}
    for race in all_races:
        pred = db.execute('''
            SELECT p.*, d1.name as p1_name, d2.name as p2_name, d3.name as p3_name
            FROM predictions p
            JOIN drivers d1 ON p.p1_driver_id = d1.id
            JOIN drivers d2 ON p.p2_driver_id = d2.id
            JOIN drivers d3 ON p.p3_driver_id = d3.id
            WHERE p.user_id = ? AND p.race_id = ?
        ''', (user['session_id'], race['id'])).fetchone()
        if pred:
            predictions[race['id']] = pred

    has_pending = has_races_pending_results(db)

    return render_template('races.html',
                          races=all_races,
                          predictions=predictions,
                          has_pending_results=has_pending)

@app.route('/logout')
def logout():
    """Clear session."""
    session.clear()
    return redirect(url_for('index'))

# Admin routes
@app.route('/admin/enter-results/<int:race_id>', methods=['GET', 'POST'])
def enter_results(race_id):
    """Enter actual race results manually (admin). API polling may have already updated."""
    db = get_db()

    race_row = db.execute('SELECT * FROM races WHERE id = ?', (race_id,)).fetchone()
    if not race_row:
        flash('Race not found', 'error')
        return redirect(url_for('races'))

    has_results = db.execute('SELECT 1 FROM results WHERE race_id = ?', (race_id,)).fetchone() is not None
    race = enrich_race_with_status(dict(race_row), has_results)
    drivers = db.execute('SELECT * FROM drivers ORDER BY name').fetchall()

    if request.method == 'POST':
        p1 = request.form.get('p1')
        p2 = request.form.get('p2')
        p3 = request.form.get('p3')

        if not all([p1, p2, p3]):
            flash('Please select all three positions', 'error')
            return redirect(url_for('enter_results', race_id=race_id))

        db.execute('''
            INSERT INTO results (race_id, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(race_id) DO UPDATE SET
                p1_driver_id = excluded.p1_driver_id,
                p2_driver_id = excluded.p2_driver_id,
                p3_driver_id = excluded.p3_driver_id
        ''', (race_id, p1, p2, p3))

        predictions = db.execute('SELECT * FROM predictions WHERE race_id = ?', (race_id,)).fetchall()
        result = {'p1_driver_id': p1, 'p2_driver_id': p2, 'p3_driver_id': p3}

        for pred in predictions:
            points = calculate_score(pred, result)
            db.execute('''
                INSERT INTO scores (user_id, race_id, points)
                VALUES (?, ?, ?)
                ON CONFLICT(user_id, race_id) DO UPDATE SET points = excluded.points
            ''', (pred['user_id'], race_id, points))

        db.commit()
        flash('Results entered and scores calculated!', 'success')
        return redirect(url_for('races'))

    return render_template('enter_results.html', race=race, drivers=drivers)

@app.route('/admin/refresh-drivers', methods=['POST'])
def refresh_drivers():
    """Refresh drivers from API - called by CronJob."""
    auth_header = request.headers.get('Authorization', '')
    expected = f"Bearer {app.config['DRIVER_REFRESH_SECRET']}"

    if auth_header != expected and app.config['DRIVER_REFRESH_SECRET']:
        return jsonify({'error': 'Unauthorized'}), 401

    db = get_db()
    success, message = refresh_drivers_from_api(db)

    if success:
        return jsonify({'status': 'success', 'message': message}), 200
    return jsonify({'status': 'error', 'message': message}), 500

@app.route('/admin/drivers-status')
def drivers_status():
    """Get driver refresh status."""
    db = get_db()

    count = db.execute('SELECT COUNT(*) FROM drivers').fetchone()[0]
    last_refresh = db.execute(
        'SELECT value FROM metadata WHERE key = "drivers_last_refresh"'
    ).fetchone()

    return jsonify({
        'driver_count': count,
        'last_refresh': last_refresh['value'] if last_refresh else None
    })

@app.route('/check-results', methods=['GET', 'POST'])
def check_results():
    """
    Check F1 API for race results and ingest. User-triggered with browser auto-retry.
    Retry param: 0-10, triggers auto-refresh when no results (max 10 retries = ~20 min).
    """
    user = get_current_user()
    if not user:
        return redirect(url_for('index'))

    db = get_db()
    retry = int(request.args.get('retry', 0))

    updated, _ = check_and_ingest_results(db)

    if updated:
        flash(f"Results updated for: {', '.join(updated)}", 'success')
        return redirect(url_for('leaderboard'))

    pending = get_races_pending_results(db)
    if not pending:
        return render_template('check_results.html', status='none', retry=retry)

    if retry >= MAX_RETRIES:
        return render_template(
            'check_results.html',
            status='exhausted',
            retry=retry,
            max_retries=MAX_RETRIES
        )

    return render_template(
        'check_results.html',
        status='retry',
        retry=retry,
        next_retry=retry + 1,
        max_retries=MAX_RETRIES,
        retry_interval_sec=RETRY_INTERVAL_SEC,
        pending_races=[r['name'] for r in pending]
    )

@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({'status': 'healthy'})

# Initialize database on startup
with app.app_context():
    init_db()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
