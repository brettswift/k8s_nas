# General behaviour

**CRITICAL: This is a GitOps project. ALL changes must be made via Git commits and ArgoCD ApplicationSets. NO manual kubectl commands without explicit permission.**

Use single-turn, non-stop execution. Treat any chat message as an end-of-turn; therefore:

- Execute end-to-end within one turn: run a command, read output, decide next command, run it, re-check, loop, and only send a final message when the task completes or is truly blocked.
- Do not say "I’ll check in X seconds" or ask for approvals mid-task. Embed polling/retries/timeouts inside the turn.
- When long waits are needed, launch bounded background watchers and send ntfy updates for milestones (e.g., Synced/Healthy); still return only after the objective is met or a hard error occurs.
- Prefer small, sequential commands (one action per execution step) while making decisions in-between based on stdout/stderr/exit codes.
- Exit conditions: send one final summary (and ntfy) when all subtasks are done, or a hard blocker remains after reasonable automated remediation.
- Idempotence & safety: write idempotent scripts; use `set -euo pipefail`; never echo secrets; put tokens into dotfiles or Kubernetes Secrets; never commit secrets.
- Logging/commits: amend commits with concise results (what works/what doesn’t) per the repo convention; record root causes when found.

# AI Guidance for Kubernetes NAS Project

## Project Overview

This project migrates a Docker Compose-based media server setup to Kubernetes with ArgoCD ApplicationSets for label-driven GitOps deployment. The goal is to create a local development environment that mirrors production infrastructure using a modern ApplicationSets pattern.

## Current State

### What's Working
- ✅ k3s cluster is running locally
- ✅ ArgoCD is installed and accessible via port forwarding
- ✅ Basic Kubernetes infrastructure is in place
- ✅ Sample hello world application deployed and working
- ✅ Demo path accessible at http://localhost:30080/demo

### What's Being Refactored
- 🔄 **Migrating from static Applications to ApplicationSets**
- 🔄 **Moving from feat/istio_argo branch to dev branch**
- 🔄 **Implementing label-driven service deployment**

## Key Decisions Made

### 1. ApplicationSets Pattern
- **Label-driven deployment**: Services enabled/disabled via cluster labels
- **Environment-based**: `dev` branch for local, `main` for production
- **Dynamic service management**: No code changes needed to enable/disable services

### 2. Branch Strategy
- **`dev`**: Local development cluster (this machine)
- **`main`**: Production server deployments  
- **`feat/*`**: Feature branches for development
- **Deployment**: `git push origin feat/application_sets:dev`

### 3. Service Management
- **Cluster labels**: `kubectl label cluster local-cluster service-enabled=true`
- **Logical grouping**: `apps/media-services/` for related services
- **Infrastructure always-on**: ArgoCD, ingress, cert-manager
- **Applications optional**: Enable via labels

### 4. Current Authentication Configuration
```yaml
# argocd-rbac-cm
policy.csv: |
  p, role:admin, applications, *, */*, allow
  p, role:admin, clusters, *, *, allow
  p, role:admin, repositories, *, *, allow
  g, admin, role:admin
  g, bswift, role:admin

# argocd-cm (attempted)
users.admin.password: $2a$10$rRyBsGSHK6.ucBf3StsONe2BZ8F8eq5kFNe2r0u4ubUiYvczLz2Ca
users.bswift.password: $2a$10$rRyBsGSHK6.ucBf3StsONe2BZ8F8eq5kFNe2r0u4ubUiYvczLz2Ca

# argocd-secret (current)
admin.password: 8480
```

## Supporting Scripts

### `start_k8s.sh`
- Main setup script that installs k3s, ArgoCD, and required plugins
- Handles both macOS (k3d) and Linux (k3s) environments
- Creates ArgoCD users and configures RBAC

### `local-argocd-access.sh`
- Sets up port forwarding to ArgoCD
- Provides login credentials
- Handles cleanup of port forwards

### `k8s_plugins.sh`
- Installs essential Kubernetes plugins (kubectl, helm, etc.)

## Local Testing Process

### 1. Start the Environment
```bash
./start_k8s.sh
```

### 2. Access ArgoCD
```bash
./local-argocd-access.sh
```
- Opens https://localhost:8080
- **CRITICAL**: Login currently fails with 401 Unauthorized

### 3. Expected Workflow
1. Login to ArgoCD dashboard
2. Connect Git repository
3. Deploy applications via ArgoCD
4. Monitor deployments in UI

## Critical Issues to Fix

### 1. ArgoCD Authentication (PRIORITY 1)
- **Problem**: No users can authenticate despite multiple configuration attempts
- **Symptoms**: 401 Unauthorized on all login attempts
- **Attempted Solutions**:
  - Password in secret vs configmap
  - Different password formats
  - bcrypt hashing
  - User creation in RBAC
- **Next Steps**: Need to debug ArgoCD authentication mechanism

### 2. Ingress Configuration
- **Problem**: Path rewriting issues with `/argocd` prefix
- **Symptoms**: Assets load incorrectly, white screen
- **Workaround**: Using port forwarding instead

## File Structure

```
k8s_nas/
├── start_k8s.sh                 # Main setup script
├── local-argocd-access.sh       # ArgoCD access helper
├── k8s_plugins.sh              # Plugin installer
├── argocd/                     # ArgoCD configuration
│   ├── applications/           # ArgoCD app definitions
│   ├── ingress/               # Ingress configuration
│   └── projects/              # ArgoCD projects
├── apps/                      # Application definitions
│   ├── core-infrastructure/   # Base services
│   ├── media-services/        # Media server apps
│   └── monitoring/            # Observability stack
└── environments/              # Environment-specific configs
    ├── dev/
    └── prod/
```

## Next Steps for GPT

1. **Fix ArgoCD Authentication**
   - Debug why users can't authenticate
   - Check ArgoCD server logs for specific errors
   - Verify secret/configmap configuration
   - Test with ArgoCD CLI if needed

2. **Complete Service Migration**
   - Migrate Docker Compose services to Kubernetes manifests
   - Set up proper ingress for production access
   - Configure persistent volumes for data

3. **Production Readiness**
   - Decide between Istio and Traefik for routing
   - Set up proper TLS certificates
   - Configure monitoring and logging

## Environment Variables

```bash
# ArgoCD Configuration
ARGOCD_ADMIN_PASSWORD=8480
ARGOCD_BSWIFT_PASSWORD=8480

# Git Configuration
GIT_REPO_URL=https://github.com/brettswift/brettswift
GIT_BRANCH=feat/istio_argo
```

## Debugging Commands

```bash
# Check ArgoCD status
kubectl get pods -n argocd
kubectl logs deployment/argocd-server -n argocd

# Check authentication config
kubectl get configmap argocd-cm -n argocd -o yaml
kubectl get configmap argocd-rbac-cm -n argocd -o yaml
kubectl get secret argocd-secret -n argocd -o yaml

# Test port forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Notes for GPT

- **CRITICAL: This is a GitOps project. ALL infrastructure changes must be made via Git commits and ArgoCD ApplicationSets. NO manual kubectl commands without explicit permission.**
- The user is extremely frustrated with the authentication issues
- Multiple attempts have been made to fix login - all failed
- Focus on getting basic ArgoCD login working before proceeding
- The project structure is sound, but authentication is blocking progress
- Use the existing scripts as a foundation, don't rebuild from scratch
- All configuration changes must be committed to Git and deployed via ArgoCD
