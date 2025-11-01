# Starr Integration Configurator

Automated configuration tool for setting up integrations between Starr media management services (Sonarr, Radarr, Prowlarr).

## Overview

This component automatically configures:
- **Sonarr ↔ Prowlarr**: TV show indexer management
- **Radarr ↔ Prowlarr**: Movie indexer management
- (Future: Download client integrations)

## Architecture

Two deployment patterns:

1. **Kubernetes Job** (`job.yaml`) - One-time execution
   - Manual trigger or ArgoCD sync hook
   - For initial setup

2. **CronJob** (`cronjob.yaml`) - Periodic reconciliation
   - Runs every 6 hours
   - Self-healing (detects and fixes configuration drift)
   - Exits early if already configured (efficient)

## How It Works

### Idempotent Operation

The script is **fully idempotent**:
- ✅ Checks current state before making changes
- ✅ Safe to run multiple times
- ✅ Exits immediately if already configured (CronJob is efficient)
- ✅ Only applies changes when needed

### Configuration Flow

1. **Wait for Services**: Ensures Sonarr and Prowlarr are ready
2. **Check State**: Queries APIs to see if integration already exists
3. **Apply Changes**: Only configures what's missing
4. **Exit**: Success if configured, error if services unavailable

## Usage

### Manual Job Execution

```bash
# Run one-time configuration
kubectl apply -f apps/media-services/starr/starr-integration-configurator/job.yaml

# Check status
kubectl get jobs -n media -l app=starr-integration-configurator

# View logs
kubectl logs -n media -l job-name=starr-integration-configurator --tail=50
```

### Enable CronJob (Self-Healing)

```bash
# Apply CronJob for periodic reconciliation
kubectl apply -f apps/media-services/starr/starr-integration-configurator/cronjob.yaml

# Check CronJob status
kubectl get cronjobs -n media starr-integration-reconciler

# View last run logs
kubectl logs -n media -l job-name=starr-integration-reconciler-* --tail=50
```

### Integration with ArgoCD

Add to Application/ApplicationSet sync hooks:

```yaml
syncPolicy:
  hooks:
    postSync:
      - name: configure-starr-integrations
        template: starr-integration-job
```

## Requirements

### Secrets

- `starr-secrets` in `media` namespace
  - `SONARR_API_KEY`
  - `PROWLARR_API_KEY`
  - `RADARR_API_KEY` (for future Radarr integration)

### ConfigMaps

- `starr-common-config` in `media` namespace
  - `SONARR_URL`
  - `PROWLARR_URL`
  - `RADARR_URL` (for future Radarr integration)

## Current Implementation

**Note:** Current implementation uses inline scripts in Job/CronJob manifests for simplicity.

**Future Improvement:** Build custom container image with the script pre-installed:

```dockerfile
FROM alpine:3.20
RUN apk add --no-cache curl jq bash
COPY configure-integrations.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/configure-integrations.sh"]
```

## Troubleshooting

### Job Fails Immediately

**Check services are ready:**
```bash
kubectl get pods -n media -l app=sonarr
kubectl get pods -n media -l app=prowlarr
```

**Check API keys:**
```bash
kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d
```

### Configuration Not Applied

**Check logs for errors:**
```bash
kubectl logs -n media -l app=starr-integration-configurator --tail=100
```

**Verify API connectivity:**
```bash
# Test from within cluster
kubectl run -it --rm test-api --image=curlimages/curl:latest --restart=Never --namespace=media -- \
  curl -H "X-Api-Key: <key>" http://sonarr.media.svc.cluster.local:8989/api/v3/system/status
```

### CronJob Not Running

**Check CronJob status:**
```bash
kubectl describe cronjob -n media starr-integration-reconciler
```

**Manually trigger:**
```bash
kubectl create job --from=cronjob/starr-integration-reconciler manual-$(date +%s) -n media
```

## See Also

- [Design Document](../docs/starr-integration-automation-design.md)
- [User Guide](../../../../CONFIGURE_STARR_INTEGRATIONS.md)
- [Story 1.2](../../../../docs/stories/1-2-configure-sonarr-prowlarr-integration.md)

