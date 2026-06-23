# TSP Production Environment — Architecture Pivot Review

**ACI:** ACI-PE-004B  
**Date:** 2026-06-22  
**Status:** **RECOMMEND PIVOT** to EC2 + Docker (broke-mode)

---

## Executive Summary

App Runner PE is blocked by account subscription and IAM role creation limits on user `nebula`. EC2 + Docker on **t3.micro** (x86_64) is viable: `nebula` has EC2 permissions (verified via dry-run), **no IAM roles are required** when pulling from public Docker Hub, and the validated container image is **amd64-only** (not ARM/t4g compatible). Terraform pivot drafted with `compute_platform = "ec2"` (default). Plan: **2 to add** (security group + instance) with existing ECR unchanged. **No apply performed.**

---

## 1. Why App Runner Was Paused

| Blocker | Status (ACI-PE-004A) |
|---------|----------------------|
| `SubscriptionRequiredException` | App Runner not subscribed on account `526123657916` |
| `iam:CreateRole` AccessDenied | User `nebula` cannot create App Runner IAM roles |

App Runner also requires two IAM roles + managed policy attachment before service creation — adding admin dependency beyond broke-mode goals.

**Broke-mode fit:** App Runner is managed but has account activation friction and mandatory IAM roles. EC2 + Docker is simpler for a one-day / low-cost PE test.

---

## 2. EC2 Route Assessment

### Proposed architecture

| Component | Choice |
|-----------|--------|
| Instance type | **t3.micro** (x86_64) |
| AMI | Amazon Linux 2023 (SSM parameter, x86_64) |
| VPC | Default VPC (no new VPC/NAT) |
| Compute | Docker via `user_data` |
| Ingress | Security group TCP **80** → container **3000** |
| SSH | **None** (no key pair) |
| IAM instance profile | **None** (Docker Hub path) |
| Elastic IP | **None** (default public IP) |

### Why not t4g.small

`t4g.small` is **ARM64-only**. The validated image is **amd64/linux** only (see §3). t4g is **rejected** for this image without multi-arch rebuild.

### Why t3.micro over t2.micro

Both are x86_64 and broke-mode compatible. **t3.micro** is preferred (current generation, better baseline performance). t2.micro remains acceptable fallback if quota or free-tier constraints apply.

### EC2 permission probes (profile `nebula`)

| Action | Result |
|--------|--------|
| `ec2:DescribeVpcs` / `DescribeInstances` | **Allowed** |
| `ec2:CreateSecurityGroup` | **Allowed** (probe SG created and deleted) |
| `ec2:RunInstances` (dry-run, AL2023 AMI) | **Allowed** (`DryRunOperation` — would succeed) |
| `iam:CreateRole` | **Denied** (unchanged; irrelevant for EC2 Docker Hub path) |

**Conclusion:** EC2 PE does **not** require IAM role creation for the recommended Docker Hub image path.

---

## 3. Image Architecture Compatibility

### Evidence (not guessed)

| Source | Result |
|--------|--------|
| `docker manifest inspect taig2k/taig_service_portal_tsp:deployable` | Platform: **linux/amd64** |
| `docker image inspect ... --format {{.Architecture}}` | **amd64** |
| Dockerfile base | `node:20-alpine` (built on `ubuntu-latest` CI → amd64) |
| GitHub Actions `docker-publish.yml` | No `platforms:` multi-arch — single-platform push |

**Verdict:** Image runs on **x86_64** EC2 (t3.micro, t2.micro). **Not compatible** with t4g (ARM64) without CI rebuild for `linux/arm64`.

---

## 4. IAM Permission Impact

| Path | IAM roles required? | `nebula` status |
|------|---------------------|-----------------|
| App Runner + ECR | Yes (2 roles + attachment) | **Blocked** |
| EC2 + Docker Hub | **No** | EC2 APIs **allowed** |
| EC2 + private ECR | Yes (instance profile for `ecr:GetAuthorizationToken`) | Not implemented |

**Recommendation:** Use **Docker Hub** on EC2 to avoid IAM instance profiles and ECR auth in `user_data`.

Existing ECR repository remains in Terraform state (sunk cost, optional future use); not required for EC2 broke-mode deploy.

---

## 5. Image Source Recommendation

**Option A — Docker Hub (selected)**

```
taig2k/taig_service_portal_tsp:deployable
```

| Pro | Con |
|-----|-----|
| No IAM instance profile | Public registry dependency |
| Same validated image as PA | Rate limits unlikely at PE scale |
| Simple `user_data` (`docker pull`) | ECR mirror becomes optional |

**Option B — ECR (deferred)**

Private ECR pull from EC2 requires an IAM instance profile (or embedded credentials — not acceptable). Defer unless broke-mode constraints change.

---

## 6. Proposed Terraform Resource List

### In state today

| Resource | Status |
|----------|--------|
| `aws_ecr_repository.tsp` | Exists |

