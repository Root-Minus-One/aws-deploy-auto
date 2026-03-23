#!/bin/bash
# ==============================================================================
# Step 9: Grafana Dashboard Setup
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 9: Grafana Dashboard Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create Grafana dashboard JSON
echo "📊 Generating Grafana dashboard JSON..."

mkdir -p "$(dirname "$0")/grafana"

cat > "$(dirname "$0")/grafana/dashboard.json" << 'DASHBOARD_EOF'
{
  "dashboard": {
    "id": null,
    "uid": "gemini-chat-dashboard",
    "title": "Gemini Chat - Application Dashboard",
    "tags": ["gemini-chat", "ecs", "production"],
    "timezone": "browser",
    "refresh": "30s",
    "time": { "from": "now-6h", "to": "now" },
    "panels": [
      {
        "id": 1,
        "title": "📊 Request Rate",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 8, "x": 0, "y": 0 },
        "targets": [
          {
            "namespace": "gemini-chat",
            "metricName": "RequestCount",
            "statistics": ["Sum"],
            "period": "60",
            "label": "Requests/min"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": { "mode": "palette-classic" },
            "custom": { "fillOpacity": 20, "lineWidth": 2 }
          }
        }
      },
      {
        "id": 2,
        "title": "💬 Chat Requests",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 8, "x": 8, "y": 0 },
        "targets": [
          {
            "namespace": "gemini-chat",
            "metricName": "ChatRequests",
            "statistics": ["Sum"],
            "period": "60",
            "label": "Chat Requests/min"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": { "fixedColor": "#8AB4F8", "mode": "fixed" },
            "custom": { "fillOpacity": 20, "lineWidth": 2 }
          }
        }
      },
      {
        "id": 3,
        "title": "❌ Error Rate",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 8, "x": 16, "y": 0 },
        "targets": [
          {
            "namespace": "gemini-chat",
            "metricName": "ErrorCount",
            "statistics": ["Sum"],
            "period": "60",
            "label": "Errors/min"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": { "fixedColor": "#EA4335", "mode": "fixed" },
            "custom": { "fillOpacity": 30, "lineWidth": 2 },
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 5, "color": "yellow" },
                { "value": 10, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "id": 4,
        "title": "🖥️ Backend CPU Utilization",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 0, "y": 8 },
        "targets": [
          {
            "namespace": "AWS/ECS",
            "metricName": "CPUUtilization",
            "dimensions": {
              "ClusterName": "gemini-chat-cluster",
              "ServiceName": "gemini-chat-backend-service"
            },
            "statistics": ["Average"],
            "period": "60"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "max": 100, "min": 0, "unit": "percent",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 60, "color": "yellow" },
                { "value": 80, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "id": 5,
        "title": "💾 Backend Memory Utilization",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 6, "y": 8 },
        "targets": [
          {
            "namespace": "AWS/ECS",
            "metricName": "MemoryUtilization",
            "dimensions": {
              "ClusterName": "gemini-chat-cluster",
              "ServiceName": "gemini-chat-backend-service"
            },
            "statistics": ["Average"],
            "period": "60"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "max": 100, "min": 0, "unit": "percent",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 60, "color": "yellow" },
                { "value": 80, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "id": 6,
        "title": "🖥️ Frontend CPU Utilization",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 12, "y": 8 },
        "targets": [
          {
            "namespace": "AWS/ECS",
            "metricName": "CPUUtilization",
            "dimensions": {
              "ClusterName": "gemini-chat-cluster",
              "ServiceName": "gemini-chat-frontend-service"
            },
            "statistics": ["Average"],
            "period": "60"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "max": 100, "min": 0, "unit": "percent",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 60, "color": "yellow" },
                { "value": 80, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "id": 7,
        "title": "💾 Frontend Memory Utilization",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 18, "y": 8 },
        "targets": [
          {
            "namespace": "AWS/ECS",
            "metricName": "MemoryUtilization",
            "dimensions": {
              "ClusterName": "gemini-chat-cluster",
              "ServiceName": "gemini-chat-frontend-service"
            },
            "statistics": ["Average"],
            "period": "60"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "max": 100, "min": 0, "unit": "percent",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 60, "color": "yellow" },
                { "value": 80, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "id": 8,
        "title": "🔍 ALB Request Count",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 16 },
        "targets": [
          {
            "namespace": "AWS/ApplicationELB",
            "metricName": "RequestCount",
            "statistics": ["Sum"],
            "period": "60",
            "label": "ALB Requests/min"
          }
        ]
      },
      {
        "id": 9,
        "title": "⚡ ALB Target Response Time",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 12, "x": 12, "y": 16 },
        "targets": [
          {
            "namespace": "AWS/ApplicationELB",
            "metricName": "TargetResponseTime",
            "statistics": ["p50", "p95", "p99"],
            "period": "60"
          }
        ],
        "fieldConfig": {
          "defaults": { "unit": "s" }
        }
      }
    ]
  },
  "overwrite": true
}
DASHBOARD_EOF

echo "  ✓ Dashboard JSON saved to infra/grafana/dashboard.json"

# ─── Grafana Setup Instructions ───
cat > "$(dirname "$0")/grafana/README.md" << 'README_EOF'
# Grafana Setup for Gemini Chat

## Option 1: Amazon Managed Grafana (Recommended for AWS)

1. Go to **AWS Console → Amazon Managed Grafana**
2. Create a new workspace
3. Add **CloudWatch** as a data source
4. Import the dashboard:
   - Go to **Dashboards → Import**
   - Upload `dashboard.json`
   - Select your CloudWatch data source

## Option 2: Self-Hosted Grafana (Docker)

```bash
# Run Grafana locally
docker run -d \
  --name grafana \
  -p 3001:3000 \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  grafana/grafana:latest

# Access at http://localhost:3001 (admin/admin)
```

### Add CloudWatch Data Source:
1. Go to **Configuration → Data Sources → Add data source**
2. Select **CloudWatch**
3. Configure:
   - **Authentication Provider**: Access & secret key
   - **Access Key ID**: Your AWS access key
   - **Secret Access Key**: Your AWS secret key
   - **Default Region**: Your AWS region
4. Click **Save & Test**

### Import Dashboard:
1. Go to **Dashboards → Import**
2. Upload `dashboard.json`
3. Select your CloudWatch data source

## Prometheus Metrics

The backend also exposes Prometheus-format metrics at `/api/metrics`:
- `http_requests_total` - Total HTTP requests by method, endpoint, status
- `http_request_duration_seconds` - Request latency histogram
- `chat_requests_total` - Total chat requests
- `file_uploads_total` - Total file uploads

You can add Prometheus as an additional data source if running a Prometheus server.
README_EOF

echo "  ✓ Grafana setup instructions saved"
echo ""
echo "✅ Grafana configuration complete!"
echo "   Dashboard: infra/grafana/dashboard.json"
echo "   Instructions: infra/grafana/README.md"
echo ""
echo "🎉 All infrastructure setup complete!"
