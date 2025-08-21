#!/bin/bash
STACK_NAME="devops-p-bootstrap"

STATE_BUCKET_NAME="cjos.devops-p-tfstate-s3"
LOCK_TABLE_NAME="cjos_devops-p-tflock-ddb-ap_ne2"
EC2_ROLE_NAME="devops-p-tf-ec2-iam_r"
REGION="ap-northeast-2"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "[INFO] Deploying bootstrap resources into account: $ACCOUNT_ID"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file bootstrap.yaml \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    StateBucketName="$STATE_BUCKET_NAME" \
    LockTableName="$LOCK_TABLE_NAME" \
    Ec2RoleName="$EC2_ROLE_NAME" \
  --tags map-migrated=migPV0803AMRO