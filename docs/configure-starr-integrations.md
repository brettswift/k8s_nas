---
title: Configure Starr Integrations
---

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
| Root Folders | Sonarr/Radarr | **Sonarr/Radarr** → Settings → Media Management → Root Folders |
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
- SABnzbd: `http://sabnzbd:8080/sabnzbd` (short name is whitelisted) or `http://sabnzbd.media.svc.cluster.local:8080/sabnzbd`
- Unpackerr: `http://unpackerr:9770`
- Jellyseerr: `http://jellyseerr:5055`
- Flaresolverr: `http://flaresolverr:8191`

---

## Part 0: Root Folder Configuration (Required First)

**Before configuring download clients or adding content, you must configure root folders in Sonarr and Radarr.**

Root folders define where each service stores its media library. These must be configured before adding any TV shows or movies.

### Configure Sonarr Root Folder

1. **Sonarr UI:** `https://home.brettswift.com/sonarr` → **Settings** → **Media Management** → **Root Folders**
2. Click **+ Add** to add new root folder
3. Enter path: `/data/media/series`
4. Click **Save**
5. Verify no errors appear
6. Check **System** → **Status** - error "Missing root folder: /data/media/series" should be cleared

### Configure Radarr Root Folder

1. **Radarr UI:** `https://home.brettswift.com/radarr` → **Settings** → **Media Management** → **Root Folders**
2. Click **+ Add** to add new root folder
3. Enter path: `/data/media/movies`
4. Click **Save**
5. Verify no errors appear
6. Check **System** → **Status** - errors "Missing root folder: /data/media/movies" should be cleared

### Required Directory Structure

**On the host server (`10.0.0.20`):**
```bash
# Create root folder directories (run on the server):
sudo mkdir -p /mnt/data/media/series /mnt/data/media/movies
sudo chown -R 1000:1000 /mnt/data/media/series /mnt/data/media/movies
sudo chmod 755 /mnt/data/media/series /mnt/data/media/movies
```

Or use the provided script:
```bash
./scripts/create-media-root-folders.sh
```

**Expected folder structure:**
```
/mnt/data/
├── media/
│   ├── series/          # Sonarr root folder → /data/media/series in container
│   └── movies/          # Radarr root folder → /data/media/movies in container
├── downloads/           # qBittorrent downloads
└── usenet/              # SABnzbd downloads
    ├── incomplete/
    └── complete/
```

**Note:** The `/data` volume mount points to `/mnt/data` in the container, so `/data/media/series` in Sonarr maps to `/mnt/data/media/series` on the host.

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

#### Configure SABnzbd Download Folders

**You must configure download folders in SABnzbd before configuring Sonarr/Radarr clients.**

SABnzbd uses its own configured folders - Sonarr/Radarr don't tell it where to download. They only send download requests with categories.

**Folder Configuration:**

1. Access SABnzbd: `https://home.brettswift.com/sabnzbd`
2. **Config** → **Folders**
3. Configure:
   - **Temporary Download Folder:** `/data/usenet/incomplete`
     - *Host path: `/mnt/data/usenet/incomplete`*
   - **Completed Download Folder:** `/data/usenet/complete`
     - *Host path: `/mnt/data/usenet/complete`*
4. **Save**

**Folder Structure:**
```
/mnt/data/
├── media/              # Final media library
├── downloads/          # qBittorrent (torrents)
└── usenet/             # SABnzbd (usenet downloads)
    ├── incomplete/     # Downloads in progress
    └── complete/        # Completed downloads
```

**Note:** SABnzbd has `/data` mounted to `/mnt/data`, so it has access to the `usenet` folder. Sonarr/Radarr have `/downloads` mounted to `/mnt/data/downloads`, so they can't directly access `/mnt/data/usenet`. You'll need to configure path mapping in Sonarr/Radarr (see below).

#### Sonarr → SABnzbd

