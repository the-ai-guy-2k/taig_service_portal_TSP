# Mirrors the validated Docker Hub image to the Terraform-managed ECR repository.
# Run AFTER: terraform apply -target=aws_ecr_repository.tsp (or full apply creating ECR first)
# Requires: AWS CLI, Docker, and credentials with ECR push access

param(
  [string]$Region = "us-east-1",
  [string]$EcrRepositoryName = "taig-service-portal-tsp",
  [string]$DockerHubImage = "taig2k/taig_service_portal_tsp",
  [string]$Tag = "deployable"
)

$ErrorActionPreference = "Stop"

$accountId = (aws sts get-caller-identity --query Account --output text)
$ecrUri = "${accountId}.dkr.ecr.${Region}.amazonaws.com/${EcrRepositoryName}"
$sourceImage = "${DockerHubImage}:${Tag}"
$targetImage = "${ecrUri}:${Tag}"

Write-Host "Source: $sourceImage"
Write-Host "Target: $targetImage"

aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "${accountId}.dkr.ecr.${Region}.amazonaws.com"

docker pull $sourceImage
docker tag $sourceImage $targetImage
docker push $targetImage

Write-Host "Mirror complete: $targetImage"
