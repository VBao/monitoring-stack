#!/bin/bash

# Monitoring Stack Configuration Validator
# This script validates all configuration files before deployment

# Note: We don't use 'set -e' here because validation checks are expected
# to return non-zero codes for failed validations, which should not terminate the script

echo "🔍 Monitoring Stack Configuration Validator"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Helper functions
check_passed() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((CHECKS++))
}

check_failed() {
    echo -e "  ${RED}✗${NC} $1"
    ((ERRORS++))
    ((CHECKS++))
}

check_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
    ((CHECKS++))
}

# Check if file exists
check_file_exists() {
    if [ -f "$1" ]; then
        check_passed "File exists: $1"
    else
        check_failed "File missing: $1"
    fi
}

echo -e "\n${BLUE}📁 Checking file structure...${NC}"

# Check required files
check_file_exists "docker-compose.yml"
check_file_exists "alloy/config.alloy" 
check_file_exists "loki/loki-config.yaml"
check_file_exists "tempo/tempo.yaml"
check_file_exists "prometheus/prometheus.yml"

# Check documentation files
if [ -d "docs" ]; then
    check_passed "Documentation directory exists"
    check_file_exists "docs/alloy-config-guide.md"
    check_file_exists "docs/loki-config-guide.md"
    check_file_exists "docs/tempo-config-guide.md"
    check_file_exists "docs/prometheus-config-guide.md"
else
    check_warning "Documentation directory missing (optional)"
fi

echo -e "\n${BLUE}🐳 Validating Docker Compose...${NC}"

# Validate Docker Compose
if command -v docker-compose &> /dev/null; then
    if docker-compose config &> /dev/null; then
        check_passed "Docker Compose configuration is valid"
    else
        check_failed "Docker Compose configuration has errors"
        echo "Run 'docker-compose config' for details"
    fi
else
    check_warning "docker-compose not found, skipping validation"
fi

echo -e "\n${BLUE}🔧 Validating Alloy configuration...${NC}"

# Check Alloy syntax
if [ -f "alloy/config.alloy" ]; then
    # Basic syntax checks
    if grep -q "otelcol.receiver.otlp" "alloy/config.alloy"; then
        check_passed "OTLP receiver configured"
    else
        check_warning "No OTLP receiver found"
    fi
    
    if grep -q "otelcol.processor.batch" "alloy/config.alloy"; then
        check_passed "Batch processor configured"
    else
        check_warning "No batch processor found"
    fi
    
    # Check for proper endpoints
    if grep -q "0.0.0.0:4317" "alloy/config.alloy"; then
        check_passed "OTLP gRPC endpoint configured"
    else
        check_warning "OTLP gRPC endpoint may not be configured"
    fi
    
    # Security check
    if grep -q "insecure = true" "alloy/config.alloy"; then
        check_warning "Insecure TLS settings detected (development only)"
    fi
fi

echo -e "\n${BLUE}📊 Validating Prometheus configuration...${NC}"

# Validate Prometheus with promtool if available
if [ -f "prometheus/prometheus.yml" ]; then
    if command -v promtool &> /dev/null; then
        if promtool check config prometheus/prometheus.yml &> /dev/null; then
            check_passed "Prometheus configuration is valid"
        else
            check_failed "Prometheus configuration has errors"
            echo "Run 'promtool check config prometheus/prometheus.yml' for details"
        fi
    else
        check_warning "promtool not found, performing basic checks"
        
        # Basic checks
        if grep -q "global:" "prometheus/prometheus.yml"; then
            check_passed "Global configuration section present"
        else
            check_failed "Missing global configuration section"
        fi
        
        if grep -q "scrape_configs:" "prometheus/prometheus.yml"; then
            check_passed "Scrape configurations present"
        else
            check_failed "Missing scrape configurations"
        fi
    fi
fi

echo -e "\n${BLUE}📋 Validating Loki configuration...${NC}"

if [ -f "loki/loki-config.yaml" ]; then
    # Basic YAML syntax check
    if command -v python3 &> /dev/null && python3 -c "import yaml" &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('loki/loki-config.yaml'))" &> /dev/null; then
            check_passed "Loki YAML syntax is valid"
        else
            check_failed "Loki YAML syntax errors"
        fi
    else
        check_warning "Python3 or PyYAML not available, skipping YAML syntax validation"
    fi
    
    # Check required sections
    if grep -q "server:" "loki/loki-config.yaml"; then
        check_passed "Server configuration present"
    else
        check_failed "Missing server configuration"
    fi
    
    if grep -q "schema_config:" "loki/loki-config.yaml"; then
        check_passed "Schema configuration present"
    else
        check_failed "Missing schema configuration"
    fi
    
    if grep -q "storage_config:" "loki/loki-config.yaml"; then
        check_passed "Storage configuration present"
    else
        check_failed "Missing storage configuration"
    fi
    
    # Check for proper schema version
    if grep -q "schema: v13" "loki/loki-config.yaml"; then
        check_passed "Using current schema version (v13)"
    else
        check_warning "May not be using latest schema version"
    fi
