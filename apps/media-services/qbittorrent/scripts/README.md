# qBittorrent Automation Scripts

High-level overview of the automation scripts for qBittorrent.

## Scripts

### `on-torrent-added.sh`
**Purpose**: Auto-categorizes and sets save path for Formula 1 torrents when manually added via qBittorrent Web UI.

**How it works**:
- Triggered by qBittorrent's "Run external program on torrent added" hook
- Matches torrent names containing "formula1" or "formula.1" (case-insensitive)
- Sets category to `formula1` and save path to `/data/media/formula1`

**Prerequisites**:
- Configured in qBittorrent Web UI: Tools → Options → Downloads → "Run external program on torrent added"
- Command: `/scripts/on-torrent-added.sh "%N" "%I"`
- qBittorrent must have "Bypass authentication for clients on localhost" enabled (for API calls)

### `torrent-scraper.py`
**Purpose**: Automatically discovers and adds Formula 1 torrents from The Pirate Bay, then configures them.

**How it works**:
- Runs as a Kubernetes CronJob (hourly)
- Queries The Pirate Bay API for user uploads
- Filters for Formula.1 UHD (4K-HLG) torrents added within last 7 days
- Adds new torrents to qBittorrent via Web API
- Configures each torrent: category, save path, sequential download
- Tracks seen torrents in state file to avoid duplicates

**Prerequisites**:
- qBittorrent must have cluster subnet (`10.0.0.0/8` or `10.42.0.0/16`) in IP whitelist for authentication bypass
- Configure in qBittorrent Web UI: Tools → Options → Web UI → "Bypass authentication for clients in whitelisted IP subnets"

**Configuration**:
- Environment variables control behavior (see script docstring for details)
- Defaults: category=`formula1`, save_path=`/data/media/formula1`, max_age=7 days

### `test-cloud-scraper.sh`
**Purpose**: Local testing script for `torrent-scraper.py` in Docker.

**How it works**:
- Builds and caches a Docker image with Python dependencies
- Runs the scraper in test mode (dry-run, no actual torrents added)
- Keeps host environment clean

## Architecture

- **Scripts are stored in ConfigMap** (`qbittorrent-scripts`) and mounted to pods
- **`on-torrent-added.sh`** runs in the qBittorrent pod (via hook)
- **`torrent-scraper.py`** runs in a separate CronJob pod (hourly schedule)
- **Custom Docker image** (`qbittorrent-scraper`) pre-installs Python dependencies for faster CronJob execution
- **State file** (`/config/scraper-state.json`) persists across CronJob runs via PVC
- **Logs** written to `/var/log/scraper.log` (with automatic rotation)

## Workflow

1. **Manual torrent addition**: User adds torrent via Web UI → `on-torrent-added.sh` auto-configures it
2. **Automatic discovery**: CronJob runs hourly → `torrent-scraper.py` finds new torrents → adds and configures them

Both scripts configure torrents the same way (category, save path), ensuring consistency.

