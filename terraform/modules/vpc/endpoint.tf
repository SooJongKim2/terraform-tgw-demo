
resource "aws_security_group" "ec2_connect_endpoint_sg" {
  name_prefix = "${var.name}-ec2-connect-endpoint-sg-"
  description = "Security group for EC2 Instance Connect endpoint"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC"
  }

  tags = {
    Name = "${var.name}-ec2-connect-endpoint-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = aws_subnet.private[0].id
  security_group_ids = [aws_security_group.ec2_connect_endpoint_sg.id]

  preserve_client_ip = false

  tags = {
    Name = "${var.name}-ec2-connect-endpoint"
  }
}

