variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}



variable "associate_public_ip" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "SSH 허용할 CIDR 리스트"
}


variable "source_sg_id" {
  type        = string
  description = "SSH 접속 허용할 소스 보안그룹 ID"
  default     = null
}
