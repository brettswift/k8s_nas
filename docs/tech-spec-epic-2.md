# Epic Technical Specification: Observability and Monitoring

Date: 2025-01-27
Author: Brett
Epic ID: 2
Status: Draft

---

## Overview

Epic 2 establishes comprehensive monitoring and alerting infrastructure for the k8s_nas Kubernetes-based media server platform. This epic transforms the system from reactive troubleshooting to proactive issue detection by deploying Prometheus metrics collection, Grafana visualization dashboards, and intelligent alerting. The monitoring solution provides complete visibility into system health, service performance, resource utilization, and certificate management, enabling rapid response to issues before they impact users.

The epic builds on the service integration foundation completed in Epic 1, leveraging existing Prometheus and Grafana deployments in the `monitoring` namespace. The implementation focuses on automatic service discovery for media services, unified health dashboards, Kubernetes-native health checks, and multi-tier alerting for service availability, certificate expiry, and resource constraints.

## Objectives and Scope

### In Scope

- **Prometheus Service Discovery**: Automatic discovery and scraping of all media services in the `media` namespace
- **Grafana Dashboards**: Unified service health dashboard plus service-specific dashboards for major services (Sonarr, Radarr, Jellyfin, qBittorrent)
- **Kubernetes Health Checks**: Liveness and readiness probes for all media services
- **Alert Configuration**: Service down alerts, certificate expiry alerts (30-day warning), resource utilization alerts (CPU >80%, Memory >85%)
- **Monitoring Coverage Validation**: Verification that all 11 media services have metrics collection and alerting coverage
- **Certificate Monitoring**: Integration with cert-manager for certificate expiry tracking and renewal monitoring
- **Resource Monitoring**: CPU and memory utilization tracking per service with alert thresholds

### Out of Scope

- Application Performance Monitoring (APM) tools or distributed tracing
- Log aggregation systems (ELK, Loki) - logs remain in pod stdout/stderr
- Custom application-level metrics beyond standard Kubernetes/Prometheus metrics
- Multi-cluster or multi-region monitoring
- Advanced service mesh observability features
- Custom metrics exporters beyond standard Kubernetes metrics
- Historical data retention beyond Prometheus default (200 hours)

## System Architecture Alignment

This epic aligns with the GitOps-driven microservices platform architecture established in the k8s_nas system. The monitoring infrastructure leverages existing components:

**Existing Infrastructure:**
- Prometheus and Grafana already deployed in `monitoring` namespace via `apps/infrastructure/monitoring/`
- Prometheus configured with Kubernetes service discovery for pods, services, and nodes
- Grafana configured with Prometheus datasource and sub-path routing (`/grafana`)
- Both services accessible via NGINX Ingress at `https://home.brettswift.com/prometheus` and `https://home.brettswift.com/grafana`

**Architecture Components Referenced:**
- **Monitoring Namespace**: Existing `monitoring` namespace hosts Prometheus, Grafana, and Alertmanager
- **Media Namespace**: Target namespace (`media`) contains all 11 media services requiring monitoring
- **Kubernetes Service Discovery**: Prometheus uses `kubernetes_sd_configs` to automatically discover scrape targets
- **Ingress Routing**: Services follow path-based routing pattern (`/service`) established in Epic 1
- **GitOps Pattern**: All monitoring configuration managed via ConfigMaps and deployed through ArgoCD ApplicationSets

**Constraints:**
- Prometheus storage retention: 200 hours (8.3 days) as configured
- Resource limits: Prometheus (400Mi-1Gi memory, 200m-500m CPU), Grafana (256Mi-512Mi memory, 100m-200m CPU)
- Alerting: Uses ntfy.sh for notifications with rate limiting considerations
- Health check endpoints: Services must expose `/ping`, `/health`, or similar endpoints for probe configuration

## Detailed Design

### Services and Modules

