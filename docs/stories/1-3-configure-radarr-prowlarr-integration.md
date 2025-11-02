# Story 1.3: Configure Radarr-Prowlarr Integration

Status: done

## Story

As a system administrator,
I want to configure Radarr to use Prowlarr as its indexer manager,
so that movie searches automatically use all configured indexers from Prowlarr.

## Acceptance Criteria

1. Radarr configured to connect to Prowlarr via Kubernetes Service DNS (`prowlarr.media.svc.cluster.local:9696`)
2. Radarr API key configured in Prowlarr application settings
3. Prowlarr automatically syncs indexers to Radarr
4. Radarr can successfully search for movies using Prowlarr indexers
5. Indexer synchronization verified via Radarr UI and test searches

## Tasks / Subtasks

- [ ] Task 1: Verify prerequisites (AC: #1)
  - [ ] Verify Radarr is deployed and accessible
  - [ ] Verify Prowlarr is deployed and accessible
  - [ ] Verify RADARR_API_KEY exists in `starr-secrets` Secret
  - [ ] Verify Story 1.2 completed (Prowlarr-Sonarr integration pattern established)
- [ ] Task 2: Configure Radarr-Prowlarr connection (AC: #1, #2)
  - [ ] Access Radarr UI via ingress
  - [ ] Navigate to Settings → Indexers
  - [ ] Add Prowlarr as indexer source
  - [ ] Configure Prowlarr URL: `http://prowlarr.media.svc.cluster.local:9696`
  - [ ] Configure Radarr API key (from `starr-secrets`)
  - [ ] Save and test connection
- [ ] Task 3: Configure Prowlarr-Radarr application sync (AC: #2, #3)
  - [ ] Access Prowlarr UI via ingress or port-forward
  - [ ] Navigate to Settings → Apps
  - [ ] Add Radarr application (in addition to existing Sonarr)
  - [ ] Configure Radarr URL: `http://radarr.media.svc.cluster.local:7878`
  - [ ] Configure Radarr API key from `starr-secrets` (RADARR_API_KEY)
  - [ ] Enable automatic indexer synchronization
  - [ ] Verify Prowlarr can connect to Radarr
- [ ] Task 4: Verify integration functionality (AC: #4, #5)
  - [ ] Verify indexers sync to Radarr automatically
  - [ ] Perform test movie search in Radarr
  - [ ] Verify search uses Prowlarr indexers
  - [ ] Document integration status

## Dev Notes

### Prerequisites

- Story 1.1: API keys configured in `starr-secrets` Secret
- Story 1.1b: Service routing fixed (Radarr accessible)
- Story 1.2: Prowlarr-Sonarr integration completed (pattern established)

### Architecture Context

**Service Communication:**
- Services communicate via Kubernetes Service DNS
- Prowlarr listens on port 9696
- Radarr listens on port 7878

**Integration Pattern:**
- Follow same pattern as Story 1.2 (Sonarr-Prowlarr)
- Reuse configuration approach from Story 1.2
- Prowlarr can manage multiple applications (Sonarr + Radarr)

### Learnings from Previous Story

**From Story 1.2 (Configure Sonarr-Prowlarr Integration):**

- **Pattern Established**: Use Kubernetes Service DNS for internal communication
- **Configuration Order**: Configure both directions (Radarr→Prowlarr and Prowlarr→Radarr)
- **API Keys**: Retrieved from `starr-secrets` Secret in `media` namespace
- **Testing Approach**: Use actual searches to verify indexer functionality

[Source: stories/1-2-configure-sonarr-prowlarr-integration.md]

### Files to Review/Modify

- Secret: `starr-secrets` already contains RADARR_API_KEY (from Story 1.1)
- Radarr deployment: `apps/media-services/starr/radarr-deployment.yaml`
- Service routing: Verify Radarr ingress is configured correctly

### Testing Strategy

1. **Connection Test:** Verify Radarr can reach Prowlarr via service DNS
2. **API Key Test:** Verify API key authentication works
3. **Indexer Sync Test:** Verify indexers appear in Radarr after Prowlarr sync
4. **Search Test:** Perform actual movie search and verify results

### References

- [Source: docs/epics.md#Story-1.3] - Story acceptance criteria
- [Source: stories/1-2-configure-sonarr-prowlarr-integration.md] - Integration pattern reference
- [Source: docs/story-1.1-completion.md] - API key extraction approach

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

