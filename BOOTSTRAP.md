# Production Server Bootstrap Guide

This guide covers setting up a production server with k3s + ArgoCD for GitOps deployment.

## Prerequisites

- Clean server (Ubuntu/Pop!_OS recommended)
- Root/sudo access
- Internet connectivity
- GitHub repository access

## 1. Server Setup

### Install k3s
```bash
# Install k3s with disabled Traefik (we'll use NGINX)
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# Add k3s to PATH
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

# Set KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
```

### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Install Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 2. Clone Repository

```bash
# Clone this repository
git clone https://github.com/brettswift/k8s_nas.git
cd k8s_nas

# Make scripts executable
chmod +x start_k8s.sh stop_k8s.sh k8s_plugins.sh
```

## 3. Install Kubernetes Plugins

```bash
# Install NGINX Ingress, cert-manager, Istio
./k8s_plugins.sh
```

## 4. Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## 5. Configure ArgoCD

### Set up ArgoCD project
```bash
kubectl apply -f argocd/projects/nas.yaml
```

### Configure GitHub access (if using private repos)
```bash
# Create GitHub token secret
kubectl create secret generic github-token \
  --from-literal=token=YOUR_GITHUB_TOKEN \
  -n argocd

# Or use SSH key
kubectl create secret generic github-ssh \
  --from-file=sshPrivateKey=~/.ssh/id_rsa \
  -n argocd
```

### Set up ArgoCD ingress
```bash
kubectl apply -f argocd/applications/argocd-ingress.yaml
```

## 6. Configure DNS and SSL

### Update ingress for your domain
Edit `argocd/ingress/ingress.yaml`:
```yaml
spec:
  rules:
  - host: your-domain.com  # Change from localhost
    http:
      paths:
      - path: /argo
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

### Set up cert-manager for SSL
```bash
# Create cluster issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## 7. Set up App-of-Apps Pattern

### Create root application
```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: nas
  source:
    repoURL: https://github.com/brettswift/k8s_nas.git
    targetRevision: HEAD
    path: argocd/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
```

## 8. Access ArgoCD

### Get admin password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Access dashboard
- URL: `https://your-domain.com/argo`
- Username: `admin`
- Password: (from above command)

## 9. GitOps Workflow

Once set up, the workflow is:

1. **Create application manifest** in `argocd/applications/`
2. **Commit and push** to Git
3. **ArgoCD automatically syncs** the new application

### Example: Adding a new app
```bash
# Create new application
cat > argocd/applications/my-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: nas
  source:
    repoURL: https://github.com/brettswift/k8s_nas.git
    targetRevision: HEAD
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# Commit and push
git add argocd/applications/my-app.yaml
git commit -m "Add my-app application"
git push origin main
```

## 10. Monitoring and Maintenance

### Check ArgoCD status
```bash
kubectl get applications -n argocd
kubectl get pods -n argocd
```

### View logs
```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller
```

### Update ArgoCD
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Security Considerations

- Use HTTPS for ArgoCD access
- Rotate admin password regularly
- Use RBAC for team access
- Keep ArgoCD updated
- Monitor for security vulnerabilities

## Troubleshooting

### Common issues:
- **ArgoCD not syncing**: Check GitHub token/SSH key
- **SSL issues**: Verify cert-manager and DNS
- **Ingress not working**: Check NGINX controller status
- **Applications failing**: Check resource limits and permissions
