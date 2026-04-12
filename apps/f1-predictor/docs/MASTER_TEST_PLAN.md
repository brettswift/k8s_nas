# F1 Predictor - Master Test Plan

## Document Information

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Branch | `feat/f1-test-automation-v2` |
| Based On | `live` branch with actual F1 app |
| Last Updated | 2026-03-23 |

## Overview

This master test plan provides comprehensive test coverage for the F1 Predictor application. Each test case has a unique **T-ID** (Test ID) for traceability between requirements, implementation, and failures.

## Test ID Convention

**Format:** `T-{CATEGORY}-{NUMBER}`

| Category | Description |
|----------|-------------|
| `RL` | Race Locking |
| `CJ` | Cron Jobs |
| `RI` | Results Ingestion |
| `LL` | Live Leaderboard |
| `UI` | User Interface |
| `ADM` | Admin Functions |
| `E2E` | End-to-End Flows |

## Test Case Registry

### 1. Race Locking (RL)

Tests for automatic race locking when race start time is reached.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **RL-001** | Auto-lock at race start | Race scheduled for 14:00 UTC, time reaches 14:00 | Race status changes to 'locked', prediction form disabled | P0 | Not Started |
| **RL-002** | Predictions allowed before race | Race at 14:00 UTC, current time 13:59 | Prediction form enabled, user can submit | P0 | Not Started |
| **RL-003** | Auto-lock on page refresh | User has race page open, race starts, page refreshes | Form disables without manual action | P1 | Not Started |
| **RL-004** | Lock message display | Race is locked | "Race in progress - predictions locked" message visible | P1 | Not Started |
| **RL-005** | No predictions after lock | User tries to POST prediction to locked race | Request rejected, 403 or redirect | P0 | Not Started |
| **RL-006** | Multiple races lock independently | Race A locked, Race B still open | Race A locked, Race B accepts predictions | P1 | Not Started |
| **RL-007** | Timezone handling | Race in different timezone | Lock triggers at correct UTC time | P1 | Not Started |
| **RL-008** | Race lock on app startup | App starts, past races exist | `auto_lock_races()` updates status to 'locked' | P0 | Not Started |
| **RL-009** | Race lock on request | User visits /races, past open races exist | `before_request` handler locks past races | P0 | Not Started |

