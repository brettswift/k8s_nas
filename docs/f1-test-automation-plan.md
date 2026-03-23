# F1 Predictor Test Automation Plan

## Overview

This document outlines a comprehensive test automation strategy for the F1 Predictor app, focusing on the hard-to-test areas that can't be covered by simple unit tests:

- **Daily cron jobs** (driver refresh, race state management)
- **Race locking** (UI locks when race starts)
- **Live race leaderboard** (real-time updates during races)
- **Results ingestion** (post-race result processing)

## Test Strategy: CI with Headless Browser + Time Manipulation

### Core Approach

Use **Playwright** with **time mocking** to simulate race weekends at different stages:

1. **Time-freeze testing** — Mock `datetime.now()` to simulate any point in the race calendar
2. **Headless browser** — Full UI automation for race locking, live updates, and user flows
3. **API mocking** — Control F1 API responses to simulate different race scenarios
4. **Database fixtures** — Pre-seed test data for consistent test scenarios

### Test Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     CI Test Environment                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Flask App   │  │  Mock F1 API │  │  Playwright Tests    │  │
│  │  (test db)   │◄─┤  (Wiremock/  │◄─┤  (time-controlled)   │  │
│  │              │  │   responses) │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│         ▲                                    │                   │
│         └────────────────────────────────────┘                   │
│                    (headless browser)                            │
└─────────────────────────────────────────────────────────────────┘
```

## Test Scenarios

### 1. Race Locking Tests

**Scenario 1.1: UI Locks at Race Start**
```gherkin
Given a race is scheduled to start at 14:00 UTC
And a user has made predictions for that race
When the current time reaches 14:00 UTC
Then the prediction form should be disabled
And a "Race in progress - predictions locked" message should display
```

**Scenario 1.2: Predictions Allowed Before Race**
```gherkin
Given a race is scheduled to start at 14:00 UTC
And the current time is 13:59 UTC
When a user visits the race page
Then the prediction form should be enabled
And the user can submit predictions
```

**Scenario 1.3: Auto-Lock Without Page Refresh**
```gherkin
Given a user has the race page open
And the race starts while the page is open
When the auto-refresh triggers (30s polling)
Then the prediction form should disable automatically
And the lock message should appear without manual refresh
```

### 2. Daily Cron Job Tests

**Scenario 2.1: Driver Refresh Job**
```gherkin
Given the driver refresh cron job is scheduled
And the F1 API returns updated driver data
When the cron job executes
Then the drivers table should be updated
And the metadata table should record the refresh timestamp
And existing predictions should remain valid (driver IDs remapped)
```

**Scenario 2.2: Race State Transitions**
```gherkin
Given races exist with status 'open'
And a race start time has passed
When the race manager cron runs
Then the race status should change to 'locked'
And the race_stages table should be updated
```

**Scenario 2.3: Results Polling**
```gherkin
Given a race has status 'locked'
And the race started 90+ minutes ago
And the F1 API returns race results
When the results polling cron runs
Then the results table should be populated
And scores should be calculated for all predictions
And race status should change to 'completed'
```

### 3. Live Race Leaderboard Tests

**Scenario 3.1: Live Page Shows Current Standings**
```gherkin
Given a race is in progress (status 'locked')
And the F1 API returns current lap positions
When a user visits the live race page
Then the current running order should display
And projected points should calculate correctly
```

**Scenario 3.2: Auto-Refresh Updates Projections**
```gherkin
Given a user is on the live race page
And the current standings show Verstappen in P2
When the F1 API updates to show Verstappen in P1
And the auto-refresh triggers
Then the projected points should update
And the position change should be highlighted
```

**Scenario 3.3: Live Page Inaccessible Before/After Race**
```gherkin
Given a race has status 'open' (not started)
When a user tries to visit the live race page
Then they should be redirected to the race prediction page

Given a race has status 'completed'
When a user tries to visit the live race page
Then they should be redirected to the race results page
```

### 4. Results Ingestion Tests

**Scenario 4.1: Manual Results Check Button**
```gherkin
Given a race has status 'locked'
And the race started 90+ minutes ago
And the F1 API has results available
When an admin clicks "Check Results"
Then the results should be ingested
And scores should be calculated
And the race status should change to 'completed'
```

**Scenario 4.2: Results Not Yet Available**
```gherkin
Given a race has status 'locked'
And the race started 90+ minutes ago
And the F1 API has no results yet
When an admin clicks "Check Results"
Then a "Results not yet available" message should display
And the race status should remain 'locked'
```

**Scenario 4.3: Score Calculation Accuracy**
```gherkin
Given predictions exist for a race
And the results are P1: Verstappen, P2: Leclerc, P3: Norris
When results are ingested
Then scores should be:
  | User | P1 Pick | P2 Pick | P3 Pick | Expected Score |
  | bob  | VER     | LEC     | NOR     | 20 (10+6+4)   |
  | alice| VER     | NOR     | LEC     | 11 (10+0+1)   |
  | carol| HAM     | RUS     | SAI     | 0             |
