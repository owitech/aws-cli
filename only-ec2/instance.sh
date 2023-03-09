#!/bin/bash

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-006dcf34c09e50022 \
    --instance-type t2.micro \
    --subnet-id subnet-01fe45d0e71c4361f \
    --security-group-ids sg-025fd5c53b5952dae \
    --associate-public-ip-address \
    --key-name web \
    --iam-instance-profile Name=SSMEC2connect \
    --instance-initiated-shutdown-behavior stop \
    --count 1 \
    --user-data file://configure.txt \
    --block-device-mappings file://mapping.json \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=i-web

aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Output instance information
echo "Instance launched with ID: $INSTANCE_ID"