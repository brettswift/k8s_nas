# F1 Mock API

Ergast-compatible F1 API mock for testing and simulation. Seeds from the real Ergast API on startup if the database is empty. Admin UI controls race state: start times, finish, and podium.

Deployed only in dev (`f1-dev` branch); accessible at `f1.home.brettswift.com/admin`.

## API Endpoints (Ergast format)

- `GET /{season}.json` — List all races for a season
- `GET /{season}/drivers.json` — List all drivers for a season
- `GET /{season}/{round}/results.json` — Race results (returns data when race is finished and podium is set)

All responses use the standard Ergast structure: `MRData.RaceTable` / `MRData.DriverTable`.

## Admin UI (`/admin`)

- **Reseed from real API** — Clear DB and re-seed from Ergast (api.jolpi.ca)
- **Set start time** — Override race start datetime (for testing lock behaviour)
- **Finish race** — Marks race as finished so the results endpoint returns data
- **Clear results** — Unfinish a race (clears results and podium)
- **Set podium** — Choose P1/P2/P3 from driver dropdowns

## Configuration

| Variable       | Default                        | Description                    |
|----------------|--------------------------------|--------------------------------|
| `DATABASE_PATH`| `/data/f1_mock.db`             | SQLite database path           |
| `ERGAST_BASE`  | `https://api.jolpi.ca/ergast/f1/` | Source API for seeding     |
| `DEFAULT_SEASON` | `2024`                      | Season to seed when empty      |
| `SECRET_KEY`   | (dev default)                  | Flask session secret           |

## Run locally

```bash
pip install -r requirements.txt
DATABASE_PATH=./data.db flask --app src.app run
```

## Docker

```bash
docker build -t f1-mock-api .
docker run -p 5000:5000 -v f1-mock-data:/data f1-mock-api
```
