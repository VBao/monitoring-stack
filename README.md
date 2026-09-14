# Monitoring Stack - Client/Server Architecture

**Production-ready observability platform with separate client and server deployments.**

This repository provides a complete monitoring stack based on Grafana, split into two independent components:

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT (Your Apps)                      │
│  Applications send telemetry via OTLP to the server        │
│  - Java, Python, Node.js, Go, .NET, etc.                   │
│  - Metrics, Logs, Traces, Profiles                          │
└─────────────────────┬───────────────────────────────────────┘
                      │ OTLP (4317/4318)
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                     SERVER (Monitoring)                      │
│  Grafana stack receives, stores, and visualizes data        │
│  - Alloy → Prometheus (metrics)                             │
│  - Alloy → Loki (logs)                                      │
│  - Alloy → Tempo (traces)                                   │
│  - Alloy → Pyroscope (profiles)                             │
│  - Grafana (visualization)                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
monitoring/
├── server/              ← Deploy monitoring backend here
│   ├── docker-compose.yml
│   ├── docker-compose.host-monitoring.yml
│   ├── stack/           # All service configs
│   ├── setup/           # Setup scripts
│   ├── scripts/         # Utility scripts
│   └── README.md        # Server documentation
│
├── client/              ← Configure your applications here
│   ├── java-spring-boot-otlp.yml
│   ├── generic-env-vars.sh
│   └── README.md        # Client instrumentation guide
│
├── docs/                # Comprehensive documentation
├── quick-start/         # 5-minute setup guides
└── README.md            # This file
```

---

## 🚀 Quick Start

### 1. Deploy the Server (Monitoring Backend)

```bash
cd server
docker-compose up -d
```

**Access UIs:**
- Grafana: http://localhost:3002 (admin/admin)
- Prometheus: http://localhost:9090
- Alloy: http://localhost:12345

**Full server documentation:** [`server/README.md`](server/README.md)

---

### 2. Configure Your Applications (Client)

**Java Spring Boot:**
```bash
cd client
cp java-spring-boot-otlp.yml /path/to/your/app/src/main/resources/application-monitoring.yml
java -jar app.jar --spring.profiles.active=monitoring
```

**Any Language (Environment Variables):**
```bash
cd client
source generic-env-vars.sh
./your-application
```

**Full client documentation:** [`client/README.md`](client/README.md)

---

## 📖 Documentation

### Quick Guides (5 minutes each)
- **[Slack Alerts Setup](quick-start/SLACK-ALERTS-README.md)** - Get error notifications in Slack
- **[Host Monitoring](quick-start/HOST-MONITORING-README.md)** - Monitor server CPU, memory, disk
- **[Commands Cheatsheet](quick-start/COMMANDS-CHEATSHEET.md)** - Copy-paste commands

### Comprehensive Guides
- **[Slack Integration](docs/slack-integration-guide.md)** - Complete alerting setup
- **[Host Monitoring](docs/host-monitoring-guide.md)** - System metrics & logs
- **[Alloy Configuration](docs/alloy-config-guide.md)** - Telemetry pipeline
- **[Prometheus Configuration](docs/prometheus-config-guide.md)** - Metrics storage
- **[Loki Configuration](docs/loki-config-guide.md)** - Log aggregation
- **[Tempo Configuration](docs/tempo-config-guide.md)** - Distributed tracing

### Reference
- **[INDEX.md](INDEX.md)** - Complete file directory
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - One-page command reference
- **[STRUCTURE.md](STRUCTURE.md)** - Directory organization
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

---

## 🎯 Use Cases

### Deploy Server Only
Perfect for centralized monitoring of multiple applications:

```bash
cd server
docker-compose up -d
```

Multiple applications send to `http://your-server:4318`

---

### Deploy Server + Host Monitoring
Monitor the server itself (CPU, memory, disk, containers):

```bash
cd server
./setup/start-host-monitoring.sh  # Linux/macOS
setup\start-host-monitoring.bat   # Windows
```

---

### Configure Client Applications
Each application independently configures OTLP export:

**Java:**
```yaml
management:
  otlp:
    metrics:
      export:
        url: http://monitoring-server:4318/v1/metrics
```

