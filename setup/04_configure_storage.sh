#!/bin/bash
set -euo pipefail

STORAGE_PATH="/mnt/data"

echo "This script will:"
echo "1. Create directory: $STORAGE_PATH (if it doesn't exist)"
echo "2. Set ownership to UID/GID: 1000:1000"
echo "3. Set permissions to: 755"

read -p "Do you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled"
    exit 1
fi

echo "Configuring storage at $STORAGE_PATH..."

# Create storage directory if it doesn't exist
if [ ! -d "$STORAGE_PATH" ]; then
    echo "Creating storage directory at $STORAGE_PATH..."
    sudo mkdir -p "$STORAGE_PATH"
    echo "Created storage directory"
fi

# Set permissions
echo "Setting ownership and permissions..."
sudo chown -R 1000:1000 "$STORAGE_PATH"
sudo chmod -R 755 "$STORAGE_PATH"

echo "Storage configured successfully at $STORAGE_PATH"
echo "Verifying permissions..."
ls -la "$STORAGE_PATH" 