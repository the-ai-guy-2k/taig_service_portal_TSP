terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  skip_credentials_validation = var.aws_skip_credential_checks
  skip_requesting_account_id  = var.aws_skip_credential_checks
  skip_metadata_api_check     = var.aws_skip_credential_checks

  default_tags {
    tags = merge(
      {
        Project     = "taig-service-portal"
        Environment = var.environment
        ManagedBy   = "terraform"
      },
      var.tags
    )
  }
}

locals {
  docker_hub_source_image = "${var.docker_hub_image}:${var.docker_image_tag}"
  image_identifier        = "${aws_ecr_repository.tsp.repository_url}:${var.docker_image_tag}"
}

# ECR repository retained from PE-004 (optional mirror target; not required for EC2 Docker Hub path).
resource "aws_ecr_repository" "tsp" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = var.tags
}
