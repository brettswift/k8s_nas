# Production Server Bootstrap Guide

This guide covers setting up a production server with k3s + ArgoCD for GitOps deployment and mirrors the local setup used for development. Follow these steps for localhost first, then apply the same to your target host (home.brettswift.com).

## Prerequisites

- Clean server (Ubuntu/Pop!_OS recommended)
- Root/sudo access
- Internet connectivity
- GitHub repository access (the repo is private)

## 1. Server Setup

### Install k3s
```bash
# Install k3s with disabled Traefik (we'll use NGINX)
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# Add k3s to PATH
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

# Set KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
```

### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Install Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 2. Clone Repository

```bash
# Clone monorepo (private)
# Replace with your Git URL if different
GIT_URL=https://github.com/brettswift/brettswift.git
BRANCH=feat/application_sets

git clone -b "$BRANCH" "$GIT_URL" bswift
cd bswift/bs-mediaserver-projects/k8s_nas

# Make scripts executable
chmod +x start_k8s.sh stop_k8s.sh bootstrap/*.sh
```

## 3. Bootstrap Options

The `start_k8s.sh` script now supports bootstrap options:

### Basic Bootstrap (Plugins Only)
```bash
./start_k8s.sh --bootstrap
```
This will:
- Start the k3s cluster
- Install ArgoCD
- Run bootstrap script with plugins (cert-manager, Istio base)
- Set up ApplicationSets pattern

### Full Bootstrap with Istio
```bash
./start_k8s.sh --bootstrap-istio
```
This will:
- Start the k3s cluster
- Install ArgoCD
- Run bootstrap script with plugins AND Istio service mesh
- Set up ApplicationSets pattern

### Manual Bootstrap
```bash
# Start cluster only
./start_k8s.sh

# Then run bootstrap manually
./bootstrap/bootstrap.sh --istio
```

## 4. Install Kubernetes Plugins (Manual)

If you didn't use the bootstrap option, you can install plugins manually:

```bash
# Install cert-manager and Istio base
./bootstrap/k8s_plugins.sh

# Or install with Istio service mesh
./bootstrap/bootstrap.sh --istio
```

## 4. Install ArgoCD (Local and Prod are the same)

```bash
# Create ArgoCD namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## 5. Configure ArgoCD Access to Private Git (CRITICAL)

Your ArgoCD Applications (root-app, argocd-ingress, etc.) point to a private repo. Without credentials, you will see:

- "failed to list refs: authentication required: Repository not found"

Two supported options are below. Pick one.

### Option A: HTTPS with GitHub Token (PAT)

```bash
# 1) Create a secret with username + PAT (token)
#    - username can be anything non-empty for PAT
#    - token must have repo:read on the private repo
kubectl -n argocd create secret generic repo-github-pat \
  --from-literal=username=bswift \
  --from-literal=password="${GITHUB_TOKEN}"

# 2) Register the repository in ArgoCD using a Repository CR
cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Repository
metadata:
  name: brettswift-monorepo
  namespace: argocd
spec:
  repo: https://github.com/brettswift/brettswift.git
  type: git
  usernameSecret:
    name: repo-github-pat
    key: username
  passwordSecret:
    name: repo-github-pat
    key: password
EOF
```

### Option B: SSH with Deploy Key

```bash
# 1) Create secret with private key (no passphrase) and known_hosts (recommended)
ssh-keyscan github.com > known_hosts
kubectl -n argocd create secret generic repo-github-ssh \
  --from-file=sshPrivateKey=~/.ssh/id_rsa \
  --from-file=known_hosts=known_hosts

# 2) Register repository in ArgoCD
cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Repository
metadata:
  name: brettswift-monorepo-ssh
  namespace: argocd
spec:
  repo: git@github.com:brettswift/brettswift.git
  type: git
  sshPrivateKeySecret:
    name: repo-github-ssh
    key: sshPrivateKey
  knownHosts: |
$(sed 's/^/    /' known_hosts)
EOF
```

> After applying either option, ArgoCD can fetch any path within the repo. The app sources in this project use paths under `bs-mediaserver-projects/k8s_nas`.

## 6. App-of-Apps (Root Application)

This repo follows an app-of-apps pattern (inspired by `argocd-cts-umb-app-of-apps`). The root app points to `argocd/applications/` in this monorepo.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: nas
  source:
    repoURL: https://github.com/brettswift/brettswift.git   # or ssh URL
    targetRevision: HEAD                                    # or a branch, e.g. feat/istio_argo
    path: bs-mediaserver-projects/k8s_nas/argocd/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
```

