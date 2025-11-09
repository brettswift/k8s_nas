# Bootstrap vs GitOps Design

**Date:** 2025-01-27  
**Purpose:** Define clear separation between bootstrap (one-time setup) and GitOps (ongoing management)

---

## Current State

### Bootstrap (Shell Scripts)
- `start_k8s.sh` - Installs k3s/k3d cluster
- `bootstrap/bootstrap.sh` - Installs plugins (cert-manager, Istio)
- `bootstrap/k8s_plugins.sh` - Installs Kubernetes plugins
- ArgoCD installed via `kubectl apply` directly from GitHub manifests

### GitOps (ArgoCD)
- `root-application.yaml` - Entry point for ApplicationSets
- `argocd/applicationsets/*` - ApplicationSet definitions
- All applications (media services, homepage, monitoring) managed via GitOps

### Problem
- **ArgoCD itself is not managed by GitOps** - installed via shell scripts
- Blurred line between bootstrap and ongoing management
- No clear process for ArgoCD upgrades or configuration changes

---

## Design: Bootstrap → GitOps Transition

### Phase 1: Bootstrap (One-Time, Manual)

**Purpose:** Get the cluster and ArgoCD to a state where GitOps can take over.

**Bootstrap Scripts (`bootstrap/`):**
1. **Cluster Setup** (`start_k8s.sh`)
   - Install k3s/k3d
   - Wait for cluster ready

2. **Initial Infrastructure** (`bootstrap/k8s_plugins.sh`)
   - Install cert-manager (needed for TLS)
   - Install Istio (optional, if needed)
   - Install NGINX Ingress Controller (or rely on cluster default)

3. **ArgoCD Installation** (`bootstrap/install_argocd.sh`) - **NEW**
   - Install ArgoCD core components
   - Create ArgoCD namespace
   - Install ArgoCD via Helm or manifests
   - Configure initial admin user
   - Set up Git repository credentials
   - **Create root application** pointing to GitOps config

**Exit Condition:** ArgoCD is running and can manage itself via GitOps.

---

### Phase 2: GitOps Takes Over (Ongoing)

**Purpose:** Everything else managed by ArgoCD.

**GitOps-Managed Components:**

1. **ArgoCD Self-Management** (`apps/infrastructure/argocd/`)
   - ArgoCD installation manifests (via Helm or raw manifests)
   - ArgoCD configuration (ConfigMaps, Secrets)
   - ArgoCD ApplicationSets
   - ArgoCD Projects (RBAC)
   - ArgoCD Ingress

2. **Infrastructure** (`apps/infrastructure/`)
   - Monitoring (Prometheus, Grafana)
   - NGINX Ingress Controller (if not using cluster default)
   - cert-manager configuration
   - Istio (if using)

3. **Applications** (`apps/`)
   - Media services
   - Homepage
   - All other applications

---

## Proposed Structure

```
k8s_nas/
├── bootstrap/                          # One-time setup scripts
│   ├── bootstrap.sh                    # Main bootstrap orchestrator
│   ├── k8s_plugins.sh                  # Install plugins (cert-manager, Istio)
│   ├── install_argocd.sh               # NEW: Install ArgoCD
│   └── install_istio.sh                # Install Istio (if needed)
│
├── apps/
│   └── infrastructure/
│       ├── argocd/                     # NEW: ArgoCD managed by GitOps
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   ├── argocd-install.yaml     # ArgoCD installation
│       │   ├── argocd-config.yaml       # ConfigMaps, Secrets
│       │   ├── argocd-ingress.yaml      # Ingress for ArgoCD UI
│       │   └── argocd-projects.yaml     # AppProjects
│       ├── monitoring/
│       └── nginx/
│
└── argocd/
    ├── applicationsets/
    │   └── argocd-infrastructure-appset.yaml  # Self-manage ArgoCD
    └── root-app.yaml                   # Bootstrap creates this, points to GitOps
```

---

## Bootstrap Flow

```bash
# 1. Bootstrap script runs
./bootstrap/bootstrap.sh

# 2. Installs cluster + plugins
# 3. Installs ArgoCD via install_argocd.sh
# 4. Creates root application manually
kubectl apply -f root-application.yaml

# 5. Root application points to GitOps
# 6. ArgoCD ApplicationSet for infrastructure creates ArgoCD self-management
# 7. GitOps takes over from here
```

---

## GitOps Flow (After Bootstrap)

```yaml
# root-application.yaml (created by bootstrap)
# Points to: argocd/applicationsets/

# argocd/applicationsets/argocd-infrastructure-appset.yaml
# Creates Application that manages apps/infrastructure/argocd/

# apps/infrastructure/argocd/
# Contains ArgoCD manifests (installation, config, ingress)
# ArgoCD manages itself!
```

---

## Homepage Routing Strategy

### Current State
- Homepage is accessible at `/` (root path)
- All other services at `/service-name`

### Proposed Options

**Option A: Keep Homepage at `/`, No Redirect**
- Homepage at `/`
- Services at `/service-name`
- **Pros:** Simple, standard pattern
- **Cons:** Root path occupied

**Option B: Redirect `/` → `/home`**
- Root path redirects to `/home`
- Homepage at `/home`
- Services at `/service-name`
- **Pros:** Root path available for redirect/landing, clear separation
- **Cons:** Extra redirect hop

