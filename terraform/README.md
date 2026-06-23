# TSP Production Environment — Terraform

Terraform definitions for the TAIG Service Portal (TSP) **Production Environment** on AWS.

**Status:** EC2 broke-mode pivot drafted (ACI-PE-004B) — App Runner gated; ready for EC2 apply ACI.

## Purpose

This directory defines the TSP Production Environment as code:

- **Target cloud:** AWS (`us-east-1`)
- **Compute (default):** EC2 + Docker (`compute_platform = "ec2"`, t3.micro)
- **Compute (optional):** App Runner (`compute_platform = "apprunner"` — requires IAM + subscription)
- **Container image:** `taig2k/taig_service_portal_tsp:deployable` (validated in ACI-004)
- **Health check:** `GET /health` on port `3000` (exposed on host port `80` for EC2)

## Terraform Structure

```
terraform/
├── main.tf                  # Provider, ECR repository
├── ec2.tf                   # Broke-mode EC2 + security group (default path)
├── apprunner.tf             # App Runner path (gated by compute_platform)
├── variables.tf             # Input variables
├── outputs.tf               # Planned and post-apply outputs
├── templates/ec2-user-data.sh.tpl
├── iam/tsp-pe-deploy-policy.json
├── terraform.tfvars.example
└── .gitignore
```

### Resources — EC2 path (default, `compute_platform = "ec2"`)

| Resource | Purpose |
|----------|---------|
| `aws_ecr_repository.tsp` | Optional mirror target (exists from PE-004) |
| `aws_security_group.tsp_ec2` | HTTP ingress on port 80 |
| `aws_instance.tsp` | AL2023 host; Docker runs TSP image |

See [PE_architecture_pivot_review.md](../docs/reports/PE_architecture_pivot_review.md) for pivot rationale.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `environment` | `production` | Environment name |
| `service_name` | `tsp-production` | App Runner service name |
| `docker_image` | `taig2k/taig_service_portal_tsp` | Container repository |
| `docker_image_tag` | `deployable` | Container tag |
| `image_repository_type` | `ECR` | `ECR` or `ECR_PUBLIC` |
| `application_port` | `3000` | Application listen port |
| `auto_deployments_enabled` | `false` | Auto-deploy on image change |
| `cpu` | `256` | Instance CPU |
| `memory` | `512` | Instance memory (MiB) |
| `max_concurrency` | `100` | Max concurrent requests per instance |
| `min_size` / `max_size` | `1` / `3` | Instance scaling bounds |
| `health_check_path` | `/health` | Health check path |
| `runtime_environment_variables` | `{}` | Extra container env vars |
| `tags` | `{}` | Additional resource tags |

See `variables.tf` for health check tuning variables.

### Docker Hub note

App Runner natively supports **Amazon ECR** and **ECR Public**. The validated TSP image is published to **Docker Hub**. Before `terraform apply`, either:

1. Mirror `taig2k/taig_service_portal_tsp:deployable` to an ECR repository and update `docker_image`, or
2. Confirm an approved registry integration path in ACI-PE-002

## Outputs

| Output | When available |
|--------|----------------|
| `planned_service_name` | Always (from variables) |
| `planned_region` | Always (from variables) |
| `planned_image` | Always (computed from variables) |
| `future_service_url` | After `terraform apply` |
| `apprunner_service_arn` | After `terraform apply` |
| `apprunner_service_id` | After `terraform apply` |
| `apprunner_access_role_arn` | After `terraform apply` |
| `apprunner_instance_role_arn` | After `terraform apply` |
| `auto_scaling_configuration_arn` | After `terraform apply` |

## Plan Instructions

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- AWS credentials configured (for plan only — read-only IAM recommended)
- No `terraform apply` in ACI-PE-001

### Commands

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars as needed

terraform init
terraform validate
terraform plan
```

`terraform plan` shows resources that **would** be created. Review output in ACI-PE-002 before applying.

### Plan review (ACI-PE-002)

```bash
cd terraform
terraform plan -var-file=terraform.tfvars.plan-review
```

See [PE_plan_review.md](../docs/reports/PE_plan_review.md) for full assessment.

`terraform.tfvars.plan-review` enables offline structural plan review (`aws_skip_credential_checks = true`). **Do not use for apply.**

### Pre-apply preparation (ACI-PE-003)

See [PE_pre_apply_review.md](../docs/reports/PE_pre_apply_review.md).

**Image source:** ECR (private). Mirror Docker Hub image before App Runner deployment:

```powershell
# After ECR repository exists (terraform apply -target=aws_ecr_repository.tsp)
.\scripts\mirror-image-to-ecr.ps1
```

**State handling (PE Phase 1):** Local `terraform.tfstate` in `terraform/`. Remote S3 backend deferred — see `backend.tf.example`.

**Real credential plan:**

```bash
aws sts get-caller-identity
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform plan -var-file=terraform.tfvars
```

### Validation only (no AWS credentials required)

```bash
cd terraform
terraform init -backend=false
terraform validate
```

## Apply Instructions

> Apply belongs to a post-PE-003 ACI after pre-apply review approval.

**Recommended apply sequence:**

```bash
# 1. Create ECR repository only
terraform apply -target=aws_ecr_repository.tsp

# 2. Mirror Docker Hub image to ECR
..\scripts\mirror-image-to-ecr.ps1

# 3. Full apply (remaining resources)
terraform plan -out=tfplan
terraform apply tfplan
```

After apply:

```bash
terraform output future_service_url
node ../scripts/smoke-test.js "$(terraform output -raw future_service_url)"
```

## Rollback Notes

| Scenario | Action |
|----------|--------|
| Plan rejected | Do not apply; adjust `.tf` files and re-plan |
| Bad apply | `terraform destroy` (later ACI only, with approval) |
| Image rollback | Redeploy prior image tag via App Runner or update `docker_image_tag` and re-apply |
| State corruption | Restore state from remote backend (configure in ACI-PE-002) |

Always tag App Runner revisions and keep Docker image SHA tags (`sha-<commit>`) for rollback.

## GitHub Actions Recommendations

Terraform deployment automation is **not implemented** in ACI-PE-001. Recommended for a future ACI:

| Step | Recommendation |
|------|----------------|
| **terraform fmt** | Run on PR; fail if formatting differs |
| **terraform validate** | Run on PR after `terraform init -backend=false` |
| **tflint** | Optional static analysis for AWS best practices |
| **terraform plan** | Run on PR to `deployable` with read-only AWS credentials; post plan as comment |
| **terraform apply** | Manual approval gate on `deployable` only; use remote state (S3 + DynamoDB lock) |
| **Secrets** | Store AWS credentials in GitHub Secrets; never commit `terraform.tfvars` |

Suggested workflow file (future): `.github/workflows/terraform.yml`

```yaml
# Future reference — not active
on:
  pull_request:
    paths: ['terraform/**']
  push:
    branches: [deployable]
    paths: ['terraform/**']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init -backend=false
        working-directory: terraform
      - run: terraform fmt -check
        working-directory: terraform
      - run: terraform validate
        working-directory: terraform
```

Do **not** add `terraform apply` until remote state, IAM least-privilege, and plan review process are established.

## Related Documents

- [../docs/reports/aws_deployment_guide.md](../docs/reports/aws_deployment_guide.md)
- [../docs/reports/deployment_runbook.md](../docs/reports/deployment_runbook.md)
- [../docs/reports/PA_validation_report.md](../docs/reports/PA_validation_report.md)
