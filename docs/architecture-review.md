# Architecture Review - k8s_nas

**Review Date:** 2025-01-27  
**Reviewed By:** Architecture Analysis  
**Project:** k8s_nas - Kubernetes-based Media Server Infrastructure

## Executive Summary

The k8s_nas project implements a GitOps-driven Kubernetes platform for managing a complete media server stack. The architecture demonstrates solid GitOps practices with ArgoCD ApplicationSets, clear separation of concerns, and comprehensive service coverage. However, several critical security and operational issues require immediate attention.

### Overall Assessment

- **Architecture Maturity:** ⭐⭐⭐⭐ (4/5) - Well-structured GitOps pattern
- **Security Posture:** ⭐⭐ (2/5) - Critical vulnerabilities present
- **Operational Readiness:** ⭐⭐⭐ (3/5) - Good foundation with gaps
- **Best Practices:** ⭐⭐⭐ (3/5) - Good patterns with inconsistencies

---

## Architecture Strengths

### 1. GitOps Implementation

✅ **Excellent ApplicationSet Pattern**
- Clean separation of ApplicationSet definitions in `argocd/applicationsets/`
- Proper use of sync waves for deployment ordering
- Automated sync policies with self-healing enabled

✅ **Clear Branch Strategy**
- `dev` branch for local development
- `main` branch for production
- Feature branches for development

✅ **Namespace Organization**
- Logical namespace isolation (media, infrastructure, monitoring)
- Clear service categorization

### 2. Service Configuration

✅ **Health Checks**
- Most services have proper liveness and readiness probes
- Appropriate timeout and failure threshold configurations

✅ **Resource Management**
- Resource requests and limits defined for most services
- Reasonable defaults for media processing workloads

✅ **Inter-Service Communication**
- Centralized ConfigMap (`starr-common-config`) for service URLs
- Consistent use of Kubernetes DNS for service discovery

### 3. Documentation

✅ **Comprehensive Documentation**
- Architecture documentation exists
- Development and deployment guides present
- Source tree analysis maintained

---

## Critical Issues (P0 - Immediate Action Required)

### 1. Security: Privileged Container (CRITICAL)

**Location:** `apps/media-services/jellyfin/deployment.yaml:44`

```44:45:apps/media-services/jellyfin/deployment.yaml
        securityContext:
          privileged: true
```

**Issue:** Jellyfin runs with `privileged: true`, granting full host access. This is a severe security risk.

**Risk:** Compromised container can access host resources, bypass security controls, and potentially escape containerization.

**Recommendation:**
- Remove `privileged: true`
- Use specific `capabilities` if GPU access is needed
- Consider using `devicePlugins` for NVIDIA GPU access
- If `/dev/dri` access is required, use `securityContext.capabilities.add: ["SYS_ADMIN"]` instead

**Example Fix:**
```yaml
securityContext:
  capabilities:
    add:
      - SYS_ADMIN  # Only if absolutely required for GPU
  allowPrivilegeEscalation: false
```

### 2. Configuration: Root Application Path Mismatch

**Location:** `argocd/root-app.yaml:12`

```12:12:argocd/root-app.yaml
    path: argocd-minimal/applications
```

**Issue:** Root application references non-existent path `argocd-minimal/applications`. Should be `argocd/applicationsets`.

**Current State:**
- `root-application.yaml` in root correctly points to `argocd/applicationsets`
- `argocd/root-app.yaml` has incorrect path

**Recommendation:**
- Update `argocd/root-app.yaml` to use path: `argocd/applicationsets`
- Consolidate to single root application configuration
- Verify which file is actually used by ArgoCD

### 3. Security: Inconsistent Security Contexts

**Issue:** Security context configuration is inconsistent across services.

**Current State:**
- Jellyfin: `privileged: true` (insecure)
- Unpackerr: `runAsUser: 1000`, `allowPrivilegeEscalation: false` (good)
- Most services: No security context defined

**Recommendation:**
- Implement Pod Security Standards (PSS)
- Add security context to all deployments:
  ```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000  # Or appropriate UID
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: false  # Adjust per service needs
  ```

---

## High Priority Issues (P1 - Address Soon)

### 4. Image Tag Strategy: Use of `:latest`

**Issue:** All services use `:latest` image tags, preventing reproducible deployments and rollback capabilities.

**Examples:**
- `jellyfin/jellyfin:latest`
- `docker.io/linuxserver/sonarr:latest`
- `ghcr.io/flaresolverr/flaresolverr:latest`

**Risk:**
- Unpredictable deployments
- Breaking changes introduced without notice
- Difficult to rollback to known good versions

