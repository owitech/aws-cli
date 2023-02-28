#!/bin/bash

REGION="us-east-1"
VPC_CIDR="10.0.0.0/25"

SUBNET_AZ="us-east-1a"
SUBNET_PUBLIC="10.0.0.0/26"
SUBNET_PRIVATE="10.0.0.64/26"

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $REGION \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpc-basic-01}]' \
    --query "Vpc.VpcId" \
    --output text)

# vpc-03948757b33fbf1ad

SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
    --availability-zone $SUBNET_AZ \
    --cidr-block $SUBNET_PUBLIC \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet-basic-public-01}]' \
    --query "Subnet.SubnetId"
    --output text)

# subnet-047bef8bfbfe1664f

SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
    --availability-zone $SUBNET_AZ \
    --cidr-block $SUBNET_PRIVATE \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet-basic-private-01}]' \
    --query "Subnet.SubnetId"
    --output text)

# subnet-04ac6c06921b6e620

IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=basic-igw}]' \
    --query "InternetGateway.InternetGatewayId" \
    --output text)

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

# igw-04088e1e627e6df78

RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rt-basic}]' \
    --query "RouteTable.RouteTableId" \
    --output text)

# rtb-0481c9c41592716f5




