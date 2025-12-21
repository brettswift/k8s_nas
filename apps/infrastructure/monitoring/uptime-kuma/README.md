# Uptime Kuma Monitor Sync

This directory contains the Uptime Kuma deployment and an automated sync system that discovers Kubernetes ingresses and creates monitors in Uptime Kuma.

## Components

- **deployment.yaml**: Uptime Kuma main deployment
- **service.yaml**: Service for Uptime Kuma
- **ingress.yaml**: Ingress for accessing Uptime Kuma UI
- **pvc.yaml**: Persistent volume claim for Uptime Kuma data
- **cronjob.yaml**: Daily sync job that discovers ingresses and creates monitors
- **serviceaccount.yaml**: Service account for the sync job
- **rbac.yaml**: RBAC permissions for the sync job to read ingresses
- **configmap-script.yaml**: The sync script that queries Kubernetes and updates Uptime Kuma

## Setup

### 1. Create API Key in Uptime Kuma

1. Access Uptime Kuma UI at `https://uptime.home.brettswift.com`
2. Go to Settings → API Keys
3. Create a new API key with appropriate permissions
4. Copy the API key

### 2. Create Kubernetes Secrets

Create secrets for API key and login credentials:

```bash
# API key for metrics endpoint (optional, for Prometheus integration)
kubectl create secret generic uptime-kuma-api-key \
  --from-literal=api-key='YOUR_API_KEY_HERE' \
  -n monitoring

# Login credentials for Socket.IO API (required for monitor sync)
kubectl create secret generic uptime-kuma-credentials \
  --from-literal=username='YOUR_USERNAME' \
  --from-literal=password='YOUR_PASSWORD' \
  -n monitoring
```

**Note:** The API key is only used for the `/metrics` endpoint. The monitor sync functionality requires username/password authentication via the Socket.IO API.

### 3. Deploy

The resources are managed by ArgoCD. Once deployed, the CronJob will run daily at 2 AM to sync monitors.

## Annotation-Based Monitoring

To enable monitoring for a service, add the following annotation to its Ingress:

```yaml
annotations:
  uptime-kuma.monitor/enabled: "true"
```

### Optional Annotations

- `uptime-kuma.monitor/notifications: "true"` - Enable notifications for this monitor
- `uptime-kuma.monitor/name: "Custom Name"` - Override the monitor name (defaults to `namespace/ingress-name`)
- `uptime-kuma.monitor/healthcheck-path: "/path/to/health"` - Use a specific healthcheck endpoint instead of the ingress path (e.g., `/jellyfin/health`)

### Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service-ingress
  namespace: media
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    uptime-kuma.monitor/enabled: "true"
    uptime-kuma.monitor/notifications: "true"
spec:
  # ... ingress spec
```

## How It Works

1. The CronJob runs daily at 2 AM
2. It queries all ingresses in the configured namespaces: `media`, `homeautomation`, `qbittorrent`, `homepage`
3. For each ingress with `uptime-kuma.monitor/enabled: "true"`:
   - Extracts the URL from the ingress (host + path, uses https if TLS is configured)
   - Creates or updates a monitor in Uptime Kuma
   - Monitor name format: `namespace/ingress-name`
4. Removes monitors for ingresses that no longer have the annotation

## Manual Sync

To manually trigger a sync:

```bash
kubectl create job --from=cronjob/uptime-kuma-sync manual-sync-$(date +%s) -n monitoring
```

## Troubleshooting

### Check CronJob logs

```bash
# Get the latest job
kubectl get jobs -n monitoring -l app=uptime-kuma-sync

# Get logs from the latest job pod
kubectl logs -n monitoring -l app=uptime-kuma-sync --tail=100
```

### Verify API key

```bash
kubectl get secret uptime-kuma-api-key -n monitoring -o jsonpath='{.data.api-key}' | base64 -d
```

### Test script manually

```bash
# Get a pod from a previous job
kubectl get pods -n monitoring -l app=uptime-kuma-sync

# Exec into it
kubectl exec -it <pod-name> -n monitoring -- /scripts/sync-monitors.sh
```

