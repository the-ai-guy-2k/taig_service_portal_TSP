# TSP Production Environment — Creation Report

**ACI:** ACI-PE-004  
**Date:** 2026-06-22  
**Status:** **PARTIAL** — ECR and image mirror complete; App Runner stack blocked by IAM and service subscription

---

## Executive Summary

ACI-PE-004 executed the first real AWS resource creation for TSP PE. Terraform plan matched expectations (6 to add). Staged ECR apply and Docker Hub → ECR mirror succeeded. Full `terraform apply` **failed** on IAM role creation (`iam:CreateRole` denied) and App Runner auto-scaling (`SubscriptionRequiredException`). Only **1 of 6** planned resources exists in Terraform state.

**Next step:** Resolve AWS permissions and App Runner account subscription, then re-run `terraform apply`.

---

## 1. AWS Identity Confirmation

**Profile:** `nebula` (operator-provided; not committed)

| Field | Value |
|-------|-------|
| Account | `526123657916` |
| Arn | `arn:aws:iam::526123657916:user/nebula` |
| UserId | `AIDAXU73J5K6MACIMBRO2` |

Access keys and secret values were **not** recorded or committed.

---

## 2. Terraform Variables

Created from `terraform.tfvars.example` → `terraform/terraform.tfvars` (gitignored).

| Variable | Value |
|----------|-------|
| `aws_region` | `us-east-1` |
| `service_name` | `tsp-production` |
| `docker_hub_image` | `taig2k/taig_service_portal_tsp` |
| `docker_image_tag` | `deployable` |
| `application_port` | `3000` |
| `environment` | `production` |

---

## 3. Terraform Plan Result

**Command:** `terraform plan -var-file=terraform.tfvars`

| Metric | Result |
|--------|--------|
| Plan | **6 to add, 0 to change, 0 to destroy** |
| Match to baseline | **Yes** |

Planned resources:

1. `aws_ecr_repository.tsp`
2. `aws_iam_role.apprunner_access`
3. `aws_iam_role_policy_attachment.apprunner_access_ecr`
4. `aws_iam_role.apprunner_instance`
5. `aws_apprunner_auto_scaling_configuration_version.tsp`
6. `aws_apprunner_service.tsp`

Plan output saved locally as `terraform/plan-output-pe004.txt` (gitignored).

---

## 4. Staged Apply — ECR

**Command:** `terraform apply -target=aws_ecr_repository.tsp -var-file=terraform.tfvars -auto-approve`

| Result | Detail |
|--------|--------|
| Status | **Success** |
| Resources added | 1 |
| Repository name | `taig-service-portal-tsp` |
| Repository URL | `526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp` |
| ARN | `arn:aws:ecr:us-east-1:526123657916:repository/taig-service-portal-tsp` |

---

## 5. ECR Image Mirror

**Script:** `scripts/mirror-image-to-ecr.ps1`

| Field | Value |
|-------|-------|
| Source | `taig2k/taig_service_portal_tsp:deployable` |
| Target | `526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp:deployable` |
| Mirror status | **Success** |
| Digest | `sha256:936c01ab146dfa86b2f95e0e4b54878eab667297e00526c25813a953f64b5dd0` |
| Pushed at | `2026-06-22T23:32:08-04:00` |

**Validation:** `aws ecr describe-images --image-ids imageTag=deployable` confirmed tag and digest in ECR.

---

## 6. Full Terraform Apply Result

**Command:** `terraform apply -var-file=terraform.tfvars -auto-approve`

| Result | Detail |
|--------|--------|
| Status | **Failed** (partial) |
| Resources in state after apply | 1 (`aws_ecr_repository.tsp` only) |

### Errors

**IAM — `aws_iam_role.apprunner_access` and `aws_iam_role.apprunner_instance`**

```
AccessDenied: User arn:aws:iam::526123657916:user/nebula is not authorized to perform: iam:CreateRole
```

**App Runner — `aws_apprunner_auto_scaling_configuration_version.tsp`**

```
SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service
```

### Remediation required

1. Grant the deploy principal (`nebula` or a dedicated Terraform role) permissions including:
   - `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PassRole`, `iam:GetRole`, `iam:TagRole`
   - `apprunner:*` (or scoped App Runner create/manage actions)
2. Ensure **AWS App Runner** is enabled/subscribed for account `526123657916` (first-time use may require console opt-in or account activation).
3. Re-run: `terraform apply -var-file=terraform.tfvars`

No manual AWS resource creation was performed outside Terraform except the documented mirror script (Docker pull/tag/push to existing ECR repo).

---

## 7. Resources Created

| Resource | Status |
|----------|--------|
| ECR repository `taig-service-portal-tsp` | **Created** |
| ECR image `deployable` | **Present** |
| IAM role `tsp-production-apprunner-access` | **Not created** |
| IAM policy attachment (ECR access) | **Not created** |
| IAM role `tsp-production-apprunner-instance` | **Not created** |
| App Runner auto scaling `tsp-production-autoscaling` | **Not created** |
| App Runner service `tsp-production` | **Not created** |

---

## 8. Terraform Outputs (current state)

```
docker_hub_source_image = "taig2k/taig_service_portal_tsp:deployable"
ecr_repository_arn      = "arn:aws:ecr:us-east-1:526123657916:repository/taig-service-portal-tsp"
ecr_repository_url      = "526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp"
planned_image           = "526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp:deployable"
planned_region          = "us-east-1"
planned_service_name    = "tsp-production"
```

App Runner URL and service ARN outputs are **not available** until full apply succeeds.

---

## 9. Cost Notes

| Component | Estimate | Current billing impact |
|-----------|----------|------------------------|
| ECR storage | ~$0.10/GB-month | Minimal (single small image) |
| ECR data transfer | Low for mirror | One-time push completed |
| App Runner | ~$7–$15/month (256 CPU / 512 MB, 1–2 instances) | **$0** — service not created |
| IAM | No charge | N/A |

**Current monthly run rate:** ECR-only (~under $1 until App Runner is deployed).

---

## 10. Risks

| Risk | Severity | Notes |
|------|----------|-------|
| Deploy principal lacks IAM permissions | **High** | Blocks App Runner stack |
| App Runner not subscribed on account | **High** | `SubscriptionRequiredException` |
| Partial state (ECR only) | Medium | Safe to re-apply; no orphan App Runner resources |
| Local Terraform state | Medium | Backup `terraform.tfstate` before next apply |
| Public App Runner URL (when created) | Low | Expected for MVP; no custom domain yet |

---

## 11. Readiness for ACI-PE-005

**Not ready.** PE validation (smoke tests against live App Runner URL) requires:

1. IAM permissions fix for Terraform deploy principal
2. App Runner service subscription/activation on the account
3. Successful full `terraform apply`
4. Captured `apprunner_service_url` output and smoke test pass

---

## 12. Secrets and Git Hygiene

The following were **not** committed:

- `terraform/terraform.tfvars`
- `terraform/terraform.tfstate`
- `terraform/.terraform/`
- AWS credentials
- `terraform/plan-output-pe004.txt`
