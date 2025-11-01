# Certificate Management Guide

This document explains how to manage SSL/TLS certificates for the k8s_nas cluster.

## Current Certificate Status

**Current Certificate:**
- Domain: `home.brettswift.com`
- Type: Let's Encrypt
- Expires: November 14, 2025 (1 month from now)
- Location: Kubernetes secret `home-brettswift-com-tls` in `argocd` namespace

## Certificate Options

### 1. Let's Encrypt with Auto-renewal (Recommended)

**Pros:**
- Free
- Automatic renewal every 60 days
- Trusted by all browsers
- No manual intervention required

**Cons:**
- 90-day maximum validity (but auto-renewed)
- Requires public DNS access

**Setup:**
```bash
# Run the cert-manager setup script
./scripts/cert-manager-setup.sh
```

### 2. Wildcard Certificate with DNS Challenge

**Pros:**
- Covers all subdomains (*.brettswift.com)
- More reliable than HTTP challenge
- Can be used for multiple services

**Cons:**
- Requires AWS Route53 access
- More complex setup

**Setup:**
```bash
# First, assume the AWS role
assume brettswift-mgmt

# Then run the wildcard certificate setup
./scripts/setup-wildcard-cert.sh
```

### 3. Self-signed Certificate

**Pros:**
- Never expires
- No external dependencies
- Works for internal services

**Cons:**
- Browser security warnings
- Not trusted by default
- Not suitable for production

**Setup:**
```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout home.brettswift.com.key \
  -out home.brettswift.com.crt \
  -subj "/CN=home.brettswift.com"

# Create Kubernetes secret
kubectl create secret tls home-brettswift-com-tls \
  --cert=home.brettswift.com.crt \
  --key=home.brettswift.com.key \
  -n argocd
```

## Recommended Solution

For production use, I recommend **Let's Encrypt with Auto-renewal** because:

1. **Automatic Management**: Certificates are renewed automatically
2. **No Expiry Concerns**: Renewal happens 30 days before expiry
3. **Trusted**: Works with all browsers without warnings
4. **Free**: No cost involved
5. **Reliable**: Let's Encrypt has 99.9% uptime

## Implementation Steps

### Step 1: Install cert-manager

```bash
# Run the setup script
./scripts/cert-manager-setup.sh
```

### Step 2: Update IngressRoutes

Replace the current IngressRoute with the cert-manager version:

```bash
# Apply the new IngressRoute with cert-manager
kubectl apply -f apps/infrastructure/traefik/argocd-ingressroute-with-cert-manager.yaml
```

### Step 3: Verify Certificate

```bash
# Check certificate status
kubectl get certificates -A

# Check certificate details
kubectl describe certificate home-brettswift-com-tls -n argocd
```

## Certificate Monitoring

### Check Certificate Status

```bash
# List all certificates
kubectl get certificates -A

# Check specific certificate
kubectl describe certificate home-brettswift-com-tls -n argocd

# Check certificate expiry
kubectl get secret home-brettswift-com-tls -n argocd -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep -A 3 'Validity'
```

### Monitor Certificate Renewal

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager

# Check certificate events
kubectl get events -n argocd --field-selector involvedObject.name=home-brettswift-com-tls
```

## Troubleshooting

### Certificate Not Issued

1. **Check ClusterIssuer status:**
   ```bash
   kubectl describe clusterissuer letsencrypt-prod
   ```

2. **Check certificate status:**
   ```bash
   kubectl describe certificate home-brettswift-com-tls -n argocd
   ```

3. **Check cert-manager logs:**
   ```bash
   kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager
   ```

### Certificate Renewal Issues

1. **Check DNS resolution:**
   ```bash
   nslookup home.brettswift.com
   ```

2. **Check HTTP challenge:**
   ```bash
   curl -I http://home.brettswift.com/.well-known/acme-challenge/test
   ```

3. **Check Traefik ingress:**
   ```bash
   kubectl get ingressroutes -A
   ```

## Security Considerations

1. **Certificate Storage**: Certificates are stored as Kubernetes secrets
2. **Access Control**: Limit access to certificate secrets
3. **Monitoring**: Set up alerts for certificate expiry
4. **Backup**: Consider backing up certificate secrets

## Migration from Current Certificate

To migrate from the current certificate to cert-manager:

1. **Install cert-manager:**
   ```bash
   ./scripts/cert-manager-setup.sh
   ```

2. **Apply new IngressRoute:**
   ```bash
   kubectl apply -f apps/infrastructure/traefik/argocd-ingressroute-with-cert-manager.yaml
   ```

3. **Verify new certificate:**
   ```bash
   kubectl get certificates -A
   ```

4. **Test HTTPS access:**
   ```bash
   curl -I https://home.brettswift.com/argocd
   ```

## Future Services

For new services, use the same certificate secret:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: service-ingressroute
  namespace: service-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`home.brettswift.com`) && PathPrefix(`/service`)
      kind: Rule
      services:
        - name: service
          port: 80
  tls:
    secretName: home-brettswift-com-tls  # Same certificate for all services
```

## Conclusion

The recommended approach is to use Let's Encrypt with cert-manager for automatic certificate management. This provides:

- **Automatic renewal** every 60 days
- **No manual intervention** required
- **Trusted certificates** that work with all browsers
- **Cost-effective** solution (free)

The 90-day expiry is not a problem because certificates are automatically renewed 30 days before expiry, ensuring continuous service availability.
