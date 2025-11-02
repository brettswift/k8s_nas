# Development Guide

**Project:** k8s_nas  
**Last Updated:** 2025-11-01

## Prerequisites

### Required Software

- **kubectl** (v1.25+): Kubernetes command-line tool
- **k3s** (Linux) or **k3d** (macOS): Lightweight Kubernetes distribution
- **Helm** (v3.0+): Package manager for Kubernetes
- **Git**: Version control
- **Docker**: Container runtime (via k3s/k3d)

### macOS Setup

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install kubectl
brew install kubectl

# Install k3d
brew install k3d

# Install Helm
brew install helm
```

### Linux Setup

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/brettswift/k8s_nas.git
cd k8s_nas
```

### 2. Start Local Cluster

**macOS (k3d):**
```bash
./start_k8s.sh
```

**Linux (k3s):**
```bash
./start_k8s.sh
```

This script will:
- Create/start k3s/k3d cluster
- Install ArgoCD
- Set up ArgoCD projects
- Configure root application

### 3. Access ArgoCD

**Port Forward:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Access UI:**
- URL: `https://localhost:8080`
- Username: `admin` or `bswift`
- Password: Run `./get-argocd-password.sh` to get admin password, or use `8480` for `bswift`

### 4. Configure KUBECONFIG

**macOS (k3d):**
```bash
export KUBECONFIG=$(k3d kubeconfig write nas-cluster)
```

**Linux (k3s):**
```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

## Local Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feat/my-feature
```

### 2. Make Changes

Edit Kubernetes manifests in `apps/` directory:

```bash
# Example: Add new environment variable to Sonarr
vim apps/media-services/starr/sonarr-deployment.yaml
```

### 3. Test Locally

**Validate Manifests:**
```bash
kubectl apply --dry-run=client -f apps/media-services/starr/
```

**Deploy to Local Cluster:**
```bash
# Apply directly (for testing)
kubectl apply -f apps/media-services/starr/

# Or use ArgoCD sync
argocd app sync media-services-production-cluster -n argocd
```

### 4. Commit and Push

```bash
git add apps/
git commit -m "feat: add new configuration"
git push origin feat/my-feature
```

### 5. ArgoCD Auto-Sync

If using `dev` branch:
- ArgoCD watches repository
- Changes automatically synced to cluster
- Monitor sync status in ArgoCD UI

## Build Process

### Kubernetes Manifests

This project uses **Kustomize** for configuration management:

```bash
# Build and preview
kubectl kustomize apps/media-services/starr/

# Apply with Kustomize
kubectl apply -k apps/media-services/starr/
```

### Kustomize Overlays

Environment-specific configurations:

```bash
# Development overlay
kubectl kustomize apps/sample-hello/overlays/dev/

# Production overlay
kubectl kustomize apps/sample-hello/overlays/prod/
```

## Running Services Locally

### Check Service Status

```bash
# All pods
kubectl get pods -A

# Media services
kubectl get pods -n media

# Infrastructure services
kubectl get pods -n argocd
kubectl get pods -n monitoring
```

### Access Services

**Via Port Forward:**
```bash
# Sonarr
kubectl port-forward svc/sonarr -n media 8989:8989
# Access: http://localhost:8989

# Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
# Access: http://localhost:3000
```

**Via Ingress (if configured):**
- Services accessible via `https://home.brettswift.com/<service>` on production
- Local development typically uses port-forwarding

## Testing

### Validation Tests

**Manifest Validation:**
```bash
# Dry-run apply
kubectl apply --dry-run=client -f apps/

# Validate with kustomize
kubectl kustomize apps/media-services/starr/
```

**ArgoCD Sync Test:**
```bash
# Check sync status
argocd app get media-services-production-cluster

# Force sync
argocd app sync media-services-production-cluster
```

### Integration Tests

```bash
# Run QA tests
./scripts/qa-tests.sh
```

### Health Checks

