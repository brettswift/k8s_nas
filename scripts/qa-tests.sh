#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDANCE_FILE="${REPO_ROOT}/AI_GUIDANCE.md"

log() {
  printf '%s\n' "$*"
}

assert_contains() {
  local file_path="$1"
  local regex="$2"
  local message="$3"
  if ! LC_ALL=C grep -qE "$regex" "$file_path"; then
    log "FAIL: ${message}"
    return 1
  fi
  log "OK: ${message}"
}

test_1() {
  local context_message="${1:-AI guidance forbids local cluster}"
  assert_contains "$GUIDANCE_FILE" "Do NOT spin up a local cluster" "$context_message"
}

test_ssh_guidance() {
  assert_contains "$GUIDANCE_FILE" "10\\.0\\.0\\.20" "AI guidance includes server IP 10.0.0.20"
  assert_contains "$GUIDANCE_FILE" "\\bssh\\b" "AI guidance includes SSH instructions"
}

# Call the first test with context
test_1 "AI guidance updated: no local cluster"


