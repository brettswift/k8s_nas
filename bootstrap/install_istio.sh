#!/bin/bash
set -euo pipefail

# OS-agnostic Istio installation script
# Supports macOS, Linux, and Pop!_OS

echo "=== Installing Istio Service Mesh ==="

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "Kubernetes cluster not accessible. Please ensure cluster is running."
    exit 1
fi

# Check if Istio is already installed
if kubectl get namespace istio-system &> /dev/null; then
    echo "Istio is already installed. Skipping installation."
    exit 0
fi

# Download and install Istio CLI
ISTIO_VERSION="1.20.3"
ISTIO_CLI_URL=""

if [[ "$OS" == "macos" ]]; then
    ISTIO_CLI_URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-osx.tar.gz"
elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "linux" ]]; then
    ISTIO_CLI_URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz"
else
    echo "Unsupported OS for Istio CLI: $OS"
    exit 1
fi

echo "Downloading Istio CLI ${ISTIO_VERSION}..."
cd /tmp
curl -L "${ISTIO_CLI_URL}" | tar xz
sudo mv istioctl /usr/local/bin/
chmod +x /usr/local/bin/istioctl

# Verify istioctl installation
if ! command -v istioctl &> /dev/null; then
    echo "Failed to install istioctl"
    exit 1
fi

echo "Istio CLI installed successfully"

# Install Istio with minimal profile
echo "Installing Istio with minimal profile..."
istioctl install --set values.defaultRevision=default -y

# Wait for Istio to be ready
echo "Waiting for Istio to be ready..."
kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s

# Enable Istio sidecar injection for default namespace (optional)
echo "Enabling Istio sidecar injection for default namespace..."
kubectl label namespace default istio-injection=enabled --overwrite

# Install Istio ingress gateway
echo "Installing Istio ingress gateway..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: istio-ingress
  labels:
    istio-injection: enabled
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: ingress
spec:
  components:
    ingressGateways:
    - name: istio-ingressgateway
      namespace: istio-ingress
      enabled: true
      k8s:
        service:
          type: NodePort
          ports:
          - port: 80
            targetPort: 8080
            name: http2
          - port: 443
            targetPort: 8443
            name: https
EOF

# Wait for ingress gateway to be ready
echo "Waiting for Istio ingress gateway to be ready..."
kubectl wait --for=condition=ready pod -l app=istio-ingressgateway -n istio-ingress --timeout=300s

echo "=== Istio Installation Complete ==="
echo "Istio is now installed and ready!"
echo ""
echo "To verify installation:"
echo "  kubectl get pods -n istio-system"
echo "  kubectl get pods -n istio-ingress"
echo ""
echo "To enable sidecar injection for a namespace:"
echo "  kubectl label namespace <namespace> istio-injection=enabled"
echo ""
echo "Istio ingress gateway is available on NodePort 80/443"
