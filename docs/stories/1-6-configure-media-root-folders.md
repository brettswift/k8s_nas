# Story 1.6: Configure Media Root Folders

Status: ready-for-dev

## Story

As a system administrator,
I want to configure root folders for Sonarr and Radarr and fix download path mappings,
so that downloaded content is organized correctly in the media library and all console errors are resolved.

## Acceptance Criteria

1. Sonarr root folder configured to `/data/media/series` (matches error requirement)
2. Radarr root folder configured to `/data/media/movies` (matches error requirement)
3. Root folder directories exist on host path (`/mnt/data/media/series` and `/mnt/data/media/movies`)
4. Services have write permissions to root folder directories
5. SABnzbd download path mapping fixed (remove double `/complete` - should be `/data/usenet/complete` not `/data/usenet/complete/complete`)
6. qBittorrent download path mapping configured correctly for both Sonarr and Radarr
7. All console errors resolved:
   - Missing root folder errors cleared
   - Remote path mapping errors cleared
   - Download clients can successfully move content to root folders

## Tasks / Subtasks

- [x] Task 1: Validate and configure usenet folder access (AC: #5)
  - [x] Verify current volume mounts in Sonarr/Radarr deployments
  - [x] Check if Sonarr/Radarr can already access `/mnt/data/usenet` through existing mounts
  - [x] If not accessible: Add usenet volume mount to Sonarr/Radarr deployments
    - [x] Add volume mount: `/usenet` → `/mnt/data/usenet` (or verify existing access path)
    - [x] Update deployment files: `apps/media-services/starr/sonarr-deployment.yaml` and `radarr-deployment.yaml`
    - [x] Commit and push changes for ArgoCD sync
    - [ ] Verify mounts are active after pod restart
  - [ ] Test access: `kubectl exec` into Sonarr pod and verify `/usenet/complete` is accessible (or whatever path works)
  - [ ] Document the correct path for remote path mapping

- [ ] Task 2: Create root folder directories on host (AC: #3, #4)
  - [ ] Verify `/mnt/data/media` exists
  - [ ] Create `/mnt/data/media/series` directory (or `/mnt/data/media/media/series` if using nested structure)
  - [ ] Create `/mnt/data/media/movies` directory (or `/mnt/data/media/media/movies` if using nested structure)
  - [ ] Verify permissions (should be owned by PUID:PGID 1000:1000)
  - [ ] Test write access from Sonarr/Radarr pods
  - [x] Created helper script: `scripts/create-media-root-folders.sh` for directory creation

- [ ] Task 3: Fix SABnzbd folder configuration (AC: #5)
  - [ ] Access SABnzbd UI: `https://home.brettswift.com/sabnzbd`
  - [ ] Navigate to **Config** → **Folders**
  - [ ] Verify **Completed Download Folder** is set to `/data/usenet/complete` (not `/data/usenet/complete/complete`)
  - [ ] Verify **Temporary Download Folder** is set to `/data/usenet/incomplete`
  - [ ] Check if SABnzbd has a subfolder structure causing double `/complete`
  - [ ] Fix any category-specific folder settings that might be adding extra paths
  - [ ] Save configuration

- [ ] Task 4: Configure Sonarr root folder (AC: #1)
  - [ ] Access Sonarr UI: `https://home.brettswift.com/sonarr`
  - [ ] Navigate to **Settings** → **Media Management** → **Root Folders**
  - [ ] Remove any existing root folders (if incorrectly configured)
  - [ ] Add root folder: `/data/media/series`
  - [ ] Verify folder is accessible and writable
  - [ ] Save configuration
  - [ ] Verify console error "Missing root folder: /data/media/series" is cleared

- [ ] Task 5: Configure Radarr root folder (AC: #2)
  - [ ] Access Radarr UI: `https://home.brettswift.com/radarr`
  - [ ] Navigate to **Settings** → **Media Management** → **Root Folders**
  - [ ] Remove any existing root folders (if incorrectly configured)
  - [ ] Add root folder: `/data/media/movies`
  - [ ] Verify folder is accessible and writable
  - [ ] Save configuration
  - [ ] Verify console error "Missing root folder: /data/media/movies" is cleared
  - [ ] Verify collection errors are cleared (Wild Robot Collection, etc.)

- [ ] Task 6: Fix SABnzbd remote path mappings in Sonarr and Radarr (AC: #5)
  - [ ] Access Sonarr → **Settings** → **Download Clients** → SABnzbd
  - [ ] Check **Remote Path Mapping**:
    - **Remote Path:** `/data/usenet/complete` (SABnzbd's completed folder as SABnzbd sees it)
    - **Local Path:** `/usenet/complete` (how Sonarr sees it after usenet mount is added in Task 1)
      - *After usenet mount is added: `/usenet` → `/mnt/data/usenet`, so `/usenet/complete` = `/mnt/data/usenet/complete` ✓*
  - [ ] Access Radarr → **Settings** → **Download Clients** → SABnzbd
  - [ ] Apply same fix for Radarr remote path mapping (Remote: `/data/usenet/complete`, Local: `/usenet/complete`)
  - [ ] Verify console error "places downloads in /data/usenet/complete/complete but this directory does not appear to exist" is cleared

- [ ] Task 7: Verify qBittorrent path mappings (AC: #6)
  - [ ] Verify qBittorrent download folder configuration
  - [ ] Check Sonarr qBittorrent client settings for correct path mappings
  - [ ] Check Radarr qBittorrent client settings for correct path mappings
  - [ ] Ensure completed downloads are accessible to both services

- [ ] Task 8: Verify all errors cleared (AC: #7)
  - [ ] Check Sonarr System → Status (no root folder errors)
  - [ ] Check Radarr System → Status (no root folder errors)
  - [ ] Verify no remote path mapping errors
  - [ ] Test that downloads can successfully move to root folders
  - [ ] Document any remaining errors (indexer errors are separate issue)

## Dev Notes

### Prerequisites

- Story 1.4: Sonarr-qBittorrent integration
- Story 1.5: Radarr-qBittorrent integration
- SABnzbd configured as download client for both Sonarr and Radarr
- Services deployed and accessible

### Architecture Context

**Current Volume Mounts:**
- Sonarr/Radarr: `/data` → `/mnt/data/media` (hostPath)
- Sonarr/Radarr: `/downloads` → `/mnt/data/downloads` (hostPath)
- SABnzbd: `/data` → `/mnt/data` (hostPath - has access to both media and usenet)

**Usenet Access Strategy:**
- SABnzbd saves to `/data/usenet/complete` (host: `/mnt/data/usenet/complete`)
- Sonarr/Radarr need to access `/mnt/data/usenet/complete` to import files
- **Solution:** Add usenet volume mount to Sonarr/Radarr deployments
  - Add volume: `usenet` with hostPath `/mnt/data/usenet`
  - Mount at: `/usenet` in container
  - This gives Sonarr/Radarr access to `/usenet/complete` = `/mnt/data/usenet/complete`
- **Validation Required:** Verify if existing mounts already provide access, or if new mount is needed

**Expected Folder Structure on Host:**
```
/mnt/data/
├── media/
│   ├── series/          # Sonarr root folder
│   └── movies/          # Radarr root folder
├── downloads/           # qBittorrent downloads
└── usenet/              # SABnzbd downloads
    ├── incomplete/
    └── complete/
```

**Container Path Mapping:**
- Sonarr/Radarr see `/data` = `/mnt/data/media` on host
- So `/data/media/series` in Sonarr = `/mnt/data/media/media/series` ❌ (WRONG)
- Should be: `/data/series` = `/mnt/data/media/series` ✓

**BUT:** Errors specifically say `/data/media/series` and `/data/media/movies`, so services expect this path structure. This means:
- Either change services to use `/data/series` and `/data/movies`
- OR create nested structure: `/mnt/data/media/media/series` and `/mnt/data/media/media/movies`
- OR change volume mount to `/mnt/data` instead of `/mnt/data/media`

**Recommended Approach:** 
Since errors specify `/data/media/series` and `/data/media/movies`, and current mount is `/data` → `/mnt/data/media`, we should create the nested structure OR update mount. Checking actual service expectations first.

### Console Errors to Fix

**Sonarr Errors:**
1. `Missing root folder: /data/media/series`
2. `Remote download client SABnzbd places downloads in /data/usenet/complete/complete but this directory does not appear to exist`
3. `No indexers available` (separate issue - Prowlarr sync)

**Radarr Errors:**
1. `Missing root folder: /data/media/movies`
2. `Missing root folder for movie collection: /data/media/movies` (multiple collections listed)
3. `Remote download client SABnzbd places downloads in /data/usenet/complete/complete but this directory does not exist`
4. `No indexers available` (separate issue - Prowlarr sync)

### SABnzbd Path Issue

The error shows `/data/usenet/complete/complete` - this suggests:
1. SABnzbd might have category-specific subfolders enabled
2. Path mapping might be incorrectly concatenating paths
3. SABnzbd completed folder might be nested

**Solution:**
- Check SABnzbd category settings
- Verify completed folder is `/data/usenet/complete` not `/data/usenet/complete/complete`
- Fix remote path mapping in Sonarr/Radarr to match actual SABnzbd structure

### Files to Review/Modify

- Volume mounts: `apps/media-services/starr/sonarr-deployment.yaml`, `apps/media-services/starr/radarr-deployment.yaml`
- SABnzbd config: Via UI or `/config/sabnzbd.ini` in pod
- Root folders: Configured via Sonarr/Radarr UI
- Path mappings: Configured via Sonarr/Radarr download client settings

### Testing Strategy

1. **Directory Creation:** Verify directories exist and are accessible
2. **Root Folder Test:** Add root folder in Sonarr/Radarr and verify no errors
3. **Path Mapping Test:** Verify SABnzbd remote path mapping resolves correctly
4. **Download Test:** Trigger test download and verify content moves to correct root folder
5. **Error Verification:** Check System → Status in both services - all folder errors should be cleared

### References

- [Source: docs/epics.md#Story-1.6] - Story acceptance criteria
- [Source: CONFIGURE_STARR_INTEGRATIONS.md] - SABnzbd configuration guide
- [Source: Current console errors from Sonarr/Radarr] - Specific errors to resolve

## Dev Agent Record

### Context Reference

- docs/stories/1-6-configure-media-root-folders.context.xml

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

