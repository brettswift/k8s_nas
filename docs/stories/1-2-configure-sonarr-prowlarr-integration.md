# Story 1.2: Configure Sonarr-Prowlarr Integration

Status: ready-for-dev

## Story

As a system administrator,
I want to configure Sonarr to use Prowlarr as its indexer manager,
so that TV show searches automatically use all configured indexers from Prowlarr.

## Acceptance Criteria

1. Sonarr configured to connect to Prowlarr via Kubernetes Service DNS (`prowlarr.media.svc.cluster.local:9696`)
2. Sonarr API key configured in Prowlarr application settings
3. Prowlarr automatically syncs indexers to Sonarr
4. Sonarr can successfully search for TV shows using Prowlarr indexers
5. Indexer synchronization verified via Sonarr UI and test searches

## Tasks / Subtasks

- [ ] Task 1: Deploy and verify Prowlarr service (AC: #1)
  - [ ] Verify Prowlarr deployment manifest exists and is included in kustomization
  - [ ] Deploy Prowlarr via ArgoCD (or manual apply if needed)
  - [ ] Verify Prowlarr pod is running in media namespace
  - [ ] Verify Prowlarr service is accessible via service DNS (`prowlarr.media.svc.cluster.local:9696`)
  - [ ] Verify Prowlarr ingress is configured and accessible at `/prowlarr`
  - [ ] Extract Prowlarr API key from config file (`/mnt/data/configs/prowlarr/config.xml`)
  - [ ] Update `starr-secrets` Secret with PROWLARR_API_KEY
- [ ] Task 2: Configure Sonarr-Prowlarr connection (AC: #1, #2)
  - [ ] Access Sonarr UI via ingress
  - [ ] Navigate to Settings → Indexers
  - [ ] Add Prowlarr as indexer source
  - [ ] Configure Prowlarr URL: `http://prowlarr.media.svc.cluster.local:9696`
  - [ ] Configure Sonarr API key (from `starr-secrets`)
  - [ ] Save and test connection
- [ ] Task 3: Configure Prowlarr-Sonarr application sync (AC: #2, #3)
  - [ ] Access Prowlarr UI via ingress at `https://home.brettswift.com/prowlarr` (or port-forward if ingress not ready)
  - [ ] Navigate to Settings → Apps
  - [ ] Add Sonarr application
  - [ ] Configure Sonarr URL: `http://sonarr.media.svc.cluster.local:8989`
  - [ ] Configure Sonarr API key from `starr-secrets` (SONARR_API_KEY)
  - [ ] Enable automatic indexer synchronization
  - [ ] Verify Prowlarr can connect to Sonarr
- [ ] Task 4: Verify integration functionality (AC: #4, #5)
  - [ ] Add test indexer in Prowlarr (if none exist)
  - [ ] Verify indexer syncs to Sonarr automatically
  - [ ] Perform test TV show search in Sonarr
  - [ ] Verify search uses Prowlarr indexers
  - [ ] Document integration status

## Dev Notes

### Prerequisites

- ✅ Story 1.1: API keys configured in `starr-secrets` Secret (SONARR_API_KEY exists)
- ✅ Story 1.1b: Service routing fixed (Sonarr accessible at `/sonarr`)
- ⚠️ Prowlarr service deployment: Prowlarr manifests exist but service is NOT deployed yet
- ⚠️ PROWLARR_API_KEY: Not yet in `starr-secrets` Secret (needs extraction)

### Architecture Context

**Service Communication:**
- Services communicate via Kubernetes Service DNS
- Internal cluster DNS: `<service-name>.<namespace>.svc.cluster.local`
- Prowlarr listens on port 9696
- Sonarr listens on port 8989

**API Key Management:**
- API keys stored in `starr-secrets` Secret in `media` namespace
- Keys referenced via environment variables or ConfigMaps
- Secret keys: `SONARR_API_KEY`, `PROWLARR_API_KEY`

### Integration Pattern

1. **Prowlarr as Indexer Manager:**
   - Prowlarr manages all indexer configurations
   - Prowlarr syncs indexers to Sonarr automatically
   - Sonarr connects to Prowlarr to perform searches

2. **Configuration Flow:**
   - Configure Sonarr → Prowlarr connection (Sonarr fetches indexers)
   - Configure Prowlarr → Sonarr application (Prowlarr syncs indexers)
   - Enable automatic synchronization in Prowlarr

### Files to Review/Modify

- **Deployment**: `apps/media-services/starr/prowlarr-deployment.yaml` (verify manifest is correct)
- **Ingress**: `apps/media-services/starr/prowlarr-ingress.yaml` (verify routing pattern follows standards)
- **Kustomization**: `apps/media-services/starr/kustomization.yaml` (verify Prowlarr is included)
- **Secret**: `starr-secrets` in `media` namespace (add PROWLARR_API_KEY after extraction)
- **Config**: `/mnt/data/configs/prowlarr/config.xml` (extract API key from existing config)

### Testing Strategy

1. **Connection Test:** Verify Sonarr can reach Prowlarr via service DNS
2. **API Key Test:** Verify API key authentication works
3. **Indexer Sync Test:** Verify indexers appear in Sonarr after Prowlarr sync
4. **Search Test:** Perform actual TV show search and verify results

### References

- [Source: docs/epics.md#Story-1.2] - Story acceptance criteria
- [Source: docs/story-1.1-completion.md] - API key extraction approach
- [Source: apps/media-services/starr/] - Starr service configurations

## Dev Agent Record

### Git Branch

- **Branch**: `story/1-2-configure-sonarr-prowlarr-integration`
- **Created**: During story grooming when moved to `ready-for-dev`
- **Base**: `dev_starr`

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

