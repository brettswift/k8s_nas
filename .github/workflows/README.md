# GitHub Workflows

## Deploy and Rollback

### Flow

1. **PR required:** Branch protection on `live` requires a PR before merging.
2. **Comment `/deploy`** on the PR → workflow pushes PR branch to `live`.
3. **Rollback:** Comment `/rollback` → workflow pushes `live-backup` to `live`.

### Required: PR_DEPLOY_TOKEN Secret

The workflows use a PAT to push to `live` (branch protection blocks the default `GITHUB_TOKEN`).

1. Create a PAT: [github.com/settings/tokens](https://github.com/settings/tokens) → Generate new token (classic) → scope `repo`
2. Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
3. Name: `PR_DEPLOY_TOKEN`
4. Value: paste the PAT

### Deploy Workflow Details

- **Trigger:** Comment `/deploy` on a PR targeting `live`
- **Before push:** Saves `live` → `live-backup` (so rollback restores pre-deploy state)
- **Action:** Pushes PR head commit to `live`
- **Note:** The PR stays open; merge it separately to close, or leave it for record

### Rollback Workflow Details

- **Trigger:** Comment `/rollback` on a PR
- **Action:** Pushes `live-backup` → `live`
