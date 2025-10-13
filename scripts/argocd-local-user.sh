#!/bin/bash
set -euo pipefail

# ArgoCD local user setup script
# Usage: ./scripts/argocd-local-user.sh <username> <password> [namespace]
# Example: ./scripts/argocd-local-user.sh admin 8480

NS="${3:-argocd}"
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <username> <password> [namespace]" >&2
  exit 1
fi
USER_NAME="$1"
USER_PASS="$2"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found" >&2
  exit 1
fi

# Generate bcrypt hash using ephemeral pod (apache2-utils)
POD_NAME="htpass-$(date +%s)"
kubectl -n "$NS" run "$POD_NAME" --restart=Never --image=alpine:3 --command -- sh -c "apk add --no-cache apache2-utils >/dev/null && htpasswd -nbBC 10 user '$USER_PASS' | cut -d: -f2 && sleep 1" >/dev/null
kubectl -n "$NS" wait --for=condition=Ready --timeout=60s pod/"$POD_NAME" >/dev/null
HASH_Y=$(kubectl -n "$NS" logs "$POD_NAME")
kubectl -n "$NS" delete pod "$POD_NAME" --ignore-not-found >/dev/null

# ArgoCD expects $2a prefix
HASH_A=$(printf %s "$HASH_Y" | sed 's/^\$2y/\$2a/')
NOW_RFC3339=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Ensure argocd-secret exists
kubectl -n "$NS" get secret argocd-secret >/dev/null 2>&1 || \
  kubectl -n "$NS" create secret generic argocd-secret --from-literal=server.secretkey="$(openssl rand -base64 32)" >/dev/null

# Patch secret using stringData (no base64 pre-encoding needed)
if [[ "$USER_NAME" == "admin" ]]; then
  kubectl -n "$NS" patch secret argocd-secret --type merge -p "{\"stringData\":{\"admin.password\":\"$HASH_A\",\"admin.passwordMtime\":\"$NOW_RFC3339\"}}" >/dev/null
else
  kubectl -n "$NS" patch secret argocd-secret --type merge -p "{\"stringData\":{\"accounts.$USER_NAME.password\":\"$HASH_A\",\"accounts.$USER_NAME.passwordMtime\":\"$NOW_RFC3339\"}}" >/dev/null
fi

# Enable local account in argocd-cm
if [[ "$USER_NAME" == "admin" ]]; then
  kubectl -n "$NS" patch configmap argocd-cm --type merge -p '{"data":{"admin.enabled":"true"}}' >/dev/null
else
  kubectl -n "$NS" patch configmap argocd-cm --type merge -p "{\"data\":{\"accounts.$USER_NAME\":\"login, apiKey\"}}" >/dev/null
fi

# Restart ArgoCD server
kubectl -n "$NS" rollout restart deployment/argocd-server >/dev/null
kubectl -n "$NS" wait --for=condition=available --timeout=180s deployment/argocd-server >/dev/null

# Optional: quick API verification via port-forward
set +e
kubectl -n "$NS" port-forward svc/argocd-server 8080:443 >/dev/null 2>&1 & PF_PID=$!
sleep 2
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" -X POST https://localhost:8080/api/v1/session -H 'Content-Type: application/json' --data "{\"username\":\"$USER_NAME\",\"password\":\"$USER_PASS\"}")
kill $PF_PID >/dev/null 2>&1 || true
set -e

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "Login verification succeeded for $USER_NAME"
else
  echo "Login verification returned HTTP $HTTP_CODE for $USER_NAME (check logs)"
fi
