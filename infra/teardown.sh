#!/bin/bash
# ==============================================================================
# Teardown: Delete ALL AWS resources created by this project
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  TEARDOWN: Deleting ALL ${PROJECT_NAME} Resources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Are you sure you want to delete everything? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Load resource IDs
[ -f "$(dirname "$0")/network-outputs.env" ] && source "$(dirname "$0")/network-outputs.env"
[ -f "$(dirname "$0")/alb-outputs.env" ] && source "$(dirname "$0")/alb-outputs.env"
[ -f "$(dirname "$0")/ecs-cluster-outputs.env" ] && source "$(dirname "$0")/ecs-cluster-outputs.env"
[ -f "$(dirname "$0")/elasticache-outputs.env" ] && source "$(dirname "$0")/elasticache-outputs.env"

# ─── 1. Delete ECS Services ───
echo "🗑️  Deleting ECS services..."
aws ecs update-service --cluster "${ECS_CLUSTER_NAME}" --service "${ECS_BACKEND_SERVICE}" --desired-count 0 --region "${AWS_REGION}" 2>/dev/null || true
aws ecs update-service --cluster "${ECS_CLUSTER_NAME}" --service "${ECS_FRONTEND_SERVICE}" --desired-count 0 --region "${AWS_REGION}" 2>/dev/null || true
sleep 10
aws ecs delete-service --cluster "${ECS_CLUSTER_NAME}" --service "${ECS_BACKEND_SERVICE}" --force --region "${AWS_REGION}" 2>/dev/null || true
aws ecs delete-service --cluster "${ECS_CLUSTER_NAME}" --service "${ECS_FRONTEND_SERVICE}" --force --region "${AWS_REGION}" 2>/dev/null || true

# ─── 2. Delete ECS Cluster ───
echo "🗑️  Deleting ECS cluster..."
aws ecs delete-cluster --cluster "${ECS_CLUSTER_NAME}" --region "${AWS_REGION}" 2>/dev/null || true

# ─── 3. Delete ALB ───
echo "🗑️  Deleting ALB..."
if [ -n "${LISTENER_ARN}" ]; then
    aws elbv2 delete-listener --listener-arn "${LISTENER_ARN}" --region "${AWS_REGION}" 2>/dev/null || true
fi
if [ -n "${ALB_ARN}" ]; then
    aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" --region "${AWS_REGION}" 2>/dev/null || true
    echo "  Waiting for ALB deletion..."
    sleep 30
fi
if [ -n "${TG_BACKEND_ARN}" ]; then
    aws elbv2 delete-target-group --target-group-arn "${TG_BACKEND_ARN}" --region "${AWS_REGION}" 2>/dev/null || true
fi
if [ -n "${TG_FRONTEND_ARN}" ]; then
    aws elbv2 delete-target-group --target-group-arn "${TG_FRONTEND_ARN}" --region "${AWS_REGION}" 2>/dev/null || true
fi

# ─── 4. Delete ElastiCache ───
echo "🗑️  Deleting ElastiCache..."
aws elasticache delete-cache-cluster --cache-cluster-id "${ELASTICACHE_CLUSTER_NAME}" --region "${AWS_REGION}" 2>/dev/null || true
echo "  Waiting for cluster deletion..."
sleep 60
aws elasticache delete-cache-subnet-group --cache-subnet-group-name "${PROJECT_NAME}-redis-subnet" --region "${AWS_REGION}" 2>/dev/null || true

# ─── 5. Delete NAT Gateway ───
echo "🗑️  Deleting NAT Gateway..."
if [ -n "${NAT_GW}" ]; then
    aws ec2 delete-nat-gateway --nat-gateway-id "${NAT_GW}" --region "${AWS_REGION}" 2>/dev/null || true
    echo "  Waiting for NAT Gateway deletion..."
    sleep 60
fi
if [ -n "${EIP_ALLOC}" ]; then
    aws ec2 release-address --allocation-id "${EIP_ALLOC}" --region "${AWS_REGION}" 2>/dev/null || true
