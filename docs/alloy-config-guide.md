# Grafana Alloy Configuration Guide

## Overview

This document provides comprehensive documentation for the Grafana Alloy configuration file (`config.alloy`) used in this monitoring stack. Alloy is a vendor-neutral distribution of the OpenTelemetry Collector that helps collect, transform, and forward telemetry data (metrics, logs, and traces).

## Configuration Structure

Alloy uses a declarative, component-based configuration syntax where components are connected to form telemetry pipelines. The configuration follows this pattern:

```alloy
component_type "component_label" {
    argument1 = value1
    argument2 = value2
    
    nested_block {
        nested_argument = value
    }
    
    forward_to = [another_component.receiver]
}
```

## Component Reference

### 1. OTLP Receiver (Data Collection)

```alloy
otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
    max_recv_msg_size = "4MiB"
    max_concurrent_streams = 50
  }
  
  http {
    endpoint = "0.0.0.0:4318"
  }
  
  output {
    traces  = [otelcol.processor.batch.traces.input]
    metrics = [otelcol.processor.batch.metrics.input]
    logs    = [otelcol.processor.batch.logs.input]
  }
}
```

**Purpose**: Receives telemetry data via OTLP (OpenTelemetry Protocol)

**Configuration Parameters**:
- `grpc.endpoint`: gRPC endpoint address (Format: `"IP:PORT"`)
  - **Default**: `"0.0.0.0:4317"` (listens on all interfaces)
  - **Valid Values**: Any valid IP:PORT combination
  - **Security Note**: Use specific IP instead of `0.0.0.0` in production

- `grpc.max_recv_msg_size`: Maximum gRPC message size
  - **Default**: `"4MiB"`
  - **Valid Values**: `"1MiB"`, `"8MiB"`, `"16MiB"`, etc.
  - **Impact**: Larger values allow bigger traces but use more memory

- `grpc.max_concurrent_streams`: Maximum concurrent gRPC streams
  - **Current**: `100` (optimized for higher throughput)
  - **Default**: `50`
  - **Valid Range**: `1` to `1000+`
  - **Impact**: Higher values support more concurrent connections

- `http.endpoint`: HTTP endpoint address
  - **Default**: `"0.0.0.0:4318"`
  - **Valid Values**: Any valid IP:PORT combination

### 2. Batch Processors (Data Processing)

```alloy
// Optimized for fast metrics processing
otelcol.processor.batch "metrics" {
  timeout = "500ms"
  send_batch_size = 256
  
  output {
    metrics = [otelcol.exporter.prometheus.default.input]
  }
}

// Standard processing for traces
otelcol.processor.batch "traces" {
  timeout = "1s"
  send_batch_size = 1024
  send_batch_max_size = 2048
  
  output {
    traces = [otelcol.exporter.otlp.tempo.input]
  }
}

// Standard processing for logs
otelcol.processor.batch "logs" {
  timeout = "1s"
  send_batch_size = 1024
  
  output {
    logs = [otelcol.exporter.loki.default.input]
  }
}
```

**Purpose**: Batches telemetry data for efficient transmission with different optimizations per data type

**Configuration Parameters**:
- `timeout`: Time to wait before sending partial batch
  - **Metrics**: `"500ms"` for fast processing (optimized for 1-minute rates)
  - **Traces/Logs**: `"1s"` for standard efficiency
  - **Valid Values**: `"100ms"`, `"500ms"`, `"1s"`, `"5s"`
  - **Trade-off**: Lower = more real-time, Higher = more efficient

- `send_batch_size`: Preferred batch size
  - **Metrics**: `256` for fast processing with low latency
  - **Traces/Logs**: `1024` for standard efficiency
  - **Valid Range**: `1` to `10000+`
  - **Performance**: Smaller batches = faster processing, larger = more efficient

- `send_batch_max_size`: Maximum batch size
  - **Default**: `2048`
  - **Rule**: Must be >= `send_batch_size`
  - **Memory Impact**: Higher values use more memory

### 3. OTLP Exporter (Tempo Integration)

```alloy
otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "http://tempo:4317"
    tls {
      insecure = true
    }
  }
}
```

**Purpose**: Exports traces to Tempo

**Configuration Parameters**:
- `client.endpoint`: Tempo endpoint URL
  - **Format**: `"http://hostname:port"` or `"https://hostname:port"`
  - **Default**: `"http://tempo:4317"`
  - **Note**: Use `https://` for secure connections