**Option C: Nothing at Root, Homepage at `/home`**
- Root path returns 404 or maintenance page
- Homepage at `/home`
- Services at `/service-name`
- **Pros:** Root path intentionally empty, explicit routing
- **Cons:** Users need to know `/home` path

### Recommendation: **Option B** (Redirect `/` → `/home`)

**Rationale:**
- Provides clean landing experience
- Root path remains flexible for future use
- Homepage path is explicit and discoverable
- Single redirect is minimal overhead

**Implementation:**
```yaml
# Ingress at root - redirect only
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: root-redirect
  namespace: homepage
  annotations:
    nginx.ingress.kubernetes.io/permanent-redirect: /home
spec:
  ingressClassName: nginx
  rules:
  - host: home.brettswift.com
    http:
      paths:
      - path: /
        pathType: Exact
        backend:
          service:
            name: homepage
            port:
              number: 80

# Homepage ingress at /home
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homepage-ingress
  namespace: homepage
spec:
  ingressClassName: nginx
  rules:
  - host: home.brettswift.com
    http:
      paths:
      - path: /home
        pathType: Prefix
        backend:
          service:
            name: homepage
            port:
              number: 80
```

---

## Migration Plan

### Step 1: Create ArgoCD GitOps Structure
- [ ] Create `apps/infrastructure/argocd/` directory
- [ ] Create ArgoCD installation manifests (Helm values or raw YAML)
- [ ] Create ArgoCD configuration manifests
- [ ] Create ArgoCD ingress manifest

### Step 2: Update Bootstrap Scripts
- [ ] Create `bootstrap/install_argocd.sh` script
- [ ] Update `bootstrap/bootstrap.sh` to call install_argocd.sh
- [ ] Ensure bootstrap creates root application

### Step 3: Create ArgoCD ApplicationSet for Self-Management
- [ ] Create `argocd/applicationsets/argocd-infrastructure-appset.yaml`
- [ ] Point to `apps/infrastructure/argocd/`
- [ ] Ensure it runs after root application

### Step 4: Test Bootstrap → GitOps Transition
- [ ] Test fresh cluster bootstrap
- [ ] Verify ArgoCD is installed
- [ ] Verify root application is created
- [ ] Verify ArgoCD self-management Application is created
- [ ] Verify GitOps manages ArgoCD

### Step 5: Update Homepage Routing
- [ ] Create root redirect ingress
- [ ] Update homepage ingress to `/home`
- [ ] Update homepage configuration for base path
- [ ] Test redirect and routing

---

## Key Principles

1. **Bootstrap is One-Time Only**
   - Everything needed to get ArgoCD running
   - Creates root application
   - Exits once GitOps can take over

2. **GitOps is Ongoing**
   - ArgoCD manages itself (self-managed)
   - All applications managed via GitOps
   - Configuration changes via Git commits

3. **Clear Separation**
   - Bootstrap scripts = cluster initialization
   - GitOps = application and infrastructure management
   - Bootstrap should not run regularly (only for new clusters)

4. **Idempotency**
   - Bootstrap scripts should be idempotent
   - GitOps provides desired state
   - Can re-run bootstrap safely

---

## Benefits

1. **ArgoCD Self-Management**
   - ArgoCD upgrades via GitOps
   - Configuration changes tracked in Git
   - Consistent with GitOps principles

2. **Clear Boundaries**
   - Bootstrap = one-time setup
   - GitOps = ongoing management
   - No confusion about which tool manages what

3. **Disaster Recovery**
   - Bootstrap script recreates cluster + ArgoCD
   - GitOps restores all applications
   - Clear recovery process

4. **Version Control**
   - All infrastructure in Git
   - ArgoCD configuration versioned
   - Audit trail for changes

---

## Documentation Updates Needed

1. Update `BOOTSTRAP.md` - Document new bootstrap flow
2. Update `README.md` - Explain bootstrap vs GitOps
3. Create `docs/argocd-self-management.md` - How ArgoCD manages itself
4. Update `docs/development-guide.md` - Development workflow
5. Update `docs/deployment-guide.md` - Deployment process

---

## Questions to Resolve

1. **ArgoCD Installation Method:**
   - Helm chart (recommended - easier upgrades)
   - Raw manifests (more control, harder upgrades)
   - **Recommendation:** Helm chart via HelmApplication or HelmRelease

2. **Root Application Creation:**
   - Bootstrap script creates it manually? ✅ (Yes)
   - Or bootstrap script deploys a manifest that creates it?
   - **Recommendation:** Bootstrap creates root application manually (chicken-and-egg problem)

3. **ArgoCD Configuration:**
   - Store in `apps/infrastructure/argocd/`?
   - Or separate `argocd/` directory?
   - **Recommendation:** `apps/infrastructure/argocd/` (consistent with structure)

4. **Homepage Base Path:**
   - `/home` or `/homepage`?
   - **Recommendation:** `/home` (shorter, cleaner)

---

## Next Steps

1. Review this design
2. Decide on ArgoCD installation method (Helm vs manifests)
3. Create `apps/infrastructure/argocd/` structure
4. Implement bootstrap → GitOps transition
5. Update homepage routing




