# Complete Guide: Starr Services Integration

**Purpose:** Configure all integrations between Starr media management services, download clients, and supporting tools.

**Services:**
- **Media Managers:** Sonarr (TV), Radarr (Movies), Lidarr (Music), Prowlarr (Indexers)
- **Download Clients:** qBittorrent (Torrents), SABnzbd (Usenet)
- **Supporting:** Bazarr (Subtitles), Unpackerr (Extraction), Flaresolverr (CAPTCHA), Jellyseerr (Requests)

---

## Quick Reference

| Integration | Direction | Where to Configure |
|------------|-----------|------------------|
| Indexers | Prowlarr → Sonarr/Radarr/Lidarr | **Prowlarr** → Settings → Apps |
| Download Client (Torrent) | Sonarr/Radarr/Lidarr → qBittorrent | **Sonarr/Radarr/Lidarr** → Settings → Download Clients |
| Download Client (Usenet) | Sonarr/Radarr/Lidarr → SABnzbd | **Sonarr/Radarr/Lidarr** → Settings → Download Clients |
| Subtitles | Sonarr/Radarr → Bazarr | **Sonarr/Radarr** → Settings → Subtitles |
| Extraction | Sonarr/Radarr → Unpackerr | **Unpackerr** → Settings → Applications |
| Requests | Jellyseerr → Sonarr/Radarr | **Jellyseerr** → Settings → Services |

---

## Prerequisites

### Create Secrets (Initial Setup)

**The `starr-secrets` Secret is created automatically during bootstrap.** If it doesn't exist:

```bash
# Create secret with empty keys (part of initial setup)
./scripts/create-starr-secrets.sh
```

This creates the secret with empty keys that will be populated later.

### Extract and Update API Keys

**View all API keys from the secret (copy and paste this command):**

```bash
for key in SONARR_API_KEY RADARR_API_KEY LIDARR_API_KEY BAZARR_API_KEY PROWLARR_API_KEY SABNZBD_API_KEY JELLYSEERR_API_KEY; do
  value=$(kubectl get secret starr-secrets -n media -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d 2>/dev/null | grep -oE '[a-f0-9]{32}' | head -1)
  if [ -n "$value" ]; then
    echo "$key: $value"
  else
    echo "$key: (empty)"
  fi
done
```

**Manual extraction** (if keys are empty, get from service UIs):
- Extract keys from service UIs:
  - Sonarr/Radarr/Lidarr: Settings → General → Security → API Key
  - Prowlarr: Settings → General → Security → API Key
  - Bazarr: Settings → General → API Key  
  - Jellyseerr: Settings → Services → [Service] → API Key
  - SABnzbd: Config → General → Security → API Key
- Update secret manually:
  ```bash
  kubectl create secret generic starr-secrets -n media \
    --from-literal=SONARR_API_KEY="<key>" \
    --from-literal=RADARR_API_KEY="<key>" \
    # ... etc
    --dry-run=client -o yaml | kubectl apply -f -
  ```

### Service URLs (Internal Kubernetes DNS)

- Sonarr: `http://sonarr:8989`
- Radarr: `http://radarr:7878`
- Lidarr: `http://lidarr:8686`
- Prowlarr: `http://prowlarr:9696`
- Bazarr: `http://bazarr:6767`
- qBittorrent: `http://qbittorrent.qbittorrent.svc.cluster.local:8080` (different namespace)
- SABnzbd: `http://sabnzbd:8081`
- Unpackerr: `http://unpackerr:9770`
- Jellyseerr: `http://jellyseerr:5055`
- Flaresolverr: `http://flaresolverr:8191`

---

## Part 1: Indexer Management (Prowlarr)

### Configure Prowlarr → Sonarr

1. **Prowlarr UI:** `https://home.brettswift.com/prowlarr` → **Settings** → **Apps**
2. **Add Application:** Click **+** → Select **Sonarr**
3. **Configure:**
   - **Name:** `Sonarr`
   - **Sync Level:** **Full Sync** (recommended) or **Add and Remove Only**
   - **Sonarr Server URL:** `http://sonarr:8989`
   - **API Key:** [Sonarr API key]
   - ✅ **Sync App Indexers:** Enabled
4. **Test** → **Save**

### Configure Prowlarr → Radarr

Same steps as Sonarr, but:
- Select **Radarr**
- **Radarr Server URL:** `http://radarr:7878`
- **API Key:** [Radarr API key]

### Configure Prowlarr → Lidarr

Same steps, but:
- Select **Lidarr**
- **Lidarr Server URL:** `http://lidarr:8686`
- **API Key:** [Lidarr API key]

### Add Indexers in Prowlarr

1. **Prowlarr UI** → **Indexers** → **+ Add Indexer**
2. Add your preferred indexers (torrent/usenet)
3. They automatically sync to Sonarr/Radarr/Lidarr!

---

## Part 2: Download Clients

### Configure qBittorrent (Torrents)

#### Get qBittorrent Credentials

1. Access qBittorrent: `https://home.brettswift.com/qbittorrent`
2. Default credentials (change if needed):
   - Username: `admin`
   - Password: Check secret or qBittorrent UI

