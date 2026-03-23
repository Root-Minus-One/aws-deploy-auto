#!/bin/bash
# ==============================================================================
# Environment variables shared across all infrastructure scripts.
# Copy this to env.sh and fill in your values before running any scripts.
# ==============================================================================

# AWS Configuration
export AWS_REGION="ap-south-2"              # Change to your preferred region
export AWS_ACCOUNT_ID=""                     # Your AWS Account ID (auto-detected if blank)
export AWS_PROFILE="default"

# Project naming
export PROJECT_NAME="gemini-chat"
export ENVIRONMENT="production"

# ECR Repositories
export ECR_BACKEND_REPO="${PROJECT_NAME}-backend"
export ECR_FRONTEND_REPO="${PROJECT_NAME}-frontend"
export ECR_GRAFANA_REPO="${PROJECT_NAME}-grafana"

# ECS Configuration
export ECS_CLUSTER_NAME="${PROJECT_NAME}-cluster"
export ECS_BACKEND_SERVICE="${PROJECT_NAME}-backend-service"
export ECS_FRONTEND_SERVICE="${PROJECT_NAME}-frontend-service"
export ECS_GRAFANA_SERVICE="${PROJECT_NAME}-grafana-service"
export ECS_BACKEND_TASK="${PROJECT_NAME}-backend-task"
export ECS_FRONTEND_TASK="${PROJECT_NAME}-frontend-task"
export ECS_GRAFANA_TASK="${PROJECT_NAME}-grafana-task"
export ECS_EXECUTION_ROLE="${PROJECT_NAME}-ecs-execution-role"
export ECS_TASK_ROLE="${PROJECT_NAME}-ecs-task-role"

# Networking
export VPC_NAME="${PROJECT_NAME}-vpc"
export VPC_CIDR="10.0.0.0/16"
export SUBNET_PUBLIC_1_CIDR="10.0.1.0/24"
export SUBNET_PUBLIC_2_CIDR="10.0.2.0/24"
export SUBNET_PRIVATE_1_CIDR="10.0.3.0/24"
export SUBNET_PRIVATE_2_CIDR="10.0.4.0/24"

# Application Load Balancer
export ALB_NAME="${PROJECT_NAME}-alb"
export TG_BACKEND_NAME="${PROJECT_NAME}-backend-tg"
export TG_FRONTEND_NAME="${PROJECT_NAME}-frontend-tg"
export TG_GRAFANA_NAME="${PROJECT_NAME}-grafana-tg"

# ElastiCache
export ELASTICACHE_CLUSTER_NAME="${PROJECT_NAME}-redis"
export ELASTICACHE_NODE_TYPE="cache.t3.micro"

# CloudWatch
export LOG_GROUP_BACKEND="/ecs/${PROJECT_NAME}/backend"
export LOG_GROUP_FRONTEND="/ecs/${PROJECT_NAME}/frontend"
export LOG_GROUP_GRAFANA="/ecs/${PROJECT_NAME}/grafana"

# Application Environment
export GEMINI_API_KEY=""                     # Your Google Gemini API Key
export MONGODB_URI=""                        # Your MongoDB Atlas URI
export GEMINI_MODEL="gemini-2.0-flash"

# Fargate task sizes
export BACKEND_CPU="512"
export BACKEND_MEMORY="1024"
export FRONTEND_CPU="256"
export FRONTEND_MEMORY="512"
export GRAFANA_CPU="256"
export GRAFANA_MEMORY="512"

# Auto-detect AWS Account ID
if [ -z "$AWS_ACCOUNT_ID" ]; then
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        echo "❌ Could not detect AWS Account ID. Set it manually in env.sh"
        exit 1
    fi
fi

export ECR_BACKEND_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_BACKEND_REPO}"
export ECR_FRONTEND_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_FRONTEND_REPO}"
export ECR_GRAFANA_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_GRAFANA_REPO}"

echo "✅ Environment loaded for: ${PROJECT_NAME} (${ENVIRONMENT})"
echo "   AWS Account: ${AWS_ACCOUNT_ID}"
echo "   Region: ${AWS_REGION}"
