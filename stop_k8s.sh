#!/bin/bash
set -euo pipefail

echo "=== Stopping Kubernetes Cluster (k3s) ==="

# Stop port forwarding if running
if [[ -f .port_forward_pid ]]; then
    PORT_FORWARD_PID=$(cat .port_forward_pid)
    if kill -0 $PORT_FORWARD_PID 2>/dev/null; then
        echo "Stopping port forwarding (PID: $PORT_FORWARD_PID)..."
        kill $PORT_FORWARD_PID
    fi
    rm -f .port_forward_pid
fi

# Stop k3s
echo "Stopping k3s..."

# Detect OS
OS=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi

if [[ "$OS" == "macos" ]]; then
    # macOS - stop k3d cluster
    if k3d cluster list | grep -q "nas-cluster"; then
        echo "Stopping k3d cluster..."
        k3d cluster stop nas-cluster
    fi
else
    # Linux - use systemd
    if systemctl is-active --quiet k3s 2>/dev/null; then
        echo "Stopping k3s service..."
        sudo systemctl stop k3s
    fi
fi

echo "=== Kubernetes Cluster Stopped ==="
echo "To start again, run: ./start_k8s.sh"
