# ACI-PE-004B Completion Report — Broke-Mode PE Architecture Pivot Assessment

**ACI:** ACI-PE-004B  
**Title:** Broke-Mode PE Architecture Pivot Assessment  
**Status:** **Completed — recommend pivot to EC2**  
**Date:** 2026-06-22

---

## 1. Summary of Work Performed

Confirmed safe Terraform state (ECR only), assessed EC2 broke-mode route, verified container image is **amd64-only**, probed EC2 IAM permissions for `nebula`, drafted Terraform pivot (`compute_platform = "ec2"`), validated configuration, ran plan (2 to add). No `terraform apply`. No PE compute resources created.

---

## 2. Current Terraform State

| Resource | In state |
|----------|----------|
| `aws_ecr_repository.tsp` | Yes |
| Other resources | None |

**Safe** — matches expectation.

---

## 3. EC2 Route Assessment

| Decision | Value |
|----------|-------|
| Platform | EC2 + Docker on Amazon Linux 2023 |
| Instance type | **t3.micro** (x86_64) |
| VPC | Default VPC |
| SSH / key pair | None |
| IAM instance profile | None (Docker Hub path) |
| Ingress | SG port 80 → container 3000 |

**t4g.small rejected** — ARM64 incompatible with image.

---

## 4. Image Architecture Compatibility

| Check | Result |
|-------|--------|
| `docker manifest inspect` | **linux/amd64** |
| `docker image inspect` | **amd64/linux** |
| CI build | Single-platform (`ubuntu-latest`), no arm64 |

**Use t3.micro or t2.micro only.**

---

## 5. IAM Permission Assessment

| Path | IAM roles? | `nebula` |
|------|------------|----------|
| App Runner | Required | Blocked |
| EC2 + Docker Hub | **Not required** | **EC2 APIs allowed** |

Probes: `CreateSecurityGroup` success; `RunInstances` dry-run success.

---

## 6. Image Source Recommendation

**Option A — Docker Hub:** `taig2k/taig_service_portal_tsp:deployable` (**selected**)

Avoids ECR auth / instance profile on EC2. ECR repo retained but optional.

---

## 7. Terraform Resource Plan

**EC2 mode — 2 to add:**

1. `aws_security_group.tsp_ec2[0]`
2. `aws_instance.tsp[0]`

**Unchanged:** `aws_ecr_repository.tsp`

**Gated off:** App Runner + IAM (`apprunner.tf`, `count = 0`)

---

## 8. Terraform Validation Result

| Command | Result |
|---------|--------|
| `terraform fmt` | Pass |
| `terraform validate` | Pass |

---

## 9. Terraform Plan Result

| Metric | Result |
|--------|--------|
| Plan | **2 to add, 0 to change, 0 to destroy** |
| `compute_platform` | `ec2` |
| Image | `taig2k/taig_service_portal_tsp:deployable` |

---

## 10. Cost Comparison

| | App Runner | EC2 t3.micro |
|---|------------|--------------|
| Monthly (est.) | $7–$15 | ~$7.50 (free tier eligible) |
| One-day test | N/A | ~$0.25–0.35 |
| Blockers | Subscription + IAM | None observed |

---

## 11. Pivot Recommendation

**PIVOT to EC2 + Docker** — viable, broke-mode aligned, bypasses PE-004 blockers, no new IAM roles for Docker Hub path.

---

## 12. Risks Discovered

| Risk | Notes |
|------|-------|
| Public IP ephemeral | No Elastic IP in broke-mode |
| No SSH | Debug via cloud-init logs only unless SSM added later |
| Open HTTP SG | MVP-acceptable |
| amd64 lock-in | ARM instances require multi-arch CI |

---

## 13. Readiness For Next ACI

**Ready for EC2 apply ACI** (e.g. ACI-PE-004C):

- `terraform apply -var-file=terraform.tfvars` with `compute_platform = "ec2"`
- Smoke test against `http://<public-ip>`

No admin IAM action required for Docker Hub path.

---

## 14. Commit ID(s)

_To be recorded after commit._

---

## PASS / FAIL Assessment

| Criterion | Result |
|-----------|--------|
| State confirmed safe | **PASS** |
| EC2 route assessed | **PASS** |
| Image arch determined | **PASS** |
| IAM impact known | **PASS** |
| Image source recommended | **PASS** |
| Terraform pivot drafted | **PASS** |
| Terraform validates | **PASS** |
| Plan captured | **PASS** |
| Cost comparison documented | **PASS** |
| Clear pivot recommendation | **PASS** |
| No PE compute created | **PASS** |
| No secrets committed | **PASS** |

**Overall ACI-PE-004B:** **PASS**