| Service/Module | Responsibility | Inputs | Outputs | Owner |
|---------------|---------------|--------|---------|-------|
| **Prometheus** | Metrics collection and storage | Kubernetes API, pod annotations, service endpoints | Time-series metrics database | Infrastructure |
| **Grafana** | Metrics visualization and dashboards | Prometheus queries | Dashboard panels, alerts | Infrastructure |
| **Alertmanager** | Alert routing and notification | Prometheus alert rules | ntfy.sh notifications | Infrastructure |
| **Kubernetes Service Discovery** | Automatic target discovery | Pod/service annotations | Scrape target list | Prometheus |
| **Media Services** (11 services) | Application metrics exposure | Health endpoints, resource usage | Metrics via `/metrics` or annotations | Media namespace |
| **cert-manager** | Certificate lifecycle management | Certificate resources | Certificate expiry metrics | Infrastructure |

**Media Services to Monitor:**
1. Sonarr (TV management) - `media` namespace
2. Radarr (Movie management) - `media` namespace
3. Lidarr (Music management) - `media` namespace
4. Bazarr (Subtitle management) - `media` namespace
5. Prowlarr (Indexer management) - `media` namespace
6. Jellyseerr (Request management) - `media` namespace
7. Sabnzbd (Usenet client) - `media` namespace
8. Flaresolverr (CAPTCHA solver) - `media` namespace
9. Unpackerr (Archive extraction) - `media` namespace
10. Jellyfin (Media server) - `media` namespace
11. qBittorrent (BitTorrent client) - `qbittorrent` namespace

### Data Models and Contracts

**Prometheus Metrics Model:**
- **Time Series**: `metric_name{label1="value1", label2="value2"} timestamp value`
- **Labels**: `kubernetes_namespace`, `kubernetes_pod_name`, `container_name`, `service_name`
- **Metric Types**: Counter, Gauge, Histogram, Summary

**Key Metrics Collected:**

**Container Metrics (cAdvisor):**
- `container_cpu_usage_seconds_total` - Cumulative CPU usage
- `container_memory_working_set_bytes` - Memory working set
- `container_memory_rss` - Resident memory size

**Kubernetes Metrics (kube-state-metrics or API):**
- `kube_pod_status_phase` - Pod phase (Running, Pending, Failed, etc.)
- `kube_pod_container_status_restarts_total` - Container restart count
- `kube_pod_status_ready` - Readiness status (0/1)

**Certificate Metrics (cert-manager):**
- `cert_manager_certificate_expiration_timestamp` - Certificate expiry timestamp
- `cert_manager_certificate_ready_status` - Certificate readiness (0/1)

**Service Health Metrics:**
- Custom metrics via service annotations: `prometheus.io/scrape: "true"`, `prometheus.io/port: "8080"`, `prometheus.io/path: "/metrics"`

**Alert Rule Data Model:**
```yaml
groups:
  - name: <group_name>
    interval: <evaluation_interval>
    rules:
      - alert: <alert_name>
        expr: <promql_expression>
        for: <duration>
        labels:
          severity: <critical|warning|info>
        annotations:
          summary: <alert_summary>
          description: <detailed_description>
```

### APIs and Interfaces

**Prometheus API:**
- **Query API**: `GET /api/v1/query?query=<promql>` - Execute PromQL queries
- **Query Range API**: `GET /api/v1/query_range?query=<promql>&start=<time>&end=<time>&step=<duration>` - Range queries
- **Targets API**: `GET /api/v1/targets` - List scrape targets and status
- **Alerts API**: `GET /api/v1/alerts` - List active alerts

**Grafana API:**
- **Dashboard API**: `GET /api/dashboards/uid/<uid>` - Retrieve dashboard JSON
- **Datasource API**: `GET /api/datasources` - List configured datasources
- **Query API**: `POST /api/ds/query` - Execute queries against datasources

**Kubernetes API:**
- **Pod Metrics**: `/apis/metrics.k8s.io/v1beta1/namespaces/<namespace>/pods` - Resource usage metrics
- **Pod Status**: `/api/v1/namespaces/<namespace>/pods/<pod-name>` - Pod status and conditions
- **Service Discovery**: Prometheus uses Kubernetes API for service discovery via `kubernetes_sd_configs`

