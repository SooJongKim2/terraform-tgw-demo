data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = [
    data.aws_availability_zones.available.names[0],  # 첫 번째
    data.aws_availability_zones.available.names[2]   # 세 번째
  ]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(local.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-public${count.index + 1}-${element(local.azs, count.index)}"
    Tier = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(local.azs, count.index)

  tags = {
    Name = "${var.name}-subnet-private${count.index + 1}-${element(local.azs, count.index)}"
    Tier = "Private"
  }
}

# Isolated Subnets
resource "aws_subnet" "isolated" {
  count             = length(var.isolated_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.isolated_subnet_cidrs[count.index]
  availability_zone = element(local.azs, count.index)

  tags = {
    Name = "${var.name}-subnet-isolated${count.index + 1}-${element(local.azs, count.index)}"
    Tier = "Isolated"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs) # 한 AZ에 NAT 1개씩
  domain  = "vpc"
  tags = {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_cidrs)
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = {
    Name = "${var.name}-nat-gw-${count.index + 1}"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private-rt-${count.index + 1}"
  }
}


resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

