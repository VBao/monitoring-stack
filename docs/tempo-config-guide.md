# Grafana Tempo Configuration Guide

## Overview

This document provides comprehensive documentation for the Grafana Tempo configuration file (`tempo.yaml`) used in this monitoring stack. Tempo is a distributed tracing backend that stores and queries traces. It integrates with Grafana to provide distributed tracing capabilities.

## Configuration Structure

Tempo configuration is written in YAML format and organized into several main sections:

```yaml
# Server configuration
server:
  http_listen_port: 3200

# Trace distribution
distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

# Trace ingestion
ingester:
  max_block_duration: 10m

# Trace storage
storage:
  trace:
    backend: local

# Metrics generation
metrics_generator:
  registry:
    collection_interval: 15s
```

## Section-by-Section Configuration

### 1. Server Configuration

```yaml
server:
  http_listen_port: 3200
  grpc_server_max_recv_msg_size: 4194304
  grpc_server_max_send_msg_size: 4194304
```

**Purpose**: Configures the HTTP and gRPC server settings

**Configuration Parameters**:
- `http_listen_port`: HTTP API port for queries and health checks
  - **Default**: `3200`
  - **Valid Range**: `1024-65535`
  - **Usage**: Grafana connects to this port
  - **Health Check**: Available at `/ready` and `/metrics`

- `grpc_server_max_recv_msg_size`: Maximum gRPC receive message size
  - **Default**: `4194304` (4MB)
  - **Format**: Bytes as integer
  - **Valid Range**: `1048576` (1MB) to `67108864` (64MB)
  - **Purpose**: Limits incoming trace size
  - **Large Traces**: Increase if you have very large traces

- `grpc_server_max_send_msg_size`: Maximum gRPC send message size
  - **Default**: `4194304` (4MB)
  - **Format**: Bytes as integer
  - **Valid Range**: `1048576` (1MB) to `67108864` (64MB)
  - **Purpose**: Limits outgoing trace responses
  - **Large Queries**: Increase for large trace responses

**Additional Server Options** (commented in config):
```yaml
# log_level: info                    # Log verbosity: debug, info, warn, error
# log_format: logfmt                 # Log format: logfmt or json
# grpc_listen_port: 9095             # Separate gRPC port if needed
# http_server_read_timeout: 30s      # HTTP read timeout
# http_server_write_timeout: 30s     # HTTP write timeout
```

### 2. Distributor Configuration

```yaml
distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318

  ring:
    heartbeat_timeout: 1m
```

**Purpose**: Configures trace reception and distribution

**Configuration Parameters**:
- `receivers.otlp.protocols.grpc`: OTLP gRPC receiver
  - **Default Endpoint**: `0.0.0.0:4317`
  - **Format**: `"IP:PORT"`
  - **Standard Port**: `4317` (OTLP gRPC)
  - **Security**: Use specific IP instead of `0.0.0.0` in production

- `receivers.otlp.protocols.http`: OTLP HTTP receiver
  - **Default Endpoint**: `0.0.0.0:4318`
  - **Format**: `"IP:PORT"`
  - **Standard Port**: `4318` (OTLP HTTP)
  - **Protocol**: Accepts HTTP/1.1 and HTTP/2

- `ring.heartbeat_timeout`: Distributor ring heartbeat timeout
  - **Default**: `1m`
  - **Valid Range**: `30s` to `5m`
  - **Purpose**: Detects failed distributors
  - **Cluster Health**: Affects failure detection time

**Additional Receivers** (commented):
```yaml
# jaeger:                              # Jaeger protocol support
#   protocols:
#     grpc:
#       endpoint: 0.0.0.0:14250
#     thrift_http:
#       endpoint: 0.0.0.0:14268
# zipkin:
#   endpoint: 0.0.0.0:9411            # Zipkin HTTP endpoint
```

### 3. Ingester Configuration

```yaml
ingester:
  max_block_duration: 10m
  max_block_bytes: 104857600
  trace_idle_period: 30s

  lifecycler:
    ring:
      replication_factor: 1
```

**Purpose**: Configures trace ingestion and block creation

**Configuration Parameters**:
- `max_block_duration`: Maximum time before flushing block to storage
  - **Default**: `10m`
  - **Valid Range**: `1m` to `60m`
  - **Trade-off**: Shorter = more blocks, Longer = fewer blocks
  - **Query Performance**: Affects query latency
  - **Memory Usage**: Longer duration = more memory

- `max_block_bytes`: Maximum block size before flush
  - **Default**: `104857600` (100MB)
  - **Format**: Bytes as integer
  - **Valid Range**: `10485760` (10MB) to `1073741824` (1GB)
  - **Storage**: Larger blocks = fewer files
  - **Memory**: Larger blocks = more memory usage

