#!/bin/bash

# REGION -> us-east-1 
# AZs:
#   us-east-1a 
#       (subnet public1[1a] & private1[1a] or private1[2a])
#   us-east-1b 
#       (subnet public2[1b] & private2[1b])
#   us-east-1c 
#       (subnet public3[1c] & private2[1c])
#   us-east-1d
#   us-east-1e
#   us-east-1f

# Variables
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"

## Subnet AZ-1a
SUBNET_AZ="us-east-1a"
SUBNET_PUBLIC_CIDR="10.0.0.0/24"
SUBNET_PRIVATE_CIDR="10.0.1.0/24"

## Security group
SG_PUBLIC_NAME="SGWebPublic"
SG_PRIVATE_NAME="sg-sql-private"
SG_PRIVATE_NAME="SGSqlPrivate"
MY_IP="$(curl -s checkip.amazonaws.com 2>&1)/32"

## Key-pair
KEY_NAME="basic-key-web"

# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value=basic-vpc}]' \
    --query 'Vpc.VpcId' \
    --output text \
    --region $REGION)

# 2. Create SUBNET
## AZ-1a
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_PUBLIC_CIDR \
    --availability-zone $SUBNET_AZ \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=basic-subnet-public1-us-east-1a}]' \
    --output text \
    --query 'Subnet.SubnetId')

SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_PRIVATE_CIDR \
    --availability-zone $SUBNET_AZ \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=basic-subnet-private1-us-east-1a}]' \
    --output text \
    --query 'Subnet.SubnetId')

# 3. Create InternetGateway
GATEWAY_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=basic-igw}]' \
    --output text \
    --query 'InternetGateway.InternetGatewayId')

## 3.1. Asociate IG to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $GATEWAY_ID \
    --vpc-id $VPC_ID

# 4. Route table
## 4.1 Create route-table PUBLIC
RTB_PUBLIC_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=basic-rtb-public}]' \
    --output text \
    --query 'RouteTable.RouteTableId')

### 4.1.1. Associate route-table public to subnet-public
aws ec2 associate-route-table --route-table-id $RTB_PUBLIC_ID --subnet-id $SUBNET_PUBLIC_ID

### 4.1.2. Create route and associate to IGW
aws ec2 create-route \
    --route-table-id $RTB_PUBLIC_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $GATEWAY_ID

## 4.2 Create route-table RRIVATE
RTB_PRIVATE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=basic-rtb-private1-us-east-1a}]' \
    --output text \
    --query 'RouteTable.RouteTableId')

### 4.2.1. Associate route-table private to subnet-private
aws ec2 associate-route-table --route-table-id $RTB_PRIVATE_ID --subnet-id $SUBNET_PRIVATE_ID

# 5. Security Group
## 5.1. Create SG PUBLIC
SG_PUBLIC_ID=$(aws ec2 create-security-group \
    --group-name $SG_PUBLIC_NAME \
    --description "SG public for ssh and http" \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=basic-sg-public}]' \
    --output text \
    --query 'GroupId')

### 5.1.1. Access to port ssh from MyIp
aws ec2 authorize-security-group-ingress \
    --group-id $SG_PUBLIC_ID \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP

### 5.1.2. Access to port http from any
aws ec2 authorize-security-group-ingress \
    --group-id $SG_PUBLIC_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

## 5.2. Create SG PRIVATE
SG_PRIVATE_ID=$(aws ec2 create-security-group \
    --group-name $SG_PRIVATE_NAME \
    --description "SG private for SQL" \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=basic-sg-private}]' \
    --output text \
    --query 'GroupId')

### 5.2.1. Access to port sql from VPC
aws ec2 authorize-security-group-ingress \
    --group-id $SG_PRIVATE_ID \
    --protocol tcp \
    --port 3306 \
    --cidr $VPC_CIDR

# 6. Create key-pairs to ec2
KEY_PAIR_WEB=$(aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-type ed25519 \
    --key-format pem \
    --query "KeyMaterial" \
    --output text)


mkdir -p basic-doc && cd ./basic-doc
echo "REGION: $REGION" > deno.txt
echo "VPC ID: $VPC_ID" >> deno.txt
echo "SUBNET PUBLIC $SUBNET_PUBLIC_ID" >> deno.txt
echo "SUBNET PRIVATE: $SUBNET_PRIVATE_ID" >> deno.txt
echo "IGW ID: $GATEWAY_ID" >> deno.txt
echo "ROUTE TABLE PUBLIC: $RTB_PUBLIC_ID" >> deno.txt
echo "ROUTE TABLE PRIVATE: $RTB_PRIVATE_ID" >> deno.txt
echo "SECURITY GROUP PUBLIC: $SG_PUBLIC_ID" >> deno.txt
echo "SECURITY GROUP PRIVATE: $SG_PRIVATE_ID" >> deno.txt
echo "$KEY_PAIR_WEB" > basic-key-web.pem