**Recommendation:**
- Pin to specific versions (e.g., `jellyfin/jellyfin:10.9.0`)
- Use semantic versioning where available
- Document version update process
- Consider tools like Renovate for dependency updates

### 5. Secrets Management: Empty Secrets in Repository

**Location:** `apps/media-services/starr/unpackerr-deployment.yaml:80`

```80:87:apps/media-services/starr/unpackerr-deployment.yaml
data:
  # These will need to be populated with actual base64 encoded API keys
  SONARR_API_KEY: ""     # Base64 encoded API key
  RADARR_API_KEY: ""     # Base64 encoded API key
  LIDARR_API_KEY: ""     # Base64 encoded API key
  BAZARR_API_KEY: ""     # Base64 encoded API key
  PROWLARR_API_KEY: ""   # Base64 encoded API key
  JELLYSEERR_API_KEY: "" # Base64 encoded API key
  SABNZBD_API_KEY: ""    # Base64 encoded API key
```

**Issue:** Secrets are defined in Git with empty values, creating deployment failures and security confusion.

**Recommendation:**
- Move secrets out of Git
- Use External Secrets Operator or Sealed Secrets
- Document secret creation process
- Use `kubectl create secret` commands in deployment scripts

**Alternative Approach:**
- Remove Secret manifests from Git
- Create secrets via bootstrap scripts
- Document required secrets in README

### 6. Storage Strategy: Inconsistent Patterns

**Issue:** Mixed storage approaches create operational complexity.

**Current State:**
- Some services use PVCs (Jellyfin, Jellyseerr, Lidarr)
- Others use direct hostPath (Sonarr, Radarr)
- Storage class varies: `local-path` vs implicit hostPath

**Recommendation:**
- Standardize on one approach per use case:
  - **Config data:** PVCs with `local-path` storage class
  - **Media files:** hostPath (shared across services)
  - **Downloads:** hostPath (high I/O, temporary)
- Document storage strategy decision rationale
- Consider long-term storage solution (NFS, CephFS)

### 7. Network Security: Missing Network Policies

**Issue:** No NetworkPolicy resources implemented despite being mentioned in TODOs.

**Current State:**
- NetworkPolicies allowed in ArgoCD projects but not implemented
- Services can communicate freely without restriction
- VPN isolation not enforced at network level

**Recommendation:**
- Implement default deny NetworkPolicy per namespace
- Allow explicit required communications:
  - Starr services → Download clients
  - Download clients → VPN (for qBittorrent)
  - Ingress → Services
- Document network topology and allowed flows

**Example Structure:**
```yaml
# Default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: media
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## Medium Priority Issues (P2 - Address When Convenient)

### 8. Resource Configuration Inconsistencies

**Issue:** Resource requests/limits vary without clear rationale.

**Recommendations:**
- Document resource requirements per service
- Create resource profile configurations (dev vs production)
- Consider HorizontalPodAutoscaler for variable workloads
- Review and standardize resource patterns

### 9. Monitoring: Service Discovery Configuration

**Issue:** Prometheus configuration may not automatically discover all services.

**Recommendation:**
- Verify Prometheus service discovery configuration
- Add PodMonitor or ServiceMonitor resources where needed
- Document metrics endpoints for each service

### 10. Backup Strategy: Missing Implementation

**Issue:** No backup strategy for persistent volumes or configurations.

**Recommendation:**
- Implement Velero or similar backup solution
- Schedule regular backups of:
  - PVC data (service configurations)
  - ArgoCD application state
  - Kubernetes secrets (encrypted)
- Document restore procedures

### 11. Health Check Inconsistencies

**Issue:** Not all services have health checks configured.

**Recommendation:**
- Add liveness and readiness probes to all services
- Standardize probe configuration
- Document expected startup times for initial delays

---

## Low Priority Issues (P3 - Nice to Have)

### 12. Documentation: Missing Service Dependencies Graph

**Recommendation:** Create visual dependency diagram showing:
- Service startup order
- Inter-service communication flows
- Data flow (download → processing → media library)

### 13. Development Experience

**Recommendation:**
- Add development environment quickstart script
- Document local debugging procedures
- Add troubleshooting guide for common issues

### 14. Testing: Automated Validation

**Recommendation:**
- Add pre-commit hooks for manifest validation
- Implement CI/CD for automated testing
- Add integration tests for service communication

### 15. Observability: Log Aggregation

**Recommendation:**
- Implement centralized logging (Loki, ELK stack)
- Add structured logging standards
- Create log retention policies

---

## Architectural Improvements

### 1. Storage Architecture

**Current:** Mixed PVC and hostPath usage  
**Recommended:** Tiered storage strategy

- **Tier 1 (Config):** PVCs with `local-path` for service configurations
- **Tier 2 (Media):** Shared hostPath for media library (read-heavy)
- **Tier 3 (Downloads):** Separate hostPath for download staging (write-heavy)

### 2. Secrets Architecture

**Current:** Secrets in Git (empty)  
**Recommended:** External Secrets Operator pattern

```yaml
# Use ExternalSecret instead of Secret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: starr-secrets
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: starr-secrets
  data:
  - secretKey: SONARR_API_KEY
    remoteRef:
      key: starr
      property: sonarr_api_key
