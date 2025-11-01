# Architectural Decisions and Rationale

**Document Purpose:** This document captures architectural decisions and explains why certain patterns were chosen, addressing concerns raised in the architecture review.

---

## Decision Record Format

Each decision includes:
- **Decision:** What was decided
- **Context:** Why the decision was made
- **Rationale:** Justification for the approach
- **Alternatives Considered:** Other options evaluated

---

## Security & Container Configuration

### Decision 1: Jellyfin Privileged Mode

**Status:** ✅ Accepted  
**Date:** 2025-01-27  
**Decision:** Use `privileged: true` for Jellyfin container to enable GPU hardware acceleration.

**Context:** Jellyfin requires direct access to GPU devices (`/dev/dri`) for hardware-accelerated media transcoding. This is essential for performance on a home media server.

**Rationale:**
- GPU acceleration is required for efficient media transcoding
- NVIDIA device plugin provides device access, but privileged mode needed for `/dev/dri`
- Home lab environment with controlled physical and network access (Tailscale ingress)
- Security risk is acceptable given isolated environment and performance requirements

**Alternatives Considered:**
- Using specific capabilities instead of privileged mode - **Rejected**: Insufficient for GPU device access
- NVIDIA device plugin alone - **Rejected**: Doesn't provide `/dev/dri` access needed for transcoding
- Runtime class with elevated permissions - **Not evaluated**: Current solution meets requirements

**Consequences:**
- ✅ Positive: Full GPU hardware acceleration for transcoding
- ⚠️ Negative: Increased security surface, but acceptable for home lab environment

**Future Considerations:**
- Investigate if newer Kubernetes versions or Jellyfin releases support more restrictive security contexts

---

### Decision 2: Security Context Inconsistencies

**Status:** Pending Review  
**Concern:** Not all services have security contexts defined.

**Your Rationale:** _(To be filled in)_

**Potential Justifications:**
- Legacy services that require specific permissions
- Different security postures for different service categories
- Gradual migration approach
- Service-specific requirements (e.g., VPN, download clients)

---

## Image Tag Strategy

### Decision 3: Use of `:latest` Tags

**Status:** ✅ Accepted (Temporary)  
**Date:** 2025-01-27  
**Decision:** Use `:latest` image tags during buildout phase, pin to specific versions once stable.

**Context:** Project is actively being developed and migrated from docker-compose. Images are third-party (not owned or built by us), and we need flexibility during setup phase.

**Rationale:**
- Active development phase requires rapid iteration and testing
- Third-party images are not under our control, so frequent updates are expected
- GitOps provides automatic rollback if issues occur
- Simplified maintenance during buildout phase
- Once final working state is achieved, versions will be pinned for reproducibility

**Alternatives Considered:**
- Pin to specific versions immediately - **Rejected**: Too restrictive during active development
- Image update automation (Renovate, Dependabot) - **Future consideration**: Will evaluate once stable

**Consequences:**
- ✅ Positive: Easy updates, faster iteration during development
- ⚠️ Negative: Potential for unexpected breaking changes (mitigated by GitOps rollback)
- 📋 Planned: Pin versions once system reaches stable state

**Action Items:**
- Document version pinning process for future implementation
- Consider version manifest file for tracking current versions

---

## Secrets Management

### Decision 4: Empty Secrets in Git

**Status:** ⚠️ Needs Improvement  
**Date:** 2025-01-27  
**Decision:** Currently using empty Secret manifests as templates in Git repository.

**Context:** Secrets are manually populated post-deployment. This creates a disaster recovery concern - if hardware needs replacement (single-node setup on gaming machine in furnace room), secret recreation is not documented.

**Rationale:**
- Manifest structure serves as documentation of required secrets
- Manual injection is acceptable for home lab
- **Issue identified:** No documented process for secret recreation during disaster recovery

**Alternatives Considered:**
- External Secrets Operator - **Not evaluated**: May be overkill for home lab
- Sealed Secrets - **Not evaluated**: Could improve disaster recovery
- Remove Secret manifests from Git - **Rejected**: Need structure documented
- Bootstrap scripts create secrets dynamically - **Future consideration**

**Consequences:**
- ✅ Positive: Structure documented in Git, manual control
- ❌ Negative: **Disaster recovery risk** - no documented process for secret recreation
- ❌ Negative: Empty secrets could cause deployment failures

**Action Items:**
1. Document secret creation/recovery process in README or bootstrap docs
2. Create script or process for populating secrets during initial setup
3. Consider moving secret templates to `.example` files or separate documentation
4. Document secret requirements for disaster recovery scenarios

---

## Storage Architecture

### Decision 5: Mixed Storage Patterns (PVC vs hostPath)

**Status:** ✅ Accepted  
**Date:** 2025-01-27  
**Decision:** Use mixed storage approach - PVCs for configs, hostPath for shared data.

**Context:** Single-node deployment requires different storage strategies for different data types:
- Service configurations need isolation
- Media files need to be shared across multiple services
- Download staging area is temporary and high I/O

**Rationale:**
- **PVCs for configs:** Service-specific configuration benefits from isolation, easier backup/restore
- **hostPath for media:** Shared media library (movies, TV, music) accessed by Jellyfin, Sonarr, Radarr, etc.
- **hostPath for downloads:** Temporary staging area, high I/O, no need for PVC overhead
- Performance optimization: Direct hostPath for media reduces abstraction overhead
- Single-node deployment makes hostPath viable and simpler

