---
name: pr-deploy-workflow
description: Use when the user says /deploy or /rollback, or when creating PRs, pushing changes to the k8s_nas cluster, or recovering from a bad deploy.
---

# PR and Deploy Workflow (k8s_nas)

## Overview

This repo uses GitOps: ArgoCD tracks the `live` branch. All deployments go through Git; never `kubectl apply` directly (except temporary test pods).

Deployments are handled via **PR comments** using GitHub Actions.

---

## Automated Deployment via PR Comments

### Step 1: Create a PR

Push your feature branch and open a PR against `live`:

```bash
git checkout -b feat/BUD-XX_description
git add .
git commit -m "feat(BUD-XX): description"
git push origin feat/BUD-XX_description
```

### Step 2: Comment /deploy on the PR

In the PR, comment:
```
/deploy
```

The GitHub Action will:
1. Backup current `live` → `live-backup`
2. Push your PR branch → `live`
3. Post a success/failure comment

### Step 3: Verify deployment

Wait ~30 seconds for ArgoCD to sync, then verify:

```bash
curl -sI https://home.brettswift.com/<affected-service>
```

- Expect `200` or `301/302`
- If issues, comment `/rollback` on the PR to restore

---

## /rollback Command

If deployment fails, comment on the PR:
```
/rollback
```

The GitHub Action will:
1. Backup current `live` → `live-pre-rollback`
2. Restore `live-backup` → `live`
3. Post confirmation comment

---

## Manual /deploy (Fallback)

If GitHub Actions is unavailable, manually push:

```bash
git push origin <current-branch>:live
```

Or for rollback:

```bash
git push origin live-backup:live --force
```

---

## Key Rules

- **Use PR comments:** Comment `/deploy` or `/rollback` on PRs — GitHub Actions handles the rest
- **Always GitOps:** `git push <branch>:live` — never `kubectl apply` for persistent resources
- **Verify every deploy:** Wait for ArgoCD sync (~30s), then HTTP check the affected service
- **Critical services:** Confirm before touching Jellyfin or `/media`
- **No kubectl:** The bot has no cluster access — verification is HTTP-only
- **One PR per story:** Use branch naming like `feat/BUD-XX_description`

## Backup Strategy

**Automated backups during deploy:**
- `/deploy` backs up `live` → `live-backup` before deploying
- `/rollback` backs up `live` → `live-pre-rollback` before restoring

**Daily backup:**
- `live-backup` updated daily at 6am UTC via `.github/workflows/backup-live.yml`
- Manual trigger: GitHub Actions → "Backup live to live-backup" → Run workflow
