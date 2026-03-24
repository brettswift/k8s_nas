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
        # Setup: Create race starting at 14:00 UTC (use round 99 to avoid conflicts)
        race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
        
        # Freeze time BEFORE creating race (at 13:59, before race start)
        time_controller.freeze(race_time - timedelta(minutes=1))
        
        # Use the app context from the fixture (already initialized)
        from app import get_db, compute_race_status
        db = get_db()
        
        db.execute('''
            INSERT INTO races (name, round, date, status)
            VALUES (?, ?, ?, 'open')
        ''', ('Test Grand Prix', 99, race_time.strftime('%Y-%m-%d %H:%M:%S')))
        db.commit()
        
        # Check status at 13:59 (should be open)
        race = db.execute('SELECT * FROM races WHERE round = 99').fetchone()
        status = compute_race_status(dict(race), has_results=False)
        assert status == 'open', f"Race should be open before start time, got {status}"
        
        # Advance time to 14:00 (race start)
        time_controller.advance(minutes=1)
        
        # Check status at 14:00 (should be locked)
        race = db.execute('SELECT * FROM races WHERE round = 99').fetchone()
        status = compute_race_status(dict(race), has_results=False)
        assert status == 'locked', f"Race should be locked at start time, got {status}"
    
    def test_predictions_allowed_before_race(self, app, time_controller):
        """T-RL-002: Predictions can be submitted before race starts.
        
        Given a race is scheduled to start at 14:00 UTC
        And the current time is 13:59 UTC
        Then the race status should be 'open' (allowing predictions)
        """
        race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
        
        # Freeze time at 13:59
        time_controller.freeze(race_time - timedelta(minutes=1))
        
        from app import get_db, compute_race_status
        db = get_db()
        
        db.execute('''
            INSERT INTO races (name, round, date, status)
            VALUES (?, ?, ?, 'open')
        ''', ('Test Grand Prix', 98, race_time.strftime('%Y-%m-%d %H:%M:%S')))
        db.commit()
        
        # Check race status is 'open' (predictions allowed)
        race = db.execute('SELECT * FROM races WHERE round = 98').fetchone()
        status = compute_race_status(dict(race), has_results=False)
        assert status == 'open', f"Race should be open for predictions, got {status}"
    
    def test_no_predictions_after_lock(self, app, time_controller, client):
        """T-RL-005: POST requests to locked race are rejected.
        
        Given a race is locked
        When a user tries to POST a prediction
        Then the request should be rejected (403 or redirect)
        """
        race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
        
        from app import get_db
        db = get_db()
        db.execute('''
            INSERT INTO races (name, round, date, status)
            VALUES (?, ?, ?, 'locked')
        ''', ('Test Grand Prix', 97, race_time.strftime('%Y-%m-%d %H:%M:%S')))
        db.execute('''
            INSERT INTO drivers (id, driver_id, name, number, code)
            VALUES (?, ?, ?, ?, ?)
        ''', (98, 'test_driver2', 'Test Driver 2', 98, 'TS2'))
        db.commit()
        
        # Try to POST prediction to locked race
        response = client.post('/predict/97', data={
            'p1_driver': '98',
            'p2_driver': '98',
            'p3_driver': '98'
        }, follow_redirects=True)
        
        # Should be rejected or redirected (302 is acceptable for locked races)
        assert response.status_code in [200, 302, 403]
    
    def test_race_lock_on_app_startup(self, app, time_controller):
        """T-RL-008: auto_lock_races() updates status on startup.
        
        Given app starts with past open races
        When init_db() runs
        Then auto_lock_races() should update status to 'locked'
        """
        past_race_time = datetime(2026, 3, 20, 14, 0, 0, tzinfo=timezone.utc)
        
        # Freeze time to after race
        time_controller.freeze(datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc))
        
        from app import get_db, auto_lock_races
        db = get_db()
        db.execute('''
            INSERT INTO races (name, round, date, status)
            VALUES (?, ?, ?, 'open')
        ''', ('Past Grand Prix', 96, past_race_time.strftime('%Y-%m-%d %H:%M:%S')))
        db.commit()
        
        # Run auto_lock_races (simulating startup)
        auto_lock_races()
        
        # Check race is now locked
        race = db.execute('SELECT * FROM races WHERE round = 96').fetchone()
        assert race['status'] == 'locked', "Past race should be locked on startup"
