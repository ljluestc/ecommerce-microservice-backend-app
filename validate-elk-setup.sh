#!/bin/bash

# ELK Stack Setup Validation Script

echo "🔍 Validating ELK Stack Configuration..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a file exists and is readable
check_file() {
    local file=$1
    local description=$2

    if [ -f "$file" ] && [ -r "$file" ]; then
        echo -e "${GREEN}✅ $description: $file${NC}"
        return 0
    else
        echo -e "${RED}❌ $description: $file (missing or unreadable)${NC}"
        return 1
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir=$1
    local description=$2

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $description: $dir${NC}"
        return 0
    else
        echo -e "${RED}❌ $description: $dir (missing)${NC}"
        return 1
    fi
}

# Function to validate YAML syntax
validate_yaml() {
    local file=$1
    local description=$2

    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✅ $description YAML syntax is valid${NC}"
            return 0
        else
            echo -e "${RED}❌ $description YAML syntax is invalid${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Python3 not found, skipping YAML validation for $description${NC}"
        return 0
    fi
}

# Function to validate JSON syntax
validate_json() {
    local file=$1
    local description=$2

    if command -v python3 &> /dev/null; then
        if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✅ $description JSON syntax is valid${NC}"
            return 0
        else
            echo -e "${RED}❌ $description JSON syntax is invalid${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Python3 not found, skipping JSON validation for $description${NC}"
        return 0
    fi
}

validation_errors=0

echo -e "\n${BLUE}📁 Checking Directory Structure${NC}"
check_directory "elk-config" "ELK Configuration Directory" || ((validation_errors++))
check_directory "elk-config/elasticsearch" "Elasticsearch Config Directory" || ((validation_errors++))
check_directory "elk-config/logstash" "Logstash Config Directory" || ((validation_errors++))
check_directory "elk-config/kibana" "Kibana Config Directory" || ((validation_errors++))
check_directory "elk-config/filebeat" "Filebeat Config Directory" || ((validation_errors++))
check_directory "elk-config/metricbeat" "Metricbeat Config Directory" || ((validation_errors++))
check_directory "logs" "Logs Directory" || ((validation_errors++))

echo -e "\n${BLUE}📄 Checking Configuration Files${NC}"

# Docker Compose files
check_file "docker-compose-elk.yml" "ELK Stack Docker Compose" || ((validation_errors++))
check_file "compose.yml" "Microservices Docker Compose" || ((validation_errors++))

# ELK Configuration files
check_file "elk-config/elasticsearch/elasticsearch.yml" "Elasticsearch Config" || ((validation_errors++))
check_file "elk-config/logstash/logstash.yml" "Logstash Config" || ((validation_errors++))
check_file "elk-config/logstash/pipelines.yml" "Logstash Pipelines Config" || ((validation_errors++))
check_file "elk-config/logstash/pipeline/logstash.conf" "Logstash Pipeline Config" || ((validation_errors++))
check_file "elk-config/kibana/kibana.yml" "Kibana Config" || ((validation_errors++))
check_file "elk-config/filebeat/filebeat.yml" "Filebeat Config" || ((validation_errors++))
check_file "elk-config/metricbeat/metricbeat.yml" "Metricbeat Config" || ((validation_errors++))

# Setup files
check_file "elk-config/elasticsearch-setup.json" "Elasticsearch Setup JSON" || ((validation_errors++))
check_file "elk-init.sh" "ELK Initialization Script" || ((validation_errors++))
check_file "kibana-setup.sh" "Kibana Setup Script" || ((validation_errors++))
check_file "start-elk-stack.sh" "Main Startup Script" || ((validation_errors++))

# Java source files
check_file "src/main/java/com/selimhorri/app/logging/StructuredLogger.java" "Structured Logger Class" || ((validation_errors++))
check_file "src/main/java/com/selimhorri/app/logging/LoggingInterceptor.java" "Logging Interceptor Class" || ((validation_errors++))
check_file "src/main/java/com/selimhorri/app/config/LoggingConfiguration.java" "Logging Configuration Class" || ((validation_errors++))

# Logback configuration
check_file "src/main/resources/logback-spring.xml" "Root Logback Configuration" || ((validation_errors++))

echo -e "\n${BLUE}🔧 Validating Configuration Syntax${NC}"

# Validate YAML files
if [ -f "docker-compose-elk.yml" ]; then
    validate_yaml "docker-compose-elk.yml" "ELK Docker Compose" || ((validation_errors++))
fi

if [ -f "elk-config/elasticsearch/elasticsearch.yml" ]; then
    validate_yaml "elk-config/elasticsearch/elasticsearch.yml" "Elasticsearch" || ((validation_errors++))
fi

