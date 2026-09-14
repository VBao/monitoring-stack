# Changelog

All notable changes to the monitoring stack project.

## [2.1.0] - 2026-02-05

### 🎉 Client/Server Separation - Clean Architecture

#### Added
- **Client/Server Directories**
  - `server/` - Complete self-contained monitoring backend
  - `client/` - Self-contained application configuration examples
  - `MIGRATION-GUIDE.md` - Migration instructions from v2.0 to v2.1

- **Server Directory** (Complete backend)
  - `server/docker-compose.yml` - Main monitoring stack
  - `server/docker-compose.host-monitoring.yml` - Host monitoring add-on
  - `server/stack/` - All component configurations
  - `server/setup/` - Setup scripts
  - `server/scripts/` - Utility scripts
  - `server/README.md` - Complete server documentation

- **Client Directory** (Application configs)
  - `client/java-spring-boot-otlp.yml` - Spring Boot configuration
  - `client/generic-env-vars.sh` - Universal environment variables
  - `client/README.md` - Multi-language instrumentation guide

#### Changed
- **No Root Entry Point**
  - Removed root `docker-compose.yml` - now in `server/`
  - Removed root `stack/` - now in `server/stack/`
  - Users must explicitly `cd server` or `cd client`

- **Clear Separation**
  - Server = Backend that RECEIVES and stores telemetry
  - Client = Configuration for apps that SEND telemetry
  - Independent deployment model

- **Documentation Restructure**
  - Root `README.md` is now navigation only
  - `server/README.md` covers backend deployment
  - `client/README.md` covers application instrumentation

#### Removed
- Root `docker-compose.yml` (→ `server/docker-compose.yml`)
- Root `docker-compose.host-monitoring.yml` (→ `server/docker-compose.host-monitoring.yml`)
- Root `stack/` directory (→ `server/stack/`)
- Root `setup/` directory (→ `server/setup/`)
- Root `scripts/` directory (→ `server/scripts/`)
- Root `configs/` directory (→ `client/`)
- Root `.env.example` (→ `server/.env.example`)

#### Benefits
- Clean root directory - only navigation and docs
- No duplicate files
- Self-contained server and client
- Clear deployment intent
- Better git diffs

## [2.0.0] - 2026-01-30

### 🎉 Major Reorganization - Clean Structure

#### Added
- **Navigation Files**
  - `INDEX.md` - Complete file index and navigation guide
  - `QUICK-REFERENCE.md` - One-page quick reference card
  - `STRUCTURE.md` - Visual directory structure guide
  - `CHANGELOG.md` - This file

- **Organized Directories**
  - `quick-start/` - 5-minute quick start guides (3 files)
  - `setup/` - Interactive setup scripts (4 scripts)
  - `configs/client-side/` - Application configuration examples
  - `configs/server-side/` - Monitoring stack configurations

- **Client-Side Configs**
  - `configs/client-side/README.md` - Client setup guide
  - `configs/client-side/java-spring-boot-otlp.yml` - Spring Boot OTLP config
  - `configs/client-side/generic-env-vars.sh` - Universal environment variables

- **Server-Side Configs**
  - `configs/server-side/README.md` - Server setup guide
  - `configs/server-side/.env.slack-only` - Slack webhook environment vars
  - `configs/server-side/docker-compose-slack-only.yml` - Docker Compose additions
  - `configs/server-side/slack-alert-rules-only.yaml` - 6 alert rules
  - `configs/server-side/slack-contact-point-only.yaml` - Slack webhook config
  - `configs/server-side/slack-notification-policy-only.yaml` - Alert routing

- **Documentation**
  - `configs/README-ARCHITECTURE.md` - Client vs Server architecture
  - `configs/COPY-PASTE-COMMANDS.md` - Quick command reference
  - `docs/slack-alert-flow-diagram.md` - Visual flow diagrams
  - `docs/IMPLEMENTATION-SUMMARY.md` - Host monitoring details
  - `docs/SLACK-IMPLEMENTATION-SUMMARY.md` - Slack alerting details

#### Changed
- **Reorganized Root Directory**
  - Moved quick guides to `quick-start/` (3 files)
  - Moved setup scripts to `setup/` (4 files)
  - Moved implementation docs to `docs/` (2 files)
  - Reduced root files from 12 to 6 (50% reduction)

- **Enhanced README.md**
  - Added quick navigation section
  - Updated links to new structure

