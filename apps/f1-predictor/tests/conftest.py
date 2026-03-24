"""Pytest configuration and fixtures."""

import pytest
import os
import sys

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))


@pytest.fixture
def app():
    """Create application for testing."""
    os.environ['DATABASE_PATH'] = ':memory:'
    os.environ['TESTING'] = 'true'
    os.environ['F1_API_URL'] = 'https://api.jolpi.ca/ergast/f1'
    
    from app import app, init_db, get_db
    
    with app.app_context():
        # Initialize database schema
        init_db()
        # Ensure tables are created
        db = get_db()
        db.commit()
        yield app
        # Cleanup
        db.close()


@pytest.fixture
def client(app):
    """Create test client."""
    return app.test_client()


@pytest.fixture
def time_controller():
    """Provide time control for tests."""
    from tests.utils.time_control import TimeController
    controller = TimeController()
    yield controller
    controller.unfreeze()
