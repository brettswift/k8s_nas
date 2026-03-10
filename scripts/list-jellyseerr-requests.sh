#!/usr/bin/env bash
# List all media requests from Jellyseerr (read-only) with titles from Sonarr/Radarr.
# Copies the SQLite DB from the pod, then resolves TV titles from Sonarr and movie
# titles from Radarr (via port-forward). No TMDB API key needed for items in Sonarr/Radarr.
#
# Optional: set TMDB_API_KEY to resolve titles for requests not yet in Sonarr/Radarr.
#
# Status: Pending | Approved | Available | Partial
set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG
NAMESPACE="${NAMESPACE:-media}"
TMP_DB="/tmp/jellyseerr_requests_$$.sqlite3"
SONARR_PF_PORT="${SONARR_PF_PORT:-19989}"
RADARR_PF_PORT="${RADARR_PF_PORT:-17878}"

cleanup() {
  rm -f "$TMP_DB" "/tmp/jellyseerr_sonarr_$$.json" "/tmp/jellyseerr_radarr_$$.json"
  kill $SONARR_PF_PID $RADARR_PF_PID 2>/dev/null
  wait $SONARR_PF_PID $RADARR_PF_PID 2>/dev/null
}
trap cleanup EXIT

POD=$(kubectl get pods -n "$NAMESPACE" -l app=jellyseerr -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) || true
if [ -z "$POD" ]; then
  echo "No Jellyseerr pod found in namespace $NAMESPACE"
  exit 1
fi

echo "Copying Jellyseerr DB from pod $POD ..."
kubectl cp -n "$NAMESPACE" "$POD":/app/config/db/db.sqlite3 "$TMP_DB" 2>/dev/null

# Get API keys from cluster
SONARR_KEY=$(kubectl get secret starr-secrets -n "$NAMESPACE" -o jsonpath='{.data.SONARR_API_KEY}' 2>/dev/null | base64 -d 2>/dev/null)
RADARR_KEY=$(kubectl get secret starr-secrets -n "$NAMESPACE" -o jsonpath='{.data.RADARR_API_KEY}' 2>/dev/null | base64 -d 2>/dev/null)

# Port-forward to Sonarr and Radarr and fetch series/movies for title lookup
SONARR_PF_PID=""
RADARR_PF_PID=""
if [ -n "$SONARR_KEY" ]; then
  kubectl port-forward -n "$NAMESPACE" svc/sonarr "$SONARR_PF_PORT:8989" &>/dev/null &
  SONARR_PF_PID=$!
fi
if [ -n "$RADARR_KEY" ]; then
  kubectl port-forward -n "$NAMESPACE" svc/radarr "$RADARR_PF_PORT:7878" &>/dev/null &
  RADARR_PF_PID=$!
fi
sleep 2

SONARR_JSON="/tmp/jellyseerr_sonarr_$$.json"
RADARR_JSON="/tmp/jellyseerr_radarr_$$.json"
if [ -n "$SONARR_KEY" ]; then
  curl -sS -H "X-Api-Key: $SONARR_KEY" "http://127.0.0.1:$SONARR_PF_PORT/sonarr/api/v3/series" > "$SONARR_JSON" 2>/dev/null || true
fi
if [ -n "$RADARR_KEY" ]; then
  curl -sS -H "X-Api-Key: $RADARR_KEY" "http://127.0.0.1:$RADARR_PF_PORT/radarr/api/v3/movie" > "$RADARR_JSON" 2>/dev/null || true
fi

# Build tvdbId -> title (Sonarr), tmdbId -> title (Radarr) via Python
python3 << PY
import json, sqlite3, sys

sonarr = []
radarr = []
try:
    with open("$SONARR_JSON") as f:
        sonarr = json.load(f)
except Exception:
    pass
try:
    with open("$RADARR_JSON") as f:
        radarr = json.load(f)
except Exception:
    pass

tvdb_to_title = {s.get("tvdbId"): (s.get("title") or "") for s in sonarr if s.get("tvdbId")}
tmdb_to_title = {m.get("tmdbId"): (m.get("title") or "") for m in radarr if m.get("tmdbId")}

conn = sqlite3.connect("$TMP_DB")
conn.row_factory = sqlite3.Row
cur = conn.execute("""
  SELECT r.id, r.status, r.type, r.createdAt, m.tmdbId, m.tvdbId
  FROM media_request r JOIN media m ON r.mediaId = m.id
  ORDER BY r.createdAt DESC
""")
status_map = {1: "Pending", 2: "Approved", 3: "Declined", 4: "Processing", 5: "Available", 6: "Partial"}
rows = []
for row in cur:
    r = dict(row)
    r["status_str"] = status_map.get(r["status"], "?")
    if r["type"] == "tv" and r.get("tvdbId"):
        r["title"] = tvdb_to_title.get(r["tvdbId"]) or "(not in Sonarr)"
    elif r["type"] == "movie" and r.get("tmdbId"):
        r["title"] = tmdb_to_title.get(r["tmdbId"]) or "(not in Radarr)"
    else:
        r["title"] = "(no id)"
    rows.append(r)

# Print table
fmt = "{req_id:<6} {status:<10} {type:<6} {requested_at:<20} {title:<50} {tmdb_id}"
print(fmt.format(req_id="req_id", status="status", type="type", requested_at="requested_at", title="title", tmdb_id="tmdb_id"))
print("-" * 6, "-" * 10, "-" * 6, "-" * 20, "-" * 50, "-" * 8)
for r in rows:
    title = (r["title"] or "")[:49]
    print(fmt.format(req_id=r["id"], status=r["status_str"], type=r["type"], requested_at=r["createdAt"], title=title, tmdb_id=r["tmdbId"] or ""))
PY

echo ""
echo "Titles from Sonarr (TV) and Radarr (movies). '(not in Sonarr/Radarr)' = request not yet added there."
echo "Done. Re-request or re-monitor from Jellyseerr UI (https://home.brettswift.com/jellyseerr)."