- `trace_idle_period`: Time to wait before considering trace complete
  - **Default**: `30s`
  - **Valid Range**: `10s` to `300s`
  - **Late Spans**: Longer period accommodates late arriving spans
  - **Memory**: Longer period = more active traces in memory

- `lifecycler.ring.replication_factor`: Number of ingester replicas
  - **Default**: `1` (single instance)
  - **Valid Range**: `1` to number of ingesters
  - **Availability**: Higher values increase availability
  - **Storage**: Higher values increase storage usage

**Additional Options** (commented):
```yaml
# max_trace_idle: 1m                  # Max time trace can be idle
# flush_check_period: 10s             # How often to check for flushable blocks
# concurrent_flushes: 16              # Max concurrent flush operations
```

### 4. Storage Configuration

```yaml
storage:
  trace:
    backend: local
    local:
      path: /var/tempo/blocks
    wal:
      path: /var/tempo/wal
```

**Purpose**: Configures trace storage backend

**Configuration Parameters**:
- `trace.backend`: Storage backend type
  - **Default**: `local`
  - **Options**: `local`, `gcs`, `s3`, `azure`
  - **Development**: Use `local`
  - **Production**: Use cloud storage for scalability

- `trace.local.path`: Local storage path for trace blocks
  - **Default**: `/var/tempo/blocks`
  - **Format**: Absolute path
  - **Docker**: Ensure path is mounted and writable
  - **Performance**: Use SSD for better performance

- `trace.wal.path`: Write-Ahead Log path
  - **Default**: `/var/tempo/wal`
  - **Format**: Absolute path
  - **Purpose**: Ensures data durability during ingestion
  - **Performance**: Use fast storage (SSD recommended)

**S3 Storage Example** (commented):
```yaml
# storage:
#   trace:
#     backend: s3
#     s3:
#       endpoint: s3.us-east-1.amazonaws.com
#       bucket: grafana-traces-data
#       forcepathstyle: true
#       insecure: false              # Set to false for HTTPS
#       access_key: your-access-key
#       secret_key: your-secret-key
```

### 5. Compactor Configuration

```yaml
compactor:
  compaction:
    block_retention: 168h
    compacted_block_retention: 1h
  ring:
    wait_stability_min_duration: 1m
```

**Purpose**: Manages trace block compaction and retention

**Configuration Parameters**:
- `compaction.block_retention`: How long to keep trace blocks
  - **Default**: `168h` (7 days)
  - **Format**: Duration string (`24h`, `168h`, `720h`)
  - **Valid Range**: `24h` to `8760h` (1 year)
  - **Storage Cost**: Directly affects storage requirements
  - **Compliance**: Set based on retention requirements

- `compaction.compacted_block_retention`: Retention for compacted blocks
  - **Default**: `1h`
  - **Valid Range**: `30m` to `24h`
  - **Purpose**: Cleanup after successful compaction
  - **Safety**: Brief retention allows for rollback

- `ring.wait_stability_min_duration`: Wait time for ring stability
  - **Default**: `1m`
  - **Valid Range**: `30s` to `5m`
  - **Purpose**: Ensures stable cluster before operations
  - **Startup**: Affects startup time in multi-node deployments

**Additional Options** (commented):
```yaml
# v2_prefetch_traces_count: 1000      # Number of traces to prefetch
```

### 6. Metrics Generator Configuration

```yaml
metrics_generator:
  registry:
    collection_interval: 15s
    stale_duration: 15m
  
  storage:
    path: /var/tempo/metrics
        
  traces_storage:
    path: /var/tempo/wal

  processor:
    span_metrics:
      dimensions: ["service.name", "operation"]
```

**Purpose**: Generates metrics from traces (RED metrics)

**Configuration Parameters**:
- `registry.collection_interval`: How often to collect metrics
  - **Default**: `15s`
  - **Valid Range**: `5s` to `60s`
  - **Performance**: Shorter = more accurate, more CPU
  - **Prometheus**: Should match or be divisible by Prometheus scrape interval

- `registry.stale_duration`: When to consider metrics stale
  - **Default**: `15m`
  - **Valid Range**: `5m` to `60m`
  - **Purpose**: Cleanup unused metric series
  - **Memory**: Shorter duration = less memory usage

- `storage.path`: Local storage for metrics generator data
  - **Default**: `/var/tempo/metrics`
  - **Format**: Absolute path
  - **Purpose**: Temporary storage for metrics processing

- `traces_storage.path`: WAL path for metrics generator
  - **Default**: `/var/tempo/wal`
  - **Purpose**: Shares WAL with ingester for efficiency
  - **Consistency**: Should match ingester WAL path

**Span Metrics Configuration**:
```yaml
processor:
  span_metrics:
    dimensions: ["service.name", "operation", "status_code"]
    # Additional dimensions to extract from spans
```

