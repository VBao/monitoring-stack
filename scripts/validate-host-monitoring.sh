#!/bin/bash

# Host Monitoring Validation Script
# Validates that all host monitoring components are working correctly

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}   Host Monitoring Validation${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

# Function to check if a service is running
check_service() {
    local service_name=$1
    if docker ps --format '{{.Names}}' | grep -q "^${service_name}$"; then
        echo -e "${GREEN}✓${NC} ${service_name} is running"
        return 0
    else
        echo -e "${RED}✗${NC} ${service_name} is NOT running"
        return 1
    fi
}

# Function to check HTTP endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected=$3

    if curl -sf "${url}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} ${name} endpoint is accessible: ${url}"
        return 0
    else
        echo -e "${RED}✗${NC} ${name} endpoint is NOT accessible: ${url}"
        return 1
    fi
}

# Function to check metrics endpoint for data
check_metrics() {
    local name=$1
    local url=$2
    local metric_pattern=$3

    if curl -sf "${url}" | grep -q "${metric_pattern}"; then
        echo -e "${GREEN}✓${NC} ${name} is exposing ${metric_pattern} metrics"
        return 0
    else
        echo -e "${RED}✗${NC} ${name} is NOT exposing ${metric_pattern} metrics"
        return 1
    fi
}

echo -e "${BOLD}1. Checking Docker Services${NC}"
echo "-----------------------------------"
check_service "node-exporter"
NODE_EXPORTER=$?

check_service "promtail"
PROMTAIL=$?

check_service "cadvisor"
CADVISOR=$?

echo ""
echo -e "${BOLD}2. Checking Endpoints${NC}"
echo "-----------------------------------"
check_endpoint "Node Exporter" "http://localhost:9100/metrics"
NODE_EXPORTER_EP=$?

check_endpoint "Promtail" "http://localhost:9080/ready"
PROMTAIL_EP=$?

check_endpoint "cAdvisor" "http://localhost:8080/metrics"
CADVISOR_EP=$?

echo ""
echo -e "${BOLD}3. Checking Metrics Data${NC}"
echo "-----------------------------------"
check_metrics "Node Exporter CPU" "http://localhost:9100/metrics" "node_cpu_seconds_total"
NODE_CPU=$?

check_metrics "Node Exporter Memory" "http://localhost:9100/metrics" "node_memory_MemTotal_bytes"
NODE_MEM=$?

check_metrics "cAdvisor Container CPU" "http://localhost:8080/metrics" "container_cpu_usage_seconds_total"
CADVISOR_CPU=$?

check_metrics "cAdvisor Container Memory" "http://localhost:8080/metrics" "container_memory_usage_bytes"
CADVISOR_MEM=$?

echo ""
echo -e "${BOLD}4. Checking Prometheus Scraping${NC}"
echo "-----------------------------------"

# Check if Prometheus is scraping node-exporter
if curl -sf "http://localhost:9090/api/v1/targets" | grep -q "node-exporter"; then
    echo -e "${GREEN}✓${NC} Prometheus is configured to scrape Node Exporter"
    PROM_NODE=0
else
    echo -e "${RED}✗${NC} Prometheus is NOT configured to scrape Node Exporter"
    PROM_NODE=1
fi

# Check if Prometheus is scraping cadvisor
if curl -sf "http://localhost:9090/api/v1/targets" | grep -q "cadvisor"; then
    echo -e "${GREEN}✓${NC} Prometheus is configured to scrape cAdvisor"
    PROM_CAD=0
else
    echo -e "${RED}✗${NC} Prometheus is NOT configured to scrape cAdvisor"
    PROM_CAD=1
fi

echo ""
echo -e "${BOLD}5. Checking Data in Prometheus${NC}"
echo "-----------------------------------"

# Check if node_exporter metrics are in Prometheus
if curl -sf "http://localhost:9090/api/v1/query?query=node_cpu_seconds_total" | grep -q '"status":"success"'; then
    echo -e "${GREEN}✓${NC} Node Exporter metrics are in Prometheus"
    PROM_NODE_DATA=0
else
    echo -e "${YELLOW}⚠${NC} Node Exporter metrics not yet in Prometheus (may need time to scrape)"
    PROM_NODE_DATA=1
fi

# Check if cAdvisor metrics are in Prometheus
if curl -sf "http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total" | grep -q '"status":"success"'; then
    echo -e "${GREEN}✓${NC} cAdvisor metrics are in Prometheus"
    PROM_CAD_DATA=0
else
    echo -e "${YELLOW}⚠${NC} cAdvisor metrics not yet in Prometheus (may need time to scrape)"
    PROM_CAD_DATA=1
fi

echo ""
echo -e "${BOLD}6. Checking Loki Log Ingestion${NC}"
echo "-----------------------------------"

# Check if Promtail can reach Loki
if docker exec promtail wget -q -O- http://loki:3100/ready 2>/dev/null | grep -q "ready"; then
    echo -e "${GREEN}✓${NC} Promtail can reach Loki"
    LOKI_REACH=0
else
    echo -e "${RED}✗${NC} Promtail CANNOT reach Loki"
    LOKI_REACH=1
fi

# Check if logs are being ingested
if curl -sf "http://localhost:3100/loki/api/v1/label" | grep -q "job"; then
    echo -e "${GREEN}✓${NC} Logs are being ingested into Loki"
    LOKI_DATA=0
else
    echo -e "${YELLOW}⚠${NC} No logs detected in Loki yet"
    LOKI_DATA=1
fi

echo ""
echo -e "${BOLD}7. Checking Grafana Dashboard${NC}"
echo "-----------------------------------"

# Check if host-monitoring dashboard exists
if [ -f "grafana/dashboards/host-monitoring.json" ]; then
    echo -e "${GREEN}✓${NC} Host monitoring dashboard file exists"
    DASH_FILE=0
else
    echo -e "${RED}✗${NC} Host monitoring dashboard file NOT found"
    DASH_FILE=1
fi

echo ""
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}   Validation Summary${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

# Count failures
FAILURES=$((NODE_EXPORTER + PROMTAIL + CADVISOR + NODE_EXPORTER_EP + PROMTAIL_EP + CADVISOR_EP + NODE_CPU + NODE_MEM + CADVISOR_CPU + CADVISOR_MEM + PROM_NODE + PROM_CAD + LOKI_REACH + DASH_FILE))
WARNINGS=$((PROM_NODE_DATA + PROM_CAD_DATA + LOKI_DATA))

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) - data may need time to appear${NC}"
    fi
    echo ""
    echo "Your host monitoring stack is working correctly!"
    echo ""
    echo "Access dashboards at:"
    echo "  - Grafana: http://localhost:3002"
    echo "  - Prometheus: http://localhost:9090"
    echo "  - Node Exporter: http://localhost:9100"
    echo "  - cAdvisor: http://localhost:8080"
    exit 0
else
    echo -e "${RED}✗ ${FAILURES} check(s) failed${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check Docker services: docker ps"
    echo "  2. View logs: docker-compose logs -f"
    echo "  3. Restart services: docker-compose restart"
    echo "  4. Ensure ports are not in use: netstat -tuln | grep -E '9100|9080|8080'"
    exit 1
fi
