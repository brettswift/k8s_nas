# Jellyseerr Service Integration Configuration Guide

## Overview

This guide provides step-by-step instructions for configuring Jellyseerr to connect to Sonarr, Radarr, and Jellyfin services.

## Prerequisites

✅ All services verified running:
- Jellyseerr: `jellyseerr.media.svc.cluster.local:5055`
- Sonarr: `sonarr.media.svc.cluster.local:8989`
- Radarr: `radarr.media.svc.cluster.local:7878`
- Jellyfin: `jellyfin.media.svc.cluster.local:80`

✅ API Keys Available:
- Sonarr API Key: Extracted from `starr-secrets` Secret (`SONARR_API_KEY`)
- Radarr API Key: Extracted from `starr-secrets` Secret (`RADARR_API_KEY`)
- Jellyfin API Key: **Needs to be extracted from Jellyfin UI** (see instructions below)

---

## Step 1: Extract API Keys

### Sonarr and Radarr API Keys

These are already stored in the `starr-secrets` Secret. To view them:

```bash
# Sonarr API Key
kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d && echo ""

# Radarr API Key
kubectl get secret starr-secrets -n media -o jsonpath='{.data.RADARR_API_KEY}' | base64 -d && echo ""
```

**Current Values:**
- Sonarr: `aa91f40651d84c2bb03faadc07d9ccbc`
- Radarr: `20c22574260f40d691b1256889ba0216`

### Jellyfin API Key

Jellyfin uses a different API key management system. You need to create or extract an API key:

**Option 1: Extract Existing Key (if available)**
```bash
# Check if Jellyfin has API keys in config
kubectl exec -n media $(kubectl get pods -n media -l app=jellyfin -o jsonpath='{.items[0].metadata.name}') -- cat /config/config/users.xml 2>/dev/null | grep -i apikey || echo "No API keys found in users.xml"
```