#### Fixed
- LogQL queries in Spring Boot dashboard to use JSON parser instead of pattern parser
- Corrected field names: `traceid`, `severity`, `body` for OTLP format
- Trace IDs now display correctly in logs

### 🔔 Slack Integration - v1.0.0

#### Added
- Complete Slack notification system
  - 6 pre-configured alert rules
  - Smart alert grouping and routing
  - Customizable thresholds
  - Trace ID correlation in alerts

- **Alert Rules**
  - High Error Rate (> 5 errors/sec)
  - Critical Error Pattern (exceptions, panics)
  - Database Errors (connection issues)
  - Application Startup Failures
  - Log Volume Spike (> 100 logs/sec)
  - Slow Response Times

- **Setup Tools**
  - Interactive setup scripts (Linux/macOS + Windows)
  - Automated configuration
  - Testing utilities

### 🖥️ Host Monitoring - v1.0.0

#### Added
- Host system monitoring capabilities
  - Node Exporter for host metrics (CPU, memory, disk, network)
  - Promtail for host log collection
  - cAdvisor for container resource tracking

- **Pre-built Dashboard**
  - 11 monitoring panels
  - CPU/Memory/Disk gauges
  - Historical trends
  - Container resource usage
  - System log viewer

- **Configuration**
  - `docker-compose.host-monitoring.yml` - Host monitoring services
  - `stack/promtail/promtail-config.yaml` - Log collection config
  - Updated Alloy config with host metrics scraping

### 📊 Dashboard Improvements

#### Fixed
- Spring Boot dashboard LogQL queries for OTLP JSON format
- Log severity aggregation (changed from `level` to `severity`)
- Trace ID display in log viewer

---

## [1.0.0] - 2025-05-29

### Initial Release

#### Added
- Base monitoring stack
  - Grafana 12.0.1
  - Prometheus 3.3.0
  - Loki 3.5
  - Tempo 2.7.2
  - Grafana Alloy 1.9.0-rc.1
  - Pyroscope 1.9.0

- Core configuration files
  - Docker Compose setup
  - Service configurations
  - Basic dashboards

- Documentation
  - Component configuration guides
  - Basic setup instructions

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| **2.1.0** | 2026-02-05 | Client/Server separation, no root entry point |
| **2.0.0** | 2026-01-30 | Major reorganization, Slack alerts, Host monitoring |
| **1.0.0** | 2025-05-29 | Initial monitoring stack release |

---

## Migration Guide

### Upgrading from 2.0 to 2.1

**Breaking Changes** - Entry point has moved:

**Old (v2.0):**
```bash
docker-compose up -d  # From root
```

**New (v2.1):**
```bash
cd server
docker-compose up -d
```

**Migration steps:**
1. Move `.env` file (if exists): `mv .env server/.env`
2. Update scripts to use `cd server && docker-compose ...`
3. Use `client/` for application configuration examples
4. See `MIGRATION-GUIDE.md` for full details

**Benefits:**
- Clear server/client separation
- No root entry point (explicit choice required)
- Independent deployment
- Self-contained directories

### Upgrading from 1.x to 2.0

**No breaking changes** - The core monitoring stack remains unchanged.

**New features available:**
1. Slack alerting - Run `./server/setup/setup-slack-alerts.sh`
2. Host monitoring - Run `./server/setup/start-host-monitoring.sh`
3. Better documentation - Check `INDEX.md` for navigation

**New navigation:**
- Start with `README.md` for navigation
- Use `QUICK-REFERENCE.md` for fast lookup
- Check `STRUCTURE.md` for directory overview

---

## Planned Features

### Coming Soon
- [ ] Additional client-side configs (Node.js, Python, .NET, Go)
- [ ] PagerDuty integration
- [ ] Email notifications
- [ ] Custom dashboard templates
- [ ] Automated backup scripts
- [ ] Performance optimization guide
- [ ] Multi-environment setup guide

### Under Consideration
- [ ] Kubernetes deployment manifests
- [ ] Terraform modules
- [ ] Alert rule library expansion
- [ ] SLA tracking dashboards
- [ ] Cost optimization guide

---

## Support

For questions, issues, or contributions:
- **Documentation**: Check `README.md` for navigation
- **Server Setup**: See `server/README.md`
- **Client Setup**: See `client/README.md`
- **Migration Help**: See `MIGRATION-GUIDE.md`
- **File Index**: See `INDEX.md`

---

**Maintained by**: DevOps Team
**Last Updated**: 2026-02-05