if [ -f "elk-config/logstash/logstash.yml" ]; then
    validate_yaml "elk-config/logstash/logstash.yml" "Logstash" || ((validation_errors++))
fi

if [ -f "elk-config/kibana/kibana.yml" ]; then
    validate_yaml "elk-config/kibana/kibana.yml" "Kibana" || ((validation_errors++))
fi

if [ -f "elk-config/filebeat/filebeat.yml" ]; then
    validate_yaml "elk-config/filebeat/filebeat.yml" "Filebeat" || ((validation_errors++))
fi

if [ -f "elk-config/metricbeat/metricbeat.yml" ]; then
    validate_yaml "elk-config/metricbeat/metricbeat.yml" "Metricbeat" || ((validation_errors++))
fi

# Validate JSON files
if [ -f "elk-config/elasticsearch-setup.json" ]; then
    validate_json "elk-config/elasticsearch-setup.json" "Elasticsearch Setup" || ((validation_errors++))
fi

echo -e "\n${BLUE}🔍 Checking Script Permissions${NC}"

scripts=("elk-init.sh" "kibana-setup.sh" "start-elk-stack.sh" "validate-elk-setup.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✅ $script is executable${NC}"
        else
            echo -e "${YELLOW}⚠️ $script is not executable (run: chmod +x $script)${NC}"
        fi
    fi
done

echo -e "\n${BLUE}📦 Checking Service Structure${NC}"

services=("api-gateway" "order-service" "payment-service" "product-service" "shipping-service" "user-service" "favourite-service" "proxy-client")
for service in "${services[@]}"; do
    if [ -d "$service" ]; then
        echo -e "${GREEN}✅ Service directory: $service${NC}"

        # Check for logback configuration
        if [ -f "$service/src/main/resources/logback-spring.xml" ]; then
            echo -e "${GREEN}  ✅ Logback configuration present${NC}"
        else
            echo -e "${RED}  ❌ Logback configuration missing${NC}"
            ((validation_errors++))
        fi

        # Check for logging classes
        if [ -d "$service/src/main/java/com/selimhorri/app/logging" ]; then
            echo -e "${GREEN}  ✅ Logging classes present${NC}"
        else
            echo -e "${RED}  ❌ Logging classes missing${NC}"
            ((validation_errors++))
        fi
    else
        echo -e "${RED}❌ Service directory missing: $service${NC}"
        ((validation_errors++))
    fi
done

echo -e "\n${BLUE}🐳 Docker Configuration Check${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is installed${NC}"

    if docker info &> /dev/null; then
        echo -e "${GREEN}✅ Docker daemon is running${NC}"

        # Check Docker memory
        total_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null)
        if [ ! -z "$total_memory" ]; then
            # Convert bytes to GB
            memory_gb=$((total_memory / 1024 / 1024 / 1024))
            if [ $memory_gb -ge 8 ]; then
                echo -e "${GREEN}✅ Docker has sufficient memory: ${memory_gb}GB${NC}"
            else
                echo -e "${YELLOW}⚠️ Docker may need more memory for ELK stack (current: ${memory_gb}GB, recommended: 8GB+)${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        ((validation_errors++))
    fi

    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose is installed${NC}"
    else
        echo -e "${RED}❌ Docker Compose is not installed${NC}"
        ((validation_errors++))
    fi
else
    echo -e "${RED}❌ Docker is not installed${NC}"
    ((validation_errors++))
fi

echo -e "\n${BLUE}☕ Java/Maven Check${NC}"

if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
    echo -e "${GREEN}✅ Java is installed: $java_version${NC}"
else
    echo -e "${YELLOW}⚠️ Java is not installed (needed for building services)${NC}"
fi

if command -v mvn &> /dev/null; then
    mvn_version=$(mvn -version 2>&1 | head -n1 | awk '{print $3}')
    echo -e "${GREEN}✅ Maven is installed: $mvn_version${NC}"
else
    echo -e "${YELLOW}⚠️ Maven is not installed (needed for building services)${NC}"
fi

# Check root POM
if [ -f "pom.xml" ]; then
    if grep -q "logstash-logback-encoder" pom.xml; then
        echo -e "${GREEN}✅ Structured logging dependencies added to root POM${NC}"
    else
        echo -e "${RED}❌ Structured logging dependencies missing from root POM${NC}"
        ((validation_errors++))
    fi
fi

echo -e "\n${BLUE}📊 Summary${NC}"

if [ $validation_errors -eq 0 ]; then
    echo -e "${GREEN}🎉 Validation completed successfully! All checks passed.${NC}"
    echo -e "${GREEN}You can now run: ./start-elk-stack.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ Validation failed with $validation_errors error(s).${NC}"
    echo -e "${YELLOW}Please fix the issues above before starting the ELK stack.${NC}"
    exit 1
fi