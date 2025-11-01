# Story-Based Branch Workflow

**Process Owner**: Scrum Master  
**Last Updated**: 2025-11-01

## Overview

Each story gets its own branch, created during grooming. Branches are story-driven, not sprint-driven. ArgoCD watches `dev_starr` branch for deployments.

## Branch Naming

Format: `story/{story-id}-{story-name}`

Examples:
- `story/1-2-configure-sonarr-prowlarr-integration`
- `story/1-3-configure-radarr-prowlarr-integration`

## Workflow Steps

### 1. Story Grooming (Scrum Master)

When a story moves to `ready-for-dev`:

```bash
# Ensure dev_starr is up to date
git checkout dev_starr
git pull origin dev_starr

# Create story branch
git checkout -b story/{story-id}-{story-name}

# Push to remote
git push -u origin story/{story-id}-{story-name}
```

### 2. Development (Developer)

Work on the story branch:

```bash
# Checkout story branch (already exists)
git checkout story/{story-id}-{story-name}
git pull

# Make changes and commit
git add .
git commit -m "feat(story-X.Y): description"
git push
```

### 3. Immediate Deployment Testing (Developer - Optional)

To test changes immediately without merging:

```bash
# Push story branch directly to dev_starr
git push origin story/{story-id}-{story-name}:dev_starr
```

**Note**: This overwrites dev_starr. Use only for testing. ArgoCD will sync from dev_starr immediately.

### 4. Story Completion (Developer + SM)

When story is marked `done`:

```bash
# Merge to dev_starr
git checkout dev_starr
git pull origin dev_starr
git merge story/{story-id}-{story-name}
git push origin dev_starr

# Clean up local branch
git branch -d story/{story-id}-{story-name}

# Clean up remote branch
git push origin --delete story/{story-id}-{story-name}
```

## Key Principles

1. **One branch per story** - Each story has its own branch
2. **Branch created during grooming** - SM creates branch when story is `ready-for-dev`
3. **dev_starr is deployment branch** - ArgoCD watches dev_starr, not feature branches
4. **Immediate deployment via push** - `git push story/{branch}:dev_starr` for testing
5. **Merge on completion** - Story branch merges to dev_starr when done

## Commit Message Format

Include story reference in commit messages:

- `feat(story-1.2): add Prowlarr deployment`
- `fix(story-1.2): correct ingress configuration`
- `docs(story-1.2): update integration docs`

## Related Documentation

- [Development Guide](./development-guide.md#git-workflow)
- [Sprint Status](./sprint-status.yaml)
