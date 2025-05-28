# Grafana Loki Configuration Guide

## Overview

This document provides comprehensive documentation for the Grafana Loki configuration file (`loki-config.yaml`) used in this monitoring stack. Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus.

## Configuration Structure

Loki configuration is written in YAML format and organized into several main sections:

```yaml
# Global settings
auth_enabled: false

# Server configuration
server:
  http_listen_port: 3100

# Common configuration shared across components
common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks

# Component-specific configurations
ingester:
  lifecycler:
    # configuration...

schema_config:
  configs:
    # configuration...
```

## Section-by-Section Configuration

### 1. Authentication

```yaml
auth_enabled: false
```

**Purpose**: Controls multi-tenancy and authentication

**Configuration Parameters**:
- `auth_enabled`: Enable/disable authentication
  - **Default**: `false`
  - **Development**: `false` (no authentication required)
  - **Production**: `true` (enables multi-tenancy and auth)
  - **Security Impact**: When `false`, all data is stored in a single tenant

### 2. Server Configuration

```yaml
server:
  http_listen_port: 3100
  grpc_listen_port: 9095
```

**Purpose**: Configures network interfaces and logging

**Configuration Parameters**:
- `http_listen_port`: HTTP API port
  - **Default**: `3100`
  - **Valid Range**: `1024-65535`
  - **Usage**: Grafana connects to this port for queries
  - **Firewall**: Ensure this port is accessible

- `grpc_listen_port`: gRPC interface port
  - **Default**: `9095`
  - **Valid Range**: `1024-65535`
  - **Usage**: Internal communication between Loki components
  - **Note**: Required for distributed deployments

### 3. Common Configuration

```yaml
common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: memberlist
```

**Purpose**: Shared configuration across all Loki components

**Configuration Parameters**:
- `path_prefix`: Base path for all Loki data
  - **Default**: `/loki`
  - **Format**: Absolute path
  - **Docker Note**: Ensure path is writable in container

- `storage.filesystem.chunks_directory`: Log chunks storage path
  - **Default**: `/loki/chunks`
  - **Format**: Absolute path
  - **Storage Impact**: This is where log data is stored
  - **Performance**: Use SSD for better performance

- `storage.filesystem.rules_directory`: Alert rules storage path
  - **Default**: `/loki/rules`
  - **Format**: Absolute path
  - **Purpose**: Stores alerting and recording rules

- `replication_factor`: Number of replicas for each log chunk
  - **Default**: `1` (single instance)
  - **Valid Range**: `1` to number of ingesters
  - **Availability**: Higher values increase availability
  - **Storage Cost**: Higher values increase storage usage

- `ring.kvstore.store`: Key-value store for service discovery
  - **Default**: `memberlist`
  - **Options**: `memberlist`, `consul`, `etcd`
  - **Development**: `memberlist` (no external dependencies)
  - **Production**: Consider `consul` or `etcd` for HA

### 4. Ingester Configuration

```yaml
ingester:
  lifecycler:
    address: 0.0.0.0
    ring:
      kvstore:
        store: memberlist
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_chunk_age: 1h
  wal:
    enabled: true
    dir: /loki/wal
    replay_memory_ceiling: 512MB
```

**Purpose**: Configures log ingestion behavior

**Configuration Parameters**:
- `lifecycler.address`: Ingester advertise address
  - **Default**: `0.0.0.0`
  - **Production**: Use specific IP address
  - **Docker**: Usually container IP or hostname

- `chunk_idle_period`: Time before closing idle chunks
  - **Default**: `5m`
  - **Valid Range**: `1m` to `30m`
  - **Trade-off**: Shorter = more chunks, Longer = larger chunks
  - **Memory Impact**: Affects memory usage

- `chunk_retain_period`: Time to keep chunks in memory after closing
  - **Default**: `30s`
  - **Valid Range**: `10s` to `5m`
  - **Purpose**: Allows late arriving logs

- `max_chunk_age`: Maximum age before forcing chunk flush
  - **Default**: `1h`
  - **Valid Range**: `10m` to `12h`
  - **Query Performance**: Affects query latency

- `wal.enabled`: Enable Write-Ahead Log
  - **Default**: `true`
  - **Purpose**: Ensures data durability
  - **Recovery**: Helps recover from crashes

- `wal.dir`: WAL directory path
  - **Default**: `/loki/wal`
  - **Format**: Absolute path
  - **Performance**: Use fast storage (SSD)

- `wal.replay_memory_ceiling`: Maximum memory for WAL replay
  - **Default**: `512MB`
  - **Format**: `"500MB"`, `"1GB"`, `"2GB"`
  - **Startup Impact**: Affects startup time after crashes

### 5. Schema Configuration

```yaml
schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
```

**Purpose**: Defines how logs are stored and indexed

**Configuration Parameters**:
- `from`: Schema start date
  - **Format**: `YYYY-MM-DD`
  - **Rule**: Must be in the past
  - **Immutable**: Cannot change once data exists

- `store`: Index store type
  - **Default**: `tsdb`
  - **Options**: `tsdb`, `boltdb-shipper`
  - **Recommendation**: Use `tsdb` for new deployments

