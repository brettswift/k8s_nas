#!/bin/bash
set -euo pipefail

# Bootstrap script for k8s_nas project
# Installs required plugins and optional components

# Ensure we're in the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "=== k8s_nas Bootstrap Script ==="

# Parse command line arguments
INSTALL_ISTIO=false
INSTALL_PLUGINS=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --istio)
            INSTALL_ISTIO=true
            shift
            ;;
        --no-plugins)
            INSTALL_PLUGINS=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --istio       Install Istio service mesh"
            echo "  --no-plugins  Skip installing Kubernetes plugins"
            echo "  --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Install plugins only"
            echo "  $0 --istio           # Install plugins and Istio"
            echo "  $0 --istio --no-plugins  # Install Istio only"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

# Install Kubernetes plugins
if [[ "$INSTALL_PLUGINS" == "true" ]]; then
    echo "Installing Kubernetes plugins..."
    ./bootstrap/k8s_plugins.sh
else
    echo "Skipping plugin installation (--no-plugins specified)"
fi

# Install Istio if requested
if [[ "$INSTALL_ISTIO" == "true" ]]; then
    echo "Installing Istio service mesh..."
    ./bootstrap/install_istio.sh
else
    echo "Skipping Istio installation (use --istio to install)"
fi

# Create starr-secrets Secret (part of initial setup)
echo ""
echo "Creating starr-secrets Secret (if needed)..."
if [ -f "./scripts/create-starr-secrets.sh" ]; then
    ./scripts/create-starr-secrets.sh || echo "⚠️  Secret creation skipped (may already exist)"
else
    echo "⚠️  create-starr-secrets.sh not found, skipping secret creation"
fi

# Setup wildcard certificate for *.home.brettswift.com (requires AWS credentials)
echo ""
echo "Setting up wildcard certificate for *.home.brettswift.com..."
if [ -f "./scripts/setup-home-wildcard-cert.sh" ]; then
    if aws sts get-caller-identity &> /dev/null 2>&1; then
        ./scripts/setup-home-wildcard-cert.sh || echo "⚠️  Certificate setup skipped (may already exist or AWS credentials not configured)"
    else
        echo "⚠️  AWS credentials not configured. Skipping certificate setup."
        echo "    Run 'assume brettswift-mgmt' and then './scripts/setup-home-wildcard-cert.sh' manually"
    fi
else
    echo "⚠️  setup-home-wildcard-cert.sh not found, skipping certificate setup"
fi

# Configure ArgoCD Git repository access
echo ""
echo "Configuring ArgoCD Git repository access..."
if [ -f "./bootstrap/configure-argocd-git.sh" ]; then
    ./bootstrap/configure-argocd-git.sh || echo "⚠️  Git repository setup skipped (may need manual configuration)"
else
    echo "⚠️  configure-argocd-git.sh not found, skipping Git repository setup"
    echo "    See BOOTSTRAP.md section 5 for manual setup instructions"
fi

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Next steps:"
echo "1. Ensure ArgoCD is running: kubectl get pods -n argocd"
echo "2. Configure Git repository credentials (if not done above)"
echo "3. Apply root application: kubectl apply -f root-application.yaml"
echo "4. Access ArgoCD UI: https://localhost:8080"
echo "5. Deploy applications via GitOps"
echo "6. After services deploy, extract API keys: See CONFIGURE_STARR_INTEGRATIONS.md for the command"
echo ""
if [[ "$INSTALL_ISTIO" == "true" ]]; then
    echo "Istio is installed and ready!"
    echo "To enable sidecar injection: kubectl label namespace <namespace> istio-injection=enabled"
fi

