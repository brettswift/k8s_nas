# Secret Sync Troubleshooting

## How Secret Sync Heals

### CronJob Sync (`sync-route53-credentials`)
- **Schedule**: Every 6 hours (`0 */6 * * *`)
- **Retry**: `restartPolicy: OnFailure` - retries if the container fails
- **Auto-heal**: Runs automatically on schedule, will retry on next run if it fails
- **Manual trigger**: 
  ```bash
  kubectl create job --from=cronjob/sync-route53-credentials manual-sync-$(date +%s) -n cert-manager
  ```

### ArgoCD PostSync Hook (`sync-route53-credentials-hook`)
- **Trigger**: Runs automatically after every ArgoCD sync
- **Retry**: `restartPolicy: OnFailure` - retries if the container fails
- **Auto-heal**: Runs on every ArgoCD sync, will retry on next sync if it fails
- **Manual trigger**: Just sync the infrastructure application in ArgoCD

## Checking Sync Status

```bash
# Check CronJob status
kubectl get cronjob sync-route53-credentials -n cert-manager

# Check recent jobs
kubectl get jobs -n cert-manager | grep sync-route53

# Check job logs
kubectl logs -n cert-manager job/sync-route53-credentials-XXXXX

# Check if secret exists in target namespace
kubectl get secret route53-credentials -n external-dns
```

## Common Issues

### 1. Permission Denied
**Symptom**: Job fails with "Forbidden" or permission errors

**Fix**: Ensure the default service account has permissions:
```bash
kubectl create clusterrolebinding route53-sync-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=cert-manager:default
```

### 2. Secret Doesn't Exist in Source
**Symptom**: Job fails with "secret not found"

**Fix**: Create the secret in cert-manager namespace:
```bash
./scripts/setup-external-dns-credentials.sh
```

### 3. Namespace Doesn't Exist
**Symptom**: Job fails with "namespace not found"

**Fix**: Ensure target namespace exists:
```bash
kubectl get namespace external-dns || kubectl create namespace external-dns
```

## Manual Sync

If sync is failing and you need immediate sync:

```bash
# Trigger CronJob manually
kubectl create job --from=cronjob/sync-route53-credentials manual-sync-$(date +%s) -n cert-manager

# Or manually copy the secret
kubectl get secret route53-credentials -n cert-manager -o yaml | \
  sed 's/namespace: cert-manager/namespace: external-dns/' | \
  sed '/^  uid:/d' | \
  sed '/^  resourceVersion:/d' | \
  sed '/^  selfLink:/d' | \
  sed '/^  creationTimestamp:/d' | \
  kubectl apply -f -
```

