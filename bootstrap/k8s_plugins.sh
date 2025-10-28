#!/bin/bash
set -euo pipefail

# Idempotent Kubernetes plugins installation script
# Installs required plugins for the NAS setup

echo "=== Installing Kubernetes Plugins ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    
    # Detect OS
    OS=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    fi
    
    if [[ "$OS" == "macos" ]]; then
        # macOS - use Homebrew
        if command -v brew &> /dev/null; then
            brew install helm
        else
            # Fallback to direct install
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        fi
    else
        # Linux - use official installer
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
else
    echo "Helm already installed: $(helm version --short)"
fi

# Install NVIDIA Container Toolkit (for GPU support)
echo "Installing NVIDIA Container Toolkit..."
if ! command -v nvidia-container-runtime &> /dev/null; then
    # Add NVIDIA repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # Update package list and install
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    
    echo "NVIDIA Container Toolkit installed successfully"
else
    echo "NVIDIA Container Toolkit already installed"
fi

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add cert-manager https://charts.jetstack.io
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Note: NGINX Ingress Controller removed - using Istio for ingress instead

# Install cert-manager
echo "Installing cert-manager..."
if ! kubectl get namespace cert-manager &> /dev/null; then
    kubectl create namespace cert-manager
fi

if ! helm list -n cert-manager | grep -q cert-manager; then
    helm install cert-manager cert-manager/cert-manager \
        --namespace cert-manager \
        --version v1.13.0 \
        --set installCRDs=true
else
    echo "cert-manager already installed"
fi

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --namespace cert-manager \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Install Istio (optional - for future use)
echo "Installing Istio..."
if ! kubectl get namespace istio-system &> /dev/null; then
    kubectl create namespace istio-system
fi

if ! helm list -n istio-system | grep -q istio-base; then
    # Install Istio base
    helm install istio-base istio/base \
        --namespace istio-system \
        --version 1.19.0
    
    # Install Istiod
    helm install istiod istio/istiod \
        --namespace istio-system \
        --version 1.19.0 \
        --set global.configValidation=false
    
    # Install Istio ingress gateway
    helm install istio-ingressgateway istio/gateway \
        --namespace istio-system \
        --version 1.19.0
else
    echo "Istio already installed"
fi

# Wait for Istio to be ready
echo "Waiting for Istio to be ready..."
kubectl wait --namespace istio-system \
    --for=condition=ready pod \
    --selector=app=istiod \
    --timeout=300s

echo "=== Kubernetes Plugins Installation Complete ==="
echo "Installed components:"
echo "- NVIDIA Container Toolkit (GPU support)"
echo "- cert-manager"
echo "- Istio (base, istiod, ingress-gateway)"
echo "- Helm repositories updated"
echo ""
echo "Note: NGINX Ingress Controller removed - using Istio for ingress"
