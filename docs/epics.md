# k8s_nas - Epic Breakdown

**Author:** Brett  
**Date:** 2025-11-01  
**Project Level:** 3  
**Target Scale:** Production media server infrastructure

---

## Overview

This document provides the detailed epic breakdown for k8s_nas production readiness enhancement, expanding on the high-level epic list in the [PRD](./PRD.md).

Each epic includes:

- Expanded goal and value proposition
- Complete story breakdown with user stories
- Acceptance criteria for each story
- Story sequencing and dependencies

**Epic Sequencing Principles:**

- Epic 1 establishes foundational infrastructure and initial functionality
- Subsequent epics build progressively, each delivering significant end-to-end value
- Stories within epics are vertically sliced and sequentially ordered
- No forward dependencies - each story builds only on previous work

---

## Epic 1: Service Integration Foundation

### Expanded Goal

Establish complete inter-service communication between all Starr media management services, enabling automated content discovery, download, and management workflows. This epic transforms isolated services into an integrated media management ecosystem where Sonarr and Radarr can automatically discover content via Prowlarr, download via qBittorrent through VPN, and manage requests through Jellyseerr.

**Value Delivery:** Enables fully automated media acquisition and management, eliminating manual content discovery and download initiation. Users can request content through Jellyseerr and have it automatically acquired, downloaded, and made available in Jellyfin without manual intervention.

**Builds On:** Existing service deployments and infrastructure foundation established in the initial migration.

### Story Breakdown

**Story 1.1: Extract and Configure API Keys for Starr Services**

As a system administrator,
I want to extract API keys from existing service configurations and configure them in Kubernetes,
So that services can communicate with each other securely.

**Acceptance Criteria:**
1. API keys extracted from existing Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, and Jellyseerr configurations
2. API keys stored in Kubernetes Secrets in the `media` namespace
3. API keys referenced in service ConfigMaps or environment variables
4. Services can authenticate using configured API keys
5. API key configuration verified via service API calls

**Prerequisites:** None (foundational story)

---

**Story 1.2: Configure Sonarr-Prowlarr Integration**

As a system administrator,
I want to configure Sonarr to use Prowlarr as its indexer manager,
So that TV show searches automatically use all configured indexers from Prowlarr.

**Acceptance Criteria:**
1. Sonarr configured to connect to Prowlarr via Kubernetes Service DNS (`prowlarr.media.svc.cluster.local:9696`)
2. Sonarr API key configured in Prowlarr application settings
3. Prowlarr automatically syncs indexers to Sonarr
4. Sonarr can successfully search for TV shows using Prowlarr indexers
5. Indexer synchronization verified via Sonarr UI and test searches

**Prerequisites:** Story 1.1 (API keys configured)

---

**Story 1.3: Configure Radarr-Prowlarr Integration**

As a system administrator,
I want to configure Radarr to use Prowlarr as its indexer manager,
So that movie searches automatically use all configured indexers from Prowlarr.

**Acceptance Criteria:**
1. Radarr configured to connect to Prowlarr via Kubernetes Service DNS
2. Radarr API key configured in Prowlarr application settings
3. Prowlarr automatically syncs indexers to Radarr
4. Radarr can successfully search for movies using Prowlarr indexers
5. Indexer synchronization verified via Radarr UI and test searches

**Prerequisites:** Story 1.1 (API keys configured), Story 1.2 (Prowlarr-Sonarr integration pattern established)

---

**Story 1.4: Configure Sonarr-qBittorrent Integration**

As a system administrator,
I want to configure Sonarr to use qBittorrent as its download client through VPN,
So that TV show downloads are automatically managed and routed through secure VPN connection.

**Acceptance Criteria:**
1. Sonarr configured to connect to qBittorrent via Kubernetes Service DNS (`qbittorrent.qbittorrent.svc.cluster.local:8080`)
2. qBittorrent credentials configured in Sonarr download client settings
3. Sonarr can successfully add torrents to qBittorrent
4. Downloads complete through VPN and are accessible to Sonarr
5. Integration verified via test TV show download