```bash
# Check pod health
kubectl get pods -n media

# Check service endpoints
kubectl get endpoints -n media

# View logs
kubectl logs -n media deployment/sonarr
```

## Common Development Tasks

### Add New Service

1. **Create Service Directory:**
```bash
mkdir -p apps/media-services/new-service/base
```

2. **Create Manifests:**
- `deployment.yaml`: Pod specification
- `service.yaml`: Service definition
- `ingress.yaml`: External routing
- `kustomization.yaml`: Kustomize config

3. **Create ApplicationSet:**
```bash
# Create argocd/applicationsets/new-service-appset.yaml
```

4. **Test and Deploy:**
```bash
kubectl apply -k apps/media-services/new-service/
```

### Modify Existing Service

1. **Edit Manifest:**
```bash
vim apps/media-services/starr/sonarr-deployment.yaml
```

2. **Apply Changes:**
```bash
# Direct apply (testing)
kubectl apply -f apps/media-services/starr/sonarr-deployment.yaml

# Or via ArgoCD (production)
git commit -am "Update Sonarr configuration"
git push
# ArgoCD auto-syncs
```

### Update Service Image

Edit `deployment.yaml`:
```yaml
spec:
  template:
    spec:
      containers:
      - name: sonarr
        image: docker.io/linuxserver/sonarr:latest  # Update tag here
```

### Add Environment Variable

**Option 1: ConfigMap (shared):**
```yaml
# apps/media-services/starr/common-configmap.yaml
data:
  NEW_VAR: "value"
```

Reference in deployment:
```yaml
env:
- name: NEW_VAR
  valueFrom:
    configMapKeyRef:
      name: starr-common-config
      key: NEW_VAR
```

**Option 2: Direct (service-specific):**
```yaml
# In deployment.yaml
env:
- name: NEW_VAR
  value: "value"
```

### Modify Resource Limits

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Debugging

### View Logs

```bash
# Pod logs
kubectl logs -n media deployment/sonarr

# Follow logs
kubectl logs -n media deployment/sonarr -f

# Previous container (if restarted)
kubectl logs -n media deployment/sonarr --previous
```

### Describe Resources

```bash
# Pod details
kubectl describe pod -n media sonarr-xxx

# Deployment details
kubectl describe deployment -n media sonarr

# Service details
kubectl describe service -n media sonarr
```

### Exec into Container

```bash
kubectl exec -it -n media deployment/sonarr -- /bin/sh
```

### Check Events

```bash
# Namespace events
kubectl get events -n media --sort-by='.lastTimestamp'

# All events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Code Style and Conventions

### YAML Formatting

- Use 2-space indentation
- Always include `apiVersion` and `kind`
- Use meaningful resource names
- Include namespace in metadata

### Naming Conventions

- **Deployments**: Use service name (lowercase)
- **Services**: Use service name (lowercase)
- **ConfigMaps**: Use `{service}-config` or `{category}-common-config`
- **Namespaces**: Use category names (media, monitoring, infrastructure)

### Resource Organization

```
apps/
└── <category>/
    └── <service>/
        ├── deployment.yaml
        ├── service.yaml
        ├── ingress.yaml
        ├── configmap.yaml (optional)
        └── kustomization.yaml
