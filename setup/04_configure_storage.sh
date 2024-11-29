#!/bin/bash
set -euo pipefail

# Ensure we're running from the repository root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

STORAGE_PATH="/mnt/data"
if [ "$ENVIRONMENT" = "development" ]; then
    STORAGE_PATH="$REPO_ROOT/dev_storage"
fi

echo "Verifying storage at $STORAGE_PATH..."

# Verify storage directory exists
if [ ! -d "$STORAGE_PATH" ]; then
    echo "Error: Storage directory $STORAGE_PATH does not exist"
    exit 1
fi

# Verify permissions
if [ ! -w "$STORAGE_PATH" ]; then
    echo "Error: Storage directory $STORAGE_PATH is not writable"
    exit 1
fi

# Verify ownership (for production path only)
if [ "$STORAGE_PATH" = "/mnt/data" ]; then
    OWNER=$(stat -c '%u:%g' "$STORAGE_PATH")
    if [ "$OWNER" != "1000:1000" ]; then
        echo "Error: Storage directory $STORAGE_PATH must be owned by 1000:1000"
        echo "Current ownership: $OWNER"
        exit 1
    fi
fi

echo "Storage configuration verified at $STORAGE_PATH"
echo "Permissions:"
ls -la "$STORAGE_PATH"