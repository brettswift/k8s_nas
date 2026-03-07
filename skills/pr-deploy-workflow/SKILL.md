---
name: pr-deploy-workflow
description: Use when the user says /deploy or /rollback, or when creating PRs, pushing changes to the k8s_nas cluster, or recovering from a bad deploy.
---

# PR and Deploy Workflow (k8s_nas)

## Overview

This repo uses GitOps: ArgoCD tracks the `live` branch. All deployments go through Git; never `kubectl apply` directly (except temporary test pods).

---

## /deploy Command

When the user says `/deploy`, push the current branch to `live`:

```bash
git push origin <current-branch>:live
```

Then wait ~30 seconds for ArgoCD to sync and verify via HTTP:

```bash
curl -sI https://home.brettswift.com/<affected-service>
```

- Expect `200` or `301/302` — anything else indicates a problem
- If unreachable, report failure and tell the user to check ArgoCD manually

---

## /rollback Command

When the user says `/rollback`, execute this flow:

### Restore from live-backup (preferred)

`live-backup` is automatically updated daily at 6am UTC. It represents the last known-good state.

```bash
git push origin live-backup:live --force
```

### Verify rollback

Wait ~30 seconds for ArgoCD to sync, then check via HTTP:

```bash
curl -sI https://home.brettswift.com
```

- Expect `200` — if still broken, report and ask the user to check ArgoCD manually

### Alternative: revert a specific commit

```bash
git revert <commit> --no-edit
git push origin HEAD:live
```

---

## Key Rules

- **Always GitOps:** `git push <branch>:live` — never `kubectl apply` for persistent resources
- **Verify every deploy:** Wait for ArgoCD sync (~30s), then HTTP check the affected service
- **Critical services:** Confirm before touching Jellyfin or `/media`
- **No kubectl:** The bot has no cluster access — verification is HTTP-only

## Backup

- `live-backup` updated daily (6am UTC) via `.github/workflows/backup-live.yml`
- Manual trigger: GitHub Actions → "Backup live to live-backup" → Run workflow
