# Prometheus Configuration Guide

## Overview

This document provides comprehensive documentation for the Prometheus configuration file (`prometheus.yml`) used in this monitoring stack. Prometheus is a time-series database and monitoring system that scrapes metrics from configured targets and stores them for querying and alerting.

## Configuration Structure

Prometheus configuration is written in YAML format and organized into several main sections:

```yaml
# Global configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alerting rules configuration
rule_files:
  - "rules.yml"

# Scraping configuration
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
```

## Data Types and Placeholders

Prometheus configuration uses specific data types:

- `<boolean>`: `true` or `false`
- `<duration>`: Duration string like `15s`, `1m`, `2h`, `1d`
- `<filename>`: Valid file path
- `<float>`: Floating-point number
- `<host>`: Hostname or IP with optional port (`hostname:port`)
- `<int>`: Integer value
- `<string>`: String value

## Section-by-Section Configuration

### 1. Global Configuration

```yaml
global:
  scrape_interval: 5s   # Optimized for fast metrics collection
  evaluation_interval: 5s  # Optimized for fast alerting
  scrape_timeout: 5s    # Keep timeout reasonable
```

**Purpose**: Sets default values for all jobs and evaluation intervals

**Configuration Parameters**:
- `scrape_interval`: Default interval for scraping targets
  - **Current**: `5s` (optimized for real-time monitoring)
  - **Default**: `15s`
  - **Valid Range**: `1s` to `1h`
  - **Format**: Duration string (`10s`, `1m`, `5m`)
  - **Performance**: Shorter intervals = more data points, higher load
  - **Use Case**: Fast intervals support 1-minute rate calculations

- `evaluation_interval`: How often to evaluate alerting rules
  - **Current**: `5s` (optimized for fast alerting)
  - **Default**: `15s`
  - **Valid Range**: `1s` to `1h`
  - **Format**: Duration string
  - **Alerting**: Affects alert responsiveness
  - **Recommendation**: Same as or multiple of `scrape_interval`

- `scrape_timeout`: Default timeout for scrape requests
  - **Current**: `5s` (balanced for fast scraping)
  - **Default**: `10s`
  - **Valid Range**: `1s` to `scrape_interval`
  - **Rule**: Must be less than `scrape_interval`
  - **Network Impact**: Adjust based on network latency

**External Labels** (commented):
```yaml
# external_labels:
#   cluster: "monitoring-stack"
#   environment: "development"
```
- **Purpose**: Labels added to all metrics when communicating with federation
- **Use Cases**: Multi-cluster setups, remote storage
- **Format**: Key-value pairs

### 2. Rule Files Configuration

```yaml
rule_files:
  - "alert_rules.yml"
  - "recording_rules.yml"
```

**Purpose**: Specifies files containing alerting and recording rules

**Configuration Parameters**:
- `rule_files`: List of rule file paths
  - **Format**: Array of file paths
  - **Paths**: Relative to Prometheus configuration directory
  - **Wildcards**: Supports glob patterns (`rules/*.yml`)
  - **Validation**: Files are validated at startup

**Rule File Example**:
```yaml
# alert_rules.yml
groups:
  - name: basic.rules
    rules:
      - alert: HighCPUUsage
        expr: cpu_usage > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
```

### 3. Scrape Configurations

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
    metrics_path: "/metrics"
    scrape_interval: 15s
```

**Purpose**: Defines what targets to scrape and how

**Job Configuration Parameters**:

#### Basic Parameters
- `job_name`: Unique name for the scrape job
  - **Format**: String (no spaces, use underscores/hyphens)
  - **Purpose**: Added as `job` label to all metrics
  - **Required**: Yes
  - **Example**: `"prometheus"`, `"node-exporter"`, `"api-server"`

- `metrics_path`: HTTP path to scrape metrics from
  - **Default**: `"/metrics"`
  - **Format**: URL path string
  - **Common Paths**: `"/metrics"`, `"/actuator/prometheus"`, `"/api/v1/metrics"`

- `scrape_interval`: Override global scrape interval
  - **Format**: Duration string
  - **Override**: Overrides global `scrape_interval`
  - **Use Case**: Different intervals for different services

- `scrape_timeout`: Override global scrape timeout
  - **Format**: Duration string
  - **Rule**: Must be less than `scrape_interval`

#### Target Discovery

##### Static Configuration
```yaml
scrape_configs:
  - job_name: "alloy"
    static_configs:
      - targets: ["alloy:12345"]
        labels:
          service: "alloy"
          environment: "dev"
