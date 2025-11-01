# Story 1.1b: Fix Service Routing and Path Configuration

Status: completed

## Story

As a system administrator,
I want to fix routing issues with Sabnzbd and Sonarr services and standardize path configurations across all media services,
so that all services are accessible via ingress without redirect loops or white pages, and follow consistent routing patterns.

## Acceptance Criteria

1. **Sabnzbd Routing Fixed:** Sabnzbd accessible at `https://home.brettswift.com/sabnzbd` without double path (`/sabnzbd/sabnzbd`) issues
2. **Sonarr Routing Fixed:** Sonarr accessible at `https://home.brettswift.com/sonarr` and displays full UI content (not white page)
3. **Routing Pattern Standardized:** All media services (Sonarr, Radarr, Sabnzbd, and any others) use consistent ingress routing configuration
4. **Path Base Configuration:** Service config files use consistent UrlBase/path_base settings that align with ingress rewrite rules
5. **Verification:** All fixed services return HTTP 200 with actual UI content when accessed via ingress
6. **Documentation:** Routing patterns documented for future service deployments

## Tasks / Subtasks

- [ ] Task 1: Diagnose and fix Sabnzbd routing issue (AC: #1)
  - [ ] Investigate Sabnzbd double path issue (`/sabnzbd/sabnzbd/wizard`)
  - [ ] Check Sabnzbd config file for url_base setting
  - [ ] Review Sabnzbd ingress configuration for path rewrite issues
  - [ ] Fix config and/or ingress to resolve double path
  - [ ] Test Sabnzbd accessibility via ingress
- [ ] Task 2: Diagnose and fix Sonarr routing issue (AC: #2)
  - [ ] Investigate Sonarr white page issue
  - [ ] Check Sonarr config file for UrlBase setting
  - [ ] Review Sonarr ingress configuration
  - [ ] Fix config to remove UrlBase conflict with ingress
  - [ ] Test Sonarr UI displays correctly via ingress
- [ ] Task 3: Standardize routing patterns across all services (AC: #3, #4)
  - [ ] Review all media service ingress configurations
  - [ ] Identify any services with UrlBase/path_base conflicts
  - [ ] Apply consistent pattern: ingress strips prefix, services serve from root
  - [ ] Update service config files to remove base URL where needed
  - [ ] Verify all services follow same routing pattern
- [ ] Task 4: Verify and document (AC: #5, #6)
  - [ ] Test all media services return HTTP 200 via ingress
  - [ ] Verify services display actual UI content (not redirects or white pages)
  - [ ] Document routing pattern and configuration approach
  - [ ] Update architecture docs with routing standards

## Dev Notes

### Problem Context

Current issues identified:

- **Sabnzbd**: Redirecting to `/sabnzbd/sabnzbd/wizard` (double path prefix)
- **Sonarr**: Displaying white page instead of UI content

Root cause: Conflict between service config files having `<UrlBase>/service</UrlBase>` and ingress rewriting paths to strip the `/service` prefix.

### Architecture Pattern

From [Source: docs/service-routing-issues.md]:

- Ingress uses regex rewrite: `nginx.ingress.kubernetes.io/rewrite-target: /$2`
- Path pattern: `/service(/|$)(.*)` captures service path and content
- Services should serve from root (`/`) with no base URL configured
- Ingress handles path routing, services don't need to know about the prefix

### Implementation Approach

**Option 1 (Recommended):** Remove base URL from service configs

- Edit config files to remove or empty `<UrlBase>` settings
- Let ingress handle all path routing
- Matches deployment comment: "Rely on ingress strip-prefix"

**Services to check/fix:**

- Sabnzbd: Check `sabnzbd.ini` for `url_base` setting
- Sonarr: Check `config.xml` for `<UrlBase>` setting
- Radarr: Check `config.xml` for `<UrlBase>` setting
- Other services: Review for similar issues

### Files to Modify

- Service config files on PVC (accessible via pod or SSH to server)
- Ingress files: `apps/media-services/starr/*-ingress.yaml`
- Documentation: `docs/service-routing-issues.md` (update with resolution)
- Architecture docs: Update routing patterns section

### Testing Strategy

1. Test each service via ingress: `curl -k https://home.brettswift.com/<service>/`
2. Verify HTTP status: Should be 200 (not 307 redirect loop)
3. Verify content: Should see actual UI HTML (not white page)
4. Test browser access: Navigate to service URL and verify full functionality

### References

- [Source: docs/service-routing-issues.md] - Detailed routing issue analysis
- [Source: apps/media-services/starr/sonarr-ingress.yaml] - Sonarr ingress configuration
- [Source: apps/media-services/starr/sabnzbd-ingress.yaml] - Sabnzbd ingress configuration
- [Source: apps/media-services/starr/sabnzbd-deployment.yaml] - Sabnzbd deployment with initContainer config

## Dev Agent Record

### Context Reference

- `docs/stories/1-1b-fix-service-routing-and-path-configuration.context.xml`

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

#### 2025-11-01 - Jellyfin Persistent Storage Fix

1. **Problem Identified:**
   - Jellyfin PVC was using dynamic `local-path` storage with `Delete` reclaim policy
   - Deleting the ApplicationSet caused data loss (database, users, configuration)
   - PV with `Retain` policy got stuck bound to deleted PVC after app deletion

2. **Solution Implemented:**
   - Created static PersistentVolume `jellyfin-config-pv-v2` with `Retain` reclaim policy
   - Configured PV to use hostPath: `/mnt/data/configs/jellyfin` (on RAID-protected disk)
   - Renamed PV from `jellyfin-config-pv` to `jellyfin-config-pv-v2` to avoid binding conflicts with stuck PVs
   - Updated PVC to explicitly bind to new PV via `volumeName` field

3. **Deployment Status:**
   - PV created and bound successfully
   - PVC bound to PV-v2
   - Jellyfin pod running and accessible
   - Database restored from `/mnt/data/configs/jellyfin/data/jellyfin.db` (464KB)

4. **Future Considerations:**
   - If ApplicationSet is deleted and recreated, the PV will persist (Retain policy)
   - If binding conflicts occur, rename PV to new version (e.g., `jellyfin-config-pv-v3`)
   - Database persists at `/mnt/data/configs/jellyfin/data/` (RAID-protected)

### File List

**Modified Files:**

- `apps/media-services/jellyfin/pv.yaml` - Created static PV with Retain policy, renamed to v2
- `apps/media-services/jellyfin/deployment.yaml` - Updated PVC to reference PV-v2 by name
