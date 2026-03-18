# F1 Predictor – Bugs and Fixes

## Bug 1: Brett predictions that didn’t predict Kimi to win

**Issue:** Multiple “brett” users (different browsers) left predictions where not all had Kimi as P1. Those incorrect entries should be removed.

**Fix:** Admin action to delete predictions for users matching a username pattern (e.g. `brett`) that did **not** predict a given driver as P1. Keep only predictions that had Kimi (or specified driver) in P1.

**Implementation:** `POST /admin/delete-predictions` (admin only), body or query: `username_pattern=brett`, `keep_p1_name=Kimi` → deletes rows in `predictions` for those users/races where `p1_driver_id != <Kimi’s driver id>`. Optionally remove corresponding `scores` for those user/race pairs so leaderboard is consistent.

---

## Bug 2: No points / points not updated after race

**Issue:** After a race, points don’t show or leaderboard isn’t updated.

**Causes:**

1. **Points page exists:** Leaderboard is at **/leaderboard** (nav: “Leaderboard”). It shows total score and per-race points. If points are “-” for a race, either:
   - Results for that race were never entered, or
   - The automatic fetch never ran (see below).
2. **Fetch only runs for locked races:** `fetch_race_results.py` only processes races with `status = 'locked'` and no result yet. If the race was never locked, the fetch job does nothing for it.
3. **Scheduler / CronJob not deployed:** The job that creates one-time “fetch results” runs (e.g. `scheduler.py` / `scheduler-cronjob.yaml`) is **not** in the base or prod kustomization, so no one-time fetch jobs are created. Also the scheduler CronJob does not mount the DB volume (`/data`), so it may fail to read races.

**Fix:**

- Ensure **race is locked** when start time passes (see Bug 3).
- Add a **recurring CronJob** (`f1-fetch-results`) that runs `fetch_race_results.py` every hour (e.g. at :05), using the app image and mounting the data PVC at `/data`, so locked races without results get results and scores without depending on the one-time scheduler.

---

## Bug 3: Chinese GP (and others) didn’t lock when race started

**Issue:** Races stay “open” after their start time, so users can change predictions and the automatic results fetch never runs (it only considers `status = 'locked'`).

**Cause:** Race status is set only:
- At **seed time** in `seed_races_2026()` (open / locked / completed from date vs now), and
- **Manually** via admin “Lock race”.

There is no automatic transition from `open` → `locked` when `race.date` passes.

**Fix:** Automatically set `status = 'locked'` for races where `status = 'open'` and `date < now()`. Options:

- **On app startup:** In `init_db()` or after, run an update: `UPDATE races SET status = 'locked' WHERE status = 'open' AND date < ?`.
- **On each request (lightweight):** In a `before_request` (or only for `/home` and `/races`), run the same update once per request (or rate-limited).
- **Cron:** A small CronJob that runs every 15–60 minutes and runs that update.

Recommended: run the update **on app startup** and **once per request** for the main pages (e.g. in a `before_request` that only runs the query when handling `/home` or `/races`) so races lock soon after their start time without adding a new CronJob.

---

## Bug 4: Scheduler CronJob not deployed / no DB access

**Issue:** The scheduler CronJob (one-time job spawner) is not in the kustomization and, if it were, it only mounts the PVC at `/app` not `/data`, so it could not read the DB.

**Fix (chosen):** Add a **recurring CronJob** `f1-fetch-results` that runs `fetch_race_results.py` every hour from the app image, with the data PVC mounted at `/data`. Implemented in `base/fetch-results-cronjob.yaml` and Dockerfile `COPY cron/` so the image contains the script.

---

## Bug 5: Results API unreachable (Ergast shut down)

**Issue:** Hourly fetch ran but never got podium data; logs showed API errors or empty data.

**Cause:** `fetch_race_results.py` used `https://ergast.com/api/f1`, which is no longer available. The app calendar already uses Jolpica (`https://api.jolpi.ca/ergast/f1`).

**Fix:** Default API base to Jolpica; set `F1_API_URL` / `F1_SEASON` on the CronJob. Run `auto_lock_past_races()` at the start of each fetch run so races become `locked` even if no one visited the site.

**Verify:** `python3 cron/fetch_race_results.py --test-api` (no DB; checks 2025 Abu Dhabi results).

---

## Summary

| Bug | Fix |
| --- | --- |
| 1. Delete Brett predictions that didn’t predict Kimi P1 | Admin endpoint `POST /admin/delete-predictions` with `username_pattern`, `keep_p1_name`; delete from `predictions` (and optionally `scores`) for matching rows. |
| 2. Points not showing | Leaderboard is at /leaderboard. Ensure races are locked (Bug 3) and fetch runs (Bug 4). |
| 3. Races don’t auto-lock at start time | Update `status = 'locked'` where `status = 'open'` and `date < now()` on startup and when serving main pages. |
| 4. Scheduler not deployed / no DB | Recurring CronJob `f1-fetch-results` runs fetch script hourly; app image includes `cron/` via Dockerfile. |
| 5. Fetch always fails | Use Jolpica URL; cron auto-locks past races before querying locked-without-results. |
