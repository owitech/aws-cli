#!/bin/bash

# Varaibles
# CIDR=Classless Inter-Domain Routing - interpretar IP
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"

# subnet public - us-east-1a
SUBNET_AZ_1a="us-east-1a"
SUBNET_PUBLIC_CIDR_1a="10.0.0.0/24"
SUBNET_PRIVATE_CIDR_1a="10.0.1.0/24"

# subnet public - us-east-1b
# SUBNET_PUBLIC_CIDR_1b="10.0.16.0/24"
# SUBNET_PRIVATE_CIDR_1b="10.0.17.0/24"
# SUBNET_AZ_1b="us-east-1b"

SECURITY_GROUP_NAME="basic-sg"
MY_IP="$(curl -s checkip.amazonaws.com 2>&1)"


AMI_ID="ami-09cd747c78a9add63" # 20.04 LTS
INSTANCE_TYPE="t2.micro"
KEY_NAME="basic-web"


# 1. Create VPC
VPC_ID=$(
    aws ec2 create-vpc \
        --cidr-block $VPC_CIDR \
        --tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value=basic-vpc}]' \
        --query 'Vpc.{VpcId:VpcId}' \
        --output text \
        --region $REGION)

# 2. Create SUBNET
## AZ-1
SUBNET_PUBLIC_ID_AZa=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_PUBLIC_CIDR_1a \
    --availability-zone $SUBNET_AZ_1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=basic-subnet-public1-us-east-1a}]' \
    --output text \
    --query 'Subnet.SubnetId')

SUBNET_PRIVATE_ID_AZa=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_PRIVATE_CIDR_1a \
    --availability-zone $SUBNET_AZ_1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=basic-subnet-private1-us-east-1a}]' \
    --output text \
    --query 'Subnet.SubnetId')

## AZ-2
# SUBNET_PUBLIC_ID_AZb=$(aws ec2 create-subnet \
#     --vpc-id $VPC_ID \
#     --cidr-block $SUBNET_PUBLIC_CIDR_1b \
#     --availability-zone $SUBNET_AZ_1b \
#     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=basic-subnet-public2-us-east-1b}]' \
#     --output text \
#     --query 'Subnet.SubnetId')

# SUBNET_PRIVATE_ID_AZb=$(aws ec2 create-subnet \
#     --vpc-id $VPC_ID \
#     --cidr-block $SUBNET_PRIVATE_CIDR_1b \
#     --availability-zone $SUBNET_AZ_1b \
#     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=basic-subnet-private2-us-east-1b}]' \
#     --output text \
#     --query 'Subnet.SubnetId')

# 3. Create InternetGateway
GATEWAY_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=basic-igw}]' \
    --output text \
    --query 'InternetGateway.InternetGatewayId')

# 4. Asociat IG a VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $GATEWAY_ID \
    --vpc-id $VPC_ID

# 5. Create route-table to internet
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=basic-rt}]' \
    --output text \
    --query 'RouteTable.RouteTableId')

# 6. Crear ruta y asociar a route-table e InternetGateway
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $GATEWAY_ID

# 7. Asocia las subredes a route-tables
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_PUBLIC_ID_AZa
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_PRIVATE_ID_AZa

# 8. Crea un grupo de seguridad para permitir el acceso a S3 y RDS
SECURITY_GROUP_ID$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for S3 and RDS access" \
    --vpc-id $VPC_ID \
    # --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=basic-sg-public}]' \ # ver si esta por defecto
    --output text \
    --query 'GroupId')

# Permite acceso a la instancia EC2 pública desde MyIP
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP

# Permite acceso a la instancia EC2 pública desde cualquier IP
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Permite acceso a RDS desde cualquier IP dentro de la VPC
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3306 \
    --cidr 10.0.0.0/16

# 9. Create key-pairs to ec2
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-type ed25519 \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > basic-key-web.pem

# 10. Crear instancia EC2 public
INSTANCE_PUBLIC_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_PUBLIC_ID_AZa \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-basic}]' \
    --user-data file://ubuntu-nginx.txt
    --output text \
    --query 'Instances[0].InstanceId')

# 11. Esperar a que la instancia este en modo "running"
aws ec2 wait instance-running \
    --instance-ids $INSTANCE_PUBLIC_ID

# 12. Asignar IP elastic

# 13. Muestra la información de la infraestructura creada
echo "VPC ID: $VPC_ID"
echo "Subnet pública ID: $SUBNET_PUBLIC_ID_AZa"
echo "Subnet privada ID: $SUBNET_PRIVATE_ID_AZa"
echo "Instancia pública ID: $INSTANCE_PUBLIC_ID"
# echo "Instancia privada ID: $instance_private_id"
# echo "Dirección IP elástica de la instancia pública: $public_ip"
# echo "Instancia de base de datos de RDS ID: $rds_id"
# echo "Bucket de S3: $bucket_name"


