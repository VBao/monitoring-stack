# Quick Configuration Reference

This guide provides quick reference for common configuration changes across the monitoring stack.

## 🚀 Common Configuration Tasks

### 1. Change Data Retention

**Prometheus (7 days → 30 days):**
```yaml
# docker-compose.yml
services:
  prometheus:
    command:
      - "--storage.tsdb.retention.time=30d"
```

**Loki (7 days → 30 days):**
```yaml
# loki/loki-config.yaml
limits_config:
  retention_period: 720h  # 30 days
```

**Tempo (7 days → 30 days):**
```yaml
# tempo/tempo.yaml
compactor:
  compaction:
    block_retention: 720h  # 30 days
```

### 2. Increase Ingestion Limits

**High-volume log ingestion:**
```yaml
# loki/loki-config.yaml
limits_config:
  ingestion_rate_mb: 50          # Default: 4MB/s
  ingestion_burst_size_mb: 100   # Default: 6MB
  per_stream_rate_limit: 10MB    # Default: 3MB
  per_stream_rate_limit_burst: 20MB  # Default: 15MB
```

**Large trace ingestion:**
```yaml
# tempo/tempo.yaml
overrides:
  ingestion_rate_limit_bytes: 50000000    # 50MB/s (default: 15MB/s)
  ingestion_burst_size_bytes: 100000000   # 100MB (default: 20MB)
  max_bytes_per_trace: 100000000          # 100MB (default: 50MB)
```

**High-throughput metrics:**
```alloy
# alloy/config.alloy
otelcol.processor.batch "metrics" {
  timeout = "2s"
  send_batch_size = 2048      # Default: 1024
  send_batch_max_size = 4096  # Default: 2048
}
```

### 3. Configure External Storage

**Loki with S3:**
```yaml
# loki/loki-config.yaml
storage_config:
  aws:
    s3: s3://my-loki-bucket/chunks
    region: us-west-2
    access_key_id: ${AWS_ACCESS_KEY_ID}
    secret_access_key: ${AWS_SECRET_ACCESS_KEY}
```

**Tempo with S3:**
```yaml
# tempo/tempo.yaml
storage:
  trace:
    backend: s3
    s3:
      bucket: my-tempo-bucket
      region: us-west-2
      access_key: ${AWS_ACCESS_KEY_ID}
      secret_key: ${AWS_SECRET_ACCESS_KEY}
```

### 4. Enable Authentication

**Loki multi-tenancy:**
```yaml
# loki/loki-config.yaml
auth_enabled: true

# Add to docker-compose.yml environment
environment:
  - LOKI_AUTH_ENABLED=true
```

**Grafana security:**
```yaml
# docker-compose.yml
services:
  grafana:
    environment:
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_SECURITY_ADMIN_PASSWORD=your-secure-password
      - GF_SECURITY_SECRET_KEY=your-secret-key
```

### 5. Performance Tuning

**Memory-constrained environment:**
```yaml
# loki/loki-config.yaml
limits_config:
  max_streams_per_user: 1000      # Default: 10000
  max_entries_limit_per_query: 1000  # Default: 5000

ingester:
  chunk_idle_period: 30m          # Default: 5m
  max_chunk_age: 2h              # Default: 1h
```

**High-performance environment:**
```yaml
# tempo/tempo.yaml
ingester:
  max_block_bytes: 209715200     # 200MB (default: 100MB)
  max_block_duration: 30m        # Default: 10m

querier:
  max_concurrent_queries: 20     # Default: 10

query_frontend:
  max_outstanding_per_tenant: 4000  # Default: 2000
```

### 6. Configure TLS/Security

**Alloy with TLS:**
```alloy
# alloy/config.alloy
otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
    tls {
      cert_file = "/path/to/server.crt"
      key_file = "/path/to/server.key"
    }
  }
}
```

**Prometheus with basic auth:**
```yaml
# prometheus/prometheus.yml
scrape_configs:
  - job_name: "secure-app"
    static_configs:
      - targets: ["app:8080"]
    basic_auth:
      username: "monitoring"
      password: "secure-password"
```

### 7. Custom Labels and Processing

**Add custom labels in Alloy:**
```alloy
# alloy/config.alloy
loki.relabel "add_labels" {
  forward_to = [loki.write.default.receiver]
  
  rule {
    source_labels = ["__meta_docker_container_name"]
    target_label = "container"
  }
  
  rule {
    source_labels = ["__meta_docker_container_label_environment"]
    target_label = "env"
  }
}
```

**Prometheus relabeling:**
```yaml
# prometheus/prometheus.yml
scrape_configs:
  - job_name: "kubernetes-pods"
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: application
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
```

## 🔧 Validation Commands

Before applying changes, validate your configuration:

```bash
# Validate Docker Compose
docker-compose config

# Validate Alloy
docker run --rm -v $(pwd)/alloy:/etc/alloy grafana/alloy:latest fmt /etc/alloy/config.alloy

# Validate Prometheus
docker run --rm -v $(pwd)/prometheus:/etc/prometheus prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml

# Check Loki config
docker run --rm -v $(pwd)/loki:/etc/loki grafana/loki:latest -config.file=/etc/loki/loki-config.yaml -verify-config

# Check Tempo config
docker run --rm -v $(pwd)/tempo:/etc/tempo grafana/tempo:latest -config.file=/etc/tempo/tempo.yaml -verify-config
```

## 📊 Resource Sizing Guidelines

### Small Environment (Development)
- **Memory**: 2-4GB total
- **CPU**: 2-4 cores
- **Storage**: 10-50GB

```yaml
# docker-compose.yml resource limits
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '0.5'
```

### Medium Environment (Staging)
- **Memory**: 8-16GB total
- **CPU**: 4-8 cores
- **Storage**: 100-500GB

```yaml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
```

### Large Environment (Production)
- **Memory**: 32GB+ total
- **CPU**: 8+ cores
- **Storage**: 1TB+

```yaml
deploy:
  resources:
    limits:
      memory: 8G
      cpus: '2.0'
```

## 🚨 Common Gotchas

1. **Port Conflicts**: Ensure ports aren't already in use
2. **Memory Limits**: Set appropriate Docker memory limits
3. **File Permissions**: Check volume mount permissions
4. **Network Connectivity**: Verify inter-service communication
5. **Configuration Syntax**: Use proper YAML/Alloy syntax
6. **Resource Dependencies**: Start services in correct order

## 🔍 Quick Debugging

**Service not starting:**
```bash
docker-compose logs -f <service-name>
```

**Service health checks:**
```bash
curl http://localhost:3100/ready    # Loki
curl http://localhost:3200/ready    # Tempo  
curl http://localhost:9090/-/ready  # Prometheus
```

**Check data ingestion:**
```bash
# Alloy pipeline status
curl http://localhost:12345/metrics | grep -i "receiver\|processor\|exporter"

# Loki ingestion rate
curl http://localhost:3100/metrics | grep loki_distributor_ingester_appends_total

# Tempo ingestion rate  
curl http://localhost:3200/metrics | grep tempo_distributor_received_spans_total
```

---

For detailed configuration options, refer to the individual service guides in the `docs/` directory.
