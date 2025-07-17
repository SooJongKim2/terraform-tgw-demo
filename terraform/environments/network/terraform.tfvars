account_id = "024848465231"
environment = "network"
name        = "demo"
aws_region  = "ap-northeast-2"
member_account_ids = [
  "084828604478",
  "011528264969"
]
internal_cidr_block = "10.0.0.0/8"

vpc_cidr    = "10.200.0.0/16"

public_subnet_cidrs = [
  "10.200.1.0/24",
  "10.200.2.0/24"
]

private_subnet_cidrs = [
  "10.200.3.0/24",
  "10.200.4.0/24"
]

isolated_subnet_cidrs = [
  "10.200.5.0/24",
  "10.200.6.0/24"
]