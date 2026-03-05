# Monitoring Alerting

## Overview

Prometheus evaluates alert rules and sends them to Alertmanager, which routes to an ntfy.sh bridge. The bridge forwards formatted notifications to ntfy.sh topics.

## Subscribe to Alerts

Subscribe to these ntfy.sh topics to receive push notifications:

- **Critical:** https://ntfy.sh/k8s-nas-critical (Jellyfin down, Homepage down, CrashLoopBackOff)
- **Warnings:** https://ntfy.sh/k8s-nas-warnings (SABnzbd down, high restarts)
- **All:** https://ntfy.sh/k8s-nas-alerts (fallback)

Use the ntfy app or open the URL in a browser to subscribe.

## Alert Rules

| Alert | Severity | Trigger |
|-------|----------|---------|
| PodCrashLoopBackOff | critical | Container in CrashLoopBackOff for 2m |
| PodHighRestarts | warning | 5+ restarts in 1h (media, homepage, qbittorrent) |
| JellyfinDown | critical | No Jellyfin replicas ready for 3m |
| HomepageDown | critical | No Homepage replicas ready for 3m |
| SABnzbdDown | warning | No SABnzbd replicas ready for 5m |

## Customize Topics

Edit `alertmanager-ntfy-bridge-configmap.yaml` to change NTFY_TOPIC_* values.
