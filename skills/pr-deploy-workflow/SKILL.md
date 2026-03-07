---
name: pr-deploy-workflow
description: Outlines how to create PRs, deploy changes, and what to verify for the k8s_nas GitOps repo. Use when creating pull requests, deploying to live, pushing changes, or verifying deployments.
---

# PR and Deploy Workflow (k8s_nas)

## Overview

This repo uses GitOps: ArgoCD tracks the `live` branch. All deployments go through Git; never `kubectl apply` directly (except temporary test pods).

## PR Workflow

### 1. Create a Branch

```bash
git checkout -b feat/my-feature   # or fix/my-fix
```

### 2. Make Changes and Commit

- Commit on your branch
- Push: `git push origin feat/my-feature`

### 3. Open a PR

- Target branch: `live`
- PR: `feat/my-feature` → `live`

### 4. Before Merge

- [ ] Changes reviewed (self or others)
- [ ] No direct `kubectl apply` of persistent resources
- [ ] Critical services (Jellyfin, `/media`) – confirm OK if touching

## Deploy Workflow

### Option A: Direct Push to Live (bypass PR)

```bash
git push origin <branch>:live
```

Use when you have approval or are the sole maintainer. Still verify after push.

### Option B: Merge PR to Live

1. Merge PR (only you should have merge permission)
2. `live` updates automatically
3. ArgoCD syncs from `live`

### Deploy Command

```bash
git push origin <your-branch>:live
```

Example: `git push origin feat/monitoring:live`

## Post-Deploy Verification Checklist

**Do not assume the push worked. Verify.**

### 1. ArgoCD Sync

- Check ArgoCD UI or: `argocd app list` / `kubectl get applications -A`
- Confirm apps are `Synced` and `Healthy`
- If out of sync: trigger manual sync in ArgoCD

### 2. Pod Status

```bash
export KUBECONFIG=~/.kube/config-nas   # or your cluster config
kubectl get pods -A | grep -v Running
```

- Resolve any `CrashLoopBackOff`, `ImagePullBackOff`, `Pending`

### 3. Service Verification

- **Homepage:** `curl -sI https://home.brettswift.com` (or your URL)
- **Jellyfin:** Check UI loads
- **Changed app:** Hit its endpoint or UI

### 4. Logs (if issues)

```bash
kubectl logs -n <namespace> <pod> --tail=50
```

## Rollback

If a deploy breaks things:

```bash
# Restore from live-backup (daily backup branch)
git push origin live-backup:live
```

Or revert a specific commit:

```bash
git revert <commit> --no-edit
git push origin HEAD:live
```

## Key Rules (from dev.mdc)

- **Always GitOps:** `git push <branch>:live` – never `kubectl apply` for persistent resources
- **Verify:** Wait for ArgoCD sync, then check pods and services
- **Critical services:** Confirm before taking Jellyfin or `/media` offline
- **Test pods:** Use temporary `kubectl apply` test pods for API testing, then destroy them

## Backup

- `live-backup` branch is updated daily (6am UTC) via `.github/workflows/backup-live.yml`
- Manual backup: Actions → "Backup live to live-backup" → Run workflow
