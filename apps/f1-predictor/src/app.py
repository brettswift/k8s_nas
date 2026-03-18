#!/usr/bin/env python3
"""
F1 Prediction App - A no-signup F1 prediction web app
Users enter a username, pick P1/P2/P3 for each race, and accumulate points.

Drivers are loaded from Jolpica F1 API (https://api.jolpi.ca/ergast/f1/)
and refreshed weekly via CronJob.
"""

import os
import uuid
import sqlite3
import requests
from datetime import datetime, timedelta
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, session, g, flash, jsonify

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['DATABASE'] = os.environ.get('DATABASE_PATH', '/data/f1_predictions.db')

# Environment configuration
app.config['ENVIRONMENT'] = os.environ.get('ENVIRONMENT', 'dev')
app.config['API_BASE_URL'] = os.environ.get('API_BASE_URL', '')
app.config['USE_STUB_API'] = os.environ.get('USE_STUB_API', 'false').lower() == 'true'
app.config['F1_API_URL'] = os.environ.get('F1_API_URL', 'https://api.jolpi.ca/ergast/f1')
app.config['DRIVER_REFRESH_SECRET'] = os.environ.get('DRIVER_REFRESH_SECRET', '')

def auto_lock_races():
    """Set status to 'locked' for races that have started (open + date in past)."""
    try:
        db = get_db()
        db.execute('''
            UPDATE races SET status = 'locked'
            WHERE status = 'open' AND datetime(date) < datetime('now')
        ''')
        db.commit()
    except Exception as e:
        app.logger.warning(f"auto_lock_races: {e}")


