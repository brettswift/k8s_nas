---
name: k8s_nas
description: Manage the Kubernetes NAS project - a k3s/k3d cluster with ArgoCD GitOps for media server applications. Use when the user needs to start/stop the cluster, check status, enable/disable services, access ArgoCD, or troubleshoot the k8s_nas setup.
---

# k8s_nas Skill

Manage the Kubernetes NAS project running on k3s (Linux) or k3d (macOS) with ArgoCD ApplicationSets for GitOps deployment of media services.

## Overview

The k8s_nas project provides:
- **k3s/k3d**: Lightweight Kubernetes cluster
- **ArgoCD**: GitOps continuous delivery
- **ApplicationSets**: Label-driven application deployment
- **Media Services**: Jellyfin, Radarr, Sonarr, Prowlarr, qBittorrent

## Common Operations

### Start the Cluster

```bash
./start_k8s.sh
```

Options:
- `--bootstrap`: Run bootstrap after startup
- `--bootstrap-istio`: Bootstrap with Istio service mesh

### Stop the Cluster

```bash
./stop_k8s.sh
```

### Check Cluster Status

```bash
# Node status
kubectl get nodes

# All pods
kubectl get pods -A

# ArgoCD applications
kubectl get applications -n argocd

# Cluster labels
kubectl get cluster local-cluster --show-labels
```

### Enable/Disable Services

Services are controlled via cluster labels:

```bash
# Enable a service
kubectl label cluster local-cluster <service>-enabled=true --overwrite

# Disable a service
kubectl label cluster local-cluster <service>-enabled=false --overwrite

# Available services
# - sample-hello (demo app)
# - jellyfin (media server)
# - radarr (movie manager)
# - sonarr (TV show manager)
# - prowlarr (indexer manager)
# - qbittorrent (download client)
```

### Access ArgoCD

```bash
# Port forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

- URL: https://localhost:8080
- Username: `admin` or `bswift`
- Default password: `8480` (bswift user)

### View Application Logs

```bash
# Get pod name
kubectl get pods -n <namespace>

# View logs
kubectl logs -n <namespace> <pod-name>

# Follow logs
kubectl logs -n <namespace> <pod-name> -f
```

## Troubleshooting

### Cluster Won't Start

1. Check if ports are available (30080, 30443, 8080)
2. Verify k3d (macOS) or k3s (Linux) is installed
3. Check Docker/Podman is running (for k3d)

### ArgoCD Not Accessible

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Restart port forward
pkill -f "kubectl port-forward"
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Applications Not Syncing

1. Check cluster labels: `kubectl get cluster local-cluster --show-labels`
2. Verify the service is enabled with `<service>-enabled=true`
3. Check ArgoCD UI for sync errors
4. Verify Git repository is accessible

### Port Conflicts

Common ports used:
- 8080: ArgoCD UI
- 30080: HTTP ingress
- 30443: HTTPS ingress

## Project Structure

```
k8s_nas/
├── start_k8s.sh              # Start cluster
├── stop_k8s.sh               # Stop cluster
├── root-application.yaml     # Root ApplicationSet
├── apps/                     # Application manifests
│   ├── infrastructure/       # ArgoCD, NGINX ingress
│   ├── media-services/       # Media applications
│   └── sample-hello/         # Demo app
├── argocd/applicationsets/   # ApplicationSet definitions
├── environments/             # Environment configs
└── bootstrap/                # Bootstrap scripts
```

## Branch Strategy

- `dev`: Local development (this machine)
- `main`: Production server
- `feat/*`: Feature branches

Always deploy to dev branch for local testing:
```bash
git push origin <feature-branch>:dev
```
