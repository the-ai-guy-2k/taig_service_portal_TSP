# App Runner compute path (paused by default; requires IAM roles + App Runner subscription).
# Enable with compute_platform = "apprunner".

resource "aws_iam_role" "apprunner_access" {
  count = var.compute_platform == "apprunner" ? 1 : 0
  name  = "${var.service_name}-apprunner-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_access_ecr" {
  count      = var.compute_platform == "apprunner" ? 1 : 0
  role       = aws_iam_role.apprunner_access[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role" "apprunner_instance" {
  count = var.compute_platform == "apprunner" ? 1 : 0
  name  = "${var.service_name}-apprunner-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_apprunner_auto_scaling_configuration_version" "tsp" {
  count                           = var.compute_platform == "apprunner" ? 1 : 0
  auto_scaling_configuration_name = "${var.service_name}-autoscaling"
  max_concurrency                 = var.max_concurrency
  max_size                        = var.max_size
  min_size                        = var.min_size

  tags = var.tags
}

resource "aws_apprunner_service" "tsp" {
  count        = var.compute_platform == "apprunner" ? 1 : 0
  service_name = var.service_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access[0].arn
    }

    auto_deployments_enabled = var.auto_deployments_enabled

    image_repository {
      image_identifier      = local.image_identifier
      image_repository_type = var.image_repository_type

      image_configuration {
        port = tostring(var.application_port)

        runtime_environment_variables = merge(
          {
            NODE_ENV = "production"
            PORT     = tostring(var.application_port)
          },
          var.runtime_environment_variables
        )
      }
    }
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.apprunner_instance[0].arn
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.tsp[0].arn

  tags = var.tags
}
