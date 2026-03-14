#!/usr/bin/env python3
"""
Add requested series to Sonarr and movies to Radarr (re-request from Jellyseerr list).
Uses Sonarr/Radarr APIs via base URL and API key. Run with port-forwards active or set
SONARR_URL, RADARR_URL to reach the services.
"""
import json
import os
import sys
import urllib.request
import urllib.error

SONARR_BASE = os.environ.get("SONARR_URL", "http://127.0.0.1:19999/sonarr")
RADARR_BASE = os.environ.get("RADARR_URL", "http://127.0.0.1:17878/radarr")
SONARR_KEY = os.environ.get("SONARR_API_KEY", "")
RADARR_KEY = os.environ.get("RADARR_API_KEY", "")

# TV: Young Sherlock, Star Trek Starfleet Academy, Knight of the Seven Kingdoms, + all "not in Sonarr" by tmdb
SONARR_TMDB_IDS = [
    255661,   # Young Sherlock (2026)
    223530,   # Star Trek: Starfleet Academy
    224372,   # A Knight of the Seven Kingdoms
    301507,   # (not in Sonarr)
    259731,   # (not in Sonarr)
    62413,    # (not in Sonarr)
    76331,    # (not in Sonarr)
    235685,   # (not in Sonarr)
]

# Movies: Peaky Blinders, Disclosure Day, The Odyssey, + all "not in Radarr" by tmdb
RADARR_TMDB_IDS = [
    875828,   # Peaky Blinders: The Immortal Man
    1275779,  # Disclosure Day
    1368337,  # The Odyssey
    1314481,  # (not in Radarr)
    350,      # (not in Radarr)
    1317288,  # (not in Radarr)
    1236153,  # (not in Radarr)
    1368166,  # (not in Radarr)
    537996,   # (not in Radarr)
    798645,   # (not in Radarr)
    238,      # (not in Radarr)
    1242898,  # (not in Radarr)
    8764,     # (not in Radarr)
]

ROOT_SERIES = "/data/media/series"
ROOT_MOVIES = "/data/media/movies"
QUALITY_PROFILE = 1  # Any


def req(url, method="GET", data=None, headers=None):
    h = {"X-Api-Key": SONARR_KEY if "sonarr" in url else RADARR_KEY, "Content-Type": "application/json"}
    if headers:
        h.update(headers)
    if data is not None and method != "GET":
        data = json.dumps(data).encode("utf-8")
    r = urllib.request.Request(url, data=data, headers=h, method=method)
    with urllib.request.urlopen(r) as f:
        return json.load(f)


def sonarr_get(path):
    return req(f"{SONARR_BASE}{path}")


def sonarr_post(path, data):
    return req(f"{SONARR_BASE}{path}", method="POST", data=data)


def radarr_get(path):
    return req(f"{RADARR_BASE}{path}")


def radarr_post(path, data):
    return req(f"{RADARR_BASE}{path}", method="POST", data=data)


def main():
    if not SONARR_KEY or not RADARR_KEY:
        print("Set SONARR_API_KEY and RADARR_API_KEY", file=sys.stderr)
        sys.exit(1)

    existing_sonarr_tvdb = {s.get("tvdbId") for s in sonarr_get("/api/v3/series") if s.get("tvdbId")}
    existing_radarr_tmdb = {m.get("tmdbId") for m in radarr_get("/api/v3/movie") if m.get("tmdbId")}

    print("=== Sonarr (TV) ===")
    for tmdb_id in SONARR_TMDB_IDS:
        try:
            lookup = sonarr_get(f"/api/v3/series/lookup?term=tmdb:{tmdb_id}")
            if not lookup:
                print(f"  tmdb {tmdb_id}: lookup empty, skip")
                continue
            s = lookup[0]
            tvdb = s.get("tvdbId")
            title = s.get("title", "?")
            if tvdb in existing_sonarr_tvdb:
                print(f"  {title} (tmdb {tmdb_id}): already in Sonarr, skip")
                continue
            # Add: remove id, add rootFolderPath, qualityProfileId, monitored
            payload = {k: v for k, v in s.items() if k not in ("id", "seasonCount")}
            payload["rootFolderPath"] = ROOT_SERIES
            payload["qualityProfileId"] = QUALITY_PROFILE
            payload["monitored"] = True
            payload["seasonFolder"] = True
            if "seasons" in payload:
                for se in payload["seasons"]:
                    se["monitored"] = True
            sonarr_post("/api/v3/series", payload)
            print(f"  Added: {title} (tmdb {tmdb_id})")
            existing_sonarr_tvdb.add(tvdb)
        except urllib.error.HTTPError as e:
            body = e.read().decode() if e.fp else ""
            if e.code == 409 or "already exists" in body.lower():
                print(f"  tmdb {tmdb_id}: already exists, skip")
            else:
                print(f"  tmdb {tmdb_id}: HTTP {e.code} {body[:200]}", file=sys.stderr)
        except Exception as ex:
            print(f"  tmdb {tmdb_id}: {ex}", file=sys.stderr)

    print("\n=== Radarr (Movies) ===")
    for tmdb_id in RADARR_TMDB_IDS:
        try:
            if tmdb_id in existing_radarr_tmdb:
                print(f"  tmdb {tmdb_id}: already in Radarr, skip")
                continue
            lookup = radarr_get(f"/api/v3/movie/lookup?term=tmdb:{tmdb_id}")
            if not lookup:
                print(f"  tmdb {tmdb_id}: lookup empty, skip")
                continue
            m = lookup[0]
            title = m.get("title", "?")
            payload = {k: v for k, v in m.items() if k not in ("id",)}
            payload["rootFolderPath"] = ROOT_MOVIES
            payload["qualityProfileId"] = QUALITY_PROFILE
            payload["monitored"] = True
            if "images" not in payload or not payload["images"]:
                payload["images"] = []
            radarr_post("/api/v3/movie", payload)
            print(f"  Added: {title} (tmdb {tmdb_id})")
            existing_radarr_tmdb.add(tmdb_id)
        except urllib.error.HTTPError as e:
            body = e.read().decode() if e.fp else ""
            if e.code == 409 or "already exists" in body.lower():
                print(f"  tmdb {tmdb_id}: already exists, skip")
            else:
                print(f"  tmdb {tmdb_id}: HTTP {e.code} {body[:200]}", file=sys.stderr)
        except Exception as ex:
            print(f"  tmdb {tmdb_id}: {ex}", file=sys.stderr)

    print("\nDone.")


if __name__ == "__main__":
    main()
