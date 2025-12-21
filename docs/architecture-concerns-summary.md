# Architecture Concerns Summary

**Date:** 2025-01-27  
**Status:** Post-Review Assessment

After reviewing architectural decisions and rationale, here are the **actual concerns** that need addressing:

---

## ✅ Resolved / Accepted Decisions

The following concerns have been reviewed and are **accepted as intentional architectural choices**:

1. ✅ **Jellyfin Privileged Mode** - Required for GPU acceleration in home lab
2. ✅ **Use of `:latest` Tags** - Intentional during buildout phase, will pin once stable
3. ✅ **Missing Network Policies** - Not needed given Tailscale + internal-only access
4. ✅ **Mixed Storage Patterns** - Intentional (PVCs for configs, hostPath for shared media)

See [Architecture Decisions](./architecture-decisions.md) for detailed rationale.

---

## ⚠️ Action Items (Needs Addressing)

### 1. Secrets Management - Disaster Recovery Risk

**Priority:** High  
**Risk:** If hardware fails or needs replacement, secret recreation process is undocumented.

**Current State:**
- Empty Secret manifests in Git as templates
- Secrets manually populated
- No documented process for disaster recovery

**Impact:**
- Single-node deployment on gaming machine in furnace room
- Hardware failure would require recreating all secrets from scratch
- No clear documentation of what secrets are needed and how to create them

**Recommendations:**
1. **Document secret requirements** - Create a checklist of all required secrets
2. **Create secret setup script** - Bootstrap script that prompts for and creates secrets
3. **Document disaster recovery** - Step-by-step guide for secret recreation
4. **Consider alternatives:**
   - Sealed Secrets (encrypted secrets in Git)
   - External Secrets Operator
   - Encrypted backup of secret values (stored separately from Git)

**Action Items:**
- [ ] Create `docs/secrets-management.md` with secret inventory
- [ ] Create `scripts/setup-secrets.sh` for secret creation
- [ ] Document secret recovery process in disaster recovery guide
- [ ] Consider Sealed Secrets or similar solution

---

### 2. Root Application Path Cleanup

**Priority:** Low (Documentation/Clarity)  
**Risk:** Confusion about which root application is active.

**Current State:**
- `root-application.yaml` (root) - ✅ Active, points to `argocd/applicationsets`
- `argocd/root-app.yaml` - ❌ Legacy, points to non-existent `argocd-minimal/applications`

**Action Items:**
- [ ] Verify `argocd/root-app.yaml` is not used by ArgoCD
- [ ] Delete `argocd/root-app.yaml` if unused, OR
- [ ] Update it if it's needed for some purpose
- [ ] Document which file is the source of truth

---

### 3. Security Context Documentation

**Priority:** Low (Best Practice)  
**Risk:** None currently, but inconsistent patterns make future maintenance harder.

**Current State:**
- Jellyfin: `privileged: true` (accepted - GPU required)
- Unpackerr: Good security context (`runAsUser: 1000`, `allowPrivilegeEscalation: false`)
- Most services: No security context defined

**Recommendation:**
- Document why Jellyfin needs privileged mode (done)
- Consider adding basic security contexts to other services when convenient
- Not critical, but would improve security posture

**Action Items:**
- [ ] Document security context strategy
- [ ] Add security contexts to services incrementally (low priority)
- [ ] Update architecture docs to explain security context decisions

---

## 📋 Future Considerations

These are **not concerns** but things to consider as the system matures:

### Image Version Pinning
- **When:** Once system reaches stable state
- **Action:** Pin all image tags to specific versions
- **Current:** Using `:latest` intentionally during buildout

### Backup Strategy
- **Consider:** Velero or similar for PVC backups
- **Priority:** Low for home lab, but good practice
- **Current:** Configs in Git (backed up), media backed up separately

### Monitoring Coverage
- **Verify:** All services are being scraped by Prometheus
- **Consider:** Custom dashboards for media server metrics
- **Current:** Prometheus/Grafana deployed, coverage needs verification

---

## ✅ Architecture Assessment

**Overall Architecture Quality:** ⭐⭐⭐⭐ (4/5)

**Strengths:**
- Excellent GitOps implementation with ArgoCD ApplicationSets
- Clear architectural decisions with documented rationale
- Appropriate patterns for home lab use case
- Good separation of concerns (configs vs. data storage)

**Minor Improvements Needed:**
1. Secrets disaster recovery documentation
2. Clean up legacy root app file
3. Document security context strategy

**Verdict:** Architecture is **sound** for the use case. The main concern is disaster recovery documentation for secrets, which is important given the single-node deployment.

---

## Next Steps

1. **Immediate:** Document secrets management and disaster recovery
2. **Short-term:** Clean up root application file confusion
3. **Long-term:** Pin image versions once stable, consider backup automation

---

## Related Documents

- [Architecture Review](./architecture-review.md) - Full detailed review
- [Architecture Decisions](./architecture-decisions.md) - Documented decisions with rationale
- [Architecture Documentation](./architecture.md) - System architecture overview









