### Monitoring & Alerting Proposal v1

#### Goal
Add self-hosted monitoring, alerting, and AI-assisted log triage to the k3s media cluster, with:
- Centralized logs and metrics
- Push notifications to phone for important issues
- A learning "issues list" so you can suppress noisy alerts
- Minimal additional operational complexity and reasonable resource overhead

#### Phase 1 – Core Monitoring Stack

**Objectives**
- Central place to see service logs
- Basic cluster and service metrics (CPU, memory, disk, uptime)
- Foundation for future alerting and AI triage

**Components**
- **Loki + Promtail**
  - Promtail as a DaemonSet, tails container logs from all namespaces
  - Loki as centralized log store (single small instance)
  - Labels: `namespace`, `pod`, `container`, `app`, `job`, etc.
- **Prometheus + exporters**
  - Prometheus server (single instance)
  - `node-exporter` for node CPU/RAM/disk
  - `kube-state-metrics` for pod/deployment/job status
- **Grafana**
  - Dashboards for cluster utilization and per-service views
  - Log panels via Loki data source

**Rough resource impact (tunable)**
- Prometheus: ~200–300m CPU, 1–2 GiB RAM, 5–20 GiB disk
- Loki: ~200–300m CPU, 0.5–1 GiB RAM, 20–100 GiB disk (log retention-dependent)
- Promtail (per node): ~20–50m CPU, 50–100 MiB RAM
- Grafana: ~50–100m CPU, 200–400 MiB RAM

#### Phase 2 – Basic Alerting to Phone

**Objectives**
- Get notified when things are clearly broken:
  - CrashLoopBackOff / pod not ready
  - Failed CronJobs (e.g., scraper)
  - Important services down (Jellyfin, qBittorrent, etc.)
  - High CPU/memory/disk on the node

**Components**
- **Alertmanager**
  - Receives alerts from Prometheus rules
  - Routes alerts to a push service
- **Push service**
  - Option A: **Gotify** (self-hosted, simple app on phone)
  - Option B: **Pushover** (SaaS, very reliable)

**Example alert rules**
- `PodCrashLooping > N times in 10m` for key namespaces (media, qbittorrent)
- `JobFailed` for CronJobs like `qbittorrent-scraper`
- `NodeCPU > 90% for 5m` or `NodeMemory > 90% for 5m`
- `HTTP probe to Jellyfin/qbit fails for 2+ minutes`

At this stage, alerts are still "dumb" (rule-based), but provide basic coverage.

#### Phase 3 – AI Triage & Learning Issues List

**Objectives**
- Reduce alert noise
- Let a local AI model classify and summarize issues
- Allow you to mark certain patterns as "not concerning" so they are suppressed in future

**Components**
- **Local model host** (in-cluster)
  - e.g., `ollama` or similar, running a small model (Llama 3 3B/8B or equivalent)
  - Used for classification and short summaries, not heavy LLM workloads
- **AI triage service** (small Python/Go service)
  - Input: alerts from Alertmanager via webhook (and optionally targeted Loki queries)
  - Tasks:
    - Classify severity/type (network, VPN, storage, media, noisy, etc.)
    - Optionally enrich with a short explanation and suggested next step
    - Check a local **suppression DB** before sending notifications
  - Output: sends filtered/summarized alerts to Gotify/Pushover
- **Suppression database**
  - Simple table (SQLite/Postgres) with:
    - `pattern_id` or hash of alert/log pattern
    - `decision` (e.g., `ignore`, `important`)
    - metadata (`first_seen`, `last_seen`, `notes`)
  - When you click "not concerning" for an alert, that pattern is recorded as `ignore`
  - Future alerts matching that pattern are silently dropped or down-prioritized

**Resource impact (AI layer)**
- Model server: ~1–2 CPU cores burst, 2–6 GiB RAM (tunable by model choice)
- Triage API: ~20m CPU, 100–200 MiB RAM

#### Phase 4 – Cluster Health & Capacity Planning

**Objectives**
- Quickly answer: "Am I overloading the node? Do I need more hardware?"
- Visualize historical trends for CPU, memory, disk, and key services

**Implementation**
- Grafana dashboards powered by Prometheus:
  - Node CPU/RAM utilization over time
  - Disk usage for key volumes (e.g., `/mnt/data`)
  - Per-namespace and per-deployment resource usage
  - Uptime graphs for Jellyfin, qBittorrent, Sabnzbd, Sonarr/Radarr, etc.
- Optional alerts when:
  - Node CPU or memory is persistently high (e.g., >80% for hours)
  - Disk usage crosses thresholds (80%, 90%)

#### Design Principles / Constraints

- **GitOps-first**: All monitoring components defined declaratively in this repo, deployed via ArgoCD
- **Self-hosted by default**: Loki, Prometheus, Grafana, Alertmanager, Gotify, AI service, model all run in k3s
- **Graceful degradation**: If k3s dies, you lose alerts (accepted trade-off); optional external uptime monitor can be added later
- **Start simple**:
  - Phase 1–2 can run without any AI
  - Phase 3 (AI triage) is an incremental add-on
- **Resource caps**: All monitoring and AI components configured with conservative resource requests/limits so they cannot starve Jellyfin/qBittorrent

#### Next Steps (when we pick this up again)

1. Choose push mechanism (Gotify vs Pushover) and define Alertmanager routes.
2. Define minimal Prometheus rules for:
   - Failed CronJobs
   - CrashLoopBackOff
   - Node resource thresholds
   - HTTP probes for key services
3. Sketch the AI triage API contract (JSON payload from Alertmanager, suppression keys, response schema).
4. Decide on model size and resource limits for the AI pod.
