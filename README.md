# Kubernetes NAS

A complete media server solution running on Kubernetes, managed by ArgoCD.

## Repository Structure

```shell
k8s_nas/
├── apps/                      # Application manifests
│   ├── sonarr/
│   ├── radarr/
│   ├── jellyfin/
│   ├── qbittorrent/
│   ├── prowlarr/
│   ├── bazarr/
│   └── jellyseerr/
├── base/                     # Base configurations
│   ├── config/              # Shared configurations
│   ├── namespaces/         # Namespace definitions
│   ├── secrets/            # Secret templates
│   └── storage-classes/    # Storage configurations
├── environments/            # Environment-specific configs
│   └── production/
│       ├── kustomization.yaml
│       ├── values.yaml
│       └── patches/
└── argocd/                  # ArgoCD configurations
    ├── applications/
    └── projects/
```

## Prerequisites

- kubectl
- minikube
- argocd CLI
- helm

## Initial Setup

Run the following setup scripts in order:

```shell
# 1. Configure minikube with required resources
./setup/01_ensure_minikube_setup.sh

# 2. Install and configure ArgoCD
./setup/02_install_argocd.sh

# 3. Configure AWS Route53 and VPN credentials
./setup/03_configure_secrets.sh

# 4. Set up storage directories
./setup/04_configure_storage.sh
```

These scripts will:

- Configure minikube with required resources and addons
- Install and set up ArgoCD
- Create necessary secrets for AWS Route53 and VPN
- Configure storage directories with proper permissions
- Deploy all required infrastructure and applications

## Configuration

### Environment Variables

All configuration is managed in `environments/production/values.yaml`:

- Network settings (hostname, ports)
- Storage paths and sizes
- AWS configuration
- VPN settings

### Storage

- Media storage is shared between pods using a PersistentVolume at `/mnt/data`
- Each application has its own config PVC
- All media apps can access the shared storage

### SSL/DNS

- Uses cert-manager with Route53 DNS validation
- Wildcard certificate for *.home.brettswift.com
- Managed by nginx-ingress

## Applications

### Media Management

- Sonarr: TV Shows
- Radarr: Movies
- Jellyfin: Media Server
- Bazarr: Subtitles

### Downloads

- qBittorrent: Torrent client (VPN protected)
- Prowlarr: Indexer management

### Infrastructure

- nginx-ingress: Ingress controller
- cert-manager: SSL certificate management

## Accessing Services

All services are available at their respective paths:

- ArgoCD: https://home.brettswift.com/argocd
- Homepage: https://home.brettswift.com
- Jellyfin: https://home.brettswift.com/jellyfin
- Sonarr: https://home.brettswift.com/sonarr
- Radarr: https://home.brettswift.com/radarr
- Prowlarr: https://home.brettswift.com/prowlarr
- qBittorrent: https://home.brettswift.com/qbittorrent

## Troubleshooting

Common issues and solutions:

```shell
# Check pod status
kubectl get pods -A

# Check logs
kubectl logs -n <namespace> <pod-name>
```

- VPN connectivity: Check qBittorrent pod logs
- Storage permissions: Verify PVC bindings
- SSL certificates: Check cert-manager pods

## Development

1. Clone this repository
2. Make changes to relevant files
3. Test changes:

```shell
kubectl kustomize environments/production
```

1. Commit and push changes
2. ArgoCD will automatically apply updates

## Maintenance

Monitor system health:

```shell
# Check ArgoCD sync status
argocd app list

# Check certificate status
kubectl get certificates -n infrastructure

# Monitor storage usage
kubectl get pv,pvc --all-namespaces
```
