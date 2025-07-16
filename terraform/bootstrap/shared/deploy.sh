#!/bin/bash

# 사용자 입력
NAME_PREFIX="demo"
ENV_NAME="shared"

REGION="ap-northeast-2"
STACK_NAME="${NAME_PREFIX}-${ENV_NAME}-terraform-bootstrap"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "[INFO] Deploying bootstrap resources into account: $ACCOUNT_ID (env: $ENV_NAME)"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file bootstrap.yaml \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides NamePrefix="$NAME_PREFIX" EnvName="$ENV_NAME"

echo "✅ Stack '$STACK_NAME' deployed successfully."

echo "Resources created:"
echo "- S3 Bucket: ${NAME_PREFIX}-${ENV_NAME}-terraform-state-${ACCOUNT_ID}"
echo "- DynamoDB Table: ${NAME_PREFIX}-${ENV_NAME}-terraform-lock"
echo "- IAM Role: ${NAME_PREFIX}-${ENV_NAME}-terraform-execution-role"
