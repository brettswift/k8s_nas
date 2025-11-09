# Starr Integration Automation Design

**Purpose:** Automate configuration of integrations between Starr services (Sonarr, Radarr, Prowlarr) without manual UI steps.

**Date:** 2025-01-27

---

## Problem Statement

Currently, configuring integrations requires:
1. Accessing each service UI
2. Manually entering API keys and URLs
3. Testing connections
4. Repeating for each integration (Sonarr↔Prowlarr, Radarr↔Prowlarr, etc.)

This is:
- **Time-consuming** for initial setup
- **Error-prone** (typos, wrong URLs)
- **Not reproducible** for fresh deployments
- **Not self-healing** (if config drifts, must fix manually)

---

## Solution Patterns

### Pattern 1: Kubernetes Job (One-Time Execution) ✅ **Recommended**

**How it works:**
- Create a Kubernetes Job that runs the configuration script
- Job is **idempotent** - safe to run multiple times
- Checks current state, applies only what's needed
- Exits successfully when configuration is complete
- Can be triggered manually or as part of deployment pipeline

**Pros:**
- ✅ Simple and straightforward
- ✅ Can be run on-demand or as part of deployment
- ✅ Idempotent (safe to rerun)
- ✅ Easy to debug (check job logs)
- ✅ Can be triggered by ArgoCD sync hooks

**Cons:**
- ❌ Doesn't auto-detect when services are ready (manual trigger or wait)
- ❌ Not self-healing (if config drifts later)

**Use Case:** **Initial setup** and **manual reconciliation**

---

### Pattern 2: CronJob with Smart Exit (Periodic Reconciliation) ✅ **Best for Self-Healing**

**How it works:**
- CronJob runs periodically (e.g., every hour)
- Script checks if configuration is needed
- If already configured and correct, exits early (no work done)
- If configuration needed or drifted, applies fixes
- Harmless to leave running even when everything is configured

**Pros:**
- ✅ Self-healing (detects and fixes configuration drift)
- ✅ Handles new services automatically when they come online
- ✅ No manual intervention needed
- ✅ Can run infrequently (once per hour/day) - low overhead

**Cons:**
- ❌ Slight resource overhead (periodic execution)
- ❌ Delay between drift and fix (up to cron interval)

**Use Case:** **Ongoing reconciliation** and **self-healing**

---

### Pattern 3: Operator Pattern (Advanced)

**How it works:**
- Custom Kubernetes operator watches for Starr services
- Automatically configures integrations when services become ready
- Continuously reconciles desired state

**Pros:**
- ✅ Immediate configuration when services start
- ✅ True declarative management
- ✅ Most "cloud-native" approach

**Cons:**
- ❌ Complex to implement
- ❌ Requires operator development
- ❌ Overkill for this use case

**Use Case:** **Large-scale deployments** or **frequent service churn**

---

## Recommended Approach: Hybrid Pattern

**Use both patterns:**

1. **Kubernetes Job** - For initial setup and manual reconciliation
   - Triggered manually or via ArgoCD post-sync hooks
   - Fast execution for immediate setup

2. **CronJob** - For ongoing self-healing
   - Runs periodically (e.g., hourly)
   - Catches any configuration drift
   - Exits early if everything is configured (efficient)

---

## Implementation Design

### Container Image

Create a lightweight container image with:
- `curl` for API calls
- `jq` for JSON parsing
- Bash script for configuration logic
- Entrypoint script that:
  1. Reads API keys from `starr-secrets` Secret
  2. Reads service URLs from `starr-common-config` ConfigMap
  3. Checks current configuration state via API
  4. Applies configuration if needed
  5. Exits with success code (0) when done

### Configuration Detection Logic

For each integration, script checks:

```bash
# Sonarr → Prowlarr
1. GET /api/v3/indexer → Check if Prowlarr indexer exists
2. If missing → POST /api/v3/indexer (create)
3. If exists but wrong config → PUT /api/v3/indexer/{id} (update)

# Prowlarr → Sonarr
1. GET /api/v1/applications → Check if Sonarr app exists
2. If missing → POST /api/v1/applications (create)
3. If exists but wrong config → PUT /api/v1/applications/{id} (update)
```

**Exit Conditions:**
- All integrations configured correctly → Exit 0 (success)
- Service not ready yet → Exit 1 (retry later)
- API error → Exit 1 (fail, will retry)

