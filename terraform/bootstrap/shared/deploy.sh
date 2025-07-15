#!/bin/bash
set -e

# ✅ 사용자 입력: 이름 프리픽스 하나만
NAME_PREFIX="demo"

REGION="ap-northeast-2"
STACK_NAME="${NAME_PREFIX}-terraform-bootstrap"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "[INFO] Deploying bootstrap resources into account: $ACCOUNT_ID"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file bootstrap.yaml \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides NamePrefix="$NAME_PREFIX"

echo "✅ Stack '$STACK_NAME' deployed successfully."

echo "Resources created:"
echo "- S3 Bucket: ${NAME_PREFIX}-terraform-state-${ACCOUNT_ID}"
echo "- DynamoDB Table: ${NAME_PREFIX}-terraform-lock"
echo "- IAM Role: ${NAME_PREFIX}-terraform-ec2-role"
echo "- Instance Profile: ${NAME_PREFIX}-terraform-ec2-role"
