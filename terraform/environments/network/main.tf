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
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/${var.role_name}"
    session_name = var.session_name
  }
}

provider "aws" {
  alias  = "shared"
  region = var.aws_region
}



# ✅ TGW 생성
resource "aws_ec2_transit_gateway" "this" {
  description                      = "Shared TGW for external accounts"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  security_group_referencing_support = "enable"
  tags = {
    Name = var.name
  }
}

# ✅ RAM 공유 생성 (외부 계정 사용을 허용)
resource "aws_ram_resource_share" "tgw_share" {
  name                       = "${var.name}-share"
  allow_external_principals = true

  tags = {
    Name = "${var.name}-tgw-share"
  }
}

# ✅ TGW를 RAM 쉐어에 연결
resource "aws_ram_resource_association" "tgw_assoc" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

# ✅ 외부 계정들에게 초대장 발송
resource "aws_ram_principal_association" "external_accounts" {
  for_each           = toset(var.member_account_ids)
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
  principal          = each.value  # 계정 ID만 사용
}


# ✅ TGW ID를 파라미터스토어에 기록
resource "aws_ssm_parameter" "tgw_id" {
  provider = aws.shared
  name     = "/terraform/${var.environment}/tgw/id"
  type     = "String"
  value    = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "TGW ID Parameter"
  }
}


# ✅ TGW Route Tables
resource "aws_ec2_transit_gateway_route_table" "dev" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "${var.name}-rtb-dev"
    Env  = "dev"
  }
}


resource "aws_ec2_transit_gateway_route_table" "shared" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "${var.name}-rtb-shared"
    Env  = "shared"
  }
}

resource "aws_ec2_transit_gateway_route_table" "network" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "${var.name}-rtb-network"
    Env  = "network"
  }
}


## ✅ TNetwork VPC
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

# 🔹 TGW Attachment 생성
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
# 🔹 프라이빗 서브넷의 10.0.0.0/8 기본 경로를 TGW로 설정
resource "aws_route" "to_tgw" {
  count                  = length(module.vpc.private_route_table_ids)
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = var.internal_cidr_block
  transit_gateway_id     = data.aws_ssm_parameter.tgw_id.value

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}


## 1차로 여기까지 (워크로드 생성후에 아래 수행)
# ✅ Static Routes in TGW Route Tables

# 🔹 SSM에서 Attachment ID 및 VPC CIDR 읽기
data "aws_ssm_parameter" "network_attachment_id" {
  provider = aws.shared
  name     = "/terraform/network/tgw/attachment/id"
  depends_on = [aws_ssm_parameter.attachment_id]
}


data "aws_ssm_parameter" "shared_attachment_id" {
  provider = aws.shared
  name     = "/terraform/shared/tgw/attachment/id"
}


data "aws_ssm_parameter" "dev_attachment_id" {
  provider = aws.shared
  name     = "/terraform/dev/tgw/attachment/id"
}


data "aws_ssm_parameter" "dev_vpc_cidr" {
  provider = aws.shared
  name     = "/terraform/dev/vpc/cidr"
}



data "aws_ssm_parameter" "shared_vpc_cidr" {
  provider = aws.shared
  name     = "/terraform/shared/vpc/cidr"
}

## Dev RT: allow shared + internet
resource "aws_ec2_transit_gateway_route" "dev_to_shared" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev.id
  destination_cidr_block         = data.aws_ssm_parameter.shared_vpc_cidr.value
  transit_gateway_attachment_id  = data.aws_ssm_parameter.shared_attachment_id.value
}

resource "aws_ec2_transit_gateway_route" "dev_to_internet" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev.id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = data.aws_ssm_parameter.network_attachment_id.value
}


## Shared RT: allow dev, prd, internet
resource "aws_ec2_transit_gateway_route" "shared_to_dev" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
  destination_cidr_block         = data.aws_ssm_parameter.dev_vpc_cidr.value
  transit_gateway_attachment_id  = data.aws_ssm_parameter.dev_attachment_id.value
}



resource "aws_ec2_transit_gateway_route" "shared_to_internet" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = data.aws_ssm_parameter.network_attachment_id.value
}

# Network RT intentionally left empty (no routes needed)
# Attachment will still be associated to tgw-rtb-network