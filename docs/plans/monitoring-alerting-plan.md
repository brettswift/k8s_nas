# Monitoring and Alerting Plan

**Status:** Plan only (not implemented)  
**Date:** 2026-03-05

## Overview

Add Prometheus alert rules, Alertmanager, and ntfy.sh push notifications to the existing Grafana + Loki stack. Alerts cover pod health (CrashLoopBackOff, high restarts), critical services (Jellyfin, Homepage, SABnzbd), and optional node resource thresholds.

## Prerequisites

- Prometheus, Grafana, Loki, Alloy already deployed in `monitoring` namespace
- kube-state-metrics **not** currently deployed (required for pod/deployment metrics)

## Components to Add

### 1. kube-state-metrics

- **Purpose:** Expose `kube_pod_*`, `kube_deployment_*` metrics for alert rules
- **Resources:** ServiceAccount, ClusterRole, ClusterRoleBinding, Deployment, Service
- **Namespace:** monitoring
- **Image:** `registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0`
- **Scrape:** Add job to Prometheus config: `kube-state-metrics.monitoring.svc.cluster.local:8080`

### 2. Prometheus Alert Rules

- **ConfigMap:** `prometheus-alertrules-configmap.yaml` with `alerts.yml`
- **Mount:** Add volume to Prometheus deployment at `/etc/prometheus/rules/`
- **Prometheus config:** Add `rule_files: - /etc/prometheus/rules/alerts.yml` and `alerting.alertmanagers`

**Proposed rules:**

| Alert | Severity | Expression | For |
|-------|----------|------------|-----|
| PodCrashLoopBackOff | critical | `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} == 1` | 2m |
| PodHighRestarts | warning | `increase(kube_pod_container_status_restarts_total{namespace=~"media\|homepage\|qbittorrent"}[1h]) >= 5` | 5m |
| JellyfinDown | critical | `kube_deployment_status_replicas_ready{deployment="jellyfin", namespace="media"} == 0` | 3m |
| HomepageDown | critical | `kube_deployment_status_replicas_ready{deployment="homepage", namespace="homepage"} == 0` | 3m |
| SABnzbdDown | warning | `kube_deployment_status_replicas_ready{deployment="sabnzbd", namespace="media"} == 0` | 5m |

**Optional / future rules** (from other design docs):

| Alert | Severity | Notes |
|-------|----------|-------|
| CronJobFailed | warning | `kube_job_failed > 0` for cert-sync, uptime-sync, etc. Requires kube-state-metrics job metrics |
| ImagePullBackOff | critical | `kube_pod_container_status_waiting_reason{reason="ImagePullBackOff"} == 1` |
| CertExpiringSoon | warning | 30 days before expiry; requires cert-manager metrics |
| NodeMemoryHigh | warning | `(1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes) * 100 > 90`; requires node-exporter |
| NodeCPUHigh | warning | Requires node-exporter |

### 3. ntfy.sh Throttling (Alertmanager)

From `docs/monitoring-design.md` – configure Alertmanager route `repeat_interval`:

- **Critical:** No throttling (e.g. 1h repeat)
- **Warning:** Throttled (e.g. 2h repeat, or 1 per 15 min via group_interval)
- **Info:** Heavily throttled (e.g. 4h repeat)

### 4. Alertmanager

- **ConfigMap:** `alertmanager-configmap.yaml` with route/receiver config
- **Deployment:** Single replica, `prom/alertmanager:latest`
- **Service:** ClusterIP on 9093
- **Route:** severity=critical → ntfy-critical, severity=warning → ntfy-warnings

### 5. ntfy.sh Bridge

- **Purpose:** Receive Alertmanager webhooks, format and POST to ntfy.sh
- **Options:**
  - **A)** In-cluster Python microservice (receives webhook, POSTs to `https://ntfy.sh/<topic>`)
  - **B)** External bridge (e.g. pinpox/alertmanager-ntfy, aTable/ntfy_alertmanager_bridge)
- **Topics:** `k8s-nas-critical`, `k8s-nas-warnings`, `k8s-nas-alerts` (configurable via ConfigMap)

### 6. User Action

- Subscribe to ntfy.sh topics: https://ntfy.sh/k8s-nas-critical, https://ntfy.sh/k8s-nas-warnings

## File Changes Summary

