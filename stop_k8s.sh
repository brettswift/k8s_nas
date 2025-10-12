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
    # macOS - kill k3s process
    if [[ -f .k3s_pid ]]; then
        K3S_PID=$(cat .k3s_pid)
        if kill -0 $K3S_PID 2>/dev/null; then
            echo "Stopping k3s (PID: $K3S_PID)..."
            kill $K3S_PID
        fi
        rm -f .k3s_pid
    fi
    # Also kill any remaining k3s processes
    pkill -f k3s || true
else
    # Linux - use systemd
    if systemctl is-active --quiet k3s 2>/dev/null; then
        echo "Stopping k3s service..."
        sudo systemctl stop k3s
    fi
fi

echo "=== Kubernetes Cluster Stopped ==="
echo "To start again, run: ./start_k8s.sh"
