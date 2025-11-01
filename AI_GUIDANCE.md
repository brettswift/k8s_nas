# General behaviour

**CRITICAL: This is a GitOps project. ALL changes must be made via Git commits and ArgoCD ApplicationSets. NO manual kubectl commands without explicit permission.**

- Do NOT spin up a local cluster. There is no local cluster; target the remote server at 10.0.0.20 only.
- Favor small, idempotent steps. Use `set -euo pipefail`. Never commit or echo secrets.
- One turn per objective: run, verify, and summarize results. Log outcomes in commit messages.

# AI Guidance for Kubernetes NAS Project

## Operating assumptions

- **Environment**: Single remote server at 10.0.0.20 (no local k3d/k3s).
- **GitOps**: All infra changes via Git + ArgoCD ApplicationSets. Sync via ArgoCD, not via kubectl.
- **Safety**: Treat `main` as production; use feature branches and PRs to merge. Roll back via git revert if a change cannot be fixed within 10 attempts.

## Server access (10.0.0.20)

- **SSH**:

```bash
ssh bswift@10.0.0.20
```

- Optional SSH config for friendlier access:

```bash
# ~/.ssh/config
Host nas
  HostName 10.0.0.20
  User bswift
  IdentityFile ~/.ssh/id_rsa
```

Then connect with:

```bash
ssh nas
```

## Branch strategy

- **dev**: development environment definitions
- **main**: production deployments
- **feat/***: feature work; open PRs into `dev` or `main` as appropriate

## ArgoCD usage

- Access ArgoCD via the server’s configured ingress or a secure tunnel approved for use. Do not use ad-hoc kubectl port-forwarding unless explicitly authorized.
- Manage applications via ApplicationSets; enable/disable services through Git-controlled values and labels.

## Developer and QA workflow

- **Developer**: implement changes via edits/commits; avoid breaking production. If a change causes issues, attempt up to 10 automated fixes; otherwise roll back cleanly.
- **QA**: verify prior steps and new features using a function-based shell test script (e.g., `scripts/qa-tests.sh`). Each test is a function; call the relevant test at the bottom. New features must add corresponding tests and re-run the full script.

## Notes

- Keep documentation concise and actionable. Prefer links to details in repository directories (e.g., `argocd/`, `apps/`, `environments/`).
- All configuration and operational changes must land via Git and be reconciled by ArgoCD.
