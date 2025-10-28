#!/bin/bash

# Migration script to copy Starr service configurations from docker-compose to Kubernetes PVCs
# This script should be run on the server to migrate existing configurations

set -e

echo "Starting Starr services configuration migration..."

# Base paths
DOCKER_COMPOSE_PATH="/home/bswift/src/docker-compose-nas_2"
K8S_MOUNT_PATH="/mnt/data/configs"

# Create the configs directory if it doesn't exist
sudo mkdir -p "$K8S_MOUNT_PATH"

# Function to copy service config
copy_service_config() {
    local service_name=$1
    local source_path="$DOCKER_COMPOSE_PATH/$service_name"
    local dest_path="$K8S_MOUNT_PATH/$service_name"
    
    if [ -d "$source_path" ]; then
        echo "Copying $service_name configuration..."
        sudo cp -r "$source_path" "$dest_path"
        sudo chown -R 1000:1000 "$dest_path"
        echo "✓ $service_name configuration copied"
    else
        echo "⚠ $service_name source directory not found: $source_path"
    fi
}

# Copy configurations for each service
copy_service_config "sonarr"
copy_service_config "radarr"
copy_service_config "lidarr"
copy_service_config "bazarr"
copy_service_config "prowlarr"
copy_service_config "jellyseerr"
copy_service_config "sabnzbd"

# Create unpackerr config directory (it doesn't have persistent config in docker-compose)
sudo mkdir -p "$K8S_MOUNT_PATH/unpackerr"
sudo chown -R 1000:1000 "$K8S_MOUNT_PATH/unpackerr"

echo "Migration completed!"
echo "Configurations copied to: $K8S_MOUNT_PATH"
echo ""
echo "Next steps:"
echo "1. Update Kubernetes deployments to use the migrated configurations"
echo "2. Restart the Starr services to pick up the new configurations"
echo "3. Verify API keys and service connections"