**Prerequisites:** Story 1.1 (API keys configured)

---

**Story 1.5: Configure Radarr-qBittorrent Integration**

As a system administrator,
I want to configure Radarr to use qBittorrent as its download client through VPN,
So that movie downloads are automatically managed and routed through secure VPN connection.

**Acceptance Criteria:**
1. Radarr configured to connect to qBittorrent via Kubernetes Service DNS
2. qBittorrent credentials configured in Radarr download client settings
3. Radarr can successfully add torrents to qBittorrent
4. Downloads complete through VPN and are accessible to Radarr
5. Integration verified via test movie download

**Prerequisites:** Story 1.1 (API keys configured), Story 1.4 (Sonarr-qBittorrent integration pattern established)

---

**Story 1.6: Configure Media Root Folders**

As a system administrator,
I want to configure root folders for Sonarr and Radarr,
So that downloaded content is organized correctly in the media library.

**Acceptance Criteria:**
1. Sonarr root folder configured to `/data/media/tv`
2. Radarr root folder configured to `/data/media/movies`
3. Root folders exist and are accessible via PVC/hostPath mounts
4. Services have write permissions to root folder directories
5. Test content successfully moves to root folders after download completion

**Prerequisites:** Story 1.4, Story 1.5 (download client integrations)

---

**Story 1.7: Configure Jellyseerr Service Integration**

As a system administrator,
I want to configure Jellyseerr to connect to Sonarr, Radarr, and Jellyfin,
So that users can request content through Jellyseerr and have it automatically acquired.

**Acceptance Criteria:**
1. Jellyseerr configured to connect to Sonarr via service DNS and API key
2. Jellyseerr configured to connect to Radarr via service DNS and API key
3. Jellyseerr configured to connect to Jellyfin via service DNS and API key
4. Test content request successfully creates requests in Sonarr/Radarr
5. Request workflow verified end-to-end from Jellyseerr to content availability

**Prerequisites:** Story 1.1 (API keys), Story 1.2, Story 1.3 (indexer integrations), Story 1.4, Story 1.5 (download integrations)

---

**Story 1.8: Verify VPN Integration and Network Security**

As a system administrator,
I want to verify that qBittorrent downloads route through VPN and media services use standard networking,
So that download security is maintained while preserving service communication.

**Acceptance Criteria:**
1. qBittorrent connectivity verified through VPN service
2. Download test confirms traffic routes through VPN IP
3. Media services (Sonarr, Radarr, Jellyfin) use standard Kubernetes networking
4. Network isolation verified - download traffic isolated, media traffic standard
5. VPN connectivity documented with test results

**Prerequisites:** Story 1.4, Story 1.5 (qBittorrent integrations)

---

**Story 1.9: End-to-End Integration Testing**

As a system administrator,
I want to test the complete content acquisition workflow from request to availability,
So that I can verify all service integrations work together correctly.

**Acceptance Criteria:**
1. Test TV show request via Jellyseerr successfully triggers Sonarr search
2. Sonarr finds content via Prowlarr and initiates download via qBittorrent
3. Download completes through VPN and content moves to library
4. Content becomes available in Jellyfin
5. Complete workflow verified for both TV shows and movies

**Prerequisites:** All previous stories in Epic 1

---

## Epic 2: Observability and Monitoring

### Expanded Goal

Deploy comprehensive monitoring and alerting infrastructure to provide complete visibility into system health, service performance, and operational status. This epic establishes Prometheus metrics collection, Grafana visualization dashboards, and proactive alerting to transform operations from reactive problem-solving to proactive issue detection and resolution.

**Value Delivery:** Enables immediate awareness of system health issues, performance degradation, and resource constraints before they impact users. Reduces mean time to detection (MTTD) from hours/days to minutes, and provides data-driven insights for capacity planning and optimization.

