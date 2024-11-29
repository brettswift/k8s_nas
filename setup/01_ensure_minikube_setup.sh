#!/bin/bash
set -euo pipefail

echo "Checking minikube installation..."
if ! command -v minikube &> /dev/null; then
    echo "minikube not found. Please install minikube first:"
    echo "Visit: https://minikube.sigs.k8s.io/docs/start/"
    echo "Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
    echo "       sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi

echo "Checking kubectl installation..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first:"
    echo "Visit: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
    echo "Linux: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "       sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
    exit 1
fi

echo "Checking minikube status..."
if ! minikube status | grep -q "Running"; then
    echo "Starting minikube with required resources..."
    minikube start --cpus 4 --memory 8192 --disk-size 100g
else
    echo "Minikube already running, checking resources..."
    current_cpus=$(minikube config view | grep cpus || echo "0")
    current_memory=$(minikube config view | grep memory || echo "0")
    
    if [[ "$current_cpus" -lt "4" ]] || [[ "$current_memory" -lt "8192" ]]; then
        echo "Minikube running with insufficient resources. Recreating..."
        minikube delete
        minikube start --cpus 4 --memory 8192 --disk-size 100g
    fi
fi

echo "Enabling required addons..."
minikube addons enable ingress
minikube addons enable metrics-server

echo "Verifying addons..."
if ! minikube addons list | grep -q "ingress: enabled"; then
    echo "Failed to enable ingress addon"
    exit 1
fi

if ! minikube addons list | grep -q "metrics-server: enabled"; then
    echo "Failed to enable metrics-server addon"
    exit 1
fi

echo "Minikube setup complete and verified!" 