# Monitoring Stack - Server (Backend)

**Grafana-based observability platform for collecting, storing, and visualizing telemetry data.**

This is the **server-side** monitoring stack that receives, stores, and visualizes observability data from your applications. It implements the three pillars of observability: Metrics, Logs, and Traces.

---

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Ports available: 3002, 4317, 4318, 9090, 12345

### Start the Stack

**Basic monitoring stack:**
```bash
cd server
docker-compose up -d
```

**With host monitoring (CPU, memory, disk, containers):**
```bash
# Linux/macOS
cd server
./setup/start-host-monitoring.sh

# Windows
cd server
setup\start-host-monitoring.bat

# Or manually
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml up -d
```

### Access the UIs

- **Grafana**: http://localhost:3002 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Alloy**: http://localhost:12345
- **Pyroscope**: http://localhost:4040

### Configure Alerts (Optional)

Set up Slack notifications:
```bash
# Linux/macOS
./setup/setup-slack-alerts.sh

# Windows
setup\setup-slack-alerts.bat
```

---

## Stack Components

### Core Services

| Service | Purpose | Port | UI/API |
|---------|---------|------|--------|
| **Grafana Alloy** | OpenTelemetry collector & data pipeline | 4317, 4318, 12345 | http://localhost:12345 |
| **Prometheus** | Time-series metrics storage | 9090 | http://localhost:9090 |
| **Loki** | Log aggregation system | 3100 | (Query via Grafana) |
| **Tempo** | Distributed tracing backend | 3200 | (Query via Grafana) |
| **Grafana** | Visualization & dashboards | 3002 | http://localhost:3002 |
| **Pyroscope** | Continuous profiling | 4040 | http://localhost:4040 |

### Host Monitoring (Optional)

| Service | Purpose | Port |
|---------|---------|------|
| **Node Exporter** | Host system metrics (CPU, memory, disk) | 9100 |
| **Promtail** | Host log collection | 9080 |
| **cAdvisor** | Container resource monitoring | 8080 |

---

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

**For Slack alerts**, add your webhook URLs:
```env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/YOUR/CRITICAL/WEBHOOK/URL
```

### Component Configurations

All service configurations are in the `stack/` directory:

```
stack/
├── alloy/config.alloy              # OTLP receiver & routing
├── prometheus/prometheus.yml        # Metrics collection
├── loki/loki-config.yaml           # Log aggregation
├── tempo/tempo.yaml                # Trace storage
├── promtail/promtail-config.yaml   # Host log collection
└── grafana/
    ├── provisioning/
    │   ├── datasources/            # Auto-configured data sources
    │   └── alerting/               # Alert rules & Slack config
    └── dashboards/                 # Pre-built dashboards
```

---

## Data Flow

```
Applications (Client)
    ↓ OTLP (port 4317/4318)
Grafana Alloy
    ├→ Metrics  → Prometheus
    ├→ Logs     → Loki
    ├→ Traces   → Tempo
    └→ Profiles → Pyroscope
         ↓
    Grafana (Visualization)
```

**How to send data:** Configure your applications using the examples in `../client/`

---

## Common Operations

### View Logs
```bash
docker-compose logs -f <service-name>

# All services
docker-compose logs -f

# With host monitoring
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml logs -f
```

### Stop the Stack
```bash
docker-compose down

# With host monitoring
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml down
```

### Restart a Service
```bash
docker-compose restart <service-name>
```

### Validate Configuration
```bash
./scripts/validate-config.sh
```

---

## Pre-configured Dashboards