**Builds On:** Service integration foundation from Epic 1, existing Prometheus and Grafana deployments.

### Story Breakdown

**Story 2.1: Configure Prometheus Service Discovery for Media Services**

As a system administrator,
I want Prometheus to automatically discover all media services for metrics collection,
So that I don't need to manually configure scrape targets for each service.

**Acceptance Criteria:**
1. Prometheus configured with Kubernetes service discovery for `media` namespace
2. All services automatically discovered and added to scrape targets
3. Service discovery filters correctly identify media services
4. Prometheus successfully scrapes metrics from all discovered services
5. Service discovery configuration documented and validated

**Prerequisites:** None (monitoring foundation)

---

**Story 2.2: Create Unified Service Health Dashboard in Grafana**

As a system administrator,
I want a single Grafana dashboard showing health status of all media services,
So that I can quickly assess overall system status at a glance.

**Acceptance Criteria:**
1. Grafana dashboard created with panels for each media service
2. Each panel shows service status (up/down) with color coding
3. Dashboard includes service response time metrics
4. Dashboard shows resource utilization (CPU, memory) per service
5. Dashboard loads within 3 seconds and updates in real-time

**Prerequisites:** Story 2.1 (Prometheus service discovery)

---

**Story 2.3: Implement Service Health Checks and Probes**

As a system administrator,
I want Kubernetes health checks configured for all services,
So that unhealthy services are automatically restarted and removed from service routing.

**Acceptance Criteria:**
1. Liveness probes configured for all media services
2. Readiness probes configured for all media services
3. Health check endpoints verified (e.g., `/ping`, `/health`)
4. Unhealthy pods automatically restarted by Kubernetes
5. Unready pods removed from service endpoints until healthy

**Prerequisites:** None (can run parallel with monitoring setup)

---

**Story 2.4: Configure Service Down Alerts**

As a system administrator,
I want to receive immediate alerts when any service becomes unavailable,
So that I can respond to issues before they impact users.

**Acceptance Criteria:**
1. Alert rules created for service down conditions
2. Alerts trigger when service health check fails
3. Alert notifications configured (email, webhook, or similar)
4. Alerts fire within 1 minute of service failure
5. Alert includes service name, namespace, and remediation guidance

**Prerequisites:** Story 2.1 (Prometheus scraping), Story 2.3 (health checks)

---

**Story 2.5: Configure Certificate Expiry Alerts**

As a system administrator,
I want to receive warnings when SSL certificates are approaching expiration,
So that I can renew certificates before they expire and cause service disruption.

**Acceptance Criteria:**
1. Alert rule created for certificate expiry monitoring
2. Alerts fire 30 days before certificate expiration
3. Alert includes certificate name, expiration date, and renewal instructions
4. Certificate status queryable via Prometheus metrics
5. Alert notifications configured and tested

**Prerequisites:** Story 2.1 (Prometheus configured)

---

**Story 2.6: Configure Resource Utilization Alerts**

As a system administrator,
I want to receive alerts when services approach resource limits,
So that I can scale resources or optimize usage before performance degradation.

**Acceptance Criteria:**
1. Alert rules created for CPU utilization thresholds (e.g., >80%)
2. Alert rules created for memory utilization thresholds (e.g., >85%)
3. Alerts include service name, current usage, and limit
4. Resource metrics visible in Grafana dashboard
5. Alert notifications configured and tested

**Prerequisites:** Story 2.1 (Prometheus scraping)

---

**Story 2.7: Create Service-Specific Grafana Dashboards**

As a system administrator,
I want detailed dashboards for each major service showing performance metrics,
So that I can diagnose service-specific issues and optimize performance.

