# Certificate Solution - Automated Let's Encrypt with DNS-01

## The Problem
- HTTP-01 challenge fails: Let's Encrypt can't reach private IP (10.0.0.20)
- DNS-01 challenge requires Route53 API access
- cert-manager Route53 provider doesn't support AWS session tokens (temporary credentials)

## The Solution: IAM Roles for Service Accounts (IRSA)

**This is the automated, best-practice solution that will work long-term.**

### How It Works
1. Create IAM role with Route53 permissions
2. Annotate cert-manager ServiceAccount with IAM role ARN
3. cert-manager assumes the role automatically (no credentials in secrets)
4. DNS-01 challenges work automatically
5. Certificates renew automatically every 60 days

### Implementation Steps

1. **Create IAM Role and Policy:**
```bash
# Create IAM policy for Route53
aws iam create-policy \
  --policy-name cert-manager-route53 \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "route53:GetChange",
        "route53:ListHostedZonesByName",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "*"
    }]
  }'

# Create IAM role (if using EKS) or use existing role
# Annotate cert-manager ServiceAccount with role ARN
```

2. **Update ClusterIssuer to use IRSA:**
```yaml
spec:
  acme:
    solvers:
    - dns01:
        route53:
          region: us-west-2
          # No accessKeyID or secretAccessKeySecretRef needed with IRSA
```

3. **Remove credential secrets** - IRSA handles authentication automatically

### Alternative: External Secrets Operator

If IRSA isn't available, use External Secrets Operator to automatically sync AWS credentials from Secrets Manager, refreshing them before expiry.

## Current Status

❌ **DNS-01 failing:** cert-manager doesn't support session tokens
✅ **Solution identified:** IRSA or External Secrets Operator
⏳ **Next step:** Implement IRSA or External Secrets Operator


