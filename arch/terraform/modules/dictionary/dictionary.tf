locals {
  TRM = {
    ENV = {
      DEVELOPMENT = { ABBR = "d", TERM = "Development" },
      PRODUCTION  = { ABBR = "p", TERM = "Production" }
    },
    PHASE = {
      DEVELOPMENT_COMMON = { ABBR = "dc", TERM = "Development Common" }
      PRODUCTION_COMMON  = { ABBR = "pc", TERM = "Production Common" }
      DEV                = { ABBR = "d", TERM = "Development" },
      QA                 = { ABBR = "q", TERM = "QA" },
      STG                = { ABBR = "s", TERM = "Staging" },
      PRD                = { ABBR = "p", TERM = "Production" }
    },
    RGN = {
      us-east-1      = { ABBR = "us_e1", TERM = "US East (N. Virginia)" },
      us-east-2      = { ABBR = "us_e2", TERM = "US East (Ohio)" },
      us-west-1      = { ABBR = "us_w1", TERM = "US West (N. California)" },
      us-west-2      = { ABBR = "us_w2", TERM = "US West (Oregon)" },
      ap-south-1     = { ABBR = "ap_s1", TERM = "Asia Pacific (Mumbai)" },
      ap-southeast-1 = { ABBR = "ap_se1", TERM = "Asia Pacific (Singapore)" },
      ap-southeast-2 = { ABBR = "ap_se2", TERM = "Asia Pacific (Sydney)" },
      ap-northeast-1 = { ABBR = "ap_ne1", TERM = "Asia Pacific (Tokyo)" },
      ap-northeast-2 = { ABBR = "ap_ne2", TERM = "Asia Pacific (Seoul)" },
      ap-northeast-3 = { ABBR = "ap_ne3", TERM = "Asia Pacific (Osaka)" },
    },
    RSC = {
      AWS_VPC                             = { ABBR = "vpc", TERM = "vpc" },
      AWS_SUBNET                          = { ABBR = "sbn", TERM = "subnet" },
      AWS_INTERNET_GATEWAY                = { ABBR = "igw", TERM = "internet_gateway" },
      AWS_NAT_GATEWAY                     = { ABBR = "ngw", TERM = "nat_gateway" },
      AWS_EIP                             = { ABBR = "eip", TERM = "elastic_ip" },
      AWS_ROUTE                           = { ABBR = "rt", TERM = "route" },
      AWS_ROUTE_TABLE                     = { ABBR = "rtt", TERM = "route_table" },
      AWS_ROUTE_TABLE_ASSOCIATION         = { ABBR = "rtt_asc", TERM = "route_table_association" },
      AWS_S3_BUCKET                       = { ABBR = "s3", TERM = "s3_bucket" },
      AWS_DYNAMODB_TABLE                  = { ABBR = "ddb", TERM = "dynamodb_table" },
      AWS_NETWORK_ACL                     = { ABBR = "nacl", TERM = "network_acl" },
      AWS_SECURITY_GROUP                  = { ABBR = "sg", TERM = "security_group" },
      AWS_VPC_ENDPOINT                    = { ABBR = "vpc_ep", TERM = "vpc_endpoint" },
      AWS_IAM_ROLE                        = { ABBR = "iam_r", TERM = "iam_role" },
      AWS_IAM_INSTANCE_PROFILE            = { ABBR = "iam_ip", TERM = "iam_instance_profile" },
      AWS_IAM_POLICY                      = { ABBR = "iam_p", TERM = "iam_policy" },
      AWS_KMS_ALIAS                       = { ABBR = "kms_a", TERM = "kms_alias" },
      AWS_CLOUDWATCH_LOG_GROUP            = { ABBR = "cwlg", TERM = "cloudwatch_log_group" },
      AWS_SSM_DOCUMENT                    = { ABBR = "ssm_doc", TERM = "ssm_document" },
      AWS_INSTANCE                        = { ABBR = "ec2", TERM = "instance" },
      AWS_SECRETS_MANAGER                 = { ABBR = "sm", TERM = "secrets_manager" },
      AWS_EBS_VOLUME                      = { ABBR = "ebs", TERM = "ebs_volume" },
      AWS_EBS_SNAPSHOT                    = { ABBR = "ebs_snap", TERM = "ebs_snapshot" },
      AWS_EFS_FILE_SYSTEM                 = { ABBR = "efs", TERM = "efs_file_system" },
      AWS_KEY_PAIR                        = { ABBR = "kp", TERM = "key_pair" },
      AWS_NETWORKFIREWALL_FIREWALL        = { ABBR = "nfw", TERM = "networkfirewall_firewall" },
      AWS_NETWORKFIREWALL_RULE_GROUP      = { ABBR = "nfw_rg", TERM = "networkfirewall_rule_group" },
      AWS_NETWORKFIREWALL_FIREWALL_POLICY = { ABBR = "nfw_fp", TERM = "networkfirewall_firewall_policy" },
      AWS_RAM_RESOURCE_SHARE              = { ABBR = "ram_rs", TERM = "ram_resource_share" },
      AWS_RAM_RESOURCE_ASSOCIATION        = { ABBR = "ram_ra", TERM = "ram_resource_association" },
      AWS_RAM_PRINCIPAL_ASSOCIATION       = { ABBR = "ram_pa", TERM = "ram_principal_association" }
    }
  }
}

