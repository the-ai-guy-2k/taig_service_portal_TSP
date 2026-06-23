# TSP Production Environment — Terraform Plan Review

**ACI:** ACI-PE-002  
**Date:** 2026-06-22  
**Region:** `us-east-1`  
**Plan result:** `5 to add, 0 to change, 0 to destroy`

---

## Executive Summary

Terraform plan review confirms a **minimal, low-footprint** Production Environment centered on a single AWS App Runner service. The configuration is appropriate for TSP MVP hosting with broke-mode cost alignment, subject to two pre-apply corrections: **ECR image mirroring** and **confirmation plan with real AWS credentials**.

**Apply recommendation:** **CONDITIONAL APPROVE** — proceed to ACI-PE-003 only after ECR image path is resolved and a credential-backed plan is re-run.

---

## Plan Generation

**Command:**

```bash
cd terraform
export AWS_ACCESS_KEY_ID=<read-only-or-plan-credentials>
export AWS_SECRET_ACCESS_KEY=<secret>
export AWS_EC2_METADATA_DISABLED=true
terraform plan -var-file=terraform.tfvars.plan-review -no-color
```

For offline structural plan review (no live AWS account), `terraform.tfvars.plan-review` sets `aws_skip_credential_checks = true` with placeholder credentials. **Do not use plan-review variables for apply.**

Full plan output captured in `terraform/plan-output.txt` (local, gitignored).

---

## Resource Inventory

| # | Resource Type | Terraform Name | Purpose | Required for PE? |
|---|---------------|----------------|---------|------------------|
| 1 | `aws_iam_role` | `apprunner_access` | Allows App Runner build service to pull container image from registry | **Yes** |
| 2 | `aws_iam_role_policy_attachment` | `apprunner_access_ecr` | Attaches AWS managed ECR access policy to pull role | **Yes** |
| 3 | `aws_iam_role` | `apprunner_instance` | Runtime role for App Runner tasks | **Yes** |
| 4 | `aws_apprunner_auto_scaling_configuration_version` | `tsp` | Defines min/max instances and concurrency | **Yes** |
| 5 | `aws_apprunner_service` | `tsp` | Hosts TSP container (`taig2k/taig_service_portal_tsp:deployable`) | **Yes** |

**Total:** 5 resources — all required for a functional App Runner PE. No extraneous VPC, ALB, RDS, or CloudFront resources.

---

## Cost Assessment

### Expected AWS services

| Service | Usage |
|---------|-------|
| AWS App Runner | 1 service, 0.25 vCPU / 0.5 GB per instance |
| IAM | 2 roles + 1 policy attachment (no charge) |

### Estimated recurring cost (us-east-1, low traffic MVP)

| Component | Estimate |
|-----------|----------|
| App Runner provisioned (1 instance, 256 CPU / 512 MB) | ~$5–$8/month |
| App Runner active compute (light traffic) | ~$1–$5/month |
| Data transfer | ~$0–$3/month (low volume) |
| **Total estimate** | **~$7–$16/month** |

### Hidden / variable costs

| Risk | Notes |
|------|-------|
| Scale-out to 3 instances (`max_size = 3`) | Could multiply cost under load; acceptable safety bound |
| ECR storage for mirrored image | ~$0.10/GB/month (negligible for single image) |
| Custom domain + ACM | Free for certificate; Route 53 hosted zone ~$0.50/month if added later |
| CloudWatch logs | Minimal at MVP traffic |

### Broke-mode alignment

**Aligned.** Smallest App Runner size (256/512), single-region, no ALB/VPC/NAT, no database, no CDN in this plan. No enterprise components.

### Cost optimization recommendations (pre-apply)

1. Consider `max_size = 2` for initial PE if traffic is expected to stay very low
2. Keep `auto_deployments_enabled = false` until CI/CD deploy pipeline is defined
3. Monitor App Runner billing in first 30 days post-apply

---

## Security Assessment

| Area | Assessment |
|------|------------|
| **Public exposure** | App Runner assigns a public `*.awsapprunner.com` URL — expected for public marketing site |
| **IAM — access role** | AWS managed `AWSAppRunnerServicePolicyForECRAccess` only — appropriate for image pull |
| **IAM — instance role** | No policies attached — minimal privilege (good) |
| **Secrets handling** | No secrets in Terraform; no env vars with credentials |
| **Network** | Default App Runner public ingress; no custom VPC (simpler, acceptable for MVP) |
| **TLS** | App Runner provides HTTPS on default URL automatically |

