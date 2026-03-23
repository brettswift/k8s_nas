# Live Race Weekend Leaderboard with Real-Time Points Projection

## Overview
Add a **"Live Race View"** that auto-refreshes during active races, showing a live leaderboard based on current running order from the F1 live timing API, with projected points for each user.

## Problem Statement
Users only see their total points after a race is completed and results are ingested. There's no engagement *during* the race — when excitement is highest.

## Solution

### Core Features
1. **Auto-refresh every 30 seconds** during active races
2. **Live leaderboard** based on current running order from F1 live timing API
3. **Points projection** — "If the race ended now, you'd have X points"
4. **Position change highlights** — "Verstappen just passed Leclerc — your P2 prediction is now worth 10 pts instead of 6!"

### Why This Matters
- **Engagement**: Users stay on the site during races instead of checking once afterward
- **Social**: Friends can watch each other's projected scores change lap by lap
- **Stickiness**: Creates a reason to return to the app mid-race

## Technical Approach

### New Components

#### API Endpoints
- `GET /api/live-standings/<race_id>` — Polls Jolpi's live timing (or FastF1) and returns current positions
- `GET /api/live-projections/<race_id>` — Returns projected points for all users based on current standings

#### Pages
- `/race/<race_id>/live` — Auto-refreshing live leaderboard page

#### Data Flow
```
F1 API (Jolpi/FastF1) → Live Standings Endpoint → Projection Engine → Frontend
                              ↑                           ↓
                         30s polling              calculate_score() reuse
```

### Database Changes
None required — reuses existing `predictions`, `drivers`, and `calculate_score()` logic.

### MVP (2-4 hours)
- Poll Jolpi's live timing API every 30s during race windows
- Show simple table: User | Current Projected Points | Best/Worst Case
- No WebSockets — AJAX polling only

### Stretch Features
- **Driver tracker**: Show where your predicted P1/P2/P3 drivers are running
- **Notifications**: "Your P1 pick is in the pits!" (browser push)
- **Race replay**: After the race, scrub through timeline to see how projections changed
- **WebSocket/SSE**: True real-time updates instead of polling

## API Integration

### Jolpi.ca Live Timing
The app already uses `api.jolpi.ca/ergast/f1` for race data. Check if live timing endpoints are available:
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

## Implementation Plan

### Phase 1: MVP
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

## Acceptance Criteria
- [ ] Live race page accessible at `/race/<race_id>/live`
- [ ] Page auto-refreshes every 30 seconds during active races
- [ ] Shows current running order from F1 API
- [ ] Shows projected points for all users based on current positions
- [ ] Highlights position changes since last refresh
- [ ] Accessible only when race status is "locked" (in progress)
- [ ] Graceful fallback if live data unavailable

## Related Files
- `src/app.py` — Add new endpoints
- `src/templates/` — Add live race template
- `src/static/` — Add live refresh JS

## Branch
`feat/f1-live-race-leaderboard`