**Python:**
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://monitoring-server:4318
opentelemetry-instrument python app.py
```

**Node.js, Go, .NET:** See [`client/README.md`](client/README.md)

---

## 🔑 Key Features

### Server Features
✅ **Complete observability stack** - Metrics, logs, traces, profiles
✅ **Pre-configured dashboards** - Spring Boot, host monitoring
✅ **Slack alerting** - 6 pre-configured alert rules
✅ **Auto-provisioning** - Data sources, dashboards, alerts
✅ **Production-ready** - Retention policies, resource limits
✅ **Docker Compose** - Single command deployment

### Client Features
✅ **Multi-language support** - Java, Python, Node.js, Go, .NET
✅ **Copy-paste configs** - Ready-to-use examples
✅ **OpenTelemetry standard** - Framework-agnostic
✅ **Trace correlation** - Link logs, metrics, and traces

---

## 📊 Stack Components

### Server Stack

| Component | Purpose | Port |
|-----------|---------|------|
| **Grafana Alloy** | OTLP receiver & router | 4317, 4318, 12345 |
| **Prometheus** | Metrics storage | 9090 |
| **Loki** | Log storage | 3100 |
| **Tempo** | Trace storage | 3200 |
| **Grafana** | Visualization | 3002 |
| **Pyroscope** | Profile storage | 4040 |

**Optional (Host Monitoring):**
- **Node Exporter** - System metrics (9100)
- **Promtail** - Log collection (9080)
- **cAdvisor** - Container metrics (8080)

---

## 🛠️ Common Operations

### Start Server
```bash
cd server
docker-compose up -d
```

### Stop Server
```bash
cd server
docker-compose down
```

### View Server Logs
```bash
cd server
docker-compose logs -f alloy prometheus loki tempo grafana
```

### Configure Client
```bash
cd client
# Edit generic-env-vars.sh or java-spring-boot-otlp.yml
# See client/README.md for details
```

### Setup Alerts
```bash
cd server
./setup/setup-slack-alerts.sh  # Linux/macOS
setup\setup-slack-alerts.bat   # Windows
```

---

## 📚 Learn More

### What is this stack?
A **production-ready observability platform** implementing:
- **Metrics** - Prometheus time-series database
- **Logs** - Loki log aggregation
- **Traces** - Tempo distributed tracing
- **Unified visualization** - Grafana dashboards

### Why client/server separation?
- **Deploy once, monitor many** - One server, multiple applications
- **Independent scaling** - Scale server and clients separately
- **Clear responsibilities** - Server receives/stores, client sends
- **Flexible deployment** - Deploy where it makes sense

### How do I get started?
1. **Deploy server:** `cd server && docker-compose up -d`
2. **Configure one app:** Use examples in `client/`
3. **Verify data:** Check http://localhost:3002
4. **Add more apps:** Repeat step 2 for each application

---

## 🔗 External Resources

- **OpenTelemetry**: https://opentelemetry.io/docs/
- **Grafana**: https://grafana.com/docs/
- **Prometheus**: https://prometheus.io/docs/
- **Loki**: https://grafana.com/docs/loki/latest/
- **Tempo**: https://grafana.com/docs/tempo/latest/

---

## 📝 Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

**Current Version:** 2.1 (Client/Server Split)

---

## 🆘 Support

### Server Issues
- Check: [`server/README.md`](server/README.md)
- Logs: `cd server && docker-compose logs -f`
- Validate: `cd server && ./scripts/validate-config.sh`

### Client Issues
- Check: [`client/README.md`](client/README.md)
- Test endpoint: `curl http://localhost:4318/v1/metrics`
- Verify Alloy: http://localhost:12345

### General Help
- Quick guides: [`quick-start/`](quick-start/)
- Detailed docs: [`docs/`](docs/)
- File index: [`INDEX.md`](INDEX.md)

---

**Ready to start monitoring? Choose your path:**

→ **Deploy Server:** [`cd server`](server/) and read `README.md`
→ **Configure Client:** [`cd client`](client/) and read `README.md`
→ **Quick Setup:** Check [`quick-start/`](quick-start/)
