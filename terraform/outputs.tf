output "planned_service_name" {
  description = "Planned production service name."
  value       = var.service_name
}

output "planned_region" {
  description = "Planned AWS region for the Production Environment."
  value       = var.aws_region
}

output "compute_platform" {
  description = "Selected compute platform for PE (ec2 or apprunner)."
  value       = var.compute_platform
}

output "planned_image" {
  description = "Planned ECR container image identifier (repository:tag)."
  value       = local.image_identifier
}

output "docker_hub_source_image" {
  description = "Docker Hub source image (used for EC2 broke-mode and optional ECR mirroring)."
  value       = local.docker_hub_source_image
}

output "ec2_container_image" {
  description = "Container image used by EC2 user_data when compute_platform = ec2."
  value       = var.compute_platform == "ec2" ? local.ec2_container_image : null
}

output "ecr_repository_url" {
  description = "ECR repository URL for image mirroring and deployment."
  value       = aws_ecr_repository.tsp.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN."
  value       = aws_ecr_repository.tsp.arn
}

output "future_service_url" {
  description = "Production service URL. Populated after terraform apply."
  value = var.compute_platform == "ec2" ? (
    length(aws_instance.tsp) > 0 ? "http://${aws_instance.tsp[0].public_ip}:${var.ec2_host_port}" : null
    ) : (
    length(aws_apprunner_service.tsp) > 0 ? aws_apprunner_service.tsp[0].service_url : null
  )
}

output "ec2_instance_id" {
  description = "EC2 instance ID when compute_platform = ec2."
  value       = var.compute_platform == "ec2" && length(aws_instance.tsp) > 0 ? aws_instance.tsp[0].id : null
}

output "ec2_public_ip" {
  description = "EC2 public IP when compute_platform = ec2."
  value       = var.compute_platform == "ec2" && length(aws_instance.tsp) > 0 ? aws_instance.tsp[0].public_ip : null
}

output "apprunner_service_arn" {
  description = "App Runner service ARN when compute_platform = apprunner."
  value       = var.compute_platform == "apprunner" && length(aws_apprunner_service.tsp) > 0 ? aws_apprunner_service.tsp[0].arn : null
}

output "apprunner_service_id" {
  description = "App Runner service ID when compute_platform = apprunner."
  value       = var.compute_platform == "apprunner" && length(aws_apprunner_service.tsp) > 0 ? aws_apprunner_service.tsp[0].id : null
}

output "apprunner_access_role_arn" {
  description = "IAM role ARN used by App Runner to access the container registry."
  value       = var.compute_platform == "apprunner" && length(aws_iam_role.apprunner_access) > 0 ? aws_iam_role.apprunner_access[0].arn : null
}

output "apprunner_instance_role_arn" {
  description = "IAM role ARN assumed by running App Runner tasks."
  value       = var.compute_platform == "apprunner" && length(aws_iam_role.apprunner_instance) > 0 ? aws_iam_role.apprunner_instance[0].arn : null
}

output "auto_scaling_configuration_arn" {
  description = "App Runner auto scaling configuration ARN."
  value       = var.compute_platform == "apprunner" && length(aws_apprunner_auto_scaling_configuration_version.tsp) > 0 ? aws_apprunner_auto_scaling_configuration_version.tsp[0].arn : null
}
