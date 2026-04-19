#!/bin/bash

# Check if vacation.brettswift.com DNS record exists
# Run this after: assume brettswift-mgmt

set -e

HOSTED_ZONE_ID="Z1A5BHLIT8EGDS"
SUBDOMAIN="vacation.brettswift.com"
TARGET="home.brettswift.com"

echo "🌐 Checking Route53 CNAME record for travel site..."
echo "   Subdomain: $SUBDOMAIN"
echo "   Target: $TARGET"
echo "   Hosted Zone: $HOSTED_ZONE_ID"

# Check if record exists
EXISTING=$(aws route53 list-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --query "ResourceRecordSets[?Name=='${SUBDOMAIN}.']" \
  --output json 2>/dev/null || echo "[]")

if [ "$EXISTING" = "[]" ]; then
  echo "❌ Record does NOT exist in Route53!"
  echo ""
  echo "Possible issues:"
  echo "1. External-dns might not be running"
  echo "2. External-dns might not have permissions"
  echo "3. The ingress might not be annotated correctly"
  echo ""
  echo "Checking ingress annotation in k8s_nas repo..."
  grep -n "external-dns" ~/src/k8s_nas/apps/travel-planner/base/ingress-external.yaml
  exit 1
else
  echo "✅ Record exists in Route53!"
  CURRENT_TARGET=$(echo "$EXISTING" | jq -r '.[0].ResourceRecords[0].Value' 2>/dev/null || echo "")
  RECORD_TYPE=$(echo "$EXISTING" | jq -r '.[0].Type' 2>/dev/null || echo "")
  TTL=$(echo "$EXISTING" | jq -r '.[0].TTL' 2>/dev/null || echo "")
  
  echo "   Type: $RECORD_TYPE"
  echo "   TTL: $TTL"
  echo "   Current target: $CURRENT_TARGET"
  echo "   Expected target: $TARGET."
  
  if [ "$CURRENT_TARGET" = "$TARGET." ]; then
    echo "✅ Record is correct!"
  else
    echo "⚠️  Record exists but points to wrong target!"
    echo "   Expected: $TARGET."
    echo "   Actual: $CURRENT_TARGET"
    exit 1
  fi
fi

echo ""
echo "Testing DNS resolution..."
echo "Note: This checks from current location, not globally"

# Try to resolve
if command -v nslookup &> /dev/null; then
  nslookup $SUBDOMAIN
elif command -v dig &> /dev/null; then
  dig $SUBDOMAIN
else
  echo "Neither nslookup nor dig available. Using curl..."
  curl -I "https://$SUBDOMAIN" 2>&1 | head -5
fi