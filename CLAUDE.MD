# CLAUDE.MD - Monitoring Stack Project

## Project Overview

This is a comprehensive **Grafana-based monitoring stack** for observability, implementing the three pillars: **Metrics**, **Logs**, and **Traces**. The stack uses OpenTelemetry standards for data collection and provides a unified platform for correlation and analysis.

## Stack Components

### Core Services
- **Grafana Alloy** (v1.9.0-rc.1) - OpenTelemetry collector and telemetry data pipeline
- **Prometheus** (v3.3.0) - Time-series metrics collection and storage
- **Grafana Loki** - Log aggregation and storage system
- **Grafana Tempo** (v2.7.2) - Distributed tracing backend
- **Grafana** - Visualization, dashboards, and alerting UI
- **Pyroscope** - Continuous profiling platform

### Host Monitoring Services (Optional)
- **Node Exporter** (v1.8.2) - Host system metrics (CPU, memory, disk, network)
- **Promtail** (v3.5.0) - Host log collection and forwarding to Loki
- **cAdvisor** (v0.49.1) - Container resource usage monitoring

### Data Flow
1. Applications send telemetry via OTLP (OpenTelemetry Protocol) to Alloy
2. Alloy processes, transforms, and routes data to appropriate backends:
   - Metrics → Prometheus
   - Logs → Loki
   - Traces → Tempo
   - Profiles → Pyroscope
3. Grafana queries all backends for unified visualization and correlation

## Directory Structure

```
monitoring/
├── alloy/                      # Grafana Alloy configuration
│   └── config.alloy           # Alloy pipeline configuration
├── prometheus/                # Prometheus configuration
│   └── prometheus.yml         # Scrape configs and rules
├── loki/                      # Loki configuration
│   └── loki-config.yaml       # Log storage and retention
├── tempo/                     # Tempo configuration
│   ├── tempo.yaml            # Trace storage configuration
│   └── tempo1.yaml           # Alternative config
├── otel-collector/           # OpenTelemetry collector configs
│   └── otel-collector-config.yaml
├── grafana/                   # Grafana provisioning
│   ├── dashboard.yaml        # Dashboard definitions
│   └── provisioning/         # Data sources and dashboards
│       ├── datasources/      # Auto-configured data sources
│       └── dashboards/       # Dashboard provisioning
├── docs/                      # Comprehensive documentation
│   ├── alloy-config-guide.md
│   ├── loki-config-guide.md
│   ├── prometheus-config-guide.md
│   ├── tempo-config-guide.md
│   └── quick-reference.md
├── scripts/                   # Utility scripts
│   └── validate-config.sh    # Configuration validation
├── promtail/                 # Promtail configuration (host monitoring)
│   └── promtail-config.yaml  # Log collection config
├── docker-compose.yml        # Main stack orchestration
├── docker-compose.host-monitoring.yml  # Host monitoring add-on
├── start-host-monitoring.sh  # Linux/macOS startup script
├── start-host-monitoring.bat # Windows startup script
└── README.md                 # Project documentation
```

## Key Configuration Files

### docker-compose.yml
Main orchestration file defining all services, ports, volumes, and networks.

**Key Ports:**
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

### Configuration Files by Service
- **Alloy**: `alloy/config.alloy`
- **Prometheus**: `prometheus/prometheus.yml`
- **Loki**: `loki/loki-config.yaml`
- **Tempo**: `tempo/tempo.yaml`
- **OTEL Collector**: `otel-collector/otel-collector-config.yaml`

## Recent Changes

Based on git status, these files have uncommitted changes:
- `loki/loki-config.yaml` - Modified
- `otel-collector/otel-collector-config.yaml` - Modified
- `scripts/validate-config.sh` - Modified
- `tempo/tempo1.yaml` - Modified

## Common Tasks

### Starting the Stack

**Main stack only**:
```bash
docker-compose up -d
```

**With host monitoring**:
```bash
# Linux/macOS
./start-host-monitoring.sh

# Windows
start-host-monitoring.bat

# Or manually
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml up -d
```

### Viewing Logs
```bash
docker-compose logs -f <service-name>

# With host monitoring
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml logs -f
```

### Validating Configurations
```bash
./scripts/validate-config.sh
```

### Accessing UIs
- Grafana: http://localhost:3002
- Prometheus: http://localhost:9090
- Alloy: http://localhost:12345
- Pyroscope: http://localhost:4040
- Node Exporter: http://localhost:9100
- cAdvisor: http://localhost:8080
- Promtail: http://localhost:9080

## Documentation

Comprehensive guides are available in the `docs/` directory:
- `alloy-config-guide.md` - Alloy pipeline configuration details
- `loki-config-guide.md` - Log aggregation configuration
- `prometheus-config-guide.md` - Metrics collection and alerting
- `tempo-config-guide.md` - Distributed tracing setup
- `host-monitoring-guide.md` - Host system and container monitoring
- `quick-reference.md` - Quick reference for common operations

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
- **Recent Commits Focus**: Dashboard updates, configuration optimizations, documentation improvements

## Notes for Claude

- This is a production-ready monitoring stack with comprehensive documentation
- Configuration changes should be validated using `scripts/validate-config.sh`
- All services use Docker Compose for orchestration
- The stack follows OpenTelemetry standards for interoperability
- Retention policies are configured per service (7d for Prometheus)
- Services communicate over a shared `monitoring` Docker network
