#!/bin/bash

# ========================================
# Generic OTLP Configuration - Environment Variables
# ========================================
# Works with any OpenTelemetry-compatible application
# Set these in your application environment

# ========================================
# REQUIRED: Basic Configuration
# ========================================

# OTLP endpoint (where to send telemetry)
export OTEL_EXPORTER_OTLP_ENDPOINT="http://monitoring-server:4318"

# Service identification
export OTEL_SERVICE_NAME="my-service-name"

# ========================================
# RECOMMENDED: Additional Configuration
# ========================================

# Service namespace (groups related services)
export OTEL_SERVICE_NAMESPACE="my-namespace"

# Resource attributes (additional metadata)
export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=production,service.version=1.0.0,service.instance.id=$(hostname)"

# Enable specific exporters
export OTEL_LOGS_EXPORTER="otlp"
export OTEL_METRICS_EXPORTER="otlp"
export OTEL_TRACES_EXPORTER="otlp"

# Protocol (http/protobuf or grpc)
export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"

# ========================================
# OPTIONAL: Separate Endpoints
# ========================================

# Use different endpoints for each signal type
# export OTEL_EXPORTER_OTLP_LOGS_ENDPOINT="http://monitoring-server:4318/v1/logs"
# export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="http://monitoring-server:4318/v1/metrics"
# export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://monitoring-server:4317/v1/traces"

# ========================================
# OPTIONAL: Batch Configuration
# ========================================

# Batch span processor settings
# export OTEL_BSP_SCHEDULE_DELAY="5000"          # Delay before export (ms)
# export OTEL_BSP_MAX_QUEUE_SIZE="2048"          # Max queue size
# export OTEL_BSP_MAX_EXPORT_BATCH_SIZE="512"    # Max batch size

# Batch log record processor settings
# export OTEL_BLRP_SCHEDULE_DELAY="1000"         # Delay before export (ms)
# export OTEL_BLRP_MAX_QUEUE_SIZE="2048"         # Max queue size
# export OTEL_BLRP_MAX_EXPORT_BATCH_SIZE="512"   # Max batch size

# ========================================
# OPTIONAL: Timeout Configuration
# ========================================

# Export timeout (milliseconds)
# export OTEL_EXPORTER_OTLP_TIMEOUT="10000"      # 10 seconds

# Specific timeouts per signal
# export OTEL_EXPORTER_OTLP_LOGS_TIMEOUT="10000"
# export OTEL_EXPORTER_OTLP_METRICS_TIMEOUT="10000"
# export OTEL_EXPORTER_OTLP_TRACES_TIMEOUT="10000"

# ========================================
# OPTIONAL: Headers (for authentication)
# ========================================

# Add custom headers (e.g., for authentication)
# export OTEL_EXPORTER_OTLP_HEADERS="api-key=your-api-key,custom-header=value"

# Specific headers per signal
# export OTEL_EXPORTER_OTLP_LOGS_HEADERS="api-key=logs-key"
# export OTEL_EXPORTER_OTLP_METRICS_HEADERS="api-key=metrics-key"
# export OTEL_EXPORTER_OTLP_TRACES_HEADERS="api-key=traces-key"

# ========================================
# OPTIONAL: Compression
# ========================================

# Enable gzip compression
# export OTEL_EXPORTER_OTLP_COMPRESSION="gzip"

# ========================================
# OPTIONAL: Sampling Configuration
# ========================================

# Trace sampling ratio (0.0 to 1.0)
# export OTEL_TRACES_SAMPLER="parentbased_traceidratio"
# export OTEL_TRACES_SAMPLER_ARG="0.1"  # Sample 10% of traces

# ========================================
# OPTIONAL: Log Level
# ========================================

# Set OTEL SDK log level
# export OTEL_LOG_LEVEL="info"  # debug, info, warn, error

# ========================================
# OPTIONAL: Propagators
# ========================================

# Context propagation format
# export OTEL_PROPAGATORS="tracecontext,baggage"  # W3C Trace Context

# ========================================
# Example Configurations by Environment
# ========================================

# --- Development ---
dev_config() {
  export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
  export OTEL_SERVICE_NAME="my-service-dev"
  export OTEL_SERVICE_NAMESPACE="development"
  export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=dev,service.version=dev-$(git rev-parse --short HEAD)"
  export OTEL_LOG_LEVEL="debug"
  export OTEL_TRACES_SAMPLER_ARG="1.0"  # Sample all traces in dev
}

# --- Staging ---
staging_config() {
  export OTEL_EXPORTER_OTLP_ENDPOINT="http://monitoring-staging:4318"
  export OTEL_SERVICE_NAME="my-service-staging"
  export OTEL_SERVICE_NAMESPACE="staging"
  export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=staging,service.version=${VERSION}"
  export OTEL_LOG_LEVEL="info"
  export OTEL_TRACES_SAMPLER_ARG="0.5"  # Sample 50%
}