**Alternatives Considered:**
- All PVCs with shared storage class - **Rejected**: Unnecessary overhead for single-node, shared media
- All hostPath for simplicity - **Rejected**: Config isolation is beneficial
- NFS or CephFS for shared storage - **Not needed**: Single-node doesn't require network storage

**Consequences:**
- ✅ Positive: Optimal storage type for each use case
- ✅ Positive: Simplified media sharing between services
- ⚠️ Negative: Mixed patterns require understanding, but well-documented

---

## Network Security

### Decision 6: Missing Network Policies

**Status:** ✅ Accepted  
**Date:** 2025-01-27  
**Decision:** No NetworkPolicy resources implemented - not required for current architecture.

**Context:** Home lab is only accessible internally or via Tailscale ingress. Physical and network isolation already provides sufficient security.

**Rationale:**
- Network isolation achieved at infrastructure level (firewall, Tailscale)
- Home lab environment with controlled access
- Complexity vs. benefit tradeoff: NetworkPolicies add operational overhead with minimal security gain
- Services require broad inter-service communication (Starr stack, download clients, media server)
- VPN pod already provides network-level isolation for download services

**Alternatives Considered:**
- Default deny with explicit allow rules - **Rejected**: Unnecessary complexity for isolated environment
- Namespace-level isolation - **Rejected**: Services need cross-namespace communication
- Service mesh (Istio) for advanced policies - **Rejected**: Overkill for home lab use case

**Consequences:**
- ✅ Positive: Simplified configuration, easier service communication
- ✅ Positive: No operational overhead from policy management
- ⚠️ Negative: Less defense-in-depth, but acceptable given network isolation

**Future Considerations:**
- Re-evaluate if expanding to multi-tenant or cloud deployment
- Consider if adding external-facing services changes threat model

---

## GitOps and Configuration

### Decision 7: Root Application Path Configuration

**Status:** ⚠️ Needs Cleanup  
**Date:** 2025-01-27  
**Concern:** `argocd/root-app.yaml` references non-existent path `argocd-minimal/applications`.

**Context:** Two root application files exist:
1. `root-application.yaml` (root directory) - Points to `argocd/applicationsets` ✅ (Correct)
2. `argocd/root-app.yaml` - Points to `argocd-minimal/applications` ❌ (Incorrect path)

**Current State:**
- `start_k8s.sh` applies `root-application.yaml`, so that's the active configuration
- `argocd/root-app.yaml` appears to be legacy/unused file

**Decision:** Remove or update `argocd/root-app.yaml` to prevent confusion.

**Action Items:**
1. Verify `argocd/root-app.yaml` is not being used by ArgoCD
2. Either:
   - Delete `argocd/root-app.yaml` if it's unused, OR
   - Update it to point to correct path if it's needed
3. Document which root application file is the source of truth

---

## Deployment Patterns

### Decision 8: Single Replica Strategy

**Status:** Implicit Decision  
**Observation:** Most services run with `replicas: 1`.

**Your Rationale:** _(To be filled in)_

**Potential Justifications:**
- Home lab with limited resources
- Stateless services can scale if needed
- Media services often have stateful requirements
- Simplicity and cost optimization

---

## Monitoring & Observability

### Decision 9: Monitoring Stack Configuration

**Status:** Pending Review  
**Observation:** Prometheus and Grafana deployed, service discovery may need verification.

**Your Rationale:** _(To be filled in)_

**Questions:**
- Are all services being scraped?
- Are there custom metrics or dashboards?
- What alerting is configured?

---

## Backup & Recovery

### Decision 10: No Backup Strategy

**Status:** Intentional or Gap?  
**Concern:** No backup solution implemented for PVCs or cluster state.

**Your Rationale:** _(To be filled in)_

**Potential Justifications:**
- Media files backed up separately
- Configurations can be regenerated from Git (GitOps)
- Disaster recovery not critical for home lab
- Future consideration when scaling

---

## Template for Adding Decisions

```markdown
### Decision N: [Title]

**Status:** [Accepted | Rejected | Pending | Superseded]  
**Date:** YYYY-MM-DD  
**Decision Makers:** [Names]

**Context:**
[Describe the situation and problem statement]

**Decision:**
[State the architectural decision clearly]

**Rationale:**
[Explain why this decision was made, including trade-offs considered]

**Alternatives Considered:**
- Alternative 1: [Description] - Rejected because [reason]
- Alternative 2: [Description] - Rejected because [reason]

**Consequences:**
- Positive: [What benefits this provides]
- Negative: [What limitations or costs this introduces]

**Related Decisions:**
- Links to other ADRs that relate

**References:**
- Links to documentation, issues, or discussions
```

---

## Next Steps

1. Review each concern from the architecture review
2. Document your rationale for each decision
3. Update architecture review to reflect accepted patterns
4. Update documentation to explain architectural choices

---

## Notes

This document should be a living record of architectural decisions. As patterns evolve, decisions can be:
- **Accepted:** Decision stands, rationale documented
- **Superseded:** Replaced by a better approach
- **Amended:** Modified based on new information

