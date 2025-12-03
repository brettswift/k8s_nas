# Post-Bootstrap, Post Git Sync Configuration

This document covers manual configuration tasks that need to be performed after the cluster is bootstrapped and GitOps has synced all applications.

**When to use this:** After running bootstrap scripts and ensuring ArgoCD has synced all applications from Git.

---

## Prowlarr → Sonarr Indexer Sync

After services are deployed via GitOps, you need to configure Prowlarr to automatically sync indexers to Sonarr.

### Problem

If you delete indexers in Sonarr, or if indexers aren't syncing automatically, you need to configure Prowlarr to manage them.

### Solution: Configure Prowlarr → Sonarr Application

1. **Go to Prowlarr UI:**
   - URL: `https://home.brettswift.com/prowlarr`

2. **Navigate to Settings:**
   - **Settings** → **Apps**

3. **Check if Sonarr is already configured:**
   - If Sonarr is listed:
     - Click **Edit** on the Sonarr application
     - Click **Save** (no changes needed) - this triggers a sync
   - If Sonarr is NOT listed:
     - Click **+ Add Application**
     - Select **Sonarr** from the list

4. **Configure Sonarr Application:**
   - **Name:** `Sonarr` (or leave default)
   - **Sonarr URL:** `http://sonarr:8989`
     - Alternative: `http://sonarr.media.svc.cluster.local:8989`
   - **API Key:** Get from Sonarr
     - Go to **Sonarr**: `https://home.brettswift.com/sonarr`
     - **Settings** → **General** → **Security** → **API Key**
     - Copy the API key
     - ⚠️ **Important:** Use Sonarr's API key, NOT Prowlarr's API key!
   - **Sync Level:** 
     - **Full Sync** ← Recommended (Prowlarr manages all indexers)
     - **Add and Remove Only** ← Use if you want to customize in Sonarr
   - **Sync App Indexers:** ✅ **Enabled**

5. **Test Connection:**
   - Click **Test** button
   - Should show success message

6. **Save:**
   - Click **Save**
   - Prowlarr will immediately sync indexers to Sonarr

### Verify Sync

1. **Go to Sonarr:**
   - URL: `https://home.brettswift.com/sonarr`

2. **Check Indexers:**
   - **Settings** → **Indexers**
   - You should see indexers from Prowlarr automatically listed
   - They will have names matching your Prowlarr indexers (e.g., "NZBGeek")

3. **Test Indexers:**
   - Click the **Test** button on each indexer
   - Should show success (green checkmark)

### Troubleshooting

**Issue: Indexers show "Unable to connect to indexer, invalid credentials"**

