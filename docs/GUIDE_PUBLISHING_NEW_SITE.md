# Guide: Publishing a New Website/App to k8s_nas

> Complete playbook from zero to deployed, capturing all the gotchas from the maritime-vacation-site deployment (BUD-86).

## Overview

This guide covers the full flow from application code → Docker image → GitOps deployment on the k3s cluster at `home.brettswift.com`.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  GitHub: brettswift/Incubator_projects (mono-repo incubator)                │
│  └── maritime-vacation-site/                                                │
│      ├── Dockerfile                                                         │
│      ├── nginx.conf, index.html, *.js, *.css                               │
│      └── builds via GitHub Actions → ghcr.io/brettswift/<image>            │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GitHub: brettswift/k8s_nas (live branch)                                   │
│  └── apps/maritime-vacation-site/base/                                      │
│      ├── deployment.yaml     (image ref, ghcr-pull secret)                 │
│      ├── service.yaml                                                         │
│      ├── ingress.yaml        (vacation.home.brettswift.com)                │
│      └── namespace.yaml                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  ArgoCD Application                                                          │
│  └── maritime-vacation-site-appset.yaml → git@github.com:brettswift/k8s_nas │
│      path: apps/maritime-vacation-site/base                                  │
│      targetRevision: live                                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  k3s Cluster (10.1.0.20)                                                    │
│  └── namespace: maritime-vacation-site                                      │
│      └── pod running private image → needs ghcr-pull secret                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Critical Rules

### 1. NEVER Use buddybs