- `tls.insecure`: Disable TLS verification
  - **Default**: `true` (for development)
  - **Production**: Set to `false` and configure proper TLS
  - **Security Risk**: Only use `true` in trusted environments

### 4. Prometheus Exporter (Metrics)

```alloy
otelcol.exporter.prometheus "default" {
  forward_to = [prometheus.remote_write.mimir.receiver]
}
```

**Purpose**: Converts OTLP metrics to Prometheus format

**Configuration Parameters**:
- `forward_to`: Target component for metrics
  - **Format**: `[component_type.component_label.receiver]`
  - **Required**: Must reference a valid prometheus.remote_write component

### 5. Loki Exporter (Logs)

```alloy
otelcol.exporter.loki "default" {
  forward_to = [loki.relabel.add_labels.receiver]
}
```

**Purpose**: Exports logs to Loki

**Configuration Parameters**:
- `forward_to`: Target component for logs
  - **Format**: `[component_type.component_label.receiver]`
  - **Required**: Must reference a valid loki component

### 6. Label Relabeling

```alloy
loki.relabel "add_labels" {
  forward_to = [loki.write.default.receiver]
  
  rule {
    source_labels = ["__meta_docker_container_name"]
    target_label = "container"
  }
  
  rule {
    source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
    target_label = "service"
  }
}
```

**Purpose**: Adds labels to logs for better organization

**Configuration Parameters**:
- `rule.source_labels`: Labels to extract from
  - **Format**: `["label_name"]`
  - **Docker Meta Labels**: Use `__meta_docker_*` for Docker discovery

- `rule.target_label`: New label name
  - **Format**: `"label_name"`
  - **Best Practice**: Use descriptive names like `"service"`, `"container"`

### 7. Remote Write (Prometheus)

```alloy
prometheus.remote_write "mimir" {
  endpoint {
    url = "http://prometheus:9090/api/v1/write"
    
    send_exemplars = true
    send_native_histograms = true
    
    // Aggressive settings for speed
    queue_config {
      batch_send_deadline = "1s"   // Fast sending
      max_samples_per_send = 256   // Small batches for speed
      max_shards = 20             // Parallel processing
    }
  }
}
```

**Purpose**: Sends metrics to Prometheus with optimized settings for fast processing

**Configuration Parameters**:
- `endpoint.url`: Prometheus remote write URL
  - **Format**: `"http://hostname:port/api/v1/write"`
  - **Default**: `"http://prometheus:9090/api/v1/write"`

- `send_exemplars`: Send exemplars with metrics
  - **Default**: `true`
  - **Purpose**: Links metrics to traces

- `send_native_histograms`: Send native histogram format
  - **Current**: `true` (enables Prometheus native histograms)
  - **Performance**: Better compression and query performance

- `queue_config.batch_send_deadline`: Maximum time to wait before sending
  - **Current**: `"1s"` (optimized for fast processing)
  - **Default**: `"5s"`
  - **Trade-off**: Lower = more real-time, higher = more efficient

- `queue_config.max_samples_per_send`: Samples per batch
  - **Current**: `256` (optimized for speed)
  - **Default**: `500`
  - **Valid Range**: `100` to `2000`
  - **Performance**: Smaller batches = faster processing

- `queue_config.max_shards`: Maximum number of parallel writers
  - **Current**: `20` (high parallelism for speed)
  - **Default**: `10`
  - **Performance**: More shards = better throughput for high-volume metrics

## Alloy Self-Monitoring and Scraping

### 8. Alloy Self-Monitoring

```alloy
prometheus.exporter.self "alloy" {}

prometheus.scrape "alloy_self" {
  targets = prometheus.exporter.self.alloy.targets
  forward_to = [prometheus.remote_write.mimir.receiver]
  scrape_interval = "10s"  // Faster scraping for monitoring
}
```

**Purpose**: Monitors Alloy's own metrics for performance and health

**Configuration Parameters**:
- `prometheus.exporter.self`: Exposes Alloy's internal metrics
  - **Metrics**: Component health, pipeline throughput, memory usage
  - **Endpoint**: Available at `/metrics` on Alloy's HTTP port