fi

echo -e "\n${BLUE}🔍 Validating Tempo configuration...${NC}"

if [ -f "tempo/tempo.yaml" ]; then
    # Basic YAML syntax check
    if command -v python3 &> /dev/null && python3 -c "import yaml" &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('tempo/tempo.yaml'))" &> /dev/null; then
            check_passed "Tempo YAML syntax is valid"
        else
            check_failed "Tempo YAML syntax errors"
        fi
    else
        check_warning "Python3 or PyYAML not available, skipping YAML syntax validation"
    fi
    
    # Check required sections
    if grep -q "server:" "tempo/tempo.yaml"; then
        check_passed "Server configuration present"
    else
        check_failed "Missing server configuration"
    fi
    
    if grep -q "distributor:" "tempo/tempo.yaml"; then
        check_passed "Distributor configuration present"
    else
        check_failed "Missing distributor configuration"
    fi
    
    if grep -q "storage:" "tempo/tempo.yaml"; then
        check_passed "Storage configuration present"
    else
        check_failed "Missing storage configuration"
    fi
    
    # Check for OTLP receiver
    if grep -q "otlp:" "tempo/tempo.yaml"; then
        check_passed "OTLP receiver configured"
    else
        check_warning "OTLP receiver may not be configured"
    fi
fi

echo -e "\n${BLUE}🔌 Checking port configurations...${NC}"

# Check for port conflicts in docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    # Common ports to check
    PORTS=("3000" "3002" "3100" "3200" "4317" "4318" "9090" "12345")
    
    for port in "${PORTS[@]}"; do
        if grep -q "$port:" "docker-compose.yml"; then
            check_passed "Port $port configured in docker-compose.yml"
        fi
    done
    
    # Check for duplicate port mappings
    DUPLICATE_PORTS=$(grep -E "^\s*-\s*\"[0-9]+:" docker-compose.yml | cut -d'"' -f2 | cut -d':' -f1 | sort | uniq -d)
    if [ -z "$DUPLICATE_PORTS" ]; then
        check_passed "No duplicate port mappings found"
    else
        check_failed "Duplicate port mappings detected: $DUPLICATE_PORTS"
    fi
fi

echo -e "\n${BLUE}🔒 Security configuration checks...${NC}"

# Check for security considerations
if [ -f "docker-compose.yml" ]; then
    if grep -q "GF_SECURITY_ADMIN_PASSWORD" "docker-compose.yml"; then
        if grep -q "GF_SECURITY_ADMIN_PASSWORD=admin" "docker-compose.yml"; then
            check_warning "Default Grafana admin password detected (change for production)"
        else
            check_passed "Custom Grafana admin password configured"
        fi
    else
        check_warning "Grafana admin password not explicitly set"
    fi
fi

if [ -f "loki/loki-config.yaml" ]; then
    if grep -q "auth_enabled: false" "loki/loki-config.yaml"; then
        check_warning "Loki authentication disabled (development only)"
    fi
fi

echo -e "\n${BLUE}💾 Volume and persistence checks...${NC}"

if [ -f "docker-compose.yml" ]; then
    # Check for named volumes
    VOLUMES=("grafana-storage" "tempo-data" "loki-data" "prometheus-data")
    
    for volume in "${VOLUMES[@]}"; do
        if grep -q "$volume:" "docker-compose.yml"; then
            check_passed "Volume $volume configured for persistence"
        else
            check_warning "Volume $volume may not be configured"
        fi
    done
fi

echo -e "\n${BLUE}📈 Performance and resource checks...${NC}"

# Check for resource limits
if [ -f "docker-compose.yml" ]; then
    if grep -q "deploy:" "docker-compose.yml"; then
        check_passed "Resource limits configured"
    else
        check_warning "No resource limits set (consider adding for production)"
    fi
    
    if grep -q "restart:" "docker-compose.yml"; then
        check_passed "Restart policies configured"
    else
        check_warning "No restart policies set"
    fi
fi

# Summary
echo -e "\n${BLUE}📊 Validation Summary${NC}"
echo "===================="
echo -e "Total checks: ${CHECKS}"
echo -e "${GREEN}Passed: $((CHECKS - ERRORS - WARNINGS))${NC}"
echo -e "${YELLOW}Warnings: ${WARNINGS}${NC}"
echo -e "${RED}Errors: ${ERRORS}${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "\n${GREEN}✅ Configuration validation completed successfully!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: Please review warnings for production deployment.${NC}"
    fi
    exit 0
else
    echo -e "\n${RED}❌ Configuration validation failed with $ERRORS error(s).${NC}"
    echo "Please fix the errors before deploying the stack."
    exit 1
fi