output "TRM" {
  value = local.TRM
}

locals {
  KTRM = {
    SBN = {
      PUBLIC_LOAD_BALANCER  = { KN = "PUBLIC_LOAD_BALANCER", ABBR = "pub_lb", TERM = "public_load_balancer" },
      PRIVATE_LOAD_BALANCER = { KN = "PRIVATE_LOAD_BALANCER", ABBR = "pri_lb", TERM = "private_load_balancer" },
      PROXY                 = { KN = "PROXY", ABBR = "pxy", TERM = "proxy" },
      FIREWALL              = { KN = "FIREWALL", ABBR = "fw", TERM = "firewall" }, // Firewall는 서브넷 조건이 있어야 겠네.
      SERVICE               = { KN = "SERVICE", ABBR = "svc", TERM = "service" },
      DATA                  = { KN = "DATA", ABBR = "dta", TERM = "data" },
      MANAGEMENT            = { KN = "MANAGEMENT", ABBR = "mgt", TERM = "management" }
    }
  }
}
output "KTRM" {
  value = local.KTRM
}

locals {
  DFN = {
    IAM_PATH_PREFIX = {
      ROLE             = "/tf"
      POLICY           = "/tf"
      INSTANCE_PROFILE = "/tf"
    },

    ARCH = {
      X86_64  = "x86_64"
      AARCH64 = "aarch64"
    },
    TAG = {
      PROJECT = "Project",
      SUBJECT = "Subject",
      SERVICE = "ServiceName",

      ENVIRONMENT = "Environment",
      PHASE       = "Phase",

      MANAGED_BY_ACCOUNT = "ManagedByAccount",

      AZ           = "AZ",
      AZ_GROUP_IDX = "AZGroupIdx"

      NAME            = "Name"
      INDEX           = "Index",
      TARGET_RESOURCE = "TargetResource"
      SBN_TYPE        = "SubnetType"
      SG_TYPE         = "SecurityGroupType"
      MAP             = "map-migrated"

      ARCH = "Architecture",
      OS   = "OS",
    },
    CIDR_BLOCKS = {
      ANY      = ["0.0.0.0/0"]
      INTERNAL = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    },
    ENV_PHASE_MAPPING_TABLE = {
      "${local.TRM.ENV.DEVELOPMENT.ABBR}" = [
        local.TRM.PHASE.DEV,
        local.TRM.PHASE.QA,
        local.TRM.PHASE.DEVELOPMENT_COMMON
      ],
      "${local.TRM.ENV.PRODUCTION.ABBR}" = [
        local.TRM.PHASE.STG,
        local.TRM.PHASE.PRD,
        local.TRM.PHASE.PRODUCTION_COMMON
      ]
    }
  }
}
output "DFN" {
  value = local.DFN
}