# Application Monitoring - Client (Frontend)

**Configuration examples for sending telemetry data from your applications to the monitoring stack.**

This directory contains **client-side** configurations for instrumenting your applications to send observability data (metrics, logs, and traces) to the monitoring server.

---

## Overview

Applications send telemetry data to the monitoring server via **OpenTelemetry Protocol (OTLP)**:

```
Your Application
    ↓ OTLP
Monitoring Server (Alloy)
    ├→ Metrics  → Prometheus
    ├→ Logs     → Loki
    ├→ Traces   → Tempo
    └→ Profiles → Pyroscope
```

**Server Endpoints:**
- **OTLP gRPC**: `http://localhost:4317`
- **OTLP HTTP**: `http://localhost:4318`

---

## Quick Start

### 1. Start the Monitoring Server

First, ensure the server is running:
```bash
cd ../server
docker-compose up -d
```

### 2. Configure Your Application

Choose the configuration that matches your application:

#### Java Spring Boot
Use `java-spring-boot-otlp.yml`:

```yaml
# Copy to your Spring Boot project as application-monitoring.yml
# Then run: java -jar app.jar --spring.profiles.active=monitoring
```

**Key configuration:**
```yaml
management:
  otlp:
    metrics:
      export:
        url: http://localhost:4318/v1/metrics
    tracing:
      export:
        url: http://localhost:4318/v1/traces
  tracing:
    sampling:
      probability: 1.0
```

#### Environment Variables (Any Language)
Use `generic-env-vars.sh`:

```bash
# Source in your application startup script
source generic-env-vars.sh

# Or export directly
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_SERVICE_NAME=my-application
export OTEL_RESOURCE_ATTRIBUTES=environment=production,team=backend
```

### 3. Verify Data Collection

1. **Check Alloy is receiving data**: http://localhost:12345
2. **View metrics in Prometheus**: http://localhost:9090
3. **Explore in Grafana**: http://localhost:3002

---

## Configuration Files

### `java-spring-boot-otlp.yml`
Complete Spring Boot configuration for:
- OTLP metrics export
- OTLP trace export
- Distributed tracing with trace IDs
- JVM metrics (memory, GC, threads)
- HTTP request metrics
- Custom application metrics

**Usage:**
```bash
# Copy to your project
cp java-spring-boot-otlp.yml /path/to/your/project/src/main/resources/application-monitoring.yml

# Run with monitoring profile
java -jar app.jar --spring.profiles.active=monitoring

# Or combine profiles
java -jar app.jar --spring.profiles.active=prod,monitoring
```

### `generic-env-vars.sh`
Universal OpenTelemetry environment variables for any language/framework:

**Supported by:**
- Java (OpenTelemetry Java Agent)
- Python (OpenTelemetry Python SDK)
- Node.js (OpenTelemetry Node SDK)
- Go (OpenTelemetry Go SDK)
- .NET (OpenTelemetry .NET SDK)

**Usage:**
```bash
# Bash/Zsh
source generic-env-vars.sh
./your-application

# Docker
docker run --env-file generic-env-vars.sh your-image

# Docker Compose
services:
  app:
    env_file:
      - generic-env-vars.sh
```

---

## Language-Specific Examples

### Java with OpenTelemetry Agent

**1. Download OpenTelemetry Java Agent:**
```bash
curl -L -O https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
```

**2. Run with agent:**
```bash
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.exporter.otlp.endpoint=http://localhost:4318 \
  -Dotel.service.name=my-app \
  -jar app.jar
```

### Python

**1. Install OpenTelemetry:**
```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install
```

**2. Run instrumented:**
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_SERVICE_NAME=my-python-app
opentelemetry-instrument python app.py
```

### Node.js

**1. Install packages:**
```bash
npm install @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-otlp-http
```

**2. Create `tracing.js`:**
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://localhost:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
  serviceName: 'my-node-app',
});

sdk.start();
```

**3. Run:**
```bash
node -r ./tracing.js app.js
```

### Go

**1. Install packages:**
```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp
go get go.opentelemetry.io/otel/sdk
```

**2. Initialize in code:**
```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer() {
    exporter, _ := otlptracehttp.New(context.Background(),
        otlptracehttp.WithEndpoint("localhost:4318"),
        otlptracehttp.WithInsecure(),
    )

    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
    )
    otel.SetTracerProvider(tp)
}
```

### .NET

**1. Install packages:**
```bash
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
```

**2. Configure in `Program.cs`:**
```csharp
builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
        tracerProviderBuilder
            .AddAspNetCoreInstrumentation()
            .AddOtlpExporter(options =>
            {
                options.Endpoint = new Uri("http://localhost:4318");
            }));
```

---

## OTLP Configuration Reference

### Endpoints

