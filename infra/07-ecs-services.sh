#!/bin/bash
# ==============================================================================
# Step 7: ECS Services (Fargate) with ALB Integration
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/network-outputs.env"
source "$(dirname "$0")/alb-outputs.env"
source "$(dirname "$0")/ecs-cluster-outputs.env"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 7: Creating ECS Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Backend Service ───
echo "🚀 Creating backend service..."
aws ecs create-service \
    --cluster "${ECS_CLUSTER_NAME}" \
    --service-name "${ECS_BACKEND_SERVICE}" \
    --task-definition "${ECS_BACKEND_TASK}" \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET_1},${PRIVATE_SUBNET_2}],securityGroups=[${ECS_SG}],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=${TG_BACKEND_ARN},containerName=backend,containerPort=8000" \
    --deployment-configuration "minimumHealthyPercent=50,maximumPercent=200" \
    --deployment-controller type=ECS \
    --enable-execute-command \
    --tags key=Project,value="${PROJECT_NAME}" \
    --region "${AWS_REGION}" > /dev/null

echo "  ✓ Backend service: ${ECS_BACKEND_SERVICE} (2 tasks)"

# ─── Frontend Service ───
echo "🚀 Creating frontend service..."
aws ecs create-service \
    --cluster "${ECS_CLUSTER_NAME}" \
    --service-name "${ECS_FRONTEND_SERVICE}" \
    --task-definition "${ECS_FRONTEND_TASK}" \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET_1},${PRIVATE_SUBNET_2}],securityGroups=[${ECS_SG}],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=${TG_FRONTEND_ARN},containerName=frontend,containerPort=3000" \
    --deployment-configuration "minimumHealthyPercent=50,maximumPercent=200" \
    --deployment-controller type=ECS \
    --enable-execute-command \
    --tags key=Project,value="${PROJECT_NAME}" \
    --region "${AWS_REGION}" > /dev/null

echo "  ✓ Frontend service: ${ECS_FRONTEND_SERVICE} (2 tasks)"

# ─── Wait for services to stabilize ───
echo ""
echo "⏳ Waiting for services to stabilize..."
echo "   (This can take 2-5 minutes)"

aws ecs wait services-stable \
    --cluster "${ECS_CLUSTER_NAME}" \
    --services "${ECS_BACKEND_SERVICE}" "${ECS_FRONTEND_SERVICE}" \
    --region "${AWS_REGION}" 2>/dev/null || echo "  ⚠️  Services may still be starting. Check AWS Console."

echo ""
echo "✅ ECS Services created!"
echo "   Backend:  ${ECS_BACKEND_SERVICE} (2 Fargate tasks)"
echo "   Frontend: ${ECS_FRONTEND_SERVICE} (2 Fargate tasks)"
echo ""
echo "🌐 Access your app at: http://${ALB_DNS}"
echo ""
echo "📝 Next: Run 08-cloudwatch-setup.sh"
