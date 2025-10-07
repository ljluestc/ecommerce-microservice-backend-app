#!/bin/bash

# Wait for Kibana to be ready
echo "Waiting for Kibana to be ready..."
until curl -s http://localhost:5601/api/status | grep -q '"level":"available"'; do
  echo "Waiting for Kibana..."
  sleep 10
done
echo "Kibana is ready!"

# Create index patterns
echo "Creating index patterns..."

# Logs index patterns
curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-logs-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "ecommerce-logs-*",
      "timeFieldName": "@timestamp"
    }
  }' || true

curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-errors-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "ecommerce-errors-*",
      "timeFieldName": "@timestamp"
    }
  }' || true

curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-performance-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "ecommerce-performance-*",
      "timeFieldName": "@timestamp"
    }
  }' || true

# Service-specific index patterns
for service in order-service payment-service user-service product-service shipping-service api-gateway; do
  curl -X POST "localhost:5601/api/saved_objects/index-pattern/ecommerce-$service-*" \
    -H "Content-Type: application/json" \
    -H "kbn-xsrf: true" \
    -d "{
      \"attributes\": {
        \"title\": \"ecommerce-$service-*\",
        \"timeFieldName\": \"@timestamp\"
      }
    }" || true
done

# Metrics index pattern
curl -X POST "localhost:5601/api/saved_objects/index-pattern/metricbeat-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "metricbeat-*",
      "timeFieldName": "@timestamp"
    }
  }' || true

echo "Index patterns created!"

# Create visualizations
echo "Creating visualizations..."

# Log Level Distribution
curl -X POST "localhost:5601/api/saved_objects/visualization" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "Log Level Distribution",
      "type": "pie",
      "params": {
        "addTooltip": true,
        "addLegend": true,
        "legendPosition": "right"
      },
      "aggs": [
        {
          "id": "1",
          "type": "count",
          "schema": "metric",
          "params": {}
        },
        {
          "id": "2",
          "type": "terms",
          "schema": "segment",
          "params": {
            "field": "log_level.keyword",
            "size": 5,
            "order": "desc",
            "orderBy": "1"
          }
        }
      ]
    },
    "references": [
      {
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern",
        "id": "ecommerce-logs-*"
      }
    ]
  }' || true

# Service Request Volume
curl -X POST "localhost:5601/api/saved_objects/visualization" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "Service Request Volume",
      "type": "line",
      "params": {
        "grid": {"categoryLines": false, "style": {"color": "#eee"}},
        "categoryAxes": [{"id": "CategoryAxis-1", "type": "category", "position": "bottom", "show": true, "style": {}, "scale": {"type": "linear"}, "labels": {"show": true, "truncate": 100}, "title": {}}],
        "valueAxes": [{"id": "ValueAxis-1", "name": "LeftAxis-1", "type": "value", "position": "left", "show": true, "style": {}, "scale": {"type": "linear", "mode": "normal"}, "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100}, "title": {"text": "Count"}}]
      },
      "aggs": [
        {
          "id": "1",
          "type": "count",
          "schema": "metric",
          "params": {}
        },
        {
          "id": "2",
          "type": "date_histogram",
          "schema": "segment",
          "params": {
            "field": "@timestamp",
            "interval": "auto",
            "customInterval": "2h",
            "min_doc_count": 1,
            "extended_bounds": {}
          }
        },
        {
          "id": "3",
          "type": "terms",
          "schema": "group",
          "params": {
            "field": "service_name.keyword",
            "size": 10,
            "order": "desc",
            "orderBy": "1"
          }
        }
      ]
    },
    "references": [
      {
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern",
        "id": "ecommerce-logs-*"
      }
    ]
  }' || true

# Response Time Distribution
curl -X POST "localhost:5601/api/saved_objects/visualization" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "Response Time Distribution",
      "type": "histogram",
      "params": {
        "grid": {"categoryLines": false, "style": {"color": "#eee"}},
        "categoryAxes": [{"id": "CategoryAxis-1", "type": "category", "position": "bottom", "show": true, "style": {}, "scale": {"type": "linear"}, "labels": {"show": true, "truncate": 100}, "title": {}}],
        "valueAxes": [{"id": "ValueAxis-1", "name": "LeftAxis-1", "type": "value", "position": "left", "show": true, "style": {}, "scale": {"type": "linear", "mode": "normal"}, "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100}, "title": {"text": "Count"}}]
      },
      "aggs": [
        {
          "id": "1",
          "type": "count",
          "schema": "metric",
          "params": {}
        },
        {
          "id": "2",
          "type": "histogram",
          "schema": "segment",
          "params": {
            "field": "response_time",
            "interval": 100,
            "extended_bounds": {}
          }
        }
      ]
    },
    "references": [
      {
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern",
        "id": "ecommerce-performance-*"
      }
    ]
  }' || true

# Error Rate by Service
curl -X POST "localhost:5601/api/saved_objects/visualization" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "Error Rate by Service",
      "type": "line",
      "params": {
        "grid": {"categoryLines": false, "style": {"color": "#eee"}},
        "categoryAxes": [{"id": "CategoryAxis-1", "type": "category", "position": "bottom", "show": true, "style": {}, "scale": {"type": "linear"}, "labels": {"show": true, "truncate": 100}, "title": {}}],
        "valueAxes": [{"id": "ValueAxis-1", "name": "LeftAxis-1", "type": "value", "position": "left", "show": true, "style": {}, "scale": {"type": "linear", "mode": "normal"}, "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100}, "title": {"text": "Count"}}]
      },
      "aggs": [
        {
          "id": "1",
          "type": "count",
          "schema": "metric",
          "params": {}
        },
        {
          "id": "2",
          "type": "date_histogram",
          "schema": "segment",
          "params": {
            "field": "@timestamp",
            "interval": "auto",
            "customInterval": "2h",
            "min_doc_count": 1,
            "extended_bounds": {}
          }
        },
        {
          "id": "3",
          "type": "terms",
          "schema": "group",
          "params": {
            "field": "service_name.keyword",
            "size": 10,
            "order": "desc",
            "orderBy": "1"
          }
        }
      ]
    },
    "references": [
      {
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern",
        "id": "ecommerce-errors-*"
      }
    ]
  }' || true

# Top Endpoints
curl -X POST "localhost:5601/api/saved_objects/visualization" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "Top Endpoints",
      "type": "table",
      "params": {
        "perPage": 10,
        "showPartialRows": false,
        "showMeticsAtAllLevels": false,
        "sort": {"columnIndex": null, "direction": null},
        "showTotal": false,
        "totalFunc": "sum"
      },
      "aggs": [
        {
          "id": "1",
          "type": "count",
          "schema": "metric",
          "params": {}
        },
        {
          "id": "2",
          "type": "terms",
          "schema": "bucket",
          "params": {
            "field": "request_path.keyword",
            "size": 20,
            "order": "desc",
            "orderBy": "1"
          }
        },
        {
          "id": "3",
          "type": "terms",
          "schema": "bucket",
          "params": {
            "field": "http_method.keyword",
            "size": 10,
            "order": "desc",
            "orderBy": "1"
          }
        }
      ]
    },
    "references": [
      {
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern",
        "id": "ecommerce-logs-*"
      }
    ]
  }' || true

echo "Visualizations created!"
echo "Kibana setup completed successfully!"
echo "Access Kibana at http://localhost:5601"