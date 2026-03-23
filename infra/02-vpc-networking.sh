#!/bin/bash
# ==============================================================================
# Step 2: VPC, Subnets, Internet Gateway, NAT, Route Tables, Security Groups
# ==============================================================================
set -e
source "$(dirname "$0")/env.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 2: Setting Up VPC & Networking"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Create VPC ───
echo "🌐 Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "${VPC_CIDR}" \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" \
    --query 'Vpc.VpcId' --output text \
    --region "${AWS_REGION}")
echo "  VPC: ${VPC_ID}"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute --vpc-id "${VPC_ID}" --enable-dns-hostnames '{"Value":true}' --region "${AWS_REGION}"

# ─── Create Internet Gateway ───
echo "🌍 Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-igw}]" \
    --query 'InternetGateway.InternetGatewayId' --output text \
    --region "${AWS_REGION}")
aws ec2 attach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}" --region "${AWS_REGION}"
echo "  IGW: ${IGW_ID}"

# ─── Get Availability Zones ───
AZ1=$(aws ec2 describe-availability-zones --region "${AWS_REGION}" --query 'AvailabilityZones[0].ZoneName' --output text)
AZ2=$(aws ec2 describe-availability-zones --region "${AWS_REGION}" --query 'AvailabilityZones[1].ZoneName' --output text)
echo "  AZs: ${AZ1}, ${AZ2}"

# ─── Create Public Subnets ───
echo "📡 Creating public subnets..."
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
    --vpc-id "${VPC_ID}" --cidr-block "${SUBNET_PUBLIC_1_CIDR}" --availability-zone "${AZ1}" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-1}]" \
    --query 'Subnet.SubnetId' --output text --region "${AWS_REGION}")

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
    --vpc-id "${VPC_ID}" --cidr-block "${SUBNET_PUBLIC_2_CIDR}" --availability-zone "${AZ2}" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-2}]" \
    --query 'Subnet.SubnetId' --output text --region "${AWS_REGION}")

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute --subnet-id "${PUBLIC_SUBNET_1}" --map-public-ip-on-launch --region "${AWS_REGION}"
aws ec2 modify-subnet-attribute --subnet-id "${PUBLIC_SUBNET_2}" --map-public-ip-on-launch --region "${AWS_REGION}"

echo "  Public Subnet 1: ${PUBLIC_SUBNET_1} (${AZ1})"
echo "  Public Subnet 2: ${PUBLIC_SUBNET_2} (${AZ2})"

# ─── Create Private Subnets ───
echo "🔒 Creating private subnets..."
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
    --vpc-id "${VPC_ID}" --cidr-block "${SUBNET_PRIVATE_1_CIDR}" --availability-zone "${AZ1}" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-1}]" \
    --query 'Subnet.SubnetId' --output text --region "${AWS_REGION}")

PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
    --vpc-id "${VPC_ID}" --cidr-block "${SUBNET_PRIVATE_2_CIDR}" --availability-zone "${AZ2}" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-2}]" \
    --query 'Subnet.SubnetId' --output text --region "${AWS_REGION}")

echo "  Private Subnet 1: ${PRIVATE_SUBNET_1} (${AZ1})"
echo "  Private Subnet 2: ${PRIVATE_SUBNET_2} (${AZ2})"

# ─── Create NAT Gateway (for private subnets to access internet) ───
echo "🔁 Creating NAT Gateway..."
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text --region "${AWS_REGION}")
NAT_GW=$(aws ec2 create-nat-gateway \
    --subnet-id "${PUBLIC_SUBNET_1}" \
    --allocation-id "${EIP_ALLOC}" \
    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-nat}]" \
    --query 'NatGateway.NatGatewayId' --output text --region "${AWS_REGION}")
echo "  NAT Gateway: ${NAT_GW} (waiting for availability...)"

aws ec2 wait nat-gateway-available --nat-gateway-ids "${NAT_GW}" --region "${AWS_REGION}"
echo "  NAT Gateway is available ✓"

# ─── Route Tables ───
echo "🗺️  Configuring route tables..."

# Public route table
PUBLIC_RT=$(aws ec2 create-route-table \
    --vpc-id "${VPC_ID}" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-rt}]" \
    --query 'RouteTable.RouteTableId' --output text --region "${AWS_REGION}")
aws ec2 create-route --route-table-id "${PUBLIC_RT}" --destination-cidr-block "0.0.0.0/0" --gateway-id "${IGW_ID}" --region "${AWS_REGION}" > /dev/null
aws ec2 associate-route-table --route-table-id "${PUBLIC_RT}" --subnet-id "${PUBLIC_SUBNET_1}" --region "${AWS_REGION}" > /dev/null
aws ec2 associate-route-table --route-table-id "${PUBLIC_RT}" --subnet-id "${PUBLIC_SUBNET_2}" --region "${AWS_REGION}" > /dev/null

