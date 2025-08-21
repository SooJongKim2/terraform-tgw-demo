# module "d" {
#   source = "git::https://gitlab.cjoshopping.com/nextstyle/arch/terraform/modules.git//dictionary"
# }
module "d" {
  source = "../../../../../modules/dictionary"
}

provider "aws" {
  region = "ap-northeast-2"
  assume_role {
    role_arn     = "arn:aws:iam::${var.acc_id_mgmt_prd}:role/${var.role_name}"
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
    key            = "accounts/management/production/security/identity_center/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "cjos_devops-p-tflock-ddb-ap_ne2"
  }
}
locals {
  session_duration = "PT8H"
  
  ip_deny_statement = {
    Effect   = "Deny"
    Action   = "*"
    Resource = "*"
    Condition = {
      NotIpAddress = {
        "aws:SourceIp" = ["1.215.252.66/32", "210.122.105.5/32"]
      }
    }
  }
  
  vdi_passthrough_vpc_statement = {
    Effect   = "Deny"
    Action   = "*"
    Resource = "*"
    Condition = {
      StringNotEqualsIfExists = {
        "aws:SourceVpc" = "vpc-12345678"
      }
    }
  }
}

module "aws-iam-identity-center" {
  source  = "aws-ia/iam-identity-center/aws"
  version = "1.0.3"  

  # -----------------------
  # SSO Groups
  # -----------------------
  sso_groups = {
    cj_enm_arch_team_admin = {
      group_name        = "cj_enm_arch_team_admin"
      group_description = "Architecture team admins"
    }
    cj_enm_arch_team = {
      group_name        = "cj_enm_arch_team"
      group_description = "Architecture team"
    }
    cj_enm_security_team = {
      group_name        = "cj_enm_security_team"
      group_description = "Security team"
    }
    cj_enm_dev_team = {
      group_name        = "cj_enm_dev_team"
      group_description = "Application dev team"
    }
    cj_ons_msp = {
      group_name        = "cj_ons_msp"
      group_description = "MSP"
    }
    external_landingzone_setup_temp = {
      group_name        = "external_landingzone_setup_temp"
      group_description = "External temporary for landing zone setup"
    }
  }

