# RELEASE_TOKEN Setup

The release workflow (semantic-release) needs a PAT to push tags and create releases on `live`, bypassing branch protection.

## Create the token

1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Scopes: **`repo`** (full control)
4. Copy the token

## Add to repo

1. Repo → Settings → Secrets and variables → Actions
2. New repository secret: `RELEASE_TOKEN` = the token

## Bypass branch protection

The token's user must be allowed to bypass the "Changes must be made through a pull request" rule:

1. Repo → Settings → Rules → Rulesets (or Branches → live)
2. Edit the rule protecting `live`
3. Add the token owner to **Bypass list**