# Private route table
PRIVATE_RT=$(aws ec2 create-route-table \
    --vpc-id "${VPC_ID}" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-rt}]" \
    --query 'RouteTable.RouteTableId' --output text --region "${AWS_REGION}")
aws ec2 create-route --route-table-id "${PRIVATE_RT}" --destination-cidr-block "0.0.0.0/0" --nat-gateway-id "${NAT_GW}" --region "${AWS_REGION}" > /dev/null
aws ec2 associate-route-table --route-table-id "${PRIVATE_RT}" --subnet-id "${PRIVATE_SUBNET_1}" --region "${AWS_REGION}" > /dev/null
aws ec2 associate-route-table --route-table-id "${PRIVATE_RT}" --subnet-id "${PRIVATE_SUBNET_2}" --region "${AWS_REGION}" > /dev/null

# ─── Security Groups ───
echo "🛡️  Creating security groups..."

# ALB Security Group
ALB_SG=$(aws ec2 create-security-group \
    --group-name "${PROJECT_NAME}-alb-sg" \
    --description "ALB Security Group" \
    --vpc-id "${VPC_ID}" \
    --query 'GroupId' --output text --region "${AWS_REGION}")
aws ec2 authorize-security-group-ingress --group-id "${ALB_SG}" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "${AWS_REGION}" > /dev/null
aws ec2 authorize-security-group-ingress --group-id "${ALB_SG}" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "${AWS_REGION}" > /dev/null
aws ec2 create-tags --resources "${ALB_SG}" --tags Key=Name,Value="${PROJECT_NAME}-alb-sg" --region "${AWS_REGION}"
echo "  ALB SG: ${ALB_SG}"

# ECS Tasks Security Group
ECS_SG=$(aws ec2 create-security-group \
    --group-name "${PROJECT_NAME}-ecs-sg" \
    --description "ECS Tasks Security Group" \
    --vpc-id "${VPC_ID}" \
    --query 'GroupId' --output text --region "${AWS_REGION}")
aws ec2 authorize-security-group-ingress --group-id "${ECS_SG}" --protocol tcp --port 8000 --source-group "${ALB_SG}" --region "${AWS_REGION}" > /dev/null
aws ec2 authorize-security-group-ingress --group-id "${ECS_SG}" --protocol tcp --port 3000 --source-group "${ALB_SG}" --region "${AWS_REGION}" > /dev/null
aws ec2 create-tags --resources "${ECS_SG}" --tags Key=Name,Value="${PROJECT_NAME}-ecs-sg" --region "${AWS_REGION}"
echo "  ECS SG: ${ECS_SG}"

# Redis Security Group
REDIS_SG=$(aws ec2 create-security-group \
    --group-name "${PROJECT_NAME}-redis-sg" \
    --description "Redis Security Group" \
    --vpc-id "${VPC_ID}" \
    --query 'GroupId' --output text --region "${AWS_REGION}")
aws ec2 authorize-security-group-ingress --group-id "${REDIS_SG}" --protocol tcp --port 6379 --source-group "${ECS_SG}" --region "${AWS_REGION}" > /dev/null
aws ec2 create-tags --resources "${REDIS_SG}" --tags Key=Name,Value="${PROJECT_NAME}-redis-sg" --region "${AWS_REGION}"
echo "  Redis SG: ${REDIS_SG}"

# ─── Save resource IDs ───
cat > "$(dirname "$0")/network-outputs.env" << EOF
# Auto-generated by 02-vpc-networking.sh — DO NOT EDIT
export VPC_ID="${VPC_ID}"
export IGW_ID="${IGW_ID}"
export PUBLIC_SUBNET_1="${PUBLIC_SUBNET_1}"
export PUBLIC_SUBNET_2="${PUBLIC_SUBNET_2}"
export PRIVATE_SUBNET_1="${PRIVATE_SUBNET_1}"
export PRIVATE_SUBNET_2="${PRIVATE_SUBNET_2}"
export NAT_GW="${NAT_GW}"
export EIP_ALLOC="${EIP_ALLOC}"
export PUBLIC_RT="${PUBLIC_RT}"
export PRIVATE_RT="${PRIVATE_RT}"
export ALB_SG="${ALB_SG}"
export ECS_SG="${ECS_SG}"
export REDIS_SG="${REDIS_SG}"
EOF

echo ""
echo "✅ VPC & Networking setup complete!"
echo "   Resource IDs saved to infra/network-outputs.env"
echo ""
echo "📝 Next: Run 03-alb-setup.sh"
