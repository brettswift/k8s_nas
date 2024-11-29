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

1. Start minikube with enough resources:

    `minikube start --cpus 4 --memory 8192 --disk-size 100g`

2. Enable required addons:

    ```shell
    minikube addons enable ingress
    minikube addons enable metrics-server
    ```

3. Install ArgoCD:

    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

4. Access ArgoCD:

    # Get the admin password
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

    # Port forward to access UI
    kubectl port-forward svc/argocd-server -n argocd 8080:443

5. Create required secrets:

    # AWS Route53 credentials for cert-manager
    kubectl create secret generic aws-credentials -n infrastructure \
      --from-literal=access-key-id=YOUR_ACCESS_KEY \
      --from-literal=secret-access-key=YOUR_SECRET_KEY \
      --from-literal=region=YOUR_REGION

    # VPN Credentials
    kubectl create secret generic vpn-credentials -n downloads \
      --from-literal=username=YOUR_VPN_USER \
      --from-literal=password=YOUR_VPN_PASS

6. Configure storage:

    # Create media storage directory
    mkdir -p /mnt/data
    sudo chown -R 1000:1000 /mnt/data

7. Deploy via ArgoCD:

    # Login to ArgoCD
    argocd login localhost:8080

    # Add this repository
    argocd repo add https://github.com/brettswift/k8s_nas.git

    # Create the project
    kubectl apply -f argocd/projects/nas.yaml

    # Deploy core infrastructure (nginx-ingress, cert-manager)
    kubectl apply -f argocd/applications/core-infrastructure.yaml

    # Deploy media applications
    kubectl apply -f argocd/applications/media-apps.yaml

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
- Homepage: https://home.brettswift.com
- Jellyfin: https://home.brettswift.com/jellyfin
- Sonarr: https://home.brettswift.com/sonarr
- Radarr: https://home.brettswift.com/radarr
- Prowlarr: https://home.brettswift.com/prowlarr
- qBittorrent: https://home.brettswift.com/qbittorrent

## Troubleshooting

1. Check pod status:

    kubectl get pods -A

2. Check logs:

    kubectl logs -n <namespace> <pod-name>

3. Common issues:
   - VPN connectivity: Check qBittorrent pod logs
   - Storage permissions: Verify PVC bindings
   - SSL certificates: Check cert-manager pods

## Development

1. Clone this repository
2. Make changes to relevant files
3. Test changes:

    kubectl kustomize environments/production

4. Commit and push changes
5. ArgoCD will automatically apply updates

## Maintenance

1. Monitor ArgoCD sync status:

    argocd app list

2. Check certificate status:

    kubectl get certificates -n infrastructure

3. Monitor storage usage:

    kubectl get pv,pvc --all-namespaces