Access via Grafana (http://localhost:3002):

1. **Spring Boot Dashboard** - JVM metrics, request rates, error rates
2. **Host Monitoring Dashboard** - CPU, memory, disk, network, containers (requires host monitoring stack)

---

## Alert Rules (Requires Slack Setup)

6 pre-configured alert rules monitor:
- High error rates (5xx responses)
- Application errors in logs
- High request latency
- JVM memory pressure
- High CPU usage
- Disk space warnings

**Configure in:** `stack/grafana/provisioning/alerting/`

---

## Troubleshooting

### Ports Already in Use
If ports conflict, modify the port mappings in `docker-compose.yml`:
```yaml
ports:
  - "NEW_PORT:CONTAINER_PORT"
```

### No Data Appearing
1. Check applications are sending to Alloy: http://localhost:12345
2. Verify Prometheus targets: http://localhost:9090/targets
3. Check service logs: `docker-compose logs -f alloy prometheus loki tempo`

### Grafana Dashboards Empty
- Wait 1-2 minutes for data collection
- Verify data sources in Grafana → Configuration → Data Sources
- Check Prometheus has metrics: http://localhost:9090/graph

---

## Performance Tuning

### Retention Policies
- **Prometheus**: 7 days (configurable in `stack/prometheus/prometheus.yml`)
- **Loki**: 7 days (configurable in `stack/loki/loki-config.yaml`)
- **Tempo**: 48 hours (configurable in `stack/tempo/tempo.yaml`)

### Resource Limits
Set in `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '2.0'
```

---

## Architecture

### Three Pillars of Observability
1. **Metrics** (Prometheus) - Quantitative measurements over time
2. **Logs** (Loki) - Discrete event records
3. **Traces** (Tempo) - Request flow through distributed systems

### Data Correlation
All telemetry is correlated using trace IDs for seamless navigation between metrics, logs, and traces.

---

## Documentation

- **Quick Setup Guides**: `../quick-start/`
- **Detailed Guides**: `../docs/`
- **Client Configuration**: `../client/README.md`

---

## Support

For issues or questions:
- Check `../docs/` for comprehensive guides
- Review logs: `docker-compose logs -f`
- Validate config: `./scripts/validate-config.sh`

---

## Technology Stack

- **Container Runtime**: Docker Compose
- **Telemetry Protocol**: OpenTelemetry (OTLP)
- **Metrics**: Prometheus
- **Logs**: Loki (LogQL)
- **Traces**: Tempo (TraceQL)
- **Visualization**: Grafana
- **Profiling**: Pyroscope

## ✅ Telemetry Invariant Check

`scripts/check-telemetry-invariants.sh` asserts that the HRMS telemetry pipeline is
healthy and exits non-zero when it is not. It is the detector for every defect class
found on 2026-09-13 — each invariant below corresponds to a defect that was actually
observed, and that nothing would have caught.

Run it **after any deploy** and **after any monitoring config change**. A check nobody
runs is worse than no check, because it produces false confidence.

```bash
./scripts/check-telemetry-invariants.sh uat        # one environment
./scripts/check-telemetry-invariants.sh            # all four (default)
PROM_URL=http://host:9090 LOKI_URL=http://host:3100 ./scripts/check-telemetry-invariants.sh uat
```

What it checks (each prints one `OK`/`FAIL` line; a `FAIL` always shows the observed value):

1. Exactly one `target_info` series per environment.
2. No `container_id` / `process_*` / `os_*` / `telemetry_distro_*` labels on HRMS series.
3. Metric families present (`hikaricp_connections_*`, `executor_*`, `jvm_*`, `http_server_*`).
   Presence only, never values — UAT is genuinely idle, so a value assertion would fail forever.
4. Exactly one Hikari series per pool per environment.
5. The legacy Loki `hrms/*` stream is not growing, i.e. one stored line per emitted line.
   Note: on a fully idle environment this passes vacuously — nothing is emitted, so nothing
   can grow. Trust this check on an environment with live traffic.
6. Each environment reports separately under its own job.
7. Sample cadence roughly matches the configured export interval. `WARN`-only — it never
   fails the run, because a flaky check erodes trust faster than a missing one.

Needs only POSIX `sh`, `curl`, `grep` and `sed`. There is no `jq` on this host, and the
script deliberately does not require one.