| Aspect | Correct | WRONG |
|--------|---------|-------|
| Repo | `brettswift/*` | `buddybs/*` |
| GHCR image | `ghcr.io/brettswift/my-app:latest` | `ghcr.io/buddybs/my-app:latest` |
| GitHub token | brettswift scoped | buddybs token (can't push brettswift) |

**Why:** The cluster has `ghcr-pull` secret configured for brettswift GHCR only. buddybs images require different auth.

### 2. GitHub Actions Permissions (Private Repo)

If Incubator_projects is **private**, the workflow needs explicit permissions:

```yaml
permissions:
  contents: read
  packages: write
```

Without this, `actions/checkout@v4` fails on empty repos.

### 3. Incubator Repo Structure

```
branch: main
|
├── README.md                      # Mono-repo incubator description
│
├── .github/workflows/
│   └── build-maritime-vacation-site.yaml
│
└── maritime-vacation-site/        # NESTED folder per project
    ├── Dockerfile
    ├── nginx.conf
    └── ... app files
```

**Key:** Each project is a **nested folder**, not repo root.

---

## Step-by-Step Deployment

### Phase 1: Build the Image

1. **Create/accept repo invite** to `brettswift/Incubator_projects`
2. **Push application** to nested folder:
   ```bash
   # ~/src/incubator_brettswift/
   mkdir -p maritime-vacation-site
   cp app-files/* maritime-vacation-site/
   git add .
   git commit -m "Add maritime-vacation-site"
   git push origin main
   ```
3. **Workflow builds automatically** → `ghcr.io/brettswift/maritime-vacation-site:latest`
4. **Make image public** (or ensure it's private but authenticated)

### Phase 2: GHCR Authentication

**The Problem:** Private images on GHCR require authentication, even for same-org pulls.

**The Fix:** Create `ghcr-pull` secret in your namespace:

```bash
# Copy from an existing namespace that has it
kubectl get secret ghcr-pull -n f1-predictor -o yaml | \
  sed 's/namespace: f1-predictor/namespace: maritime-vacation-site/' | \
  kubectl apply -f -

# Or create fresh:
kubectl create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username=brettswift \
  --docker-password=<GITHUB_TOKEN> \
  -n maritime-vacation-site
```

### Phase 3: Add k8s Manifests

In `brettswift/k8s_nas` on branch `live`:

```bash
mkdir -p apps/maritime-vacation-site/base
```

Files:

**namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: maritime-vacation-site
```

**deployment.yaml** (CRITICAL: imagePullSecrets):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maritime-vacation-site
  namespace: maritime-vacation-site
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maritime-vacation-site
  template:
    metadata:
      labels:
        app: maritime-vacation-site
    spec:
      imagePullSecrets:
      - name: ghcr-pull          # ← REQUIRED for private GHCR images
      containers:
      - name: app
        image: ghcr.io/brettswift/maritime-vacation-site:latest
```

**service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: maritime-vacation-site
  namespace: maritime-vacation-site
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
  selector:
    app: maritime-vacation-site
```

**ingress.yaml** (CRITICAL: TLS secret reference):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: maritime-vacation-site
  namespace: maritime-vacation-site
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    external-dns.alpha.kubernetes.io/hostname: vacation.home.brettswift.com
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - vacation.home.brettswift.com
    secretName: vacation-home-brettswift-com-tls  # ← cert-manager creates this
  rules:
  - host: vacation.home.brettswift.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: maritime-vacation-site
            port:
              number: 80
```

**kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: maritime-vacation-site

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

### Phase 4: Add ArgoCD Application

**CRITICAL:** ArgoCD won't deploy without an Application resource!

In `argocd/applicationsets/maritime-vacation-site-appset.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: maritime-vacation-site
  namespace: argocd
  labels:
    app.kubernetes.io/name: maritime-vacation-site
    category: website
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "30"
spec:
  project: apps
  source:
    repoURL: git@github.com:brettswift/k8s_nas.git
    targetRevision: live
    path: apps/maritime-vacation-site/base
  destination:
    server: https://kubernetes.default.svc
    namespace: maritime-vacation-site
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

Commit to `live` branch:
```bash
git add apps/maritime-vacation-site/ argocd/applicationsets/
git commit -m "feat: deploy maritime-vacation-site"
git push origin live
```

---

## The Gotchas (Gap Documentation)

### Gap 1: Image Pull Failures (401 Unauthorized)

**Symptom:** Pod stuck `ImagePullBackOff`, events show:  
`Failed to pull image "ghcr.io/brettswift/...": rpc error: code = Unknown desc = failed to pull and unpack image: failed to resolve reference: unexpected status code 401 Unauthorized`

**Root Cause:** Private GHCR images require authentication token.

**Fix:** Add `imagePullSecrets` to Deployment AND ensure `ghcr-pull` secret exists:
```bash
kubectl get secret ghcr-pull -n <namespace>
# If missing, copy from a working namespace
```

### Gap 2: ArgoCD Not Syncing (App Not Found)

**Symptom:** `kubectl get pods -n <namespace>` → "No resources in <namespace> namespace"

**Root Cause:** Missing ArgoCD Application resource.

**Fix:** Create `argocd/applicationsets/<app>-appset.yaml`

### Gap 3: Wrong GitHub Org (buddybs vs brettswift)

**Symptom:** Image pushes fail, or ArgoCD refuses to pull (wrong GHCR namespace).

**Root Cause:** Using buddybs token/repos instead of brettswift.

**Fix:** Always verify:
- GitHub token scope (brettswift)
- Image tag (`ghcr.io/brettswift/...`)
- Repo URL (`git@github.com:brettswift/...`)

### Gap 4: TLS/HTTPS Not Working

**Symptom:** Site serves on HTTP but 404/500 on HTTPS.

**Root Cause:** Missing or incorrect `secretName` in Ingress TLS block.

**Fix:** Ensure cert-manager has created the secret:
```bash
kubectl get secret vacation-home-brettswift-com-tls -n maritime-vacation-site
```

---

## Verification Checklist

After pushing to `live` branch:

```bash
# 1. ArgoCD Application exists
kubectl get application -n argocd maritime-vacation-site

# 2. Application is synced
kubectl get application -n argocd maritime-vacation-site -o jsonpath='{.status.sync.status}'
# Expected: Synced

# 3. Pods are running
kubectl get pods -n maritime-vacation-site

# 4. Service endpoints work
kubectl get svc -n maritime-vacation-site

# 5. Ingress is configured
kubectl get ingress -n maritime-vacation-site

# 6. Certificate is ready
kubectl get certificate -n maritime-vacation-site
# or check TLS secret exists

# 7. Site is accessible
curl -sv https://vacation.home.brettswift.com 2>&1 | head -20
```

---

## Quick Reference: File Locations

| Purpose | Path |
|---------|------|
| App source code | `brettswift/Incubator_projects/<project>/` |
| Docker build workflow | `brettswift/Incubator_projects/.github/workflows/build-<project>.yml` |
| K8s manifests | `brettswift/k8s_nas/apps/<project>/base/` |
| ArgoCD Application | `brettswift/k8s_nas/argocd/applicationsets/<project>-appset.yaml` |
| Live deploy branch | `live` |
| Images | `ghcr.io/brettswift/<project>:latest` |

---

## Quick Reference: Commands

```bash
# Check ArgoCD sync status
kubectl get applications -n argocd

# Check pod status
kubectl get pods -n <namespace> -w

# Check pod events
kubectl describe pod -n <namespace> <pod-name>

# Check image pull errors
kubectl get events -n <namespace> --field-selector reason=Failed

# Force ArgoCD sync (if stuck)
argocd app sync <app-name>  # or use ArgoCD UI

# Copy ghcr-pull secret between namespaces
kubectl get secret ghcr-pull -n <source-ns> -o yaml | \
  sed 's/namespace: <source-ns>/namespace: <target-ns>/' | \
  kubectl apply -f -

# Verify image exists on GHCR
curl -H "Authorization: Bearer $(echo $GITHUB_TOKEN)" \
  https://ghcr.io/v2/brettswift/<project>/tags/list
```

---

## Lessons Learned

1. **Always use brettswift repos/images** — never buddybs for production
2. **Private GHCR requires imagePullSecrets** — even within the same org
3. **ArgoCD needs an Application resource** — k8s manifests alone aren't enough
4. **Check the actual error** — `kubectl describe pod`/`kubectl get events` tells you everything
5. **Cert-manager creates TLS secrets** — reference them correctly in Ingress
6. **The live branch is the source of truth** — ArgoCD watches it, not main

---

*Document created from gaps fixed during BUD-86 deployment (maritime-vacation-site).*
