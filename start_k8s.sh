#!/bin/bash
set -euo pipefail

# OS-agnostic Kubernetes setup script using k3s
# Supports macOS, Linux, and Pop!_OS

echo "=== Starting Kubernetes Cluster (k3s) ==="

# Detect OS
OS=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &> /dev/null; then
        OS="ubuntu"  # Includes Pop!_OS
    elif command -v yum &> /dev/null; then
        OS="rhel"
    else
        OS="linux"
    fi
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo "Detected OS: $OS"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first."
    echo "Visit: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if k3d is installed (for macOS) or k3s (for Linux)
if [[ "$OS" == "macos" ]]; then
    if ! command -v k3d &> /dev/null; then
        echo "k3d not found. Installing k3d..."
        if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Please install Homebrew first:"
            echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        brew install k3d
    fi
    
    # Check if k3d cluster is running
    if ! k3d cluster list | grep -q "nas-cluster"; then
        echo "Creating k3d cluster..."
        k3d cluster create nas-cluster --port "30080:30080@loadbalancer" --port "30443:30443@loadbalancer" --k3s-arg "--disable=traefik@server:0"
        export KUBECONFIG=$(k3d kubeconfig write nas-cluster)
    else
        echo "k3d cluster already exists"
        export KUBECONFIG=$(k3d kubeconfig write nas-cluster)
    fi
else
    # Linux - use k3s
    if ! command -v k3s &> /dev/null; then
        echo "k3s not found. Installing k3s..."
        curl -sfL https://get.k3s.io | sh -
        export PATH=$PATH:/usr/local/bin
        echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
    fi
    
    # Check if k3s is running
    if ! systemctl is-active --quiet k3s 2>/dev/null; then
        echo "Starting k3s..."
        sudo systemctl start k3s
        sudo systemctl enable k3s
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    else
        echo "k3s already running"
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    fi
fi

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install required plugins
echo "Installing Kubernetes plugins..."
./k8s_plugins.sh

echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "Setting up ArgoCD admin user..."
# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# Wait for ingress to be ready
echo "Waiting for ingress to be ready..."
sleep 5

# Set up ArgoCD project
echo "Setting up ArgoCD project..."
kubectl apply -f argocd/projects/nas.yaml

# Apply the ArgoCD ingress application
echo "Setting up ArgoCD ingress..."
kubectl apply -f argocd/applications/argocd-ingress.yaml

# Set up app-of-apps pattern for GitOps
echo "Setting up app-of-apps pattern..."
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: nas
  source:
    repoURL: https://github.com/brettswift/k8s_nas.git
    targetRevision: HEAD
    path: argocd/applications
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

# Wait for the applications to be synced
echo "Waiting for ArgoCD applications to sync..."
sleep 10

echo "=== Kubernetes Cluster Started Successfully ==="
echo "ArgoCD is available at: http://localhost:30080/argocd"
echo "Username: admin or bswift"
echo "Password: $ARGOCD_PASSWORD (admin) or 8480 (bswift)"
echo ""
echo "ArgoCD is ready with GitOps enabled!"
echo "Create new apps in argocd/applications/ and they'll auto-sync!"
echo ""
echo "To stop the cluster, run: ./stop_k8s.sh"
