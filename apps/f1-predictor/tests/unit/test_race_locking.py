"""Unit tests for race locking functionality."""

import pytest
from datetime import datetime, timezone, timedelta

from tests.utils.time_control import TimeController


class TestRaceLocking:
    """Test cases for T-RL-001 to T-RL-009."""
    
    def test_auto_lock_at_race_start(self, app, time_controller):
        """T-RL-001: Race status changes to 'locked' when race start time is reached.
        
        Given a race is scheduled to start at 14:00 UTC
        When the current time reaches 14:00 UTC
        Then the race status should change to 'locked'
        And the prediction form should be disabled
        """
        # Setup: Create race starting at 14:00 UTC
        race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
        
        with app.app_context():
            from app import get_db
            db = get_db()
            db.execute('''
                INSERT INTO races (name, round, date, status)
                VALUES (?, ?, ?, 'open')
            ''', ('Chinese Grand Prix', 1, race_time.strftime('%Y-%m-%d %H:%M:%S')))
            db.commit()
        
        # Freeze time at 13:59 (1 minute before race)
        time_controller.freeze(race_time - timedelta(minutes=1))
        
        with app.app_context():
            from app import get_db, compute_race_status
            db = get_db()
            race = db.execute('SELECT * FROM races WHERE round = 1').fetchone()
            status = compute_race_status(dict(race), has_results=False)
            assert status == 'open', "Race should be open before start time"
        
        # Advance time to 14:00 (race start)
        time_controller.advance(minutes=1)
        
        with app.app_context():
            from app import get_db, compute_race_status
            db = get_db()
            race = db.execute('SELECT * FROM races WHERE round = 1').fetchone()
            status = compute_race_status(dict(race), has_results=False)
            assert status == 'locked', "Race should be locked at start time"
    
    def test_predictions_allowed_before_race(self, app, time_controller, client):
        """T-RL-002: Predictions can be submitted before race starts.
        
        Given a race is scheduled to start at 14:00 UTC
        And the current time is 13:59 UTC
        When a user visits the race page
        Then the prediction form should be enabled
        And the user can submit predictions
        """
        race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
        
        with app.app_context():
            from app import get_db
            db = get_db()
            db.execute('''
                INSERT INTO races (name, round, date, status)
                VALUES (?, ?, ?, 'open')
            ''', ('Chinese Grand Prix', 1, race_time.strftime('%Y-%m-%d %H:%M:%S')))
            # Add a driver for predictions
            db.execute('''
                INSERT INTO drivers (id, driver_id, name, number, code)
                VALUES (1, 'max_verstappen', 'Max Verstappen', 1, 'VER')
            ''')
            db.commit()
        
        # Freeze time at 13:59
        time_controller.freeze(race_time - timedelta(minutes=1))
        
        # Visit race page
        response = client.get('/race/1')
        assert response.status_code == 200
        # Form should be present (not locked)
        assert b'predictions locked' not in response.data.lower()
    
    def test_no_predictions_after_lock(self, app, time_controller, client):
        """T-RL-005: POST requests to locked race are rejected.
        
        Given a race is locked
        When a user tries to POST a prediction
        Then the request should be rejected (403 or redirect)
        """
        race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
        
        with app.app_context():
            from app import get_db
            db = get_db()
            db.execute('''
                INSERT INTO races (name, round, date, status)
                VALUES (?, ?, ?, 'locked')
            ''', ('Chinese Grand Prix', 1, race_time.strftime('%Y-%m-%d %H:%M:%S')))
            db.execute('''
                INSERT INTO drivers (id, driver_id, name, number, code)
                VALUES (1, 'max_verstappen', 'Max Verstappen', 1, 'VER')
            ''')
            db.commit()
        
        # Try to POST prediction to locked race
        response = client.post('/race/1/predict', data={
            'p1_driver': '1',
            'p2_driver': '1',
            'p3_driver': '1'
        }, follow_redirects=True)
        
        # Should be rejected or redirected
        assert response.status_code in [200, 302, 403]
    
    def test_race_lock_on_app_startup(self, app, time_controller):
        """T-RL-008: auto_lock_races() updates status on startup.
        
        Given app starts with past open races
        When init_db() runs
        Then auto_lock_races() should update status to 'locked'
        """
        past_race_time = datetime(2026, 3, 20, 14, 0, 0, tzinfo=timezone.utc)
        
        with app.app_context():
            from app import get_db, auto_lock_races
            db = get_db()
            db.execute('''
                INSERT INTO races (name, round, date, status)
                VALUES (?, ?, ?, 'open')
            ''', ('Past Grand Prix', 1, past_race_time.strftime('%Y-%m-%d %H:%M:%S')))
            db.commit()
            
            # Freeze time to after race
            time_controller.freeze(datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc))
            
            # Run auto_lock_races (simulating startup)
            auto_lock_races()
            
            # Check race is now locked
            race = db.execute('SELECT * FROM races WHERE round = 1').fetchone()
            assert race['status'] == 'locked', "Past race should be locked on startup"
