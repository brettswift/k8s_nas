# External DNS Setup

External DNS automatically manages Route53 DNS records based on Kubernetes Ingress/IngressRoute annotations.

## How It Works

1. **External DNS watches** Ingress and IngressRoute resources
2. **Reads annotations** like `external-dns.alpha.kubernetes.io/hostname`
3. **Automatically creates/updates/deletes** Route53 CNAME records
4. **Uses AWS credentials** from the `route53-credentials` secret (shared with cert-manager)

## Setup

### 1. Ensure Route53 Credentials Secret Has Access Key ID

The secret needs both `access-key-id` and `secret-access-key`:

```bash
# Get your AWS access key ID (from ClusterIssuer or AWS console)
AWS_ACCESS_KEY_ID="your-access-key-id"

# Patch the secret to add access-key-id
kubectl patch secret route53-credentials -n cert-manager --type=json \
  -p="[{\"op\": \"add\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$AWS_ACCESS_KEY_ID" | base64)\"}]"
```

Or if the secret doesn't exist yet:

```bash
kubectl create secret generic route53-credentials \
  --from-literal=access-key-id="YOUR_ACCESS_KEY_ID" \
  --from-literal=secret-access-key="YOUR_SECRET_ACCESS_KEY" \
  --namespace=cert-manager
```

### 2. Deploy External DNS

External DNS is deployed via ArgoCD as part of the infrastructure application.

### 3. Annotate Your Ingress/IngressRoute

Add the annotation to any Ingress or IngressRoute:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myservice.home.brettswift.com
spec:
  # ... rest of spec
```

External DNS will automatically:
- Create the Route53 CNAME record pointing to your ingress
- Update it if the annotation changes
- Delete it when the resource is deleted

## Examples

### Traefik Dashboard

```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: traefik.home.brettswift.com
```

### qBittorrent (already using subdomain)

```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: qbittorrent.home.brettswift.com
```

## Benefits

✅ **Declarative** - DNS records defined in Git with your services  
✅ **Automatic** - No manual DNS management  
✅ **Self-healing** - Records automatically sync on changes  
✅ **GitOps-friendly** - Works perfectly with ArgoCD  
✅ **Scalable** - Add as many subdomains as you need  

## Troubleshooting

Check External DNS logs:
```bash
kubectl logs -n external-dns deployment/external-dns
```

Check if DNS records are being created:
```bash
# In Route53 console or via AWS CLI
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1A5BHLIT8EGDS \
  --query "ResourceRecordSets[?Type=='CNAME']"
```

## Migration from Manual Scripts

Replace manual DNS scripts with annotations:

**Before:**
```bash
./scripts/create-traefik-dns.sh
```

**After:**
```yaml
annotations:
  external-dns.alpha.kubernetes.io/hostname: traefik.home.brettswift.com
```

Just commit and push - External DNS handles the rest!

