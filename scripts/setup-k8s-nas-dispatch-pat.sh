#!/usr/bin/env bash
# Interactive: set K8S_NAS_DISPATCH_PAT on GitHub repos (stdin to gh; nothing written to disk).
set -euo pipefail

echo ""
echo "== K8S_NAS dispatch PAT setup =="
echo "This stores the PAT as the Actions secret K8S_NAS_DISPATCH_PAT."
echo "Your typing will be hidden when you enter the PAT."
echo ""
read -r -p "Press Enter when you are ready."

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not found. Install it first, then run this script again."
  exit 1
fi

# Do not use `gh auth status` alone: it exits 1 if *any* cached github.com login is invalid,
# even when your main account works. API check matches what `gh secret set` needs.
if ! OWNER="$(gh api user -q .login 2>/dev/null)" || [[ -z "${OWNER}" ]]; then
  echo "gh cannot use a valid token for api.github.com."
  echo "Try: gh auth login -h github.com"
  echo ""
  echo "If gh says you are already logged in, you may have a stale second account. Run:"
  echo "  gh auth status"
  echo "Then remove the failed one, for example:"
  echo "  gh auth logout -h github.com -u 'OTHER_USERNAME_SHOWN_AS_FAILED'"
  exit 1
fi

echo ""
echo "You are logged in to GitHub as: ${OWNER}"
echo ""

read -r -s -p "Enter K8S_NAS_DISPATCH_PAT: " PAT
echo ""
if [[ -z "${PAT}" ]]; then
  echo "No input — exiting."
  exit 1
fi

read -r -p "Press Enter to set the secret on ${OWNER}/k8s_nas …"
printf '%s' "${PAT}" | gh secret set K8S_NAS_DISPATCH_PAT --repo "${OWNER}/k8s_nas"
echo "Done: ${OWNER}/k8s_nas"

echo ""
read -r -p "Set the same secret on ${OWNER}/travel-planner? [y/N] " yn
case "${yn}" in
  [yY] | [yY][eE][sS])
    printf '%s' "${PAT}" | gh secret set K8S_NAS_DISPATCH_PAT --repo "${OWNER}/travel-planner"
    echo "Done: ${OWNER}/travel-planner"
    ;;
  *)
    echo "Skipped travel-planner."
    ;;
esac

unset PAT
echo ""
echo "Finished. The PAT was only kept in memory for this session."
echo ""
