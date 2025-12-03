# Configure Usenet Provider and NZB Indexers

This guide explains how to configure your `news.newshosting.com` Usenet provider subscription in SABnzbd and how to add NZB indexers in Prowlarr.

---

## Understanding the Components

### Usenet Provider (news.newshosting.com)
- **What it is:** A Usenet server that stores binary files (movies, TV shows, music, etc.)
- **Where it goes:** Configured in **SABnzbd** (the downloader)
- **What you need:** Server hostname, port, username, password from your subscription
- **Purpose:** SABnzbd connects to this server to download files

### NZB Indexer (e.g., NZBGeek, NZBPlanet, DrunkenSlug)
- **What it is:** A search engine that finds content on Usenet and provides `.nzb` files
- **Where it goes:** Configured in **Prowlarr** (the indexer manager)
- **What you need:** Indexer URL, API key (from the indexer website)
- **Purpose:** Prowlarr searches these indexers when Sonarr/Radarr request content

### How They Work Together

```
Sonarr/Radarr → Prowlarr → NZB Indexer → Returns .nzb file
                                                      ↓
Sonarr/Radarr → SABnzbd → Usenet Provider → Downloads actual files
```

---

## Step 1: Configure Usenet Provider in SABnzbd

### Access SABnzbd
- **URL:** `https://home.brettswift.com/sabnzbd`
- **Default credentials:** Check your deployment config or reset if needed

### Add Usenet Server (news.newshosting.com)

1. **SABnzbd UI** → **Config** → **Servers**
2. Click **+ Add Server** (or edit existing if one is configured)
3. **Configure:**
   - **Description:** `Newshosting` (or any name you prefer)
   - **Host:** `news.newshosting.com`
   - **Port:** `563` (SSL) or `119` (non-SSL)
     - ⚠️ **Recommended:** Use `563` with SSL enabled
   - **Username:** [Your Newshosting username]
   - **Password:** [Your Newshosting password]
   - ✅ **Enable:** Checked
   - ✅ **SSL:** Checked (if using port 563)
   - **Connections:** `8-20` (check your subscription limits)
     - Most subscriptions allow 8-20 connections
   - **Retention:** Leave default or set to match your subscription
   - **Priority:** `0` (normal priority)
4. Click **Test Server** to verify connection
5. Click **Save**

### Verify Server Status

1. **SABnzbd UI** → **Status** → **Server Status**
2. You should see:
   - Server name: `Newshosting`
   - Status: `Connected`
   - Articles: `Available`
   - Speed: Connection speed

---

## Step 2: Add NZB Indexers in Prowlarr

### Access Prowlarr
- **URL:** `https://home.brettswift.com/prowlarr`
- **Default credentials:** Check your deployment config or reset if needed

### Add an NZB Indexer

1. **Prowlarr UI** → **Indexers** → **+ Add Indexer**
2. **Select Indexer Type:**
   - Common options:
     - **NZBGeek** (popular, paid)
     - **NZBPlanet** (popular, paid)
     - **DrunkenSlug** (popular, paid)
     - **NZB.su** (paid)
     - **DOGnzb** (paid)
     - **nzbindex.com** (free, limited)
     - **Binsearch** (free, limited)
3. **Configure Indexer:**
   - **Name:** `NZBGeek` (or indexer name)
   - **Enable RSS:** ✅ (recommended)
   - **Enable Automatic Search:** ✅ (recommended)
   - **Enable Interactive Search:** ✅ (recommended)
   - **Priority:** `25` (default, lower = higher priority)
   - **API Key:** [Your indexer API key]
     - ⚠️ **Get this from the indexer's website** (usually in Account → API Key)
   - **Base URL:** Usually auto-filled, but verify it's correct
   - **Categories:** Leave default or customize
4. Click **Test** to verify connection
5. Click **Save**

### Popular NZB Indexers

| Indexer | Type | Cost | Notes |
|---------|------|------|-------|
| **NZBGeek** | Paid | ~$15/year | Very popular, good retention |
| **NZBPlanet** | Paid | ~$10/year | Good for older content |
| **DrunkenSlug** | Paid | ~$10/year | Popular, good community |
| **NZB.su** | Paid | ~$10/year | Reliable |
| **DOGnzb** | Paid | ~$10/year | Good retention |
| **nzbindex.com** | Free | Free | Limited, good for testing |
| **Binsearch** | Free | Free | Limited, good for testing |

**Note:** Free indexers are limited and may not work well with automation. Paid indexers are recommended for reliable automation.

---

## Step 3: Configure Prowlarr → SABnzbd Integration

Prowlarr needs to know about SABnzbd so it can send download requests.

### Add SABnzbd as Download Client in Prowlarr

1. **Prowlarr UI** → **Settings** → **Download Clients** → **+ Add Download Client**
2. Select **SABnzbd**
3. **Configure:**
   - **Name:** `SABnzbd`
   - **Host:** `sabnzbd` (or `sabnzbd.media.svc.cluster.local`)
   - **Port:** `8080`
   - **URL Base:** `/sabnzbd` ⚠️ **REQUIRED**
   - **API Key:** [SABnzbd API key]
     - **Get SABnzbd API Key:**
       1. Go to **SABnzbd**: `https://home.brettswift.com/sabnzbd`
       2. **Config** → **General** → Scroll to **Security** section
       3. Copy the **API Key**
   - **Category:** Leave empty or set to `prowlarr`
   - ✅ **Use SSL:** No (internal cluster communication)
4. Click **Test** to verify connection
5. Click **Save**

**Note:** Use `http://sabnzbd:8080` (not port 80). The service port is 8080.

---

## Step 4: Configure Prowlarr → Sonarr/Radarr Integration

This allows Sonarr/Radarr to automatically use indexers from Prowlarr.

