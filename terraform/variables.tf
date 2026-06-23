variable "aws_region" {
  description = "AWS region for TSP Production Environment resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (e.g. production)."
  type        = string
  default     = "production"
}

variable "service_name" {
  description = "AWS App Runner service name for TSP."
  type        = string
  default     = "tsp-production"
}

variable "docker_image" {
  description = "Container image repository. Validated image: taig2k/taig_service_portal_tsp. May require ECR mirror before apply (see terraform/README.md)."
  type        = string
  default     = "taig2k/taig_service_portal_tsp"
}

variable "docker_image_tag" {
  description = "Container image tag. Validated tag from ACI-004: deployable."
  type        = string
  default     = "deployable"
}

variable "image_repository_type" {
  description = "App Runner image repository type. Valid values: ECR, ECR_PUBLIC. Docker Hub images may require mirroring to ECR before apply."
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