**Service Health Endpoints:**
- **Sonarr/Radarr**: `GET /ping` - Returns 200 OK if healthy
- **Jellyfin**: `GET /health` - Health check endpoint
- **Prowlarr/Jellyseerr**: `GET /api/v1/status` - Status endpoint
- **Generic**: Services expose `/metrics` endpoint for Prometheus scraping (if supported)

**Alertmanager API:**
- **Alert API**: `POST /api/v1/alerts` - Send alerts to Alertmanager
- **Webhook Receiver**: Alertmanager sends POST requests to configured webhook URLs (ntfy.sh)

### Workflows and Sequencing

**Service Discovery Workflow:**
1. Prometheus queries Kubernetes API for pods/services in `media` namespace
2. Prometheus filters targets based on annotations (`prometheus.io/scrape: "true"`)
3. Prometheus constructs scrape targets from pod IPs and annotation ports/paths
4. Prometheus scrapes metrics every 15 seconds (configured interval)
5. Metrics stored in Prometheus time-series database

**Alert Evaluation Workflow:**
1. Prometheus evaluates alert rules every 15 seconds (evaluation_interval)
2. Alert rule expression (PromQL) evaluated against current metrics
3. If expression returns true for `for` duration, alert fires
4. Alert sent to Alertmanager with labels and annotations
5. Alertmanager routes alert to configured receiver (ntfy.sh webhook)
6. Notification delivered to user

**Dashboard Query Workflow:**
1. User opens Grafana dashboard
2. Dashboard panel executes PromQL query via Grafana datasource
3. Grafana queries Prometheus API (`/api/v1/query_range`)
4. Prometheus evaluates query and returns time-series data
5. Grafana renders visualization (graph, table, gauge, etc.)

**Health Check Workflow:**
1. Kubernetes kubelet executes liveness probe (HTTP GET to `/ping` or `/health`)
2. If probe fails, kubelet restarts container
3. Kubernetes kubelet executes readiness probe
4. If probe fails, pod removed from Service endpoints
5. Prometheus monitors pod status via `kube_pod_status_phase` metric
6. Alert fires if pod phase != Running for > 5 minutes

**Certificate Monitoring Workflow:**
1. cert-manager manages Certificate resources
2. cert-manager exposes metrics via `/metrics` endpoint (if enabled)
3. Prometheus scrapes cert-manager metrics
4. Alert rule evaluates `cert_manager_certificate_expiration_timestamp`
5. Alert fires 30 days before expiration
6. Alert includes certificate name and expiry date

## Non-Functional Requirements

### Performance

**Metrics Collection Performance:**
- Prometheus scrape interval: 15 seconds (as configured)
- Scrape timeout: 10 seconds per target
- Target discovery refresh: Every 30 seconds
- Maximum scrape targets: ~20 pods/services (media namespace + infrastructure)

**Dashboard Performance:**
- Dashboard load time: < 3 seconds (NFR002 from PRD)
- Query response time: < 1 second for single panel queries
- Concurrent dashboard users: 1-2 (single administrator)
- Data retention: 200 hours (~8.3 days) as configured

**Alert Performance:**
- Alert evaluation interval: 15 seconds
- Alert delivery time: < 1 minute from detection to notification (NFR002)
- Alert rule evaluation: < 100ms per rule

**Resource Utilization:**
- Prometheus: 400Mi-1Gi memory, 200m-500m CPU (as configured)
- Grafana: 256Mi-512Mi memory, 100m-200m CPU (as configured)
- Total monitoring stack overhead: ~1.2Gi memory, ~400m CPU average

### Security

**Authentication & Authorization:**
- Prometheus ServiceAccount with RBAC permissions for Kubernetes API access
- Grafana admin password stored in deployment environment variable (consider Secret migration)
- Alertmanager webhook URLs configured securely (ntfy.sh topic names)

**Network Security:**
- Prometheus scrapes via Kubernetes Service DNS (internal cluster communication)
- Grafana accessible via HTTPS ingress with cert-manager certificates
- Alertmanager webhook calls to ntfy.sh over HTTPS

**Data Privacy:**
- Metrics contain pod names, namespaces, resource usage (no sensitive data)
- No API keys or secrets exposed in metrics
- Certificate expiry dates exposed (not private keys)

