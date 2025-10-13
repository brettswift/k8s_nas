#!/bin/bash

# Local ArgoCD Access Script
# This script sets up port forwarding to ArgoCD and provides login information

set -e

echo "🚀 Setting up ArgoCD local access..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if ArgoCD is running
if ! kubectl get pods -n argocd | grep -q "argocd-server.*Running"; then
    echo "❌ ArgoCD server not running. Please start ArgoCD first."
    exit 1
fi

# Get the ArgoCD server pod name
ARGOCD_POD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')

if [ -z "$ARGOCD_POD" ]; then
    echo "❌ Could not find ArgoCD server pod."
    exit 1
fi

echo "📡 Found ArgoCD pod: $ARGOCD_POD"

# Kill any existing port forwards
pkill -f "kubectl port-forward.*argocd" 2>/dev/null || true

# Start port forward
echo "🔗 Starting port forward..."
kubectl port-forward pod/$ARGOCD_POD -n argocd 8080:8080 &
PORT_FORWARD_PID=$!

# Save PID for cleanup
echo $PORT_FORWARD_PID > .argocd_port_forward_pid

# Wait for port forward to be ready
sleep 3

echo ""
echo "✅ ArgoCD is now accessible!"
echo ""
echo "🌐 URL: https://localhost:8080"
echo ""
echo "👤 Login Options:"
echo "   Username: admin"
echo "   Password: 8480"
echo ""
echo "   Username: bswift"
echo "   Password: 8480"
echo ""
echo "📝 Note: You'll need to accept the self-signed certificate warning in your browser."
echo ""
echo "🛑 To stop the port forward, run:"
echo "   pkill -f 'kubectl port-forward.*argocd'"
echo "   or kill \$(cat .argocd_port_forward_pid)"
echo ""
echo "🔍 Port forward PID: $PORT_FORWARD_PID"
