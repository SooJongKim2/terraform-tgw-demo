data "terraform_remote_state" "proj" {
  backend = "s3"
  config  = local.proj_state_config
}

locals {
  DEFAULT_REMOTE_STATE_CONFIG = {
    bucket = "cjos.devops-p-tfstate-s3"
    region = "ap-northeast-2"
  }

  proj_state_config = merge(local.DEFAULT_REMOTE_STATE_CONFIG, { key = "accounts/devops/terraform.tfstate" })
  PROJ_OUT          = data.terraform_remote_state.proj.outputs
}