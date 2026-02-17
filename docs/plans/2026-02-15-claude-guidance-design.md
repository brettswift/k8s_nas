# CLAUDE.md Design Document

**Date:** 2026-02-15
**Purpose:** Design for Claude-specific guidance document that supplements existing AI_GUIDANCE.md

## Overview

Create a concise `CLAUDE.md` at the repository root that focuses on Claude Code-specific features, skills, and workflows for this k8s/GitOps project. This supplements the existing `docs/AI_GUIDANCE.md` which contains detailed infrastructure information.

## Design Principles

- **Concise over comprehensive** - High-level guidance that adapts to fluid workflows
- **Safety first** - Critical rules at the top, impossible to miss
- **Practical over theoretical** - Working examples and actual project patterns
- **Lightweight process** - No bmad-style heavy workflows
- **GitOps only** - Emphasize Git commits + ArgoCD, never direct kubectl apply

## Target Audience

Claude Code users (AI assistants) working on this k8s home server project with starr apps, who need to understand:
- What NOT to do (constraints)
- What Claude can do (skills)
- How the project is organized (structure)
- How to accomplish common tasks (workflows)

## Document Structure

### Section 1: Critical Rules
**Purpose:** Safety constraints that prevent breaking production

**Content:**
- 🚫 No local cluster - remote server only (10.1.0.20)
- 🚫 No `kubectl apply` - GitOps via Git + ArgoCD only
- ✅ Safe rollback pattern: `git push origin <branch>:live`
- ✅ All changes: Edit → Commit → Push → ArgoCD syncs
- Reference to `docs/AI_GUIDANCE.md` for detailed infrastructure info

**Rationale:** These rules must be at the top so they're impossible to miss. Prevents accidents that could break the live cluster.

### Section 2: Claude Skills for K8s Work
**Purpose:** Quick reference of Claude capabilities relevant to this project

**Content:**
- `superpowers:brainstorming` - Before adding services or architectural changes
- `superpowers:systematic-debugging` - When pods fail or ArgoCD won't sync
- `superpowers:writing-plans` - For multi-step changes
- `superpowers:verification-before-completion` - Verify on cluster before claiming success
- Note on workflow: Push to `live` → Test on cluster → Rollback if needed
- Example of how to invoke skills

**Rationale:** While Claude auto-invokes skills, documenting them gives users visibility into capabilities and allows explicit invocation. Removes TDD since the project tests on live cluster, not via TDD.

### Section 3: Project Structure & Conventions
**Purpose:** Where things live and how they're organized

**Content:**
- Directory tree: `apps/`, `argocd/`, `docs/`, `scripts/`, `bootstrap/`
- Key patterns: kustomization.yaml, standard k8s resources, shared configs
- Ingress pattern: all services at `home.brettswift.com/<service>`
- Branch strategy: `live` (what's running), `feat/*` (development)
- Deploy/rollback commands

**Rationale:** Understanding the structure is essential for making changes. Branch strategy highlights the unique `git push origin <branch>:live` pattern for easy deployments and rollbacks.

### Section 4: Common Workflows
**Purpose:** Practical patterns for typical operations

**Content:**
- Adding a new service (step-by-step)
- Debugging deployment issues (where to look)
- Updating configurations (edit → commit → push → sync)
- Rollback pattern (examples)

**Rationale:** High-level guidance with practical examples. Each workflow is concise but complete enough to execute.

### Section 5: Additional Resources
**Purpose:** Links and quick tips

**Content:**
- Links to key docs: AI_GUIDANCE.md, configure-starr-integrations.md, BOOTSTRAP.md
- Quick tips: kubeconfig, ArgoCD UI, server access, verification
- Philosophy: "Commit small, test on live, rollback easily"

**Rationale:** Points to detailed information without duplicating it. Quick tips provide frequently-needed info at a glance.

## What's NOT Included

- **Local cluster setup** - This project only uses the remote server at 10.1.0.20
- **kubectl apply commands** - All changes go through GitOps
- **Heavy process documentation** - No bmad-style elaborate workflows
- **Abstract k8s concepts** - Focus is on practical patterns for this project
- **TDD workflows** - Project tests on live cluster, not via TDD

## Relationship to Existing Documentation

- **AI_GUIDANCE.md** - Detailed infrastructure info (server access, certificates, current services)
- **CLAUDE.md** - Claude-specific features and high-level workflows
- **Other docs/** - Specific guides for integrations, bootstrap, etc.

`CLAUDE.md` references `AI_GUIDANCE.md` for details rather than duplicating content.

## Success Criteria

A successful `CLAUDE.md` will:
1. Prevent common mistakes (kubectl apply, local cluster confusion)
2. Surface Claude's relevant capabilities clearly
3. Enable quick understanding of project structure
4. Provide enough guidance to execute common tasks
5. Stay concise and maintainable
6. Not replicate bmad-style heavy process

## Implementation Notes

- File location: `/Users/bswift/src/brettswift/bs-mediaserver-projects/k8s_nas/CLAUDE.md`
- Format: Markdown with clear sections
- Length target: ~150-200 lines (concise)
- Tone: Direct, practical, safety-conscious
- Use elements-of-style skill for clear writing

## Next Steps

After approval:
1. Invoke `superpowers:writing-plans` skill to create implementation plan
2. Write the `CLAUDE.md` file following this design
3. Commit to feature branch
4. Review and deploy to live