### Idempotency

Script is **fully idempotent**:
- ✅ Can be run multiple times safely
- ✅ Checks state before applying changes
- ✅ No side effects if run when already configured
- ✅ Safe for CronJob to run repeatedly

---

## Resource Requirements

**Job Configuration:**
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

**CronJob Schedule:**
```yaml
# Run hourly, but exits immediately if already configured
schedule: "0 * * * *"  # Every hour at :00
# Or less frequently:
schedule: "0 */6 * * *"  # Every 6 hours
```

**Overhead:**
- **Job execution time:** < 30 seconds (if already configured, < 5 seconds)
- **Resource usage:** Minimal (script execution, API calls)
- **Network:** Only internal cluster DNS (no external calls)

---

## Integration with GitOps

### ArgoCD Sync Hooks

Configure Job to run **after** Starr services are deployed:

```yaml
# In ApplicationSet or Application
syncPolicy:
  syncOptions:
    - CreateNamespace=true
  hooks:
    postSync:
      - name: configure-starr-integrations
        template: starr-integration-job
```

This ensures:
1. Services deployed first
2. Services become ready
3. Integration Job runs automatically
4. Configurations applied

### Manual Trigger

For manual reconciliation:

```bash
# Trigger Job manually
kubectl create job --from=cronjob/starr-integration-reconciler manual-reconcile-$(date +%s) -n media

# Or run the Job directly
kubectl apply -f apps/media-services/starr/starr-integration-job.yaml
```

---

## Alternative: Buildarr

**Note:** There's an existing tool called **Buildarr** that does exactly this!

**Buildarr:**
- Python-based configuration management for *arr applications
- Declarative YAML configuration
- Idempotent reconciliation
- Supports Prowlarr, Sonarr, Radarr

**Consideration:**
- Could use Buildarr instead of custom script
- Requires Python runtime (heavier container)
- More features but more complex
- Our custom script is simpler and fits our exact needs

**Decision:** Start with custom script, migrate to Buildarr if we need more features.

---

## Migration Path

**Phase 1: Manual Script (Current)**
- ✅ Script exists: `scripts/configure-sonarr-prowlarr-integration.sh`
- ✅ Works from local machine or pod
- ⚠️ Manual execution required

**Phase 2: Kubernetes Job**
- Containerize the script
- Create Job manifest
- Can be triggered manually or via ArgoCD hooks
- **Target:** Next sprint

**Phase 3: CronJob (Self-Healing)**
- Wrap Job in CronJob
- Runs periodically for drift detection
- **Target:** After Phase 2 is proven stable

**Phase 4: Evaluate Buildarr (Optional)**
- If we need more complex configuration management
- Migrate to Buildarr if it provides value

---

## Security Considerations

**Secrets Management:**
- ✅ API keys stored in Kubernetes Secret (`starr-secrets`)
- ✅ Secret mounted as environment variables (not files)
- ✅ Job runs in `media` namespace (RBAC restricted)
- ✅ No secrets in logs (script handles carefully)

**RBAC:**
```yaml
# ServiceAccount for Job
apiVersion: v1
kind: ServiceAccount
metadata:
  name: starr-integration-configurator
  namespace: media

---
# Role - read secrets, no write permissions needed
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: starr-integration-configurator
  namespace: media
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
```

---

## Monitoring & Observability

**Job Status:**
```bash
# Check Job execution
kubectl get jobs -n media -l app=starr-integration-configurator

# View logs
kubectl logs -n media -l job-name=starr-integration-configurator --tail=50
```

**Success Indicators:**
- Job completes with exit code 0
- Logs show "Configuration complete" or "Already configured"
- Services show correct integrations in UI/API

**Alerting:**
- If Job fails repeatedly → Alert (configuration issue)
- If CronJob stops running → Alert (CronJob issue)

---

## Next Steps

1. ✅ **Documentation** - This design document
2. ⏳ **Containerize script** - Create Dockerfile with script
3. ⏳ **Create Job manifest** - Kubernetes Job YAML
4. ⏳ **Test Job execution** - Verify it works end-to-end
5. ⏳ **Create CronJob** - Wrap Job in CronJob for self-healing
6. ⏳ **Integrate with ArgoCD** - Add sync hooks if desired

---

**Last Updated:** 2025-01-27  
**Status:** Design Complete - Ready for Implementation




