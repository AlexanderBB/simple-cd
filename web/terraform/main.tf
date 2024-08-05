variable "region" {
  description = "The deployment region for the infrastructure"
  type        = string
}

variable "vpc_id" {
  description = "The destination VPC for the EC2 deployment"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "deployment_role" {
  description = "The role that will deploy the infrastructure"
  type        = string
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.deployment_role
  }
}

terraform {
  backend "s3" {
    encrypt = true
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_security_group" "web_server_sg" {
  name        = "web_server_sg"
  description = "Web Server SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.202.216.48/29"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  user_data              = file("${path.module}/templates/user-data.sh")

  tags = {
    Name = "Web Server"
  }

  depends_on = [aws_security_group.web_server_sg]
}

output "web_address" {
  value = "http://${aws_instance.web_server.public_dns}"
}