### Add Sonarr as Application in Prowlarr

1. **Prowlarr UI** → **Settings** → **Apps** → **+ Add Application**
2. Select **Sonarr**
3. **Configure:**
   - **Name:** `Sonarr`
   - **Sonarr URL:** `http://sonarr:8989` (or `http://sonarr.media.svc.cluster.local:8989`)
   - **API Key:** [Sonarr's API key] ⚠️ **NOT Prowlarr's API key!**
     - **Get Sonarr API Key:**
       1. Go to **Sonarr**: `https://home.brettswift.com/sonarr`
       2. **Settings** → **General** → **Security** → **API Key**
       3. Copy the API key
   - **Sync Level:** 
     - **Full Sync** ← Recommended (Prowlarr manages all indexers)
     - **Add and Remove Only** ← Use if you want to customize in Sonarr
   - ✅ **Sync App Indexers:** Enabled
4. Click **Test** to verify connection
5. Click **Save**

### Add Radarr as Application in Prowlarr

Same steps as Sonarr, but:
- **Name:** `Radarr`
- **Radarr URL:** `http://radarr:7878` (or `http://radarr.media.svc.cluster.local:7878`)
- **API Key:** [Radarr's API key]

---

## Step 5: Verify Everything Works

### Test Usenet Provider (SABnzbd)

1. **SABnzbd UI** → **Status** → **Server Status**
2. Verify server shows **Connected**
3. Try a manual download:
   - **SABnzbd UI** → **+ Add** → Paste an `.nzb` file URL or upload an `.nzb` file
   - Watch it download

### Test NZB Indexer (Prowlarr)

1. **Prowlarr UI** → **Indexers**
2. Verify your indexer shows:
   - **Status:** Green checkmark
   - **Categories:** Listed
3. **Test Search:**
   - **Prowlarr UI** → **Search** → Enter a search term
   - Verify results appear

### Test Full Integration

1. **Sonarr/Radarr UI** → **Settings** → **Indexers**
2. You should see indexers from Prowlarr automatically synced
3. **Test a search:**
   - **Sonarr UI** → **Search** → Search for a TV show
   - **Radarr UI** → **Search** → Search for a movie
   - Verify results appear and downloads start in SABnzbd

---

## Troubleshooting

### SABnzbd: Server Connection Failed

**Possible causes:**
- Incorrect username/password
- Wrong port (use 563 for SSL, 119 for non-SSL)
- SSL enabled but using non-SSL port (or vice versa)
- Firewall blocking connection

**Solutions:**
1. Verify credentials in your Newshosting account
2. Try port 563 with SSL enabled
3. Check SABnzbd logs: **Status** → **Logs**

### Prowlarr: Indexer Test Failed

**Possible causes:**
- Invalid API key
- Indexer website is down
- Rate limiting

**Solutions:**
1. Verify API key on indexer's website
2. Check indexer status page
3. Wait a few minutes and try again

### Prowlarr: SABnzbd Connection Failed

**Possible causes:**
- Wrong URL Base (must be `/sabnzbd`)
- Incorrect API key
- Wrong host/port

**Solutions:**
1. Verify URL Base is `/sabnzbd`
2. Get fresh API key from SABnzbd
3. Try full DNS: `sabnzbd.media.svc.cluster.local`

### Sonarr/Radarr: No Indexers Found

**Possible causes:**
- Prowlarr not syncing
- Wrong API key in Prowlarr
- Sync Level misconfigured

**Solutions:**
1. Verify Prowlarr → Sonarr/Radarr connection test passes
2. Use **Full Sync** in Prowlarr
3. Check Prowlarr logs: **System** → **Logs**

---

## Summary

### What Goes Where

| Component | Where to Configure | What You Need |
|-----------|-------------------|---------------|
| **Usenet Provider** (news.newshosting.com) | **SABnzbd** → Config → Servers | Hostname, port, username, password |
| **NZB Indexer** (e.g., NZBGeek) | **Prowlarr** → Indexers | Indexer URL, API key |
| **SABnzbd Integration** | **Prowlarr** → Settings → Download Clients | SABnzbd URL, API key |
| **Sonarr/Radarr Integration** | **Prowlarr** → Settings → Apps | Sonarr/Radarr URL, API key |

### Quick Reference URLs

#### External URLs (Browser Access)
- **SABnzbd:** `https://home.brettswift.com/sabnzbd`
- **Prowlarr:** `https://home.brettswift.com/prowlarr`
- **Sonarr:** `https://home.brettswift.com/sonarr`
- **Radarr:** `https://home.brettswift.com/radarr`

#### Internal Service URLs (For Service-to-Service Configuration)
All services are in the `media` namespace. Use these URLs when configuring services to talk to each other:

| Service | Internal URL | Port | Notes |
|---------|--------------|------|-------|
| **Prowlarr** | `http://prowlarr:9696` | 9696 | Not port 80! |
| **SABnzbd** | `http://sabnzbd:8080` | 8080 | URL Base: `/sabnzbd` |
| **Sonarr** | `http://sonarr:8989` | 8989 | Default port |
| **Radarr** | `http://radarr:7878` | 7878 | Default port |
| **Lidarr** | `http://lidarr:8686` | 8686 | Default port |
| **Jellyseerr** | `http://jellyseerr:5055` | 5055 | Default port |

**Important:** 
- ✅ Use the **service name** (e.g., `prowlarr`, `sabnzbd`) - Kubernetes DNS will resolve it
- ✅ Use the **service port** (not port 80 unless the service actually uses it)
- ✅ Use **HTTP** (not HTTPS) for internal cluster communication
- ✅ All services are in the `media` namespace, so short names work fine

---

**Last Updated:** 2025-12-01