| File | Action |
|------|--------|
| `prometheus-configmap.yaml` | Add alerting block, rule_files, kube-state-metrics scrape job |
| `prometheus-deployment.yaml` | Add volume mount for alert rules ConfigMap |
| `prometheus-alertrules-configmap.yaml` | New |
| `kube-state-metrics-*.yaml` | New (5 files) |
| `alertmanager-configmap.yaml` | New |
| `alertmanager-deployment.yaml` | New |
| `alertmanager-service.yaml` | New |
| `alertmanager-ntfy-bridge-*.yaml` | New (3 files) |
| `kustomization.yaml` | Add all new resources |

## External Bot Access

How an external bot (outside the cluster) can access alarms, logs, and cluster status after implementation.

### 1. Alarms

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| **Alertmanager API** | `GET https://home.brettswift.com/alertmanager/api/v2/alerts` | Add Basic Auth or API key via ingress | Returns active alerts as JSON |
| **Prometheus API** | `GET https://home.brettswift.com/prometheus/api/v1/alerts` | Same as Prometheus UI | All firing alerts |
| **ntfy.sh subscribe** | `GET https://ntfy.sh/k8s-nas-critical` (SSE stream) | None (public topic) | Long-polling; bot receives pushes as they occur |

**Recommendation:** Expose Alertmanager via ingress with auth, or have the bot subscribe to ntfy.sh topics (SSE).

### 2. Log Queries

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| **Loki API** | `POST https://home.brettswift.com/loki/loki/api/v1/query_range` | Add auth on ingress | LogQL queries; Loki must be exposed |
| **Grafana API** | `POST /api/ds/query` (datasource proxy) | Grafana API key | Indirect; Grafana runs the query against Loki |

**Current state:** Loki is typically not exposed. Add ingress for Loki (e.g. `/loki`) and protect it.

**Recommendation:** Expose Loki behind ingress with auth; bot calls Loki query API directly.

### 3. Cluster Status

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| **Prometheus API** | `GET /api/v1/query?query=<PromQL>` | Same as Prometheus UI | Metrics (pods, CPU, memory, etc.) |
| **Prometheus API** | `GET /api/v1/query_range` | Same | Time-series for graphs |
| **Grafana API** | Dashboard JSON, panel data | Grafana API key | Pre-built dashboards |
| **Kubernetes API** | `https://<cluster>:6443` | Kubeconfig/token | Full cluster access; generally not exposed externally |

**Recommendation:** Use Prometheus for cluster status. Already exposed; has the metrics needed (e.g. `kube_pod_status_phase`, `kube_deployment_status_replicas_ready`).

### Summary for a Bot

| Need | Primary Option | Secondary |
|------|----------------|-----------|
| Alarms | ntfy.sh SSE subscribe | Alertmanager REST API |
| Logs | Loki query API (after ingress) | Grafana datasource API |
| Cluster status | Prometheus query API | Grafana API |

### Auth and Exposure Notes

- **Prometheus:** Already at `https://home.brettswift.com/prometheus`; add auth (Basic Auth, OAuth) on ingress if needed.
- **Alertmanager:** Add ingress + auth when deployed.
- **Loki:** Add ingress (e.g. `https://home.brettswift.com/loki`) + auth.
- **ntfy.sh:** No auth; anyone with topic name can subscribe. Use private/authenticated ntfy if secrecy needed.

## Success Metrics (from tech-spec)

- Mean time to detect (MTTD) pod failures: < 2 minutes
- Mean time to alert (MTTA) for critical issues: < 5 minutes
- Dashboard load time: < 3 seconds

## Future Phases (from Monitoring-Proposal-1)

- **Phase 3 – AI triage:** Local model (e.g. ollama) + suppression DB to reduce alert noise
- **Phase 4 – Capacity planning:** Node CPU/RAM/disk dashboards, disk usage alerts (80%, 90%)

## Related Documents – Consolidate or Archive

These docs overlap with this plan. **Recommendation:** Treat this plan as the single source of truth. Archive or delete the others to avoid confusion.

| Document | Content | Recommendation |
|----------|---------|----------------|
| `Monitoring-Proposal-1.md` (root) | Phase 1–4 vision, Gotify/Pushover, AI triage | **Archive** – Phase 3/4 captured above; push choice (ntfy) decided |
| `docs/monitoring-design.md` | Detailed design, dashboards, ntfy throttling, resource overhead | **Archive** – Useful reference; implementation details merged into this plan |
| `docs/tech-spec-epic-2.md` | Epic 2 acceptance criteria, APIs, NFRs | **Keep** – For story/AC tracking if using epic workflow; otherwise archive |

To archive: move to `docs/archive/` or add `_archived` suffix. To delete: remove after confirming nothing unique is lost.
