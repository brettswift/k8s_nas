# Story 1.4: Configure Sonarr-qBittorrent Integration

Status: done

## Story

As a system administrator,
I want to configure Sonarr to use qBittorrent as its download client through VPN,
so that TV show downloads are automatically managed and routed through secure VPN connection.

## Acceptance Criteria

1. Sonarr configured to connect to qBittorrent via Kubernetes Service DNS (`qbittorrent.qbittorrent.svc.cluster.local:8080`)
2. qBittorrent credentials configured in Sonarr download client settings
3. Sonarr can successfully add torrents to qBittorrent
4. Downloads complete through VPN and are accessible to Sonarr
5. Integration verified via test TV show download

## Tasks / Subtasks

- [ ] Task 1: Verify qBittorrent deployment and credentials (AC: #1, #2)
  - [ ] Verify qBittorrent is deployed in qbittorrent namespace
  - [ ] Verify qBittorrent service is accessible via service DNS
  - [ ] Verify qBittorrent is configured with VPN
  - [ ] Obtain qBittorrent username and password
  - [ ] Test qBittorrent accessibility from media namespace
- [ ] Task 2: Configure Sonarr-qBittorrent connection (AC: #1, #2, #3)
  - [ ] Access Sonarr UI via ingress
  - [ ] Navigate to Settings → Download Clients
  - [ ] Add qBittorrent download client
  - [ ] Configure qBittorrent URL: `http://qbittorrent.qbittorrent.svc.cluster.local:8080`
  - [ ] Configure qBittorrent username and password
  - [ ] Configure download category (e.g., "tv" or "sonarr")
  - [ ] Save and test connection
- [ ] Task 3: Configure download paths and mapping (AC: #4)
  - [ ] Verify shared storage access between Sonarr and qBittorrent
  - [ ] Configure download directory mapping
  - [ ] Configure completed download handling
  - [ ] Verify Sonarr can access completed downloads
- [ ] Task 4: Verify integration functionality (AC: #4, #5)
  - [ ] Perform test TV show download via Sonarr
  - [ ] Verify torrent is added to qBittorrent
  - [ ] Verify download completes through VPN
  - [ ] Verify Sonarr can access completed download
  - [ ] Verify content moves to appropriate location
  - [ ] Document integration status

## Dev Notes

### Prerequisites

- Story 1.1: API keys configured
- Story 1.1b: Service routing fixed (Sonarr accessible)
- Story 1.2: Sonarr-Prowlarr integration (for search functionality)
- qBittorrent deployed in qbittorrent namespace with VPN configured

### Architecture Context

**Service Communication:**
- qBittorrent is in `qbittorrent` namespace (separate from `media` namespace)
- Service DNS: `qbittorrent.qbittorrent.svc.cluster.local:8080`
- qBittorrent uses VPN for all downloads (network isolation)

**Storage Considerations:**
- Downloads need to be accessible from both qBittorrent and Sonarr
- May require shared PVC or hostPath mount
- Completed downloads need to be in Sonarr-accessible location

**Network Considerations:**
- Cross-namespace communication via Service DNS
- VPN routing handled by qBittorrent pod configuration
- Sonarr does not need VPN (only qBittorrent)

### Configuration Details

**qBittorrent Settings:**
- Web UI port: 8080
- Default credentials: admin/adminadmin (may need to verify/changed)
- Category: "tv" or "sonarr" for TV show downloads

**Sonarr Download Client Settings:**
- Type: qBittorrent
- Host: `qbittorrent.qbittorrent.svc.cluster.local`
- Port: 8080
- Username/Password: qBittorrent credentials
- Category: "tv" or "sonarr"
- URL Base: May be required (check qBittorrent configuration)

### Files to Review/Modify

- qBittorrent deployment: `apps/media-services/qbittorrent/` (verify namespace)
- Sonarr configuration: May need to update via UI (no file changes required)
- Storage: Verify shared storage configuration between namespaces

### Testing Strategy

1. **Connection Test:** Verify Sonarr can reach qBittorrent via service DNS
2. **Authentication Test:** Verify qBittorrent credentials work
3. **Download Test:** Add test TV show in Sonarr and verify torrent appears in qBittorrent
4. **Completion Test:** Verify completed download is accessible to Sonarr
5. **VPN Test:** Verify download traffic routes through VPN

### References

- [Source: docs/epics.md#Story-1.4] - Story acceptance criteria
- [Source: apps/media-services/qbittorrent/] - qBittorrent deployment configuration
- [Source: docs/architecture.md] - Namespace and network architecture

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

