#!/bin/bash

REGION="us-east-1"
VPC_CIDR="10.0.0.0/25"
MY_IP="$(curl -s checkip.amazonaws.com 2>&1)/32"

SUBNET_AZ="us-east-1a"
SUBNET_PUBLIC="10.0.0.0/26"
SUBNET_PRIVATE="10.0.0.64/26"

SG_NAME="WebPublicBasicGroup"

# Create Vpc
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $REGION \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpc-basic-01}]' \
    --query "Vpc.VpcId" \
    --output text)

# Create Subnet Public
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
    --availability-zone $SUBNET_AZ \
    --cidr-block $SUBNET_PUBLIC \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet-basic-public-01}]' \
    --query "Subnet.SubnetId" \
    --output text)

# Create Subnet Private
SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
    --availability-zone $SUBNET_AZ \
    --cidr-block $SUBNET_PRIVATE \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet-basic-private-01}]' \
    --query "Subnet.SubnetId" \
    --output text)

# Create Interne Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw-basic-01}]' \
    --query "InternetGateway.InternetGatewayId" \
    --output text)

# Attach Internet Gateway with Vpc
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

# Create Route-Table and associate with Vpc
RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rt-basic-01}]' \
    --query "RouteTable.RouteTableId" \
    --output text)
# Por defector crea un route 10.0.0.0/25 -> local

# Create and associate a Route with Route-Table and Internet Gateway
aws ec2 create-route \
    --route-table-id $RTB_ID \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id $IGW_ID

# Associate Route-Table-Rule with Subnet-Public
RTB_ASSOC_PUBLIC_ID=$(aws ec2 associate-route-table \
    --route-table-id $RTB_ID \
    --subnet-id $SUBNET_PUBLIC_ID \
    --query "AssociationId" \
    --output text)

# Create Security Group
GROUP_PUBLIC_ID=$(aws ec2 create-security-group \
    --group-name $SG_NAME \
    --description "SG for Subnet Public" \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=sg-basic-public-01}]' \
    --query "GroupId" \
    --output text)

# Create an Security-Group-Rule SSH
SGR_PUBLIC_SSH=$(aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_PUBLIC_ID \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP \
    --tag-specifications 'ResourceType=security-group-rule,Tags=[{Key=Name,Value=sgr-ssh-01}]' \
    --query "SecurityGroupRules[].SecurityGroupRuleId" \
    --output text)

# Create an Security-Group-Rule HTTP
SGR_PUBLIC_HTTP=$(aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_PUBLIC_ID \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0" \
    --tag-specifications 'ResourceType=security-group-rule,Tags=[{Key=Name,Value=sgr-http-01}]' \
    --query "SecurityGroupRules[].SecurityGroupRuleId" \
    --output text)


mkdir -p doc && cd ./doc
echo "REGION:                   $REGION"                > ids.txt
echo "VPC ID:                   $VPC_ID"                >> ids.txt
echo "SUBNET PUBLIC ID:         $SUBNET_PUBLIC_ID"      >> ids.txt
echo "SUBNET PRIVAT ID:         $SUBNET_PRIVATE_ID"     >> ids.txt
echo "INTERNET GATEWAY ID:      $IGW_ID"                >> ids.txt
echo "RT ID:                    $RTB_ID"                >> ids.txt
echo "RT ASSOCIATE PUBLIC ID:   $RTB_ASSOC_PUBLIC_ID"   >> ids.txt
echo "SG PUBLIC ID:             $GROUP_PUBLIC_ID"       >> ids.txt
echo "SGR PUBLIC SSH:           $SGR_PUBLIC_SSH"        >> ids.txt
echo "SGR PUBLIC HTTP:          $SGR_PUBLIC_HTTP"       >> ids.txt