- `scrape_interval`: How often to collect Alloy's own metrics
  - **Current**: `"10s"` (optimized for real-time monitoring)
  - **Default**: `"15s"`
  - **Performance**: Faster intervals provide better visibility into pipeline health

### 9. Docker Container Discovery

```alloy
discovery.docker "containers" {
  host = "unix:///var/run/docker.sock"
  
  filter {
    name = "label"
    values = ["monitoring.scrape=true"]
  }
}

prometheus.scrape "docker_containers" {
  targets = discovery.docker.containers.targets
  forward_to = [prometheus.remote_write.mimir.receiver]
  scrape_interval = "10s"  // Faster scraping
}
```

**Purpose**: Automatically discovers and scrapes Docker containers with monitoring labels

**Configuration Parameters**:
- `filter.name`: Filter type for container discovery
  - **Current**: `"label"` (filters by Docker labels)
  - **Alternative**: `"container"` (filter by container names)

- `filter.values`: Specific filter criteria
  - **Current**: `["monitoring.scrape=true"]`
  - **Usage**: Only containers with this label will be scraped
  - **Best Practice**: Add this label to containers you want to monitor

- `scrape_interval`: Frequency of metrics collection
  - **Current**: `"10s"` (optimized for fast data ingestion)
  - **Impact**: Faster intervals provide more real-time metrics

## Configuration Validation

### Syntax Validation
- Use proper Alloy syntax with correct block structure
- Ensure all component references exist
- Check for circular dependencies

### Common Validation Errors
1. **Missing Component Reference**: `forward_to = [non.existent.component]`
2. **Invalid Duration**: `timeout = "invalid"` (use `"1s"`, `"500ms"`, etc.)
3. **Wrong Data Type**: `send_batch_size = "1024"` (should be `1024`)

### Testing Configuration
```bash
# Validate configuration without starting
curl -X POST http://localhost:12345/-/reload

# Check component graph in UI
# Navigate to http://localhost:12345
```

## Performance Tuning

### High Throughput
```alloy
otelcol.processor.batch "traces" {
  timeout = "2s"
  send_batch_size = 2048
  send_batch_max_size = 4096
}
```

### Low Latency
```alloy
otelcol.processor.batch "traces" {
  timeout = "100ms"
  send_batch_size = 256
  send_batch_max_size = 512
}
```

### Memory Optimization
- Reduce `max_recv_msg_size` if receiving small traces
- Lower `send_batch_max_size` to reduce memory usage
- Adjust `max_concurrent_streams` based on available resources

## Security Considerations

### Production TLS Configuration
```alloy
otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "https://tempo:4317"
    tls {
      insecure = false
      cert_file = "/path/to/cert.pem"
      key_file = "/path/to/key.pem"
      ca_file = "/path/to/ca.pem"
    }
  }
}
```

### Network Security
- Bind to specific interfaces instead of `0.0.0.0`
- Use authentication when available
- Implement proper firewall rules

## Troubleshooting

### Common Issues
1. **Connection Refused**: Check if target services are running
2. **Memory Issues**: Reduce batch sizes and concurrent streams
3. **High CPU**: Increase batch timeout to reduce processing frequency

### Debug Configuration
```alloy
// Add logging for debugging
otelcol.processor.debug "debug" {
  verbosity = "detailed"
  sampling_initial = 5
  sampling_thereafter = 200
}
```

### Log Analysis
- Check Alloy logs: `docker logs alloy`
- Monitor component status in UI: `http://localhost:12345`
- Verify metrics: `curl http://localhost:12345/metrics`

## Best Practices

1. **Component Naming**: Use descriptive names like `"traces"`, `"metrics"`, `"logs"`
2. **Error Handling**: Always configure retry policies
3. **Resource Limits**: Set appropriate batch sizes for your environment
4. **Monitoring**: Monitor Alloy's own metrics
5. **Documentation**: Comment complex configurations
6. **Testing**: Validate changes in development first

## Configuration Reload

Alloy supports dynamic configuration reloading:

```bash
# Reload configuration
curl -X POST http://localhost:12345/-/reload

# Response on success:
{"status":"success","message":"config reloaded"}

# Response on error:
{"status":"error","message":"error description"}
```

## References

- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/)
- [OpenTelemetry Collector Documentation](https://opentelemetry.io/docs/collector/)
- [Alloy Configuration Syntax](https://grafana.com/docs/alloy/latest/get-started/configuration-syntax/)
