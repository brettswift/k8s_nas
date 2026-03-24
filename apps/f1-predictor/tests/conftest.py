"""Pytest configuration and fixtures."""

import pytest
import os
import sys

# Set environment variables BEFORE anything else
os.environ['DATABASE_PATH'] = ':memory:'
os.environ['TESTING'] = 'true'
os.environ['F1_API_URL'] = 'https://api.jolpi.ca/ergast/f1'

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

# Import after setting env vars
import app as app_module


@pytest.fixture
def app():
    """Create application for testing."""
    # Get fresh app context
    with app_module.app.app_context():
        # Initialize database schema
        app_module.init_db()
        yield app_module.app


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
