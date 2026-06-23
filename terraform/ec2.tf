# Broke-mode EC2 + Docker compute path (default). No IAM instance profile required for Docker Hub.

data "aws_vpc" "default" {
  count   = var.compute_platform == "ec2" ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.compute_platform == "ec2" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_subnet" "default" {
  count = var.compute_platform == "ec2" ? 1 : 0
  id    = data.aws_subnets.default[0].ids[0]
}

data "aws_ssm_parameter" "al2023_ami" {
  count = var.compute_platform == "ec2" ? 1 : 0
  name  = var.ec2_ami_ssm_parameter
}

locals {
  ec2_container_image = var.ec2_image_source == "docker_hub" ? local.docker_hub_source_image : local.image_identifier
}

resource "aws_security_group" "tsp_ec2" {
  count       = var.compute_platform == "ec2" ? 1 : 0
  name        = "${var.service_name}-ec2"
  description = "TSP broke-mode EC2 HTTP access"
  vpc_id      = data.aws_vpc.default[0].id

  ingress {
    description = "HTTP to TSP container"
    from_port   = var.ec2_host_port
    to_port     = var.ec2_host_port
    protocol    = "tcp"
    cidr_blocks = var.ec2_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.service_name}-ec2"
  })
}

resource "aws_instance" "tsp" {
  count                       = var.compute_platform == "ec2" ? 1 : 0
  ami                         = data.aws_ssm_parameter.al2023_ami[0].value
  instance_type               = var.ec2_instance_type
  subnet_id                   = data.aws_subnet.default[0].id
  vpc_security_group_ids      = [aws_security_group.tsp_ec2[0].id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/ec2-user-data.sh.tpl", {
    container_image = local.ec2_container_image
    container_port  = var.application_port
    host_port       = var.ec2_host_port
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  root_block_device {
    volume_size = var.ec2_root_volume_gb
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = var.service_name
  })
}
