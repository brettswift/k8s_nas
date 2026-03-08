#!/bin/bash
# Create Route53 CNAME for f1.home.brettswift.com (bypass if external-dns hasn't created it)
# Run after: assume brettswift-mgmt (or with AWS credentials for Route53)

set -e

HOSTED_ZONE_ID="Z1A5BHLIT8EGDS"
SUBDOMAIN="f1.home.brettswift.com"
TARGET="home.brettswift.com"

echo "Creating Route53 CNAME: $SUBDOMAIN -> $TARGET"

CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${SUBDOMAIN}.",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${TARGET}."}]
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

echo "Done. DNS may take a few minutes to propagate. Test: dig $SUBDOMAIN"
