# Ecommerce Microservices with ELK Stack

This project implements a complete ELK (Elasticsearch, Logstash, Kibana) stack with Beats for comprehensive monitoring and logging of ecommerce microservices.

## 🏗️ Architecture Overview

### ELK Stack Components

- **Elasticsearch**: Distributed document store for logs and metrics
- **Logstash**: Data pipeline for processing and transforming logs
- **Kibana**: Visualization and analytics platform
- **Filebeat**: Lightweight log shipper
- **Metricbeat**: System and service metrics collector
- **APM Server**: Application Performance Monitoring

### Microservices

- **API Gateway** (Port 8080): Entry point for all requests
- **User Service** (Port 8700): User management
- **Product Service** (Port 8500): Product catalog
- **Order Service** (Port 8300): Order processing
- **Payment Service** (Port 8400): Payment handling
- **Shipping Service** (Port 8600): Shipping logistics
- **Favourite Service** (Port 8800): User favorites
- **Service Discovery** (Port 8761): Eureka service registry
- **Cloud Config** (Port 9296): Configuration management
- **Proxy Client** (Port 8900): Frontend proxy

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 8GB RAM available for ELK stack
- Java 11+ for microservices
- Maven for building services

### 1. Start the ELK Stack and Microservices

```bash
# Make scripts executable
chmod +x start-elk-stack.sh elk-init.sh kibana-setup.sh

# Start everything
./start-elk-stack.sh
```

### 2. Access the Stack

- **Kibana Dashboard**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200
- **API Gateway**: http://localhost:8080
- **Zipkin Tracing**: http://localhost:9411

### 3. View Logs and Metrics

Navigate to Kibana at http://localhost:5601 to explore:

- **Discover**: Real-time log exploration
- **Visualizations**: Pre-built charts and graphs
- **Dashboards**: Comprehensive monitoring dashboards

## 📊 Monitoring Features

### Structured Logging

All microservices use structured JSON logging with the following fields:

```json
{
  "@timestamp": "2025-01-26T10:30:00.000Z",
  "service": "order-service",
  "log_level": "INFO",
  "logger": "com.selimhorri.app.controller.OrderController",
  "message": "Order created successfully",
  "request_id": "uuid-123",
  "user_id": "user-456",
  "http_method": "POST",
  "request_path": "/api/orders",
  "response_code": 201,
  "response_time": 150,
  "environment": "development"
}
```

### Key Metrics Tracked

1. **Request Metrics**
   - Request volume per service
   - Response times and latencies
   - HTTP status code distribution
   - Top endpoints by traffic

2. **Error Monitoring**
   - Error rates by service
   - Exception types and messages
   - Stack traces for debugging
   - Error trends over time

3. **Performance Metrics**
   - Service response times
   - Database query performance
   - Memory and CPU usage
   - Garbage collection metrics

4. **Business Metrics**
   - Order creation rates
   - Payment success rates
   - User activity patterns
   - Product search trends

### Log Categories

Logs are automatically categorized into different Elasticsearch indices:

- `ecommerce-logs-*`: General application logs
- `ecommerce-errors-*`: Error logs and exceptions
- `ecommerce-performance-*`: Performance-related logs
- `ecommerce-{service}-*`: Service-specific logs
- `metricbeat-*`: System and application metrics

## 🔧 Configuration

### Elasticsearch Configuration

Located in `elk-config/elasticsearch/elasticsearch.yml`:

- Single node setup for development
- Security disabled for simplicity
- Memory optimized settings
- Custom index templates

### Logstash Pipeline

Located in `elk-config/logstash/pipeline/logstash.conf`:

- Beats input on port 5044
- TCP/UDP input on port 5000
- Grok patterns for Spring Boot logs
- JSON parsing for structured logs
- Multiple output indices based on log type

### Kibana Setup

Located in `elk-config/kibana/kibana.yml`:

- Connected to Elasticsearch
- Index patterns pre-configured
- Visualizations and dashboards ready

### Filebeat Configuration

