# Bootstrap Steps - Successful Commands

This file tracks the successful steps required to bootstrap the k3s cluster after a fresh install or database reset.

## Git Repository Access

- Create SSH secret for ArgoCD Git access:
  ```bash
  kubectl -n argocd create secret generic repo-github-ssh \
    --from-file=sshPrivateKey=~/.ssh/id_rsa \
    --from-file=known_hosts=<(ssh-keyscan github.com)
  ```

- Install ArgoCD CLI and configure repository:
  ```bash
  curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
  kubectl port-forward -n argocd svc/argocd-server 8080:443 &
  argocd login localhost:8080 --insecure --username admin --password "$ARGOCD_PASSWORD"
  argocd repo add git@github.com:brettswift/k8s_nas.git --ssh-private-key-path ~/.ssh/id_rsa --insecure
  ```

## ArgoCD Setup

- Apply ArgoCD projects:
  ```bash
  kubectl apply -f argocd/projects/
  ```

- Apply root application:
  ```bash
  kubectl apply -f root-application.yaml
  ```

- Restart ArgoCD repo-server after adding Git credentials:
  ```bash
  kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-repo-server
  ```

## Infrastructure Components

- Disable Traefik (k3s default ingress):
  ```bash
  kubectl delete deployment traefik -n kube-system
  kubectl delete svc traefik -n kube-system
  kubectl delete daemonset svclb-traefik -n kube-system
  sudo rm -f /var/lib/rancher/k3s/server/manifests/traefik.yaml
  ```

- Install cert-manager:
  ```bash
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true \
    --version v1.13.0
  kubectl wait --namespace cert-manager \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s
  ```

- Install NGINX Ingress Controller:
  ```bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  kubectl create namespace ingress-nginx
  helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.hostNetwork=true \
    --set controller.service.type=ClusterIP \
    --set controller.admissionWebhooks.enabled=false
  ```

- Update infrastructure project permissions (add to `argocd/projects/infrastructure.yaml`):
  - Add to `namespaceResourceWhitelist`: ServiceAccount, CronJob, Role, RoleBinding
  - Add to `clusterResourceWhitelist`: ClusterRole, ClusterRoleBinding

- Update apps project to allow SSH Git URL (add to `argocd/projects/apps.yaml`):
  - Add `'git@github.com:brettswift/k8s_nas.git'` to `sourceRepos` list

