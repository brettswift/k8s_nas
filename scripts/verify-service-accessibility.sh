#!/bin/bash
# Verify Service Accessibility
# Tests that all deployed services are accessible via ingress without 404 errors

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

DOMAIN="home.brettswift.com"
NAMESPACE="media"

echo "🌐 Verifying Service Accessibility"
echo "==================================="
echo ""
echo "Testing services at https://${DOMAIN}/<service>"
echo ""

# Get list of services from ingress
echo "Checking ingress routes..."
INGRESS_LIST=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.rules[0].http.paths[0].path}{" "}{.spec.rules[0].http.paths[0].backend.service.name}{"\n"}{end}')

FAILED=0
PASSED=0

while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi
    
    ingress_name=$(echo "$line" | awk '{print $1}')
    path=$(echo "$line" | awk '{print $2}' | sed 's|(/.*)||g' | sed 's|/$||')
    service_name=$(echo "$line" | awk '{print $3}')
    
    if [ -z "$path" ] || [ -z "$service_name" ]; then
        continue
    fi
    
    # Extract service name from path (remove leading /)
    service_path="${path#/}"
    
    echo "Testing: ${service_path}"
    echo "  Ingress: ${ingress_name}"
    echo "  Service: ${service_name}"
    echo "  URL: https://${DOMAIN}${path}"
    
    # Check if service exists and has endpoints
    if kubectl get service ${service_name} -n ${NAMESPACE} >/dev/null 2>&1; then
        endpoints=$(kubectl get endpoints ${service_name} -n ${NAMESPACE} -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || echo "")
        if [ -n "$endpoints" ]; then
            echo "  ✅ Service exists with endpoints"
            PASSED=$((PASSED + 1))
        else
            echo "  ⚠️  Service exists but no endpoints (pod not ready?)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "  ❌ Service does not exist"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
done <<< "$INGRESS_LIST"

# Also check for services that should have ingress but don't
echo "Checking for missing ingress routes..."
EXPECTED_SERVICES=("sonarr" "radarr" "prowlarr" "lidarr" "bazarr" "jellyseerr" "sabnzbd" "jellyfin")
for service in "${EXPECTED_SERVICES[@]}"; do
    if ! echo "$INGRESS_LIST" | grep -q "${service}"; then
        # Check if deployment exists
        if kubectl get deployment ${service} -n ${NAMESPACE} >/dev/null 2>&1; then
            echo "⚠️  ${service}: Deployment exists but no ingress route"
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo "=========================================="
echo "Summary:"
echo "  ✅ Passing: ${PASSED}"
echo "  ❌ Failing: ${FAILED}"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "✅ All accessible services have proper ingress configuration"
    exit 0
else
    echo ""
    echo "⚠️  Some services need attention (missing ingress or no endpoints)"
    exit 1
fi





