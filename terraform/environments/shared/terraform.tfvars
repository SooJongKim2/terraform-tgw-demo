account_id = "084828604478"
environment = "shared"
name        = "demo"
aws_region  = "ap-northeast-2"

vpc_cidr    = "10.100.0.0/16"

public_subnet_cidrs = [
  "10.100.1.0/24",
  "10.100.2.0/24"
]

private_subnet_cidrs = [
  "10.100.3.0/24",
  "10.100.4.0/24"
]

isolated_subnet_cidrs = [
  "10.100.5.0/24",
  "10.100.6.0/24"
]