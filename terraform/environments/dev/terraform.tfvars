account_id = "011528264969"
environment = "dev"
name        = "demo"
aws_region  = "ap-northeast-2"

vpc_cidr    = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

isolated_subnet_cidrs = [
  "10.0.5.0/24",
  "10.0.6.0/24"
]