**Acceptance Criteria:**
1. Individual Grafana dashboards created for Sonarr, Radarr, Jellyfin, qBittorrent
2. Each dashboard shows service-specific metrics (requests, downloads, library size, etc.)
3. Dashboards include historical trends and performance baselines
4. Dashboards accessible from unified health dashboard
5. Dashboard performance optimized for fast loading

**Prerequisites:** Story 2.2 (unified dashboard), Story 2.1 (metrics collection)

---

**Story 2.8: Validate Complete Monitoring Coverage**

As a system administrator,
I want to verify that all services have monitoring and alerting coverage,
So that no service can fail silently without detection.

**Acceptance Criteria:**
1. All 11 media services have Prometheus metrics collection
2. All services included in unified health dashboard
3. All critical services have down alerts configured
4. Alert delivery tested for all alert types
5. Monitoring coverage documented in runbook

**Prerequisites:** All previous stories in Epic 2

---

## Epic 3: Backup and Disaster Recovery

### Expanded Goal

Implement automated backup strategies for all service configurations and critical data, establishing tested recovery procedures that enable rapid restoration from any failure scenario. This epic transforms the system from a fragile state where configuration loss could require days of recovery work to a resilient infrastructure with confidence in data safety and quick recovery capabilities.

**Value Delivery:** Eliminates fear of data loss and configuration corruption. Enables rapid recovery from failures (target: <1 hour for single service, <4 hours for complete infrastructure). Provides peace of mind through proven, tested recovery procedures.

**Builds On:** Service integrations from Epic 1, monitoring from Epic 2 to detect backup failures.

### Story Breakdown

**Story 3.1: Design Backup Strategy and Retention Policy**

As a system administrator,
I want a defined backup strategy specifying what to backup, how often, and retention period,
So that I have a clear plan for protecting critical data.

**Acceptance Criteria:**
1. Backup scope defined (service configurations, PVC data, secrets)
2. Backup frequency determined (daily recommended)
3. Retention policy defined (e.g., 30 days daily, 12 months weekly)
4. Backup storage location identified
5. Backup strategy documented

**Prerequisites:** None (planning story)

---

**Story 3.2: Implement Automated Configuration Backup**

As a system administrator,
I want automated daily backups of all service configurations,
So that I never lose configuration changes even if storage fails.

**Acceptance Criteria:**
1. Backup job/schedule configured (CronJob or similar)
2. Backup script copies all ConfigMaps from `media` namespace
3. Backup script copies all Secrets from `media` namespace
4. Backup script copies PVC configuration manifests
5. Backups stored in designated location with timestamp
6. Backup job runs successfully daily

**Prerequisites:** Story 3.1 (backup strategy)

---

**Story 3.3: Implement PVC Data Backup**

As a system administrator,
I want to backup PersistentVolumeClaim data containing service configurations,
So that I can restore complete service state including all settings and metadata.

**Acceptance Criteria:**
1. Backup script identifies all PVCs in `media` namespace
2. Backup process mounts or copies PVC data to backup location
3. PVC backups include all service configuration directories
4. Backup preserves file permissions and ownership
5. Backup completes successfully for all services
6. Backup size and duration monitored and logged

**Prerequisites:** Story 3.2 (configuration backup), Story 3.1 (backup strategy)

---

**Story 3.4: Implement Backup Verification and Integrity Checks**

As a system administrator,
I want backup verification to ensure backups are valid and restorable,
So that I have confidence backups will work when needed.

**Acceptance Criteria:**
1. Backup verification script checks backup file integrity (checksums)
2. Verification confirms all expected files are present
3. Backup size and completeness validated
4. Verification failures trigger alerts
5. Backup verification results logged and monitored

**Prerequisites:** Story 3.2, Story 3.3 (backup implementation)

---

**Story 3.5: Create Service Restore Procedure Documentation**

As a system administrator,
I want documented step-by-step restore procedures for each service,
So that I can quickly recover from any failure scenario.

