# F1 Predictor App - Live Race Leaderboard Design

## Overview

This document describes the **Live Race Leaderboard** feature for the F1 Predictor application to be built in the `k8s_nas` project.

## Context: F1 Predictor App

The F1 Predictor is a new web application that will be added to `k8s_nas/apps/f1-predictor/`. It allows users to:
- Enter a username (no signup required)
- Predict P1/P2/P3 for each F1 race
- Accumulate points based on actual race results
- View leaderboards and race results

**App Location:** `apps/f1-predictor/` (to be created)

## Feature: Live Race Weekend Leaderboard

### Problem Statement
Users only see their total points after a race is completed and results are ingested. There's no engagement *during* the race — when excitement is highest.

### Solution
Add a **"Live Race View"** that:
1. **Auto-refreshes every 30 seconds** during active races
2. **Shows a live leaderboard** based on current running order from F1 live timing API
3. **Projects points** — "If the race ended now, you'd have X points"
4. **Highlights position changes** — "Verstappen just passed Leclerc — your P2 prediction is now worth 10 pts instead of 6!"

### Why This Matters
- **Engagement**: Users stay on the site during races instead of checking once afterward
- **Social**: Friends can watch each other's projected scores change lap by lap
- **Stickiness**: Creates a reason to return to the app mid-race

## Technical Design

### App Architecture (k8s_nas)

```
k8s_nas/apps/f1-predictor/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   └── prod/
├── src/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── templates/
│       ├── base.html
│       ├── index.html
│       ├── races.html
│       ├── race_detail.html
│       └── race_live.html  ← NEW
├── cron/
│   └── race-manager.yaml
└── docs/
    └── live-race-leaderboard.md  ← THIS FILE
```

### New Components for Live Feature

#### API Endpoints
```python
# src/app.py additions

@app.route('/api/live-standings/<int:race_id>')
def get_live_standings(race_id):
    """Fetch current lap positions from F1 API."""
    # Poll Jolpi/FastF1 for live timing
    # Return: [{driver_id, position, last_lap_time}, ...]

@app.route('/api/live-projections/<int:race_id>')
def get_live_projections(race_id):
    """Calculate projected points for all users based on current standings."""
    # Get current live standings
    # For each user with predictions, calculate projected score
    # Return: [{username, projected_points, current_total, change}, ...]
```

#### Page Template
```
src/templates/race_live.html
```

### Data Flow

```
F1 API (Jolpi/FastF1)
         ↓
GET /api/live-standings/<race_id>  (30s polling)
         ↓
Projection Engine (reuse calculate_score())
         ↓
GET /api/live-projections/<race_id>
         ↓
race_live.html (auto-refreshing)
```

### Database Schema (Existing)

The live feature reuses existing tables:
- `races` — race info, status ('open', 'locked', 'completed')
- `drivers` — driver info from F1 API
- `predictions` — user predictions per race
- `users` — session-based users

### MVP Implementation (2-4 hours)

1. **Research** Jolpi live timing endpoints
2. **Endpoint** `/api/live-standings/<race_id>` — simple polling wrapper
3. **Endpoint** `/api/live-projections/<race_id>` — calculate projections
4. **Template** `race_live.html` — auto-refresh every 30s
5. **Route** `/race/<race_id>/live` — link from race list when active

### Stretch Features

- **Driver tracker**: Show where your predicted P1/P2/P3 drivers are running
- **Notifications**: "Your P1 pick is in the pits!" (browser push)
- **Race replay**: After the race, scrub through timeline to see how projections changed
- **WebSocket/SSE**: True real-time updates instead of polling
- **Best/Worst case**: Show potential points range based on possible outcomes

## API Integration

### Jolpi.ca Live Timing

The app will use `api.jolpi.ca/ergast/f1` for race data. Check if live timing endpoints are available:
- `/{season}/{round}/laps.json` — Lap-by-lap data
- `/{season}/{round}/results.json` — Updated throughout race (may have provisional results)