# Context processor to make environment available to all templates
@app.context_processor
def inject_environment():
    return dict(
        environment=app.config['ENVIRONMENT'],
        api_base_url=app.config['API_BASE_URL'],
        use_stub_api=app.config['USE_STUB_API'],
        app_version=os.environ.get('APP_VERSION', '')
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
    
    # Drivers table - populated from API, not hardcoded
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
    
    # Races table
    db.execute('''
        CREATE TABLE IF NOT EXISTS races (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            round INTEGER NOT NULL,
            date TIMESTAMP NOT NULL,
            status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'open', 'locked', 'completed'))
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
    
    # Lazy load drivers from API on first startup
    ensure_drivers_loaded(db)
    seed_races_2026(db)

def fetch_drivers_from_api():
    """Fetch 2026 drivers from Jolpica F1 API."""
    api_url = f"{app.config['F1_API_URL']}/2026/drivers.json"
    
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
                'team': None  # API doesn't provide team in this endpoint
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

def refresh_drivers_from_api(db):
    """Refresh drivers from API. Called by CronJob."""
    app.logger.info("Refreshing drivers from API...")
    
    drivers = fetch_drivers_from_api()
    if not drivers:
        return False, "Failed to fetch from API"
    
    # Store old driver IDs for reference integrity
    old_drivers = {d['driver_id']: d['id'] for d in 
                   db.execute('SELECT driver_id, id FROM drivers').fetchall()}
    
    # Build mapping from old to new IDs
    id_mapping = {}
    new_id = 1
    
    for driver in drivers:
        old_id = old_drivers.get(driver['driver_id'])
        if old_id:
            id_mapping[old_id] = new_id
        driver['new_id'] = new_id
        new_id += 1
    
    # Clear and reload drivers
    db.execute('DELETE FROM drivers')
    
    for driver in drivers:
        db.execute('''
            INSERT INTO drivers (id, driver_id, name, team, number, code, nationality)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (driver['new_id'], driver['driver_id'], driver['name'],
              driver['team'], driver['number'], driver['code'], driver['nationality']))
    
    # Update metadata
    db.execute('''
        INSERT INTO metadata (key, value, updated_at)
        VALUES ('drivers_last_refresh', ?, CURRENT_TIMESTAMP)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP
    ''', (datetime.now().isoformat(),))
    
    db.commit()
    
    app.logger.info(f"Refreshed {len(drivers)} drivers")
    return True, f"Refreshed {len(drivers)} drivers"

def seed_races_2026(db):
    """Seed 2026 F1 race calendar from API or fallback."""
    # Check if races already exist
    count = db.execute('SELECT COUNT(*) FROM races').fetchone()[0]
    if count > 0:
        return
    
    # Try to fetch from API first
    races = fetch_races_from_api()
    if not races:
        # Fallback to hardcoded 2026 schedule
        races = get_fallback_races_2026()
    
    for name, round_num, date_str in races:
        try:
            race_date = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
            # Set status based on date relative to now
            if race_date > datetime.now() + timedelta(hours=1):
                status = 'open'
            elif race_date > datetime.now():
                status = 'locked'
            else:
                status = 'completed'
        except:
            status = 'upcoming'
        
        db.execute(
            'INSERT INTO races (name, round, date, status) VALUES (?, ?, ?, ?)',
            (name, round_num, date_str, status)
        )
    
    db.commit()

def fetch_races_from_api():
    """Fetch 2026 race calendar from Jolpica API."""
    api_url = f"{app.config['F1_API_URL']}/2026.json"
    
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
            time = race.get('time', '12:00:00Z').replace('Z', '')
            
            if date:
                date_str = f"{date} {time}" if time else f"{date} 12:00:00"
                races.append((race_name, round_num, date_str))
        
        return races
    except Exception as e:
        app.logger.error(f"Failed to fetch races from API: {e}")
        return None

def get_fallback_races_2026():
    """Fallback 2026 race calendar if API fails."""
    return [
        ("Australian Grand Prix", 1, "2026-03-15 04:00:00"),
        ("Chinese Grand Prix", 2, "2026-03-22 07:00:00"),
        ("Japanese Grand Prix", 3, "2026-04-05 05:00:00"),
        ("Bahrain Grand Prix", 4, "2026-04-12 15:00:00"),
        ("Saudi Arabian Grand Prix", 5, "2026-04-19 17:00:00"),
        ("Miami Grand Prix", 6, "2026-05-03 20:00:00"),
        ("Canadian Grand Prix", 7, "2026-05-24 20:00:00"),
        ("Spanish Grand Prix", 8, "2026-06-07 13:00:00"),
        ("Austrian Grand Prix", 9, "2026-06-21 13:00:00"),
        ("British Grand Prix", 10, "2026-07-05 14:00:00"),
        ("Belgian Grand Prix", 11, "2026-07-19 13:00:00"),
        ("Hungarian Grand Prix", 12, "2026-07-26 13:00:00"),
        ("Dutch Grand Prix", 13, "2026-08-23 13:00:00"),
        ("Italian Grand Prix", 14, "2026-09-06 13:00:00"),
        ("Azerbaijan Grand Prix", 15, "2026-09-13 11:00:00"),
        ("Singapore Grand Prix", 16, "2026-10-11 12:00:00"),
        ("United States Grand Prix", 17, "2026-10-25 20:00:00"),
        ("Mexico City Grand Prix", 18, "2026-11-01 20:00:00"),
        ("Brazilian Grand Prix", 19, "2026-11-08 17:00:00"),
        ("Las Vegas Grand Prix", 20, "2026-11-22 04:00:00"),
        ("Qatar Grand Prix", 21, "2026-11-29 16:00:00"),
        ("Abu Dhabi Grand Prix", 22, "2026-12-06 13:00:00"),
    ]

# Admin: only these usernames can lock races, enter results, etc.
ADMIN_USERNAMES = {'brett'}


def is_admin(user):
    """Check if user is an admin (case-insensitive)."""
    return user and user['username'].strip().lower() in ADMIN_USERNAMES


def admin_required(f):
    """Decorator: require admin user for lock/enter-results routes."""
    @wraps(f)
    def decorated(*args, **kwargs):
        user = get_current_user()
        if not user:
            flash('Please log in to access admin', 'error')
            return redirect(url_for('index'))
        if not is_admin(user):
            flash('Admin access only', 'error')
            return redirect(url_for('races'))
        return f(*args, **kwargs)
    return decorated


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
    
    # Exact positions
    if prediction['p1_driver_id'] == result['p1_driver_id']:
        points += 10
    if prediction['p2_driver_id'] == result['p2_driver_id']:
        points += 6
    if prediction['p3_driver_id'] == result['p3_driver_id']:
        points += 4
    
    # Driver in top 3 (wrong position) - 1 point each
    predicted_drivers = {prediction['p1_driver_id'], prediction['p2_driver_id'], prediction['p3_driver_id']}
    result_drivers = {result['p1_driver_id'], result['p2_driver_id'], result['p3_driver_id']}
    
    for driver_id in predicted_drivers:
        if driver_id in result_drivers:
            # Check if already counted as exact position
            exact = False
            if driver_id == prediction['p1_driver_id'] and driver_id == result['p1_driver_id']:
                exact = True
            elif driver_id == prediction['p2_driver_id'] and driver_id == result['p2_driver_id']:
                exact = True
            elif driver_id == prediction['p3_driver_id'] and driver_id == result['p3_driver_id']:
                exact = True
            
            if not exact:
                points += 1
    
    return points

# Routes
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
    
    # Get next upcoming/open race
    next_race = db.execute('''
        SELECT * FROM races 
        WHERE status IN ('upcoming', 'open') 
        ORDER BY date LIMIT 1
    ''').fetchone()
    
    # Get user's prediction for next race if exists
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
    
    # Get user's total score
    total_score = db.execute('''
        SELECT COALESCE(SUM(points), 0) as total FROM scores WHERE user_id = ?
    ''', (user['session_id'],)).fetchone()['total']
    
    return render_template('home.html', 
                          user=user, 
                          next_race=next_race,
                          user_prediction=user_prediction,
                          total_score=total_score)

@app.route('/predict/<int:race_id>', methods=['GET', 'POST'])
def predict(race_id):
    """Make or update prediction for a race."""
    user = get_current_user()
    if not user:
        return redirect(url_for('index'))
    
    db = get_db()
    
    # Check race is open
    race = db.execute('SELECT * FROM races WHERE id = ?', (race_id,)).fetchone()
    if not race:
        flash('Race not found', 'error')
        return redirect(url_for('home'))
    
    if race['status'] == 'locked':
        flash('Predictions are locked for this race', 'error')
        return redirect(url_for('home'))
    
    if race['status'] == 'completed':
        flash('This race has already been completed', 'error')
        return redirect(url_for('home'))
    
    # Get all drivers
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
        
        # Insert or update prediction
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
    
    # Get existing prediction if any
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
    
    # Get all users with their total scores
    users = db.execute('''
        SELECT u.*, COALESCE(SUM(s.points), 0) as total_score
        FROM users u
        LEFT JOIN scores s ON u.session_id = s.user_id
        GROUP BY u.session_id
        ORDER BY total_score DESC
    ''').fetchall()
    
    # Get race-by-race breakdown
    races = db.execute('SELECT * FROM races ORDER BY round').fetchall()
    
    # Build score matrix
    score_matrix = {}
    for u in users:
        score_matrix[u['session_id']] = {}
        for race in races:
            score = db.execute('''
                SELECT points FROM scores WHERE user_id = ? AND race_id = ?
            ''', (u['session_id'], race['id'])).fetchone()
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
    all_races = db.execute('''
        SELECT r.*, 
               res.p1_driver_id, res.p2_driver_id, res.p3_driver_id,
               d1.name as p1_name, d2.name as p2_name, d3.name as p3_name
        FROM races r
        LEFT JOIN results res ON r.id = res.race_id
        LEFT JOIN drivers d1 ON res.p1_driver_id = d1.id
        LEFT JOIN drivers d2 ON res.p2_driver_id = d2.id
        LEFT JOIN drivers d3 ON res.p3_driver_id = d3.id
        ORDER BY r.round
    ''').fetchall()
    
    # Get user's predictions
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
    
    return render_template('races.html', races=all_races, predictions=predictions, is_admin=is_admin(user))

@app.route('/logout')
def logout():
    """Clear session."""
    session.clear()
    return redirect(url_for('index'))

# Admin routes
@app.route('/admin/enter-results/<int:race_id>', methods=['GET', 'POST'])
@admin_required
def enter_results(race_id):
    """Enter actual race results (admin only)."""
    db = get_db()
    
    race = db.execute('SELECT * FROM races WHERE id = ?', (race_id,)).fetchone()
    if not race:
        flash('Race not found', 'error')
        return redirect(url_for('races'))
    
    drivers = db.execute('SELECT * FROM drivers ORDER BY name').fetchall()
    
    if request.method == 'POST':
        p1 = request.form.get('p1')
        p2 = request.form.get('p2')
        p3 = request.form.get('p3')
        
        if not all([p1, p2, p3]):
            flash('Please select all three positions', 'error')
            return redirect(url_for('enter_results', race_id=race_id))
        
        # Save results
        db.execute('''
            INSERT INTO results (race_id, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(race_id) DO UPDATE SET
                p1_driver_id = excluded.p1_driver_id,
                p2_driver_id = excluded.p2_driver_id,
                p3_driver_id = excluded.p3_driver_id
        ''', (race_id, p1, p2, p3))
        
        # Mark race as completed
        db.execute('UPDATE races SET status = ? WHERE id = ?', ('completed', race_id))
        
        # Calculate scores for all predictions
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

@app.route('/admin/lock-race/<int:race_id>')
@admin_required
def lock_race(race_id):
    """Lock predictions for a race."""
    db = get_db()
    db.execute('UPDATE races SET status = ? WHERE id = ?', ('locked', race_id))
    db.commit()
    flash('Race predictions locked', 'success')
    return redirect(url_for('races'))


@app.route('/admin/delete-predictions', methods=['GET', 'POST'])
@admin_required
def delete_predictions():
    """
    Delete predictions for users matching a pattern that did NOT predict
    the given driver as P1. Used to remove duplicate/wrong 'brett' entries.
    """
    if request.method == 'GET':
        return render_template('admin_delete_predictions.html')

    username_pattern = (request.form.get('username_pattern') or request.args.get('username_pattern') or 'brett').strip()
    keep_p1_name = (request.form.get('keep_p1_name') or request.args.get('keep_p1_name') or 'Kimi').strip()
    if not username_pattern or not keep_p1_name:
        flash('username_pattern and keep_p1_name are required', 'error')
        return redirect(url_for('delete_predictions'))

    db = get_db()
    # Resolve driver id for keep_p1 (e.g. Kimi -> Kimi Antonelli)
    driver = db.execute(
        'SELECT id FROM drivers WHERE name LIKE ?', (f'%{keep_p1_name}%',)
    ).fetchone()
    if not driver:
        flash(f'No driver found matching "{keep_p1_name}"', 'error')
        return redirect(url_for('delete_predictions'))

    keep_p1_id = driver['id']
    pattern = f'%{username_pattern}%'
    session_ids = [
        row[0] for row in
        db.execute('SELECT session_id FROM users WHERE username LIKE ?', (pattern,)).fetchall()
    ]
    if not session_ids:
        flash(f'No users found matching username "{username_pattern}"', 'error')
        return redirect(url_for('delete_predictions'))

    # Predictions to remove: those users, and p1_driver_id != keep_p1_id
    placeholders = ','.join('?' * len(session_ids))
    to_delete = db.execute(
        f'''
        SELECT user_id, race_id FROM predictions
        WHERE user_id IN ({placeholders}) AND p1_driver_id != ?
        ''',
        (*session_ids, keep_p1_id)
    ).fetchall()

    for row in to_delete:
        db.execute('DELETE FROM scores WHERE user_id = ? AND race_id = ?', (row['user_id'], row['race_id']))
        db.execute('DELETE FROM predictions WHERE user_id = ? AND race_id = ?', (row['user_id'], row['race_id']))

    db.commit()
    n = len(to_delete)
    flash(f'Deleted {n} prediction(s) (and their scores) for users matching "{username_pattern}" that did not predict {keep_p1_name} as P1.', 'success')
    return redirect(url_for('races'))

# Driver refresh endpoint for CronJob
@app.route('/admin/refresh-drivers', methods=['POST'])
def refresh_drivers():
    """Refresh drivers from API - called by CronJob."""
    # Simple secret check (should use proper auth in production)
    auth_header = request.headers.get('Authorization', '')
    expected = f"Bearer {app.config['DRIVER_REFRESH_SECRET']}"
    
    if auth_header != expected and app.config['DRIVER_REFRESH_SECRET']:
        return jsonify({'error': 'Unauthorized'}), 401
    
    db = get_db()
    success, message = refresh_drivers_from_api(db)
    
    if success:
        return jsonify({'status': 'success', 'message': message}), 200
    else:
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

# Health check
@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({'status': 'healthy'})

@app.before_request
def before_request():
    """Auto-lock races that have started (all HTML/API except static and health)."""
    if request.endpoint in (None, 'static', 'health'):
        return
    # Include predict and admin routes so /predict/N cannot bypass lock after race start
    auto_lock_races()


# Initialize database on startup
with app.app_context():
    init_db()
    auto_lock_races()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
