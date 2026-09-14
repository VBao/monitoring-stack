# Quick Reference Card

One-page reference for the monitoring stack (v2.1 - Client/Server Architecture).

## 🚀 Start Stack

```bash
# Server (monitoring backend)
cd server
docker-compose up -d

# Server with host monitoring
cd server
./setup/start-host-monitoring.sh  # Linux/macOS
setup\start-host-monitoring.bat   # Windows
```

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3002 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| Alloy | http://localhost:12345 | - |
| Loki | http://localhost:3100 | - |
| Tempo | http://localhost:3200 | - |
| Pyroscope | http://localhost:4040 | - |
| Node Exporter | http://localhost:9100 | - |
| cAdvisor | http://localhost:8080 | - |
| Promtail | http://localhost:9080 | - |

## 📊 Key Ports

| Port | Service | Protocol |
|------|---------|----------|
| 4317 | Alloy OTLP | gRPC |
| 4318 | Alloy OTLP | HTTP |
| 3002 | Grafana | HTTP |
| 9090 | Prometheus | HTTP |
| 3100 | Loki | HTTP |
| 3200 | Tempo | HTTP |
| 4040 | Pyroscope | HTTP |

## 🔧 Common Commands

```bash
# All commands run from server/ directory
cd server

# View logs
docker-compose logs -f [service-name]

# Restart service
docker-compose restart [service-name]

# Check status
docker-compose ps

# Stop all
docker-compose down

# Update and restart
docker-compose pull
docker-compose up -d

# Validate configs
./scripts/validate-config.sh
```

## 📁 Directory Structure

```
monitoring/
├── server/              ⭐ Deploy backend here
│   ├── docker-compose.yml
│   ├── stack/           # Component configs
│   ├── setup/           # Setup scripts
│   └── scripts/         # Utilities
│
├── client/              ⭐ Configure apps here
│   ├── java-spring-boot-otlp.yml
│   ├── generic-env-vars.sh
│   └── README.md
│
├── docs/                # Detailed guides
└── quick-start/         # 5-min guides
```

## 🎯 Quick Tasks

### Deploy Server
```bash
cd server
docker-compose up -d
```

### Add Slack Alerts
```bash
cd server
./setup/setup-slack-alerts.sh
```

### Configure App to Send Logs
```bash
cd client
# Java Spring Boot
cp java-spring-boot-otlp.yml /path/to/app/

# Any language (env vars)
source generic-env-vars.sh
```

### Test OTLP Endpoint
```bash
curl http://localhost:4318/v1/logs -v
```

### View Logs in Grafana
```
1. Open http://localhost:3002
2. Explore → Loki
3. Query: {service_name="my-app"}
```

## 🐛 Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| Service not starting | `cd server && docker-compose logs [service]` |
| Port already in use | `docker ps` to find conflict |
| Slack not working | Check `server/.env` has webhook URL |
| Logs not appearing | `curl http://localhost:4318/v1/logs -v` |
| Commands fail | Verify you're in `server/` directory |

## 📞 Get Help

```bash
# Navigation
cat README.md           # Architecture overview
cat server/README.md    # Server deployment
cat client/README.md    # App configuration

# Find anything
cat INDEX.md            # Complete index

# Migration help
cat MIGRATION-GUIDE.md  # v2.0 → v2.1
```

## 🔗 Key Files

| File | Location | Purpose |
|------|----------|---------|
| Main README | `README.md` | Navigation |
| Server docs | `server/README.md` | Backend deployment |
| Client docs | `client/README.md` | App instrumentation |
| Index | `INDEX.md` | Complete file index |
| Quick ref | `QUICK-REFERENCE.md` | This file |
| Migration | `MIGRATION-GUIDE.md` | v2.0 → v2.1 guide |

## 💡 Pro Tips

- Always `cd server` before running docker-compose
- Use `client/` for app configuration examples
- Check `INDEX.md` to find anything
- Read `server/README.md` for full server docs
- Read `client/README.md` for app setup

## 📝 Version

**Current**: 2.1.0 (Client/Server Separation)

**Key Change from v2.0:**
- Old: `docker-compose up -d` (from root)
- New: `cd server && docker-compose up -d`

---

**For full navigation**: See [`README.md`](README.md) | [`INDEX.md`](INDEX.md)
