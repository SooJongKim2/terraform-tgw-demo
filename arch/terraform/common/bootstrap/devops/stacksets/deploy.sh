#!/bin/bash

# OU IDs를 배열로 정의
OU_IDS_ARRAY=(
  "ou-nz58-bru65ypz"
  # "ou-xxxx-xxxxxxxx"  # 필요시 추가
)

STACKSET_NAME="ct-devops-p-tf-iam"
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

# 배열을 쉼표로 연결된 문자열로 변환
IFS=','
APPLY_TRUST_ARNS="\"$(echo "${APPLY_TRUST_ARNS_ARRAY[*]}")\""
PLAN_TRUST_ARNS="\"$(echo "${PLAN_TRUST_ARNS_ARRAY[*]}")\""
unset IFS

# OU_IDS를 JSON 배열로 간단 변환 (printf 사용)
OU_IDS=$(printf ',"%s"' "${OU_IDS_ARRAY[@]}")
OU_IDS="[${OU_IDS:1}]"

echo "[INFO] OU_IDS = ${OU_IDS}"
echo "[INFO] APPLY_TRUST_ARNS = ${APPLY_TRUST_ARNS}"
echo "[INFO] PLAN_TRUST_ARNS  = ${PLAN_TRUST_ARNS}"

# StackSet 존재 여부 확인
echo "[1/3] StackSet 생성 또는 업데이트 중..."
if aws cloudformation describe-stack-set \
    --stack-set-name "$STACKSET_NAME" \
    --region "$REGION" \
    --call-as DELEGATED_ADMIN &>/dev/null; then

  echo "✅ StackSet이 이미 존재합니다. 업데이트를 진행합니다."
  aws cloudformation update-stack-set \
    --stack-set-name "$STACKSET_NAME" \
    --template-body file://$TEMPLATE_FILE \
    --parameters \
      ParameterKey=ApplyRoleName,ParameterValue=$APPLY_ROLE_NAME \
      ParameterKey=PlanRoleName,ParameterValue=$PLAN_ROLE_NAME \
      ParameterKey=ApplyTrustArns,ParameterValue="$APPLY_TRUST_ARNS" \
      ParameterKey=PlanTrustArns,ParameterValue="$PLAN_TRUST_ARNS" \
    --capabilities CAPABILITY_NAMED_IAM \
    --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false \
    --permission-model SERVICE_MANAGED \
    --region "$REGION" \
    --call-as DELEGATED_ADMIN \
    --tags Key=map-migrated,Value=migPV0803AMRO

  echo "[2/3] Stack Instances 동기화 중..."
  
  # StackSet 작업 완료 대기 함수
  wait_for_operation() {
    local operation_id=$1
    echo "⏳ 작업 ID $operation_id 완료 대기 중..."
    while true; do
      STATUS=$(aws cloudformation describe-stack-set-operation \
        --stack-set-name "$STACKSET_NAME" \
        --operation-id "$operation_id" \
        --region "$REGION" \
        --call-as DELEGATED_ADMIN \
        --query 'StackSetOperation.Status' \
        --output text 2>/dev/null)
      
      if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ 작업 $operation_id 완료"
        break
      elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "STOPPED" ]; then
        echo "❌ 작업 $operation_id 실패. Status: $STATUS"
        return 1
      else
        echo "🔄 작업 진행 중... (Status: $STATUS)"
        sleep 15
      fi
    done
    return 0
  }
  
  # 현재 배포된 Stack Instances 조회 (중복 제거)
  echo "🔍 현재 배포된 Stack Instances 조회 중..."
  CURRENT_INSTANCES=$(aws cloudformation list-stack-instances \
    --stack-set-name "$STACKSET_NAME" \
    --region "$REGION" \
    --call-as DELEGATED_ADMIN \
    --query 'Summaries[].OrganizationalUnitId' \
    --output text | tr '\t' '\n' | sort -u | tr '\n' ' ')
  
  # 새로운 OU IDs 파싱 (배열에서 추출)
  NEW_OU_LIST=""
  for ou in "${OU_IDS_ARRAY[@]}"; do
    NEW_OU_LIST="$NEW_OU_LIST$ou "
  done
  
  echo "📋 현재 OU IDs: $CURRENT_INSTANCES"
  echo "📋 새로운 OU IDs: $NEW_OU_LIST"
  
  # 제거할 OU 찾기 (현재 있지만 새 목록에 없는 것)
  for current_ou in $CURRENT_INSTANCES; do
    if ! echo "$NEW_OU_LIST" | grep -q "$current_ou"; then
      echo "🗑️  OU $current_ou 에서 Stack Instance 삭제 중..."
      OPERATION_OUTPUT=$(aws cloudformation delete-stack-instances \
        --stack-set-name "$STACKSET_NAME" \
        --deployment-targets "OrganizationalUnitIds=[\"$current_ou\"]" \
        --regions "$REGION" \
        --no-retain-stacks \
        --operation-preferences '{"FailureToleranceCount":5,"MaxConcurrentCount":10}' \
        --region "$REGION" \
        --call-as DELEGATED_ADMIN)
      
      DELETE_OPERATION_ID=$(echo "$OPERATION_OUTPUT" | jq -r '.OperationId')
      if [ "$DELETE_OPERATION_ID" != "null" ] && [ ! -z "$DELETE_OPERATION_ID" ]; then
        wait_for_operation "$DELETE_OPERATION_ID"
      fi
    fi
  done
  
  # 추가할 OU 찾기 (새 목록에 있지만 현재 없는 것)
  for new_ou in "${OU_IDS_ARRAY[@]}"; do
    if ! echo "$CURRENT_INSTANCES" | grep -q "$new_ou"; then
      echo "➕ OU $new_ou 에 Stack Instance 추가 중..."
      OPERATION_OUTPUT=$(aws cloudformation create-stack-instances \
        --stack-set-name "$STACKSET_NAME" \
        --deployment-targets "OrganizationalUnitIds=[\"$new_ou\"]" \
        --regions "$REGION" \
        --operation-preferences '{"FailureToleranceCount":5,"MaxConcurrentCount":10}' \
        --region "$REGION" \
        --call-as DELEGATED_ADMIN)
      
      CREATE_OPERATION_ID=$(echo "$OPERATION_OUTPUT" | jq -r '.OperationId')
      if [ "$CREATE_OPERATION_ID" != "null" ] && [ ! -z "$CREATE_OPERATION_ID" ]; then
        wait_for_operation "$CREATE_OPERATION_ID"
      fi
    fi
  done
  
  # 기존 OU에 대해서는 업데이트 실행
  EXISTING_OUS=""
  for new_ou in "${OU_IDS_ARRAY[@]}"; do
    if echo "$CURRENT_INSTANCES" | grep -q "$new_ou"; then
      if [ -z "$EXISTING_OUS" ]; then
        EXISTING_OUS="\"$new_ou\""
      else
        EXISTING_OUS="$EXISTING_OUS,\"$new_ou\""
      fi
    fi
  done
  
  if [ ! -z "$EXISTING_OUS" ]; then
    echo "🔄 기존 OU [$EXISTING_OUS]의 Stack Instances 업데이트 중..."
    OPERATION_OUTPUT=$(aws cloudformation update-stack-instances \
      --stack-set-name "$STACKSET_NAME" \
      --deployment-targets "OrganizationalUnitIds=[$EXISTING_OUS]" \
      --regions "$REGION" \
      --operation-preferences '{"FailureToleranceCount":5,"MaxConcurrentCount":10}' \
      --region "$REGION" \
      --call-as DELEGATED_ADMIN)
    
    UPDATE_OPERATION_ID=$(echo "$OPERATION_OUTPUT" | jq -r '.OperationId')
    if [ "$UPDATE_OPERATION_ID" != "null" ] && [ ! -z "$UPDATE_OPERATION_ID" ]; then
      wait_for_operation "$UPDATE_OPERATION_ID"
    fi
  fi

