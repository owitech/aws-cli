# VPC
## Commands
- `aws ec2 create-vpc --generate-cli-skeleton`

## VPC
- Delete: `aws ec2 delete-vpc --vpc-id <id>`
- Lists Id: `aws ec2 describe-vpcs --query "Vpcs[].VpcId"`

## Subnet

## Route
- `aws ec2 disassociate-route-table --association-id $RTB_ASSOC_PUBLIC_ID`

## Security group
- `aws ec2 revoke-security-group-ingress --group-id SG_ID --security-group-rule-ids SGR_ID`