#!/usr/bin/env python3
"""
Scraper for The Pirate Bay user uploads
Fetches Formula.1 UHD (4K-HLG) torrents and adds them to qBittorrent

USAGE:
    # Test mode (dry run, prints what it finds without adding):
    TEST_MODE=true python3 torrent-scraper.py
    
    # Production mode (runs continuously, adds torrents):
    python3 torrent-scraper.py

ENVIRONMENT VARIABLES:
    SCRAPE_URL          - API URL to query (default: https://apibay.org/q.php?q=user:smcgill1969)
    QBT_URL             - qBittorrent Web API URL (default: http://127.0.0.1:8080)
    CHECK_INTERVAL      - Seconds between checks (default: 3600 = 1 hour)
    STATE_FILE          - Path to JSON file tracking seen torrents (default: /config/scraper-state.json)
    LOG_FILE            - Path to log file (default: /var/log/scraper.log)
    TEST_MODE           - Set to "true" for dry-run mode (default: false)
    CRON_MODE           - Set to "true" to run once and exit (for CronJob) (default: false)
    CATEGORY            - Category to assign to added torrents (default: formula1)
    SAVE_PATH           - Save/download path for torrents (default: /data/media/formula1)
    MAX_AGE_DAYS        - Only add torrents added within last N days (default: 7)
    SEQUENTIAL_DOWNLOAD - Enable sequential download (default: true)

FILTERING:
    Only adds torrents matching: Formula.1.*4K-HLG or Formula.1.*UHD (case-insensitive)
    Examples that match:
        - Formula.1.2025x22.USA.Race.SkyF1UHD.4K-HLG
        - Formula.1.2025x21.Brazil.Race.SkyF1UHD.4K-HLG
    Examples that DON'T match:
        - Formula.1.2025x22.USA.Race.SkyF1HD.SD
        - Formula.1.2025x22.USA.Race.SkyF1HD.1080p
        - MotoGP.2025x22.Spain.Race.TNTSportsHD.4K

API:
    Uses The Pirate Bay's public API (apibay.org) which returns JSON.
    No Cloudflare challenges, no browser automation needed - simple HTTP requests.
    Returns magnet links using info_hash: magnet:?xt=urn:btih:INFO_HASH

STATE TRACKING:
    Tracks seen torrent URLs in STATE_FILE (JSON format) to avoid duplicates.
    State persists across pod restarts if STATE_FILE is on a PVC (like /config).
"""

import os
import re
import time
import json
import logging
import requests
from pathlib import Path
from logging.handlers import RotatingFileHandler

# Configuration
SCRAPE_URL = os.getenv("SCRAPE_URL", "https://apibay.org/q.php?q=user:smcgill1969")
QBT_URL = os.getenv("QBT_URL", "http://127.0.0.1:8080")
CHECK_INTERVAL = int(os.getenv("CHECK_INTERVAL", "3600"))  # 1 hour
STATE_FILE = Path(os.getenv("STATE_FILE", "/config/scraper-state.json"))
LOG_FILE = Path(os.getenv("LOG_FILE", "/var/log/scraper.log"))
TEST_MODE = os.getenv("TEST_MODE", "false").lower() == "true"
CRON_MODE = os.getenv("CRON_MODE", "false").lower() == "true"
CATEGORY = os.getenv("CATEGORY", "formula1")
SAVE_PATH = os.getenv("SAVE_PATH", "/data/media/formula1")
MAX_AGE_DAYS = int(os.getenv("MAX_AGE_DAYS", "7"))  # Only add torrents from last week
SEQUENTIAL_DOWNLOAD = os.getenv("SEQUENTIAL_DOWNLOAD", "true").lower() == "true"

# Setup logging to both file and stdout
def setup_logging(log_file):
    """Configure logging to write to both file and stdout"""
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Clear any existing handlers
    logger.handlers.clear()
    
    # Format for log messages
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # File handler with rotation (10MB max, keep 5 backups)
    log_file.parent.mkdir(parents=True, exist_ok=True)
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    
    # Console handler (stdout) - for kubectl logs
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    return logger

# Setup logging
logger = setup_logging(LOG_FILE)

# Load state (track torrent hashes/URLs we've already added)
if STATE_FILE.exists():
    with open(STATE_FILE, 'r') as f:
        state = json.load(f)
    logger.info(f"Loaded state from {STATE_FILE} ({len(state.get('seen_torrents', []))} seen torrents)")
else:
    state = {"seen_torrents": [], "seen_hashes": []}
    logger.info(f"Starting with empty state (state file: {STATE_FILE})")

