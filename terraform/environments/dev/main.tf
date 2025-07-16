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
    key            = "environments/dev/terraform.tfstate"
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

provider "aws" {
  alias   = "shared"
  region  = var.aws_region
}


module "vpc" {
  source = "../../modules/vpc"

  name                  = var.name
  vpc_cidr              = var.vpc_cidr  
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  isolated_subnet_cidrs = var.isolated_subnet_cidrs
}

resource "aws_ssm_parameter" "vpc_cidr" {
  provider = aws.shared
  name     = "/terraform/${var.environment}/vpc/cidr"
  type     = "String"
  value    = module.vpc.vpc_cidr_block 
  tags = {
    Name = "${var.name}-vpc-cidr"
  }
}