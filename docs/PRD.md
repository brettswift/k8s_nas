# k8s_nas Product Requirements Document (PRD)

**Author:** Brett  
**Date:** 2025-11-01  
**Project Level:** 3  
**Target Scale:** Production media server infrastructure

---

## Goals and Background Context

### Goals

- Complete service integration and API key configuration across all Starr services for seamless inter-service communication
- Establish reliable monitoring and alerting for production-grade observability of media services infrastructure
- Implement automated backup and disaster recovery strategy for configurations and critical data
- Achieve full GitOps automation where all infrastructure changes are managed through ArgoCD ApplicationSets
- Optimize VPN integration and network security for download services
- Ensure production-ready SSL certificate management with automated renewal

### Background Context

The k8s_nas project is a Kubernetes-based Network Attached Storage media server infrastructure that has been migrated from a docker-compose setup to a GitOps-managed Kubernetes deployment. The project currently has all core Starr media management services (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr, Jellyfin, qBittorrent, Sabnzbd) successfully deployed and running on a remote Kubernetes cluster at 10.0.0.20.

The infrastructure uses ArgoCD ApplicationSets for GitOps deployment management, NGINX Ingress for routing, and follows a GitOps-first approach where all changes must be committed to Git and reconciled through ArgoCD. Services are accessible via `https://home.brettswift.com/<service>` with path-based routing.

**Current State:**
- ✅ All services deployed and running in `media` namespace
- ✅ Infrastructure foundation (ArgoCD, NGINX Ingress) established
- ✅ Configurations migrated from docker-compose setup
- ⚠️ Services require API key configuration and inter-service integration
- ⚠️ Monitoring, backup, and production hardening needed

**Key Challenge:**
While services are running, they lack proper configuration for inter-service communication, monitoring, and production-grade reliability. This PRD addresses the gap between "deployed" and "production-ready" by establishing requirements for service integration, observability, and operational excellence.

---

## Requirements

### Functional Requirements

#### Service Integration (Phase 1)

**FR001: API Key Configuration**
- The system shall configure API keys for all Starr services (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr) to enable inter-service communication.

**FR002: Sonarr Integration**
- The system shall configure Sonarr to communicate with Prowlarr for indexer management.
- The system shall configure Sonarr to use qBittorrent as the download client via VPN.
- The system shall configure Sonarr root folders to `/data/media/tv` for TV show storage.

**FR003: Radarr Integration**
- The system shall configure Radarr to communicate with Prowlarr for indexer management.
- The system shall configure Radarr to use qBittorrent as the download client via VPN.
- The system shall configure Radarr root folders to `/data/media/movies` for movie storage.

**FR004: Prowlarr Application Management**
- The system shall configure Prowlarr to manage indexers for both Sonarr and Radarr.
- The system shall enable automatic indexer synchronization between Prowlarr and Starr applications.

**FR005: Jellyseerr Integration**
- The system shall configure Jellyseerr to connect to Jellyfin media server.
- The system shall configure Jellyseerr to communicate with Sonarr and Radarr for content requests.
- The system shall enable request management workflows through Jellyseerr.

**FR006: VPN Integration Verification**
- The system shall verify qBittorrent connectivity through VPN service (Gluetun).
- The system shall validate that all download traffic routes through VPN network.
- The system shall test download functionality to confirm VPN integration.

#### Observability (Phase 2)

**FR007: Prometheus Service Discovery**
- The system shall configure Prometheus to automatically discover all media services for metrics collection.
- The system shall enable Prometheus scraping for all services in the `media` namespace.

**FR008: Grafana Dashboards**
- The system shall create Grafana dashboards for all media services showing health, performance, and resource utilization.
- The system shall provide a unified dashboard showing overall infrastructure health.

**FR009: Service Health Monitoring**
- The system shall implement health checks for all services using Kubernetes liveness and readiness probes.
- The system shall monitor service availability and response times.

**FR010: Alert Configuration**
- The system shall configure alerts for service down conditions with immediate notification.
- The system shall configure certificate expiry warnings (30 days before expiration).
- The system shall configure resource utilization alerts (CPU, memory thresholds).
- The system shall configure health check failure alerts.

#### Operational Excellence (Phase 3)

**FR011: Automated Configuration Backup**
- The system shall perform automated daily backups of all service configurations.
- The system shall store backups in a designated backup location with retention policy.
- The system shall include PVC data (PersistentVolumeClaims) in backup scope.

**FR012: Backup Verification**
- The system shall verify backup integrity after each backup operation.
- The system shall test backup restoration procedures to ensure recoverability.

**FR013: Disaster Recovery Procedures**
- The system shall provide documented recovery procedures for all services.
- The system shall enable recovery of any single service configuration within 1 hour.
- The system shall support recovery of complete infrastructure from backups.

**FR014: GitOps Completion**
- The system shall ensure all infrastructure changes are managed through ArgoCD ApplicationSets.
- The system shall eliminate manual kubectl apply operations for production changes.
- The system shall maintain Git repository as the single source of truth.

