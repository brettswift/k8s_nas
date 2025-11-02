#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDANCE_FILE="${REPO_ROOT}/docs/AI_GUIDANCE.md"
JELLYFIN_URL="https://home.brettswift.com/jellyfin/"
SONARR_URL="https://home.brettswift.com/sonarr/"
SAB_URL="https://home.brettswift.com/sabnzbd/"
RADARR_URL="https://home.brettswift.com/radarr/"

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

# --- Jellyfin tests ---
have_kubectl() {
  command -v kubectl >/dev/null 2>&1
}

cluster_reachable() {
  have_kubectl || return 1
  kubectl get ns -o name >/dev/null 2>&1 || return 1
}

have_network() {
  curl -skI --connect-timeout 3 https://home.brettswift.com >/dev/null 2>&1
}

test_jellyfin_http() {
  if ! have_network; then
    log "SKIP: No network access to home.brettswift.com"
    return 0
  fi
  local http_code
  http_code=$(curl -skL -o /tmp/jellyfin.html -w '%{http_code}' "$JELLYFIN_URL") || true
  if [[ "$http_code" =~ ^2|3 ]]; then
    if grep -qiE "jellyfin|doctype|html" /tmp/jellyfin.html; then
      log "OK: Jellyfin HTTP responded with page content"
      return 0
    fi
  fi
  log "FAIL: Jellyfin HTTP not serving main page (code=$http_code)"
  return 1
}

test_jellyfin_k8s() {
  if ! cluster_reachable; then
    log "SKIP: kubectl not configured or cluster unreachable"
    return 0
  fi
  # Deployment healthy
  if ! kubectl -n media get deploy jellyfin >/dev/null 2>&1; then
    log "FAIL: jellyfin deployment missing in namespace media"
    return 1
  fi
  local ready
  ready=$(kubectl -n media get deploy jellyfin -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [[ "$ready" != "1" ]]; then
    log "FAIL: jellyfin not ready (readyReplicas=$ready)"
    return 1
  fi
  log "OK: jellyfin deployment ready"

  # ArgoCD Application synced/healthy (best-effort)
  local app
  app=$(kubectl -n argocd get applications.argoproj.io -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -i jellyfin | head -n1 || true)
  if [[ -z "$app" ]]; then
    log "SKIP: No ArgoCD Application found matching jellyfin"
    return 0
  fi
  local sync health
  sync=$(kubectl -n argocd get applications.argoproj.io "$app" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  health=$(kubectl -n argocd get applications.argoproj.io "$app" -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  if [[ "$sync" == "Synced" && "$health" == "Healthy" ]]; then
    log "OK: ArgoCD app $app is Synced/Healthy"
    return 0
  fi
  log "FAIL: ArgoCD app $app not Synced/Healthy (sync=$sync health=$health)"
  return 1
}

# --- Sonarr tests ---
test_sonarr_http() {
  if ! have_network; then
    log "SKIP: No network access to home.brettswift.com"
    return 0
  fi
  local http_code
  http_code=$(curl -skL -o /tmp/sonarr.html -w '%{http_code}' "$SONARR_URL") || true
  if [[ "$http_code" =~ ^2|3 ]]; then
    if grep -qiE "sonarr|doctype|html" /tmp/sonarr.html; then
      log "OK: Sonarr HTTP responded with page content"
      return 0
    fi
  fi
  log "FAIL: Sonarr HTTP not serving main page (code=$http_code)"
  return 1
}

test_sonarr_k8s() {
  if ! cluster_reachable; then
    log "SKIP: kubectl not configured or cluster unreachable"
    return 0
  fi
  if ! kubectl -n media get deploy sonarr >/dev/null 2>&1; then
    log "FAIL: sonarr deployment missing in namespace media"
    return 1
  fi
  local ready
  ready=$(kubectl -n media get deploy sonarr -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [[ "$ready" != "1" ]]; then
    log "FAIL: sonarr not ready (readyReplicas=$ready)"
    return 1
  fi
  log "OK: sonarr deployment ready"

  # ArgoCD application (media-services) status
  local app="media-services-production-cluster"
  local sync health
  sync=$(kubectl -n argocd get applications.argoproj.io "$app" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  health=$(kubectl -n argocd get applications.argoproj.io "$app" -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  if [[ "$sync" == "Synced" && "$health" == "Healthy" ]]; then
    log "OK: ArgoCD app $app is Synced/Healthy"
    return 0
  fi
  log "FAIL: ArgoCD app $app not Synced/Healthy (sync=$sync health=$health)"
  return 1
}

# Call the first test with context
test_1 "AI guidance updated: no local cluster"

# Optionally run Jellyfin tests
test_jellyfin_http || true
test_jellyfin_k8s || true

# Sonarr tests (will pass after deployment)
test_sonarr_k8s || true
test_sonarr_http || true

# --- SABnzbd tests ---
test_sab_http() {
  if ! have_network; then
    log "SKIP: No network access to home.brettswift.com"
    return 0
  fi
  local http_code
  http_code=$(curl -skL -o /tmp/sab.html -w '%{http_code}' "$SAB_URL") || true
  if [[ "$http_code" =~ ^2|3 ]]; then
    if grep -qiE "sabnzbd|doctype|html" /tmp/sab.html; then
      log "OK: SABnzbd HTTP responded with page content"
      return 0
    fi
  fi
  log "FAIL: SABnzbd HTTP not serving main page (code=$http_code)"
  return 1
}

test_sab_k8s() {
  if ! cluster_reachable; then
    log "SKIP: kubectl not configured or cluster unreachable"
    return 0
  fi
  if ! kubectl -n media get deploy sabnzbd >/dev/null 2>&1; then
    log "FAIL: sabnzbd deployment missing in namespace media"
    return 1
  fi
  local ready
  ready=$(kubectl -n media get deploy sabnzbd -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [[ "$ready" != "1" ]]; then
    log "FAIL: sabnzbd not ready (readyReplicas=$ready)"
    return 1
  fi
  log "OK: sabnzbd deployment ready"
}

test_sab_k8s || true
test_sab_http || true

# --- Radarr tests ---
test_radarr_http() {
  if ! have_network; then
    log "SKIP: No network access to home.brettswift.com"
    return 0
  fi
  local http_code
  http_code=$(curl -skL -o /tmp/radarr.html -w '%{http_code}' "$RADARR_URL") || true
  if [[ "$http_code" =~ ^2|3 ]]; then
    if grep -qiE "radarr|doctype|html" /tmp/radarr.html; then
      log "OK: Radarr HTTP responded with page content"
      return 0
    fi
  fi
  log "FAIL: Radarr HTTP not serving main page (code=$http_code)"
  return 1
}

test_radarr_k8s() {
  if ! cluster_reachable; then
    log "SKIP: kubectl not configured or cluster unreachable"
    return 0
  fi
  if ! kubectl -n media get deploy radarr >/dev/null 2>&1; then
    log "FAIL: radarr deployment missing in namespace media"
    return 1
  fi
  local ready
  ready=$(kubectl -n media get deploy radarr -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [[ "$ready" != "1" ]]; then
    log "FAIL: radarr not ready (readyReplicas=$ready)"
    return 1
  fi
  log "OK: radarr deployment ready"
}

test_radarr_k8s || true
test_radarr_http || true