def get_torrent_links(api_url):
    """Fetch torrents from The Pirate Bay API (returns JSON)"""
    try:
        logger.info("Fetching from The Pirate Bay API...")
        response = requests.get(api_url, timeout=30)
        response.raise_for_status()
        
        # Parse JSON response
        torrents = response.json()
        
        if not torrents or len(torrents) == 0:
            logger.warning("No torrents found in API response")
            return []
        
        logger.info(f"Found {len(torrents)} total torrents")
        
        # Calculate cutoff time (now - MAX_AGE_DAYS)
        current_time = int(time.time())
        cutoff_time = current_time - (MAX_AGE_DAYS * 24 * 60 * 60)
        
        # Filter for Formula.1 UHD/4K-HLG torrents added within last week
        formula1_torrents = []
        for torrent in torrents:
            name = torrent.get('name', '')
            info_hash = torrent.get('info_hash', '')
            added_timestamp = int(torrent.get('added', 0))
            
            # Match Formula.1.*4K-HLG or Formula.1.*UHD
            if re.search(r'Formula\.1.*4K-HLG|Formula\.1.*UHD', name, re.IGNORECASE):
                # Check if added within last week
                if added_timestamp >= cutoff_time:
                    # Create magnet link from info_hash
                    magnet_link = f"magnet:?xt=urn:btih:{info_hash}"
                    formula1_torrents.append((magnet_link, name, info_hash, added_timestamp))
                else:
                    logger.debug(f"Skipping {name} - added {MAX_AGE_DAYS + 1}+ days ago")
        
        if TEST_MODE:
            logger.info(f"[TEST MODE] Found {len(formula1_torrents)} Formula.1 UHD/4K-HLG torrents (added within last {MAX_AGE_DAYS} days):")
            for magnet, name, info_hash, added_ts in formula1_torrents[:10]:
                added_date = time.strftime('%Y-%m-%d', time.gmtime(added_ts))
                logger.info(f"  - {name} (added: {added_date})")
        
        return formula1_torrents
    except json.JSONDecodeError as e:
        logger.error(f"API returned invalid JSON: {e}")
        return []
    except Exception as e:
        logger.error(f"Error fetching from API: {e}", exc_info=True)
        return []

def is_torrent_seen(magnet_link, state):
    """Check if we've already seen this magnet link"""
    return magnet_link in state.get("seen_torrents", [])

def add_torrent_to_state(magnet_link, state):
    """Add magnet link to state tracking"""
    if "seen_torrents" not in state:
        state["seen_torrents"] = []
    state["seen_torrents"].append(magnet_link)

def save_state_to_file(state, state_file):
    """Save state dictionary to JSON file"""
    try:
        state_file.parent.mkdir(parents=True, exist_ok=True)
        with open(state_file, 'w') as f:
            json.dump(state, f, indent=2)
        logger.debug(f"State saved to {state_file}")
        return True
    except Exception as e:
        logger.warning(f"Failed to save state: {e}", exc_info=True)
        return False

def add_torrent_to_qbit(magnet_link):
    """Add torrent to qBittorrent via Web API"""
    try:
        response = requests.post(
            f"{QBT_URL}/api/v2/torrents/add",
            data={"urls": magnet_link},
            timeout=10
        )
        success = response.status_code == 200
        if not success:
            logger.warning(f"qBittorrent API returned status {response.status_code}")
        return success
    except Exception as e:
        logger.error(f"Error adding torrent to qBittorrent: {e}", exc_info=True)
        return False

def configure_torrent(info_hash):
    """Configure torrent: set category, location, and sequential download"""
    # Retry configuration (torrent might not be immediately available after add)
    max_retries = 3
    for attempt in range(max_retries):
        try:
            if attempt > 0:
                time.sleep(2)  # Wait before retry
            
            # Set location (save/download path)
            response = requests.post(
                f"{QBT_URL}/api/v2/torrents/setLocation",
                data={"hashes": info_hash, "location": SAVE_PATH},
                timeout=10
            )
            if response.status_code != 200:
                if attempt < max_retries - 1:
                    continue
                logger.warning(f"Failed to set location: {response.status_code}")
            
            # Set category
            response = requests.post(
                f"{QBT_URL}/api/v2/torrents/setCategory",
                data={"hashes": info_hash, "category": CATEGORY},
                timeout=10
            )
            if response.status_code != 200:
                if attempt < max_retries - 1:
                    continue
                logger.warning(f"Failed to set category: {response.status_code}")
            
            # Enable sequential download if configured
            if SEQUENTIAL_DOWNLOAD:
                response = requests.post(
                    f"{QBT_URL}/api/v2/torrents/toggleSequentialDownload",
                    data={"hashes": info_hash},
                    timeout=10
                )
                if response.status_code != 200:
                    if attempt < max_retries - 1:
                        continue
                    logger.warning(f"Failed to enable sequential download: {response.status_code}")
            
            return True
        except Exception as e:
            if attempt < max_retries - 1:
                logger.debug(f"Configuration attempt {attempt + 1} failed, retrying: {e}")
                continue
            logger.error(f"Error configuring torrent after {max_retries} attempts: {e}", exc_info=True)
            return False
    
    return False