```

### 3. Network Architecture

**Current:** No network policies  
**Recommended:** Zero-trust network model

- Default deny NetworkPolicy in each namespace
- Explicit allow rules for required communications
- Service mesh (Istio) for advanced policies (optional)

### 4. Deployment Architecture

**Current:** Single replica per service  
**Recommended:** Gradual HA adoption

- Start with stateless services (Jellyseerr, Homepage)
- Add HPA for variable workloads
- Consider StatefulSets for services requiring ordered deployment

---

## Security Recommendations Summary

### Immediate Actions (This Week)

1. ✅ Remove `privileged: true` from Jellyfin deployment
2. ✅ Fix root application path mismatch
3. ✅ Remove or properly manage secrets in repository
4. ✅ Add security contexts to all deployments

### Short Term (This Month)

1. Pin image tags to specific versions
2. Implement NetworkPolicies
3. Set up proper secrets management (External Secrets Operator)
4. Document security baseline

### Long Term (This Quarter)

1. Implement Pod Security Standards (PSS)
2. Add security scanning to CI/CD
3. Set up runtime security monitoring (Falco)
4. Conduct security audit

---

## Operational Recommendations

### Monitoring

- ✅ Prometheus and Grafana configured
- ⚠️ Verify service discovery and metrics collection
- ⚠️ Add alerting rules for critical metrics

### Backup & Recovery

- ❌ No backup strategy implemented
- ⚠️ Add Velero or similar solution
- ⚠️ Document restore procedures

### Disaster Recovery

- ❌ No DR plan documented
- ⚠️ Document recovery procedures
- ⚠️ Test restore procedures regularly

---

## Migration Considerations

Based on `docs/experiments/TODO.md`, migration from docker-compose is ongoing. Recommendations:

1. **Complete Migration:** Finish migrating all services from docker-compose
2. **Pattern Consistency:** Ensure all migrated services follow same patterns
3. **Test Parity:** Verify feature parity with docker-compose setup
4. **Performance Validation:** Compare performance metrics

---

## Compliance & Best Practices Checklist

- [x] GitOps pattern implemented
- [x] Namespace isolation
- [x] Health checks configured
- [x] Resource limits defined
- [ ] Security contexts configured
- [ ] Image tags pinned
- [ ] Secrets properly managed
- [ ] Network policies implemented
- [ ] Backup strategy in place
- [ ] Monitoring and alerting configured
- [ ] Documentation complete
- [ ] Disaster recovery plan

---

## Action Items by Priority

### P0 - Critical (Fix Immediately)

1. **Remove privileged mode from Jellyfin**
   - File: `apps/media-services/jellyfin/deployment.yaml`
   - Replace with specific capabilities

2. **Fix root application path**
   - File: `argocd/root-app.yaml`
   - Change path to `argocd/applicationsets`

3. **Address secrets in Git**
   - Remove secret manifests or use External Secrets Operator
   - Document secret creation process

### P1 - High Priority (Fix This Week)

1. Pin image tags to specific versions
2. Add security contexts to all deployments
3. Standardize storage strategy
4. Document security baseline

### P2 - Medium Priority (Fix This Month)

1. Implement NetworkPolicies
2. Set up backup solution
3. Improve monitoring coverage
4. Add CI/CD validation

### P3 - Low Priority (When Convenient)

1. Create service dependency diagrams
2. Add centralized logging
3. Improve development documentation
4. Add integration testing

---

## Conclusion

The k8s_nas project demonstrates strong architectural foundation with excellent GitOps practices and clear organizational structure. The primary concerns are security-related and can be addressed with focused effort on implementing security best practices.

**Key Strengths:**
- Clean GitOps architecture
- Well-organized service structure
- Good documentation foundation

**Key Weaknesses:**
- Security configuration gaps
- Inconsistent patterns across services
- Missing operational safeguards

**Recommended Focus:**
1. Security hardening (immediate)
2. Pattern standardization (short-term)
3. Operational excellence (ongoing)

---

## References

- [Architecture Documentation](./architecture.md)
- [Development Guide](./development-guide.md)
- [Deployment Guide](./deployment-guide.md)
- [Project Overview](./project-overview.md)

