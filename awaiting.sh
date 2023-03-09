#!/bin/bash

# 9. Create key-pairs to ec2
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-type ed25519 \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > basic-key-web.pem

# 11. Esperar a que la instancia este en modo "running"
aws ec2 wait instance-running \
    --instance-ids $INSTANCE_PUBLIC_ID

# Crear rol IAM
ROLE_NAME="my-ec2-role"
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://assume-role-policy.json --region $REGION
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ROLE_NAME --region $REGION
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID --iam-instance-profile Name=$ROLE_NAME --region $REGION

# Crea un bucket de S3
bucket_name=my-s3-bucket
aws s3api create-bucket --bucket $bucket_name --region us-east-1


# START AWAIT
# Espera a que las instancias estén en estado "running"
aws ec2 wait instance-running --instance-ids $instance_public_id
aws ec2 wait instance-running --instance-ids $instance_private_id

# Asigna
# Asigna una dirección IP elástica a la instancia pública
public_ip=$(aws ec2 allocate-address --domain vpc --output text --query 'PublicIp')
aws ec2 associate-address --instance-id $instance_public_id --public-ip $public_ip

# Crea una instancia de base de datos de RDS
rds_id=$(aws rds create-db-instance --db-name mydatabase --db-instance-identifier mydbinstance --db-instance-class db.t2.micro --engine mysql --allocated-storage 5 --master-username myuser --master-user-password mypassword --vpc-security-group-ids $security_group_id --output text --query 'DBInstance.DBInstanceIdentifier')
# END AWAIT

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