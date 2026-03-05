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

### 3. Alertmanager

- **ConfigMap:** `alertmanager-configmap.yaml` with route/receiver config
- **Deployment:** Single replica, `prom/alertmanager:latest`
- **Service:** ClusterIP on 9093
- **Route:** severity=critical → ntfy-critical, severity=warning → ntfy-warnings

### 4. ntfy.sh Bridge

- **Purpose:** Receive Alertmanager webhooks, format and POST to ntfy.sh
- **Options:**
  - **A)** In-cluster Python microservice (receives webhook, POSTs to `https://ntfy.sh/<topic>`)
  - **B)** External bridge (e.g. pinpox/alertmanager-ntfy, aTable/ntfy_alertmanager_bridge)
- **Topics:** `k8s-nas-critical`, `k8s-nas-warnings`, `k8s-nas-alerts` (configurable via ConfigMap)

### 5. User Action

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

## References

- `Monitoring-Proposal-1.md` – Phase 2 alerting, push services
- `docs/monitoring-design.md` – ntfy.sh integration, alert throttling
- `docs/tech-spec-epic-2.md` – Epic 2 acceptance criteria
