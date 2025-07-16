# 공통 TF_VAR 설정
# source ../_common/local_tfenv.sh

# assume role 세션 이름을 현재 프로파일의 사용자로부터 구성
CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
CALLER_ID=$(basename "$CALLER_ARN") 

# TF_VAR 설정
export TF_VAR_role_name="demo-member-terraform-apply"
export TF_VAR_session_name="tf-${CALLER_ID}"

echo "[tfenv] TF_VAR 설정 완료: session_name=${TF_VAR_session_name}"
