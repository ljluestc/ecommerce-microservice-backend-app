#!/bin/bash

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; do
  echo "Waiting for Elasticsearch..."
  sleep 5
done
echo "Elasticsearch is ready!"

# Create index template
echo "Creating Elasticsearch index template..."
curl -X PUT "localhost:9200/_index_template/ecommerce-logs-template" \
  -H "Content-Type: application/json" \
  -d @elk-config/elasticsearch-setup.json

# Create initial indices with proper mappings
echo "Creating initial indices..."
curl -X PUT "localhost:9200/ecommerce-logs-$(date +%Y.%m.%d)" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  }'

curl -X PUT "localhost:9200/ecommerce-errors-$(date +%Y.%m.%d)" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  }'

curl -X PUT "localhost:9200/ecommerce-performance-$(date +%Y.%m.%d)" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  }'

# Create service-specific indices
for service in order-service payment-service user-service product-service shipping-service api-gateway; do
  curl -X PUT "localhost:9200/ecommerce-$service-$(date +%Y.%m.%d)" \
    -H "Content-Type: application/json" \
    -d '{
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      }
    }'
done

echo "Elasticsearch setup completed!"

# Wait for Kibana to be ready
echo "Waiting for Kibana to be ready..."
until curl -s http://localhost:5601/api/status | grep -q '"level":"available"'; do
  echo "Waiting for Kibana..."
  sleep 5
done
echo "Kibana is ready!"

# Create index patterns in Kibana
echo "Creating Kibana index patterns..."
curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-logs-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "ecommerce-logs-*",
      "timeFieldName": "@timestamp"
    }
  }'

curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-errors-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "ecommerce-errors-*",
      "timeFieldName": "@timestamp"
    }
  }'

curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-performance-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "ecommerce-performance-*",
      "timeFieldName": "@timestamp"
    }
  }'

curl -X POST "localhost:5601/api/saved_objects/index-pattern/metricbeat-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "metricbeat-*",
      "timeFieldName": "@timestamp"
    }
  }'

echo "Kibana index patterns created!"

echo "ELK stack initialization completed successfully!"