### Alternative: FastF1

If Jolpi doesn't have live data, consider [FastF1](https://docs.fastf1.dev/) Python library for live timing from F1's official data feeds.

## UI/UX Design

### Live Race Page (`/race/<race_id>/live`)

```
┌─────────────────────────────────────────────────────────────┐
│  🏁 Chinese Grand Prix - LIVE (Lap 34/56)                   │
│  Last updated: 14:32:05 (auto-refreshing...)               │
├─────────────────────────────────────────────────────────────┤
│  CURRENT STANDINGS (Live)                                   │
│  1. Verstappen  ▲  (was P2)                                │
│  2. Leclerc     ▼  (was P1)                                │
│  3. Norris     ─  (no change)                              │
├─────────────────────────────────────────────────────────────┤
│  PROJECTED LEADERBOARD                                      │
│  ┌──────────────┬──────────────┬─────────────┬────────────┐│
│  │ User         │ Projected    │ Current     │ Change     ││
│  │              │ Points       │ Total       │            ││
│  ├──────────────┼──────────────┼─────────────┼────────────┤│
│  │ brett        │ 16 pts       │ 142 pts     │ ▲ +6       ││
│  │ alice        │ 12 pts       │ 128 pts     │ ▲ +2       ││
│  │ bob          │ 4 pts        │ 95 pts      │ ─          ││
│  └──────────────┴──────────────┴─────────────┴────────────┘│
├─────────────────────────────────────────────────────────────┤
│  YOUR PREDICTION                                            │
│  P1: Verstappen ✅ (currently P1 - 10 pts)                 │
│  P2: Leclerc     ⚠️ (currently P2 - 6 pts)                 │
│  P3: Hamilton    ❌ (currently P8 - 0 pts)                 │
└─────────────────────────────────────────────────────────────┘
```

### Position Change Alerts

When a driver passes another, show a toast notification:
> "🔥 Verstappen overtook Leclerc! Your P2 pick is now worth 10 points!"

## Implementation Phases

### Phase 1: MVP (Core Live Feature)
1. Research Jolpi live timing endpoints
2. Create `/api/live-standings/<race_id>` endpoint
3. Create projection logic (reuse `calculate_score()`)
4. Build live race page with 30s auto-refresh
5. Add link from race list to live view when race is active

### Phase 2: Polish
1. Add position change detection and highlighting
2. Add "best/worst case" projections
3. Improve UI with driver colors/team logos
4. Add manual refresh button with cooldown

### Phase 3: Stretch
1. WebSocket/SSE for real-time updates
2. Browser push notifications
3. Race replay timeline
4. Driver tracker visualization

## Open Questions

1. Does Jolpi.ca have live timing data, or do we need FastF1?
2. What's the rate limit on F1 data APIs?
3. Should we cache live data to reduce API calls?
4. How do we handle race delays, red flags, or session interruptions?

## Dependencies

- **Parent Story:** F1 Predictor Base App (core app must exist first)
- **API:** Jolpi.ca or FastF1 for live timing
- **Frontend:** Auto-refresh JavaScript (no new dependencies)

## Acceptance Criteria

- [ ] Live race page accessible at `/race/<race_id>/live`
- [ ] Page auto-refreshes every 30 seconds during active races
- [ ] Shows current running order from F1 API
- [ ] Shows projected points for all users based on current positions
- [ ] Highlights position changes since last refresh
- [ ] Accessible only when race status is "locked" (in progress)
- [ ] Graceful fallback if live data unavailable
- [ ] Link appears on race list only when race is active

## Related Files (in k8s_nas)

- `apps/f1-predictor/src/app.py` — Add new endpoints
- `apps/f1-predictor/src/templates/race_live.html` — New template
- `apps/f1-predictor/src/static/js/live.js` — Auto-refresh logic

## Branch
`feat/f1-live-race-leaderboard`

## Design Doc Location
`apps/f1-predictor/docs/live-race-leaderboard.md`
