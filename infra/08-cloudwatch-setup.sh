#!/bin/bash
# ==============================================================================
# Step 8: CloudWatch Log Groups, Metric Filters, Alarms
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 8: Setting Up CloudWatch Logging & Alarms"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Create Log Groups ───
echo "📋 Creating CloudWatch log groups..."

aws logs create-log-group \
    --log-group-name "${LOG_GROUP_BACKEND}" \
    --retention-in-days 30 \
    --region "${AWS_REGION}" 2>/dev/null || echo "  ℹ️  Backend log group already exists"

aws logs create-log-group \
    --log-group-name "${LOG_GROUP_FRONTEND}" \
    --retention-in-days 30 \
    --region "${AWS_REGION}" 2>/dev/null || echo "  ℹ️  Frontend log group already exists"

echo "  ✓ ${LOG_GROUP_BACKEND} (30 day retention)"
echo "  ✓ ${LOG_GROUP_FRONTEND} (30 day retention)"

# ─── Metric Filters ───
echo "📊 Creating metric filters..."

# Error count metric
aws logs put-metric-filter \
    --log-group-name "${LOG_GROUP_BACKEND}" \
    --filter-name "${PROJECT_NAME}-error-count" \
    --filter-pattern '{ $.level = "ERROR" }' \
    --metric-transformations \
        metricName=ErrorCount,metricNamespace="${PROJECT_NAME}",metricValue=1,defaultValue=0 \
    --region "${AWS_REGION}"
echo "  ✓ Error count metric filter"

# Request latency metric (from structured logs)
aws logs put-metric-filter \
    --log-group-name "${LOG_GROUP_BACKEND}" \
    --filter-name "${PROJECT_NAME}-request-latency" \
    --filter-pattern '{ $.message = "←*" }' \
    --metric-transformations \
        metricName=RequestCount,metricNamespace="${PROJECT_NAME}",metricValue=1,defaultValue=0 \
    --region "${AWS_REGION}"
echo "  ✓ Request count metric filter"

# Chat request metric
aws logs put-metric-filter \
    --log-group-name "${LOG_GROUP_BACKEND}" \
    --filter-name "${PROJECT_NAME}-chat-requests" \
    --filter-pattern '{ $.message = "Chat in*" }' \
    --metric-transformations \
        metricName=ChatRequests,metricNamespace="${PROJECT_NAME}",metricValue=1,defaultValue=0 \
    --region "${AWS_REGION}"
echo "  ✓ Chat requests metric filter"

# ─── CloudWatch Alarms ───
echo "🔔 Creating CloudWatch alarms..."

# High error rate alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-high-error-rate" \
    --alarm-description "Fires when error rate exceeds 10 errors in 5 minutes" \
    --metric-name ErrorCount \
    --namespace "${PROJECT_NAME}" \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --treat-missing-data notBreaching \
    --region "${AWS_REGION}"
echo "  ✓ High error rate alarm (>10 errors/5min)"

# CPU utilization alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-high-cpu" \
    --alarm-description "Backend ECS service CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace "AWS/ECS" \
    --dimensions Name=ClusterName,Value="${ECS_CLUSTER_NAME}" Name=ServiceName,Value="${ECS_BACKEND_SERVICE}" \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --treat-missing-data notBreaching \
    --region "${AWS_REGION}"
echo "  ✓ High CPU alarm (>80% for 10min)"

# Memory utilization alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-high-memory" \
    --alarm-description "Backend ECS service memory exceeds 80%" \
    --metric-name MemoryUtilization \
    --namespace "AWS/ECS" \
    --dimensions Name=ClusterName,Value="${ECS_CLUSTER_NAME}" Name=ServiceName,Value="${ECS_BACKEND_SERVICE}" \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --treat-missing-data notBreaching \
    --region "${AWS_REGION}"
echo "  ✓ High memory alarm (>80% for 10min)"

# ─── Create CloudWatch Dashboard ───
echo "📈 Creating CloudWatch dashboard..."

DASHBOARD_BODY=$(cat << 'DASHBOARD'
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "ECS CPU & Memory Utilization",
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ClusterName", "CLUSTER", "ServiceName", "BACKEND_SERVICE", {"label": "Backend CPU"}],
          ["AWS/ECS", "MemoryUtilization", "ClusterName", "CLUSTER", "ServiceName", "BACKEND_SERVICE", {"label": "Backend Memory"}],
          ["AWS/ECS", "CPUUtilization", "ClusterName", "CLUSTER", "ServiceName", "FRONTEND_SERVICE", {"label": "Frontend CPU"}],
          ["AWS/ECS", "MemoryUtilization", "ClusterName", "CLUSTER", "ServiceName", "FRONTEND_SERVICE", {"label": "Frontend Memory"}]
        ],
        "period": 60,
        "region": "REGION",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "Application Metrics",
        "metrics": [
          ["PROJECT", "ErrorCount", {"label": "Errors", "color": "#d62728"}],
          ["PROJECT", "RequestCount", {"label": "Requests", "color": "#2ca02c"}],
          ["PROJECT", "ChatRequests", {"label": "Chat Requests", "color": "#1f77b4"}]
        ],
        "period": 60,
        "region": "REGION",
        "view": "timeSeries"
      }
    },
    {
      "type": "log",
      "x": 0, "y": 6, "width": 24, "height": 6,
      "properties": {
        "title": "Recent Backend Errors",
        "query": "SOURCE 'LOG_GROUP' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20",
        "region": "REGION",
        "view": "table"
      }
    }
  ]
}
DASHBOARD
)

# Substitute variables into dashboard JSON
DASHBOARD_BODY=$(echo "$DASHBOARD_BODY" | \
    sed "s/CLUSTER/${ECS_CLUSTER_NAME}/g" | \
    sed "s/BACKEND_SERVICE/${ECS_BACKEND_SERVICE}/g" | \
    sed "s/FRONTEND_SERVICE/${ECS_FRONTEND_SERVICE}/g" | \
    sed "s/REGION/${AWS_REGION}/g" | \
    sed "s/PROJECT/${PROJECT_NAME}/g" | \
    sed "s|LOG_GROUP|${LOG_GROUP_BACKEND}|g")

aws cloudwatch put-dashboard \
    --dashboard-name "${PROJECT_NAME}-dashboard" \
    --dashboard-body "${DASHBOARD_BODY}" \
    --region "${AWS_REGION}" > /dev/null

echo "  ✓ Dashboard: ${PROJECT_NAME}-dashboard"

echo ""
echo "✅ CloudWatch setup complete!"
echo "   Log groups: ${LOG_GROUP_BACKEND}, ${LOG_GROUP_FRONTEND}"
echo "   Alarms: error-rate, high-cpu, high-memory"
echo "   Dashboard: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${PROJECT_NAME}-dashboard"
echo ""
echo "📝 Next: Run 09-grafana-setup.sh"
