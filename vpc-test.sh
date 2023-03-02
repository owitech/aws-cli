#!/bin/bash

# Variables
REGION="us-east-1"
VPC_NAME="vpc-test"
VPC_CIDR="10.0.0.0/25"

SUBNET_AZ="us-east-1a"
MY_IP="$(curl -s checkip.amazonaws.com 2>&1)/32"

SUBNET_PUBLIC_CIDR="10.0.0.0/26"
SUBNET_PUBLIC_NAME="subnet-test-public"

SUBNET_PRIVATE_CIDR="10.0.0.64/26"
SUBNET_PRIVATE_NAME="subnet-test-private"

GROUP_NAME="WebPublicBasicGroup"
GROUP_DESC="SG for Subnet Public"



# Create Vpc
echo "Creando la VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $REGION \
    --query "Vpc.VpcId" \
    --output text)

# Agregar etiquetas a la VPC
echo "Agregando etiquetas a la VPC..."
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME

# Activar la resolución de DNS para la VPC
echo "Activando la resolución de DNS para la VPC..."
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"



# Create Subnet Public
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
    --availability-zone $SUBNET_AZ \
    --cidr-block $SUBNET_PUBLIC_CIDR \
    --vpc-id $VPC_ID \
    --query "Subnet.SubnetId" \
    --output text)

# Agregar etiquetas a la subred pública
echo "Agregando etiquetas a la subred pública..."
aws ec2 create-tags --resources $SUBNET_PUBLIC_ID --tags Key=Name,Value=$SUBNET_PUBLIC_NAME



# Create Subnet Private
SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
    --availability-zone $SUBNET_AZ \
    --cidr-block $SUBNET_PRIVATE_CIDR \
    --vpc-id $VPC_ID \
    --query "Subnet.SubnetId" \
    --output text)

# Agregar etiquetas a la subred privada
echo "Agregando etiquetas a la subred privada..."
aws ec2 create-tags --resources $SUBNET_PRIVATE_ID --tags Key=Name,Value=$SUBNET_PRIVATE_NAME



# Create Interne Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --query "InternetGateway.InternetGatewayId" \
    --output text)

# Attach Internet Gateway with Vpc
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

# Create Route-Table and associate with Vpc
# --filters Name=vpc-id,Values=$VPC_ID \ ???
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query "RouteTable.RouteTableId" \
    --output text)
# Por defector crea un route 10.0.0.0/25 -> local

# Create and associate a Route with Route-Table and Internet Gateway
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id $IGW_ID

# Associate Route-Table-Rule with Subnet-Public
RTB_ASSOC_PUBLIC_ID=$(aws ec2 associate-route-table \
    --route-table-id $ROUTE_TABLE_ID \
    --subnet-id $SUBNET_PUBLIC_ID \
    --query "AssociationId" \
    --output text)



# Create Security Group
echo "Creando un grupo de seguridad para la instancia..."
GROUP_PUBLIC_ID=$(aws ec2 create-security-group \
    --group-name $GROUP_NAME \
    --description $GROUP_DESC \
    --vpc-id $VPC_ID \
    --query "GroupId" \
    --output text)

#Agregar reglas de entrada y salida para el grupo de seguridad
echo "Agregando reglas de entrada y salida para el grupo de seguridad..."
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
echo "RT ID:                    $ROUTE_TABLE_ID"        >> ids.txt
echo "RT ASSOCIATE PUBLIC ID:   $RTB_ASSOC_PUBLIC_ID"   >> ids.txt
echo "SG PUBLIC ID:             $GROUP_PUBLIC_ID"       >> ids.txt
echo "SGR PUBLIC SSH:           $SGR_PUBLIC_SSH"        >> ids.txt
echo "SGR PUBLIC HTTP:          $SGR_PUBLIC_HTTP"       >> ids.txt