### 7. Querier Configuration

```yaml
querier:
  max_concurrent_queries: 10
  frontend_worker:
    frontend_address: 127.0.0.1:9095
```

**Purpose**: Configures trace querying behavior

**Configuration Parameters**:
- `max_concurrent_queries`: Maximum concurrent queries per querier
  - **Default**: `10`
  - **Valid Range**: `1` to `100`
  - **Resource Impact**: Higher values = more CPU/memory usage
  - **Performance**: Balance between throughput and resource usage

- `frontend_worker.frontend_address`: Query frontend address
  - **Default**: `127.0.0.1:9095`
  - **Format**: `"IP:PORT"`
  - **Purpose**: Connects queriers to query frontend
  - **Distributed**: Use actual frontend address in multi-node setup

**Additional Options** (commented):
```yaml
# trace_by_id_prefer_self: 10         # Prefer local data for trace by ID
# query_timeout: 300s                 # Query timeout duration
```

### 8. Query Frontend Configuration

```yaml
query_frontend:
  max_outstanding_per_tenant: 2000
```

**Purpose**: Manages query queuing and distribution

**Configuration Parameters**:
- `max_outstanding_per_tenant`: Maximum outstanding queries per tenant
  - **Default**: `2000`
  - **Valid Range**: `100` to `10000`
  - **Purpose**: Prevents query queue overflow
  - **Multi-tenancy**: Isolates tenants from each other

**Additional Options** (commented):
```yaml
# querier_forget_delay: 15m           # Time to remember failed queriers
# max_retries: 5                      # Max query retries
# retry_delay: 2s                     # Delay between retries
# search:
#   duration_slo: 5s                  # Search duration SLO
#   throughput_bytes_slo: 1073741824  # Search throughput SLO (1GB)
# trace_by_id:
#   duration_slo: 5s                  # Trace by ID duration SLO
```

### 9. Overrides Configuration

```yaml
overrides:
  metrics_generator_processors: [service-graphs, span-metrics, local-blocks]
  
  max_traces_per_user: 5000
  max_global_traces_per_user: 100000
  
  ingestion_rate_strategy: global
  ingestion_rate_limit_bytes: 15000000
  ingestion_burst_size_bytes: 20000000
  max_bytes_per_trace: 50000000
  
  max_search_duration: 0s
```

**Purpose**: Per-tenant limits and feature controls

**Configuration Parameters**:
- `metrics_generator_processors`: Enabled metrics processors
  - **Default**: `[service-graphs, span-metrics, local-blocks]`
  - **Options**: `service-graphs`, `span-metrics`, `local-blocks`
  - **Feature Control**: Enable/disable specific metrics

- `max_traces_per_user`: Maximum active traces per tenant
  - **Default**: `5000`
  - **Valid Range**: `1000` to `100000`
  - **Memory Impact**: Directly affects memory usage
  - **Adjustment**: Increase for high-throughput services

- `max_global_traces_per_user`: Maximum global traces per tenant
  - **Default**: `100000`
  - **Valid Range**: `10000` to `1000000`
  - **Purpose**: Global limit across all ingesters

- `ingestion_rate_strategy`: Rate limiting strategy
  - **Default**: `global`
  - **Options**: `local`, `global`
  - **Global**: Shared rate limit across cluster
  - **Local**: Per-instance rate limit

- `ingestion_rate_limit_bytes`: Maximum ingestion rate
  - **Default**: `15000000` (15MB/s)
  - **Format**: Bytes per second
  - **Valid Range**: `1000000` (1MB/s) to `1000000000` (1GB/s)
  - **Purpose**: Prevents ingestion overload

- `ingestion_burst_size_bytes`: Burst ingestion limit
  - **Default**: `20000000` (20MB)
  - **Format**: Bytes
  - **Rule**: Should be >= `ingestion_rate_limit_bytes`
  - **Purpose**: Allows short bursts of traces

- `max_bytes_per_trace`: Maximum trace size
  - **Default**: `50000000` (50MB)
  - **Format**: Bytes
  - **Valid Range**: `1000000` (1MB) to `1000000000` (1GB)
  - **Purpose**: Prevents extremely large traces

- `max_search_duration`: Maximum search time range
  - **Default**: `0s` (unlimited)
  - **Format**: Duration string (`1h`, `24h`, `168h`)
  - **Purpose**: Limits expensive search queries
  - **Performance**: Set limit for large deployments

**Additional Overrides** (commented):
```yaml
# max_spans_per_trace: 100000         # Max spans per trace
# max_bytes_per_tag_values_query: 5000000  # Max bytes for tag values query
# max_blocks_per_tag_values_query: 1000    # Max blocks for tag values query
# max_search_bytes_per_trace: 5000000      # Max bytes per trace in search
# block_retention: 720h                    # Per-tenant block retention (30 days)
```

