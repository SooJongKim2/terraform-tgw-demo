module "d" {
  source = "git::https://gitlab.cjoshopping.com/nextstyle/arch/terraform/modules.git//dictionary"
}

provider "aws" {
  region = "ap-northeast-2"
  assume_role {
    role_arn     = "arn:aws:iam::${var.acc_id_devops_prd}:role/${var.role_name}"
    session_name = var.session_name
  }
  default_tags {
    tags = {
      "${module.d.DFN.TAG.PROJECT}"     = local.ACC_RES.context.PROJECT.TERM
      "${module.d.DFN.TAG.ENVIRONMENT}" = local.ACC_RES.context.ENVIRONMENT.TERM
      "${module.d.DFN.TAG.MAP}"         = var.map_tag_value
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "cjos.devops-p-tfstate-s3"
    key            = "accounts/devops/production/network/vpc/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "cjos_devops-p-tflock-ddb-ap_ne2"
  }
}

locals {
  VPC_CIDR_BLOCK = local.NET_PRD_NET_SHR_RES.cidr_blocks["${local.ACC_RES.context.PROJECT.ABBR}_${local.ACC_RES.context.ENVIRONMENT.ABBR}"]
  TG_CIDR_BLOCKS = [for k, v in local.NET_PRD_NET_SHR_RES.cidr_blocks : v if k != "${local.ACC_RES.context.PROJECT.ABBR}_${local.ACC_RES.context.ENVIRONMENT.ABBR}"]
}
module "vpc" {
  source = "git::https://gitlab.cjoshopping.com/nextstyle/arch/terraform/modules.git//network/vpc"

  acc_ctx        = local.ACC_RES.context
  vpc_cidr_block = local.VPC_CIDR_BLOCK
  edge_config = {
    edge_type = "NONE"
  }
  transit_gateway = {
    cidr_blocks = local.TG_CIDR_BLOCKS
    id          = local.NET_PRD_NET_TGW_RES.transit_gateway_id
  }
  merge_service_to = {
    management = true
  }
}

output "result" {
  value = merge({ cidr_block : local.VPC_CIDR_BLOCK }, module.vpc.result)
}

output "debug" {
  value = local.NET_PRD_NET_TGW_RES
}