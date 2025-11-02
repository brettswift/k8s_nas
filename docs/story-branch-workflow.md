# Story-Based Branch Workflow

**Process Owner**: Scrum Master  
**Last Updated**: 2025-11-01  
**Status**: **MANDATORY PROCESS - ALL STORIES MUST FOLLOW THIS WORKFLOW**

## Overview

**This is the standard process for EVERY story.** Each story gets its own feature branch, created off the current deployment branch. The deployment branch is currently `dev_starr` (this may change over time - always check the current deployment branch). ArgoCD watches `dev_starr` branch for deployments.

## Branch Naming

Format: `feat/{story-id}-{story-name}`

Examples:
- `feat/1-2-configure-sonarr-prowlarr`
- `feat/1-3-configure-radarr-prowlarr-integration`

## Workflow Steps

### 1. Create Feature Branch (Developer)

**Always create the branch off the current deployment branch.** Currently this is `dev_starr`:

```bash
# Ensure you're on the deployment branch and it's up to date
git checkout dev_starr
git pull origin dev_starr

# Create feature branch off dev_starr
git checkout -b feat/{story-id}-{story-name}

# Push to remote and set upstream
git push -u origin feat/{story-id}-{story-name}
```

### 2. Development Work (Developer)

Work on the feature branch:

```bash
# Checkout feature branch (if not already on it)
git checkout feat/{story-id}-{story-name}
git pull

# Make changes and commit
git add .
git commit -m "feat(story-X.Y): description"
git push
```

### 3. Mid-Story Deployment Testing (Developer)

**When you want to deploy during development (without merging):**

To test changes immediately without switching ArgoCD tracking branches:

```bash
# Push feature branch directly to dev_starr
# This avoids having to reconfigure ArgoCD to track a different branch
git push origin feat/{story-id}-{story-name}:dev_starr
```

**Why this approach?** ArgoCD tracks `dev_starr`. By pushing the feature branch to `dev_starr`, you can test your changes immediately without changing ArgoCD configuration. ArgoCD will sync from `dev_starr` automatically.

### 4. Story Completion and Merge (Developer + SM)

**After QA is complete:**

```bash
# Switch to deployment branch
git checkout dev_starr
git pull origin dev_starr

# Merge feature branch with --no-ff to preserve branch history
git merge feat/{story-id}-{story-name} --no-ff

# Push the merge commit to dev_starr
git push origin dev_starr

# Clean up local branch
git branch -d feat/{story-id}-{story-name}

# Clean up remote branch (optional, can keep for reference)
git push origin --delete feat/{story-id}-{story-name}
```

**Important:** The `--no-ff` flag ensures a merge commit is created, making the branch and merge visible in git history.

## Key Principles

1. **One branch per story** - Each story has its own feature branch
2. **Branch off deployment branch** - Always create from current deployment branch (currently `dev_starr`)
3. **dev_starr is deployment branch** - ArgoCD watches `dev_starr`, not feature branches
4. **Mid-story deployment via push** - `git push origin feat/{branch}:dev_starr` to test without switching ArgoCD tracking
5. **Merge with --no-ff** - Always use `--no-ff` flag to create visible merge commit in history
6. **QA before merge** - Story must be QA'd before merging to `dev_starr`
7. **This is MANDATORY** - Every story must follow this process without exception

## Commit Message Format

Include story reference in commit messages:

- `feat(story-1.2): add Prowlarr deployment`
- `fix(story-1.2): correct ingress configuration`
- `docs(story-1.2): update integration docs`

## Example: Complete Story Workflow

```bash
# 1. Create feature branch (current deployment branch is dev_starr)
git checkout dev_starr
git pull origin dev_starr
git checkout -b feat/1-2-configure-sonarr-prowlarr
git push -u origin feat/1-2-configure-sonarr-prowlarr

# 2. Development work
git add .
git commit -m "feat(story-1.2): add Prowlarr deployment"
git push

# 3. Mid-story deployment testing
git push origin feat/1-2-configure-sonarr-prowlarr:dev_starr
# ArgoCD syncs from dev_starr automatically

# 4. Continue development...
git commit -m "fix(story-1.2): correct ingress configuration"
git push
git push origin feat/1-2-configure-sonarr-prowlarr:dev_starr

# 5. Story complete - QA done, merge to dev_starr
git checkout dev_starr
git pull origin dev_starr
git merge feat/1-2-configure-sonarr-prowlarr --no-ff
git push origin dev_starr

# 6. Cleanup
git branch -d feat/1-2-configure-sonarr-prowlarr
git push origin --delete feat/1-2-configure-sonarr-prowlarr
```

## Related Documentation

- [Development Guide](./development-guide.md#git-workflow)
- [Sprint Status](./sprint-status.yaml)
