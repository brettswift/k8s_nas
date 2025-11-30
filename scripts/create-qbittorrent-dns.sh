#!/bin/bash

# Create Route53 CNAME record for qbittorrent.home.brettswift.com
# Run this after: assume brettswift-mgmt

set -e

HOSTED_ZONE_ID="Z1A5BHLIT8EGDS"
SUBDOMAIN="qbittorrent.home.brettswift.com"
TARGET="home.brettswift.com"

echo "🌐 Creating Route53 CNAME record..."
echo "   Subdomain: $SUBDOMAIN"
echo "   Target: $TARGET"
echo "   Hosted Zone: $HOSTED_ZONE_ID"

# Check if record already exists
EXISTING=$(aws route53 list-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --query "ResourceRecordSets[?Name=='${SUBDOMAIN}.']" \
  --output json 2>/dev/null || echo "[]")

if [ "$EXISTING" != "[]" ]; then
  echo "⚠️  Record already exists. Checking if it's correct..."
  CURRENT_TARGET=$(echo "$EXISTING" | jq -r '.[0].ResourceRecords[0].Value' 2>/dev/null || echo "")
  if [ "$CURRENT_TARGET" = "$TARGET." ]; then
    echo "✅ Record already exists and is correct!"
    exit 0
  else
    echo "⚠️  Record exists but points to: $CURRENT_TARGET"
    echo "   Updating to point to: $TARGET"
  fi
fi

# Create/update the record
CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${SUBDOMAIN}.",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{
        "Value": "${TARGET}."
      }]
    }
  }]
}
EOF
)

CHANGE_ID=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "$CHANGE_BATCH" \
  --query 'ChangeInfo.Id' \
  --output text 2>&1)

if [ $? -eq 0 ]; then
  echo "✅ Route53 record created/updated successfully!"
  echo "   Change ID: $CHANGE_ID"
  echo ""
  echo "⏳ DNS propagation may take a few minutes..."
  echo "   You can check with: dig $SUBDOMAIN"
else
  echo "❌ Failed to create Route53 record"
  echo "$CHANGE_ID"
  exit 1
fi

