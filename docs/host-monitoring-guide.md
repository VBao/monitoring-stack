# Host Monitoring Guide

## Overview

This guide explains how to set up and use the host monitoring capabilities of your monitoring stack. Host monitoring provides deep insights into the physical or virtual machine running your services.

## Architecture

The host monitoring solution consists of several specialized components:

```
┌─────────────────────────────────────────────────────────────┐
│                       Host Machine                          │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Node Exporter│  │   Promtail   │  │   cAdvisor   │    │
│  │              │  │              │  │              │    │
│  │ - CPU        │  │ - Syslog     │  │ - Container  │    │
│  │ - Memory     │  │ - Auth logs  │  │   CPU/Memory │    │
│  │ - Disk       │  │ - Kernel     │  │ - Container  │    │
│  │ - Network    │  │ - Docker     │  │   Network    │    │
│  │ - Load       │  │ - App logs   │  │ - Container  │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │            │
│         └──────────────────┼──────────────────┘            │
│                            │                               │
└────────────────────────────┼───────────────────────────────┘
                             │
                   ┌─────────▼──────────┐
                   │   Grafana Alloy    │
                   │  (Data Pipeline)   │
                   └─────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼─────┐   ┌───▼────┐   ┌────▼─────┐
         │Prometheus│   │  Loki  │   │  Tempo   │
         │ (Metrics)│   │ (Logs) │   │ (Traces) │
         └────┬─────┘   └───┬────┘   └────┬─────┘
              │             │             │
              └─────────────┼─────────────┘
                            │
                      ┌─────▼──────┐
                      │  Grafana   │
                      │ (Dashboard)│
                      └────────────┘
```

## Components

### 1. Node Exporter
**Purpose**: Collects host-level metrics

**Metrics Collected**:
- CPU usage (total, per-core, by mode)
- Memory usage (total, available, cached, buffers)
- Disk usage and I/O statistics
- Network traffic and errors
- System load averages
- Process statistics
- Filesystem usage
- System uptime

**Port**: 9100
**Endpoint**: http://localhost:9100/metrics

### 2. Promtail
**Purpose**: Collects and forwards host logs to Loki

**Logs Collected**:
- System logs (`/var/log/syslog`)
- Authentication logs (`/var/log/auth.log`)
- Kernel logs (`/var/log/kern.log`)
- Docker container logs
- Application logs
- Web server logs (nginx/apache)

**Port**: 9080
**Configuration**: `stack/promtail/promtail-config.yaml`

### 3. cAdvisor
**Purpose**: Monitors container resource usage

**Metrics Collected**:
- Per-container CPU usage
- Per-container memory usage
- Per-container network I/O
- Per-container disk I/O
- Container filesystem usage

**Port**: 8080
**UI**: http://localhost:8080

## Installation

### Quick Start

#### Linux/macOS:
```bash
./start-host-monitoring.sh
```

#### Windows:
```batch
start-host-monitoring.bat
```

### Manual Start

```bash
# Start main monitoring stack
docker-compose -f docker-compose.yml up -d

# Start host monitoring extensions
docker-compose -f docker-compose.host-monitoring.yml up -d
```

### Combined Command

```bash
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml up -d
```

## Configuration

### Node Exporter Configuration

Node Exporter is configured via command-line flags in `docker-compose.host-monitoring.yml`:

```yaml
command:
  - '--path.rootfs=/host'
  - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
  - '--collector.cpu'
  - '--collector.meminfo'
  - '--collector.diskstats'
  # ... more collectors
```

**Key Collectors**:
- `cpu` - CPU statistics
- `meminfo` - Memory information
- `diskstats` - Disk I/O statistics
- `filesystem` - Filesystem usage
- `netdev` - Network device statistics
- `loadavg` - System load
- `systemd` - Systemd service status

### Promtail Configuration

Edit `stack/promtail/promtail-config.yaml` to customize log collection:

```yaml
scrape_configs:
  - job_name: syslog
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          host: ${HOSTNAME}
          __path__: /var/log/syslog
```

**Adding Custom Log Sources**:

```yaml
  - job_name: my_app
    static_configs:
      - targets:
          - localhost
        labels:
          job: my_app
          environment: production
          __path__: /var/log/my_app/*.log
```

### cAdvisor Configuration

cAdvisor is configured to monitor Docker containers only:

```yaml
command:
  - '--docker_only=true'
  - '--housekeeping_interval=10s'
```

## Dashboards

### Host System Monitoring Dashboard

Located at: `stack/grafana/dashboards/host-monitoring.json`

