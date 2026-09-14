# Monitoring Stack - Directory Structure

Visual representation of the v2.1 client/server architecture.

## Overview

The monitoring stack is organized into two independent components with **no root entry point**:

- **server/** - Complete monitoring backend (Grafana stack)
- **client/** - Application configuration examples

Users must explicitly choose which component to use by navigating to that directory.

---

## Complete Directory Tree

```
monitoring/
│
├── 📁 server/                       ⭐ MONITORING BACKEND
│   ├── docker-compose.yml           Main monitoring stack
│   ├── docker-compose.host-monitoring.yml  Host monitoring add-on
│   ├── .env.example                 Environment variables template
│   ├── .env.slack-only              Slack webhook config
│   ├── README.md                    Complete server documentation
│   │
│   ├── stack/                       Component Configurations
│   │   ├── alloy/                   Grafana Alloy (OTLP receiver)
│   │   │   └── config.alloy         OTLP receivers & routing
│   │   ├── prometheus/              Prometheus (Metrics)
│   │   │   └── prometheus.yml       Scrape configs & retention
│   │   ├── loki/                    Loki (Logs)
│   │   │   └── loki-config.yaml     Log storage & retention
│   │   ├── tempo/                   Tempo (Traces)
│   │   │   └── tempo.yaml           Trace storage config
│   │   ├── promtail/                Promtail (Host logs)
│   │   │   └── promtail-config.yaml Host log collection
│   │   └── grafana/                 Grafana (Visualization)
│   │       ├── provisioning/
│   │       │   ├── datasources/     Auto-configured sources
│   │       │   ├── dashboards/      Dashboard provisioning
│   │       │   └── alerting/        Alert rules & Slack
│   │       │       ├── alert-rules.yaml
│   │       │       ├── slack-contact-point.yaml
│   │       │       └── notification-policies.yaml
│   │       ├── dashboards/
│   │       │   ├── spring-boot.json
│   │       │   └── host-monitoring.json
│   │       └── dashboard.yaml
│   │
│   ├── setup/                       Setup Scripts
│   │   ├── setup-slack-alerts.sh    Slack setup (Linux/macOS)
│   │   ├── setup-slack-alerts.bat   Slack setup (Windows)
│   │   ├── start-host-monitoring.sh Start with host monitoring
│   │   └── start-host-monitoring.bat
│   │
│   └── scripts/                     Utility Scripts
│       ├── validate-config.sh       Validate configs
│       └── validate-host-monitoring.sh
│
├── 📁 client/                       ⭐ APPLICATION CONFIGS
│   ├── java-spring-boot-otlp.yml    Spring Boot OTLP config
│   ├── generic-env-vars.sh          Universal environment vars
│   └── README.md                    Multi-language guide
│
├── 📁 docs/                         Comprehensive Documentation
│   ├── slack-integration-guide.md   Complete Slack guide
│   ├── host-monitoring-guide.md     Complete host monitoring
│   ├── slack-alert-flow-diagram.md  Visual diagrams
│   ├── IMPLEMENTATION-SUMMARY.md    Host monitoring details
│   ├── SLACK-IMPLEMENTATION-SUMMARY.md  Slack details
│   ├── alloy-config-guide.md        Alloy configuration
│   ├── loki-config-guide.md         Loki configuration
│   ├── prometheus-config-guide.md   Prometheus configuration
│   └── tempo-config-guide.md        Tempo configuration
│
├── 📁 quick-start/                  Quick Guides (5 minutes)
│   ├── SLACK-ALERTS-README.md       Slack setup guide
│   ├── HOST-MONITORING-README.md    Host monitoring guide
│   └── COMMANDS-CHEATSHEET.md       Copy-paste commands
│
└── 📄 Root Documentation           Navigation & Reference
    ├── README.md                    Navigation & architecture
    ├── CLAUDE.MD                    AI assistant context
    ├── INDEX.md                     Complete file index
    ├── CHANGELOG.md                 Version history
    ├── QUICK-REFERENCE.md           One-page quick reference
    ├── STRUCTURE.md                 This file
    ├── MIGRATION-GUIDE.md           Migration from v2.0
    └── .gitignore                   Git ignore rules
```

---

## Component Breakdown

### Server Directory (Backend)

**Purpose**: Complete monitoring backend - receives, stores, and visualizes telemetry

**Entry Point**:
```bash
cd server
docker-compose up -d
```

**Contains**:
- ✅ Docker Compose files
- ✅ All component configs (Grafana, Prometheus, Loki, Tempo, Alloy)
- ✅ Setup and validation scripts
- ✅ Complete documentation

**Self-contained**: Can be deployed independently on a dedicated monitoring server.

---

### Client Directory (Frontend)

**Purpose**: Configuration examples for applications that send telemetry

**Usage**:
```bash
cd client
# Copy configuration for your language
cp java-spring-boot-otlp.yml /path/to/app/
```

**Contains**:
- ✅ Java Spring Boot configuration
- ✅ Universal environment variables
- ✅ Multi-language examples and guides

**Self-contained**: Complete documentation for instrumenting applications.

---

### Documentation Directories

**docs/** - Comprehensive guides (detailed explanations)
**quick-start/** - Quick guides (5-minute setup)

Both directories provide documentation but at different levels of detail.

---

## Navigation Patterns

### By User Type

**DevOps Engineer (Deploy Server)**:
```
README.md → server/README.md → cd server && docker-compose up -d
```

**Developer (Configure App)**:
```
README.md → client/README.md → Copy config for your language
```

**Team Lead (Understand Architecture)**:
```
README.md → STRUCTURE.md → INDEX.md
```

---

### By Task

**"Deploy monitoring stack"**:
```
1. cd server
2. docker-compose up -d
3. Access http://localhost:3002
```

**"Set up Slack alerts"**:
```
1. cd server
2. ./setup/setup-slack-alerts.sh
3. Test in Grafana
```

**"Configure my Java app"**:
```
1. cd client
2. cp java-spring-boot-otlp.yml to app
3. Follow client/README.md
```

---

## File Organization Principles

### 1. No Root Entry Point
- No `docker-compose.yml` in root
- Users must `cd server` or `cd client` explicitly
- Prevents accidental deployments

### 2. Self-Contained Directories
- `server/` is complete - all backend files
- `client/` is complete - all config examples
- Each has own README.md

### 3. Clear Separation
- **Server** = Receives and stores (backend)
- **Client** = Sends data (frontend)
- No confusion about what goes where

### 4. Progressive Disclosure
- Root README.md = Navigation
- `server/README.md` = Server deployment
- `client/README.md` = App instrumentation
- `docs/` = Deep dives

---

## Key Directories Explained

### `server/stack/`
All monitoring component configurations:
- **alloy/** - OTLP receiver and routing
- **prometheus/** - Metrics collection
- **loki/** - Log storage
- **tempo/** - Trace storage
- **grafana/** - Dashboards and alerts
- **promtail/** - Host log collection

### `server/setup/`
Interactive setup scripts:
- Slack alerts configuration
- Host monitoring startup
- Windows and Linux/macOS versions

### `server/scripts/`
Validation and utility scripts:
- Config validation
- Host monitoring checks

### `client/`
Application configuration examples:
- Java Spring Boot
- Environment variables (any language)
- Multi-language guide

### `docs/`
Comprehensive documentation:
- Component guides (Alloy, Loki, Prometheus, Tempo)
- Integration guides (Slack, Host Monitoring)
- Implementation summaries

### `quick-start/`
Quick reference guides:
- 5-minute Slack setup
- 5-minute host monitoring
- Command cheatsheet

---

## What's Different in v2.1

### Before (v2.0)
```
monitoring/
├── docker-compose.yml     ← Root entry point
├── stack/                 ← Component configs
├── configs/
│   ├── client-side/
│   └── server-side/
├── setup/
└── scripts/
```

### After (v2.1)
```
monitoring/
├── server/                ← Backend (self-contained)
│   ├── docker-compose.yml
│   ├── stack/
│   ├── setup/
│   └── scripts/
├── client/                ← Frontend (self-contained)
└── docs/                  ← Shared docs
```

**Key Changes**:
- ✅ No root `docker-compose.yml`
- ✅ Server is self-contained in `server/`
- ✅ Client is self-contained in `client/`
- ✅ Clean root with only navigation docs

---

## Finding Things

| Looking for... | Location |
|----------------|----------|
| Deploy server | `cd server && docker-compose up -d` |
| Configure app | `client/README.md` |
| Alert rules | `server/stack/grafana/provisioning/alerting/` |
| Dashboards | `server/stack/grafana/dashboards/` |
| OTLP config | `server/stack/alloy/config.alloy` |
| Prometheus config | `server/stack/prometheus/prometheus.yml` |
| Setup Slack | `server/setup/setup-slack-alerts.sh` |
| Java example | `client/java-spring-boot-otlp.yml` |
| Env vars | `client/generic-env-vars.sh` |
| Complete index | `INDEX.md` |

---

## Design Benefits

✅ **Clean Root** - Only navigation and reference docs
✅ **No Duplicates** - Each file in exactly one location
✅ **Self-Contained** - Server and client are independent
✅ **Clear Intent** - Must explicitly choose server or client
✅ **Better Git** - Cleaner diffs, easier code review
✅ **Scalable** - Easy to add more client examples

---

## Maintenance Guidelines

### Adding New Content

**New client language**:
```
client/
├── java-spring-boot-otlp.yml     ✓ Exists
├── generic-env-vars.sh           ✓ Exists
├── python-flask-otlp.py          → Add here
└── nodejs-express-otlp.js        → Add here
```

**New alert rule**:
```
server/stack/grafana/provisioning/alerting/alert-rules.yaml
```

**New dashboard**:
```
server/stack/grafana/dashboards/my-dashboard.json
```

**New documentation**:
```
docs/new-feature-guide.md
```

### Updating Documentation

When structure changes, update in this order:
1. `STRUCTURE.md` (this file)
2. `INDEX.md`
3. `README.md`
4. `CHANGELOG.md`
5. `CLAUDE.MD`

---

**Version**: 2.1.0 (Client/Server Separation)
**Last Updated**: 2026-02-05
