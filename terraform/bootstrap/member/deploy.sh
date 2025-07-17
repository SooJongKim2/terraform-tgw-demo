#!/bin/bash
set -e

# 중앙 계정 ID를 인자로 입력받음
if [ -z "$1" ]; then
  echo "[ERROR] Shared Account ID를 인자로 입력해야 합니다."
  echo "사용 예: ./deploy.sh 123456789012"
  exit 1
fi

# 사용자 입력
NAME_PREFIX="demo"
REGION="ap-northeast-2"

# 워크로드 계정의 환경 이름
ENV_NAME="member"

# 중앙 계정의 환경 이름
SHARED_ENV_NAME="shared"

SHARED_ACCOUNT_ID="$1"

# 중앙 계정의 EC2 Role 이름
TRUST_ROLE_NAME="${NAME_PREFIX}-${SHARED_ENV_NAME}-terraform-ec2-role"

# Trust ARNs
APPLY_TRUST_ARNS="arn:aws:iam::${SHARED_ACCOUNT_ID}:role/${TRUST_ROLE_NAME}"
PLAN_TRUST_ARNS="arn:aws:iam::${SHARED_ACCOUNT_ID}:role/${TRUST_ROLE_NAME}"

# CloudFormation Stack 이름
STACK_NAME="${NAME_PREFIX}-${ENV_NAME}-terraform-roles"

echo "[INFO] 워크로드 계정에 Terraform plan/apply 역할을 생성 중..."

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file bootstrap.yaml \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NamePrefix="${NAME_PREFIX}" \
    EnvName="${ENV_NAME}" \
    ApplyTrustArns="${APPLY_TRUST_ARNS}" \
    PlanTrustArns="${PLAN_TRUST_ARNS}"

echo "✅ Role 생성 완료:"
echo "- Apply Role Name: ${NAME_PREFIX}-${ENV_NAME}-terraform-apply"
echo "- Plan  Role Name: ${NAME_PREFIX}-${ENV_NAME}-terraform-plan"