### EC2 path (`compute_platform = "ec2"`) — plan 2 to add

| Resource | Purpose |
|----------|---------|
| `data.aws_vpc.default` | Default VPC |
| `data.aws_subnets.default` | Subnet selection |
| `data.aws_subnet.default` | Launch subnet |
| `data.aws_ssm_parameter.al2023_ami` | AL2023 x86_64 AMI |
| `aws_security_group.tsp_ec2` | HTTP ingress on port 80 |
| `aws_instance.tsp` | Docker host + TSP container |

### App Runner path (`compute_platform = "apprunner"`) — gated off

Resources in `apprunner.tf` with `count` — not planned when `ec2` is selected (0 add).

### Explicitly avoided

NAT Gateway, ALB, RDS, CloudFront, Route53, VPC creation, IAM roles (EC2 path), key pairs, Elastic IP.

### Files changed

| File | Change |
|------|--------|
| `main.tf` | ECR only |
| `ec2.tf` | New EC2 + SG + data sources |
| `apprunner.tf` | App Runner gated by `compute_platform` |
| `variables.tf` | `compute_platform`, EC2 variables |
| `outputs.tf` | EC2 + conditional App Runner outputs |
| `templates/ec2-user-data.sh.tpl` | Docker install + run |

---

## 7. Terraform Validation

| Command | Result |
|---------|--------|
| `terraform fmt` | **Pass** |
| `terraform validate` | **Pass** |

---

## 8. Terraform Plan Result

**Command:** `terraform plan -var-file=terraform.tfvars`  
**Profile:** `nebula`  
**`compute_platform`:** `ec2` (default)

| Metric | Result |
|--------|--------|
| Plan | **2 to add, 0 to change, 0 to destroy** |
| ECR | No change (in state) |
| App Runner / IAM | 0 to add (gated off) |

Resources to create:

1. `aws_security_group.tsp_ec2[0]`
2. `aws_instance.tsp[0]`

Container image in plan: `taig2k/taig_service_portal_tsp:deployable`

---

## 9. Cost Comparison

| Item | App Runner (paused) | EC2 broke-mode (proposed) |
|------|-------------------|---------------------------|
| Compute | ~$7–$15/month (256/512, 1–2 instances) | **t3.micro** ~$7.50/month on-demand |
| Free tier | No App Runner free tier | **750 hrs/month t2/t3.micro** (12 mo, new accounts) |
| EBS | N/A | 8 GB gp3 ~$0.64/month (30 GB free tier) |
| ECR | ~<$1 storage | Optional (already exists) |
| Data transfer | Low | Low for MVP traffic |
| **One-day test** | N/A (not deployed) | **~$0.25–0.35** compute + pennies EBS |

**Broke-mode alignment:** EC2 t3.micro is **free-tier/trial friendly** and avoids App Runner subscription blocker. Cost is comparable or lower than App Runner for a single-instance MVP.

---

## 10. Recommendation

### **PIVOT — proceed with EC2 + Docker**

| Factor | Decision |
|--------|----------|
| Account blockers | EC2 path bypasses App Runner subscription + IAM roles |
| Image arch | amd64 → t3.micro |
| Permissions | Verified EC2 create path for `nebula` |
| Complexity | Default VPC, no SSH, no LB — minimal |
| Terraform | Validated; plan 2 to add |

### Do not pivot back to App Runner until

- App Runner subscribed on account `526123657916`
- IAM deploy policy attached (see `terraform/iam/tsp-pe-deploy-policy.json`)
- Broke-mode cost/simplicity advantage no longer applies

---

## 11. Risks

| Risk | Mitigation |
|------|------------|
| Ephemeral public IP | Accept for PE test; Elastic IP deferred |
| No SSH / SSM | `user_data` only; check `/var/log/cloud-init-output.log` via SSM later if profile added |
| SG open to 0.0.0.0/0:80 | Acceptable for MVP PE smoke test |
| Docker Hub pull on boot | Retry logic could be added in future ACI |
| ECR cost | Minimal; can destroy repo in teardown ACI |
| user_data failure silent | Post-apply smoke test required in next ACI |

---

## 12. Readiness For Next ACI

**Ready for ACI-PE-004C (or PE EC2 Apply)** when operator approves pivot:

1. Confirm `compute_platform = "ec2"` in `terraform.tfvars`
2. Run `terraform apply -var-file=terraform.tfvars`
3. Capture `terraform output future_service_url`
4. Run `node scripts/smoke-test.js http://<public-ip>`

No admin IAM changes required for EC2 Docker Hub path.

---

## 13. Terraform State Safety

**`terraform state list`:** `aws_ecr_repository.tsp` only — **safe**, no unexpected resources.

---

## 14. Secrets / Git Hygiene

Not committed: `terraform.tfvars`, `terraform.tfstate`, credentials, `.terraform/`, plan output files.