**Access Control:**
- Grafana dashboards accessible only via authenticated ingress
- Prometheus UI accessible only via authenticated ingress
- No external exposure of monitoring endpoints without TLS

### Reliability/Availability

**Monitoring Stack Availability:**
- Prometheus: Single replica (no HA), restarts automatically on failure
- Grafana: Single replica, restarts automatically on failure
- Alertmanager: Single replica (if deployed), restarts automatically on failure
- Storage: Prometheus uses emptyDir (data lost on pod restart) - acceptable for 200h retention

**Service Health Detection:**
- Mean Time to Detection (MTTD): < 2 minutes (NFR001 from PRD)
- Health check probe interval: 10-30 seconds (configurable per service)
- Health check timeout: 5 seconds
- Failure threshold: 3 consecutive failures before marking unhealthy

**Alert Reliability:**
- Alert delivery: Best-effort via ntfy.sh (rate limiting may delay non-critical alerts)
- Alert deduplication: Alertmanager groups similar alerts
- Alert persistence: Alerts stored in Alertmanager memory (lost on restart)

**Degradation Behavior:**
- If Prometheus unavailable: No new metrics collected, existing data remains queryable
- If Grafana unavailable: Dashboards inaccessible, alerts still fire
- If Alertmanager unavailable: Alerts fire but notifications not delivered
- If service discovery fails: Manual scrape target configuration fallback

### Observability

**Metrics Collection:**
- All 11 media services have metrics collection enabled (via annotations or `/metrics` endpoints)
- Kubernetes system metrics (CPU, memory, pod status) collected via cAdvisor
- Certificate metrics collected from cert-manager (if available)

**Logging:**
- Prometheus logs: Available via `kubectl logs` in `monitoring` namespace
- Grafana logs: Available via `kubectl logs` in `monitoring` namespace
- Service logs: Remain in pod stdout/stderr (not aggregated in this epic)

**Tracing:**
- Not implemented (out of scope)

**Dashboards:**
- Unified service health dashboard showing all services
- Service-specific dashboards for Sonarr, Radarr, Jellyfin, qBittorrent
- Certificate management dashboard
- Resource utilization dashboard

**Alert Coverage:**
- Service down alerts for all critical services
- Certificate expiry alerts (30-day warning)
- Resource utilization alerts (CPU >80%, Memory >85%)
- Health check failure alerts

## Dependencies and Integrations

**Kubernetes Dependencies:**
- Kubernetes API server: Required for service discovery and pod metrics
- cAdvisor: Container metrics collection (built into kubelet)
- kube-state-metrics: Optional, for enhanced pod status metrics (may not be deployed)

**Infrastructure Dependencies:**
- Prometheus: Already deployed in `monitoring` namespace (vLatest)
- Grafana: Already deployed in `monitoring` namespace (vLatest)
- Alertmanager: May need deployment if not already present
- cert-manager: Already deployed (v1.13.0) for certificate management

**External Dependencies:**
- ntfy.sh: Free tier push notification service for alerts (rate-limited)
- GitHub: Git repository for GitOps configuration management

**Service Dependencies:**
- Media services must expose health endpoints (`/ping`, `/health`, `/api/v1/status`)
- Services should support Prometheus annotations for scraping
- Services must be running in `media` or `qbittorrent` namespaces

**Configuration Dependencies:**
- Prometheus ConfigMap: `prometheus-config` in `monitoring` namespace
- Grafana ConfigMaps: `grafana-datasources`, `grafana-dashboards` in `monitoring` namespace
- Alert rules: Stored in Prometheus ConfigMap or separate ConfigMap

**Version Constraints:**
- Prometheus: Latest (as deployed)
- Grafana: Latest (as deployed)
- Kubernetes: k3s (latest) - supports all required APIs
- cert-manager: v1.13.0 (as deployed)

## Acceptance Criteria (Authoritative)

**AC2.1.1**: Prometheus configured with Kubernetes service discovery for `media` namespace
**AC2.1.2**: All services automatically discovered and added to scrape targets
**AC2.1.3**: Service discovery filters correctly identify media services
**AC2.1.4**: Prometheus successfully scrapes metrics from all discovered services
**AC2.1.5**: Service discovery configuration documented and validated