### Security concerns

| Issue | Severity | Mitigation |
|-------|----------|------------|
| Public URL with no WAF | Low | Acceptable for MVP; add WAF/CloudFront in future ACI if needed |
| Instance role unused | Low | Attach policies only when app needs AWS API access |
| Docker Hub vs ECR mismatch | **Medium** | Mirror image to ECR before apply (see Deployment) |

**Verdict:** Security posture is **appropriate and minimal** for TSP MVP. Nothing excessive.

---

## Deployment Assessment

| Setting | Planned Value | Validated? |
|---------|---------------|------------|
| **Docker image** | `taig2k/taig_service_portal_tsp:deployable` | Yes (ACI-004) |
| **Repository type** | `ECR` | **Mismatch** — image is on Docker Hub, not ECR |
| **Port** | `3000` | Yes — matches application |
| **Health check** | `HTTP /health` | Yes — matches smoke tests |
| **Region** | `us-east-1` | Per project spec |
| **CPU / Memory** | 256 / 512 | Smallest practical tier |
| **Auto deploy** | `false` | Manual/image-pin controlled |

### Critical pre-apply item

**ECR mirror required.** Plan shows `image_repository_type = "ECR"` with `image_identifier = "taig2k/taig_service_portal_tsp:deployable"`. App Runner will not pull Docker Hub images with this configuration. Before apply:

1. Create ECR repository (ACI-PE-003 or manual step)
2. Mirror `taig2k/taig_service_portal_tsp:deployable` to ECR
3. Update `docker_image` to ECR URI (e.g. `<account>.dkr.ecr.us-east-1.amazonaws.com/tsp:deployable`)
4. Re-run `terraform plan` with real credentials

---

## Drift / Over-Engineering Review

| Item | Verdict |
|------|---------|
| VPC / subnets | Not included — good |
| ALB / CloudFront | Not included — good |
| RDS / database | Not included — good |
| Route 53 / custom domain | Not included — deferred correctly |
| Auto scaling 1–3 instances | Reasonable; could reduce `max_size` to 2 |
| Separate autoscaling config resource | Required by App Runner API |
| IAM roles (2) | Minimum required by App Runner |

**No over-engineering identified.** Configuration is lean.

---

## Risks

| Risk | Severity | Notes |
|------|----------|-------|
| ECR/Docker Hub image mismatch | **High** | Apply will fail or pull wrong image without ECR mirror |
| Offline plan used dummy credentials | Medium | Re-plan with real AWS creds before apply |
| Public App Runner URL only | Low | Custom domain deferred appropriately |
| `max_size = 3` cost under spike | Low | Monitor usage |
| No remote Terraform state | Medium | Configure S3 backend before apply (ACI-PE-003) |

---

## Recommendations

1. **Before apply:** Mirror Docker Hub image to ECR and update `docker_image` variable
2. **Before apply:** Run `terraform plan` with real read-only AWS credentials (`aws_skip_credential_checks = false`)
3. **Before apply:** Configure remote state backend (S3 + DynamoDB lock)
4. **Consider:** Reduce `max_size` from 3 to 2 for initial PE
5. **ACI-PE-003:** Terraform apply with approval gate, post-apply smoke tests against `future_service_url`
6. **Future:** Custom domain, Route 53, WAF — separate ACIs

---

## Apply Recommendation

### CONDITIONAL APPROVE

| Criterion | Status |
|-----------|--------|
| Plan generates successfully | **Yes** (5 to add) |
| Resources are PE-appropriate | **Yes** |
| Cost aligned with broke-mode | **Yes** (~$7–$16/month) |
| Security minimal and acceptable | **Yes** |
| ECR image path resolved | **No — blocker for apply** |
| Real-credential plan run | **No — required before apply** |

**Authorization for `terraform apply`:** Deferred to **ACI-PE-003** after ECR mirror and credential-backed plan confirmation.

---

## Related Documents

- [ACI-PE-002-completion-report.md](./ACI-PE-002-completion-report.md)
- [ACI-PE-001-completion-report.md](./ACI-PE-001-completion-report.md)
- [../../terraform/README.md](../../terraform/README.md)
- [deployment_runbook.md](./deployment_runbook.md)
- [aws_deployment_guide.md](./aws_deployment_guide.md)
