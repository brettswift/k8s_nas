# F1 Race Results Auto-Fetcher

Automatically fetches race results from Ergast API after each F1 race.

## How It Works

1. **Scheduler** (`scheduler.py`): Runs daily, spawns one-time CronJobs for upcoming races
2. **Fetcher** (`fetch_race_results.py`): Fetches results from Ergast API and updates database
3. **CronJobs**: Kubernetes CronJobs that run once per race (1.5 hours after start)

## Flow

```
Race Date/Time
    ↓
+ 1.5 hours (race typically ends)
    ↓
K8s CronJob triggers
    ↓
Fetch results from Ergast API
    ↓
If results available:
   - Update database
   - Calculate scores
   - Mark race complete
   - CronJob auto-deletes after success
If not available:
   - Retry next scheduled run
```

## Manual Trigger

To manually fetch results (prod):
```bash
kubectl exec -it deployment/f1-predictor -n f1-predictor -- \
  python3 /app/cron/fetch_race_results.py
```

For dev: use namespace `f1-predictor-dev`.

## API Source

Uses [Ergast F1 API](http://ergast.com/mrd/) - free, official F1 timing data.

Example: `https://ergast.com/api/f1/2026/1/results.json`