- **Cause:** Sonarr is using an old/wrong Prowlarr API key
- **Solution:** 
  1. Check Prowlarr API key in secret:
     ```bash
     kubectl get secret starr-secrets -n media -o jsonpath='{.data.PROWLARR_API_KEY}' | base64 -d && echo
     ```
  2. Verify Prowlarr is using the correct Sonarr API key (not Prowlarr's key)
  3. Re-save the Sonarr application in Prowlarr to trigger a fresh sync

**Issue: Indexers not appearing in Sonarr**

- **Cause:** Prowlarr → Sonarr application not configured, or sync disabled
- **Solution:**
  1. Verify Prowlarr has Sonarr configured as an application
  2. Ensure "Sync App Indexers" is enabled
  3. Check sync level is not "Disabled"
  4. Manually trigger sync by editing and saving the Sonarr application in Prowlarr

**Issue: Indexers deleted in Sonarr, need to re-add**

- **Solution:** Simply edit and save the Sonarr application in Prowlarr (no changes needed) - this triggers a sync and re-adds the indexers

---

## API Key Reference

**Current API Keys (from `starr-secrets` Secret):**

To get current API keys:
```bash
kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d && echo
kubectl get secret starr-secrets -n media -o jsonpath='{.data.PROWLARR_API_KEY}' | base64 -d && echo
```

**Which Key to Use:**

1. **Prowlarr → Sonarr (Adding Sonarr as Application in Prowlarr):**
   - Use: **Sonarr's API Key**
   - Reason: Prowlarr needs to authenticate to Sonarr

2. **Sonarr → Prowlarr (Adding Prowlarr as Indexer in Sonarr):**
   - Use: **Prowlarr's API Key**
   - Reason: Sonarr needs to authenticate to Prowlarr
   - ⚠️ **Note:** This is NOT needed if using Prowlarr's sync feature (recommended)

---

## Internal Service URLs

When configuring services to talk to each other, use these internal URLs:

| Service | Internal URL | Port | Notes |
|---------|--------------|------|-------|
| **Prowlarr** | `http://prowlarr:9696` | 9696 | Not port 80! |
| **Sonarr** | `http://sonarr:8989` | 8989 | Default port |
| **Radarr** | `http://radarr:7878` | 7878 | Default port |
| **SABnzbd** | `http://sabnzbd:8080` | 8080 | URL Base: `/sabnzbd` |

**Important:**
- ✅ Use the **service name** (e.g., `prowlarr`, `sonarr`) - Kubernetes DNS will resolve it
- ✅ Use the **service port** (not port 80 unless the service actually uses it)
- ✅ Use **HTTP** (not HTTPS) for internal cluster communication
- ✅ All services are in the `media` namespace, so short names work fine

---

## qBittorrent Download Path Configuration

After services are deployed, qBittorrent needs to be configured to save downloads to the correct path so Sonarr and Radarr can access them.

### Path Structure

**Volume Mounts:**
- **qBittorrent:** `/downloads` → `/mnt/data/downloads` (host)
- **Sonarr/Radarr:** `/downloads` → `/mnt/data/downloads` (host)

Since both services mount the same host path, they can share the downloads directory directly.

### Configure qBittorrent Download Path

1. **Go to qBittorrent UI:**
   - URL: `https://qbittorrent.home.brettswift.com`

2. **Navigate to Download Settings:**
   - **Tools** → **Options** → **Downloads**

3. **Set Default Save Path:**
   - **Default Save Path:** `/downloads`
   - ⚠️ **Important:** Use `/downloads` (the container path, not the host path)
   - This maps to `/mnt/data/downloads` on the host

4. **Optional - Set Category Paths:**
   - If using categories (e.g., `tv`, `movies`), you can set:
     - **Category:** `tv` → **Save Path:** `/downloads/tv`
     - **Category:** `movies` → **Save Path:** `/downloads/movies`
   - Or leave default and let Sonarr/Radarr organize after download

5. **Save Configuration:**
   - Click **OK** to save

### Configure Sonarr/Radarr Remote Path Mapping

Since qBittorrent and Sonarr/Radarr share the same volume mount (`/downloads` → `/mnt/data/downloads`), you typically **don't need** remote path mappings. However, if Sonarr/Radarr are complaining about paths, verify:

#### In Sonarr:

1. **Settings** → **Download Clients** → **qBittorrent**
2. **Remote Path Mappings:**
   - If needed, add:
     - **Remote Path:** `/downloads` (how qBittorrent sees it)
     - **Local Path:** `/downloads` (how Sonarr sees it - same path!)
   - **Note:** Usually not needed since paths are identical

#### In Radarr:

1. **Settings** → **Download Clients** → **qBittorrent**
2. **Remote Path Mappings:**
   - Same as Sonarr (usually not needed)

### Verify Configuration

1. **Test Download:**
   - Add a test torrent in qBittorrent
   - Verify it downloads to `/downloads` (check qBittorrent UI → Transfers)

2. **Check Sonarr/Radarr:**
   - Go to **Activity** → **Queue**
   - Downloads should appear and be accessible
   - No path errors in logs

3. **Verify File Access:**
   ```bash
   # Check if files are accessible from Sonarr pod
   kubectl exec -n media -it $(kubectl get pods -n media -l app=sonarr -o jsonpath='{.items[0].metadata.name}') -- ls -la /downloads
   ```

### Troubleshooting

**Issue: Sonarr/Radarr can't find downloaded files**

- **Cause:** Path mismatch between qBittorrent and Sonarr/Radarr
- **Solution:**
  1. Verify qBittorrent saves to `/downloads` (not `/data/downloads` or other path)
  2. Verify Sonarr/Radarr have `/downloads` mounted (check deployment)
  3. Add remote path mapping if paths differ:
     - **Remote Path:** `/downloads` (qBittorrent's path)
     - **Local Path:** `/downloads` (Sonarr/Radarr's path)

**Issue: Downloads not moving to media library**

- **Cause:** Root folders not configured or incorrect paths
- **Solution:**
  1. Verify Sonarr root folder: `/data/media/series`
  2. Verify Radarr root folder: `/data/media/movies`
  3. Ensure completed downloads are accessible at `/downloads`

**Issue: Permission errors**

- **Cause:** File ownership/permissions mismatch
- **Solution:**
  1. Verify all services use same PUID/PGID (1000:1000)
  2. Check file permissions:
     ```bash
     ls -la /mnt/data/downloads
     ```
  3. Fix permissions if needed:
     ```bash
     sudo chown -R 1000:1000 /mnt/data/downloads
     ```

---

**Last Updated:** 2025-01-27