- `object_store`: Object storage backend
  - **Default**: `filesystem`
  - **Options**: `filesystem`, `s3`, `gcs`, `azure`
  - **Production**: Consider cloud storage for scalability

- `schema`: Schema version
  - **Default**: `v13`
  - **Latest**: `v13` (as of Loki 3.x)
  - **Migration**: Changing requires data migration

- `index.prefix`: Index file prefix
  - **Default**: `index_`
  - **Purpose**: Organizes index files
  - **S3 Note**: Acts as object key prefix

- `index.period`: How often to create new index files
  - **Default**: `24h`
  - **Options**: `24h`, `168h` (7 days)
  - **Trade-off**: Shorter = more files, better parallelism

### 6. Storage Configuration

```yaml
storage_config:
  tsdb_shipper:
    active_index_directory: /loki/tsdb-shipper-active
    cache_location: /loki/tsdb-shipper-cache
    cache_ttl: 24h
  filesystem:
    directory: /loki/chunks
```

**Purpose**: Configures storage backends

**Configuration Parameters**:
- `tsdb_shipper.active_index_directory`: Active index storage
  - **Default**: `/loki/tsdb-shipper-active`
  - **Purpose**: Stores current index files
  - **Performance**: Use fast storage

- `tsdb_shipper.cache_location`: Index cache directory
  - **Default**: `/loki/tsdb-shipper-cache`
  - **Purpose**: Caches downloaded index files
  - **Size**: Can grow large, monitor disk usage

- `tsdb_shipper.cache_ttl`: Index cache TTL
  - **Default**: `24h`
  - **Valid Range**: `1h` to `168h`
  - **Memory vs Speed**: Longer TTL = more cache hits

- `filesystem.directory`: Chunk storage directory
  - **Default**: `/loki/chunks`
  - **Format**: Absolute path
  - **Critical**: Must be persistent and writable

### 7. Limits Configuration

```yaml
limits_config:
  max_streams_per_user: 10000
  max_entries_limit_per_query: 10000
  max_global_streams_per_user: 5000
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  retention_period: 168h
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20
  per_stream_rate_limit: 3MB
  per_stream_rate_limit_burst: 15MB
```

**Purpose**: Controls resource usage and prevents abuse

**Configuration Parameters**:
- `max_streams_per_user`: Maximum active streams per tenant
  - **Default**: `10000`
  - **Impact**: Higher = more memory usage
  - **Recommendation**: Start conservative, increase as needed

- `max_entries_limit_per_query`: Maximum log entries per query
  - **Default**: `10000`
  - **Purpose**: Prevents large query responses
  - **User Impact**: Affects query result size

- `reject_old_samples`: Reject logs older than threshold
  - **Default**: `true`
  - **Purpose**: Prevents backdated data ingestion
  - **Clock Skew**: May need `false` if clocks are not synchronized

- `reject_old_samples_max_age`: Maximum age for accepted logs
  - **Default**: `168h` (7 days)
  - **Format**: `"24h"`, `"72h"`, `"168h"`
  - **Use Case**: Allow for delayed log delivery

- `retention_period`: How long to keep logs
  - **Default**: `168h` (7 days)
  - **Format**: `"24h"`, `"720h"` (30 days), `"8760h"` (1 year)
  - **Storage Cost**: Directly affects storage requirements

- `ingestion_rate_mb`: Ingestion rate limit per tenant
  - **Default**: `10` MB/s
  - **Valid Range**: `1` to `1000+`
  - **Purpose**: Prevents ingestion spikes

- `ingestion_burst_size_mb`: Burst ingestion limit
  - **Default**: `20` MB
  - **Rule**: Should be >= `ingestion_rate_mb`
  - **Purpose**: Allows short bursts of logs

- `per_stream_rate_limit`: Rate limit per stream
  - **Default**: `3MB`
  - **Format**: `"1MB"`, `"5MB"`, `"10MB"`
  - **Granularity**: Per-stream control

- `per_stream_rate_limit_burst`: Burst limit per stream
  - **Default**: `15MB`
  - **Rule**: Should be >= `per_stream_rate_limit`
  - **Purpose**: Handles log bursts

### 8. Compactor Configuration

```yaml
compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  delete_request_store: filesystem
```

**Purpose**: Manages log compaction and retention

**Configuration Parameters**:
- `working_directory`: Compactor temporary files
  - **Default**: `/loki/compactor`
  - **Purpose**: Temporary space during compaction
  - **Size**: Can require significant space

- `compaction_interval`: How often to run compaction
  - **Default**: `10m`
  - **Valid Range**: `5m` to `60m`
  - **Performance**: More frequent = better query performance

- `retention_enabled`: Enable automatic retention
  - **Default**: `true`
  - **Purpose**: Automatically delete old logs
  - **Dependency**: Requires proper retention configuration

- `delete_request_store`: Delete request storage
  - **Default**: `filesystem`
  - **Options**: `filesystem`, `s3`, `gcs`
  - **Purpose**: Tracks log deletion requests

### 9. Query Range Configuration

