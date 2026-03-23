#!/bin/bash
# ==============================================================================
# Step 6: ECS Fargate Task Definitions
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/ecs-cluster-outputs.env"
source "$(dirname "$0")/elasticache-outputs.env"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 6: Registering Fargate Task Definitions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Backend Task Definition ───
echo "📋 Registering backend task definition..."

cat > /tmp/backend-task-def.json << EOF
{
  "family": "${ECS_BACKEND_TASK}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${BACKEND_CPU}",
  "memory": "${BACKEND_MEMORY}",
  "executionRoleArn": "${EXECUTION_ROLE_ARN}",
  "taskRoleArn": "${TASK_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "${ECR_BACKEND_URI}:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "GEMINI_API_KEY", "value": "${GEMINI_API_KEY}"},
        {"name": "GEMINI_MODEL", "value": "${GEMINI_MODEL}"},
        {"name": "MONGODB_URI", "value": "${MONGODB_URI}"},
        {"name": "MONGODB_DB_NAME", "value": "gemini_chat"},
        {"name": "REDIS_URL", "value": "${REDIS_URL}"},
        {"name": "ALLOWED_ORIGINS", "value": "*"},
        {"name": "LOG_LEVEL", "value": "INFO"},
        {"name": "APP_NAME", "value": "gemini-chat-api"},
        {"name": "DEBUG", "value": "false"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${LOG_GROUP_BACKEND}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/api/health')\" || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 10
      }
    }
  ]
}
EOF

aws ecs register-task-definition \
    --cli-input-json file:///tmp/backend-task-def.json \
    --region "${AWS_REGION}" > /dev/null

echo "  ✓ Backend task: ${ECS_BACKEND_TASK}"

# ─── Frontend Task Definition ───
echo "📋 Registering frontend task definition..."

cat > /tmp/frontend-task-def.json << EOF
{
  "family": "${ECS_FRONTEND_TASK}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${FRONTEND_CPU}",
  "memory": "${FRONTEND_MEMORY}",
  "executionRoleArn": "${EXECUTION_ROLE_ARN}",
  "taskRoleArn": "${TASK_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "frontend",
      "image": "${ECR_FRONTEND_URI}:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "NEXT_PUBLIC_API_URL", "value": "PLACEHOLDER_ALB_DNS"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${LOG_GROUP_FRONTEND}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000 || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 15
      }
    }
  ]
}
EOF

aws ecs register-task-definition \
    --cli-input-json file:///tmp/frontend-task-def.json \
    --region "${AWS_REGION}" > /dev/null

echo "  ✓ Frontend task: ${ECS_FRONTEND_TASK}"

# Clean up temp files
rm -f /tmp/backend-task-def.json /tmp/frontend-task-def.json

echo ""
echo "✅ Task definitions registered!"
echo "   Backend: ${BACKEND_CPU} CPU / ${BACKEND_MEMORY} Memory"
echo "   Frontend: ${FRONTEND_CPU} CPU / ${FRONTEND_MEMORY} Memory"
echo ""
echo "⚠️  Note: Push Docker images to ECR before running 07-ecs-services.sh"
echo "   docker build -t ${ECR_BACKEND_URI}:latest ./backend"
echo "   docker push ${ECR_BACKEND_URI}:latest"
echo ""
echo "📝 Next: Run 07-ecs-services.sh"