```

## Git Workflow

### Story-Based Branch Strategy

**Principle:** Each story gets its own branch. Stories drive branches, not sprints.

#### Branch Naming Convention

- **Story branches**: `feat/{story-id}-{story-name}`
  - Example: `feat/1-2-configure-sonarr-prowlarr`
  - Created off the current deployment branch (currently `dev_starr`)
  - **This is the MANDATORY process for ALL stories**

#### Main Branches

- **`dev_starr`**: Development deployment branch (ArgoCD watches this branch)
- **`main`**: Production deployments (future use)

#### Workflow

**This is the MANDATORY process for ALL stories.**

1. **Create Feature Branch**:
   - Create branch off current deployment branch (currently `dev_starr`): `git checkout dev_starr && git pull origin dev_starr`
   - Create feature branch: `git checkout -b feat/{story-id}-{story-name}`
   - Push to remote: `git push -u origin feat/{story-id}-{story-name}`

2. **Development**:
   - Developer works on feature branch
   - All commits go to feature branch
   - Frequent commits recommended

3. **Mid-Story Deployment** (for testing during development):
   - Push feature branch directly to dev_starr: `git push origin feat/{branch}:dev_starr`
   - This triggers ArgoCD to sync from dev_starr without switching ArgoCD tracking branches
   - **Why?** ArgoCD tracks `dev_starr`, so pushing to it avoids reconfiguring ArgoCD
   - Use this anytime during development to test changes

4. **Story Completion**:
   - Story must be QA'd first
   - Merge feature branch to dev_starr: `git checkout dev_starr && git pull origin dev_starr`
   - Merge with --no-ff: `git merge feat/{story-id}-{story-name} --no-ff`
   - Push dev_starr: `git push origin dev_starr`
   - Delete feature branch: `git branch -d feat/{story-id}-{story-name}` (and remote: `git push origin --delete feat/{story-id}-{story-name}`)
   - **Important:** The `--no-ff` flag creates a merge commit visible in history

#### Branch Lifecycle Example

```bash
# 1. Create feature branch (off current deployment branch dev_starr)
git checkout dev_starr
git pull origin dev_starr
git checkout -b feat/1-2-configure-sonarr-prowlarr
git push -u origin feat/1-2-configure-sonarr-prowlarr

# 2. Development work (Dev commits)
git commit -m "feat(story-1.2): add Prowlarr to kustomization"
git commit -m "feat(story-1.2): extract Prowlarr API key"
git push

# 3. Mid-story deployment for testing (can do this multiple times)
git push origin feat/1-2-configure-sonarr-prowlarr:dev_starr
# ArgoCD automatically syncs from dev_starr

# 4. Story complete - QA done, merge to dev_starr
git checkout dev_starr
git pull origin dev_starr
git merge feat/1-2-configure-sonarr-prowlarr --no-ff
git push origin dev_starr
git branch -d feat/1-2-configure-sonarr-prowlarr
git push origin --delete feat/1-2-configure-sonarr-prowlarr
```

### Commit Messages

Use conventional commits with story reference:
- `feat(story-1.2): add Prowlarr to kustomization`
- `fix(story-1.2): correct Prowlarr ingress configuration`
- `docs(story-1.2): update integration documentation`
- `refactor(story-1.2): reorganize manifest structure`

### Deployment Process

**Standard Flow:**
1. Story completed → Merge to dev_starr
2. ArgoCD automatically syncs from dev_starr
3. Changes deployed to cluster

**Mid-Story Testing Flow:**
1. Push feature branch to dev_starr: `git push origin feat/{branch}:dev_starr`
2. ArgoCD syncs immediately from dev_starr
3. Test changes
4. Continue development on feature branch
5. Repeat step 1 as needed during development
6. When story is complete and QA'd, merge with `--no-ff` as described above

## Troubleshooting

### Cluster Not Starting

```bash
# Check k3s status
systemctl status k3s  # Linux
k3d cluster list      # macOS

# Restart cluster
sudo systemctl restart k3s  # Linux
k3d cluster delete nas-cluster && k3d cluster create nas-cluster  # macOS
```

### ArgoCD Not Syncing

```bash
# Check ArgoCD status
kubectl get pods -n argocd

# Check Application status
argocd app list

# Force refresh
argocd app get <app-name>
argocd app sync <app-name>
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Check ingress
kubectl get ingress -n <namespace>

# Test service internally
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://<service>.<namespace>.svc.cluster.local:<port>
```

## Next Steps

- See [Deployment Guide](./deployment-guide.md) for production deployment
- See [Architecture Documentation](./architecture.md) for system design
- See [Project Overview](./project-overview.md) for high-level overview