1. **Sonarr UI** → **Settings** → **Download Clients** → **+ Add Download Client**
2. Select **SABnzbd**
3. **Configure:**
   - **Name:** `SABnzbd`
   - **Host:** `sabnzbd` (short name is in whitelist) or `sabnzbd.media.svc.cluster.local` (full DNS)
   - **Port:** `8080` (not 8081)
   - **URL Base:** `/sabnzbd` ⚠️ **REQUIRED** - Without this, Sonarr will try `http://sabnzbd:8080/api` instead of `http://sabnzbd:8080/sabnzbd/api` and get 403 errors
   - **API Key:** [SABnzbd API key] (use API key from Config → General → Security, not NZB key)
   - **Category:** `tv` (or `sonarr`)
   - ✅ **Use SSL:** No
  - **Remote Path Mapping (Advanced):**
    - **Remote Path:** `/data/usenet/complete` (SABnzbd's completed folder)
    - **Local Path:** `/usenet/complete` (how Sonarr sees it after usenet mount is added)
    - *Note: Requires usenet volume mount in Sonarr deployment (see Path Configuration section below)*
4. **Test** → **Save**

**Path Configuration - Usenet Folder Access:**

**Requirement:** Sonarr/Radarr must be able to access SABnzbd's completed downloads folder.

**Current Setup:**
- SABnzbd saves to `/data/usenet/complete` (host: `/mnt/data/usenet/complete`)
- Sonarr/Radarr have `/data` → `/mnt/data/media` and `/downloads` → `/mnt/data/downloads` mounted
- **Usenet folder access:** Sonarr/Radarr need a mount to access `/mnt/data/usenet`

**Solution:** Add usenet volume mount to Sonarr/Radarr deployments

**Deployment Updates Required:**
1. Edit `apps/media-services/starr/sonarr-deployment.yaml`:
   - Add volume mount in container spec:
     ```yaml
     volumeMounts:
     - name: usenet
       mountPath: /usenet
     ```
   - Add volume definition:
     ```yaml
     volumes:
     - name: usenet
       hostPath:
         path: /mnt/data/usenet
         type: Directory
     ```
2. Apply same changes to `apps/media-services/starr/radarr-deployment.yaml`
3. Commit and push changes
4. ArgoCD will sync and restart pods with new mounts

**Remote Path Mapping Configuration:**
Once usenet mount is added, configure in Sonarr/Radarr:
- **Remote Path:** `/data/usenet/complete` (how SABnzbd sees it)
- **Local Path:** `/usenet/complete` (how Sonarr/Radarr see it after mount)

#### Radarr → SABnzbd

Same steps as Sonarr, but in Radarr:
- **Category:** `movies` (or `radarr`)
- **Remote Path Mapping:** Same as Sonarr (configure Remote Path: `/data/usenet/complete`, Local Path: `/usenet/complete`)

**Important:** Ensure Sonarr/Radarr deployments have usenet volume mount configured (see Path Configuration section above) before setting up remote path mapping.

---

## Part 3: Subtitles (Bazarr)

**Bazarr manages subtitles for Sonarr and Radarr. It needs to be configured in both directions:**
1. **Bazarr → Sonarr/Radarr:** Bazarr monitors libraries and searches for subtitles
2. **Sonarr/Radarr → Bazarr:** Services connect to Bazarr to enable subtitle downloads

### Step 1: Configure Bazarr → Sonarr

1. **Bazarr UI:** `https://home.brettswift.com/bazarr` → **Settings** → **General** → **Sonarr**
2. **Enable:** ✅ **Enabled**
3. **Host:** `sonarr` (or `sonarr.media.svc.cluster.local`)
4. **Port:** `8989`
5. **URL Base:** `/sonarr` (required - Bazarr uses health check endpoint)
6. **API Key:** [Sonarr API key]
7. **Click **Test Connection** → **Save**

### Step 2: Configure Bazarr → Radarr

1. **Bazarr UI** → **Settings** → **General** → **Radarr**
2. **Enable:** ✅ **Enabled**
3. **Host:** `radarr` (or `radarr.media.svc.cluster.local`)
4. **Port:** `7878`
5. **URL Base:** `/radarr` (required - Bazarr uses health check endpoint)
6. **API Key:** [Radarr API key]
7. **Click **Test Connection** → **Save**

### Step 3: Configure Bazarr Media Paths

Bazarr needs access to media files to download subtitles:

1. **Bazarr UI** → **Settings** → **General** → **Paths**
2. **TV Path:** `/data/media/series` (matches Sonarr root folder)
3. **Movie Path:** `/data/media/movies` (matches Radarr root folder)
4. **Save**

**Note:** Bazarr has `/data` mounted to `/mnt/data`, so these paths map correctly to the host.

### Step 4: Get Bazarr API Key

1. **Bazarr UI** → **Settings** → **General** → **Security**
2. Find **API Key** and copy it
3. Update the secret (if needed):
   ```bash
   kubectl create secret generic starr-secrets -n media \
     --from-literal=BAZARR_API_KEY="<your-bazarr-api-key>" \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

### Step 5: Configure Sonarr → Bazarr

1. **Sonarr UI:** `https://home.brettswift.com/sonarr` → **Settings** → **Subtitles**
2. **Enable:** ✅ **Use Subtitles**
3. **Subtitle Languages:** Select your preferred languages (e.g., `en`, `es`)
4. **Add Subtitle Provider:** Click **+** → Select **Bazarr**
5. **Configure:**
   - **Host:** `bazarr` (or `bazarr.media.svc.cluster.local`)
   - **Port:** `6767`
   - **URL Base:** `/bazarr` (required - Bazarr serves on `/bazarr` path)
   - **API Key:** [Bazarr API key]
6. **Test** → **Save**

### Step 6: Configure Radarr → Bazarr

1. **Radarr UI:** `https://home.brettswift.com/radarr` → **Settings** → **Subtitles**
2. **Enable:** ✅ **Use Subtitles**
3. **Subtitle Languages:** Select your preferred languages
4. **Add Subtitle Provider:** Click **+** → Select **Bazarr**
5. **Configure:**
   - **Host:** `bazarr` (or `bazarr.media.svc.cluster.local`)
   - **Port:** `6767`
   - **URL Base:** `/bazarr` (required - Bazarr serves on `/bazarr` path)
   - **API Key:** [Bazarr API key]
6. **Test** → **Save**

### Configure Subtitle Providers in Bazarr

After connecting to Sonarr/Radarr, configure subtitle providers:

1. **Bazarr UI** → **Settings** → **Subtitles** → **Providers**
2. Add subtitle providers (e.g., OpenSubtitles, Subscene)
3. Configure API keys for providers as needed
4. **Save**

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

Jellyseerr enables users to request content via web interface, which automatically creates requests in Sonarr/Radarr.

### Prerequisites

✅ All services verified running:
- Jellyseerr: `jellyseerr.media.svc.cluster.local:5055`
- Sonarr: `sonarr.media.svc.cluster.local:8989`
- Radarr: `radarr.media.svc.cluster.local:7878`
- Jellyfin: `jellyfin.media.svc.cluster.local:80`

✅ API Keys Available:
- Sonarr API Key: Extract from `starr-secrets` Secret or Sonarr UI
- Radarr API Key: Extract from `starr-secrets` Secret or Radarr UI
- Jellyfin API Key: Create/extract from Jellyfin UI

**Extract API Keys:**
```bash
# Sonarr API Key
kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d && echo ""

# Radarr API Key
kubectl get secret starr-secrets -n media -o jsonpath='{.data.RADARR_API_KEY}' | base64 -d && echo ""
```

### Configure Jellyseerr → Sonarr

1. **Jellyseerr UI:** `https://home.brettswift.com/jellyseerr` → **Settings** → **Services**
2. **Add Service** → Select **Sonarr**
3. **Configure:**
   - **Name:** `Sonarr`
   - **Server URL:** `http://sonarr:8989` ⚠️ Use short service name (not full DNS)
   - **API Key:** [Sonarr API key from secret or UI]
   - **Default Server:** ✅ Enable (if this is your primary Sonarr instance)
   - **Sync Enabled:** ✅ Enable (sync content library)
   - **Sync Interval:** `0` (manual sync) or `360` (every 6 hours)
4. **Test** → **Save**

**Expected Result:**
- ✅ Connection test successful
- Sonarr appears in services list
- Jellyseerr can query Sonarr for TV shows

### Configure Jellyseerr → Radarr

1. **Jellyseerr UI** → **Settings** → **Services** → **Add Service** → Select **Radarr**
2. **Configure:**
   - **Name:** `Radarr`
   - **Server URL:** `http://radarr:7878` ⚠️ Use short service name
   - **API Key:** [Radarr API key from secret or UI]
   - **Default Server:** ✅ Enable (if this is your primary Radarr instance)
   - **Sync Enabled:** ✅ Enable (sync content library)
   - **Sync Interval:** `0` or `360`
3. **Test** → **Save**

**Expected Result:**
- ✅ Connection test successful
- Radarr appears in services list
- Jellyseerr can query Radarr for movies

### Configure Jellyseerr → Jellyfin

1. **Jellyseerr UI** → **Settings** → **Services** → **Add Service** → Select **Jellyfin**
2. **Configure:**
   - **Name:** `Jellyfin`
   - **Server URL:** `http://jellyfin:80` ⚠️ Use short service name and service port (not container port 8096)
   - **API Key:** [Jellyfin API key - create in Jellyfin UI: Settings → API Keys → New API Key]
   - **Username:** (optional, if not using API key)
   - **Password:** (optional, if not using API key)
3. **Test** → **Save**

**Get Jellyfin API Key:**
1. Access Jellyfin UI: `https://home.brettswift.com/jellyfin`
2. Navigate to **Settings** (gear icon) → **API Keys**
3. Click **New API Key**
4. Enter name: `Jellyseerr`
5. Click **Create**
6. **Copy the API key immediately** (it won't be shown again)

**Expected Result:**
- ✅ Connection test successful
- Jellyfin appears in services list
- Jellyseerr can query Jellyfin library for existing content
- Shows existing movies and TV shows in Jellyseerr

### Test Integration

#### Test Sonarr Integration
1. In Jellyseerr, navigate to **Discover** or **Requests**
2. Search for a TV show (e.g., "The Office")
3. Click **Request** on a show
4. Verify the request appears in Sonarr:
   - Access Sonarr UI: `https://home.brettswift.com/sonarr`
   - Navigate to **Wanted** or **Series** page
   - Look for the requested show

#### Test Radarr Integration
1. In Jellyseerr, search for a movie
2. Click **Request** on a movie
3. Verify the request appears in Radarr:
   - Access Radarr UI: `https://home.brettswift.com/radarr`
   - Navigate to **Movies** page
   - Look for the requested movie

#### Test Jellyfin Integration
1. In Jellyseerr, navigate to **Media** or **Library**
2. Verify existing content from Jellyfin is displayed
3. Check that content availability is synced correctly

### Troubleshooting

#### Connection Test Fails

**Issue:** "Unable to connect" or "Connection timeout"

**Solutions:**
1. Verify service is running:
   ```bash
   kubectl get pods -n media -l app=sonarr
   kubectl get pods -n media -l app=radarr
   kubectl get pods -n media -l app=jellyfin
   ```

2. Verify service DNS resolves (test from Jellyseerr pod):
   ```bash
   kubectl exec -n media $(kubectl get pods -n media -l app=jellyseerr -o jsonpath='{.items[0].metadata.name}') -- nslookup sonarr
   ```

3. Verify API key is correct:
   - Re-extract from secret or UI
   - Check for trailing spaces
   - Ensure key is complete

4. Verify port number:
   - Sonarr: `8989`
   - Radarr: `7878`
   - Jellyfin: `80` (service port, not 8096)

#### API Key Invalid

**Issue:** "Unauthorized" or "Invalid API key"

**Solutions:**
1. Re-extract API key from service UI:
   - Sonarr: Settings → General → Security → API Key
   - Radarr: Settings → General → Security → API Key
   - Jellyfin: Settings → API Keys → Copy key

2. Verify key hasn't been regenerated
3. Create new API key if needed

#### Service Not Found in Jellyseerr

**Issue:** Service doesn't appear in Jellyseerr after configuration

**Solutions:**
1. Refresh Jellyseerr page
2. Check service is saved (not just tested)
3. Verify service is enabled in Jellyseerr settings
4. Check Jellyseerr logs:
   ```bash
   kubectl logs -n media -l app=jellyseerr --tail=50
   ```

**Note:** Jellyseerr enables users to request content via web interface. Once configured, requests automatically create entries in Sonarr/Radarr for content acquisition.

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

### Root Folders (Required First)
- [ ] Sonarr root folder configured: `/data/media/series`
- [ ] Radarr root folder configured: `/data/media/movies`
- [ ] Root folder directories created on host (`/mnt/data/media/series` and `/mnt/data/media/movies`)
- [ ] No root folder errors in Sonarr/Radarr System → Status

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

### SABnzbd 403 Forbidden Error

**Error:** `Unable to connect to SABnzbd, HTTP request failed: [403:Forbidden]`

**Common Causes:**
1. **Missing URL Base:** Sonarr is calling `http://sabnzbd:8080/api` instead of `http://sabnzbd:8080/sabnzbd/api`
   - **Fix:** Set **URL Base** to `/sabnzbd` in Sonarr's SABnzbd client settings
2. **Hostname not whitelisted:** SABnzbd hostname whitelist doesn't include the hostname being used
   - **Fix:** Restart SABnzbd pod: `kubectl rollout restart deployment sabnzbd -n media`
   - Verify whitelist: Check SABnzbd config includes `sabnzbd` and `sabnzbd.media.svc.cluster.local`
3. **Wrong API Key:** Using NZB key instead of API key
   - **Fix:** Use the **API Key** from SABnzbd → Config → General → Security (not the NZB key)

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
SABnzbd          http://sabnzbd.media.svc.cluster.local:8080/sabnzbd  /sabnzbd
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

