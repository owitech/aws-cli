#!/bin/bash

# Variables de configuración
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
SECURITY_GROUP_NAME="my-security-group"
KEY_NAME="my-key-pair"
AMI_ID="ami-0c94855ba95c71c99"
INSTANCE_TYPE="t2.micro"

# Usar AWS CLI para obtener la lista de instancias de EC2
#INSTANCES=$(aws ec2 describe-instances --region $REGION --query "Reservations[].Instances[].InstanceId" --output text)

# Imprimir la lista de instancias
#echo "Instancias de EC2 en la región $REGION:"
#echo $INSTANCES

# 1. Crear VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.{VpcId:VpcId}' --output text --region $REGION)

# 2. Crear subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --query 'Subnet.{SubnetId:SubnetId}' --output text --region $REGION)

# 3. Crear Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' --output text --region $REGION)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION

# 4. Crear ruta a Internet
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.{RouteTableId:RouteTableId}' --output text --region $REGION)
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID --region $REGION

# 5. Crear Security Group
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "My security group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION

# 6. Crear Elastic IP
EIP_ID=$(aws ec2 allocate-address --query '{AllocationId:AllocationId}' --output text --region $REGION)

# 7. Crear instancia EC2
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --associate-public-ip-address --query 'Instances[0].InstanceId' --output text --region $REGION)

# Crear rol IAM
ROLE_NAME="my-ec2-role"
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://assume-role-policy.json --region $REGION
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ROLE_NAME --region $REGION
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID --iam-instance-profile Name=$ROLE_NAME --region $REGION

# Imprimir información de la instancia
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].[PublicIpAddress,InstanceId,Tags[?Key==`Name`].Value]' --output text --region $REGION