Located in `elk-config/filebeat/filebeat.yml`:

- Monitors log files and Docker containers
- Sends data to Logstash
- Docker metadata enrichment

### Metricbeat Configuration

Located in `elk-config/metricbeat/metricbeat.yml`:

- System metrics collection
- Docker container metrics
- JVM metrics via Jolokia
- HTTP endpoint monitoring

## 📈 Pre-built Dashboards

### Ecommerce Overview Dashboard

- Service health overview
- Request volume trends
- Error rate monitoring
- Response time distribution
- Top endpoints analysis

### Service-Specific Dashboards

Each microservice has dedicated monitoring with:

- Request patterns
- Error rates
- Performance metrics
- Business KPIs

## 🛠️ Development

### Adding Custom Logging

Use the structured logger in your services:

```java
import com.selimhorri.app.logging.StructuredLogger;

public class OrderController {
    private static final StructuredLogger logger = StructuredLogger.getLogger(OrderController.class);

    @PostMapping("/orders")
    public ResponseEntity<Order> createOrder(@RequestBody OrderRequest request) {
        long startTime = System.currentTimeMillis();

        try {
            // Business logic
            Order order = orderService.createOrder(request);

            // Log successful business event
            Map<String, Object> fields = Map.of(
                "orderId", order.getId(),
                "userId", request.getUserId(),
                "amount", order.getTotalAmount()
            );
            logger.logBusiness("ORDER_CREATED", "order", "create", fields);

            long duration = System.currentTimeMillis() - startTime;
            logger.logPerformance("createOrder", duration, fields);

            return ResponseEntity.ok(order);
        } catch (Exception e) {
            logger.logError("createOrder", "Failed to create order", e,
                Map.of("userId", request.getUserId()));
            throw e;
        }
    }
}
```

### Custom Grok Patterns

Add custom patterns in `elk-config/logstash/pipeline/logstash.conf`:

```ruby
# Custom pattern for payment logs
if [service_name] == "payment-service" {
  grok {
    match => {
      "log_message" => "Payment %{WORD:payment_status} for amount %{NUMBER:amount} user %{WORD:user_id}"
    }
  }
  mutate {
    add_tag => ["payment", "business-critical"]
  }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Elasticsearch won't start**
   ```bash
   # Check available memory
   docker stats
   # Increase Docker memory to 8GB+
   ```

2. **Logs not appearing in Kibana**
   ```bash
   # Check Logstash logs
   docker-compose -f docker-compose-elk.yml logs logstash

   # Verify Filebeat is running
   docker-compose -f docker-compose-elk.yml logs filebeat
   ```

3. **High memory usage**
   ```bash
   # Reduce Elasticsearch heap size in docker-compose-elk.yml
   ES_JAVA_OPTS: "-Xms1g -Xmx1g"
   ```

### Health Checks

```bash
# Check Elasticsearch cluster health
curl http://localhost:9200/_cluster/health

# Check Kibana status
curl http://localhost:5601/api/status

# Check Logstash status
curl http://localhost:9600/_node/stats

# View all indices
curl http://localhost:9200/_cat/indices?v
```

## 🛑 Stopping the Stack

```bash
# Stop ELK stack
docker-compose -f docker-compose-elk.yml down

# Stop microservices
docker-compose down

# Remove volumes (caution: deletes all data)
docker-compose -f docker-compose-elk.yml down -v
```

## 📚 Additional Resources

### ELK Stack Documentation

- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Reference](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana User Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Beats Platform](https://www.elastic.co/guide/en/beats/libbeat/current/index.html)

### Grok Pattern Testing

- [Grok Debugger](https://grokdebug.herokuapp.com/)
- [Grok Patterns](https://github.com/elastic/logstash/tree/main/patterns)

### Performance Tuning

- [Elasticsearch Performance Tips](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html)
- [Logstash Performance Tuning](https://www.elastic.co/guide/en/logstash/current/tuning-logstash.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your logging enhancements
4. Test with the ELK stack
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.