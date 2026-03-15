#!/bin/bash
# Create Route53 A record for f1.home.brettswift.com (bypass if external-dns hasn't created it)
# Run after: assume brettswift-mgmt (or with AWS credentials for Route53)

set -e

HOSTED_ZONE_ID="Z1A5BHLIT8EGDS"
SUBDOMAIN="f1.home.brettswift.com"
TARGET_IP="${1:-68.147.109.77}"

echo "Creating Route53 A record: $SUBDOMAIN -> $TARGET_IP"

CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${SUBDOMAIN}.",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${TARGET_IP}"}]
    }
  }]
}
EOF
)

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "$CHANGE_BATCH" \
  --query 'ChangeInfo.Id' \
  --output text

echo "Done. Pass IP as arg to override (default: 68.147.109.77). Test: dig $SUBDOMAIN"
