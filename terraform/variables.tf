variable "aws_region" {
  description = "AWS region for TSP Production Environment resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_skip_credential_checks" {
  description = "Skip AWS credential validation for offline plan review only. Must be false for terraform apply."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment name (e.g. production)."
  type        = string
  default     = "production"
}

variable "service_name" {
  description = "TSP production service name prefix for compute resources."
  type        = string
  default     = "tsp-production"
}

variable "compute_platform" {
  description = "Production compute target: ec2 (broke-mode default) or apprunner (requires IAM + App Runner subscription)."
  type        = string
  default     = "ec2"

  validation {
    condition     = contains(["ec2", "apprunner"], var.compute_platform)
    error_message = "compute_platform must be ec2 or apprunner."
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type. Use x86_64 types (t3.micro, t2.micro) for amd64 container image."
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_ssm_parameter" {
  description = "SSM parameter for Amazon Linux 2023 x86_64 AMI (used when compute_platform = ec2)."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "ec2_image_source" {
  description = "Container image source for EC2 user_data: docker_hub (no IAM profile) or ecr (requires instance profile — not implemented)."
  type        = string
  default     = "docker_hub"

  validation {
    condition     = contains(["docker_hub", "ecr"], var.ec2_image_source)
    error_message = "ec2_image_source must be docker_hub or ecr."
  }
}

variable "ec2_host_port" {
  description = "Host port exposed on the EC2 instance (maps to application_port in container)."
  type        = number
  default     = 80
}

variable "ec2_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the EC2 host port."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ec2_root_volume_gb" {
  description = "Root EBS volume size in GB for the EC2 instance."
  type        = number
  default     = 8
}

variable "docker_hub_image" {
  description = "Source Docker Hub repository for pre-apply image mirroring (ACI-004 validated image)."
  type        = string
  default     = "taig2k/taig_service_portal_tsp"
}

variable "docker_image_tag" {
  description = "Container image tag. Validated tag from ACI-004: deployable."
  type        = string
  default     = "deployable"
}

variable "ecr_repository_name" {
  description = "ECR repository name for the TSP production image."
  type        = string
  default     = "taig-service-portal-tsp"
}

variable "ecr_force_delete" {
  description = "Allow ECR repository deletion even when images exist (useful for PE test teardown)."
  type        = bool
  default     = true
}

variable "ecr_scan_on_push" {
  description = "Enable basic image scanning on push to ECR."
  type        = bool
  default     = true
}

variable "image_repository_type" {
  description = "App Runner image repository type. ECR is required for private ECR deployment."
  type        = string
  default     = "ECR"

  validation {
    condition     = contains(["ECR", "ECR_PUBLIC"], var.image_repository_type)
    error_message = "image_repository_type must be ECR or ECR_PUBLIC."
  }
}

variable "application_port" {
  description = "Port the TSP application listens on inside the container."
  type        = number
  default     = 3000
}

variable "auto_deployments_enabled" {
  description = "Whether App Runner automatically deploys when the image changes."
  type        = bool
  default     = false
}

variable "cpu" {
  description = "App Runner instance CPU units."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "App Runner instance memory (MiB)."
  type        = string
  default     = "512"
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per App Runner instance."
  type        = number
  default     = 100
}

variable "min_size" {
  description = "Minimum number of App Runner instances."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of App Runner instances."
  type        = number
  default     = 3
}

variable "health_check_path" {
  description = "HTTP path used for App Runner health checks."
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Seconds between App Runner health checks."
  type        = number
  default     = 10
}

variable "health_check_timeout" {
  description = "Seconds before an App Runner health check times out."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Consecutive successful health checks before healthy."
  type        = number
  default     = 1
}

variable "health_check_unhealthy_threshold" {
  description = "Consecutive failed health checks before unhealthy."
  type        = number
  default     = 3
}

variable "runtime_environment_variables" {
  description = "Additional runtime environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
