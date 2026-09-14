# Monitoring Stack - Master Index

Quick reference to find what you need in the new client/server architecture.

## 🚀 Getting Started (Pick One)

| I want to... | Go to |
|--------------|-------|
| **Deploy monitoring server** | `cd server && docker-compose up -d` |
| **Configure my app** | [`client/README.md`](client/README.md) |
| **Add Slack alerts** | [`server/setup/setup-slack-alerts.sh`](server/setup/setup-slack-alerts.sh) |
| **Add host monitoring** | [`server/setup/start-host-monitoring.sh`](server/setup/start-host-monitoring.sh) |

## 📁 New Structure (v2.1)

```
monitoring/
├── server/              ⭐ Complete monitoring backend
├── client/              ⭐ Application configuration examples
├── docs/                📚 Comprehensive guides
├── quick-start/         ⚡ 5-minute setup guides
└── *.md                 📄 Navigation & reference docs
```

**No root entry point** - Users must `cd server` or `cd client` explicitly.

## 📚 Documentation by Type

### Quick Start Guides (5 min read)
- [`quick-start/SLACK-ALERTS-README.md`](quick-start/SLACK-ALERTS-README.md) - Slack notifications setup
- [`quick-start/HOST-MONITORING-README.md`](quick-start/HOST-MONITORING-README.md) - Host monitoring setup
- [`quick-start/COMMANDS-CHEATSHEET.md`](quick-start/COMMANDS-CHEATSHEET.md) - Copy-paste commands

### Comprehensive Guides (Deep dive)
- [`server/README.md`](server/README.md) - Complete server deployment guide
- [`client/README.md`](client/README.md) - Application instrumentation guide
- [`docs/slack-integration-guide.md`](docs/slack-integration-guide.md) - Complete Slack integration
- [`docs/host-monitoring-guide.md`](docs/host-monitoring-guide.md) - Complete host monitoring
- [`docs/slack-alert-flow-diagram.md`](docs/slack-alert-flow-diagram.md) - Visual flow diagrams

### Configuration References
- [`server/stack/`](server/stack/) - All monitoring component configs
- [`client/`](client/) - Application configuration examples
- [`server/.env.example`](server/.env.example) - Environment variables template

### Implementation Details
- [`docs/IMPLEMENTATION-SUMMARY.md`](docs/IMPLEMENTATION-SUMMARY.md) - Host monitoring implementation
- [`docs/SLACK-IMPLEMENTATION-SUMMARY.md`](docs/SLACK-IMPLEMENTATION-SUMMARY.md) - Slack alerting implementation

## 🗂️ Directory Structure

```
monitoring/
├── 📁 server/                       ⭐ Monitoring Backend
│   ├── docker-compose.yml           Main stack
│   ├── docker-compose.host-monitoring.yml  Host monitoring
│   ├── .env.example                 Environment template
│   ├── README.md                    Server documentation
│   ├── stack/                       Component configs
│   │   ├── alloy/                   OTLP receiver
│   │   ├── prometheus/              Metrics
│   │   ├── loki/                    Logs
│   │   ├── tempo/                   Traces
│   │   ├── promtail/                Host logs
│   │   └── grafana/                 Dashboards & alerts
│   ├── setup/                       Setup scripts
│   │   ├── setup-slack-alerts.sh
│   │   ├── setup-slack-alerts.bat
│   │   ├── start-host-monitoring.sh
│   │   └── start-host-monitoring.bat
│   └── scripts/                     Utilities
│       ├── validate-config.sh
│       └── validate-host-monitoring.sh
│
├── 📁 client/                       ⭐ Application Configs
│   ├── java-spring-boot-otlp.yml    Spring Boot config
│   ├── generic-env-vars.sh          Universal env vars
│   └── README.md                    Client documentation
│
├── 📁 docs/                         Comprehensive Guides
│   ├── slack-integration-guide.md
│   ├── host-monitoring-guide.md
│   ├── alloy-config-guide.md
│   ├── loki-config-guide.md
│   ├── prometheus-config-guide.md
│   └── tempo-config-guide.md
│
├── 📁 quick-start/                  Quick Guides
│   ├── SLACK-ALERTS-README.md
│   ├── HOST-MONITORING-README.md
│   └── COMMANDS-CHEATSHEET.md
│
└── 📄 Documentation
    ├── README.md                    Navigation & architecture
    ├── CLAUDE.MD                    AI assistant context
    ├── INDEX.md                     This file
    ├── CHANGELOG.md                 Version history
    ├── QUICK-REFERENCE.md           Quick reference
    ├── STRUCTURE.md                 Directory guide
```