#### Sonarr → qBittorrent

**Note:** qBittorrent uses **username/password** authentication (not API key).

1. **Sonarr UI:** `https://home.brettswift.com/sonarr` → **Settings** → **Download Clients**
2. **Add Download Client:** Click **+** → Select **qBittorrent**
3. **Configure:**
   - **Name:** `qBittorrent`
   - **Host:** `qbittorrent.qbittorrent.svc.cluster.local` (must use full DNS - different namespace)
   - **Port:** `8080`
   - **Username:** `admin` (default, check qBittorrent UI if changed)
   - **Password:** [Your qBittorrent Web UI password]
     - *Get from: qBittorrent UI → Tools → Options → Web UI → Password*
     - *Default may be `adminadmin` (check qBittorrent deployment)*
   - **Category:** `tv` (or `sonarr`)
   - ✅ **Use SSL:** No (internal network)
4. **Test** → **Save**

#### Radarr → qBittorrent

Same steps, but in Radarr:
- **Category:** `movies` (or `radarr`)

#### Lidarr → qBittorrent

Same steps, but in Lidarr:
- **Category:** `music` (or `lidarr`)

---

### Configure SABnzbd (Usenet)

#### Get SABnzbd API Key

**Method 1: From UI**
1. Access SABnzbd: `https://home.brettswift.com/sabnzbd`
2. **Config** → **General** → Scroll to **Security** section
3. Find **API Key** and copy it

**Method 2: Extract from Config** (if UI not accessible)
```bash
# Extract from running pod
kubectl exec -n media $(kubectl get pods -n media -l app=sabnzbd -o jsonpath='{.items[0].metadata.name}') \
  -- cat /config/sabnzbd.ini | grep "^api_key" | sed 's/.*=\s*//'
```


#### Sonarr → SABnzbd

1. **Sonarr UI** → **Settings** → **Download Clients** → **+ Add Download Client**
2. Select **SABnzbd**
3. **Configure:**
   - **Name:** `SABnzbd`
   - **Host:** `sabnzbd:8081`
   - **Port:** `8081`
   - **API Key:** [SABnzbd API key]
   - **Category:** `tv` (or `sonarr`)
   - ✅ **Use SSL:** No
4. **Test** → **Save**

#### Radarr → SABnzbd

Same steps, but in Radarr:
- **Category:** `movies` (or `radarr`)

---

## Part 3: Subtitles (Bazarr)

### Configure Sonarr → Bazarr

1. **Sonarr UI** → **Settings** → **Subtitles**
2. **Enable:** ✅ **Use Subtitles**
3. **Subtitle Languages:** Select your preferred languages
4. **Add Subtitle Provider:** Click **+** → Select **Bazarr**
5. **Configure:**
   - **Host:** `bazarr:6767`
   - **Port:** `6767`
   - **API Key:** [Bazarr API key]
6. **Test** → **Save**

### Configure Radarr → Bazarr

Same steps, but in Radarr.

---

## Part 4: Extraction (Unpackerr)

### Configure Unpackerr → Sonarr/Radarr

1. **Unpackerr UI:** `https://home.brettswift.com/unpackerr` (if available) or edit ConfigMap
2. **Settings** → **Applications**
3. **Add Application** → Select **Sonarr**
   - **URL:** `http://sonarr:8989`
   - **API Key:** [Sonarr API key]
4. **Add Application** → Select **Radarr**
   - **URL:** `http://radarr:7878`
   - **API Key:** [Radarr API key]
5. **Save**

**Note:** Unpackerr automatically extracts archives from download clients.

---

## Part 5: Content Requests (Jellyseerr)

### Configure Jellyseerr → Sonarr/Radarr

1. **Jellyseerr UI:** `https://home.brettswift.com/jellyseerr` → **Settings** → **Services**
2. **Add Service** → Select **Sonarr**
   - **Name:** `Sonarr`
   - **Server URL:** `http://sonarr:8989`
   - **API Key:** [Sonarr API key]
3. **Add Service** → Select **Radarr**
   - **Name:** `Radarr`
   - **Server URL:** `http://radarr:7878`
   - **API Key:** [Radarr API key]
4. **Test** → **Save**

**Note:** Jellyseerr enables users to request content via web interface.

---

## Part 6: CAPTCHA Solving (Flaresolverr - Optional)

### When to Use

Only needed if you have indexers that require CAPTCHA solving.

### Configure Prowlarr → Flaresolverr

1. **Prowlarr UI** → **Settings** → **Indexers**
2. Edit an indexer that requires Flaresolverr
3. **Flaresolverr URL:** `http://flaresolverr:8191`
4. **Save**

---

## Integration Summary Table

| Service | Configure In | Purpose |
|---------|--------------|---------|
| **Prowlarr → Sonarr/Radarr/Lidarr** | Prowlarr | Indexer management |
| **Sonarr/Radarr/Lidarr → qBittorrent** | Sonarr/Radarr/Lidarr | Torrent downloads |
| **Sonarr/Radarr/Lidarr → SABnzbd** | Sonarr/Radarr/Lidarr | Usenet downloads |
| **Sonarr/Radarr → Bazarr** | Sonarr/Radarr | Subtitle management |
| **Unpackerr → Sonarr/Radarr** | Unpackerr | Archive extraction |
| **Jellyseerr → Sonarr/Radarr** | Jellyseerr | Content requests |
| **Prowlarr → Flaresolverr** | Prowlarr | CAPTCHA solving (optional) |

