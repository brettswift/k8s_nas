#!/bin/bash
set -euo pipefail

# Configure ArgoCD Git repository access
# This script sets up SSH or HTTPS credentials for ArgoCD to access private Git repositories

echo "=== Configuring ArgoCD Git Repository Access ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "Kubernetes cluster not accessible. Please ensure cluster is running."
    exit 1
fi

# Check if ArgoCD is running
if ! kubectl get namespace argocd &> /dev/null; then
    echo "ArgoCD namespace not found. Please install ArgoCD first."
    exit 1
fi

# Detect SSH key location
SSH_KEY=""
if [ -f ~/.ssh/id_rsa ]; then
    SSH_KEY=~/.ssh/id_rsa
elif [ -f ~/.ssh/id_ed25519 ]; then
    SSH_KEY=~/.ssh/id_ed25519
else
    SSH_KEY=$(find ~/.ssh -name 'id_*' ! -name '*.pub' 2>/dev/null | head -1)
fi

if [ -z "$SSH_KEY" ] || [ ! -f "$SSH_KEY" ]; then
    echo "⚠️  No SSH key found. Skipping SSH repository setup."
    echo "    To use HTTPS instead, set GITHUB_TOKEN environment variable and re-run."
    exit 0
fi

echo "Using SSH key: $SSH_KEY"

# Create known_hosts for GitHub
TMP_KNOWN_HOSTS=$(mktemp)
ssh-keyscan github.com > "$TMP_KNOWN_HOSTS" 2>/dev/null || {
    echo "⚠️  Failed to get GitHub SSH keys. Continuing anyway..."
    echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" > "$TMP_KNOWN_HOSTS"
    echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" >> "$TMP_KNOWN_HOSTS"
    echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOh/gYc935s2myYsG1AvU/upMKOuYfu1kC4wavXktOWBuhz/UbwpnuZNbyV9rFGAUqXobzxPbXVUD62+OXgS7AgvkmFPhtEQ7nBTtN5nTHqOyA52s2EdAWCjJSNAK5LdNG1O1XaZGpQSg0c7t+bz2yIhDh0jfZX28qwkVD4AaWSOy0Ues2XtxNgq/sdwx5DsO0g11EoFqjjlVZ2K9Xlzs56lSOmXNbGzpy51y0mfA4Yl3YMOYiq4boLM2X39XkV0z5wJx9WLzn0J4EQbG39HLFKpokJ8Lg5tw7hkG4orTX8h2nYaYyPvM7vz4qMQ7aUMMlekvpQ/8X1FvJ4sqokE7jIk6S48a2yZf0ormO4F0kQZF6KlHQT1Xvj0os/3BkZ+FZ6AJwqF3EH/OKrKM65pfvX1lJpKOgH2b1tRL1k2PhGci+u5yK4Kf8NFZ48mZ2BtU=" >> "$TMP_KNOWN_HOSTS"
}

# Create SSH secret for ArgoCD
echo "Creating SSH secret for ArgoCD..."
kubectl -n argocd create secret generic repo-github-ssh \
    --from-file=sshPrivateKey="$SSH_KEY" \
    --from-file=known_hosts="$TMP_KNOWN_HOSTS" \
    --dry-run=client -o yaml | kubectl apply -f -

# Clean up temp file
rm -f "$TMP_KNOWN_HOSTS"

echo "✅ SSH secret created: repo-github-ssh"

# Try to add repository via argocd CLI if available
if command -v argocd &> /dev/null; then
    echo "Configuring repository via ArgoCD CLI..."
    
    # Get ArgoCD admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "")
    
    if [ -n "$ARGOCD_PASSWORD" ]; then
        # Port-forward ArgoCD server
        kubectl port-forward -n argocd svc/argocd-server 8080:443 > /dev/null 2>&1 &
        PF_PID=$!
        sleep 3
        
        # Login and add repository
        if argocd login localhost:8080 --insecure --username admin --password "$ARGOCD_PASSWORD" &> /dev/null; then
            if argocd repo add git@github.com:brettswift/k8s_nas.git --ssh-private-key-path "$SSH_KEY" --insecure &> /dev/null; then
                echo "✅ Repository added via ArgoCD CLI"
            else
                echo "⚠️  Failed to add repository via CLI (may already exist)"
            fi
        else
            echo "⚠️  Failed to login to ArgoCD CLI"
        fi
        
        # Clean up port-forward
        kill $PF_PID 2>/dev/null || true
    else
        echo "⚠️  Could not retrieve ArgoCD admin password"
    fi
else
    echo "⚠️  ArgoCD CLI not found. Install it or configure repository via UI:"
    echo "    Settings > Repositories > Connect Repo"
    echo "    Or install CLI: curl -sSL -o /tmp/argocd-linux-amd64 \\"
    echo "      https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
fi

echo ""