**Related Bugs:** Bug 3 (Chinese GP didn't lock)

---

### 2. Cron Jobs (CJ)

Tests for background jobs: driver refresh, race state management, results fetching.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **CJ-001** | Driver refresh updates table | New driver data from API | Drivers table updated, IDs remapped | P1 | Not Started |
| **CJ-002** | Driver refresh preserves predictions | Drivers updated, predictions exist | Predictions remain valid (driver IDs remapped) | P0 | Not Started |
| **CJ-003** | Driver refresh timestamp | Refresh completes | Metadata table updated with timestamp | P1 | Not Started |
| **CJ-004** | Race manager: watching → locked | Race starts within 6 min | Stage transitions to 'locked' | P0 | Not Started |
| **CJ-005** | Race manager: locked → polling | 90 min since lock | Stage transitions to 'polling' | P0 | Not Started |
| **CJ-006** | Race manager: polling → completed | API returns results | Stage transitions to 'completed', scores calculated | P0 | Not Started |
| **CJ-007** | Race manager idle between races | No active races | Script exits quickly (< 1s) | P2 | Not Started |
| **CJ-008** | Fetch results for locked race | Race locked, no results, API has data | Results ingested, scores calculated | P0 | Not Started |
| **CJ-009** | Fetch results no data yet | Race locked, API has no results | No error, retry next run | P1 | Not Started |
| **CJ-010** | Fetch results only for locked | Race open, API has results | No action (only processes 'locked') | P1 | Not Started |
| **CJ-011** | Scheduler creates one-time jobs | Race enters polling stage | One-time fetch job scheduled | P1 | Not Started |
| **CJ-012** | Hourly fetch cron runs | CronJob triggers | `fetch_race_results.py` executes successfully | P0 | Not Started |
| **CJ-013** | CronJob has DB access | Fetch job runs | PVC mounted at /data, DB readable | P0 | Not Started |

**Related Bugs:** Bug 2 (points not updated), Bug 4 (scheduler not deployed)

---

### 3. Results Ingestion (RI)

Tests for processing race results and calculating scores.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **RI-001** | Manual results check | Admin clicks "Check Results", data available | Results ingested, scores calculated | P0 | Not Started |
| **RI-002** | Manual check no data | Admin clicks, API has no results | "Results not yet available" message | P1 | Not Started |
| **RI-003** | Score calculation: perfect prediction | P1/P2/P3 all correct | 20 points (10+6+4) | P0 | Not Started |
| **RI-004** | Score calculation: partial match | P1 correct, P2/P3 swapped | 11 points (10+0+1) | P0 | Not Started |
| **RI-005** | Score calculation: all wrong | No positions correct | 0 points | P0 | Not Started |
| **RI-006** | Score calculation: driver in podium wrong position | Driver in top 3, wrong slot | 1 point per driver | P0 | Not Started |
| **RI-007** | Score update on re-ingest | Results re-fetched | Scores recalculated, table updated | P1 | Not Started |
| **RI-008** | Results API failure handling | API returns 500 | Graceful error, no crash | P1 | Not Started |
| **RI-009** | Results with missing drivers | Driver in results not in DB | Skip or handle gracefully | P1 | Not Started |
| **RI-010** | Jolpica API integration | Fetch from Jolpica | Data retrieved successfully | P0 | Not Started |

**Related Bugs:** Bug 5 (Ergast shut down)

**Score Calculation Matrix:**

| Prediction | Actual | Points |
|------------|--------|--------|
| P1: VER, P2: LEC, P3: NOR | P1: VER, P2: LEC, P3: NOR | 20 (10+6+4) |
| P1: VER, P2: NOR, P3: LEC | P1: VER, P2: LEC, P3: NOR | 11 (10+0+1) |
| P1: LEC, P2: VER, P3: NOR | P1: VER, P2: LEC, P3: NOR | 2 (0+0+1+1) |
| P1: HAM, P2: RUS, P3: SAI | P1: VER, P2: LEC, P3: NOR | 0 |

---

### 4. Live Leaderboard (LL)

Tests for real-time race viewing and points projection.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **LL-001** | Live page accessible during race | Race status 'locked' | Page loads, shows live standings | P0 | Not Started |
| **LL-002** | Live page redirects before race | Race status 'open' | Redirect to prediction page | P1 | Not Started |
| **LL-003** | Live page redirects after race | Race status 'completed' | Redirect to results page | P1 | Not Started |
| **LL-004** | Auto-refresh live data | Page open, 30s passes | Data refreshes automatically | P0 | Not Started |
| **LL-005** | Projected points calculation | Live standings available | Correct projected points per user | P0 | Not Started |
| **LL-006** | Position change highlight | Driver moves up/down | Visual indicator of change | P2 | Not Started |
| **LL-007** | Position change notification | User's pick improves | Toast: "Verstappen overtook! +4 points!" | P2 | Not Started |
| **LL-008** | Best/worst case projection | Live standings | Show potential points range | P2 | Not Started |
| **LL-009** | Driver tracker | User's P1/P2/P3 picks | Show current positions of picked drivers | P3 | Not Started |
| **LL-010** | Live data fallback | API unavailable | Graceful message, no crash | P1 | Not Started |
| **LL-011** | Rate limiting | Many users on live page | API calls throttled appropriately | P2 | Not Started |

---

### 5. User Interface (UI)

Tests for general UI functionality and user flows.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **UI-001** | User registration | New user enters username | Session created, user in DB | P0 | Not Started |
| **UI-002** | Username persistence | User returns to site | Previous username remembered | P1 | Not Started |
| **UI-003** | Prediction submission | User selects P1/P2/P3 | Prediction saved to DB | P0 | Not Started |
| **UI-004** | Prediction update | User changes prediction before lock | Old prediction replaced | P0 | Not Started |
| **UI-005** | Race list display | User visits /races | All races shown with correct status | P1 | Not Started |
| **UI-006** | Leaderboard display | User visits /leaderboard | Total scores and per-race points visible | P0 | Not Started |
| **UI-007** | Leaderboard sorted | Multiple users | Sorted by total score descending | P1 | Not Started |
| **UI-008** | Mobile responsiveness | View on mobile device | Layout adapts correctly | P2 | Not Started |
| **UI-009** | DEV badge display | ENVIRONMENT=dev | "DEV" badge visible | P2 | Not Started |
| **UI-010** | Version display | APP_VERSION set | Version shown in footer | P3 | Not Started |

---

### 6. Admin Functions (ADM)

Tests for admin-only operations.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **ADM-001** | Admin lock race | Admin clicks "Lock Race" | Race status changes to 'locked' | P0 | Not Started |
| **ADM-002** | Admin enter results | Admin manually enters P1/P2/P3 | Results saved, scores calculated | P0 | Not Started |
| **ADM-003** | Admin delete predictions | POST /admin/delete-predictions | Matching predictions deleted | P1 | Not Started |
| **ADM-004** | Admin delete preserves scores | Delete predictions | Corresponding scores removed | P1 | Not Started |
| **ADM-005** | Non-admin blocked | Regular user accesses admin endpoint | 403 Forbidden | P0 | Not Started |
| **ADM-006** | Admin check results | Admin clicks "Check Results" | Results fetched if available | P0 | Not Started |
| **ADM-007** | Admin auth required | No session | Redirect to login | P0 | Not Started |

**Related Bugs:** Bug 1 (delete Brett predictions)

---

### 7. End-to-End Flows (E2E)

Complete user journey tests.

| T-ID | Test Case | Scenario | Expected Result | Priority | Status |
|------|-----------|----------|-----------------|----------|--------|
| **E2E-001** | Complete race weekend | Full race lifecycle | Predictions → Lock → Race → Results → Scores | P0 | Not Started |
| **E2E-002** | New user journey | First-time user | Register → Predict → View Leaderboard | P0 | Not Started |
| **E2E-003** | Multi-race season | Multiple races in season | Cumulative scores across races | P1 | Not Started |
| **E2E-004** | Race delay handling | Race delayed | Lock time adjusts, no premature lock | P2 | Not Started |
| **E2E-005** | Red flag scenario | Race paused | Live page shows "Red Flag" status | P3 | Not Started |
| **E2E-006** | API outage recovery | F1 API down during race | Graceful degradation, retry on recovery | P1 | Not Started |
| **E2E-007** | Concurrent users | Multiple users predicting | No race conditions, all predictions saved | P1 | Not Started |

---

## Test Coverage Matrix

| Feature | Unit | Integration | E2E | Total |
|---------|------|-------------|-----|-------|
| Race Locking | 4 | 3 | 2 | 9 |
| Cron Jobs | 3 | 6 | 3 | 12 |
| Results Ingestion | 4 | 4 | 2 | 10 |
| Live Leaderboard | 2 | 4 | 5 | 11 |
| User Interface | 3 | 3 | 4 | 10 |
| Admin Functions | 3 | 3 | 1 | 7 |
| **Total** | **19** | **23** | **17** | **59** |

---

## Bug Regression Tests

| Bug | T-IDs | Description |
|-----|-------|-------------|
| Bug 1 | ADM-003, ADM-004 | Delete predictions with pattern matching |
| Bug 2 | CJ-008, CJ-012, RL-001 | Points not showing - ensure lock + fetch |
| Bug 3 | RL-001, RL-008, RL-009 | Auto-lock at race start |
| Bug 4 | CJ-012, CJ-013 | Scheduler CronJob deployed with DB access |
| Bug 5 | RI-010, CJ-008 | Jolpica API integration |

---

## Implementation Priority

### Phase 1: Critical (P0) - 18 tests
- RL-001, RL-002, RL-005, RL-008, RL-009
- CJ-004, CJ-005, CJ-006, CJ-008, CJ-012, CJ-013
- RI-001, RI-003, RI-004, RI-005, RI-006, RI-010
- LL-001, LL-005

### Phase 2: High (P1) - 24 tests
- RL-003, RL-004, RL-006, RL-007
- CJ-001, CJ-002, CJ-003, CJ-007, CJ-009, CJ-010, CJ-011
- RI-002, RI-007, RI-008, RI-009
- LL-002, LL-003, LL-010
- UI-001, UI-003, UI-004, UI-006
- ADM-001, ADM-002, ADM-005, ADM-006, ADM-007

### Phase 3: Medium (P2) - 12 tests
- RL-... (none)
- CJ-... (none)
- RI-... (none)
- LL-004, LL-006, LL-007, LL-008, LL-011
- UI-002, UI-005, UI-007, UI-009
- ADM-003, ADM-004

### Phase 4: Low (P3) - 5 tests
- LL-009
- UI-010
- E2E-004, E2E-005, E2E-007

---

## Traceability

When implementing tests:
1. Create test file with T-ID in comment: `# T-RL-001: Auto-lock at race start`
2. Reference T-ID in commit message: `test: T-RL-001 add race locking test`
3. On failure, reference T-ID in bug report: `Bug: T-RL-001 fails intermittently`

---

## Branch
`feat/f1-test-automation-v2`

## Related Documents
- `apps/f1-predictor/docs/BUGS_AND_FIXES.md` - Known issues
- `apps/f1-predictor/docs/test-automation-plan.md` - Technical implementation
- `apps/f1-predictor/docs/live-race-leaderboard.md` - Feature design
