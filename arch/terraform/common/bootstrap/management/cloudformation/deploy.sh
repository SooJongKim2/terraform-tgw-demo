#!/bin/bash

# 스택 배포 설정
STACK_NAME="ct-devops-p-tf-iam"
APPLY_ROLE_NAME="ct-devops-p-tf-apply-iam_r"
PLAN_ROLE_NAME="ct-devops-p-tf-plan-iam_r"

REGION="ap-northeast-2"
TEMPLATE_FILE="bootstrap.yaml"

# ARN 리스트를 배열로 정의
APPLY_TRUST_ARNS_ARRAY=(
  "arn:aws:iam::522114752812:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_AWSAdministratorAccess_c184f8d61af8bb1a"
  "arn:aws:iam::522114752812:role/devops-p-tf-ec2-iam_r"
  "arn:aws:iam::522114752812:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_Admin_24f796c4dbc6e331"
  "arn:aws:iam::522114752812:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_TerraformPlan_dda8be9234c52fae"
)

PLAN_TRUST_ARNS_ARRAY=(
  "arn:aws:iam::522114752812:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_AWSAdministratorAccess_c184f8d61af8bb1a"
  "arn:aws:iam::522114752812:role/devops-p-tf-ec2-iam_r"
  "arn:aws:iam::522114752812:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_Admin_24f796c4dbc6e331"
  "arn:aws:iam::522114752812:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_TerraformPlan_dda8be9234c52fae"
)

# 배열을 쉼표로 연결하여 문자열로 변환
IFS=','
APPLY_TRUST_ARNS="\"$(echo "${APPLY_TRUST_ARNS_ARRAY[*]}")\""
PLAN_TRUST_ARNS="\"$(echo "${PLAN_TRUST_ARNS_ARRAY[*]}")\""
unset IFS

echo "[INFO] APPLY_TRUST_ARNS = ${APPLY_TRUST_ARNS}"
echo "[INFO] PLAN_TRUST_ARNS  = ${PLAN_TRUST_ARNS}"

# Stack 존재 여부 확인
echo "Stack 생성 또는 업데이트 중..."
if aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" &>/dev/null; then

  echo "✅ Stack이 이미 존재합니다. 업데이트를 진행합니다."
  aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://$TEMPLATE_FILE \
    --parameters \
      ParameterKey=ApplyRoleName,ParameterValue="$APPLY_ROLE_NAME" \
      ParameterKey=PlanRoleName,ParameterValue="$PLAN_ROLE_NAME" \
      ParameterKey=ApplyTrustArns,ParameterValue="$APPLY_TRUST_ARNS" \
      ParameterKey=PlanTrustArns,ParameterValue="$PLAN_TRUST_ARNS" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --tags Key=map-migrated,Value=migPV0803AMRO

  echo "⏳ Stack 업데이트 완료 대기 중..."
  aws cloudformation wait stack-update-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

else
  echo "🆕 Stack이 존재하지 않습니다. 생성합니다."
  aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://$TEMPLATE_FILE \
    --parameters \
      ParameterKey=ApplyRoleName,ParameterValue="$APPLY_ROLE_NAME" \
      ParameterKey=PlanRoleName,ParameterValue="$PLAN_ROLE_NAME" \
      ParameterKey=ApplyTrustArns,ParameterValue="$APPLY_TRUST_ARNS" \
      ParameterKey=PlanTrustArns,ParameterValue="$PLAN_TRUST_ARNS" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --tags Key=map-migrated,Value=migPV0803AMRO

  echo "⏳ Stack 생성 완료 대기 중..."
  aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"
fi

echo "✅ Stack 배포 완료: $STACK_NAME"