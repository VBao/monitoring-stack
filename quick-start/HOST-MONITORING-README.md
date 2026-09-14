# Host Monitoring Quick Start

This document provides quick instructions for setting up host machine monitoring.

## What Gets Monitored?

### System Metrics (via Node Exporter)
- ✅ CPU usage (total and per-core)
- ✅ Memory usage (available, used, cached)
- ✅ Disk usage and I/O operations
- ✅ Network traffic (bytes sent/received)
- ✅ System load averages
- ✅ Process statistics
- ✅ Filesystem usage

### Container Metrics (via cAdvisor)
- ✅ Per-container CPU usage
- ✅ Per-container memory usage
- ✅ Per-container network I/O
- ✅ Container filesystem usage

### System Logs (via Promtail)
- ✅ System logs (syslog)
- ✅ Authentication logs
- ✅ Kernel logs
- ✅ Docker container logs
- ✅ Custom application logs

## Quick Start

### 1. Start Services

**Linux/macOS:**
```bash
chmod +x start-host-monitoring.sh
./start-host-monitoring.sh
```

**Windows:**
```batch
start-host-monitoring.bat
```

**Manual:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml up -d
```

### 2. Verify Services

```bash
# Check all containers are running
docker ps | grep -E "node-exporter|promtail|cadvisor"

# Test endpoints
curl http://localhost:9100/metrics  # Node Exporter
curl http://localhost:8080/metrics  # cAdvisor
curl http://localhost:9080/ready    # Promtail
```

### 3. Access Grafana Dashboard

1. Open Grafana: http://localhost:3002
2. Login: `admin` / `admin`
3. Go to **Dashboards** → **Host System Monitoring**

## Dashboard Overview

The **Host System Monitoring** dashboard includes:

| Panel | Description |
|-------|-------------|
| CPU Usage | Current CPU usage percentage (gauge) |
| Memory Usage | Current memory usage percentage (gauge) |
| Disk Usage | Current disk usage percentage (gauge) |
| System Load | 1m, 5m, 15m load averages (time series) |
| CPU Usage Over Time | Historical CPU usage with I/O wait |
| Memory Usage Over Time | Total, used, and available memory |
| Network I/O | Network traffic in/out per interface |
| Disk I/O | Disk read/write operations |
| Container CPU Usage | CPU usage per container |
| Container Memory Usage | Memory usage per container |
| System Logs | Recent system logs from Promtail |

## Common Queries

### CPU Usage
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Memory Usage Percentage
```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

### Disk Usage Percentage
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})
```

### Top Containers by CPU
```promql
topk(5, sum by (name) (rate(container_cpu_usage_seconds_total[5m]) * 100))
```

### System Logs (Last Hour)
```logql
{job="syslog"} [1h]
```

## Stopping Services

```bash
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml down
```

## Troubleshooting

### Node Exporter Not Working

**Linux/macOS:**
```bash
# Check if service is running
docker ps | grep node-exporter

# View logs
docker logs node-exporter

# Restart
docker restart node-exporter
```

**Windows:**
Node Exporter doesn't work natively on Windows. Use Windows Exporter instead:
1. Uncomment `windows-exporter` section in `docker-compose.host-monitoring.yml`
2. Comment out `node-exporter` section
3. Restart services

### Promtail Not Collecting Logs

```bash
# Check configuration
docker exec promtail cat /etc/promtail/config.yaml

# View logs
docker logs promtail

# Test Loki connection
docker exec promtail wget -O- http://loki:3100/ready
```

### cAdvisor Not Showing Metrics

```bash
# Ensure it's running with privileged mode
docker inspect cadvisor | grep Privileged

# Check metrics endpoint
curl http://localhost:8080/metrics | grep container_cpu
```

### No Data in Grafana

1. **Check Prometheus targets:**
   - Go to http://localhost:9090/targets
   - Ensure `node-exporter` and `cadvisor` show as "UP"

2. **Check Loki:**
   - Go to http://localhost:3100/ready
   - Should return "ready"

3. **Verify Alloy scraping:**
   - Go to http://localhost:12345
   - Check scrape jobs are active

## Configuration Files

| Component | Configuration File |
|-----------|-------------------|
| Node Exporter | `docker-compose.host-monitoring.yml` (command args) |
| Promtail | `stack/promtail/promtail-config.yaml` |
| cAdvisor | `docker-compose.host-monitoring.yml` (command args) |
| Alloy Scraping | `stack/alloy/config.alloy` (updated with host monitoring) |

## Adding Custom Logs

Edit `stack/promtail/promtail-config.yaml`:

```yaml
scrape_configs:
  - job_name: my_custom_app
    static_configs:
      - targets:
          - localhost
        labels:
          job: my_app
          environment: production
          __path__: /var/log/myapp/*.log
```

Restart Promtail:
```bash
docker restart promtail
```

## Port Reference

| Service | Port | Purpose |
|---------|------|---------|
| Node Exporter | 9100 | Metrics endpoint |
| Promtail | 9080 | Health/status endpoint |
| cAdvisor | 8080 | Metrics & Web UI |

## Next Steps

1. **Customize the dashboard** - Add panels for specific metrics
2. **Set up alerts** - Configure Prometheus alerting rules
3. **Add more log sources** - Extend Promtail configuration
4. **Optimize retention** - Adjust Prometheus and Loki retention policies
5. **Enable remote storage** - Configure long-term metrics storage

## More Information

For detailed documentation, see:
- [Host Monitoring Guide](docs/host-monitoring-guide.md)
- [Prometheus Config Guide](docs/prometheus-config-guide.md)
- [Loki Config Guide](docs/loki-config-guide.md)

## Support

For issues or questions:
1. Check container logs: `docker logs <container-name>`
2. Verify configuration: `./scripts/validate-config.sh`
3. Review documentation in `docs/` directory
