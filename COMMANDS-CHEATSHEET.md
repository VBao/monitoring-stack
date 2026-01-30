# Host Monitoring Commands Cheatsheet

Quick reference for common commands and operations.

## Starting Services

```bash
# Quick start (Linux/macOS)
./start-host-monitoring.sh

# Quick start (Windows)
start-host-monitoring.bat

# Manual start with both compose files
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml up -d

# Start only main stack
docker-compose up -d

# Start only host monitoring
docker-compose -f docker-compose.host-monitoring.yml up -d
```

## Stopping Services

```bash
# Stop everything
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml down

# Stop and remove volumes (CAREFUL!)
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml down -v

# Stop only host monitoring
docker-compose -f docker-compose.host-monitoring.yml down
```

## Viewing Logs

```bash
# All services
docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml logs -f

# Specific service
docker logs -f node-exporter
docker logs -f promtail
docker logs -f cadvisor

# Last 100 lines
docker logs --tail 100 node-exporter
```

## Service Management

```bash
# Restart a service
docker restart node-exporter
docker restart promtail
docker restart cadvisor

# Check service status
docker ps | grep -E "node-exporter|promtail|cadvisor"

# View service details
docker inspect node-exporter
```

## Validation & Testing

```bash
# Run validation script
./scripts/validate-host-monitoring.sh

# Test endpoints manually
curl http://localhost:9100/metrics          # Node Exporter
curl http://localhost:8080/metrics          # cAdvisor
curl http://localhost:9080/ready            # Promtail
curl http://localhost:9090/api/v1/targets   # Prometheus targets
curl http://localhost:3100/ready            # Loki
```

## Prometheus Queries

```bash
# Query CPU usage
curl -s 'http://localhost:9090/api/v1/query?query=100-(avg(irate(node_cpu_seconds_total{mode="idle"}[5m]))*100)' | jq

# Query memory usage
curl -s 'http://localhost:9090/api/v1/query?query=node_memory_MemTotal_bytes' | jq

# List all metrics
curl -s http://localhost:9090/api/v1/label/__name__/values | jq
```

## Loki Queries

```bash
# Query system logs (last 10 minutes)
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="syslog"}' \
  --data-urlencode "start=$(date -d '10 minutes ago' +%s)000000000" \
  --data-urlencode "end=$(date +%s)000000000" | jq

# List available labels
curl -s http://localhost:3100/loki/api/v1/labels | jq

# List values for a label
curl -s http://localhost:3100/loki/api/v1/label/job/values | jq
```

## Container Resource Usage

```bash
# View resource usage
docker stats node-exporter promtail cadvisor

# View resource limits
docker inspect node-exporter | jq '.[0].HostConfig.Memory'
docker inspect cadvisor | jq '.[0].HostConfig.Privileged'
```

## Network Debugging

```bash
# Check port bindings
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Test network connectivity between containers
docker exec node-exporter ping -c 3 prometheus
docker exec promtail wget -q -O- http://loki:3100/ready
```

## File System & Volumes

```bash
# List volumes
docker volume ls | grep monitoring

# Inspect volume
docker volume inspect prometheus-data

# Check disk usage
docker system df
docker system df -v
```

## Configuration Management

```bash
# Validate Docker Compose files
docker-compose -f docker-compose.yml config
docker-compose -f docker-compose.host-monitoring.yml config

# View active configuration
docker exec promtail cat /etc/promtail/config.yaml
docker inspect node-exporter --format='{{.Args}}'
```

## Troubleshooting

```bash
# Check if Docker is running
docker info

# Check network
docker network ls
docker network inspect monitoring

# Remove and recreate network
docker network rm monitoring
docker network create monitoring

# Force recreate services
docker-compose -f docker-compose.host-monitoring.yml up -d --force-recreate

# Clean up stopped containers
docker container prune -f

# Clean up unused images
docker image prune -a
```