---

## Configuration Checklist

### Indexers (Prowlarr)
- [ ] Prowlarr → Sonarr configured
- [ ] Prowlarr → Radarr configured
- [ ] Prowlarr → Lidarr configured (if using)
- [ ] Indexers added in Prowlarr
- [ ] Indexers synced to Sonarr/Radarr/Lidarr

### Download Clients
- [ ] Sonarr → qBittorrent configured
- [ ] Sonarr → SABnzbd configured
- [ ] Radarr → qBittorrent configured
- [ ] Radarr → SABnzbd configured
- [ ] Lidarr → qBittorrent configured (if using)
- [ ] Test downloads work

### Subtitles
- [ ] Sonarr → Bazarr configured
- [ ] Radarr → Bazarr configured
- [ ] Subtitles enabled in Sonarr/Radarr

### Supporting Services
- [ ] Unpackerr → Sonarr/Radarr configured
- [ ] Jellyseerr → Sonarr/Radarr configured (if using)
- [ ] Flaresolverr configured (if needed)

---

## Verification

### Test Indexers
1. **Sonarr/Radarr** → **Settings** → **Indexers**
2. Verify Prowlarr-managed indexers are listed
3. Test search: **Sonarr/Radarr** → **Search** → Test with a show/movie

### Test Download Clients
1. **Sonarr/Radarr** → **Settings** → **Download Clients**
2. Click **Test** on each client
3. Add a test show/movie and verify it downloads

### Test Subtitles
1. **Bazarr UI** → Check subtitle search/management
2. Verify subtitles are being downloaded

---

## Troubleshooting

### Connection Tests Fail

**Common Issues:**
1. **Wrong API Key:** Verify you're using the correct service's API key
2. **DNS Resolution:** Try short DNS (`http://service:port`) instead of full DNS
3. **Wrong Port:** Double-check service ports
4. **SSL/TLS:** Disable SSL for internal Kubernetes DNS connections

### Indexers Not Syncing

1. **Check Prowlarr:** Settings → Apps → Verify Sonarr/Radarr are connected
2. **Sync Level:** Ensure "Sync App Indexers" is enabled
3. **Wait:** Sync can take a few minutes

### Downloads Not Starting

1. **Download Client:** Verify connection test passes
2. **Category:** Ensure category matches (e.g., `tv` for Sonarr)
3. **Paths:** Verify download paths are correct
4. **qBittorrent:** Check if VPN is working (if using)

### Subtitles Not Downloading

1. **Bazarr Connection:** Verify Sonarr/Radarr can connect to Bazarr
2. **Enable Subtitles:** Ensure subtitles are enabled in Sonarr/Radarr settings
3. **Languages:** Check subtitle language settings

---

## Quick Reference: Service URLs

```
Service          Internal URL                          Ingress URL
─────────────────────────────────────────────────────────────────────
Sonarr           http://sonarr:8989                    /sonarr
Radarr           http://radarr:7878                    /radarr
Lidarr           http://lidarr:8686                    /lidarr
Prowlarr         http://prowlarr:9696                  /prowlarr
Bazarr           http://bazarr:6767                    /bazarr
qBittorrent      http://qbittorrent.qbittorrent.svc.cluster.local:8080  /qbittorrent
SABnzbd          http://sabnzbd:8081                   /sabnzbd
Unpackerr        http://unpackerr:9770                 /unpackerr
Jellyseerr       http://jellyseerr:5055                /jellyseerr
Flaresolverr     http://flaresolverr:8191              /flaresolverr
```

---

## API Keys & Authentication Quick Reference

### Services Using API Keys

- **Sonarr/Radarr/Lidarr:** Settings → General → Security → API Key
- **Prowlarr:** Settings → General → Security → API Key
- **Bazarr:** Settings → General → API Key
- **SABnzbd:** Config → General → Security → API Key
- **Jellyseerr:** Settings → Services → [Service] → API Key

### Services Using Username/Password

- **qBittorrent:** **No API key** - uses username/password authentication
  - Get credentials from: qBittorrent UI → Tools → Options → Web UI
  - Default username: `admin`
  - Default password: Check deployment config or UI settings

### Extract All Keys

```bash
# View all API keys (copy and paste this command):
for key in SONARR_API_KEY RADARR_API_KEY LIDARR_API_KEY BAZARR_API_KEY PROWLARR_API_KEY SABNZBD_API_KEY JELLYSEERR_API_KEY; do
  value=$(kubectl get secret starr-secrets -n media -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d 2>/dev/null | grep -oE '[a-f0-9]{32}' | head -1)
  if [ -n "$value" ]; then
    echo "$key: $value"
  else
    echo "$key: (empty)"
  fi
done
```

---

**Last Updated:** 2025-01-27  
**Status:** Complete integration guide
