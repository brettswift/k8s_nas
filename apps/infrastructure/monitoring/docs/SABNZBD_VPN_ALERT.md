# Sabnzbd VPN health metric and Grafana alert

## What’s in place

- **Pushgateway** in `monitoring`: receives metrics pushed by batch jobs.
- **CronJob `sabnzbd-vpn-check`** (every 15 min): execs into the Sabnzbd pod’s VPN container, runs `wget https://ipinfo.io/json` through the tunnel, and pushes:
  - `sabnzbd_vpn_healthy 1` if the request succeeds
  - `sabnzbd_vpn_healthy 0` if no Sabnzbd pod or the request fails
- **Prometheus** scrapes Pushgateway; the metric appears as `sabnzbd_vpn_healthy` (and optionally `pushgateway_*` with job/instance labels).

## Grafana alert (once you have an alarm target)

1. In Grafana: **Alerting** → **Alert rules** (or **Contact points** first if you haven’t set one up).
2. **Contact point** (alarm target): add a contact point (e.g. webhook to ntfy.sh `bswift_general`, or email). Save.
3. **New alert rule:**
   - **Name:** e.g. `Sabnzbd VPN down`
   - **Query:** Prometheus,
     - Metric: `sabnzbd_vpn_healthy`
     - Or in PromQL: `sabnzbd_vpn_healthy == 0`
   - **Condition:** IS BELOW 1 (or “last value of B is 0”) for at least **2** evaluation periods (e.g. 2 × 15s = 30s, or use 2 × scrape interval so two consecutive failed checks ≈ 30 min).
   - **Contact point:** the one you created (e.g. ntfy).

**PromQL examples:**

- Alert when the metric is 0 (VPN check failed):
  ```promql
  sabnzbd_vpn_healthy == 0
  ```
- Alert when it’s been 0 for two consecutive scrapes (reduce flapping):
  ```promql
  sabnzbd_vpn_healthy == 0
  and
  on() (sabnzbd_vpn_healthy offset 1m == 0)
  ```
  Or use Grafana’s “for” duration (e.g. 5m) so the alert fires only if the condition holds for 5 minutes.

4. **Evaluate every:** e.g. 1m or 5m. **For:** 5m (so one missed cron run doesn’t alert immediately).

## Optional: run the check more or less often

Edit the CronJob schedule in `sabnzbd-vpn-check-cronjob.yaml`:

- `*/15 * * * *` = every 15 minutes (default)
- `0 * * * *` = once per hour
- `*/5 * * * *` = every 5 minutes

Then re-apply the manifest (or let ArgoCD sync).
