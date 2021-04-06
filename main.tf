#*************
#*** Config **
#*************

terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

#********************
#*** IAM Resources **
#********************

resource "aws_iam_role" "docker_base" {
  name = "docker_base"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    project = var.project
  }
}

resource "aws_iam_instance_profile" "docker_base" {
  name = "docker_base"
  role = aws_iam_role.docker_base.name
}

resource "aws_iam_role_policy" "allow_ecr_access" {
  name = "allow_ecr_access"
  role = aws_iam_role.docker_base.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

#*******************************
#*** Security Group Resources **
#*******************************

module "dev_ssh_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2_sg"
  description = "Security group for ec2_sg"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["10.0.0.0/16"]
  ingress_rules       = ["ssh-tcp"]
}

module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2_sg"
  description = "Security group for ec2_sg"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

#***************
#*** Instance **
#***************

resource "aws_instance" "docker-base" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  root_block_device {
    volume_size = 40
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo curl -L https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    sudo docker run --name nginx1 -p 80:80 -d nginx
  EOF

  vpc_security_group_ids = [
    module.ec2_sg.this_security_group_id,
    module.dev_ssh_sg.this_security_group_id
  ]
  iam_instance_profile = aws_iam_instance_profile.docker_base.name

  tags = {
    project     = var.project
    environment = var.env
    contact     = var.contact
  }

  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = true
}
