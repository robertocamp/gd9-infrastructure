#!/bin/bash

# Fetch all EC2 instance IDs
INSTANCE_IDS=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)

for ID in $INSTANCE_IDS; do
  # For each instance ID, fetch and print the associated IAM role
  IAM_ROLE_ARN=$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[*].Instances[*].IamInstanceProfile.Arn' --output text)
  echo "Instance ID: $ID has IAM Role: $IAM_ROLE_ARN"
done
