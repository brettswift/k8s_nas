#!/bin/bash

# Jellyfin Data Migration Script
# This script migrates Jellyfin data from docker-compose to Kubernetes

set -e

echo "🎬 Starting Jellyfin data migration..."

# Configuration
DOCKER_COMPOSE_PATH="/Users/bswift/src/brettswift/bs-mediaserver-projects/docker-compose-nas/jellyfin"
SERVER="bswift@10.0.0.20"
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
NAMESPACE="media"
APP_LABEL="app=jellyfin"

echo "📋 Configuration:"
echo "  Docker Compose Path: $DOCKER_COMPOSE_PATH"
echo "  Server: $SERVER"
echo "  Namespace: $NAMESPACE"

# Check if docker-compose data exists
if [ ! -d "$DOCKER_COMPOSE_PATH" ]; then
    echo "❌ Error: Docker compose Jellyfin directory not found at $DOCKER_COMPOSE_PATH"
    exit 1
fi

echo "✅ Found docker-compose Jellyfin data"

# Get the current PVC path
echo "🔍 Finding Kubernetes Jellyfin config volume..."
PVC_PATH=$(ssh $SERVER "export KUBECONFIG=$KUBECONFIG_PATH && kubectl get pvc -n $NAMESPACE jellyfin-config -o jsonpath='{.spec.volumeName}' | xargs -I {} kubectl get pv {} -o jsonpath='{.spec.local.path}'")

if [ -z "$PVC_PATH" ]; then
    echo "❌ Error: Could not find Jellyfin config volume path"
    exit 1
fi

echo "✅ Found Kubernetes volume at: $PVC_PATH"

# Scale down Jellyfin deployment
echo "⏸️  Scaling down Jellyfin deployment..."
ssh $SERVER "export KUBECONFIG=$KUBECONFIG_PATH && kubectl scale deployment jellyfin -n $NAMESPACE --replicas=0"

# Wait for pod to terminate
echo "⏳ Waiting for Jellyfin pod to terminate..."
ssh $SERVER "export KUBECONFIG=$KUBECONFIG_PATH && kubectl wait --for=delete pod -l $APP_LABEL -n $NAMESPACE --timeout=60s"

# Clear the current config directory
echo "🧹 Clearing current Jellyfin config..."
ssh $SERVER "sudo rm -rf $PVC_PATH/* 2>/dev/null || true"

# Copy docker-compose data to Kubernetes volume
echo "📦 Copying docker-compose data to Kubernetes volume..."
ssh $SERVER "sudo mkdir -p $PVC_PATH"
scp -r "$DOCKER_COMPOSE_PATH"/* $SERVER:/tmp/jellyfin-migration/
ssh $SERVER "sudo cp -r /tmp/jellyfin-migration/* $PVC_PATH/ && sudo chown -R 1000:1000 $PVC_PATH/"

# Clean up temp files
ssh $SERVER "rm -rf /tmp/jellyfin-migration/"

# Scale up Jellyfin deployment
echo "▶️  Scaling up Jellyfin deployment..."
ssh $SERVER "export KUBECONFIG=$KUBECONFIG_PATH && kubectl scale deployment jellyfin -n $NAMESPACE --replicas=1"

# Wait for pod to be ready
echo "⏳ Waiting for Jellyfin pod to be ready..."
ssh $SERVER "export KUBECONFIG=$KUBECONFIG_PATH && kubectl wait --for=condition=ready pod -l $APP_LABEL -n $NAMESPACE --timeout=300s"

echo "✅ Jellyfin data migration completed successfully!"
echo "🌐 Jellyfin should now be accessible at: https://home.brettswift.com/jellyfin"
echo "👥 Your old users and library should be available"