## 7. Ingress (Local Parity)

- Local: expose ArgoCD at `http://localhost/argocd` (via NGINX Ingress). For dev, you can also use the helper script `./local-argocd-access.sh` (port-forward) while iterating.
- Prod: expose at `https://home.brettswift.com/argocd` (update host in the ingress and configure cert-manager).

If health flips to Unknown, verify:
- Ingress points to `argocd-server` service over HTTP (backend-protocol: HTTP).
- `argocd-server` service targets port 8080.
- NGINX controller is Running and has no errors.

## 8. Create Local Users (admin/bswift)

Use the provided script to set a local ArgoCD user with a bcrypt password and restart the server:

```bash
# Example: set admin to password 8480
./scripts/argocd-local-user.sh admin 8480

# Example: create/enable bswift user with password 8480
./scripts/argocd-local-user.sh bswift 8480
```

## 9. Sample App + Environments

Create a minimal app and env overlays to validate GitOps flow.

```bash
# App base
mkdir -p apps/sample-hello/base
cat > apps/sample-hello/base/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-hello
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sample-hello
  template:
    metadata:
      labels:
        app: sample-hello
    spec:
      containers:
      - name: web
        image: ghcr.io/nginxinc/nginx-unprivileged:alpine
        ports:
        - containerPort: 8080
        command: ["/bin/sh","-c"]
        args: ["echo 'hello from $(ENV_NAME)' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
        env:
        - name: ENV_NAME
          value: base
---
apiVersion: v1
kind: Service
metadata:
  name: sample-hello
spec:
  selector:
    app: sample-hello
  ports:
  - port: 80
    targetPort: 8080
YAML

# Kustomize base
cat > apps/sample-hello/base/kustomization.yaml <<'YAML'
resources:
- deployment.yaml
YAML

# Environments (overlays)
mkdir -p apps/sample-hello/overlays/dev apps/sample-hello/overlays/prod
cat > apps/sample-hello/overlays/dev/kustomization.yaml <<'YAML'
resources:
- ../../base
patches:
- target:
    kind: Deployment
    name: sample-hello
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/env/0/value
      value: dev
YAML

cat > apps/sample-hello/overlays/prod/kustomization.yaml <<'YAML'
resources:
- ../../base
patches:
- target:
    kind: Deployment
    name: sample-hello
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/env/0/value
      value: prod
YAML
```

Create an ArgoCD Application for the sample app (dev overlay):

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-hello-dev
  namespace: argocd
spec:
  project: nas
  source:
    repoURL: https://github.com/brettswift/brettswift.git
    targetRevision: HEAD
    path: bs-mediaserver-projects/k8s_nas/apps/sample-hello/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## 10. Access ArgoCD

### Get admin password (if using the initial secret)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### Access dashboard

- Local URL: `http://localhost/argocd` (via ingress) or `https://localhost:8080` (via port-forward)
- Username: `admin`
- Password: as configured with `scripts/argocd-local-user.sh` (e.g., 8480) or the initial secret

## 11. GitOps Workflow

Once set up, the workflow is:

1. **Create application manifest** in `argocd/applications/`
2. **Commit and push** to your branch (e.g., `feat/istio_argo`)
3. **ArgoCD automatically syncs** the new application

### Example: Adding a new app

```bash
# Commit and push
git add apps/sample-hello argocd/applications/sample-hello-dev.yaml
git commit -m "Add sample-hello dev application"
git push origin "$BRANCH"
```

## 12. Troubleshooting

- **Repository not found / authentication required**:
  - Ensure you created a Repository CR pointing to the monorepo.
  - Ensure credentials secret (PAT or SSH key) exists and names/keys match the CR.
  - Verify ArgoCD can reach GitHub (no firewall/DNS issues).
- **Ingress Unknown/Unhealthy**:
  - Confirm annotations: `nginx.ingress.kubernetes.io/backend-protocol: HTTP` and regex rewrite.
  - Confirm `argocd-server` service targets port 8080.
  - Check NGINX ingress controller logs.
- **Login fails**:
  - Use `./scripts/argocd-local-user.sh admin 8480` to forcibly reset the local admin password.

## 13. Notes

- Pattern inspired by `argocd-cts-umb-app-of-apps` (AWS), adapted for local + home lab (`home.brettswift.com`).
- Local testing should use the same manifests/structure used in prod for parity.