```

**Parameters**:
- `static_configs.targets`: List of `host:port` endpoints
  - **Format**: Array of `"hostname:port"` strings
  - **Examples**: `["localhost:9090"]`, `["service1:8080", "service2:8080"]`
  - **DNS**: Hostnames are resolved at scrape time

- `static_configs.labels`: Additional labels for targets
  - **Format**: Key-value pairs
  - **Purpose**: Add custom labels to metrics
  - **Override**: Can override job-level labels

##### Service Discovery (Examples)

**DNS Service Discovery**:
```yaml
scrape_configs:
  - job_name: "dns-discovery"
    dns_sd_configs:
      - names: ["_metrics._tcp.example.com"]
        type: SRV
        port: 9090
```

**File-based Service Discovery**:
```yaml
scrape_configs:
  - job_name: "file-discovery"
    file_sd_configs:
      - files: ["targets.json"]
        refresh_interval: 30s
```

**Kubernetes Service Discovery**:
```yaml
scrape_configs:
  - job_name: "kubernetes-pods"
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

#### Relabeling Configuration

```yaml
scrape_configs:
  - job_name: "alloy"
    static_configs:
      - targets: ["alloy:12345"]
    relabel_configs:
      - target_label: service
        replacement: alloy
```

**Purpose**: Modify, add, or remove labels before scraping

**Relabel Actions**:
- `replace`: Replace target label with value (default)
- `keep`: Keep targets matching regex
- `drop`: Drop targets matching regex
- `labelmap`: Map label names using regex
- `labeldrop`: Drop labels matching regex
- `labelkeep`: Keep labels matching regex

**Common Relabel Patterns**:
```yaml
relabel_configs:
  # Add custom label
  - target_label: service
    replacement: my-service
  
  # Extract from existing label
  - source_labels: [__meta_kubernetes_pod_name]
    target_label: pod_name
  
  # Keep targets with specific label
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    action: keep
    regex: true
  
  # Drop metrics with specific labels
  - source_labels: [__name__]
    action: drop
    regex: "debug_.*"
```

#### Metric Relabeling

```yaml
scrape_configs:
  - job_name: "example"
    static_configs:
      - targets: ["example:9090"]
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "debug_.*"
        action: drop
```

**Purpose**: Modify labels after scraping but before storage

**Use Cases**:
- Drop unwanted metrics
- Rename metric labels
- Add computed labels
- Filter high-cardinality metrics

#### HTTP Configuration

```yaml
scrape_configs:
  - job_name: "secure-service"
    static_configs:
      - targets: ["secure.example.com:443"]
    scheme: https
    tls_config:
      cert_file: client.crt
      key_file: client.key
      ca_file: ca.crt
      insecure_skip_verify: false
    basic_auth:
      username: admin
      password: secret
```

**HTTP Parameters**:
- `scheme`: HTTP scheme (`http` or `https`)
  - **Default**: `http`
  - **Security**: Use `https` for production

- `tls_config`: TLS configuration for HTTPS
  - `cert_file`: Client certificate file
  - `key_file`: Client private key file
  - `ca_file`: CA certificate file
  - `insecure_skip_verify`: Skip TLS verification (dangerous)

- `basic_auth`: HTTP Basic Authentication
  - `username`: Username for authentication
  - `password`: Password (consider using `password_file`)

- `bearer_token`: Bearer token for authentication
- `bearer_token_file`: File containing bearer token

- `proxy_url`: HTTP proxy URL
- `follow_redirects`: Follow HTTP redirects (default: true)

### 4. Sample Scrape Configurations

#### Current Configuration Analysis

```yaml
scrape_configs:
  - job_name: "alloy"
    static_configs:
      - targets: ["alloy:12345"]
    metrics_path: "/metrics"
    scrape_interval: 10s
    relabel_configs:
      - target_label: service
        replacement: alloy
```

**Analysis**:
- **Purpose**: Scrapes Alloy's own metrics
- **Endpoint**: `http://alloy:12345/metrics`
- **Frequency**: Every 10 seconds
- **Labels**: Adds `service="alloy"` label

```yaml
  - job_name: "alloy-otel-metrics"
    static_configs:
      - targets: ["alloy:9999"]
    metrics_path: "/metrics"
    scrape_interval: 10s
    relabel_configs:
      - target_label: service
        replacement: otel-metrics
```