```yaml
query_range:
  align_queries_with_step: true
  max_retries: 5
  cache_results: true
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 500
        ttl: 24h
```

**Purpose**: Optimizes query performance

**Configuration Parameters**:
- `align_queries_with_step`: Align queries to step boundaries
  - **Default**: `true`
  - **Purpose**: Improves cache hit rate
  - **Recommendation**: Keep enabled

- `max_retries`: Maximum query retries
  - **Default**: `5`
  - **Valid Range**: `1` to `10`
  - **Reliability**: Higher = more resilient to failures

- `cache_results`: Enable query result caching
  - **Default**: `true`
  - **Performance**: Significantly improves repeat queries
  - **Memory**: Uses additional memory

- `results_cache.cache.embedded_cache.max_size_mb`: Cache size
  - **Default**: `500` MB
  - **Valid Range**: `100` to `5000+` MB
  - **Memory Impact**: Directly affects memory usage

- `results_cache.cache.embedded_cache.ttl`: Cache TTL
  - **Default**: `24h`
  - **Valid Range**: `1h` to `168h`
  - **Freshness vs Performance**: Longer = better cache hits

## Performance Tuning

### High Volume Environments
```yaml
ingester:
  chunk_idle_period: 10m
  max_chunk_age: 2h
  
limits_config:
  ingestion_rate_mb: 50
  max_streams_per_user: 50000
  
query_range:
  results_cache:
    cache:
      embedded_cache:
        max_size_mb: 2000
```

### Low Resource Environments
```yaml
ingester:
  chunk_idle_period: 2m
  max_chunk_age: 30m
  
limits_config:
  ingestion_rate_mb: 5
  max_streams_per_user: 5000
  
query_range:
  results_cache:
    cache:
      embedded_cache:
        max_size_mb: 100
```

## Storage Backends

### Filesystem (Development)
```yaml
storage_config:
  filesystem:
    directory: /loki/chunks
```

### S3 (Production)
```yaml
storage_config:
  aws:
    s3: s3://region/bucket-name
    s3forcepathstyle: false
  
common:
  storage:
    s3:
      endpoint: s3.amazonaws.com
      bucketnames: loki-chunks
      access_key_id: ${AWS_ACCESS_KEY_ID}
      secret_access_key: ${AWS_SECRET_ACCESS_KEY}
```

## Security Configuration

### Enable Authentication
```yaml
auth_enabled: true

server:
  http_listen_port: 3100
  grpc_listen_port: 9095
  grpc_tls_config:
    cert_file: /path/to/cert.pem
    key_file: /path/to/key.pem
  http_tls_config:
    cert_file: /path/to/cert.pem
    key_file: /path/to/key.pem
```

## Environment Variables

Loki supports environment variable substitution (requires `-config.expand-env=true`):

```yaml
server:
  http_listen_port: ${LOKI_HTTP_PORT:3100}

storage_config:
  aws:
    access_key_id: ${AWS_ACCESS_KEY_ID}
    secret_access_key: ${AWS_SECRET_ACCESS_KEY}
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Check directory permissions
   ls -la /loki/
   chmod 755 /loki/chunks /loki/wal
   ```

2. **Out of Memory**
   ```yaml
   # Reduce memory usage
   limits_config:
     max_streams_per_user: 5000
   ingester:
     chunk_idle_period: 2m
   ```

3. **Slow Queries**
   ```yaml
   # Increase cache
   query_range:
     results_cache:
       cache:
         embedded_cache:
           max_size_mb: 1000
   ```

### Validation Commands

```bash
# Validate configuration
loki -config.file=loki-config.yaml -verify-config

# Print effective configuration
loki -config.file=loki-config.yaml -print-config-stderr

# Check configuration with environment expansion
loki -config.file=loki-config.yaml -config.expand-env=true -verify-config
```

### Monitoring Loki

Key metrics to monitor:
- `loki_ingester_memory_streams`: Number of active streams
- `loki_ingester_chunks_flushed_total`: Chunk flush rate
- `loki_request_duration_seconds`: Query latency
- `loki_ingester_wal_disk_full_failures_total`: WAL disk issues

## Best Practices

1. **Storage Planning**: Plan for log volume growth
2. **Retention Policy**: Set appropriate retention based on compliance
3. **Label Strategy**: Use consistent label naming conventions
4. **Resource Monitoring**: Monitor memory, CPU, and disk usage
5. **Backup Strategy**: Backup configuration and critical data
6. **Index Optimization**: Choose appropriate index period
7. **Security**: Enable authentication in production
8. **Performance Testing**: Test with realistic log volumes

## Migration Notes

### Upgrading Schema
1. Add new schema config with future date
2. Keep old schema for existing data
3. Plan migration strategy for large datasets

### Version Compatibility
- Check Loki release notes for breaking changes
- Test configuration changes in staging
- Monitor metrics after upgrades

## References

- [Grafana Loki Documentation](https://grafana.com/docs/loki/)
- [Loki Configuration Reference](https://grafana.com/docs/loki/latest/configure/)
- [Storage Configuration Guide](https://grafana.com/docs/loki/latest/operations/storage/)
