# Kubernetes NAS - ArgoCD GitOps Setup

A clean Kubernetes setup with ArgoCD for GitOps deployment of media server applications.

## Quick Start

1. **Start the cluster:**
   ```bash
   ./start_k8s.sh
   ```

2. **Access ArgoCD:**
   - URL: https://localhost:8080 (port forward)
   - Username: `admin`
   - Password: (displayed in terminal output)

3. **Stop the cluster:**
   ```bash
   ./stop_k8s.sh
   ```

## Architecture

- **k3s**: Lightweight Kubernetes cluster
- **NGINX Ingress**: Ingress controller (replaces k3s Traefik)
- **cert-manager**: SSL certificate management
- **Istio**: Service mesh (for future use)
- **ArgoCD**: GitOps deployment tool

## Repository Structure

```
k8s_nas/
├── start_k8s.sh              # Start k3s + ArgoCD
├── stop_k8s.sh               # Stop k3s
├── k8s_plugins.sh            # Install plugins
├── BOOTSTRAP.md              # Production server setup guide
└── argocd/
    ├── projects/
    │   └── nas.yaml          # Basic project permissions
    ├── applications/
    │   └── argocd-ingress.yaml  # ArgoCD ingress
    └── ingress/
        ├── ingress.yaml      # ArgoCD ingress config
        └── kustomization.yaml
```

## Adding Applications

To add a new application:

1. Create application manifest in `argocd/applications/`
2. Commit and push to Git
3. ArgoCD will automatically sync (if using app-of-apps pattern)

## Production Deployment

See `BOOTSTRAP.md` for complete production server setup instructions.

## Troubleshooting

- **Port conflicts**: Make sure ports 8080, 30080, 30443 are available
- **k3s issues**: Check `kubectl get nodes` and `kubectl get pods -A`
- **ArgoCD access**: Verify port forwarding with `kubectl port-forward svc/argocd-server -n argocd 8080:443`