# --- Production ---
production_config() {
  export OTEL_EXPORTER_OTLP_ENDPOINT="http://monitoring-prod:4318"
  export OTEL_SERVICE_NAME="my-service-prod"
  export OTEL_SERVICE_NAMESPACE="production"
  export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=production,service.version=${VERSION},k8s.cluster=prod-us-east"
  export OTEL_LOG_LEVEL="warn"
  export OTEL_TRACES_SAMPLER_ARG="0.1"  # Sample 10% in prod
  export OTEL_EXPORTER_OTLP_COMPRESSION="gzip"
}

# ========================================
# Docker Compose Example
# ========================================

# Create docker-compose.yml:
cat << 'EOF' > docker-compose.yml
services:
  your-app:
    image: your-app:latest
    environment:
      # OTLP Configuration
      - OTEL_SERVICE_NAME=my-service
      - OTEL_SERVICE_NAMESPACE=my-namespace
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4318
      - OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production
      - OTEL_LOGS_EXPORTER=otlp
      - OTEL_METRICS_EXPORTER=otlp
      - OTEL_TRACES_EXPORTER=otlp
    networks:
      - monitoring

networks:
  monitoring:
    external: true
EOF

# ========================================
# Kubernetes ConfigMap Example
# ========================================

# Create configmap:
kubectl create configmap otel-config \
  --from-literal=OTEL_SERVICE_NAME=my-service \
  --from-literal=OTEL_SERVICE_NAMESPACE=my-namespace \
  --from-literal=OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy.monitoring:4318 \
  --from-literal=OTEL_RESOURCE_ATTRIBUTES="deployment.environment=production"

# Use in pod:
cat << 'EOF' > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: my-app:latest
    envFrom:
    - configMapRef:
        name: otel-config
EOF

# ========================================
# Systemd Service Example
# ========================================

# Create /etc/systemd/system/my-app.service:
cat << 'EOF' > /etc/systemd/system/my-app.service
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=app
Environment="OTEL_SERVICE_NAME=my-service"
Environment="OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318"
Environment="OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production"
ExecStart=/usr/local/bin/my-app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ========================================
# Testing Configuration
# ========================================

# Test OTLP endpoint connectivity:
test_otlp_connection() {
  echo "Testing OTLP endpoint..."
  curl -v "${OTEL_EXPORTER_OTLP_ENDPOINT}/v1/logs" 2>&1 | grep -q "Connected"
  if [ $? -eq 0 ]; then
    echo "✓ OTLP endpoint is reachable"
  else
    echo "✗ Cannot reach OTLP endpoint"
    return 1
  fi
}

# Send test log:
send_test_log() {
  curl -X POST "${OTEL_EXPORTER_OTLP_ENDPOINT}/v1/logs" \
    -H "Content-Type: application/json" \
    -d "{
      \"resourceLogs\": [{
        \"resource\": {
          \"attributes\": [
            {\"key\": \"service.name\", \"value\": {\"stringValue\": \"${OTEL_SERVICE_NAME}\"}},
            {\"key\": \"service.namespace\", \"value\": {\"stringValue\": \"${OTEL_SERVICE_NAMESPACE}\"}}
          ]
        },
        \"scopeLogs\": [{
          \"logRecords\": [{
            \"timeUnixNano\": \"$(date +%s)000000000\",
            \"severityText\": \"INFO\",
            \"body\": {\"stringValue\": \"Test log from $(hostname)\"}
          }]
        }]
      }]
    }"
  echo "✓ Test log sent"
}

# Verify environment variables:
verify_config() {
  echo "=== OTLP Configuration ==="
  echo "Endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT}"
  echo "Service: ${OTEL_SERVICE_NAME}"
  echo "Namespace: ${OTEL_SERVICE_NAMESPACE}"
  echo "Attributes: ${OTEL_RESOURCE_ATTRIBUTES}"
  echo "=========================="
}

# ========================================
# Load Configuration Based on Environment
# ========================================

case "${ENV}" in
  dev|development)
    dev_config
    ;;
  staging)
    staging_config
    ;;
  prod|production)
    production_config
    ;;
  *)
    echo "Environment not specified. Using defaults."
    ;;
esac

# ========================================
# Usage Instructions
# ========================================

cat << 'USAGE'
# ========================================
# How to Use This Configuration
# ========================================

# 1. Source this file in your startup script:
source /path/to/generic-env-vars.sh

# 2. Or add to your .bashrc/.zshrc:
echo "source /path/to/generic-env-vars.sh" >> ~/.bashrc

# 3. Or export individual variables:
export OTEL_EXPORTER_OTLP_ENDPOINT="http://monitoring-server:4318"
export OTEL_SERVICE_NAME="my-service"

# 4. Or use with Docker:
docker run -e OTEL_EXPORTER_OTLP_ENDPOINT="http://alloy:4318" \
  -e OTEL_SERVICE_NAME="my-service" \
  your-app:latest

# 5. Verify configuration:
env | grep OTEL_

# 6. Test connectivity:
curl http://monitoring-server:4318/v1/logs -v

# ========================================
USAGE

# Uncomment to run tests on source:
# verify_config
# test_otlp_connection
# send_test_log
