#!/usr/bin/env python3
"""Update SABnzbd API key in Sonarr and Radarr via their APIs"""

import json
import sys
import urllib.request
import urllib.parse

SABNZBD_API_KEY = sys.argv[1] if len(sys.argv) > 1 else "8ae9fbed4b344a72908859434269067c"
SONARR_API_KEY = "aa91f40651d84c2bb03faadc07d9ccbc"
RADARR_API_KEY = "20c22574260f40d691b1256889ba0216"

SONARR_URL = "http://sonarr.media:8989/sonarr"
RADARR_URL = "http://radarr.media:7878/radarr"

def update_download_client(url, api_key, client_name, new_api_key_value):
    """Update download client API key"""
    # Get all download clients
    req = urllib.request.Request(f"{url}/api/v3/downloadclient?apikey={api_key}")
    with urllib.request.urlopen(req) as response:
        clients = json.loads(response.read())
    
    # Find SABnzbd
    sabnzbd = None
    for client in clients:
        if client.get("name") == client_name:
            sabnzbd = client
            break
    
    if not sabnzbd:
        print(f"{client_name} not found. You may need to add it manually in the UI.")
        return False
    
    # Update the apiKey field
    for field in sabnzbd.get("fields", []):
        if field.get("name") == "apiKey":
            field["value"] = new_api_key_value
            break
    
    # Update the client
    client_id = sabnzbd.get("id")
    data = json.dumps(sabnzbd).encode('utf-8')
    req = urllib.request.Request(
        f"{url}/api/v3/downloadclient/{client_id}?apikey={api_key}",
        data=data,
        headers={'Content-Type': 'application/json'},
        method='PUT'
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read())
            print(f"✅ Updated {client_name} API key successfully")
            return True
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"❌ Error updating {client_name}: {e.code} - {error_body}")
        return False

if __name__ == "__main__":
    print(f"Updating SABnzbd API key to: {SABNZBD_API_KEY}")
    print("\nUpdating Sonarr...")
    update_download_client(SONARR_URL, SONARR_API_KEY, "SABnzbd", SABNZBD_API_KEY)
    print("\nUpdating Radarr...")
    update_download_client(RADARR_URL, RADARR_API_KEY, "SABnzbd", SABNZBD_API_KEY)
    print("\nDone!")

