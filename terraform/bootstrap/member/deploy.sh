#!/bin/bash
set -e

NAME_PREFIX="demo"
REGION="ap-northeast-2"
STACK_NAME="${NAME_PREFIX}-terraform-access-roles"

# Comma-delimited list로 입력 (예: arn1,arn2,arn3)
APPLY_TRUST_ARNS="arn:aws:iam::021891598063:role/demo-terraform-ec2-role"
PLAN_TRUST_ARNS="arn:aws:iam::021891598063:role/demo-terraform-ec2-role"

echo "[INFO] 워크로드 계정에 Terraform용 Assume 대상 Roles 생성 중..."
aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file bootstrap.yaml \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NamePrefix="$NAME_PREFIX" \
    ApplyTrustArns="$APPLY_TRUST_ARNS" \
    PlanTrustArns="$PLAN_TRUST_ARNS"

echo "✅ Role 생성 완료:"
echo "- Apply Role Name: ${NAME_PREFIX}-shared-terraform-apply"
echo "- Plan  Role Name: ${NAME_PREFIX}-shared-terraform-plan"
