# Cluster Rebuild - Clean Bootstrap

This is the **single source of truth** for rebuilding the k8s_nas cluster.

**Last verified:** 2025-11-29

## Target Architecture

- **k3s** with **Traefik** as the ingress controller (k3s default, no nginx)
- **cert-manager** with **Let's Encrypt DNS-01** via **Route53**
- **ArgoCD** for GitOps
- TLS termination at Traefik using a single cert for `home.brettswift.com` + `jellyseerr.home.brettswift.com`

## Acceptance Criteria

```bash
curl -sI https://home.brettswift.com/argocd/ | head -5
# Should show HTTP/2 200

echo | openssl s_client -connect home.brettswift.com:443 -servername home.brettswift.com 2>/dev/null | openssl x509 -noout -issuer
# Should show: issuer=C=US, O=Let's Encrypt, CN=R12 (or similar)
```

---

## Prerequisites

- Server IP: `10.1.0.20` (update if changed)
- SSH access: `ssh bswift@10.1.0.20`
- AWS CLI with `assume brettswift-mgmt` for Route53 access
- IAM user `cert-manager-route53` with Route53 permissions
- Route53 hosted zone ID: `Z1A5BHLIT8EGDS`

---

## Phase 1: Uninstall k3s (on server)

```bash
ssh bswift@10.1.0.20 'sudo /usr/local/bin/k3s-uninstall.sh'
```

---

## Phase 2: Install k3s with Traefik (on server)

```bash
ssh bswift@10.1.0.20 'curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --node-ip=10.1.0.20'
```

Wait for k3s to be ready:

```bash
ssh bswift@10.1.0.20 'sudo kubectl get nodes'
```

---

## Phase 3: Fetch kubeconfig (from Mac)

```bash
ssh bswift@10.1.0.20 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed 's/127.0.0.1/10.1.0.20/' > ~/.kube/config-nas

export KUBECONFIG=~/.kube/config-nas
kubectl get nodes
```

---

## Phase 4: Wait for Traefik to be ready

```bash
kubectl get deploy traefik -n kube-system
kubectl get svc traefik -n kube-system
# Should show EXTERNAL-IP: 10.1.0.20
```

---

## Phase 5: Install cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.0 \
  --set installCRDs=true

# Wait for cert-manager to be ready
kubectl -n cert-manager wait --for=condition=ready pod \
  -l app.kubernetes.io/component=controller --timeout=180s
```

---

## Phase 6: Create Route53 credentials

Get AWS credentials for the IAM user:

```bash
assume brettswift-mgmt

# If needed, create new access key
aws iam create-access-key --user-name cert-manager-route53
# Note the AccessKeyId and SecretAccessKey

# Create the secret
kubectl -n cert-manager create secret generic route53-credentials \
  --from-literal=secret-access-key="YOUR_SECRET_ACCESS_KEY_HERE"
```

---

## Phase 7: Create ClusterIssuer

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns-home
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: brettswift@gmail.com
    privateKeySecretRef:
      name: letsencrypt-dns-home
    solvers:
    - dns01:
        route53:
          region: us-west-2
          hostedZoneID: Z1A5BHLIT8EGDS
          accessKeyID: "YOUR_ACCESS_KEY_ID_HERE"
          secretAccessKeySecretRef:
            name: route53-credentials
            key: secret-access-key
EOF
```

---

## Phase 8: Create Certificate

```bash
kubectl create namespace argocd

cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: home-brettswift-com-dns
  namespace: argocd
spec:
  secretName: home-brettswift-com-tls
  issuerRef:
    name: letsencrypt-dns-home
    kind: ClusterIssuer
  dnsNames:
    - "home.brettswift.com"
    - "jellyseerr.home.brettswift.com"
  renewBefore: 2592000s
EOF

# Monitor certificate issuance (wait for READY=True)
kubectl get certificate -n argocd -w
```

---

## Phase 9: Install ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl -n argocd wait --for=condition=available deployment/argocd-server --timeout=180s

# Delete network policies (they block Traefik)
kubectl delete networkpolicies -n argocd --all

# Configure ArgoCD for /argocd subpath
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge \
  -p '{"data":{"server.insecure":"true","server.basehref":"/argocd/","server.rootpath":"/argocd"}}'

# Restart argocd-server
kubectl -n argocd rollout restart deployment argocd-server
kubectl -n argocd wait --for=condition=available deployment/argocd-server --timeout=60s
```

---

## Phase 10: Create Traefik IngressRoute

**Important:** Do NOT use stripPrefix middleware - ArgoCD expects `/argocd` in the path.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: argocd-ingressroute
  namespace: argocd
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`home.brettswift.com`) && PathPrefix(`/argocd`)
      kind: Rule
      services:
        - name: argocd-server
          port: 80
  tls:
    secretName: home-brettswift-com-tls
EOF
```

---

## Phase 11: Verify

```bash
# Test HTTPS access
curl -sI https://home.brettswift.com/argocd/ | head -5
# Should show: HTTP/2 200

# Verify Let's Encrypt certificate
echo | openssl s_client -connect home.brettswift.com:443 -servername home.brettswift.com 2>/dev/null | openssl x509 -noout -issuer -dates
# Should show: issuer=C=US, O=Let's Encrypt, CN=R12

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

**ArgoCD Access:**

- URL: `https://home.brettswift.com/argocd/`
- Username: `admin`
- Password: (from command above)

---

## Post-Rebuild: GitOps Setup

```bash
# Add Git SSH key for ArgoCD
kubectl -n argocd create secret generic repo-github-ssh \
  --from-file=sshPrivateKey=~/.ssh/id_rsa \
  --from-file=known_hosts=<(ssh-keyscan github.com)

# Apply projects
kubectl apply -f argocd/projects/

# Apply root application
kubectl apply -f root-application.yaml
```

---

## DNS Configuration

If the server IP changes, update Route53:

```bash
assume brettswift-mgmt

aws route53 change-resource-record-sets --hosted-zone-id Z1A5BHLIT8EGDS --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "home.brettswift.com",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "NEW_IP_HERE"}]
    }
  }]
}'

aws route53 change-resource-record-sets --hosted-zone-id Z1A5BHLIT8EGDS --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "jellyseerr.home.brettswift.com",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "NEW_IP_HERE"}]
    }
  }]
}'
```

---

## Troubleshooting

### Certificate not issuing

```bash
kubectl describe certificate -n argocd home-brettswift-com-dns
kubectl get challenges -A
kubectl describe challenge -A
kubectl logs -n cert-manager -l app.kubernetes.io/component=controller --tail=50
```

### Traefik not routing

```bash
kubectl get ingressroutes -A
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=50
```

### DNS TXT record conflicts

Check Route53 for leftover `_acme-challenge.home.brettswift.com` TXT records and delete them.

### ArgoCD network policies blocking traffic

```bash
kubectl delete networkpolicies -n argocd --all
```