## Performance & Monitoring

```bash
# Check Prometheus scrape targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job | contains("node")) | {job: .labels.job, health: .health, lastError: .lastError}'

# Check metrics cardinality
curl -s http://localhost:9090/api/v1/status/tsdb | jq

# Check Loki metrics
curl -s http://localhost:3100/metrics | grep loki_ingester
```

## Grafana Management

```bash
# Access Grafana API
curl -u admin:admin http://localhost:3002/api/health

# List dashboards
curl -s -u admin:admin http://localhost:3002/api/search | jq

# Get specific dashboard
curl -s -u admin:admin http://localhost:3002/api/dashboards/uid/host-monitoring | jq
```

## Backup & Restore

```bash
# Backup Prometheus data
docker run --rm -v prometheus-data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz /data

# Backup Loki data
docker run --rm -v loki-data:/data -v $(pwd):/backup alpine tar czf /backup/loki-backup.tar.gz /data

# Backup Grafana dashboards
cp -r grafana/dashboards/ dashboards-backup/
```

## Update Services

```bash
# Pull latest images
docker-compose -f docker-compose.host-monitoring.yml pull

# Recreate with new images
docker-compose -f docker-compose.host-monitoring.yml up -d --force-recreate

# Update specific service
docker pull prom/node-exporter:latest
docker-compose -f docker-compose.host-monitoring.yml up -d node-exporter
```

## URLs Quick Reference

```
Grafana:         http://localhost:3002
Prometheus:      http://localhost:9090
Prometheus API:  http://localhost:9090/api/v1/
Loki:            http://localhost:3100
Loki API:        http://localhost:3100/loki/api/v1/
Alloy:           http://localhost:12345
Node Exporter:   http://localhost:9100
cAdvisor:        http://localhost:8080
Promtail:        http://localhost:9080
Pyroscope:       http://localhost:4040
```

## Common Issues & Fixes

```bash
# Issue: Port already in use
# Fix: Find and kill process
netstat -tuln | grep 9100
lsof -i :9100
kill -9 <PID>

# Issue: Permission denied for Docker socket
# Fix: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Issue: Node Exporter not showing metrics
# Fix: Check if running with host PID namespace
docker inspect node-exporter | grep PidMode

# Issue: Promtail can't read logs
# Fix: Check file permissions
ls -la /var/log/syslog
# Ensure promtail container can read it

# Issue: cAdvisor not showing containers
# Fix: Ensure it's running in privileged mode
docker inspect cadvisor | grep Privileged
```

## Environment Variables

```bash
# Set custom hostname for logs
export HOSTNAME=my-server

# Use in Promtail
docker-compose -f docker-compose.host-monitoring.yml up -d
```

## Advanced Operations

```bash
# Export metrics for analysis
curl -s http://localhost:9100/metrics > node_metrics.txt

# Count unique metric names
curl -s http://localhost:9100/metrics | grep -v '^#' | cut -d'{' -f1 | cut -d' ' -f1 | sort -u | wc -l

# Find specific metrics
curl -s http://localhost:9100/metrics | grep cpu

# Live tail container logs
docker logs -f --tail 50 promtail 2>&1 | grep -i error
```

## Automation Scripts

```bash
# Auto-restart on failure
docker update --restart=unless-stopped node-exporter promtail cadvisor

# Health check loop
while true; do
  curl -sf http://localhost:9100/metrics > /dev/null && echo "OK" || echo "FAIL"
  sleep 30
done
```

---

**Pro Tip**: Create aliases in `~/.bashrc` or `~/.zshrc`:

```bash
alias mon-start='cd /path/to/monitoring && ./start-host-monitoring.sh'
alias mon-stop='cd /path/to/monitoring && docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml down'
alias mon-logs='cd /path/to/monitoring && docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml logs -f'
alias mon-validate='cd /path/to/monitoring && ./scripts/validate-host-monitoring.sh'
```