fi

# ─── 6. Delete Security Groups ───
echo "🗑️  Deleting security groups..."
for SG in "${REDIS_SG}" "${ECS_SG}" "${ALB_SG}"; do
    if [ -n "${SG}" ]; then
        aws ec2 delete-security-group --group-id "${SG}" --region "${AWS_REGION}" 2>/dev/null || true
    fi
done

# ─── 7. Delete Subnets and Route Tables ───
echo "🗑️  Deleting subnets and route tables..."
for SUBNET in "${PUBLIC_SUBNET_1}" "${PUBLIC_SUBNET_2}" "${PRIVATE_SUBNET_1}" "${PRIVATE_SUBNET_2}"; do
    if [ -n "${SUBNET}" ]; then
        aws ec2 delete-subnet --subnet-id "${SUBNET}" --region "${AWS_REGION}" 2>/dev/null || true
    fi
done

for RT in "${PUBLIC_RT}" "${PRIVATE_RT}"; do
    if [ -n "${RT}" ]; then
        aws ec2 delete-route-table --route-table-id "${RT}" --region "${AWS_REGION}" 2>/dev/null || true
    fi
done

# ─── 8. Delete Internet Gateway ───
echo "🗑️  Deleting Internet Gateway..."
if [ -n "${IGW_ID}" ] && [ -n "${VPC_ID}" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}" --region "${AWS_REGION}" 2>/dev/null || true
    aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}" --region "${AWS_REGION}" 2>/dev/null || true
fi

# ─── 9. Delete VPC ───
echo "🗑️  Deleting VPC..."
if [ -n "${VPC_ID}" ]; then
    aws ec2 delete-vpc --vpc-id "${VPC_ID}" --region "${AWS_REGION}" 2>/dev/null || true
fi

# ─── 10. Delete ECR Repos ───
echo "🗑️  Deleting ECR repositories..."
aws ecr delete-repository --repository-name "${ECR_BACKEND_REPO}" --force --region "${AWS_REGION}" 2>/dev/null || true
aws ecr delete-repository --repository-name "${ECR_FRONTEND_REPO}" --force --region "${AWS_REGION}" 2>/dev/null || true

# ─── 11. Delete CloudWatch ───
echo "🗑️  Deleting CloudWatch resources..."
aws logs delete-log-group --log-group-name "${LOG_GROUP_BACKEND}" --region "${AWS_REGION}" 2>/dev/null || true
aws logs delete-log-group --log-group-name "${LOG_GROUP_FRONTEND}" --region "${AWS_REGION}" 2>/dev/null || true
aws cloudwatch delete-alarms --alarm-names "${PROJECT_NAME}-high-error-rate" "${PROJECT_NAME}-high-cpu" "${PROJECT_NAME}-high-memory" --region "${AWS_REGION}" 2>/dev/null || true
aws cloudwatch delete-dashboards --dashboard-names "${PROJECT_NAME}-dashboard" --region "${AWS_REGION}" 2>/dev/null || true

# ─── 12. Delete IAM Roles ───
echo "🗑️  Deleting IAM roles..."
aws iam detach-role-policy --role-name "${ECS_EXECUTION_ROLE}" --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" 2>/dev/null || true
aws iam delete-role --role-name "${ECS_EXECUTION_ROLE}" 2>/dev/null || true
aws iam delete-role-policy --role-name "${ECS_TASK_ROLE}" --policy-name "${PROJECT_NAME}-cloudwatch-policy" 2>/dev/null || true
aws iam delete-role --role-name "${ECS_TASK_ROLE}" 2>/dev/null || true

# Clean up output files
rm -f "$(dirname "$0")/network-outputs.env"
rm -f "$(dirname "$0")/alb-outputs.env"
rm -f "$(dirname "$0")/ecs-cluster-outputs.env"
rm -f "$(dirname "$0")/elasticache-outputs.env"

echo ""
echo "✅ Teardown complete! All ${PROJECT_NAME} AWS resources deleted."