**FR015: Certificate Management Automation**
- The system shall monitor SSL certificate status and renewal schedules.
- The system shall alert on certificate expiry risks.
- The system shall verify cert-manager automatic certificate renewal functionality.

#### Production Hardening (Phase 4)

**FR016: VPN Security Verification**
- The system shall verify VPN network isolation for download services.
- The system shall validate that only download services use VPN, media services use standard networking.

**FR017: Network Security**
- The system shall ensure all services are accessible only via HTTPS.
- The system shall verify proper TLS termination at ingress level.

**FR018: Operational Documentation**
- The system shall provide runbooks for common operational tasks.
- The system shall document recovery procedures for each service type.
- The system shall maintain architecture documentation reflecting current state.

### Non-Functional Requirements

**NFR001: Reliability and Availability**
- The system shall achieve 99%+ uptime for all critical media services.
- The system shall detect service failures within 5 minutes and alert immediately.
- The system shall support automated recovery from common failure patterns.

**NFR002: Performance**
- Service health checks shall respond within 2 seconds.
- Grafana dashboards shall load within 3 seconds.
- Alert delivery shall occur within 1 minute of event detection.

**NFR003: Maintainability**
- All infrastructure changes shall be version-controlled in Git.
- Configuration changes shall be reversible via GitOps rollback.
- Operational procedures shall be documented and repeatable.

**NFR004: Security**
- All service communications shall use encrypted channels (HTTPS/TLS).
- VPN isolation shall be maintained for download services.
- Certificate management shall be automated with monitoring.

**NFR005: Observability**
- All services shall have metrics collection enabled.
- System health visibility shall be available through centralized dashboards.
- Alert coverage shall include all critical failure scenarios.

---

## User Journeys

### Journey 1: Service Integration Configuration

**Actor:** System Administrator (Brett)

**Goal:** Configure Sonarr to automatically download TV shows using Prowlarr indexers and qBittorrent download client.

**Steps:**
1. Administrator accesses Sonarr UI via `https://home.brettswift.com/sonarr`
2. Administrator navigates to Settings → General → API Key section
3. Administrator retrieves API key from existing configuration or generates new one
4. Administrator configures API key in Kubernetes ConfigMap/Secret
5. Administrator navigates to Settings → Download Clients
6. Administrator adds qBittorrent as download client using Kubernetes Service DNS (`qbittorrent.qbittorrent.svc.cluster.local:8080`)
7. Administrator enters qBittorrent API credentials
8. Administrator navigates to Settings → Indexers
9. Administrator configures Prowlarr as indexer manager using service DNS (`prowlarr.media.svc.cluster.local:9696`)
10. System automatically synchronizes indexers from Prowlarr
11. Administrator navigates to Settings → Media Management → Root Folders
12. Administrator configures root folder as `/data/media/tv`
13. Administrator tests integration by adding a TV show
14. System successfully searches for content via Prowlarr
15. System successfully initiates download via qBittorrent through VPN
16. Administrator verifies download completes and content moves to library

**Alternatives:**
- If API key is invalid, system displays error and administrator regenerates key
- If qBittorrent is unreachable, administrator verifies VPN connectivity
- If Prowlarr sync fails, administrator checks service health and DNS resolution

**Edge Cases:**
- Service restart during configuration - configuration persists via ConfigMap/PVC
- Network interruption - system retries connections automatically
- Invalid credentials - system provides clear error messages

### Journey 2: Monitoring and Alerting Setup

**Actor:** System Administrator (Brett)

**Goal:** Set up monitoring and receive alerts when services become unavailable.

**Steps:**
1. Administrator accesses Grafana via `https://home.brettswift.com/grafana`
2. Administrator logs into Grafana dashboard
3. Administrator navigates to Prometheus datasource (pre-configured)
4. Administrator creates new dashboard for media services
5. Administrator adds panels for each service showing:
   - Pod status (up/down)
   - HTTP response times
   - Resource utilization (CPU, memory)
6. Administrator navigates to Alerting section
7. Administrator creates alert rule for service down condition
8. Administrator configures alert notification channel (email/webhook)
9. Administrator tests alert by temporarily stopping a service pod
10. System detects service down condition
11. Prometheus triggers alert within 1 minute
12. Alert notification is delivered to administrator
13. Administrator accesses Grafana dashboard to investigate
14. Dashboard shows service status and recent metrics
15. Administrator resolves issue and verifies service recovery
16. Alert automatically resolves when service returns to healthy state

**Alternatives:**
- If Prometheus not scraping - administrator checks service discovery configuration
- If alert not firing - administrator verifies alert rule thresholds
- If notification not delivered - administrator checks notification channel configuration

**Edge Cases:**
- Brief service restart - alert fires but auto-resolves quickly
- Partial service degradation - resource utilization alerts trigger
- Certificate expiry approaching - warning alert fires 30 days early

### Journey 3: Backup and Recovery

**Actor:** System Administrator (Brett)

**Goal:** Restore a service configuration after accidental loss or corruption.

