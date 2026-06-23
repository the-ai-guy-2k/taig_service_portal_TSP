output "planned_service_name" {
  description = "Planned App Runner service name."
  value       = var.service_name
}

output "planned_region" {
  description = "Planned AWS region for the Production Environment."
  value       = var.aws_region
}

output "planned_image" {
  description = "Planned container image identifier (repository:tag)."
  value       = local.image_identifier
}

output "future_service_url" {
  description = "App Runner service URL. Populated after terraform apply."
  value       = aws_apprunner_service.tsp.service_url
}

output "apprunner_service_arn" {
  description = "App Runner service ARN. Populated after terraform apply."
  value       = aws_apprunner_service.tsp.arn
}

output "apprunner_service_id" {
  description = "App Runner service ID. Populated after terraform apply."
  value       = aws_apprunner_service.tsp.id
}

output "apprunner_access_role_arn" {
  description = "IAM role ARN used by App Runner to access the container registry."
  value       = aws_iam_role.apprunner_access.arn
}

output "apprunner_instance_role_arn" {
  description = "IAM role ARN assumed by running App Runner tasks."
  value       = aws_iam_role.apprunner_instance.arn
}

output "auto_scaling_configuration_arn" {
  description = "App Runner auto scaling configuration ARN."
  value       = aws_apprunner_auto_scaling_configuration_version.tsp.arn
}