## High Availability Configuration

### Memberlist Configuration (commented)
```yaml
# memberlist:
#   node_name: tempo-1                 # Node name in cluster
#   bind_port: 7946                    # Bind port
#   join_members: ["tempo-2", "tempo-3"]  # Other cluster members
```

## Performance Tuning

### High Throughput Configuration
```yaml
ingester:
  max_block_duration: 20m
  max_block_bytes: 209715200  # 200MB
  
overrides:
  ingestion_rate_limit_bytes: 50000000  # 50MB/s
  max_traces_per_user: 20000
```

### Low Latency Configuration
```yaml
ingester:
  max_block_duration: 5m
  max_block_bytes: 52428800   # 50MB
  trace_idle_period: 10s
  
metrics_generator:
  registry:
    collection_interval: 10s
```

### Memory Optimization
```yaml
ingester:
  max_block_bytes: 26214400   # 25MB
  trace_idle_period: 15s
  
overrides:
  max_traces_per_user: 2000
  max_bytes_per_trace: 10000000  # 10MB
```

## Storage Backend Configuration

### Local Storage (Development)
```yaml
storage:
  trace:
    backend: local
    local:
      path: /var/tempo/blocks
```

### S3 Storage (Production)
```yaml
storage:
  trace:
    backend: s3
    s3:
      endpoint: s3.amazonaws.com
      bucket: tempo-traces
      region: us-east-1
      access_key: ${AWS_ACCESS_KEY}
      secret_key: ${AWS_SECRET_KEY}
      insecure: false
```

### GCS Storage (Production)
```yaml
storage:
  trace:
    backend: gcs
    gcs:
      bucket_name: tempo-traces
      project_id: my-project
      # Use service account key file
```

## Security Configuration

### TLS Configuration
```yaml
server:
  http_tls_config:
    cert_file: /path/to/cert.pem
    key_file: /path/to/key.pem
  grpc_tls_config:
    cert_file: /path/to/cert.pem
    key_file: /path/to/key.pem
```

### Authentication
```yaml
# Tempo doesn't have built-in auth, use reverse proxy
# or configure at the application level
```

## Monitoring and Observability

### Key Metrics to Monitor
- `tempo_ingester_live_traces`: Number of active traces
- `tempo_ingester_blocks_flushed_total`: Block flush rate
- `tempo_request_duration_seconds`: Query latency
- `tempo_distributor_bytes_received_total`: Ingestion rate

### Health Checks
```bash
# Health check
curl http://localhost:3200/ready

# Metrics endpoint
curl http://localhost:3200/metrics

# Configuration endpoint
curl http://localhost:3200/config
```

## Troubleshooting

### Common Issues

1. **Out of Memory**
   ```yaml
   # Reduce memory usage
   ingester:
     max_block_bytes: 26214400  # 25MB
     trace_idle_period: 15s
   overrides:
     max_traces_per_user: 2000
   ```

2. **Slow Queries**
   ```yaml
   # Optimize for query performance
   compactor:
     compaction:
       block_retention: 72h  # Shorter retention
   querier:
     max_concurrent_queries: 20
   ```

3. **High Disk Usage**
   ```yaml
   # Reduce storage usage
   compactor:
     compaction:
       block_retention: 48h
       compacted_block_retention: 30m
   ```

### Debug Configuration
```yaml
server:
  log_level: debug

# Enable additional logging
```

### Validation Commands
```bash
# Validate configuration
tempo -config.file=tempo.yaml -config.check-syntax

# Print effective configuration
tempo -config.file=tempo.yaml -config.print

# Run with verbose logging
tempo -config.file=tempo.yaml -log.level=debug
```

## Best Practices

1. **Resource Planning**: Plan for trace volume and retention
2. **Storage Strategy**: Use object storage for production
3. **Retention Policy**: Set appropriate retention for compliance
4. **Monitoring**: Monitor key metrics and set up alerts
5. **Security**: Use TLS and proper network security
6. **Backup**: Backup configuration and critical data
7. **Testing**: Test with realistic trace volumes
8. **Documentation**: Document custom configurations

## Migration and Upgrades

### Version Compatibility
- Check Tempo release notes for breaking changes
- Test configuration changes in staging
- Monitor performance after upgrades

### Schema Migrations
- Tempo handles schema migrations automatically
- Plan for downtime during major version upgrades
- Backup data before major upgrades

## References

- [Grafana Tempo Documentation](https://grafana.com/docs/tempo/)
- [Tempo Configuration Reference](https://grafana.com/docs/tempo/latest/configuration/)
- [Tempo Operations Guide](https://grafana.com/docs/tempo/latest/operations/)