else
  echo "🆕 StackSet이 존재하지 않습니다. 생성합니다."
  aws cloudformation create-stack-set \
    --stack-set-name "$STACKSET_NAME" \
    --template-body file://$TEMPLATE_FILE \
    --parameters \
      ParameterKey=ApplyRoleName,ParameterValue=$APPLY_ROLE_NAME \
      ParameterKey=PlanRoleName,ParameterValue=$PLAN_ROLE_NAME \
      ParameterKey=ApplyTrustArns,ParameterValue="$APPLY_TRUST_ARNS" \
      ParameterKey=PlanTrustArns,ParameterValue="$PLAN_TRUST_ARNS" \
    --capabilities CAPABILITY_NAMED_IAM \
    --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false \
    --permission-model SERVICE_MANAGED \
    --region "$REGION" \
    --call-as DELEGATED_ADMIN \
    --tags Key=map-migrated,Value=migPV0803AMRO

  echo "[2/3] Stack Instances 배포 중..."
  aws cloudformation create-stack-instances \
    --stack-set-name "$STACKSET_NAME" \
    --deployment-targets "OrganizationalUnitIds=${OU_IDS}" \
    --regions "$REGION" \
    --operation-preferences '{"FailureToleranceCount":5,"MaxConcurrentCount":10}' \
    --region "$REGION" \
    --call-as DELEGATED_ADMIN
fi

# 모든 작업 완료 확인
echo "[3/3] 모든 Stack Instance 작업이 완료되었습니다."

echo "✅ StackSet 및 Stack Instances 처리 완료"