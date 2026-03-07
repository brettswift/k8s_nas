# F1 Prediction App Plan

**Status:** Plan only (not implemented)  
**Date:** 2026-02-15

## Overview

A no-signup F1 prediction web app. Users land on the site, enter a username (session-based), pick P1/P2/P3 for each race, and accumulate points. Data stored in SQLite on a PVC.

## Core Requirements

- **No signup:** Session controls identity; user enters username on first visit
- **Predictions:** Pick 1st, 2nd, 3rd place finishers per race
- **Scoring:** Points for correct predictions; cumulative leaderboard
- **Persistence:** SQLite on PVC (small, single-pod friendly)

## Architecture

### High-Level Flow

```
User → Ingress (/f1-predictor) → App Pod
                                    ├── SQLite (PVC at /data)
                                    └── Session (cookie) → username
```

### Session Model

- **First visit:** User sees "Enter your name" form
- **Submit:** App creates session (UUID), stores `session_id → username` in DB, sets cookie
- **Return visit:** Cookie identifies session; username loaded from DB
- **No auth:** Anyone with the cookie can act as that user (acceptable for low-stakes app)

### Data Model (SQLite)

| Table | Purpose |
|-------|---------|
| `users` | `session_id` (PK), `username`, `created_at` |
| `drivers` | `id`, `name`, `team`, `number` – F1 grid (manual seed or API) |
| `races` | `id`, `name`, `round`, `date`, `status` (upcoming \| open \| locked \| completed) |
| `predictions` | `user_id`, `race_id`, `p1_driver_id`, `p2_driver_id`, `p3_driver_id`, `created_at` |
| `results` | `race_id`, `p1_driver_id`, `p2_driver_id`, `p3_driver_id` – actual results when race done |
| `scores` | `user_id`, `race_id`, `points` – computed after each race |

### Scoring Logic

| Correct | Points |
|---------|--------|
| P1 exact | 10 |
| P2 exact | 6 |
| P3 exact | 4 |
| Driver in top 3 (wrong position) | 1 |

*Alternative: 25/18/15 for exact P1/P2/P3 only.*

### Race Lifecycle

1. **Upcoming:** Race visible; no predictions yet
2. **Open:** Predictions accepted; user picks P1/P2/P3
3. **Locked:** Predictions closed (e.g. 1h before race)
4. **Completed:** Results entered; scores calculated; leaderboard updated

## Tech Stack Options

| Option | Backend | Frontend | Pros |
|--------|---------|----------|------|
| A | Python Flask + SQLite | Jinja + HTMX | Simple, single process, easy to deploy |
| B | FastAPI + SQLite | React/Vue SPA | Clean API, modern UI |
| C | Go + SQLite | Go templates + HTMX | Fast, single binary |

**Recommendation:** Option A (Flask + HTMX) for simplicity and quick iteration.

## Deployment (k8s_nas)

### Location

```
apps/media-services/f1-predictor/
├── deployment.yaml
├── service.yaml
├── ingress.yaml
├── pvc.yaml
└── kustomization.yaml
```

### Key Config

- **Namespace:** `media` (or new `f1-predictor`)
- **Image:** Custom Python (Flask) image or build from Dockerfile in repo
- **PVC:** `ReadWriteOnce`, 1Gi, mount at `/data` for SQLite file
- **Ingress:** `https://home.brettswift.com/f1-predictor` (path-based, per existing standards)
- **Replicas:** 1 (SQLite is single-writer)

### Driver Data

- **Option 1:** Manual CSV/JSON seed at startup; update seasonally
- **Option 2:** Fetch from [Ergast F1 API](http://ergast.com/mrd/) (free, no key) on first run or cron

## UI Sketch

1. **Landing:** "Enter your name" → submit
2. **Home:** Upcoming race, "Make predictions" → driver picker (P1, P2, P3 dropdowns)
3. **Leaderboard:** Table of username, total points, race-by-race breakdown
4. **Past races:** Results + who predicted what

## Implementation Phases

### Phase 1: MVP

- [ ] Flask app with SQLite, session cookie, username entry
- [ ] Drivers table (manual seed for current season)
- [ ] Races table (manual seed for next 2–3 races)
- [ ] Prediction form (P1/P2/P3 dropdowns)
- [ ] Basic scoring (exact position only)
- [ ] Leaderboard (total points)
- [ ] k8s manifests (Deployment, Service, Ingress, PVC)
- [ ] ArgoCD ApplicationSet for f1-predictor

### Phase 2: Polish

- [ ] Race lock (close predictions before race)
- [ ] Results entry (admin or manual)
- [ ] Partial scoring (driver in top 3, wrong position)
- [ ] Past race history view

### Phase 3: Optional

- [ ] Ergast API integration for drivers/races
- [ ] Email/ntfy reminder before race lock
- [ ] Per-race leaderboard

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| SQLite + PVC: pod crash loses in-memory state | SQLite is file-based; data persists on PVC |
| Single replica: no HA | Acceptable for low-traffic app |
| Session hijacking | Low stakes; document that sessions are not secure |

## Related Documents

- [Architecture](../architecture.md) – routing standards, ingress pattern
- [PR and Deploy Workflow](../../skills/pr-deploy-workflow/SKILL.md) – deployment process
