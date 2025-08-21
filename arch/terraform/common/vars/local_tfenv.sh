# 사용법 source ../_common/local_tfenv.sh
export TF_VAR_role_name="ct-devops-p-tf-apply-iam_r"

# assume role 세션 이름을 현재 프로파일의 사용자로부터 구성
export TF_VAR_session_name="tf-$(basename $(aws sts get-caller-identity --query Arn --output text 2>/dev/null))"
echo "[tfenv] TF_VAR 설정 완료: session_name=${TF_VAR_session_name}"

export TF_VAR_acc_id_management_prd="724772064101"

export TF_VAR_acc_id_devops_prd="522114752812"
export TF_VAR_acc_id_net_prd="967883358468"
export TF_VAR_acc_id_cjos_dev="718950864915"

export TF_VAR_map_tag_value="migPV0803AMRO"