#!/usr/bin/env python3
"""
F1 Prediction App - A no-signup F1 prediction web app
Users enter a username, pick P1/P2/P3 for each race, and accumulate points.
"""

import os
import uuid
import sqlite3
from datetime import datetime, timedelta
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, session, g, flash, jsonify

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['DATABASE'] = os.environ.get('DATABASE_PATH', '/data/f1_predictions.db')

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
    """Initialize database with schema and seed data."""
    db = get_db()
    
    # Users table
    db.execute('''
        CREATE TABLE IF NOT EXISTS users (
            session_id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Drivers table
    db.execute('''
        CREATE TABLE IF NOT EXISTS drivers (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            team TEXT NOT NULL,
            number INTEGER NOT NULL
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
    seed_drivers_2025(db)
    seed_races_2025(db)

def seed_drivers_2025(db):
    """Seed 2025 F1 driver grid."""
    drivers = [
        (1, "Max Verstappen", "Red Bull Racing", 1),
        (2, "Liam Lawson", "Red Bull Racing", 30),
        (3, "Lewis Hamilton", "Ferrari", 44),
        (4, "Charles Leclerc", "Ferrari", 16),
        (5, "Lando Norris", "McLaren", 4),
        (6, "Oscar Piastri", "McLaren", 81),
        (7, "George Russell", "Mercedes", 63),
        (8, "Kimi Antonelli", "Mercedes", 12),
        (9, "Fernando Alonso", "Aston Martin", 14),
        (10, "Lance Stroll", "Aston Martin", 18),
        (11, "Pierre Gasly", "Alpine", 10),
        (12, "Jack Doohan", "Alpine", 7),
        (13, "Alexander Albon", "Williams", 23),
        (14, "Carlos Sainz", "Williams", 55),
        (15, "Nico Hulkenberg", "Kick Sauber", 27),
        (16, "Gabriel Bortoleto", "Kick Sauber", 5),
        (17, "Yuki Tsunoda", "Racing Bulls", 22),
        (18, "Isack Hadjar", "Racing Bulls", 6),
        (19, "Esteban Ocon", "Haas", 31),
        (20, "Oliver Bearman", "Haas", 87),
    ]
    
    # Check if drivers already exist
    count = db.execute('SELECT COUNT(*) FROM drivers').fetchone()[0]
    if count == 0:
        db.executemany(
            'INSERT INTO drivers (id, name, team, number) VALUES (?, ?, ?, ?)',
            drivers
        )
        db.commit()

def seed_races_2025(db):
    """Seed 2025 F1 race calendar."""
    races = [
        ("Australian Grand Prix", 1, "2025-03-16 01:00:00"),
        ("Chinese Grand Prix", 2, "2025-03-23 08:00:00"),
        ("Japanese Grand Prix", 3, "2025-04-06 06:00:00"),
        ("Bahrain Grand Prix", 4, "2025-04-13 16:00:00"),
        ("Saudi Arabian Grand Prix", 5, "2025-04-20 17:00:00"),
        ("Miami Grand Prix", 6, "2025-05-04 20:00:00"),
        ("Emilia Romagna Grand Prix", 7, "2025-05-18 14:00:00"),
        ("Monaco Grand Prix", 8, "2025-05-25 14:00:00"),
        ("Canadian Grand Prix", 9, "2025-06-15 14:00:00"),
        ("Spanish Grand Prix", 10, "2025-06-22 14:00:00"),
        ("Austrian Grand Prix", 11, "2025-06-29 14:00:00"),
        ("British Grand Prix", 12, "2025-07-06 14:00:00"),
        ("Belgian Grand Prix", 13, "2025-07-27 14:00:00"),
        ("Hungarian Grand Prix", 14, "2025-08-03 14:00:00"),
        ("Dutch Grand Prix", 15, "2025-08-31 14:00:00"),
        ("Italian Grand Prix", 16, "2025-09-07 14:00:00"),
        ("Azerbaijan Grand Prix", 17, "2025-09-21 13:00:00"),
        ("Singapore Grand Prix", 18, "2025-10-05 13:00:00"),
        ("United States Grand Prix", 19, "2025-10-19 14:00:00"),
        ("Mexico City Grand Prix", 20, "2025-10-26 14:00:00"),
        ("Brazilian Grand Prix", 21, "2025-11-09 14:00:00"),
        ("Las Vegas Grand Prix", 22, "2025-11-22 18:00:00"),
        ("Qatar Grand Prix", 23, "2025-11-30 14:00:00"),
        ("Abu Dhabi Grand Prix", 24, "2025-12-07 13:00:00"),
    ]
    
    # Check if races already exist
    count = db.execute('SELECT COUNT(*) FROM races').fetchone()[0]
    if count == 0:
        for name, round_num, date_str in races:
            race_date = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
            # Set status based on date relative to now
            if race_date > datetime.now() + timedelta(hours=1):
                status = 'open'
            elif race_date > datetime.now():
                status = 'locked'
            else:
                status = 'completed'
            
            db.execute(
                'INSERT INTO races (name, round, date, status) VALUES (?, ?, ?, ?)',
                (name, round_num, date_str, status)
            )
        db.commit()

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
        user_prediction = db.execute('''
            SELECT p.*, d1.name as p1_name, d2.name as p2_name, d3.name as p3_name
            FROM predictions p
            JOIN drivers d1 ON p.p1_driver_id = d1.id
            JOIN drivers d2 ON p.p2_driver_id = d2.id
            JOIN drivers d3 ON p.p3_driver_id = d3.id
            WHERE p.user_id = ? AND p.race_id = ?
        ''', (user['session_id'], next_race['id'])).fetchone()
    
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
    drivers = db.execute('SELECT * FROM drivers ORDER BY team, name').fetchall()
    
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
    
    return render_template('races.html', races=all_races, predictions=predictions)

@app.route('/logout')
def logout():
    """Clear session."""
    session.clear()
    return redirect(url_for('index'))

# Admin routes (no auth for simplicity, but in production would need protection)
@app.route('/admin/enter-results/<int:race_id>', methods=['GET', 'POST'])
def enter_results(race_id):
    """Enter actual race results (admin only - no auth for MVP)."""
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
def lock_race(race_id):
    """Lock predictions for a race."""
    db = get_db()
    db.execute('UPDATE races SET status = ? WHERE id = ?', ('locked', race_id))
    db.commit()
    flash('Race predictions locked', 'success')
    return redirect(url_for('races'))

# Health check
@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({'status': 'healthy'})

# Initialize database on startup
with app.app_context():
    init_db()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
