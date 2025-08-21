data "terraform_remote_state" "acc" {
  backend = "s3"
  config  = local.acc_state_config
}

data "terraform_remote_state" "net_prd_net_shr" {
  backend = "s3"
  config  = local.net_prd_net_shr_state_config
}

data "terraform_remote_state" "net_prd_net_tgw" {
  backend = "s3"
  config  = local.net_prd_net_tgw_state_config
}

locals {
  DEFAULT_REMOTE_STATE_CONFIG = {
    bucket = "cjos.devops-p-tfstate-s3"
    region = "ap-northeast-2"
  }

  acc_state_config = merge(local.DEFAULT_REMOTE_STATE_CONFIG, { key = "accounts/devops/production/terraform.tfstate" })
  ACC_RES          = data.terraform_remote_state.acc.outputs.result

  net_prd_net_shr_state_config = merge(local.DEFAULT_REMOTE_STATE_CONFIG, { key = "accounts/network/production/network/shared/terraform.tfstate" })
  net_prd_net_tgw_state_config = merge(local.DEFAULT_REMOTE_STATE_CONFIG, { key = "accounts/network/production/network/tgw/terraform.tfstate" })
  NET_PRD_NET_SHR_RES          = data.terraform_remote_state.net_prd_net_shr.outputs.result
  NET_PRD_NET_TGW_RES          = data.terraform_remote_state.net_prd_net_tgw.outputs.result
}