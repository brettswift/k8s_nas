# Story 1.5: Configure Radarr-qBittorrent Integration

Status: done

## Story

As a system administrator,
I want to configure Radarr to use qBittorrent as its download client through VPN,
so that movie downloads are automatically managed and routed through secure VPN connection.

## Acceptance Criteria

1. Radarr configured to connect to qBittorrent via Kubernetes Service DNS (`qbittorrent.qbittorrent.svc.cluster.local:8080`)
2. qBittorrent credentials configured in Radarr download client settings
3. Radarr can successfully add torrents to qBittorrent
4. Downloads complete through VPN and are accessible to Radarr
5. Integration verified via test movie download

## Dev Notes

### Prerequisites

- Story 1.1: API keys configured
- Story 1.1b: Service routing fixed (Radarr accessible)
- Story 1.4: Sonarr-qBittorrent integration (pattern established)
- qBittorrent deployed in qbittorrent namespace with VPN configured

### Architecture Context

**Service Communication:**
- qBittorrent is in `qbittorrent` namespace (separate from `media` namespace)
- Service DNS: `qbittorrent.qbittorrent.svc.cluster.local:8080`
- qBittorrent uses VPN for all downloads (network isolation)

**Integration Pattern:**
- Follow same pattern as Story 1.4 (Sonarr-qBittorrent)
- Reuse configuration approach from Story 1.4
- Category: "movies" or "radarr" for movie downloads

## Dev Agent Record

### Context Reference

<!-- Story completed manually -->

### Agent Model Used

N/A - Completed manually

### Debug Log References

### Completion Notes List

### File List

