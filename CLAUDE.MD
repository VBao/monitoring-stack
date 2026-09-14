# CLAUDE.MD - Monitoring Stack Project

## Project Overview

This is a comprehensive **Grafana-based monitoring stack** for observability, implementing the three pillars: **Metrics**, **Logs**, and **Traces**. The stack uses OpenTelemetry standards for data collection and provides a unified platform for correlation and analysis.

**Architecture:** The project is split into independent **client** and **server** components with no root entry point. Users manually navigate to the directory they need.

## Directory Structure

```
monitoring/
├── 📁 server/                       # Monitoring backend (deploy here)
│   ├── docker-compose.yml           # Main monitoring stack
│   ├── docker-compose.host-monitoring.yml  # Host monitoring add-on
│   ├── .env.example                 # Environment variables template
│   ├── .env.slack-only              # Slack-only config
│   ├── README.md                    # Server documentation
│   │
│   ├── stack/                       # Component configurations
│   │   ├── alloy/config.alloy       # OTLP receiver & router
│   │   ├── prometheus/prometheus.yml # Metrics collection
│   │   ├── loki/loki-config.yaml    # Log aggregation
│   │   ├── tempo/tempo.yaml         # Trace storage
│   │   ├── promtail/promtail-config.yaml  # Host log collector
│   │   └── grafana/                 # Grafana configs
│   │       ├── provisioning/
│   │       │   ├── datasources/     # Auto-configured sources
│   │       │   └── alerting/        # Alert rules & Slack
│   │       └── dashboards/          # Pre-built dashboards
│   │
│   ├── setup/                       # Setup scripts
│   │   ├── setup-slack-alerts.sh    # Slack setup (Linux/macOS)
│   │   ├── setup-slack-alerts.bat   # Slack setup (Windows)
│   │   ├── start-host-monitoring.sh # Start with host monitoring
│   │   └── start-host-monitoring.bat
│   │
│   └── scripts/                     # Utility scripts
│       ├── validate-config.sh
│       └── validate-host-monitoring.sh
│
├── 📁 client/                       # Application configs (send data)
│   ├── java-spring-boot-otlp.yml    # Spring Boot example
│   ├── generic-env-vars.sh          # Universal env vars
│   └── README.md                    # Client instrumentation guide
│
├── 📁 docs/                         # Comprehensive documentation
│   ├── slack-integration-guide.md
│   ├── host-monitoring-guide.md
│   ├── alloy-config-guide.md
│   ├── loki-config-guide.md
│   ├── prometheus-config-guide.md
│   └── tempo-config-guide.md
│
├── 📁 quick-start/                  # Quick guides (5 minutes each)
│   ├── SLACK-ALERTS-README.md
│   ├── HOST-MONITORING-README.md
│   └── COMMANDS-CHEATSHEET.md
│
├── 📄 Core Documentation
│   ├── README.md                    # Navigation & architecture overview
│   ├── INDEX.md                     # Complete file index
│   ├── QUICK-REFERENCE.md           # One-page quick reference
│   ├── STRUCTURE.md                 # Directory organization guide
│   ├── CHANGELOG.md                 # Version history
│   └── CLAUDE.MD                    # This file - AI assistant context
│
└── 📁 configs/                      # OLD - for backwards compatibility
    ├── client-side/                 # Copied to ../client/
    └── server-side/                 # Configs for server/ alerting
```

## Architecture

### Client/Server Separation

**No root entry point** - Users choose which component to deploy:

1. **Server (Backend)**: Receives, stores, and visualizes telemetry
   - Location: `server/`
   - Entry point: `cd server && docker-compose up -d`
   - All server configs in `server/stack/`

2. **Client (Frontend)**: Applications send telemetry to server
   - Location: `client/`
   - Configuration examples for Java, Python, Node.js, Go, .NET
   - No deployment needed - just configuration

### Stack Components (Server)

- **Grafana Alloy** (v1.9.0-rc.1) - OpenTelemetry collector and telemetry data pipeline
- **Prometheus** (v3.3.0) - Time-series metrics collection and storage
- **Grafana Loki** - Log aggregation and storage system
- **Grafana Tempo** (v2.7.2) - Distributed tracing backend
- **Grafana** (v12.0.1) - Visualization, dashboards, and alerting UI
- **Pyroscope** (v1.9.0) - Continuous profiling platform

### Optional Host Monitoring (Server)
- **Node Exporter** (v1.8.2) - Host system metrics (CPU, memory, disk, network)
- **Promtail** (v3.5.0) - Host log collection and forwarding to Loki
- **cAdvisor** (v0.49.1) - Container resource usage monitoring

### Data Flow
```
Applications (Client)
    ↓ OTLP (4317/4318)
Grafana Alloy (Server)
    ├→ Metrics  → Prometheus
    ├→ Logs     → Loki
    ├→ Traces   → Tempo
    └→ Profiles → Pyroscope
         ↓
    Grafana (Visualization)
```

## Key Files

### Server Entry Points
- `server/docker-compose.yml` - Main monitoring stack
- `server/docker-compose.host-monitoring.yml` - Host monitoring overlay
- `server/README.md` - Complete server documentation

### Server Configuration
- `server/stack/alloy/config.alloy` - OTLP receiver and routing
- `server/stack/prometheus/prometheus.yml` - Metrics collection
- `server/stack/loki/loki-config.yaml` - Log storage
- `server/stack/tempo/tempo.yaml` - Trace storage
- `server/stack/grafana/provisioning/` - Auto-provisioned configs

### Client Configuration
- `client/java-spring-boot-otlp.yml` - Spring Boot OTLP config
- `client/generic-env-vars.sh` - Universal environment variables
- `client/README.md` - Instrumentation guide for all languages

