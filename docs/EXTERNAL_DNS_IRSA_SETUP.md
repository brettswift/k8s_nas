# External DNS with IAM Roles (IRSA)

External DNS can use IAM roles instead of storing credentials in secrets. This is more secure and follows AWS best practices.

## Option 1: Instance Profile (if k3s runs on EC2)

If your k3s nodes are EC2 instances, you can attach an IAM role to the instances:

1. **Create IAM Role and Policy:**
```bash
# Create IAM policy for External DNS
aws iam create-policy \
  --policy-name external-dns-route53 \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "route53:GetChange",
        "route53:ListHostedZones",
        "route53:ListHostedZonesByName",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "*"
    }]
  }'

# Create IAM role and attach policy
aws iam create-role \
  --role-name external-dns-route53 \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name external-dns-route53 \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/external-dns-route53

# Create instance profile
aws iam create-instance-profile --instance-profile-name external-dns-route53
aws iam add-role-to-instance-profile \
  --instance-profile-name external-dns-route53 \
  --role-name external-dns-route53

# Attach to EC2 instances
aws ec2 associate-iam-instance-profile \
  --instance-id i-INSTANCE_ID \
  --iam-instance-profile Name=external-dns-route53
```

2. **Update External DNS Deployment:**
Remove the AWS credential environment variables - External DNS will automatically use the instance profile.

## Option 2: Keep Using Secrets (Current Setup)

If you're not on EC2 or prefer secrets, the current setup works fine. The sync cronjob keeps secrets in sync across namespaces.

## Migration

To switch from secrets to IRSA:
1. Set up IAM role (Option 1)
2. Remove `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` env vars from deployment
3. External DNS will automatically use instance profile credentials

