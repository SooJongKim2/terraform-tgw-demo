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
    bucket         = "demo-shared-terraform-state-084828604478"
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

# 🔹 TGW ID 조회 (공유된 네트워크 계정에서)
data "aws_ssm_parameter" "tgw_id" {
  provider = aws.shared
  name     = "/terraform/network/tgw/id"
}

# 🔹 TGW Attachment 생성 (워크로드 VPC → TGW)
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids         = module.vpc.private_subnet_ids
  transit_gateway_id = data.aws_ssm_parameter.tgw_id.value
  vpc_id             = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-tgw-attachment"
  }

  depends_on = [module.vpc]
}

# 🔹 TGW Attachment ID를 SSM에 기록
resource "aws_ssm_parameter" "attachment_id" {
  provider = aws.shared
  name     = "/terraform/${var.environment}/tgw/attachment/id"
  type     = "String"
  value    = aws_ec2_transit_gateway_vpc_attachment.this.id

  tags = {
    Name = "${var.name}-tgw-attachment-id"
  }
}

# 🔹 프라이빗 서브넷의 0.0.0.0/0 기본 경로를 TGW로 설정
resource "aws_route" "to_tgw" {
  count                    = length(module.vpc.private_route_table_ids)
  route_table_id           = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block   = "0.0.0.0/0"
  transit_gateway_id       = data.aws_ssm_parameter.tgw_id.value

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}


# ✅ EC2 테스트 인스턴스
module "test_ec2" {
  source = "../../modules/ec2"

  name                 = var.name
  vpc_id              = module.vpc.vpc_id
  subnet_id           = module.vpc.private_subnet_ids[0]
  ami                 = "ami-03ff09c4b716e6425"
  instance_type       = "t3.micro"
  ssh_allowed_cidrs   = [module.vpc.vpc_cidr_block]
  associate_public_ip = false
}