```

### 5. End-to-End Race Weekend Tests

**Scenario 5.1: Complete Race Weekend Flow**
```gherkin
Given a race weekend is 2 days away
When time advances to race day - 1 hour
Then predictions can be submitted

When time advances to race start
Then predictions lock automatically

When time advances to race start + 90 minutes
And results are available
Then results can be ingested
And leaderboard updates with final scores
```

## Technical Implementation

### 1. Test Infrastructure

#### 1.1 Playwright Setup
```python
# tests/conftest.py
import pytest
from playwright.sync_api import Page, Browser, BrowserContext
from testcontainers.postgres import PostgresContainer
from testcontainers.core.container import DockerContainer

@pytest.fixture(scope="session")
def postgres():
    """Spin up PostgreSQL test container."""
    with PostgresContainer("postgres:15") as postgres:
        yield postgres

@pytest.fixture
def app(postgres):
    """Flask app with test database."""
    os.environ['DATABASE_URL'] = postgres.get_connection_url()
    os.environ['TESTING'] = 'true'
    from app import app, init_db
    with app.app_context():
        init_db()
        yield app

@pytest.fixture
def page(browser: Browser, app):
    """Playwright page with app running."""
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://localhost:5000")
    yield page
    context.close()
```

#### 1.2 Time Mocking
```python
# tests/utils/time_control.py
from datetime import datetime, timezone
from unittest.mock import patch

class TimeController:
    """Control time for testing time-sensitive features."""
    
    def __init__(self):
        self._frozen_time = None
        self._patcher = None
    
    def freeze(self, dt: datetime):
        """Freeze time at specific datetime."""
        self._frozen_time = dt
        if self._patcher:
            self._patcher.stop()
        self._patcher = patch('app._now_utc', return_value=dt)
        self._patcher.start()
    
    def advance(self, minutes: int):
        """Advance frozen time by minutes."""
        if self._frozen_time:
            self._frozen_time += timedelta(minutes=minutes)
            self._patcher.stop()
            self._patcher = patch('app._now_utc', return_value=self._frozen_time)
            self._patcher.start()
    
    def unfreeze(self):
        """Restore normal time."""
        if self._patcher:
            self._patcher.stop()
            self._patcher = None

@pytest.fixture
def time_controller():
    """Provide time control for tests."""
    controller = TimeController()
    yield controller
    controller.unfreeze()
```

#### 1.3 F1 API Mocking
```python
# tests/utils/mock_f1_api.py
from flask import Flask, jsonify, request
import threading
import json

class MockF1API:
    """Mock F1 API server for testing."""
    
    def __init__(self):
        self.app = Flask(__name__)
        self.drivers = []
        self.races = []
        self.results = {}  # race_round -> results
        self.live_standings = {}  # race_round -> current positions
        
        self._setup_routes()
        self.server = None
        self.port = None
    
    def _setup_routes(self):
        @self.app.route('/ergast/f1/<season>/drivers.json')
        def get_drivers(season):
            return jsonify({
                'MRData': {
                    'DriverTable': {'Drivers': self.drivers}
                }
            })
        
        @self.app.route('/ergast/f1/<season>.json')
        def get_races(season):
            return jsonify({
                'MRData': {
                    'RaceTable': {'Races': self.races}
                }
            })
        
        @self.app.route('/ergast/f1/<season>/<round>/results.json')
        def get_results(season, round):
            return jsonify({
                'MRData': {
                    'RaceTable': {'Races': self.results.get(int(round), [])}
                }
            })
        
        @self.app.route('/ergast/f1/<season>/<round>/laps.json')
        def get_laps(season, round):
            return jsonify({
                'MRData': {
                    'RaceTable': {'Races': self.live_standings.get(int(round), [])}
                }
            })
    
    def start(self):
        """Start mock server in background thread."""
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.bind(('127.0.0.1', 0))
        self.port = sock.getsockname()[1]
        sock.close()
        
        def run():
            self.app.run(host='127.0.0.1', port=self.port, debug=False)
        
        self.server = threading.Thread(target=run, daemon=True)
        self.server.start()
        return f"http://127.0.0.1:{self.port}"
    
    def set_drivers(self, drivers):
        self.drivers = drivers
    
    def set_races(self, races):
        self.races = races
    
    def set_results(self, round_num, results):
        self.results[round_num] = results
    
    def set_live_standings(self, round_num, standings):
        self.live_standings[round_num] = standings