**AC2.2.1**: Grafana dashboard created with panels for each media service
**AC2.2.2**: Each panel shows service status (up/down) with color coding
**AC2.2.3**: Dashboard includes service response time metrics
**AC2.2.4**: Dashboard shows resource utilization (CPU, memory) per service
**AC2.2.5**: Dashboard loads within 3 seconds and updates in real-time

**AC2.3.1**: Liveness probes configured for all media services
**AC2.3.2**: Readiness probes configured for all media services
**AC2.3.3**: Health check endpoints verified (e.g., `/ping`, `/health`)
**AC2.3.4**: Unhealthy pods automatically restarted by Kubernetes
**AC2.3.5**: Unready pods removed from service endpoints until healthy

**AC2.4.1**: Alert rules created for service down conditions
**AC2.4.2**: Alerts trigger when service health check fails
**AC2.4.3**: Alert notifications configured (email, webhook, or similar)
**AC2.4.4**: Alerts fire within 1 minute of service failure
**AC2.4.5**: Alert includes service name, namespace, and remediation guidance

**AC2.5.1**: Alert rule created for certificate expiry monitoring
**AC2.5.2**: Alerts fire 30 days before certificate expiration
**AC2.5.3**: Alert includes certificate name, expiration date, and renewal instructions
**AC2.5.4**: Certificate status queryable via Prometheus metrics
**AC2.5.5**: Alert notifications configured and tested

**AC2.6.1**: Alert rules created for CPU utilization thresholds (e.g., >80%)
**AC2.6.2**: Alert rules created for memory utilization thresholds (e.g., >85%)
**AC2.6.3**: Alerts include service name, current usage, and limit
**AC2.6.4**: Resource metrics visible in Grafana dashboard
**AC2.6.5**: Alert notifications configured and tested

**AC2.7.1**: Individual Grafana dashboards created for Sonarr, Radarr, Jellyfin, qBittorrent
**AC2.7.2**: Each dashboard shows service-specific metrics (requests, downloads, library size, etc.)
**AC2.7.3**: Dashboards include historical trends and performance baselines
**AC2.7.4**: Dashboards accessible from unified health dashboard
**AC2.7.5**: Dashboard performance optimized for fast loading

**AC2.8.1**: All 11 media services have Prometheus metrics collection
**AC2.8.2**: All services included in unified health dashboard
**AC2.8.3**: All critical services have down alerts configured
**AC2.8.4**: Alert delivery tested for all alert types
**AC2.8.5**: Monitoring coverage documented in runbook

## Traceability Mapping