**Analysis**:
- **Purpose**: Scrapes OTLP metrics exposed by Alloy
- **Endpoint**: `http://alloy:9999/metrics`
- **Different Port**: Separates Alloy internals from OTLP metrics

```yaml
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
    relabel_configs:
      - target_label: service
        replacement: prometheus
```

**Analysis**:
- **Purpose**: Scrapes Prometheus's own metrics
- **Self-monitoring**: Essential for monitoring Prometheus health
- **Localhost**: Uses localhost since it's scraping itself

#### Additional Service Monitoring

```yaml
  - job_name: "tempo"
    static_configs:
      - targets: ["tempo:3200"]
    metrics_path: "/metrics"
    scrape_interval: 15s
    relabel_configs:
      - target_label: service
        replacement: tempo
```

**Purpose**: Monitors Tempo tracing backend

```yaml
  - job_name: "loki"
    static_configs:
      - targets: ["loki:3100"]
    metrics_path: "/metrics"
    scrape_interval: 15s
    relabel_configs:
      - target_label: service
        replacement: loki
```

**Purpose**: Monitors Loki logging backend

```yaml
  - job_name: "grafana"
    static_configs:
      - targets: ["grafana:3000"]
    metrics_path: "/metrics"
    scrape_interval: 30s
    relabel_configs:
      - target_label: service
        replacement: grafana
```

**Purpose**: Monitors Grafana dashboarding service

## Current Optimized Configuration

The monitoring stack is currently configured with optimized settings for fast metrics collection and 1-minute rate calculations:

```yaml
# Current scrape_configs (optimized for speed)
scrape_configs:
  - job_name: "alloy"
    static_configs:
      - targets: ["alloy:12345"]
    metrics_path: "/metrics"
    scrape_interval: 5s  # Fast scraping for real-time monitoring
    relabel_configs:
      - target_label: service
        replacement: alloy

  - job_name: "otel-metrics"
    static_configs:
      - targets: ["alloy:9999"]
    metrics_path: "/metrics"
    scrape_interval: 5s  # Fast scraping for OTLP metrics
    relabel_configs:
      - target_label: service
        replacement: otel-collector

  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
    scrape_interval: 10s  # Moderate scraping for Prometheus itself
    relabel_configs:
      - target_label: service
        replacement: prometheus

  - job_name: "tempo"
    static_configs:
      - targets: ["tempo:3200"]
    metrics_path: "/metrics"
    scrape_interval: 15s  # Standard scraping for Tempo
    relabel_configs:
      - target_label: service
        replacement: tempo

  - job_name: "loki"
    static_configs:
      - targets: ["loki:3100"]
    metrics_path: "/metrics"
    scrape_interval: 15s  # Standard scraping for Loki
    relabel_configs:
      - target_label: service
        replacement: loki
```

**Key Optimizations**:
- **Alloy Metrics**: 5s intervals for real-time pipeline monitoring
- **OTLP Metrics**: 5s intervals for fast telemetry data processing
- **Core Services**: 10-15s intervals balancing performance and load
- **Service Labels**: Consistent labeling across all jobs for better querying

## Advanced Configuration

### Remote Write Configuration

```yaml
remote_write:
  - url: "https://prometheus-remote.example.com/api/v1/write"
    queue_config:
      max_samples_per_send: 1000
      max_shards: 200
      capacity: 2500
    write_relabel_configs:
      - source_labels: [__name__]
        regex: "debug_.*"
        action: drop
```

**Purpose**: Send metrics to remote Prometheus instances

**Parameters**:
- `url`: Remote write endpoint URL
- `queue_config`: Queue configuration for batching
- `write_relabel_configs`: Filter/modify metrics before sending

### Remote Read Configuration

```yaml
remote_read:
  - url: "https://prometheus-remote.example.com/api/v1/read"
    read_recent: true
```

**Purpose**: Read metrics from remote Prometheus instances

### Alertmanager Configuration

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]
```

**Purpose**: Configure Alertmanager endpoints for sending alerts

## Performance Tuning

### High-Volume Environments

```yaml
global:
  scrape_interval: 30s
  evaluation_interval: 30s

# Use longer intervals for non-critical services
scrape_configs:
  - job_name: "batch-jobs"
    static_configs:
      - targets: ["batch:8080"]
    scrape_interval: 60s
```

### Low-Latency Monitoring

```yaml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

# Critical services with frequent scraping
scrape_configs:
  - job_name: "critical-api"
    static_configs:
      - targets: ["api:8080"]
    scrape_interval: 5s