def process_torrent(magnet_link, torrent_name, info_hash, state, state_file):
    """Process a single torrent: add to qBittorrent, configure it, and update state"""
    if TEST_MODE:
        logger.info(f"[TEST MODE] Would add: {torrent_name} ({magnet_link[:60]}...)")
        logger.info(f"  Would configure: category={CATEGORY}, path={SAVE_PATH}, sequential={SEQUENTIAL_DOWNLOAD}")
        return True
    
    logger.info(f"Adding new torrent: {torrent_name} ({magnet_link[:60]}...)")
    
    # Add to qBittorrent
    if not add_torrent_to_qbit(magnet_link):
        logger.error(f"Failed to add torrent: {torrent_name}")
        return False
    
    logger.info(f"Successfully added torrent: {torrent_name}")
    
    # Configure torrent (category, location, sequential download)
    # Small delay to ensure torrent is registered in qBittorrent
    time.sleep(2)
    if configure_torrent(info_hash):
        logger.info(f"Configured torrent: category={CATEGORY}, path={SAVE_PATH}, sequential={SEQUENTIAL_DOWNLOAD}")
    else:
        logger.warning(f"Failed to configure torrent (may still work): {torrent_name}")
    
    # Update state and save immediately
    add_torrent_to_state(magnet_link, state)
    if save_state_to_file(state, state_file):
        logger.debug(f"State saved to {state_file}")
    
    return True

def process_torrents(torrent_links, state, state_file):
    """Process all torrents, skipping ones we've already seen"""
    new_count = 0
    
    for magnet_link, torrent_name, info_hash, added_timestamp in torrent_links:
        # Skip if already seen
        if is_torrent_seen(magnet_link, state):
            logger.debug(f"Skipping already seen torrent: {torrent_name}")
            continue
        
        # Process the torrent
        if process_torrent(magnet_link, torrent_name, info_hash, state, state_file):
            new_count += 1
            # Small delay between adds (only in production mode)
            if not TEST_MODE:
                time.sleep(2)
    
    return new_count

def main():
    mode_str = "[TEST MODE - DRY RUN]" if TEST_MODE else ""
    logger.info(f"Starting The Pirate Bay scraper {mode_str}")
    logger.info(f"API URL: {SCRAPE_URL}")
    logger.info(f"Filter: Formula.1 UHD (4K-HLG) only")
    logger.info(f"Log file: {LOG_FILE}")
    logger.info(f"State file: {STATE_FILE}")
    
    while True:
        logger.info("Checking for new torrents...")
        
        # Fetch torrents from API
        torrent_links = get_torrent_links(SCRAPE_URL)
        
        if not torrent_links:
            logger.info("No Formula.1 UHD torrents found")
            if TEST_MODE:
                logger.info("[TEST MODE] Exiting after one check")
                break
            logger.info(f"Sleeping for {CHECK_INTERVAL}s...")
            time.sleep(CHECK_INTERVAL)
            continue
        
        # Display found torrents
        logger.info(f"Found {len(torrent_links)} Formula.1 UHD torrent(s) (added within last {MAX_AGE_DAYS} days):")
        for magnet_link, torrent_name, info_hash, added_ts in torrent_links:
            added_date = time.strftime('%Y-%m-%d', time.gmtime(added_ts))
            logger.info(f"  - {torrent_name} (added: {added_date})")
            if TEST_MODE:
                logger.debug(f"    Magnet: {magnet_link[:60]}...")
        
        # Process all torrents
        new_count = process_torrents(torrent_links, state, STATE_FILE)
        
        # Summary
        if new_count == 0:
            logger.info("No new torrents found")
        else:
            action = "Would add" if TEST_MODE else "Added"
            logger.info(f"{action} {new_count} new torrent(s)")
        
        # Exit in test mode or cron mode (run once)
        if TEST_MODE:
            logger.info("[TEST MODE] Exiting after one check")
            break
        
        if CRON_MODE:
            logger.info("[CRON MODE] Exiting after one check")
            break
        
        # Wait before next check (only in sidecar mode)
        logger.info(f"Sleeping for {CHECK_INTERVAL}s...")
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()

