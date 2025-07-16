terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "demo-shared-terraform-state-021891598063"
    key            = "environments/network/terraform.tfstate"
    dynamodb_table = "demo-shared-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/${var.role_name}"
    session_name = var.session_name
  }
}