#!/bin/bash

set -e

echo "🚀 Starting ELK Stack with Ecommerce Microservices..."

# Function to check if a service is healthy
check_health() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    echo "Checking health of $service_name..."

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo "✅ $service_name is healthy!"
            return 0
        fi

        echo "⏳ Waiting for $service_name (attempt $attempt/$max_attempts)..."
        sleep 10
        attempt=$((attempt + 1))
    done

    echo "❌ $service_name failed to become healthy after $max_attempts attempts"
    return 1
}

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p logs

# Start ELK Stack
echo "🔥 Starting ELK Stack..."
docker-compose -f docker-compose-elk.yml up -d

# Wait for Elasticsearch to be ready
echo "⏳ Waiting for Elasticsearch..."
check_health "http://localhost:9200/_cluster/health" "Elasticsearch"

# Wait for Kibana to be ready
echo "⏳ Waiting for Kibana..."
check_health "http://localhost:5601/api/status" "Kibana"

# Initialize Elasticsearch indices and Kibana
echo "🔧 Setting up Elasticsearch indices and Kibana..."
./elk-init.sh

# Start Kibana dashboards setup
echo "📊 Setting up Kibana dashboards..."
./kibana-setup.sh

echo "🏗️ Starting microservices..."
# Start the microservices
docker-compose up -d

# Wait for services to be ready
services=(
    "http://localhost:8761:Service Discovery"
    "http://localhost:9296:Cloud Config"
    "http://localhost:8080:API Gateway"
    "http://localhost:8700/actuator/health:User Service"
    "http://localhost:8500/actuator/health:Product Service"
    "http://localhost:8300/actuator/health:Order Service"
    "http://localhost:8400/actuator/health:Payment Service"
    "http://localhost:8600/actuator/health:Shipping Service"
    "http://localhost:8800/actuator/health:Favourite Service"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r url name <<< "$service_info"
    check_health "$url" "$name" || echo "⚠️ $name may not be fully ready, but continuing..."
done

echo ""
echo "🎉 ELK Stack and Microservices are running!"
echo ""
echo "📍 Access Points:"
echo "  🔍 Elasticsearch: http://localhost:9200"
echo "  📊 Kibana:        http://localhost:5601"
echo "  🌐 API Gateway:   http://localhost:8080"
echo "  📡 Zipkin:        http://localhost:9411"
echo ""
echo "🔧 ELK Stack Services:"
echo "  📥 Logstash:      localhost:5044 (Beats), localhost:5000 (TCP/UDP)"
echo "  📈 APM Server:    http://localhost:8200"
echo ""
echo "🏪 Ecommerce Services:"
echo "  👤 User Service:     http://localhost:8700"
echo "  📦 Product Service:  http://localhost:8500"
echo "  🛒 Order Service:    http://localhost:8300"
echo "  💳 Payment Service:  http://localhost:8400"
echo "  🚚 Shipping Service: http://localhost:8600"
echo "  ❤️ Favourite Service: http://localhost:8800"
echo "  🔄 Proxy Client:     http://localhost:8900"
echo ""
echo "📚 To view logs in real-time:"
echo "  docker-compose -f docker-compose-elk.yml logs -f"
echo ""
echo "🛑 To stop everything:"
echo "  docker-compose -f docker-compose-elk.yml down"
echo "  docker-compose down"
echo ""

# Generate some sample logs
echo "📝 Generating sample logs..."
curl -s http://localhost:8080/actuator/health > /dev/null || true
curl -s http://localhost:8700/actuator/health > /dev/null || true
curl -s http://localhost:8500/actuator/health > /dev/null || true

echo "✨ Setup complete! Check Kibana at http://localhost:5601 for dashboards and logs."