**Panels**:
1. **CPU Usage** - Gauge showing current CPU usage
2. **Memory Usage** - Gauge showing current memory usage
3. **Disk Usage** - Gauge showing root filesystem usage
4. **System Load** - 1m, 5m, 15m load averages
5. **CPU Usage Over Time** - Time series of CPU metrics
6. **Memory Usage Over Time** - Time series of memory metrics
7. **Network I/O** - Network traffic in/out
8. **Disk I/O** - Disk read/write operations
9. **Container CPU Usage** - Per-container CPU usage
10. **Container Memory Usage** - Per-container memory usage
11. **System Logs** - Recent system logs from Loki

### Accessing Dashboards

1. Open Grafana: http://localhost:3002
2. Login with `admin` / `admin`
3. Navigate to **Dashboards** → **Host System Monitoring**

## Useful Queries

### Prometheus Queries (PromQL)

**CPU Usage**:
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory Usage**:
```promql
100 * (1 - ((node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes))
```

**Disk Usage**:
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!="rootfs"} * 100) / node_filesystem_size_bytes{mountpoint="/",fstype!="rootfs"})
```

**Network Traffic**:
```promql
irate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m])
```

**Container CPU**:
```promql
sum by (name) (rate(container_cpu_usage_seconds_total{image!=""}[5m]) * 100)
```

### Loki Queries (LogQL)

**System Logs**:
```logql
{job="syslog"}
```

**Error Logs**:
```logql
{job=~"syslog|auth"} |~ "error|ERROR|fail|FAIL"
```

**Docker Container Logs**:
```logql
{compose_project="monitoring"} | json
```

**Logs with Trace Correlation**:
```logql
{job="syslog"} | json | traceid != ""
```

## Alerting

### Example Alert Rules

Add to `stack/prometheus/prometheus.yml`:

```yaml
groups:
  - name: host_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for 5 minutes"

      - alert: HighMemoryUsage
        expr: 100 * (1 - ((node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes)) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85% for 5 minutes"

      - alert: DiskSpaceLow
        expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!="rootfs"} * 100) / node_filesystem_size_bytes{mountpoint="/",fstype!="rootfs"}) > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space low"
          description: "Disk usage is above 90%"
```

## Troubleshooting

### Node Exporter Not Showing Metrics

**Check if service is running**:
```bash
docker ps | grep node-exporter
```

**Check logs**:
```bash
docker logs node-exporter
```

**Test metrics endpoint**:
```bash
curl http://localhost:9100/metrics
```

### Promtail Not Collecting Logs

**Check configuration**:
```bash
docker exec promtail cat /etc/promtail/config.yaml
```

**Check logs**:
```bash
docker logs promtail
```

**Verify Loki connection**:
```bash
docker exec promtail wget -O- http://loki:3100/ready
```

### cAdvisor Not Showing Container Metrics

**Ensure proper permissions**:
```bash
docker inspect cadvisor | grep Privileged
# Should show "Privileged": true
```

**Check metrics**:
```bash
curl http://localhost:8080/metrics | grep container_cpu
```

## Windows-Specific Monitoring

For Windows hosts, replace Node Exporter with Windows Exporter:

Uncomment in `docker-compose.host-monitoring.yml`:

```yaml
windows-exporter:
  image: ghcr.io/prometheus-community/windows-exporter:latest
  container_name: windows-exporter
  restart: unless-stopped
  ports:
    - "9182:9182"
  networks:
    - monitoring
  labels:
    - "monitoring.scrape=true"
    - "monitoring.port=9182"
    - "monitoring.path=/metrics"
```

Update Alloy config to scrape Windows Exporter on port 9182.

## Performance Considerations

### Resource Usage

Typical resource consumption:
- **Node Exporter**: ~10MB RAM, negligible CPU
- **Promtail**: ~50-100MB RAM, low CPU
- **cAdvisor**: ~100-200MB RAM, 1-2% CPU

### Retention

Configured retention periods:
- **Prometheus**: 7 days (configured in `docker-compose.yml`)
- **Loki**: 30 days (configured in `stack/loki/loki-config.yaml`)

### Optimization Tips

1. **Reduce scrape frequency** for less critical metrics
2. **Filter unnecessary metrics** using metric_relabel_configs
3. **Limit log collection** to essential sources
4. **Use metric aggregation** for high-cardinality data

## Best Practices

1. **Regular Monitoring**: Check dashboards daily
2. **Set Alerts**: Configure alerts for critical thresholds
3. **Log Rotation**: Ensure host log rotation is configured
4. **Backup Configuration**: Version control all config files
5. **Security**: Restrict access to monitoring endpoints
6. **Capacity Planning**: Monitor trends for resource planning

## Next Steps

1. Customize dashboards for your specific needs
2. Set up alerting rules
3. Integrate with notification channels (Slack, PagerDuty)
4. Add custom exporters for application-specific metrics
5. Configure long-term storage for metrics (Mimir, Cortex)

## References

- [Node Exporter Documentation](https://github.com/prometheus/node_exporter)
- [Promtail Documentation](https://grafana.com/docs/loki/latest/clients/promtail/)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Prometheus Querying](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
