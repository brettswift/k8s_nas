# Traefik Routing Guide for k8s_nas

This document provides comprehensive guidance on setting up Traefik routes for ArgoCD and future services in the k8s_nas cluster.

## Overview

Traefik is the ingress controller used in k3s by default. We use Traefik's native CRDs (`IngressRoute` and `Middleware`) for more advanced routing capabilities than standard Kubernetes Ingress.

## Current Setup

### ArgoCD Configuration

**ArgoCD Login Credentials:**
- Username: `admin`
- Password: `pMXpMZvSBaItyzFA`
- URL: `https://home.brettswift.com/argocd`

### Certificate Management

**Current Certificate:**
- Type: Let's Encrypt
- Domain: `home.brettswift.com`
- Expires: November 14, 2025 (1 month from now)
- Location: Kubernetes secret `home-brettswift-com-tls` in `argocd` namespace

**Certificate Issue:**
The current certificate expires in 1 month, which is not suitable for production. We need to locate and use the long-term certificate from the docker-compose-nas2 system.

## Traefik Routing Patterns

### 1. Basic IngressRoute Pattern

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
    - match: Host(`home.brettswift.com`) && PathPrefix(`/service-path`)
      kind: Rule
      services:
        - name: service-name
          port: 80
      middlewares:
        - name: service-stripprefix
          namespace: service-namespace
  tls:
    secretName: home-brettswift-com-tls
```

### 2. StripPrefix Middleware Pattern

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: service-stripprefix
  namespace: service-namespace
spec:
  stripPrefix:
    prefixes:
      - /service-path
```

### 3. ArgoCD Specific Configuration

**IngressRoute:**
```yaml
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
      middlewares:
        - name: argocd-stripprefix
          namespace: argocd
  tls:
    secretName: home-brettswift-com-tls
```

**Middleware:**
```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: argocd-stripprefix
  namespace: argocd
spec:
  stripPrefix:
    prefixes:
      - /argocd
```

**ArgoCD ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
data:
  server.insecure: "true"
  server.basehref: "/argocd/"
```

## Service Migration Patterns

### From Docker Compose to Kubernetes

When migrating services from the docker-compose-nas2 system to Kubernetes, follow these patterns:

#### 1. Path-Based Routing
```yaml
# For services like /jellyfin, /sonarr, /radarr, etc.
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: jellyfin-ingressroute
  namespace: media-services
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`home.brettswift.com`) && PathPrefix(`/jellyfin`)
      kind: Rule
      services:
        - name: jellyfin
          port: 8096
      middlewares:
        - name: jellyfin-stripprefix
          namespace: media-services
  tls:
    secretName: home-brettswift-com-tls
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: jellyfin-stripprefix
  namespace: media-services
spec:
  stripPrefix:
    prefixes:
      - /jellyfin
```

#### 2. Root Path Routing (Homepage)
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: homepage-ingressroute
  namespace: homepage
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`home.brettswift.com`) && PathPrefix(`/`)
      kind: Rule
      services:
        - name: homepage
          port: 3000
  tls:
    secretName: home-brettswift-com-tls
```

## Certificate Management

### Current Certificate Issues

1. **Short Expiry**: Current Let's Encrypt certificate expires in 1 month
2. **Need Long-term Certificate**: Should use the certificate from docker-compose-nas2 system
3. **Wildcard Certificate**: Ideally should have `*.brettswift.com` for subdomains

### Certificate Update Process

1. **Locate Long-term Certificate**: Find the certificate from docker-compose-nas2 that doesn't expire
2. **Create Kubernetes Secret**: 
   ```bash
   kubectl create secret tls home-brettswift-com-tls \
     --cert=path/to/certificate.crt \
     --key=path/to/private.key \
     -n argocd
   ```
3. **Update All IngressRoutes**: Ensure all services reference the new certificate secret
4. **Test HTTPS**: Verify all services work with the new certificate

## Debugging Traefik

### Enable Debug Logs
```bash
# Port forward to Traefik dashboard
kubectl port-forward svc/traefik -n kube-system 8080:8080

# Access dashboard at http://localhost:8080
```

### Common Issues

1. **404 Errors**: Check if middleware is properly referenced
2. **Certificate Errors**: Verify certificate secret exists and is valid
3. **Routing Issues**: Check Traefik logs for routing decisions

### Useful Commands

```bash
# Check Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik

# List IngressRoutes
kubectl get ingressroutes --all-namespaces

# List Middlewares
kubectl get middlewares --all-namespaces

# Check certificate details
kubectl get secret home-brettswift-com-tls -n argocd -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

## Future Service Integration

### Adding New Services

1. **Create Namespace**: `kubectl create namespace service-name`
2. **Deploy Service**: Create Deployment and Service manifests
3. **Create IngressRoute**: Define routing rules
4. **Create Middleware**: If path stripping is needed
5. **Test**: Verify service is accessible via HTTPS

### Service Labels for Homepage

Services should include Homepage labels for automatic discovery:

```yaml
metadata:
  labels:
    homepage.group: "Media"
    homepage.name: "Jellyfin"
    homepage.icon: "jellyfin.png"
    homepage.href: "/jellyfin"
    homepage.description: "Media server"
    homepage.weight: "3"
```

## Security Considerations

1. **TLS Only**: All services should use HTTPS
2. **Certificate Validation**: Regular certificate expiry monitoring
3. **Access Control**: Implement proper RBAC for services
4. **Network Policies**: Consider implementing network policies for service isolation

## Monitoring and Maintenance

1. **Certificate Monitoring**: Set up alerts for certificate expiry
2. **Service Health**: Monitor service availability
3. **Traefik Metrics**: Enable Traefik metrics collection
4. **Log Aggregation**: Centralize Traefik and service logs

## Troubleshooting Checklist

- [ ] Certificate is valid and not expired
- [ ] IngressRoute is created and active
- [ ] Middleware is properly referenced
- [ ] Service is running and healthy
- [ ] DNS resolution is working
- [ ] Traefik is receiving requests
- [ ] No conflicting ingress rules