@pytest.fixture(scope="session")
def mock_f1_api():
    """Provide mock F1 API."""
    api = MockF1API()
    base_url = api.start()
    os.environ['F1_API_URL'] = f"{base_url}/ergast/f1"
    yield api
```

### 2. Example Test Implementation

```python
# tests/test_race_locking.py
import pytest
from datetime import datetime, timezone, timedelta

def test_ui_locks_at_race_start(page, time_controller, mock_f1_api, app):
    """Test that prediction form locks when race starts."""
    
    # Setup: Create race starting in 5 minutes
    race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
    mock_f1_api.set_races([{
        'raceName': 'Chinese Grand Prix',
        'round': 1,
        'date': race_time.strftime('%Y-%m-%d'),
        'time': race_time.strftime('%H:%M:%SZ')
    }])
    
    # Seed database with race
    with app.app_context():
        from app import get_db
        db = get_db()
        db.execute('''
            INSERT INTO races (name, round, date, status)
            VALUES (?, ?, ?, 'open')
        ''', ('Chinese Grand Prix', 1, race_time.strftime('%Y-%m-%d %H:%M:%S')))
        db.commit()
    
    # Freeze time 10 minutes before race
    time_controller.freeze(race_time - timedelta(minutes=10))
    
    # Navigate to race page
    page.goto("http://localhost:5000/races")
    page.click("text=Chinese Grand Prix")
    
    # Verify form is enabled
    assert page.is_enabled("button[type='submit']")
    assert "predictions locked" not in page.content().lower()
    
    # Advance time to race start
    time_controller.advance(10)
    
    # Trigger auto-refresh (simulate polling)
    page.reload()
    
    # Verify form is now locked
    assert page.is_disabled("button[type='submit']")
    assert page.locator("text=Race in progress - predictions locked").is_visible()


def test_live_leaderboard_updates(page, time_controller, mock_f1_api, app):
    """Test live race page shows updated projections."""
    
    # Setup race in progress
    race_time = datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc)
    current_time = race_time + timedelta(minutes=30)  # 30 min into race
    
    mock_f1_api.set_races([{
        'raceName': 'Chinese Grand Prix',
        'round': 1,
        'date': race_time.strftime('%Y-%m-%d'),
        'time': race_time.strftime('%H:%M:%SZ')
    }])
    
    # Initial standings: Leclerc P1, Verstappen P2
    mock_f1_api.set_live_standings(1, {
        'laps': [{
            'number': 15,
            'Timings': [
                {'driverId': 'leclerc', 'position': '1'},
                {'driverId': 'max_verstappen', 'position': '2'},
                {'driverId': 'norris', 'position': '3'}
            ]
        }]
    })
    
    # Seed database
    with app.app_context():
        from app import get_db
        db = get_db()
        db.execute('INSERT INTO races (name, round, date, status) VALUES (?, ?, ?, ?)',
                   ('Chinese Grand Prix', 1, race_time.strftime('%Y-%m-%d %H:%M:%S'), 'locked'))
        # Add drivers
        db.execute('INSERT INTO drivers (id, driver_id, name, number) VALUES (?, ?, ?, ?)',
                   (1, 'leclerc', 'Charles Leclerc', 16))
        db.execute('INSERT INTO drivers (id, driver_id, name, number) VALUES (?, ?, ?, ?)',
                   (2, 'max_verstappen', 'Max Verstappen', 1))
        db.execute('INSERT INTO drivers (id, driver_id, name, number) VALUES (?, ?, ?, ?)',
                   (3, 'norris', 'Lando Norris', 4))
        # Add user prediction (Verstappen P1, Leclerc P2, Norris P3)
        db.execute('INSERT INTO users (session_id, username) VALUES (?, ?)',
                   ('test-session', 'brett'))
        db.execute('''
            INSERT INTO predictions (user_id, race_id, p1_driver_id, p2_driver_id, p3_driver_id)
            VALUES (?, ?, ?, ?, ?)
        ''', ('test-session', 1, 2, 1, 3))  # P1=VER, P2=LEC, P3=NOR
        db.commit()
    
    time_controller.freeze(current_time)
    
    # Navigate to live page
    page.goto("http://localhost:5000/race/1/live")
    
    # Check initial projection (Verstappen P2 = 6 pts for P1 pick)
    assert page.locator("text=6 pts").is_visible()
    
    # Update standings: Verstappen overtakes to P1
    mock_f1_api.set_live_standings(1, {
        'laps': [{
            'number': 16,
            'Timings': [
                {'driverId': 'max_verstappen', 'position': '1'},
                {'driverId': 'leclerc', 'position': '2'},
                {'driverId': 'norris', 'position': '3'}
            ]
        }]
    })
    
    # Trigger refresh
    page.click("button:has-text('Refresh')")
    
    # Check updated projection (Verstappen P1 = 10 pts for P1 pick)
    assert page.locator("text=10 pts").is_visible()
    assert page.locator("text=Verstappen overtook Leclerc").is_visible()
