# Kubernetes NAS - ArgoCD ApplicationSets GitOps

A clean Kubernetes setup with ArgoCD ApplicationSets for label-driven GitOps deployment of media server applications.

## Quick Start

1. **Start the cluster:**
   ```bash
   ./start_k8s.sh
   ```

2. **Access ArgoCD:**
   - URL: https://localhost:8080 (port forward)
   - Username: `admin` or `bswift`
   - Password: `8480`

3. **Deploy applications:**
   ```bash
   # Enable a service (e.g., sample-hello)
   kubectl label cluster local-cluster sample-hello-enabled=true
   
   # Deploy to dev environment
   git push origin feat/application_sets:dev
   ```

4. **Stop the cluster:**
   ```bash
   ./stop_k8s.sh
   ```

## Architecture

- **k3s**: Lightweight Kubernetes cluster
- **NGINX Ingress**: Ingress controller
- **ArgoCD ApplicationSets**: Label-driven application deployment
- **Environment-based**: `dev` branch for local development, `main` for production

## Repository Structure

```
k8s_nas/
├── start_k8s.sh              # Start k3s + ArgoCD
├── stop_k8s.sh               # Stop k3s
├── k8s_plugins.sh            # Install plugins
├── BOOTSTRAP.md              # Production server setup guide
├── AI_GUIDANCE.md            # AI assistant guidance
├── root-application.yaml     # Root ApplicationSet
├── apps/                     # Application manifests
│   ├── infrastructure/       # Always-on services
│   │   ├── argocd/
│   │   └── nginx-ingress/
│   ├── media-services/       # Optional media services
│   │   ├── jellyfin/
│   │   ├── radarr/
│   │   └── sonarr/
│   └── sample-hello/         # Demo application
├── argocd/
│   └── applicationsets/      # ApplicationSet definitions
│       ├── infrastructure-appset.yaml
│       ├── media-services-appset.yaml
│       └── sample-hello-appset.yaml
└── environments/
    ├── dev/                  # Development configurations
    └── server/               # Production server configurations
```

## Deployment Model

### Branch Strategy
- **`dev`**: Local development cluster (this machine)
- **`main`**: Production server deployments
- **`feat/*`**: Feature branches for development

### Deployment Process
1. **Develop on feature branch**: `feat/application_sets`
2. **Deploy to dev**: `git push origin feat/application_sets:dev`
3. **ArgoCD syncs**: Automatically pulls from `dev` branch
4. **Enable services**: Use cluster labels to control what gets deployed

### Service Management
```bash
# Enable services via cluster labels
kubectl label cluster local-cluster sample-hello-enabled=true
kubectl label cluster local-cluster jellyfin-enabled=true
kubectl label cluster local-cluster radarr-enabled=false

# Check current labels
kubectl get cluster local-cluster --show-labels
```

## ApplicationSets Pattern

Applications are deployed via **ApplicationSets** with cluster label selectors:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: sample-hello
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          sample-hello-enabled: "true"
  template:
    spec:
      source:
        repoURL: https://github.com/brettswift/k8s_nas.git
        targetRevision: dev  # Always use dev branch for this cluster
        path: apps/sample-hello
```

## Environment Configuration

### Development (Local)
- **Branch**: `dev`
- **Cluster Labels**: `environment=dev`
- **Resource Limits**: Minimal for laptop
- **Services**: Enable/disable via labels

### Production (Server)
- **Branch**: `main`
- **Cluster Labels**: `environment=server`
- **Resource Limits**: Full production resources
- **Services**: All enabled by default

## Adding New Applications

1. **Create application manifests** in `apps/media-services/new-app/`
2. **Create ApplicationSet** in `argocd/applicationsets/new-app-appset.yaml`
3. **Add cluster label** for the service: `kubectl label cluster local-cluster new-app-enabled=true`
4. **Deploy**: `git push origin feat/application_sets:dev`

## Production Deployment

See `BOOTSTRAP.md` for complete production server setup instructions.

## Configuring Service Integrations

After deploying services, configure integrations between Starr media management applications:

- **Sonarr-Prowlarr Integration**: Configure TV show indexer management
- **Radarr-Prowlarr Integration**: Configure movie indexer management
- **Download Client Integration**: Connect services to qBittorrent

See **[CONFIGURE_STARR_INTEGRATIONS.md](./CONFIGURE_STARR_INTEGRATIONS.md)** for step-by-step configuration guides.

## Troubleshooting

- **Port conflicts**: Make sure ports 8080, 30080, 30443 are available
- **k3s issues**: Check `kubectl get nodes` and `kubectl get pods -A`
- **ArgoCD access**: Verify port forwarding with `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- **ApplicationSets not working**: Check cluster labels with `kubectl get cluster local-cluster --show-labels`
- **Branch issues**: Ensure ArgoCD is pointing to `dev` branch, not `feat/istio_argo`