| Protocol | URL | Use Case |
|----------|-----|----------|
| HTTP | `http://localhost:4318` | Most frameworks, easier debugging |
| gRPC | `http://localhost:4317` | Better performance, lower overhead |

### Key Environment Variables

```bash
# Core settings
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=my-service

# Resource attributes (metadata)
OTEL_RESOURCE_ATTRIBUTES=environment=production,version=1.0.0,team=backend

# Sampling (1.0 = 100%, 0.1 = 10%)
OTEL_TRACES_SAMPLER=traceidratio
OTEL_TRACES_SAMPLER_ARG=1.0

# Signal-specific endpoints
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4318/v1/traces
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://localhost:4318/v1/metrics
OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://localhost:4318/v1/logs
```

---

## Correlation with Trace IDs

To correlate logs with traces, include trace context in your logs:

### Logback (Java)
```xml
<pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} [trace_id=%X{trace_id} span_id=%X{span_id}] - %msg%n</pattern>
```

### Python (structlog)
```python
import structlog
from opentelemetry import trace

structlog.configure(
    processors=[
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        lambda _, __, event_dict: {
            **event_dict,
            "trace_id": trace.get_current_span().get_span_context().trace_id,
        },
    ]
)
```

---

## Testing Your Configuration

### 1. Generate Test Traffic
```bash
# HTTP requests
curl http://localhost:8080/api/test

# Load testing
ab -n 1000 -c 10 http://localhost:8080/api/test
```

### 2. Verify in Grafana
1. Open http://localhost:3002
2. Go to **Explore**
3. Select **Prometheus** → Query: `rate(http_server_requests_seconds_count[5m])`
4. Select **Loki** → Query: `{service_name="my-app"}`
5. Select **Tempo** → Search for traces

---

## Troubleshooting

### No Data Appearing

**Check application logs:**
```bash
# Look for OTLP export errors
grep -i "otlp\|opentelemetry\|export" application.log
```

**Verify endpoints are reachable:**
```bash
curl http://localhost:4318/v1/metrics
# Should return: 405 Method Not Allowed (endpoint exists)

curl http://localhost:12345
# Should show Alloy UI
```

**Check Alloy is receiving data:**
```bash
docker logs alloy | grep -i "received\|exported"
```

### High Cardinality Warnings

If you see cardinality warnings in Prometheus:
- Reduce trace sampling: `OTEL_TRACES_SAMPLER_ARG=0.1` (10%)
- Limit resource attributes
- Avoid user IDs or request IDs in metric labels

### Performance Impact

**Reduce overhead:**
- Use gRPC instead of HTTP: `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`
- Lower sampling rate: `OTEL_TRACES_SAMPLER_ARG=0.1`
- Batch exports instead of synchronous
- Disable unused instrumentations

---

## Best Practices

### 1. Service Naming
Use consistent, descriptive names:
```bash
OTEL_SERVICE_NAME=payments-api
OTEL_SERVICE_NAME=user-service
OTEL_SERVICE_NAME=notification-worker
```

### 2. Resource Attributes
Include useful metadata:
```bash
OTEL_RESOURCE_ATTRIBUTES=environment=production,version=v1.2.3,datacenter=us-east-1,team=payments
```

### 3. Sampling Strategy
- **Development**: 100% (`OTEL_TRACES_SAMPLER_ARG=1.0`)
- **Staging**: 50% (`OTEL_TRACES_SAMPLER_ARG=0.5`)
- **Production**: 10% (`OTEL_TRACES_SAMPLER_ARG=0.1`)

### 4. Sensitive Data
**Never log:**
- Passwords
- API keys
- Credit card numbers
- Personal identifiable information (PII)

Use log scrubbing or filtering in Alloy.

---

## Remote Server Configuration

If the monitoring server is on a different host:

```bash
# Replace localhost with server IP/hostname
export OTEL_EXPORTER_OTLP_ENDPOINT=http://monitoring-server:4318

# For production, use HTTPS
export OTEL_EXPORTER_OTLP_ENDPOINT=https://monitoring.example.com:4318
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer YOUR_TOKEN"
```

---

## Next Steps

1. **Start with one application** - Instrument your most critical service first
2. **Verify data flow** - Check Grafana dashboards for metrics, logs, and traces
3. **Set up alerts** - Configure Slack notifications in `../server/`
4. **Scale gradually** - Add more applications once the first one works

---

## Documentation

- **Server Setup**: `../server/README.md`
- **Detailed Guides**: `../docs/`
- **OpenTelemetry Docs**: https://opentelemetry.io/docs/

---

## Support

For issues:
- Check application logs for OTLP errors
- Verify server is running: `cd ../server && docker-compose ps`
- Review Alloy logs: `docker logs alloy`