**Acceptance Criteria:**
1. Restore procedure documented for Sonarr
2. Restore procedure documented for Radarr
3. Restore procedure documented for Jellyfin
4. Restore procedure documented for qBittorrent
5. General restore procedure for other services documented
6. Procedures include prerequisites, steps, and verification

**Prerequisites:** Story 3.2, Story 3.3 (backup implementation understood)

---

**Story 3.6: Test and Validate Restore Procedures**

As a system administrator,
I want to test restore procedures in a non-production scenario,
So that I can verify recovery works correctly before needing it in production.

**Acceptance Criteria:**
1. Test restore of Sonarr configuration from backup
2. Test restore of Radarr configuration from backup
3. Test restore of complete service (config + PVC data)
4. Restored services verified to work correctly
5. Restore time measured and documented (target: <1 hour per service)
6. Restore procedures updated based on test learnings

**Prerequisites:** Story 3.5 (procedures documented), Story 3.4 (backup verification)

---

**Story 3.7: Implement Backup Monitoring and Alerts**

As a system administrator,
I want alerts when backups fail or are incomplete,
So that I can fix backup issues before they become critical.

**Acceptance Criteria:**
1. Backup job success/failure monitored via Prometheus or Kubernetes events
2. Alert configured for backup job failures
3. Alert configured for backup verification failures
4. Backup status visible in Grafana dashboard
5. Alert notifications tested and verified

**Prerequisites:** Story 3.4 (backup verification), Epic 2 (monitoring infrastructure)

---

**Story 3.8: Document Disaster Recovery Runbook**

As a system administrator,
I want a complete disaster recovery runbook covering all failure scenarios,
So that I can recover from any disaster efficiently and confidently.

**Acceptance Criteria:**
1. Disaster recovery runbook created covering single service failure
2. Runbook covers complete infrastructure failure scenario
3. Runbook includes recovery time objectives (RTO) for each scenario
4. Runbook includes prerequisites, tools needed, and step-by-step procedures
5. Runbook tested and validated through dry-run exercises

**Prerequisites:** Story 3.6 (restore procedures tested), Story 3.7 (backup monitoring)

---

## Epic 4: Production Hardening and Documentation

### Expanded Goal

Complete the transformation to production-ready infrastructure by finalizing security hardening, optimizing operational procedures, completing GitOps automation, and documenting all operational knowledge in runbooks. This epic ensures the system is not just functional but maintainable, secure, and reliable for long-term operation.

**Value Delivery:** Establishes operational excellence through automation, documentation, and security best practices. Reduces ongoing maintenance burden, ensures knowledge is preserved, and provides confidence in long-term system reliability and security.

**Builds On:** All previous epics - integrations, monitoring, and backups provide the foundation for hardening.

### Story Breakdown

**Story 4.1: Complete GitOps Automation Verification**

As a system administrator,
I want to verify that all infrastructure changes are managed through GitOps,
So that I can eliminate manual kubectl operations and ensure all changes are version-controlled.

**Acceptance Criteria:**
1. Audit identifies any remaining manual infrastructure changes
2. All manual changes migrated to GitOps (ArgoCD ApplicationSets)
3. No direct kubectl apply operations needed for production changes
4. All changes committed to Git repository
5. ArgoCD successfully syncs all applications automatically
6. GitOps workflow documented

**Prerequisites:** Epic 1 (services configured), Epic 2 (monitoring configured)

---

**Story 4.2: Implement Certificate Renewal Monitoring**

As a system administrator,
I want automated monitoring of SSL certificate renewal status,
So that certificates are renewed before expiration without manual intervention.

**Acceptance Criteria:**
1. cert-manager certificate status monitored via Prometheus
2. Certificate expiry alerts configured (30 days before expiration)
3. Certificate renewal process verified and documented
4. Certificate status visible in Grafana dashboard
5. Automated renewal tested and validated

**Prerequisites:** Epic 2 (monitoring infrastructure), Story 2.5 (certificate alerts)

