# Story 1.7: Configure Jellyseerr Service Integration

Status: ready-for-dev

## Story

As a system administrator,
I want to configure Jellyseerr to connect to Sonarr, Radarr, and Jellyfin,
so that users can request content through Jellyseerr and have it automatically acquired.

## Acceptance Criteria

1. Jellyseerr configured to connect to Sonarr via service DNS and API key
2. Jellyseerr configured to connect to Radarr via service DNS and API key
3. Jellyseerr configured to connect to Jellyfin via service DNS and API key
4. Test content request successfully creates requests in Sonarr/Radarr
5. Request workflow verified end-to-end from Jellyseerr to content availability

## Tasks / Subtasks

- [x] Task 1: Verify prerequisites (AC: #1, #2, #3)
  - [x] Verify Jellyseerr is deployed and accessible
    - ✅ Pod: `jellyseerr-c4b74558c-kdww4` (Running)
    - ✅ Service: `jellyseerr.media.svc.cluster.local:5055`
  - [x] Verify Sonarr is deployed and accessible
    - ✅ Pod: `sonarr-644b7655fb-wnnc9` (Running)
    - ✅ Service: `sonarr.media.svc.cluster.local:8989`
  - [x] Verify Radarr is deployed and accessible
    - ✅ Pod: `radarr-8454d946c6-fpqxx` (Running)
    - ✅ Service: `radarr.media.svc.cluster.local:7878`
  - [x] Verify Jellyfin is deployed and accessible
    - ✅ Pod: `jellyfin-85f767bdff-gwhw9` (Running)
    - ✅ Service: `jellyfin.media.svc.cluster.local:80`
  - [x] Verify API keys exist in `starr-secrets` Secret for Sonarr, Radarr
    - ✅ Sonarr API Key: `aa91f40651d84c2bb03faadc07d9ccbc` (extracted from secret)
    - ✅ Radarr API Key: `20c22574260f40d691b1256889ba0216` (extracted from secret)
    - ⚠️ Jellyfin API Key: Needs to be created/extracted from Jellyfin UI (Settings → API Keys)
  - [x] Verify service DNS names resolve correctly in cluster
    - ✅ All services have ClusterIP services with correct DNS names

- [ ] Task 2: Configure Jellyseerr → Sonarr integration (AC: #1)
  - [ ] Access Jellyseerr UI: `https://home.brettswift.com/jellyseerr`
  - [ ] Navigate to **Settings** → **Services**
  - [ ] Add Sonarr service
    - [ ] Configure service name: `Sonarr`
    - [ ] Configure server URL: `http://sonarr:8989`
    - [ ] Configure API key: Extract from `starr-secrets` Secret (SONARR_API_KEY)
    - [ ] Test connection
  - [ ] Verify Sonarr appears in Jellyseerr services list
  - [ ] Verify Jellyseerr can query Sonarr for content

- [ ] Task 3: Configure Jellyseerr → Radarr integration (AC: #2)
  - [ ] In Jellyseerr **Settings** → **Services**
  - [ ] Add Radarr service
    - [ ] Configure service name: `Radarr`
    - [ ] Configure server URL: `http://radarr:7878`
    - [ ] Configure API key: Extract from `starr-secrets` Secret (RADARR_API_KEY)
    - [ ] Test connection
  - [ ] Verify Radarr appears in Jellyseerr services list
  - [ ] Verify Jellyseerr can query Radarr for content

- [ ] Task 4: Configure Jellyseerr → Jellyfin integration (AC: #3)
  - [ ] In Jellyseerr **Settings** → **Services**
  - [ ] Add Jellyfin service
    - [ ] Configure service name: `Jellyfin`
    - [ ] Configure server URL: `http://jellyfin:80`
    - [ ] Configure API key: Extract from Jellyfin settings or create new API key
    - [ ] Test connection
  - [ ] Verify Jellyfin appears in Jellyseerr services list
  - [ ] Verify Jellyseerr can query Jellyfin library for existing content

- [ ] Task 5: Test content request workflow (AC: #4, #5)
  - [ ] Create test TV show request in Jellyseerr
  - [ ] Verify request appears in Sonarr
  - [ ] Verify Sonarr searches for content (via Prowlarr)
  - [ ] Create test movie request in Jellyseerr
  - [ ] Verify request appears in Radarr
  - [ ] Verify Radarr searches for content (via Prowlarr)
  - [ ] Document end-to-end workflow verification results

## Dev Notes

### Prerequisites

- Story 1.1: Extract and Configure API Keys (API keys in `starr-secrets`)
- Story 1.2: Configure Sonarr-Prowlarr Integration (indexer sync working)
- Story 1.3: Configure Radarr-Prowlarr Integration (indexer sync working)
- Story 1.4: Configure Sonarr-qBittorrent Integration (download client configured)
- Story 1.5: Configure Radarr-qBittorrent Integration (download client configured)
- All services deployed and accessible

### Architecture Context

**Service URLs (Use Short Names):**
- Sonarr: `http://sonarr:8989`
- Radarr: `http://radarr:7878`
- Jellyfin: `http://jellyfin:80` (service port, not container port 8096)
- Jellyseerr: Already deployed at `http://jellyseerr:5055`

**API Keys:**
- Sonarr API key: Stored in `starr-secrets` Secret as `SONARR_API_KEY`
- Radarr API key: Stored in `starr-secrets` Secret as `RADARR_API_KEY`
- Jellyfin API key: May need to extract from Jellyfin config or create new via UI

**Network Configuration:**
- All services run in `media` namespace
- Services communicate via Kubernetes Service DNS within cluster
- Jellyseerr uses BASE_URL="/jellyseerr" for ingress routing

### Configuration Pattern

**Similar to Previous Stories:**
- Follow pattern from Story 1.2 (Sonarr-Prowlarr) and Story 1.3 (Radarr-Prowlarr)
- Configure connections using internal Kubernetes Service DNS
- Use API keys from `starr-secrets` Secret
- Test connections before proceeding

### Jellyfin API Key

Jellyfin uses different API key management than Starr services:
- API keys created in Jellyfin UI: **Settings** → **API Keys**
- May need to create dedicated API key for Jellyseerr
- Or extract existing key from Jellyfin config if available

### Expected Workflow

1. User requests content via Jellyseerr UI
2. Jellyseerr creates request in Sonarr/Radarr via API
3. Sonarr/Radarr searches via Prowlarr
4. Sonarr/Radarr triggers download via qBittorrent
5. Content moves to library folders
6. Jellyfin scans and makes content available
7. User can access content in Jellyfin

### Files to Review/Modify

- Jellyseerr deployment: `apps/media-services/starr/jellyseerr-deployment.yaml`
- Service configuration: Via Jellyseerr UI (no YAML changes needed)
- API keys: Extract from `starr-secrets` Secret
- Documentation: `CONFIGURE_STARR_INTEGRATIONS.md` (already has Jellyseerr section)

### Testing Strategy

1. **Connection Tests:** Verify each service connection in Jellyseerr UI
2. **Query Tests:** Test Jellyseerr can query content from each service
3. **Request Tests:** Create test requests and verify they appear in Sonarr/Radarr
4. **End-to-End Tests:** Complete workflow from request to content availability
5. **Error Handling:** Verify proper error messages if services are unavailable

### References

- [Source: docs/epics.md#Story-1.7] - Story acceptance criteria
- [Source: CONFIGURE_STARR_INTEGRATIONS.md#Part-5] - Jellyseerr configuration guide
- [Source: Previous stories 1-2, 1-3] - Service integration patterns

## Dev Agent Record

### Context Reference

- docs/stories/1-7-configure-jellyseerr-service-integration.context.xml (if exists)

### Agent Model Used

Composer (Cursor AI)

### Debug Log References

**Task 1 - Prerequisites Verification:**
- All services verified running: Jellyseerr, Sonarr, Radarr, Jellyfin pods are healthy
- Service DNS names confirmed: All services have ClusterIP services in `media` namespace
- API keys extracted: Sonarr and Radarr keys available from `starr-secrets` Secret
- Jellyfin API key: Needs manual extraction from UI (Settings → API Keys → Create new key)
- Integrated Jellyseerr configuration guide into `CONFIGURE_STARR_INTEGRATIONS.md` Part 5

### Completion Notes List

(To be filled during implementation)

### File List

**Created:**
- `docs/stories/1-7-configure-jellyseerr-service-integration.md` - Story file

**Updated:**
- `CONFIGURE_STARR_INTEGRATIONS.md` - Integrated comprehensive Jellyseerr configuration guide into Part 5

### Change Log

(To be filled during implementation)