### Key Ports (Server)
- 3002: Grafana UI
- 9090: Prometheus UI
- 4317: OTLP gRPC receiver (Alloy)
- 4318: OTLP HTTP receiver (Alloy)
- 12345: Alloy UI
- 3100: Loki API
- 3200: Tempo API
- 4040: Pyroscope UI
- 9100: Node Exporter (host metrics)
- 9080: Promtail (log collector)
- 8080: cAdvisor (container metrics)

## Common Tasks

### Deploy Server

**Main stack only**:
```bash
cd server
docker-compose up -d
```

**With host monitoring**:
```bash
cd server
./setup/start-host-monitoring.sh  # Linux/macOS
setup\start-host-monitoring.bat   # Windows

# Or manually
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml up -d
```

### Configure Client

**Java Spring Boot**:
```bash
cd client
cp java-spring-boot-otlp.yml /path/to/app/src/main/resources/application-monitoring.yml
```

**Any language (environment variables)**:
```bash
cd client
source generic-env-vars.sh
./your-application
```

### View Logs
```bash
cd server
docker-compose logs -f <service-name>

# All services
docker-compose logs -f

# With host monitoring
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml logs -f
```

### Validate Configuration
```bash
cd server
./scripts/validate-config.sh
```

### Access UIs (Server Running)
- Grafana: http://localhost:3002 (admin/admin)
- Prometheus: http://localhost:9090
- Alloy: http://localhost:12345
- Pyroscope: http://localhost:4040
- Node Exporter: http://localhost:9100
- cAdvisor: http://localhost:8080
- Promtail: http://localhost:9080

## Recent Changes

### Version 2.1 - Client/Server Separation (2026-02-05)

**Major Refactoring:**
- Split into independent `server/` and `client/` directories
- No root entry point - users manually cd to desired directory
- Server contains complete monitoring stack
- Client contains application configuration examples

**Server Directory:**
- All Docker Compose files moved to `server/`
- All component configs in `server/stack/`
- Setup scripts in `server/setup/`
- Validation scripts in `server/scripts/`
- Self-contained with own README.md

**Client Directory:**
- Client-side configs moved to `client/`
- Examples for Java, Python, Node.js, Go, .NET
- Clear separation: client SENDS, server RECEIVES
- Self-contained with own README.md

**Documentation:**
- Root README.md is navigation only
- `server/README.md` covers backend deployment
- `client/README.md` covers application instrumentation
- Existing detailed guides remain in `docs/`

### Version 2.0 - Major Reorganization (2026-01-30)

**Stack Component Organization:**
- All monitoring component configs in `stack/` directory
- Reduced root directory clutter
- Components: grafana, prometheus, loki, tempo, alloy, promtail, otel-collector

**Configuration Separation:**
- Client-side configs in `configs/client-side/` (now `client/`)
- Server-side configs in `configs/server-side/`

**New Features:**
- Slack alerting with 6 pre-configured alert rules
- Host monitoring with Node Exporter, Promtail, cAdvisor
- Copy-paste ready configurations
- Interactive setup scripts

## Architecture Patterns

### Three Pillars of Observability
1. **Metrics** (Prometheus) - Quantitative measurements over time
2. **Logs** (Loki) - Discrete event records
3. **Traces** (Tempo) - Request flow through distributed systems

### Data Correlation
All telemetry is correlated using trace IDs, allowing seamless navigation between:
- Metrics showing anomalies
- Logs providing context
- Traces revealing causation

## Technology Stack

- **Container Runtime**: Docker Compose
- **Telemetry Protocol**: OpenTelemetry (OTLP)
- **Metrics**: Prometheus (PromQL)
- **Logs**: Loki (LogQL)
- **Traces**: Tempo (TraceQL)
- **Visualization**: Grafana
- **Profiling**: Pyroscope

## Git Information

- **Current Branch**: main
- **Remote**: Standard Git repository
- **Recent Focus**: Client/server separation, documentation improvements

## Notes for Claude

### Project Organization
- **NO ROOT ENTRY POINT** - Users must `cd server` or `cd client` manually
- **server/** directory is self-contained - complete monitoring backend
- **client/** directory is self-contained - application config examples
- **docs/** directory has comprehensive documentation
- **quick-start/** directory has 5-minute setup guides
- Use **INDEX.md** to find any file quickly
- Use **QUICK-REFERENCE.md** for one-page command reference

### Path References
- **Server paths**: All relative to `server/` directory
  - Docker Compose: `cd server && docker-compose up -d`
  - Configs: `server/stack/<component>/`
  - Scripts: `server/scripts/` and `server/setup/`

- **Client paths**: All relative to `client/` directory
  - Spring Boot config: `client/java-spring-boot-otlp.yml`
  - Env vars: `client/generic-env-vars.sh`

### Technical Details
- Server is production-ready monitoring stack with comprehensive documentation
- Client provides configuration examples for multiple languages
- Configuration changes should be validated using `server/scripts/validate-config.sh`
- All services use Docker Compose for orchestration (in `server/`)
- The stack follows OpenTelemetry standards for interoperability
- Retention policies: 7d for Prometheus, 7d for Loki, 48h for Tempo
- Services communicate over shared `monitoring` Docker network

### Alerting & Monitoring
- Slack alerting configured via Grafana provisioning (requires webhook URL in .env)
- 6 pre-configured alert rules monitor for errors, performance issues, anomalies
- Host monitoring available via `server/docker-compose.host-monitoring.yml`
- Alert rules at `server/stack/grafana/provisioning/alerting/alert-rules.yaml`

### Deployment Philosophy
- **Server deploys once** - Centralized monitoring for multiple applications
- **Clients configure independently** - Each app sends to server endpoints
- **Clear separation** - Server receives/stores, clients send
- **Flexible** - Deploy server on dedicated host, clients anywhere
