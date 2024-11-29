#!/bin/bash
set -euo pipefail

# Source environment variables from .env file if it exists
if [ -f .env ]; then
    source .env
fi

# Function to prompt for variable if not set
prompt_var() {
    local var_name=$1
    local prompt_text=$2
    local is_secret=${3:-false}

    if [ -z "${!var_name}" ]; then
        if [ "$is_secret" = true ]; then
            read -s -p "$prompt_text: " value
            echo
        else
            read -p "$prompt_text: " value
        fi
        eval "$var_name='$value'"
    fi
}

# Prompt for AWS credentials if not set
prompt_var "AWS_ACCESS_KEY_ID" "Enter AWS Access Key ID"
prompt_var "AWS_SECRET_ACCESS_KEY" "Enter AWS Secret Access Key" true
prompt_var "AWS_REGION" "Enter AWS Region (e.g., us-east-1)"

# Prompt for VPN credentials if not set
prompt_var "VPN_USERNAME" "Enter VPN Username"
prompt_var "VPN_PASSWORD" "Enter VPN Password" true

# Create infrastructure namespace if it doesn't exist
kubectl create namespace infrastructure --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace downloads --dry-run=client -o yaml | kubectl apply -f -

# Create/update AWS credentials secret
kubectl create secret generic aws-credentials \
    --namespace infrastructure \
    --from-literal=access-key-id="$AWS_ACCESS_KEY_ID" \
    --from-literal=secret-access-key="$AWS_SECRET_ACCESS_KEY" \
    --from-literal=region="$AWS_REGION" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create/update VPN credentials secret
kubectl create secret generic vpn-credentials \
    --namespace downloads \
    --from-literal=username="$VPN_USERNAME" \
    --from-literal=password="$VPN_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets configured successfully!" 