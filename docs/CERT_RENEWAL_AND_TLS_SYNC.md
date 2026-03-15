# Certificate Renewal and TLS Secret Sync

When cert-manager renews the Let's Encrypt certificate, the new cert is written only to **kube-system** (where the Certificate resource lives). Ingress in other namespaces (media, argocd, homeautomation, etc.) use the **same secret name** but must have the secret **copied into their namespace**. If the copy is stale, browsers see "certificate expired" even though the Certificate resource is Ready.

## Why Services Break After Renewal

- **Certificate** `home-brettswift-com-dns` in **kube-system** issues into secret `home-brettswift-com-tls` in **kube-system**.
- Ingress resources in **media**, **argocd**, **homeautomation**, **homepage**, **monitoring**, **qbittorrent**, **dns** reference `secretName: home-brettswift-com-tls` in their **own** namespace.
- A **sync** must copy the secret from kube-system into each of those namespaces. The sync runs via the **cert-sync** CronJob (every 15 minutes) and must use **kube-system** as the source.

## Process That Works

### 1. Ensure the certificate is renewed (cert-manager)

- Check: `kubectl get certificate -n kube-system home-brettswift-com-dns`
- If **READY** is False, fix the ClusterIssuer (e.g. Route53 `accessKeyID` — see below) and/or delete the stuck CertificateRequest so a new one is created.
- If renewal fails with "only one of access and secret key was provided", patch the ClusterIssuer with the Route53 access key (from the existing secret):

  ```bash
  ACCESS_KEY=$(kubectl get secret route53-credentials -n cert-manager -o jsonpath='{.data.access-key-id}' | base64 -d)
  kubectl patch clusterissuer letsencrypt-dns-home --type='json' -p="[{\"op\":\"add\",\"path\":\"/spec/acme/solvers/0/dns01/route53/accessKeyID\",\"value\":\"$ACCESS_KEY\"}]"
  ```

  Then delete the stuck CertificateRequest so cert-manager re-issues:  
  `kubectl delete certificaterequest -n kube-system <name-of-stuck-request>`

### 2. Copy the TLS secret to all ingress namespaces (one-time after renewal)

Run from a machine with `KUBECONFIG` set (e.g. `export KUBECONFIG=~/.kube/config-nas`):

```bash
SECRET_NAME="home-brettswift-com-tls"
SOURCE_NS="kube-system"
TARGET_NS="argocd media homeautomation homepage monitoring qbittorrent dns"

for ns in $TARGET_NS; do
  kubectl get secret "$SECRET_NAME" -n "$SOURCE_NS" -o yaml | \
    sed "s/namespace: $SOURCE_NS/namespace: $ns/" | \
    sed '/^  uid:/d' | \
    sed '/^  resourceVersion:/d' | \
    sed '/^  selfLink:/d' | \
    sed '/^  creationTimestamp:/d' | \
    kubectl apply -f -
  echo "Synced to $ns"
done
```

### 3. Verify

- Check secret in a target namespace:  
  `kubectl get secret home-brettswift-com-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates`  
  Dates should match the renewed cert (e.g. ~90 days from renewal).
- Test a service:  
  `curl -sS -o /dev/null -w "%{http_code} %{ssl_verify_result}\n" https://home.brettswift.com/jellyfin/`  
  Expect `302 0` (redirect + SSL verify OK).

## Automated sync (CronJob)

The **sync-cert-secret** CronJob in the **argocd** namespace runs every 15 minutes. It must use **kube-system** as the source:

- In `apps/infrastructure/cert-manager/cert-sync-cronjob.yaml`, `SOURCE_NS` must be **kube-system** (not argocd).
- The CronJob discovers target namespaces by listing Ingress resources that reference `home-brettswift-com-tls` and copies the secret from kube-system into each.

After changing the cron to use kube-system, deploy via GitOps (commit and push to your deployment branch). Future renewals will then propagate within ~15 minutes; for immediate fix after a renewal, run the manual copy above.

## Quick reference

| Item | Location |
|------|----------|
| Certificate | `kube-system` / `home-brettswift-com-dns` |
| TLS secret (source) | `kube-system` / `home-brettswift-com-tls` |
| Sync CronJob | `argocd` / `sync-cert-secret` |
| Sync source (must be) | `kube-system` |

---

*Verified: curl to https://home.brettswift.com/jellyfin/ returns 302 with valid SSL after running the above process. Confirmed by user on 2026-03-01 (working on TV).*
