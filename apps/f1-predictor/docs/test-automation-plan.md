# F1 Predictor Test Automation Plan

## Overview

This document outlines a comprehensive test automation strategy for the F1 Predictor app in `apps/f1-predictor/`, focusing on hard-to-test areas that can't be covered by simple unit tests:

- **Daily cron jobs** (driver refresh, race state management)
- **Race locking** (UI locks when race starts)
- **Live race leaderboard** (real-time updates during races)
- **Results ingestion** (post-race result processing)

## Existing Test Infrastructure

The app already has `apps/f1-mock-api/` which can be leveraged for testing. This plan extends that with:
- **Playwright** for headless browser testing
- **Time mocking** for race scenario simulation
- **CI/CD integration** for automated test runs

## Test Strategy: CI with Headless Browser + Time Manipulation

### Core Approach

Use **Playwright** with **time mocking** to simulate race weekends at different stages:

1. **Time-freeze testing** — Mock `datetime.now()` to simulate any point in the race calendar
2. **Headless browser** — Full UI automation for race locking, live updates, and user flows
3. **API mocking** — Leverage existing `f1-mock-api` for controlled F1 API responses
4. **Database fixtures** — Pre-seed test data for consistent test scenarios

### Test Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     CI Test Environment                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Flask App   │  │  f1-mock-api │  │  Playwright Tests    │  │
│  │  (test db)   │◄─┤  (existing)  │◄─┤  (time-controlled)   │  │
│  │              │  │              │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│         ▲                                    │                   │
│         └────────────────────────────────────┘                   │
│                    (headless browser)                            │
└─────────────────────────────────────────────────────────────────┘
```

### Test Directory Structure

```
apps/f1-predictor/
├── src/
│   ├── app.py
│   └── ...
├── tests/                    ← NEW TEST DIRECTORY
│   ├── conftest.py          ← Pytest fixtures
│   ├── unit/                ← Unit tests
│   ├── integration/         ← API/integration tests
│   └── e2e/                 ← Playwright E2E tests
│       ├── test_race_locking.py
│       ├── test_cron_jobs.py
│       ├── test_live_leaderboard.py
│       └── test_results_ingestion.py
├── tests/fixtures/          ← Test data
│   └── race_scenarios.py
├── tests/utils/             ← Test utilities
│   ├── time_control.py      ← Time mocking
│   └── mock_f1_api.py       ← Mock API client
└── docs/
    └── test-automation-plan.md  ← THIS FILE
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

@pytest.fixture(scope="session")
def app():
    """Flask app with test database."""
    os.environ['DATABASE_PATH'] = ':memory:'
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

#### 1.3 F1 Mock API Integration
```python
# tests/utils/mock_f1_api_client.py
"""Client to configure the existing f1-mock-api for tests."""

import requests

class MockF1APIClient:
    """Control the f1-mock-api for testing."""
    
    def __init__(self, base_url="http://f1-mock-api:8080"):
        self.base_url = base_url
    
    def set_drivers(self, drivers):
        """Set mock driver data."""
        requests.post(f"{self.base_url}/admin/drivers", json=drivers)
    
    def set_races(self, races):
        """Set mock race calendar."""
        requests.post(f"{self.base_url}/admin/races", json=races)
    
    def set_results(self, round_num, results):
        """Set mock race results."""
        requests.post(f"{self.base_url}/admin/results/{round_num}", json=results)
    
    def set_live_standings(self, round_num, standings):
        """Set mock live timing data."""
        requests.post(f"{self.base_url}/admin/live/{round_num}", json=standings)
    
    def reset(self):
        """Reset all mock data."""
        requests.post(f"{self.base_url}/admin/reset")

@pytest.fixture
def mock_f1_api():
    """Provide mock F1 API client."""
    client = MockF1APIClient()
    client.reset()
    yield client
    client.reset()
```

### 2. Example Test Implementation

```python
# tests/e2e/test_race_locking.py
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
```

### 3. CI/CD Integration

#### GitHub Actions Workflow
```yaml
# .github/workflows/f1-tests.yml
name: F1 Predictor Tests

on:
  push:
    branches: [live, main]
    paths:
      - 'apps/f1-predictor/**'
      - 'apps/f1-mock-api/**'
  pull_request:
    paths:
      - 'apps/f1-predictor/**'
      - 'apps/f1-mock-api/**'

jobs:
  test:
    runs-on: ubuntu-latest
    
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
      
      - name: Start mock API
        working-directory: apps/f1-mock-api
        run: |
          pip install -r requirements.txt
          python src/app.py &
          sleep 5
      
      - name: Run unit tests
        working-directory: apps/f1-predictor
        run: pytest tests/unit/ -v
      
      - name: Run integration tests
        working-directory: apps/f1-predictor
        env:
          F1_API_URL: http://localhost:8080
        run: pytest tests/integration/ -v
      
      - name: Run E2E tests
        working-directory: apps/f1-predictor
        env:
          F1_API_URL: http://localhost:8080
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
]

RACE_RESULTS_CHINESE_2026 = {
    'p1': 'max_verstappen',
    'p2': 'leclerc', 
    'p3': 'norris'
}
```

## Dependencies

- **Existing:** `apps/f1-predictor/` base app
- **Existing:** `apps/f1-mock-api/` for API mocking
- **New:** Playwright, pytest, pytest-playwright

## Implementation Phases

### Phase 1: Test Infrastructure
1. Set up Playwright and pytest
2. Create `tests/` directory structure
3. Implement time mocking utilities
4. Create mock API client for f1-mock-api

### Phase 2: Core Tests
1. Write race locking tests
2. Write cron job tests
3. Write results ingestion tests

### Phase 3: Advanced Tests
1. Write live leaderboard tests (depends on live feature)
2. Write end-to-end race weekend tests
3. Set up CI pipeline

## Acceptance Criteria

- [ ] Playwright test framework configured with time mocking
- [ ] Mock API client for f1-mock-api
- [ ] CI pipeline runs tests on every PR to `live` branch
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
| F1-TEST-3 | Create mock API client for f1-mock-api | F1-TEST-1 |
| F1-TEST-4 | Write race locking tests | F1-TEST-2 |
| F1-TEST-5 | Write cron job tests | F1-TEST-2, F1-TEST-3 |
| F1-TEST-6 | Write live leaderboard tests | F1-TEST-2, F1-TEST-3, F1-LIVE-1 |
| F1-TEST-7 | Set up CI pipeline | F1-TEST-1 |

## Branch
`feat/f1-test-automation-v2` (branched from `live`)

## Design Doc Location
`apps/f1-predictor/docs/test-automation-plan.md`
