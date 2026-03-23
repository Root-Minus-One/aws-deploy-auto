#!/bin/bash
# ==============================================================================
# Step 1: Create ECR Repositories
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1: Creating ECR Repositories"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create backend ECR repo
echo "📦 Creating backend ECR repository: ${ECR_BACKEND_REPO}"
aws ecr create-repository \
    --repository-name "${ECR_BACKEND_REPO}" \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE \
    --region "${AWS_REGION}" \
    2>/dev/null || echo "  ℹ️  Repository already exists"

# Create frontend ECR repo
echo "📦 Creating frontend ECR repository: ${ECR_FRONTEND_REPO}"
aws ecr create-repository \
    --repository-name "${ECR_FRONTEND_REPO}" \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE \
    --region "${AWS_REGION}" \
    2>/dev/null || echo "  ℹ️  Repository already exists"

# Set lifecycle policy (keep last 10 images)
LIFECYCLE_POLICY='{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}'

echo "📋 Setting lifecycle policies..."
aws ecr put-lifecycle-policy \
    --repository-name "${ECR_BACKEND_REPO}" \
    --lifecycle-policy-text "${LIFECYCLE_POLICY}" \
    --region "${AWS_REGION}" > /dev/null

aws ecr put-lifecycle-policy \
    --repository-name "${ECR_FRONTEND_REPO}" \
    --lifecycle-policy-text "${LIFECYCLE_POLICY}" \
    --region "${AWS_REGION}" > /dev/null

echo ""
echo "✅ ECR Repositories created:"
echo "   Backend: ${ECR_BACKEND_URI}"
echo "   Frontend: ${ECR_FRONTEND_URI}"
echo ""
echo "📝 Next: Run 02-vpc-networking.sh"
