module "d" {
  source = "git::https://gitlab.cjoshopping.com/nextstyle/arch/terraform/modules.git//dictionary"
}

terraform {
  backend "s3" {
    bucket         = "cjos.devops-p-tfstate-s3"
    key            = "accounts/devops/production/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "cjos_devops-p-tflock-ddb-ap_ne2"
  }
}

output "result" {
  value = {
    context = {
      PROJECT     = local.PROJ_OUT.result.name
      ENVIRONMENT = module.d.TRM.ENV.PRODUCTION
    }
    subjects = local.PROJ_OUT.result.subjects
  }
}