**Option 2: Create New API Key via UI (Recommended)**
1. Access Jellyfin UI: `https://home.brettswift.com/jellyfin`
2. Navigate to **Settings** (gear icon) → **API Keys**
3. Click **New API Key**
4. Enter name: `Jellyseerr`
5. Click **Create**
6. **Copy the API key immediately** (it won't be shown again)

---

## Step 2: Access Jellyseerr UI

1. Open browser: `https://home.brettswift.com/jellyseerr`
2. If first-time setup, complete initial configuration:
   - Create admin account
   - Set language and region
   - Complete welcome wizard

---

## Step 3: Configure Sonarr Service

1. In Jellyseerr, navigate to **Settings** → **Services**
2. Click **Add Service** or **+** button
3. Select **Sonarr** from the service list
4. Fill in configuration:
   - **Name:** `Sonarr`
   - **Server URL:** `http://sonarr.media.svc.cluster.local:8989`
     - ⚠️ Use internal Kubernetes Service DNS (not external URL)
   - **API Key:** Paste Sonarr API key from Step 1
     - Value: `aa91f40651d84c2bb03faadc07d9ccbc`
   - **Default Server:** ✅ Enable (if this is your primary Sonarr instance)
   - **Sync Enabled:** ✅ Enable (sync content library)
   - **Sync Interval:** `0` (manual sync) or `360` (every 6 hours)
5. Click **Test** to verify connection
6. If test succeeds (green checkmark), click **Save**

**Expected Result:**
- ✅ Connection test successful
- Sonarr appears in services list
- Jellyseerr can query Sonarr for TV shows

---

## Step 4: Configure Radarr Service

1. In Jellyseerr, navigate to **Settings** → **Services**
2. Click **Add Service** → Select **Radarr**
3. Fill in configuration:
   - **Name:** `Radarr`
   - **Server URL:** `http://radarr.media.svc.cluster.local:7878`
     - ⚠️ Use internal Kubernetes Service DNS (not external URL)
   - **API Key:** Paste Radarr API key from Step 1
     - Value: `20c22574260f40d691b1256889ba0216`
   - **Default Server:** ✅ Enable (if this is your primary Radarr instance)
   - **Sync Enabled:** ✅ Enable (sync content library)
   - **Sync Interval:** `0` or `360`
4. Click **Test** to verify connection
5. If test succeeds, click **Save**

**Expected Result:**
- ✅ Connection test successful
- Radarr appears in services list
- Jellyseerr can query Radarr for movies

---

## Step 5: Configure Jellyfin Service

1. In Jellyseerr, navigate to **Settings** → **Services**
2. Click **Add Service** → Select **Jellyfin**
3. Fill in configuration:
   - **Name:** `Jellyfin`
   - **Server URL:** `http://jellyfin.media.svc.cluster.local:80`
     - ⚠️ Use internal Kubernetes Service DNS (not external URL)
     - ⚠️ Use port `80` (service port, not container port 8096)
   - **API Key:** Paste Jellyfin API key from Step 1
   - **Username:** (optional, if not using API key)
   - **Password:** (optional, if not using API key)
4. Click **Test** to verify connection
5. If test succeeds, click **Save**

**Expected Result:**
- ✅ Connection test successful
- Jellyfin appears in services list
- Jellyseerr can query Jellyfin library for existing content
- Shows existing movies and TV shows in Jellyseerr

---

## Step 6: Verify Service Integration

### Test Sonarr Integration
1. In Jellyseerr, navigate to **Discover** or **Requests**
2. Search for a TV show (e.g., "The Office")
3. Click **Request** on a show
4. Verify the request appears in Sonarr:
   - Access Sonarr UI: `https://home.brettswift.com/sonarr`
   - Navigate to **Wanted** or **Series** page
   - Look for the requested show

### Test Radarr Integration
1. In Jellyseerr, search for a movie
2. Click **Request** on a movie
3. Verify the request appears in Radarr:
   - Access Radarr UI: `https://home.brettswift.com/radarr`
   - Navigate to **Movies** page
   - Look for the requested movie

### Test Jellyfin Integration
1. In Jellyseerr, navigate to **Media** or **Library**
2. Verify existing content from Jellyfin is displayed
3. Check that content availability is synced correctly

---

## Troubleshooting

### Connection Test Fails

**Issue:** "Unable to connect" or "Connection timeout"

**Solutions:**
1. Verify service is running:
   ```bash
   kubectl get pods -n media -l app=sonarr
   kubectl get pods -n media -l app=radarr
   kubectl get pods -n media -l app=jellyfin
   ```

2. Verify service DNS resolves:
   ```bash
   kubectl exec -n media $(kubectl get pods -n media -l app=jellyseerr -o jsonpath='{.items[0].metadata.name}') -- nslookup sonarr.media.svc.cluster.local
   ```

3. Verify API key is correct:
   - Re-extract from secret or UI
   - Check for trailing spaces
   - Ensure key is complete

4. Verify port number:
   - Sonarr: `8989`
   - Radarr: `7878`
   - Jellyfin: `80` (service port, not 8096)

### API Key Invalid

**Issue:** "Unauthorized" or "Invalid API key"

**Solutions:**
1. Re-extract API key from service UI:
   - Sonarr: Settings → General → Security → API Key
   - Radarr: Settings → General → Security → API Key
   - Jellyfin: Settings → API Keys → Copy key

2. Verify key hasn't been regenerated
3. Create new API key if needed

### Service Not Found in Jellyseerr

**Issue:** Service doesn't appear in Jellyseerr after configuration

**Solutions:**
1. Refresh Jellyseerr page
2. Check service is saved (not just tested)
3. Verify service is enabled in Jellyseerr settings
4. Check Jellyseerr logs:
   ```bash
   kubectl logs -n media -l app=jellyseerr --tail=50
   ```

---

## Service URLs Reference

| Service | Internal DNS | External URL | Port |
|---------|--------------|--------------|------|
| Jellyseerr | `jellyseerr.media.svc.cluster.local:5055` | `https://home.brettswift.com/jellyseerr` | 5055 |
| Sonarr | `sonarr.media.svc.cluster.local:8989` | `https://home.brettswift.com/sonarr` | 8989 |
| Radarr | `radarr.media.svc.cluster.local:7878` | `https://home.brettswift.com/radarr` | 7878 |
| Jellyfin | `jellyfin.media.svc.cluster.local:80` | `https://home.brettswift.com/jellyfin` | 80 |

**⚠️ Important:** Always use **internal DNS** (`*.media.svc.cluster.local`) when configuring services in Jellyseerr, not external URLs. This ensures services communicate within the Kubernetes cluster network.

---

## Next Steps

After completing this configuration:
1. Test end-to-end workflow: Request → Sonarr/Radarr → Download → Jellyfin
2. Verify content requests appear in Sonarr/Radarr
3. Verify content becomes available in Jellyfin after download
4. Configure user permissions in Jellyseerr if needed
5. Set up notification settings for request approvals

---

## Related Documentation

- [CONFIGURE_STARR_INTEGRATIONS.md](../CONFIGURE_STARR_INTEGRATIONS.md#Part-5) - Part 5: Content Requests (Jellyseerr)
- Story 1.7: Configure Jellyseerr Service Integration

