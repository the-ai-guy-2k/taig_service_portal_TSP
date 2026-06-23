# TSP Production Environment — Pre-Apply Review

**ACI:** ACI-PE-003  
**Date:** 2026-06-22  
**Status:** Ready for apply authorization (pending operator AWS credentials)

---

## Executive Summary

ACI-PE-002 blockers have been addressed in Terraform configuration and documentation. Image source is resolved via **ECR mirror**. State handling is **local** for PE Phase 1. Structural plan confirms **6 resources to add**. Real-credential `terraform plan` requires operator AWS configuration before apply ACI.

**Apply recommendation:** **APPROVE FOR APPLY** after operator runs real-credential plan and confirms identity.

---

## 1. Image Source Decision

### Decision: **Option B — Amazon ECR (private)**

| Aspect | Detail |
|--------|--------|
| **Rationale** | App Runner Terraform configuration requires `image_repository_type = ECR` for private registry deployment |
| **Docker Hub** | Remains source of truth for validated image (`taig2k/taig_service_portal_tsp:deployable`) |
| **ECR repository** | `taig-service-portal-tsp` (created by Terraform) |
| **App Runner image** | `<account>.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp:deployable` |

### Mirroring workflow

1. `terraform apply -target=aws_ecr_repository.tsp` (creates empty ECR repo)
2. Run `scripts/mirror-image-to-ecr.ps1` (pull from Docker Hub, push to ECR)
3. Full `terraform apply` (creates App Runner + IAM + scaling)

**Docker Hub direct deploy:** Not supported with current App Runner Terraform provider constraints.

---

## 2. AWS Credential Validation

**Command:** `aws sts get-caller-identity`

| Check | Result (ACI-PE-003 session) |
|-------|----------------------------|
| AWS CLI installed | Yes (`aws-cli/2.34.57`) |
| Stale PE-002 dummy creds cleared | Yes |
| Valid operator credentials | **Not configured** (`Unable to locate credentials`) |

### Operator action required

Configure credentials before real-credential plan or apply:

```bash
aws configure
# OR
aws login
```

Then verify (capture only non-secret fields):

```bash
aws sts get-caller-identity
# Record: Account, Arn, UserId — NOT access keys
```

**No credentials were committed, printed, or stored in Terraform files.**

---

## 3. State Handling Decision

### Decision: **Option A — Local state (PE Phase 1)**

| Aspect | Detail |
|--------|--------|
| **State file** | `terraform/terraform.tfstate` (gitignored) |
| **Rationale** | Acceptable for one-day PE test; minimal cost and complexity |
| **Remote state** | Deferred — template in `terraform/backend.tf.example` |
| **Promotion path** | Migrate to S3 + DynamoDB after PE is proven |

---

## 4. Terraform Configuration Updates

| Change | Purpose |
|--------|---------|
| Added `aws_ecr_repository.tsp` | Private ECR for App Runner image |
| `image_identifier` → ECR URL | Resolves PE-002 Docker Hub / ECR mismatch |
| `docker_hub_image` variable | Documents mirror source |
| `max_size` default → 2 in tfvars.example | Broke-mode cost alignment |
| `backend.tf.example` | Future remote state template |
| `scripts/mirror-image-to-ecr.ps1` | Image mirroring automation |

**Not added:** VPC, NAT, ALB, RDS, multi-AZ, enterprise monitoring.

---

## 5. Terraform Plan Results

### Structural plan (offline, validated config)

**Command:** `terraform plan -var-file=terraform.tfvars.plan-review`  
**Result:** `Plan: 6 to add, 0 to change, 0 to destroy`  
**Exit code:** 0

| Resource | Type |
|----------|------|
| `aws_ecr_repository.tsp` | ECR repository |
| `aws_iam_role.apprunner_access` | IAM role |
| `aws_iam_role_policy_attachment.apprunner_access_ecr` | IAM policy attachment |
| `aws_iam_role.apprunner_instance` | IAM role |
| `aws_apprunner_auto_scaling_configuration_version.tsp` | Auto scaling |
| `aws_apprunner_service.tsp` | App Runner service |

### Real-credential plan

**Status:** **Pending operator AWS credentials**

**Command (operator):**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform plan -var-file=terraform.tfvars
```

Expected result when credentials are valid: `Plan: 6 to add, 0 to change, 0 to destroy` with live AWS account context.

---

## 6. Resource Inventory

| # | Resource | Required for PE | Purpose |
|---|----------|-----------------|---------|
| 1 | `aws_ecr_repository.tsp` | Yes | Host mirrored container image |
| 2 | `aws_iam_role.apprunner_access` | Yes | ECR pull for App Runner build |
| 3 | `aws_iam_role_policy_attachment.apprunner_access_ecr` | Yes | ECR read managed policy |
| 4 | `aws_iam_role.apprunner_instance` | Yes | Runtime task role |
| 5 | `aws_apprunner_auto_scaling_configuration_version.tsp` | Yes | Scaling bounds |
| 6 | `aws_apprunner_service.tsp` | Yes | TSP hosting |

---

## 7. Cost Expectation

| Service | Estimate |
|---------|----------|
| App Runner (256/512, 1–2 instances) | ~$7–$14/month |
| ECR storage | ~$0.10/month |
| IAM | $0 |
| **Total** | **~$7–$15/month** |

No NAT, ALB, RDS, or CloudFront charges in this plan.

---

## 8. Security Notes

- App Runner public HTTPS URL (expected for marketing site)
- IAM: managed ECR policy on access role only; instance role has no attached policies
- ECR scan on push enabled
- No secrets in Terraform or tfvars examples
- Local state file must not be committed (gitignored)

---

## 9. Apply Recommendation

### APPROVE FOR APPLY (with pre-conditions)

| Pre-condition | Status |
|---------------|--------|
| Image source resolved (ECR) | **Done** |
| Terraform validate passes | **Done** |
| Structural plan (6 resources) | **Done** |
| State approach documented | **Done** |
| Operator AWS credentials configured | **Pending** |
| Real-credential `terraform plan` | **Pending** |
| Docker image mirrored to ECR | **Pending** (post-ECR create, pre-App Runner) |

**Authorization:** Proceed to apply ACI after operator completes credential validation and real-credential plan.

---

## 10. Risks

| Risk | Mitigation |
|------|------------|
| App Runner fails if ECR image missing | Mirror image before or immediately after ECR create |
| Local state loss | Backup `terraform.tfstate`; migrate to S3 later |
| No AWS creds on dev machine | Operator configures `aws configure` before plan/apply |
| Public App Runner URL | Acceptable for MVP; custom domain later |

---

## Related Documents

- [PE_plan_review.md](./PE_plan_review.md)
- [ACI-PE-003-completion-report.md](./ACI-PE-003-completion-report.md)
- [../../terraform/README.md](../../terraform/README.md)
