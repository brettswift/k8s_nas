#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Simple YAML scanner for ApplicationSets: outputs name,targetRevision,path
scan_dir() {
  local dir="$1"
  local file
  for file in "$dir"/*.yaml; do
    [[ -f "$file" ]] || continue
    awk -v f="$file" '
      $0 ~ /^kind:\s*ApplicationSet/ { inapp=1 }
      inapp && $0 ~ /^metadata:/ { inmeta=1 }
      inapp && inmeta && $0 ~ /^\s*name:/ { gsub(/name: /,""); name=$0; sub(/^\s*/,"",name) }
      inapp && $0 ~ /^\s*targetRevision:/ { tr=$2 }
      inapp && $0 ~ /^\s*path:/ { path=$2 }
      inapp && $0 ~ /^spec:/ { insp=1 }
      inapp && $0 ~ /^destination:/ { indest=1 }
      inapp && $0 ~ /^\s*namespace:/ { ns=$2 }
      inapp && $0 ~ /^\s*repoURL:/ { repo=$2 }
      inapp && $0 ~ /^\s*template:/ { }
      inapp && $0 ~ /^$/ { }
      END {
        if (name != "") {
          printf("%s|%s|%s|%s|%s\n", name, tr, path, ns, repo)
        }
      }
    ' "$file"
  done
}

echo "name|targetRevision|path|namespace|repoURL"
scan_dir "${REPO_ROOT}/argocd/applicationsets" | sort