```

### 3. CI/CD Integration

#### GitHub Actions Workflow
```yaml
# .github/workflows/f1-tests.yml
name: F1 Predictor Tests

on:
  push:
    paths:
      - 'apps/f1-predictor/**'
  pull_request:
    paths:
      - 'apps/f1-predictor/**'

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        working-directory: apps/f1-predictor
        run: |
          pip install -r requirements.txt
          pip install -r requirements-test.txt
          playwright install chromium
      
      - name: Run unit tests
        working-directory: apps/f1-predictor
        run: pytest tests/unit/ -v
      
      - name: Run integration tests
        working-directory: apps/f1-predictor
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/f1_test
        run: pytest tests/integration/ -v
      
      - name: Run E2E tests
        working-directory: apps/f1-predictor
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/f1_test
        run: pytest tests/e2e/ -v --browser chromium
      
      - name: Upload test artifacts
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-artifacts
          path: |
            apps/f1-predictor/test-results/
            apps/f1-predictor/playwright-report/
```

### 4. Test Data Fixtures

```python
# tests/fixtures/race_scenarios.py
"""Pre-built race scenarios for testing."""

from datetime import datetime, timezone

CHINESE_GP_2026 = {
    'name': 'Chinese Grand Prix',
    'round': 1,
    'date': datetime(2026, 3, 23, 14, 0, 0, tzinfo=timezone.utc),
    'circuit': 'Shanghai International Circuit'
}

SAUDI_GP_2026 = {
    'name': 'Saudi Arabian Grand Prix', 
    'round': 2,
    'date': datetime(2026, 3, 30, 17, 0, 0, tzinfo=timezone.utc),
    'circuit': 'Jeddah Street Circuit'
}

DRIVER_GRID_2026 = [
    {'driverId': 'max_verstappen', 'givenName': 'Max', 'familyName': 'Verstappen', 
     'permanentNumber': '1', 'code': 'VER', 'nationality': 'Dutch'},
    {'driverId': 'leclerc', 'givenName': 'Charles', 'familyName': 'Leclerc',
     'permanentNumber': '16', 'code': 'LEC', 'nationality': 'Monegasque'},
    {'driverId': 'norris', 'givenName': 'Lando', 'familyName': 'Norris',
     'permanentNumber': '4', 'code': 'NOR', 'nationality': 'British'},
    # ... more drivers
]

RACE_RESULTS_CHINESE_2026 = {
    'p1': 'max_verstappen',
    'p2': 'leclerc', 
    'p3': 'norris'
}
```

## Acceptance Criteria

- [ ] Playwright test framework configured with time mocking
- [ ] Mock F1 API server for controlled test scenarios
- [ ] CI pipeline runs tests on every PR
- [ ] Race locking tests verify UI state changes at race start
- [ ] Cron job tests verify database state transitions
- [ ] Live leaderboard tests verify projection calculations
- [ ] E2E tests cover complete race weekend flow
- [ ] Test artifacts (screenshots, videos) captured on failure
- [ ] Documentation for writing new tests

## Related Stories

| Story | Description | Depends On |
|-------|-------------|------------|
| F1-TEST-1 | Set up Playwright test framework | — |
| F1-TEST-2 | Implement time mocking utilities | F1-TEST-1 |
| F1-TEST-3 | Create mock F1 API server | F1-TEST-1 |
| F1-TEST-4 | Write race locking tests | F1-TEST-2 |
| F1-TEST-5 | Write cron job tests | F1-TEST-2, F1-TEST-3 |
| F1-TEST-6 | Write live leaderboard tests | F1-TEST-2, F1-TEST-3 |
| F1-TEST-7 | Set up CI pipeline | F1-TEST-1 |

## Branch
`feat/f1-test-automation`

## PR
https://github.com/brettswift/k8s_nas/pull/36 (design doc only)