**Steps:**
1. Administrator discovers Sonarr configuration is corrupted or lost
2. Administrator accesses backup storage location
3. Administrator identifies most recent Sonarr configuration backup
4. Administrator verifies backup integrity (checksum validation)
5. Administrator stops Sonarr deployment to prevent conflicts
6. Administrator restores configuration files to PVC mount point (`/mnt/data/configs/sonarr`)
7. Administrator restarts Sonarr deployment
8. System loads restored configuration on startup
9. Administrator verifies Sonarr UI loads correctly
10. Administrator verifies API key still valid
11. Administrator verifies service integrations still configured
12. Administrator tests functionality by checking existing TV shows
13. System confirms all configuration restored successfully
14. Administrator documents recovery procedure for future reference

**Alternatives:**
- If backup is corrupted - administrator uses previous backup version
- If restore fails - administrator manually reconstructs critical configuration items
- If service won't start - administrator checks logs and fixes configuration issues

**Edge Cases:**
- Multiple services affected - restore procedures executed sequentially
- Backup from different cluster version - administrator migrates configuration format if needed
- Partial data loss - administrator restores only affected configuration sections

---

## UX Design Principles

Since this is an infrastructure project with minimal user-facing UI (mostly administrative interfaces), UX principles focus on operational efficiency:

**Principle 1: Visibility Over Complexity**
- System health and status should be immediately visible without deep navigation
- Dashboards should present critical information at a glance
- Avoid burying important alerts or warnings in nested menus

**Principle 2: Consistency with Existing Patterns**
- Service UIs (Sonarr, Radarr, etc.) maintain their native interfaces
- Grafana dashboards follow standard Prometheus/Grafana conventions
- Kubernetes tools (ArgoCD, kubectl) use standard Kubernetes UI patterns

**Principle 3: Automation Over Manual Steps**
- Prefer automated configuration over manual UI interactions where possible
- Reduce cognitive load by automating routine operations
- Manual steps should be exception cases, not standard operations

**Principle 4: Fail-Safe Defaults**
- Configuration changes should be reversible
- Destructive operations should require explicit confirmation
- System should gracefully handle missing or invalid configuration

---

## User Interface Design Goals

**Admin Interface Goals:**

1. **Centralized Health View**
   - Single Grafana dashboard showing all service health statuses
   - Color-coded status indicators (green/yellow/red) for quick assessment
   - Drill-down capability to individual service details

2. **Alert Visibility**
   - Prominent alert display in Grafana
   - Clear alert severity levels
   - Actionable alert messages with remediation guidance

3. **Service Configuration Access**
   - Direct links to service UIs from dashboard
   - Pre-configured service URLs via homepage dashboard
   - Quick access to ArgoCD for infrastructure changes

4. **Operational Documentation**
   - Runbooks accessible from documentation
   - Inline help for configuration options
   - Clear error messages with troubleshooting links

**Note:** This infrastructure project primarily interfaces with existing service UIs (Sonarr, Radarr, Grafana, ArgoCD). The UX/UI work focuses on monitoring dashboards and operational tooling rather than custom user-facing applications.

---

## Epic List

- **Epic 1: Service Integration Foundation**  
  Configure API keys and establish inter-service communication between all Starr services, enabling automated content management workflows. (Estimated: 8-10 stories)

- **Epic 2: Observability and Monitoring**  
  Deploy and configure Prometheus metrics collection, Grafana dashboards, and alerting for complete system visibility and proactive issue detection. (Estimated: 6-8 stories)

- **Epic 3: Backup and Disaster Recovery**  
  Implement automated backup strategies for service configurations and establish tested recovery procedures for disaster scenarios. (Estimated: 5-7 stories)

- **Epic 4: Production Hardening and Documentation**  
  Complete security hardening, optimize VPN integration, finalize GitOps automation, and document operational runbooks for long-term maintainability. (Estimated: 6-8 stories)

> **Note:** Detailed epic breakdown with full story specifications is available in [epics.md](./epics.md)

---

## Out of Scope

**Feature Additions:**
- Adding new media services beyond the current Starr stack
- Implementing custom media management applications
- Building user-facing web interfaces or mobile apps
- Developing content recommendation algorithms

**Infrastructure Enhancements:**
- Multi-cluster or multi-region deployment for high availability
- Advanced service mesh features beyond basic Istio (if deployed)
- Automated horizontal pod autoscaling
- Custom resource controllers or operators

**Advanced Monitoring:**
- Application Performance Monitoring (APM) tools
- Log aggregation systems (ELK, Loki)
- Custom metrics beyond standard Kubernetes/Prometheus
- Distributed tracing

**Security Enhancements:**
- Multi-factor authentication for service access
- Advanced network policies and micro-segmentation
- Security scanning and vulnerability management automation
- Compliance certification (SOC 2, ISO 27001, etc.)

**External Integrations:**
- Third-party backup services (AWS S3, Google Cloud Storage)
- External monitoring services (Datadog, New Relic)
- CI/CD pipeline enhancements beyond GitOps
- ChatOps integrations (Slack, Discord)

**Future Considerations (Post-MVP):**
- Content delivery network (CDN) integration
- Multi-user access with RBAC
- Advanced analytics and content consumption insights
- Smart home automation integration
- Mobile application development