---

**Story 4.3: Verify and Document VPN Security**

As a system administrator,
I want to verify VPN integration security and document the network architecture,
So that I understand and can maintain secure download isolation.

**Acceptance Criteria:**
1. VPN connectivity verified for qBittorrent downloads
2. Network isolation confirmed (download traffic only through VPN)
3. Media services verified to use standard Kubernetes networking
4. VPN security architecture documented
5. VPN troubleshooting procedures documented

**Prerequisites:** Epic 1 (VPN integration from Story 1.8)

---

**Story 4.4: Create Operational Runbooks**

As a system administrator,
I want documented runbooks for common operational tasks,
So that I can perform routine operations efficiently and consistently.

**Acceptance Criteria:**
1. Runbook created for service configuration changes
2. Runbook created for troubleshooting service issues
3. Runbook created for scaling services
4. Runbook created for certificate management
5. Runbook created for backup and restore operations
6. Runbooks include prerequisites, steps, and verification procedures

**Prerequisites:** Epic 1, Epic 2, Epic 3 (operational experience gained)

---

**Story 4.5: Document Service Dependencies and Architecture**

As a system administrator,
I want complete architecture documentation showing service dependencies and data flow,
So that I understand how the system works and can make informed changes.

**Acceptance Criteria:**
1. Service dependency diagram created
2. Data flow documented (request → discovery → download → library)
3. Network architecture documented
4. Integration points documented with API details
5. Architecture documentation updated to reflect current state

**Prerequisites:** Epic 1 (integrations complete), existing architecture docs

---

**Story 4.6: Implement Self-Healing Deployment Patterns**

As a system administrator,
I want self-healing capabilities where common failures are automatically recovered,
So that the system maintains availability with minimal manual intervention.

**Acceptance Criteria:**
1. Pod restart policies configured for automatic recovery
2. Health check failures trigger automatic pod restarts
3. ArgoCD self-healing enabled for all applications
4. Common failure scenarios tested for automatic recovery
5. Self-healing behavior documented

**Prerequisites:** Epic 1 (services deployed), Epic 2 (health checks), Story 4.1 (GitOps)

---

**Story 4.7: Security Hardening Review and Implementation**

As a system administrator,
I want security best practices applied to all services,
So that the infrastructure meets production security standards.

**Acceptance Criteria:**
1. Security review completed for all services
2. HTTPS-only access verified for all services
3. Network policies evaluated and implemented if needed
4. Secrets management reviewed and secured
5. Security hardening documented

**Prerequisites:** Story 4.3 (VPN security), Epic 1 (service configuration)

---

**Story 4.8: Production Readiness Validation**

As a system administrator,
I want to validate that the infrastructure meets all production-readiness criteria,
So that I have confidence the system is ready for long-term production use.

**Acceptance Criteria:**
1. All services integrated and tested (Epic 1 complete)
2. Monitoring and alerting operational (Epic 2 complete)
3. Backups automated and tested (Epic 3 complete)
4. Documentation complete and reviewed (Epic 4 stories)
5. Production readiness checklist completed
6. System validated against all MVP success criteria from PRD

**Prerequisites:** All previous epics and stories

---

## Story Guidelines Reference

**Story Format:**

```
**Story [EPIC.N]: [Story Title]**

As a [user type],
I want [goal/desire],
So that [benefit/value].

**Acceptance Criteria:**
1. [Specific testable criterion]
2. [Another specific criterion]
3. [etc.]

**Prerequisites:** [Dependencies on previous stories, if any]
```

**Story Requirements:**

- **Vertical slices** - Complete, testable functionality delivery
- **Sequential ordering** - Logical progression within epic
- **No forward dependencies** - Only depend on previous work
- **AI-agent sized** - Completable in 2-4 hour focused session
- **Value-focused** - Integrate technical enablers into value-delivering stories

---

**For implementation:** Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown.

