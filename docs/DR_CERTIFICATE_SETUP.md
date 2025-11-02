# Disaster Recovery: Certificate Setup

This document outlines the certificate setup process for disaster recovery scenarios.

## Overview

The wildcard certificate for `*.home.brettswift.com` uses cert-manager with Let's Encrypt and Route53 DNS challenge. The setup is designed to be **idempotent** and **DR-safe**.

## DR Flow

### Step 1: Bootstrap Process

The bootstrap process (`bootstrap/bootstrap.sh`) automatically:

1. Installs cert-manager (via `bootstrap/k8s_plugins.sh`)
2. Waits for cert-manager to be ready
3. Attempts to run certificate setup (if AWS credentials are available)

### Step 2: GitOps Deployment

ArgoCD ApplicationSet (`argocd/applicationsets/infrastructure-appset.yaml`) deploys:

- `apps/infrastructure/cert-manager/clusterissuer.yaml` - ClusterIssuer manifest
- `apps/infrastructure/cert-manager/certificate.yaml` - Certificate resource

**Important:** The ClusterIssuer in Git has an empty `accessKeyID: ""` field. This is intentional - sensitive credentials cannot be stored in Git.

### Step 3: Credential Injection

After GitOps creates the ClusterIssuer, run:

```bash
# 1. Ensure AWS credentials are available
assume brettswift-mgmt

# 2. Run the setup script (idempotent - safe to re-run)
./scripts/setup-home-wildcard-cert.sh
```

The script will:
1. Create the Route53 credentials secret (if missing)
2. Wait for ClusterIssuer to exist (created by GitOps)
3. Patch the ClusterIssuer with `accessKeyID` (merge strategy, survives GitOps sync)
4. Verify the patch was applied

## Why This Approach?

### GitOps-Compliant
- All manifests are in Git ✅
- Sensitive data (credentials) are injected via script ✅
- Certificate resource is managed by GitOps ✅

### DR-Safe
- Script is idempotent (can be re-run safely) ✅
- Merge patch strategy means GitOps won't overwrite the credential ✅
- Setup is documented and reproducible ✅

### Security
- AWS credentials never stored in Git ✅
- Secret stored in Kubernetes Secret (encrypted at rest) ✅
- accessKeyID is injected at runtime ✅

## Verification

After setup, verify:

```bash
# 1. Check ClusterIssuer has accessKeyID set
kubectl get clusterissuer letsencrypt-dns-home -o jsonpath='{.spec.acme.solvers[0].dns01.route53.accessKeyID}'
# Should output: ASIA... (your access key ID)

# 2. Check Route53 secret exists
kubectl get secret route53-credentials -n cert-manager

# 3. Check certificate is being issued
kubectl get certificate -n media home-brettswift-com-wildcard

# 4. Monitor certificate status
kubectl describe certificate -n media home-brettswift-com-wildcard
```

## Troubleshooting

### Issue: Certificate stuck in "Pending" state

**Check ClusterIssuer:**
```bash
kubectl describe clusterissuer letsencrypt-dns-home
kubectl get clusterissuer letsencrypt-dns-home -o yaml | grep -A 5 accessKeyID
```

**If accessKeyID is empty:**
```bash
assume brettswift-mgmt
./scripts/setup-home-wildcard-cert.sh
```

### Issue: Challenge fails with "NoCredentialProviders"

This means the `accessKeyID` is not set. Re-run the setup script.

### Issue: GitOps overwrote the accessKeyID patch

The script uses merge patch strategy, which should survive GitOps sync. If this happens:
1. Re-run the setup script
2. Consider adding an ArgoCD sync hook or post-sync job

## Future Improvements

Consider implementing:

1. **External Secrets Operator** - Automatically sync AWS credentials from Secrets Manager
2. **ArgoCD Sync Hook** - Automatically patch ClusterIssuer after GitOps creates it
3. **Sealed Secrets** - Encrypt credentials in Git (for non-AWS credentials)