| AC ID | Spec Section | Component/API | Test Idea |
|-------|-------------|---------------|-----------|
| AC2.1.1 | Prometheus Service Discovery | `prometheus-config` ConfigMap, `kubernetes_sd_configs` | Verify Prometheus config includes `media` namespace service discovery |
| AC2.1.2 | Service Discovery | Prometheus `/api/v1/targets` API | Query Prometheus targets API, verify all media services listed |
| AC2.1.3 | Service Discovery Filters | Prometheus relabel_configs | Verify filters correctly identify media namespace services |
| AC2.1.4 | Metrics Scraping | Prometheus scrape targets | Check Prometheus UI targets page, verify all services show "UP" |
| AC2.1.5 | Documentation | Monitoring runbook | Verify service discovery configuration documented |
| AC2.2.1 | Grafana Dashboard | Grafana dashboard JSON | Verify unified dashboard exists with panels for all services |
| AC2.2.2 | Dashboard Panels | Grafana panel queries | Verify panels show up/down status with color coding (green/red) |
| AC2.2.3 | Response Time Metrics | PromQL queries for HTTP latency | Verify dashboard includes response time graphs |
| AC2.2.4 | Resource Metrics | `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes` | Verify CPU and memory panels show per-service utilization |
| AC2.2.5 | Dashboard Performance | Grafana load time | Measure dashboard load time, verify < 3 seconds |
| AC2.3.1 | Liveness Probes | Deployment manifests, `livenessProbe` | Verify all media service deployments have livenessProbe configured |
| AC2.3.2 | Readiness Probes | Deployment manifests, `readinessProbe` | Verify all media service deployments have readinessProbe configured |
| AC2.3.3 | Health Endpoints | Service HTTP endpoints | Test `/ping`, `/health`, `/api/v1/status` endpoints return 200 OK |
| AC2.3.4 | Pod Restart | Kubernetes kubelet | Stop service container, verify pod restarts automatically |
| AC2.3.5 | Service Endpoints | Kubernetes Service endpoints | Verify unhealthy pods removed from Service endpoint list |
| AC2.4.1 | Alert Rules | Prometheus alert rules ConfigMap | Verify alert rules exist for service down conditions |
| AC2.4.2 | Alert Evaluation | Prometheus alert evaluation | Stop a service, verify alert fires within evaluation interval |
| AC2.4.3 | Alert Notifications | Alertmanager webhook config | Verify ntfy.sh webhook configured in Alertmanager |
| AC2.4.4 | Alert Timing | Prometheus alert evaluation | Measure time from service failure to alert notification |
| AC2.4.5 | Alert Content | Alert annotations | Verify alert includes service name, namespace, remediation info |
| AC2.5.1 | Certificate Alert Rules | Prometheus alert rules | Verify certificate expiry alert rule exists |
| AC2.5.2 | Certificate Alert Timing | Alert rule `for` duration | Verify alert fires 30 days before expiration |
| AC2.5.3 | Certificate Alert Content | Alert annotations | Verify alert includes certificate name, expiry date, instructions |
| AC2.5.4 | Certificate Metrics | cert-manager metrics | Query Prometheus for certificate expiry metrics |
| AC2.5.5 | Certificate Alert Testing | Alert testing | Manually trigger certificate alert, verify notification received |
| AC2.6.1 | CPU Alert Rules | Prometheus alert rules | Verify CPU utilization alert rule with >80% threshold |
| AC2.6.2 | Memory Alert Rules | Prometheus alert rules | Verify memory utilization alert rule with >85% threshold |
| AC2.6.3 | Resource Alert Content | Alert annotations | Verify alerts include service name, current usage, limit |
| AC2.6.4 | Resource Dashboard | Grafana dashboard panels | Verify resource utilization visible in Grafana dashboard |
| AC2.6.5 | Resource Alert Testing | Alert testing | Simulate high CPU/memory usage, verify alerts fire |
| AC2.7.1 | Service Dashboards | Grafana dashboards | Verify individual dashboards exist for Sonarr, Radarr, Jellyfin, qBittorrent |
| AC2.7.2 | Service Metrics | Service-specific PromQL queries | Verify dashboards show service-specific metrics (requests, downloads, etc.) |
| AC2.7.3 | Historical Trends | Grafana time-series panels | Verify dashboards include historical trend graphs |
| AC2.7.4 | Dashboard Navigation | Grafana dashboard links | Verify service dashboards accessible from unified dashboard |
| AC2.7.5 | Dashboard Performance | Dashboard load time | Measure service dashboard load time, verify optimized |
| AC2.8.1 | Metrics Coverage | Prometheus targets | Verify all 11 media services appear in Prometheus targets |
| AC2.8.2 | Dashboard Coverage | Unified dashboard | Verify all services appear in unified health dashboard |
| AC2.8.3 | Alert Coverage | Alert rules | Verify critical services (Jellyfin, Sonarr, Radarr) have down alerts |
| AC2.8.4 | Alert Testing | End-to-end alert testing | Test all alert types (service down, cert expiry, resource), verify delivery |
| AC2.8.5 | Documentation | Monitoring runbook | Verify monitoring coverage documented with service list |

## Risks, Assumptions, Open Questions

**Risks:**

**R1: Service Discovery May Not Work for All Services**
- **Risk**: Some services may not expose metrics endpoints or support Prometheus annotations
- **Mitigation**: Use Kubernetes pod annotations (`prometheus.io/scrape: "true"`) and fallback to manual scrape config if needed
- **Impact**: Medium - May require manual configuration for some services