## 🎯 Common Tasks

### Deploy Server
```bash
cd server
docker-compose up -d
```

### Deploy Server with Host Monitoring
```bash
cd server
./setup/start-host-monitoring.sh  # Linux/macOS
setup\start-host-monitoring.bat   # Windows
```

### Configure Application (Client)
```bash
cd client
# Follow README.md for Java, Python, Node.js, Go, .NET
```

### Add Slack Alerts
```bash
cd server
./setup/setup-slack-alerts.sh
```

### View Server Logs
```bash
cd server
docker-compose logs -f grafana
```

### Validate Configuration
```bash
cd server
./scripts/validate-config.sh
```

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Slack alerts not working | [`server/README.md#troubleshooting`](server/README.md) |
| App not sending logs | [`client/README.md#troubleshooting`](client/README.md) |
| Host metrics not showing | [`quick-start/HOST-MONITORING-README.md`](quick-start/HOST-MONITORING-README.md) |
| Docker compose errors | Verify in `server/` directory |

## 📞 Quick Help

```bash
# Access UIs (server must be running)
Grafana:    http://localhost:3002
Prometheus: http://localhost:9090
Alloy:      http://localhost:12345

# Check server health
cd server
docker-compose ps
curl http://localhost:3002/api/health
curl http://localhost:3100/ready
curl http://localhost:9090/-/healthy

# Test OTLP endpoint (from application)
curl http://localhost:4318/v1/logs -v
```

## 🌟 Features

### Server Features
- ✅ Metrics collection (Prometheus)
- ✅ Log aggregation (Loki)
- ✅ Distributed tracing (Tempo)
- ✅ Continuous profiling (Pyroscope)
- ✅ Unified dashboards (Grafana)
- ✅ 6 pre-configured alert rules
- ✅ Slack notifications
- ✅ Host monitoring (optional)

### Client Features
- ✅ Multi-language examples (Java, Python, Node.js, Go, .NET)
- ✅ Copy-paste configurations
- ✅ OpenTelemetry standard
- ✅ Trace correlation

## 🔗 External Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Slack Webhooks Guide](https://api.slack.com/messaging/webhooks)

## 📋 Checklists

### New Team Member Onboarding
- [ ] Read [`README.md`](README.md) - Architecture overview
- [ ] Deploy server: `cd server && docker-compose up -d`
- [ ] Access Grafana: http://localhost:3002
- [ ] Read [`client/README.md`](client/README.md)
- [ ] Configure one app to send logs

### Deploying to Production
- [ ] Set strong Grafana admin password
- [ ] Configure Slack webhook in `server/.env`
- [ ] Enable HTTPS for OTLP endpoints
- [ ] Set up firewall rules
- [ ] Configure retention in `server/stack/`
- [ ] Test all alert rules
- [ ] Document runbooks

### Adding New Application
- [ ] Read [`client/README.md`](client/README.md)
- [ ] Configure OTLP endpoint: http://server:4318
- [ ] Set service name and environment
- [ ] Verify logs in Grafana
- [ ] Add custom dashboards if needed
- [ ] Test error notifications

## 📝 Version Notes

**Current Version**: 2.1.0 (Client/Server Separation)

**What's New in v2.1:**
- ✅ Server and client in separate directories
- ✅ No root entry point - explicit choice required
- ✅ Self-contained server and client
- ✅ Clear separation of concerns
- ✅ Better documentation structure

**Migration from v2.0:**
- See [`MIGRATION-GUIDE.md`](MIGRATION-GUIDE.md)
- Old command: `docker-compose up -d` (from root)
- New command: `cd server && docker-compose up -d`

---

**Need help?**
- Start: [`README.md`](README.md)
- Server: [`server/README.md`](server/README.md)
- Client: [`client/README.md`](client/README.md)
- Migration: [`MIGRATION-GUIDE.md`](MIGRATION-GUIDE.md)