```

### Memory Optimization

```yaml
# Drop high-cardinality metrics
scrape_configs:
  - job_name: "application"
    static_configs:
      - targets: ["app:8080"]
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "histogram_.*_bucket"
        action: drop
      - source_labels: [cardinality]
        regex: "high"
        action: drop
```

## Security Configuration

### TLS Configuration

```yaml
scrape_configs:
  - job_name: "secure-service"
    static_configs:
      - targets: ["secure.example.com:443"]
    scheme: https
    tls_config:
      cert_file: /etc/prometheus/client.crt
      key_file: /etc/prometheus/client.key
      ca_file: /etc/prometheus/ca.crt
      server_name: secure.example.com
      insecure_skip_verify: false
```

### Authentication

```yaml
scrape_configs:
  - job_name: "authenticated-service"
    static_configs:
      - targets: ["auth.example.com:8080"]
    basic_auth:
      username: prometheus
      password_file: /etc/prometheus/password
    # OR
    bearer_token_file: /etc/prometheus/token
```

## Service Discovery Examples

### Docker Service Discovery

```yaml
scrape_configs:
  - job_name: "docker"
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        port: 9100
    relabel_configs:
      - source_labels: [__meta_docker_container_label_prometheus_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_docker_container_name]
        target_label: container_name
```

### Consul Service Discovery

```yaml
scrape_configs:
  - job_name: "consul"
    consul_sd_configs:
      - server: "consul.example.com:8500"
        services: ["web", "api", "database"]
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: service
```

## Troubleshooting

### Common Configuration Errors

1. **Invalid YAML Syntax**
   ```bash
   # Validate YAML
   promtool check config prometheus.yml
   ```

2. **Scrape Target Issues**
   ```bash
   # Check target status
   curl http://localhost:9090/api/v1/targets
   ```

3. **Rule Validation**
   ```bash
   # Validate rules
   promtool check rules alert_rules.yml
   ```

### Debug Configuration

```yaml
global:
  external_labels:
    debug: "true"

# Add debug job
scrape_configs:
  - job_name: "debug"
    static_configs:
      - targets: ["localhost:9090"]
    scrape_interval: 5s
    metrics_path: "/debug/metrics"
```

### Performance Monitoring

Monitor these Prometheus metrics:
- `prometheus_tsdb_symbol_table_size_bytes`: Memory usage
- `prometheus_config_last_reload_successful`: Configuration status
- `prometheus_rule_evaluation_duration_seconds`: Rule evaluation time
- `prometheus_tsdb_compactions_total`: Storage compaction

## Best Practices

### Configuration Organization

1. **Job Naming**: Use descriptive, consistent job names
2. **Service Labels**: Add service labels for identification
3. **Interval Planning**: Choose appropriate scrape intervals
4. **Label Management**: Avoid high-cardinality labels
5. **Rule Organization**: Group related rules together

### Performance Optimization

1. **Scrape Intervals**: Balance freshness vs. load
2. **Metric Filtering**: Drop unnecessary metrics
3. **Target Grouping**: Group similar targets
4. **Storage Planning**: Plan for metric retention
5. **Resource Monitoring**: Monitor Prometheus resources

### Security Considerations

1. **TLS Configuration**: Use TLS for production
2. **Authentication**: Implement proper authentication
3. **Network Security**: Secure Prometheus network access
4. **Secret Management**: Use files for sensitive data
5. **Access Control**: Limit configuration access

## Configuration Validation

### Syntax Validation
```bash
# Check configuration syntax
promtool check config prometheus.yml

# Check rules syntax
promtool check rules rules/*.yml

# Query validation
promtool query instant http://localhost:9090 'up'
```

### Runtime Validation
```bash
# Reload configuration
curl -X POST http://localhost:9090/-/reload

# Check configuration via API
curl http://localhost:9090/api/v1/status/config

# Check build info
curl http://localhost:9090/api/v1/status/buildinfo
```

## Migration and Upgrades

### Version Compatibility
- Check Prometheus release notes for breaking changes
- Test configuration changes in staging
- Plan for storage format changes

### Configuration Migration
```bash
# Backup configuration
cp prometheus.yml prometheus.yml.backup

# Validate after changes
promtool check config prometheus.yml

# Test with new configuration
prometheus --config.file=prometheus.yml --web.listen-address=:9091
```

## References

- [Prometheus Configuration Documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Prometheus Operator Guide](https://prometheus.io/docs/guides/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
