#!/bin/bash

# Crea la VPC
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId')

# Crea las subredes
subnet_public_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --output text --query 'Subnet.SubnetId')
subnet_private_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --output text --query 'Subnet.SubnetId')

# Crea una puerta de enlace a internet para la VPC
gateway_id=$(aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id $gateway_id --vpc-id $vpc_id

# Crea una tabla de rutas para la VPC
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --output text --query 'RouteTable.RouteTableId')
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $gateway_id

# Asocia las subredes a la tabla de rutas
aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $subnet_public_id
aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $subnet_private_id

# Crea un grupo de seguridad para permitir el acceso a S3 y RDS
security_group_id=$(aws ec2 create-security-group --group-name my-security-group --description "Security group for S3 and RDS access" --vpc-id $vpc_id --output text --query 'GroupId')
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 3306 --cidr 10.0.0.0/16 # Permite acceso a RDS desde cualquier IP dentro de la VPC
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 # Permite acceso a la instancia EC2 pública desde cualquier IP

# Crea dos instancias EC2, una en cada subred
instance_public_id=$(aws ec2 run-instances --image-id ami-0c94855ba95c71c99 --count 1 --instance-type t2.micro --key-name my-key-pair --security-group-ids $security_group_id --subnet-id $subnet_public_id --associate-public-ip-address --output text --query 'Instances[0].InstanceId')
instance_private_id=$(aws ec2 run-instances --image-id ami-0c94855ba95c71c99 --count 1 --instance-type t2.micro --key-name my-key-pair --security-group-ids $security_group_id --subnet-id $subnet_private_id --output text --query 'Instances[0].InstanceId')

# Espera a que las instancias estén en estado "running"
aws ec2 wait instance-running --instance-ids $instance_public_id
aws ec2 wait instance-running --instance-ids $instance_private_id

# Asigna
# Asigna una dirección IP elástica a la instancia pública
public_ip=$(aws ec2 allocate-address --domain vpc --output text --query 'PublicIp')
aws ec2 associate-address --instance-id $instance_public_id --public-ip $public_ip

# Crea una instancia de base de datos de RDS
rds_id=$(aws rds create-db-instance --db-name mydatabase --db-instance-identifier mydbinstance --db-instance-class db.t2.micro --engine mysql --allocated-storage 5 --master-username myuser --master-user-password mypassword --vpc-security-group-ids $security_group_id --output text --query 'DBInstance.DBInstanceIdentifier')

# Crea un bucket de S3
bucket_name=my-s3-bucket
aws s3api create-bucket --bucket $bucket_name --region us-east-1

# Muestra la información de la infraestructura creada
echo "VPC ID: $vpc_id"
echo "Subnet pública ID: $subnet_public_id"
echo "Subnet privada ID: $subnet_private_id"
echo "Instancia pública ID: $instance_public_id"
echo "Instancia privada ID: $instance_private_id"
echo "Dirección IP elástica de la instancia pública: $public_ip"
echo "Instancia de base de datos de RDS ID: $rds_id"
echo "Bucket de S3: $bucket_name"
