#!/bin/bash

# Script to update all Starr service deployments with proper volume mounts
# This updates the volume mounts to use the migrated configurations

set -e

STARR_DIR="apps/media-services/starr"

echo "Updating Starr service deployments..."

# Function to update a deployment file
update_deployment() {
    local service_name=$1
    local deployment_file="$STARR_DIR/${service_name}-deployment.yaml"
    
    if [ -f "$deployment_file" ]; then
        echo "Updating $service_name deployment..."
        
        # Update volume mounts to include downloads
        sed -i '' '/- name: media/,/- name: downloads/c\
        - name: media\
          mountPath: /data\
        - name: downloads\
          mountPath: /downloads' "$deployment_file"
        
        # Update volume definitions
        sed -i '' '/- name: config/,/- name: media/c\
      - name: config\
        hostPath:\
          path: /mnt/data/configs/'$service_name'\
          type: Directory\
      - name: media\
        hostPath:\
          path: /mnt/data/media\
          type: Directory\
      - name: downloads\
        hostPath:\
          path: /mnt/data/downloads\
          type: Directory' "$deployment_file"
        
        echo "✓ $service_name deployment updated"
    else
        echo "⚠ $service_name deployment file not found: $deployment_file"
    fi
}

# Update each service
update_deployment "sonarr"
update_deployment "radarr"
update_deployment "lidarr"
update_deployment "bazarr"
update_deployment "prowlarr"
update_deployment "jellyseerr"
update_deployment "sabnzbd"
update_deployment "unpackerr"

echo "All deployments updated!"





