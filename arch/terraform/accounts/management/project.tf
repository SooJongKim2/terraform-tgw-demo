terraform {
  backend "s3" {
    bucket         = "cjos.devops-p-tfstate-s3"
    key            = "accounts/management/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "cjos_devops-p-tflock-ddb-ap_ne2"
  }
}
output "result" {
  value = {
    name = {
      ABBR = "management"
      TERM = "management"
    }
    subjects = {
      management = {
        ABBR = "mng"
        TERM = "management"
      },
      data = {
        ABBR = "data"
        TERM = "data"
      },
      common = {
        ABBR = "com"
        TERM = "common"
      },
    }
  }
}