  # -----------------------
  # Account Assignments 
  # -----------------------
  account_assignments = {
    # cj_enm_arch_team_admin
    arch_admin_Admin = {
      principal_name  = "cj_enm_arch_team_admin"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = [
        var.acc_id_mgmt_prd,
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_net_prd,
        var.acc_id_devops_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev
      ]
    }
    arch_admin_ReadOnly = {
      principal_name  = "cj_enm_arch_team_admin"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = [
        var.acc_id_mgmt_prd,
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_net_prd,
        var.acc_id_devops_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev
      ]
    }
    
    arch_admin_TerraformPlan = {
      principal_name  = "cj_enm_arch_team_admin"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["TerraformPlan"]
      account_ids     = [var.acc_id_devops_prd]
    }

    # cj_enm_arch_team
    arch_team_ReadOnly = {
      principal_name  = "cj_enm_arch_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = [
        var.acc_id_mgmt_prd,
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_net_prd,
        var.acc_id_devops_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev
      ]
    }
    arch_team_TerraformPlan = {
      principal_name  = "cj_enm_arch_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["TerraformPlan"]
      account_ids     = [var.acc_id_devops_prd]
    }
    arch_team_Admin = {
      principal_name  = "cj_enm_arch_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = [
        # var.acc_id_cjos_prd, 
        var.acc_id_cjos_dev
      ]
    }

    # cj_enm_security_team
    security_team_ReadOnly = {
      principal_name  = "cj_enm_security_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = [
        var.acc_id_mgmt_prd,
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_devops_prd,
        var.acc_id_net_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev
      ]
    }
    security_team_ControlTowerControls = {
      principal_name  = "cj_enm_security_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ControlTowerControls"]
      account_ids     = [var.acc_id_mgmt_prd]
    }
    security_team_Admin = {
      principal_name  = "cj_enm_security_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = [var.acc_id_log_prd, var.acc_id_audit_prd]
    }
    security_team_Firewall = {
      principal_name  = "cj_enm_security_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Firewall"]
      account_ids     = [var.acc_id_net_prd]
    }
    security_team_WAF = {
      principal_name  = "cj_enm_security_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["WAF"]
      account_ids     = [
        # var.acc_id_cjos_prd, 
        var.acc_id_cjos_dev
      ]
    }

    # cj_enm_dev_team
    dev_team_ReadOnly = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = [
        var.acc_id_devops_prd, 
        var.acc_id_net_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev
      ]
    }
    dev_team_TerraformPlan = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["TerraformPlan"]
      account_ids     = [var.acc_id_devops_prd]
    }
    dev_team_EC2SSMAccess = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["EC2SSMAccess"]
      account_ids     = [
        # var.acc_id_cjos_prd, 
        var.acc_id_cjos_dev
      ]
    }

    dev_team_EC2SSMAccess_VDI = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["EC2SSMAccess-VDI"]
      account_ids     = [
        # var.acc_id_cjos_prd
      ]
    }
    dev_team_EKSViewAccess = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["EKSViewAccess"]
      account_ids     = [
        # var.acc_id_cjos_prd, 
        var.acc_id_cjos_dev
      ]
    }

    dev_team_EKSViewAccess_VDI = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["EKSViewAccess-VDI"]
      account_ids     = [
        # var.acc_id_cjos_prd
      ]
    }
    dev_team_EKSAdminAccess = {
      principal_name  = "cj_enm_dev_team"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["EKSAdminAccess"]
      account_ids     = [
        # var.acc_id_cjos_prd, 
        var.acc_id_cjos_dev
      ]
    }

    # cj_ons_msp
    msp_ReadOnly = {
      principal_name  = "cj_ons_msp"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = [
        var.acc_id_mgmt_prd,
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_devops_prd,
        var.acc_id_net_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev
      ]
    }

    # external_landingzone_setup_temp
    external_temp_ReadOnly = {
      principal_name  = "external_landingzone_setup_temp"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = [
        var.acc_id_mgmt_prd,
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_net_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev,
        var.acc_id_devops_prd
      ]
    }
    external_temp_Admin = {
      principal_name  = "external_landingzone_setup_temp"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = [
        var.acc_id_log_prd,
        var.acc_id_audit_prd,
        var.acc_id_net_prd,
        # var.acc_id_cjos_prd,
        var.acc_id_cjos_dev,
        var.acc_id_devops_prd
      ]
    }

    external_temp_TerraformPlan = {
      principal_name  = "external_landingzone_setup_temp"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["TerraformPlan"]
      account_ids     = [var.acc_id_devops_prd]
    }
  }

  # -----------------------
  # Permission Sets 
  # -----------------------
  permission_sets = {
    Admin = {
      description          = "Administrator access"
      session_duration     = local.session_duration
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.ip_deny_statement]
      })
    }
    ReadOnly = {
      description          = "Read only access"
      session_duration     = local.session_duration
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.ip_deny_statement]
      })
    }
    EC2SSMAccess = {
      description          = "ReadOnly + EC2 SSM access"
      session_duration     = local.session_duration
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"        
      ]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          local.ip_deny_statement,
          {
            Effect   = "Allow"
            Action   = [
              "ssm:StartSession",
              "ssm:TerminateSession",
              "ssm:ResumeSession",
              "ssm:DescribeSessions",
              "ssm:GetConnectionStatus",
              "ssmmessages:CreateControlChannel",
              "ssmmessages:CreateDataChannel",
              "ssmmessages:OpenControlChannel",
              "ssmmessages:OpenDataChannel",
              "ssm:DescribeInstanceInformation",
              "ec2:DescribeInstances",
              "ec2:DescribeTags"
            ]
            Resource = "*"
          }
        ]
      })
    }
    "EC2SSMAccess-VDI" = {
      description          = "ReadOnly + EC2 SSM access (VDI only)"
      session_duration     = local.session_duration
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"        
      ]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          local.vdi_passthrough_vpc_statement,
          {
            Effect   = "Allow"
            Action   = [
              "ssm:StartSession",
              "ssm:TerminateSession",
              "ssm:ResumeSession",
              "ssm:DescribeSessions",
              "ssm:GetConnectionStatus",
              "ssmmessages:CreateControlChannel",
              "ssmmessages:CreateDataChannel",
              "ssmmessages:OpenControlChannel",
              "ssmmessages:OpenDataChannel",
              "ssm:DescribeInstanceInformation",
              "ec2:DescribeInstances",
              "ec2:DescribeTags"
            ]
            Resource = "*"
          }
        ]
      })
    }

    TerraformPlan = {
      description          = "Terraform plan only"
      session_duration     = local.session_duration
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          local.ip_deny_statement,
          {
            "Effect": "Allow",
            "Action": ["sts:AssumeRole","sts:TagSession"],
            "Resource": "arn:aws:iam::*:role/ct-devops-p-tf-plan-iam_r"
          },
          {
            "Effect": "Allow",
            "Action": [
              "s3:GetObject",
              "s3:ListBucket"
            ],
            "Resource": [
              "arn:aws:s3:::cjos.devops-p-tfstate-s3",
              "arn:aws:s3:::cjos.devops-p-tfstate-s3/*"
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem",
                "dynamodb:DescribeTable"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/cjos_devops-p-tflock-ddb-ap_ne2"
          },
          {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:AddTagsToResource",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:GetParameterHistory",
                "ssm:DeleteParameter",
                "ssm:DeleteParameters",
                "ssm:LabelParameterVersion",
                "ssm:ListTagsForResource"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/terraform/*"
          }
        ]
      })
    }

    ControlTowerControls = {
      description          = "Control Tower controls"
      session_duration     = local.session_duration
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"      
        ]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          local.ip_deny_statement,
          {
            "Sid": "ControlTowerAccess",
            "Effect": "Allow",
            "Action": [
              "controltower:Get*",
              "controltower:List*",
              "controltower:Describe*",
              "controltower:EnableControl",
              "controltower:DisableControl",
              "controlcatalog:Get*",
              "controlcatalog:List*",
              "organizations:CreatePolicy",
              "organizations:UpdatePolicy",
              "organizations:AttachPolicy",
              "organizations:Describe*",
              "organizations:List*",
              "account:Get*",
              "account:List*"
            ],
            "Resource": "*"
          }
        ]
      })
    }
    Firewall = {
      description          = "Network firewall management"
      session_duration     = local.session_duration
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AWSNetworkFirewallFullAccess"
        ]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.ip_deny_statement]
      })
    }
    WAF = {
      description          = "WAF visibility/ops"
      session_duration     = local.session_duration
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AWSWAFFullAccess"      
      ]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.ip_deny_statement]
      })
    }
    EKSViewAccess = {
      description          = "EKS View access"
      session_duration     = local.session_duration
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.ip_deny_statement]
      })
    }
    "EKSViewAccess-VDI" = {
      description          = "EKS View access (VDI only)"
      session_duration     = local.session_duration
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.vdi_passthrough_vpc_statement]
      })
    }
    EKSAdminAccess = {
      description          = "EKS Admin access"
      session_duration     = local.session_duration
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [local.ip_deny_statement]
      })
    }
  }

}