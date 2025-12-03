#!/usr/bin/env bash
# qBittorrent completion hook: Notify on F1 torrent completion
#
# CONFIGURATION IN qBittorrent WEB UI:
# 1. Go to Tools → Options → Downloads
# 2. Check "Run external program on torrent completion"
# 3. Paste this into the text field:
#    /config/notify_f1.sh "%N" "%I" "%L"
#
# VARIABLES PROVIDED BY qBittorrent:
#   %N = Torrent name
#   %I = Info hash
#   %L = Save path
#   %F = Content path
#   %R = Root path
#   %D = Torrent save path
#   %C = Number of files
#   %Z = Torrent size (bytes)
#   %T = Current tracker
#   %G = Torrent tags (comma separated)
#
# SCRIPT LOCATION: /config/notify_f1.sh

set -euo pipefail

# Configuration
NTFY_TOPIC="bswift_general"
SCRIPT_PATH="/config/notify_f1.sh"

# Get arguments from qBittorrent
TORRENT_NAME="${1:-}"
TORRENT_HASH="${2:-}"
SAVE_PATH="${3:-}"

# Log function (optional, for debugging)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> /config/notify_f1.log 2>&1 || true
}

log "Torrent completed: $TORRENT_NAME"

# Check if torrent name is provided
if [ -z "$TORRENT_NAME" ]; then
    log "ERROR: No torrent name provided"
    exit 1
fi

# Filter for F1 torrents (case-insensitive)
# Match: formula1, formula.1, FORMULA1, ForMulA1, etc.
shopt -s nocasematch
if [[ ! "$TORRENT_NAME" =~ formula1|formula\.1 ]]; then
    log "Not an F1 torrent, skipping notification: $TORRENT_NAME"
    exit 0
fi

log "F1 torrent detected, sending notification: $TORRENT_NAME"

# Parse race info from torrent name (optional enhancement)
# Format: Formula.1.2025x22.USA.Race.SkyF1UHD.4K-HLG
RACE_INFO=$(echo "$TORRENT_NAME" | grep -oE 'Formula\.1\.[0-9]+x[0-9]+\.[^.]+\.([^.]+)' | cut -d'.' -f4-5 | tr '.' ' -' 2>/dev/null || echo "")

# Build notification message
if [ -n "$RACE_INFO" ]; then
    # Try to extract country and event type
    COUNTRY=$(echo "$RACE_INFO" | cut -d' ' -f1 2>/dev/null || echo "")
    EVENT_TYPE=$(echo "$RACE_INFO" | cut -d' ' -f2 2>/dev/null || echo "")
    
    if [ -n "$COUNTRY" ] && [ -n "$EVENT_TYPE" ]; then
        MESSAGE="$COUNTRY - $EVENT_TYPE"
        TITLE="F1 Torrent Completed"
    else
        MESSAGE="$TORRENT_NAME"
        TITLE="F1 Torrent Completed"
    fi
else
    MESSAGE="$TORRENT_NAME"
    TITLE="F1 Torrent Completed"
fi

# Send notification to ntfy.sh
curl -s \
    -H "Title: $TITLE" \
    -H "Tags: formula1" \
    -d "$MESSAGE" \
    "https://ntfy.sh/$NTFY_TOPIC" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Notification sent successfully: $MESSAGE"
else
    log "ERROR: Failed to send notification"
    exit 1
fi

exit 0

