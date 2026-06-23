# ACI-PE-004 Completion Report — PE Creation

**ACI:** ACI-PE-004  
**Title:** PE Creation  
**Status:** **BLOCKED** (partial completion — ECR phase done)  
**Date:** 2026-06-22

---

## 1. Summary of Work Performed

Configured operator AWS profile `nebula`, created local `terraform.tfvars`, ran real-credential Terraform plan (6 to add), staged ECR apply (success), mirrored validated Docker Hub image to ECR (success), and attempted full Terraform apply. Full apply failed due to IAM `CreateRole` denial and App Runner `SubscriptionRequiredException`. Documented results in `PE_creation_report.md`. No secrets committed.

---

## 2. AWS Credential Confirmation

| Field | Value |
|-------|-------|
| Profile | `nebula` |
| Account | `526123657916` |
| Arn | `arn:aws:iam::526123657916:user/nebula` |

Secrets not printed or stored in repository.

---

## 3. Terraform Plan Result

| Metric | Result |
|--------|--------|
| Command | `terraform plan -var-file=terraform.tfvars` |
| Outcome | **Success** |
| Plan | **6 to add, 0 to change, 0 to destroy** |

Matches ACI-PE-004 baseline expectation.

---

## 4. ECR Apply Result

| Metric | Result |
|--------|--------|
| Command | `terraform apply -target=aws_ecr_repository.tsp` |
| Outcome | **Success** |
| Repository | `taig-service-portal-tsp` |
| URL | `526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp` |

---

## 5. Image Mirror Result

| Metric | Result |
|--------|--------|
| Script | `scripts/mirror-image-to-ecr.ps1` |
| Source | `taig2k/taig_service_portal_tsp:deployable` |
| Target tag | `deployable` |
| Digest | `sha256:936c01ab146dfa86b2f95e0e4b54878eab667297e00526c25813a953f64b5dd0` |
| Outcome | **Success** |

---

## 6. Full Terraform Apply Result

| Metric | Result |
|--------|--------|
| Command | `terraform apply -var-file=terraform.tfvars -auto-approve` |
| Outcome | **Failed** |
| Created in this step | 0 (ECR already in state) |
| Blockers | `iam:CreateRole` AccessDenied; App Runner SubscriptionRequiredException |

---

## 7. Resources Created

| # | Resource | State |
|---|----------|-------|
| 1 | `aws_ecr_repository.tsp` | **In Terraform state / AWS** |
| 2 | `aws_iam_role.apprunner_access` | Not created |
| 3 | `aws_iam_role_policy_attachment.apprunner_access_ecr` | Not created |
| 4 | `aws_iam_role.apprunner_instance` | Not created |
| 5 | `aws_apprunner_auto_scaling_configuration_version.tsp` | Not created |
| 6 | `aws_apprunner_service.tsp` | Not created |

ECR image `deployable` is present in the repository (verified via `describe-images`).

---

## 8. Terraform Outputs

Available now:

```
ecr_repository_arn   = arn:aws:ecr:us-east-1:526123657916:repository/taig-service-portal-tsp
ecr_repository_url   = 526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp
planned_image        = 526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp:deployable
planned_region       = us-east-1
planned_service_name = tsp-production
docker_hub_source_image = taig2k/taig_service_portal_tsp:deployable
```

Pending full apply: `future_service_url`, `apprunner_service_arn`, `apprunner_service_id`, IAM role ARNs, auto-scaling ARN.

---

## 9. Cost Notes

- **Active:** ECR storage for one image (negligible monthly cost).
- **Not yet incurred:** App Runner compute (~$7–$15/month estimated when deployed).

---

## 10. Risks Discovered

| Risk | Impact |
|------|--------|
| `nebula` IAM user cannot `CreateRole` | Full PE stack cannot deploy |
| App Runner subscription not active on account | Auto-scaling and service creation blocked |
| Partial PE state | ECR exists; re-apply is idempotent for remaining 5 resources |

---

## 11. Readiness For ACI-PE-005

**Not ready.** Operator must:

1. Attach IAM policy allowing role creation and App Runner management to deploy principal (or use elevated role).
2. Activate/subscribe AWS App Runner for account `526123657916`.
3. Re-run `terraform apply -var-file=terraform.tfvars` from `terraform/`.
4. Capture App Runner URL and run `node scripts/smoke-test.js <url>`.

Then ACI-PE-005 (PE validation) can proceed.

---

## 12. Commit ID(s)

`9e91586` — ACI-PE-004: Document partial PE creation (ECR complete, App Runner blocked).

---

## PASS / FAIL Assessment

| Criterion | Result |
|-----------|--------|
| AWS credentials confirmed | **PASS** |
| Real Terraform plan succeeds | **PASS** |
| ECR repository created | **PASS** |
| Docker image mirrored to ECR | **PASS** |
| Full Terraform apply succeeds | **FAIL** |
| App Runner service exists | **FAIL** |
| Terraform outputs captured | **PARTIAL** (ECR only) |
| No secrets committed | **PASS** |
| PE creation report exists | **PASS** |
| Completion report exists | **PASS** |

**Overall ACI-PE-004:** **CONDITIONAL FAIL** — resume after IAM and App Runner blockers resolved.