**R2: ntfy.sh Rate Limiting**
- **Risk**: Free tier ntfy.sh has rate limits that may delay non-critical alerts
- **Mitigation**: Implement alert throttling (critical alerts immediate, warnings throttled), consider upgrading to paid tier if needed
- **Impact**: Low - Critical alerts prioritized, warnings can be delayed

**R3: Prometheus Storage Growth**
- **Risk**: Prometheus storage may grow beyond available disk space with 200h retention
- **Mitigation**: Monitor Prometheus disk usage, reduce retention to 100h if needed, consider PVC expansion
- **Impact**: Low - Storage usage predictable (~1-4GB for cluster size)

**R4: Health Check Endpoints May Vary**
- **Risk**: Different services expose health endpoints at different paths (`/ping`, `/health`, `/api/v1/status`)
- **Mitigation**: Document endpoint per service, configure probes individually per deployment
- **Impact**: Low - Standardized during Epic 1, endpoints known

**Assumptions:**

**A1**: Prometheus and Grafana are already deployed and accessible (verified - exists in `monitoring` namespace)
**A2**: Media services support standard health endpoints (`/ping`, `/health`) (verified in Epic 1)
**A3**: cert-manager exposes metrics endpoint (may need verification/enablement)
**A4**: Kubernetes ServiceAccount has permissions for service discovery (verified - `prometheus` ServiceAccount exists)
**A5**: Alertmanager is deployed or can be deployed (may need verification)

**Open Questions:**

**Q1**: Does cert-manager expose metrics endpoint? If not, how to monitor certificate expiry?
- **Answer Needed**: Check cert-manager deployment for metrics endpoint, or use Certificate resource status via Kubernetes API

**Q2**: Should Alertmanager be deployed if not already present?
- **Answer Needed**: Verify Alertmanager deployment status, deploy if missing

**Q3**: Which services are considered "critical" for alerting priority?
- **Answer**: Jellyfin (media server), Sonarr/Radarr (content management), qBittorrent (downloads) - others can be warning level

**Q4**: Should we use kube-state-metrics for enhanced pod status metrics?
- **Answer**: Optional - cAdvisor metrics sufficient for basic monitoring, kube-state-metrics adds overhead

## Test Strategy Summary

**Test Levels:**

**1. Unit/Configuration Testing:**
- Validate Prometheus ConfigMap syntax (YAML validation)
- Validate Grafana dashboard JSON syntax
- Validate alert rule PromQL expressions
- Test service discovery configuration with `promtool check config`

**2. Integration Testing:**
- Verify Prometheus discovers all media services via Kubernetes API
- Verify Prometheus successfully scrapes metrics from discovered targets
- Verify Grafana can query Prometheus datasource
- Verify Alertmanager receives alerts from Prometheus
- Verify alert notifications delivered to ntfy.sh

**3. End-to-End Testing:**
- Stop a service pod, verify alert fires within 1 minute
- Verify alert notification received via ntfy.sh
- Verify service appears as "down" in Grafana dashboard
- Verify pod restarts automatically via liveness probe
- Verify pod removed from Service endpoints when unhealthy

**4. Performance Testing:**
- Measure Grafana dashboard load time (target: < 3 seconds)
- Measure Prometheus query response time (target: < 1 second)
- Measure alert evaluation time (target: < 100ms per rule)
- Monitor Prometheus resource usage during normal operation

**5. Coverage Testing:**
- Verify all 11 media services have metrics collection
- Verify all services appear in unified health dashboard
- Verify critical services have down alerts configured
- Verify all alert types tested (service down, cert expiry, resource utilization)

**Test Frameworks:**
- **Prometheus**: `promtool` for config validation
- **Grafana**: Manual testing via UI, API testing for dashboard creation
- **Kubernetes**: `kubectl` for pod/service status verification
- **Alert Testing**: Manual service failure simulation

**Edge Cases:**
- Service restart during metrics collection (should recover automatically)
- Multiple services failing simultaneously (alerts should group)
- Prometheus pod restart (should recover scrape targets)
- Network interruption during scrape (should retry on next interval)
- Certificate expiry exactly at 30-day threshold (alert should fire)

