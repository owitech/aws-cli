#!/bin/bash

IAM_ID="SSMEC2connect"
AMI_ID="ami-006dcf34c09e50022"

GROUP_ID="sg-0229084012065926e"
SUBNET_ID="subnet-0310d3c34c7f23b55"

USER_DATA="file://configure.txt"
EBS_DEVICE="file://mapping.json"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --subnet-id $SUBNET_ID \
    --security-group-ids $GROUP_ID \
    --associate-public-ip-address \
    --key-name web \
    --iam-instance-profile Name=$IAM_ID \
    --instance-initiated-shutdown-behavior stop \
    --count 1 \
    --user-data $USER_DATA \
    --block-device-mappings $EBS_DEVICE \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=i-web Key=Hostname,Value=ec2-web

echo "Creating instance..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Output instance information
echo "Instance launched with ID: $INSTANCE_ID"
