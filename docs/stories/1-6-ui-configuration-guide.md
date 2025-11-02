# Story 1.6 UI Configuration Guide

**Story:** Configure Media Root Folders  
**Status:** Infrastructure changes complete - UI configuration required

## Completed Infrastructure Changes

✅ **Deployment Updates:**
- Added `/usenet` volume mount to Sonarr and Radarr deployments
- Changed `/data` mount from `/mnt/data/media` to `/mnt/data` to support `/data/media/*` paths
- Committed and pushed to `dev_starr` branch
- ArgoCD will sync automatically and restart pods

## Required Manual Steps

### Step 1: Create Root Folder Directories

**Host:** Run this script on the server at IP `10.0.0.20` (the Kubernetes node where `/mnt/data` is mounted)

**SSH to the host:**
```bash
ssh user@10.0.0.20  # or however you access the server
```

**Then run the script:**
```bash
cd /path/to/k8s_nas/repo  # navigate to repo directory
./scripts/create-media-root-folders.sh
```

Or manually:

```bash
sudo mkdir -p /mnt/data/media/series /mnt/data/media/movies
sudo chown -R 1000:1000 /mnt/data/media/series /mnt/data/media/movies
sudo chmod 755 /mnt/data/media/series /mnt/data/media/movies
```

**Verify:** Wait for ArgoCD to sync and pods to restart, then run:
```bash
./scripts/verify-media-root-config.sh
```

### Step 2: Fix SABnzbd Folder Configuration

**Updated Configuration (via deployment):**
- Temporary Download Folder: `/data/usenet/incomplete`
- Completed Download Folder: `/data/usenet/complete` (simplified - no nested `/complete/complete`)

**Note:** The deployment init container now automatically configures these paths. After pods restart, verify in UI:

1. Access SABnzbd UI: `https://home.brettswift.com/sabnzbd`
2. Navigate to **Config** → **Folders**
3. Verify settings match:
   - **Temporary Download Folder:** `/data/usenet/incomplete`
   - **Completed Download Folder:** `/data/usenet/complete`
4. If they don't match, update them manually and **Save**

### Step 3: Configure Sonarr Root Folder

1. Access Sonarr UI: `https://home.brettswift.com/sonarr`
2. Navigate to **Settings** → **Media Management** → **Root Folders**
3. Remove any existing root folders (if incorrectly configured)
4. Click **+ Add** to add new root folder
5. Enter path: `/data/media/series`
6. Click **Save**
7. Verify no errors appear
8. Check **System** → **Status** - error "Missing root folder: /data/media/series" should be cleared

### Step 4: Configure Radarr Root Folder

1. Access Radarr UI: `https://home.brettswift.com/radarr`
2. Navigate to **Settings** → **Media Management** → **Root Folders**
3. Remove any existing root folders (if incorrectly configured)
4. Click **+ Add** to add new root folder
5. Enter path: `/data/media/movies`
6. Click **Save**
7. Verify no errors appear
8. Check **System** → **Status** - errors "Missing root folder: /data/media/movies" should be cleared

### Step 5: Fix SABnzbd Remote Path Mappings

**Note:** After fixing SABnzbd folders, the completed folder is now `/data/usenet/complete` (simplified).

#### In Sonarr:

1. Navigate to **Settings** → **Download Clients** → **SABnzbd**
2. Scroll to **Remote Path Mappings** section
3. Add or update mapping:
   - **Remote Path:** `/data/usenet/complete` (how SABnzbd sees it - the completed downloads folder)
   - **Local Path:** `/usenet/complete` (how Sonarr sees it after new mount)
   - *Explanation: SABnzbd reports completed downloads in `/data/usenet/complete`, and Sonarr needs to map this to `/usenet/complete` which maps to `/mnt/data/usenet/complete` on the host*
4. Click **Save**
5. Verify error "places downloads in /data/usenet/complete/complete but this directory does not appear to exist" is cleared

#### In Radarr:

1. Navigate to **Settings** → **Download Clients** → **SABnzbd**
2. Scroll to **Remote Path Mappings** section
3. Add or update mapping:
   - **Remote Path:** `/data/usenet/complete` (how SABnzbd sees it - the completed downloads folder)
   - **Local Path:** `/usenet/complete` (how Radarr sees it after new mount)
   - *Explanation: Same as Sonarr - maps SABnzbd's completed folder to accessible path*
4. Click **Save**
5. Verify error "places downloads in /data/usenet/complete/complete but this directory does not exist" is cleared

### Step 6: Verify qBittorrent Path Mappings (if configured)

1. In Sonarr: **Settings** → **Download Clients** → **qBittorrent**
   - Verify download folder is accessible (should be `/downloads` mount point)
2. In Radarr: **Settings** → **Download Clients** → **qBittorrent**
   - Verify download folder is accessible (should be `/downloads` mount point)

### Step 7: Final Verification

1. **Sonarr:** Check **System** → **Status**
   - ✅ No root folder errors
   - ✅ No remote path mapping errors
2. **Radarr:** Check **System** → **Status**
   - ✅ No root folder errors
   - ✅ No remote path mapping errors
   - ✅ Collection errors cleared (if applicable)

2. Run verification script:
```bash
./scripts/verify-media-root-config.sh
```

## Expected Results

After completing all steps:

- ✅ Sonarr root folder: `/data/media/series` configured and accessible
- ✅ Radarr root folder: `/data/media/movies` configured and accessible
- ✅ SABnzbd remote path mapping fixed (no double `/complete` errors)
- ✅ All console errors related to root folders and path mappings cleared
- ✅ Downloads can successfully move to root folders after completion

## Troubleshooting

**If directories are not accessible:**
- Wait for ArgoCD to sync (check with `kubectl get applications -n argocd`)
- Verify pods have restarted: `kubectl get pods -n media -l 'app in (sonarr,radarr)'`
- Check volume mounts: `kubectl describe pod <pod-name> -n media | grep -A 5 "Mounts:"`

**If root folder errors persist:**
- Verify `/data` mount points to `/mnt/data` (not `/mnt/data/media`)
- Verify directories exist on host: `ls -la /mnt/data/media/`
- Check permissions: `ls -ld /mnt/data/media/series /mnt/data/media/movies`

**If remote path mapping errors persist:**
- Verify `/usenet` mount exists: `kubectl get pod <pod-name> -n media -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}'`
- Test access: `kubectl exec -n media <pod-name> -- ls -d /usenet/complete`

