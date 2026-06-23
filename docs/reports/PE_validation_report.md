# TSP Production Environment — Validation Report

**ACI:** ACI-PE-005  
**Date:** 2026-06-23  
**PE URL:** http://32.197.194.117  
**Status:** **VALIDATED** — ready for PAPEV certification review

---

## Executive Summary

TSP Production Artifact is **operational** on EC2 broke-mode PE. All core routes return HTTP 200, smoke tests pass (6/6 pre- and post-reboot), Terraform state matches expected inventory, and `/health` recovers within ~20 seconds after EC2 reboot. Container source is documented as `taig2k/taig_service_portal_tsp:deployable` via Terraform `user_data` and outputs.

**Recommendation:** **APPROVE for PAPEV certification.**

---

## 1. Validation Environment

| Field | Value |
|-------|-------|
| AWS account | `526123657916` |
| Region | `us-east-1` |
| Instance | `i-04db848abd1bd57f7` (t3.micro) |
| Public IP | `32.197.194.117` |
| Security group | `sg-01ae803e7f43f286e` |
| Compute platform | `ec2` |
| Validator profile | `nebula` |

---

## 2. Application Availability

**Target:** `http://32.197.194.117`

| Check | Result |
|-------|--------|
| HTTP reachability | **PASS** |
| Home page (`/`) | HTTP **200** |
| Response time (/) | **299 ms** (cold connection) |
| Page load | HTML body 5,592 bytes |

---

## 3. Core Route Validation

| Route | Status | Response time | Notes |
|-------|--------|---------------|-------|
| `/` | **200** | 299 ms | Home |
| `/about` | **200** | 62 ms | About page |
| `/services` | **200** | 66 ms | Services page |
| `/contact` | **200** | 72 ms | Contact page |
| `/health` | **200** | 53 ms | `{"status":"ok"}` |

**Result:** **5/5 routes PASS**

---

## 4. Smoke Test Results

**Command:** `node scripts/smoke-test.js "http://32.197.194.117"`

### Pre-reboot (validation session)

| Result | Count |
|--------|-------|
| Pass | **6** |
| Fail | **0** |

| Test | Result |
|------|--------|
| Health endpoint `/health` | PASS |
| Home page `/` | PASS |
| Home Nebula section `/` | PASS |
| About page `/about` | PASS |
| Services page `/services` | PASS |
| Contact page `/contact` | PASS |

### Post-reboot (confirmation)

| Result | Count |
|--------|-------|
| Pass | **6** |
| Fail | **0** |

**Operator reproducibility:** Any operator with network access can re-run:

```bash
node scripts/smoke-test.js "http://32.197.194.117"
```

---

## 5. Container Source Verification

**Expected image:** `taig2k/taig_service_portal_tsp:deployable`

| Evidence | Detail |
|----------|--------|
| Terraform output `ec2_container_image` | `taig2k/taig_service_portal_tsp:deployable` |
| Terraform output `docker_hub_source_image` | `taig2k/taig_service_portal_tsp:deployable` |
| `templates/ec2-user-data.sh.tpl` | `docker pull ${container_image}` → `docker run ... ${container_image}` |
| Variable default | `docker_hub_image` + `docker_image_tag: deployable` |
| Docker Hub manifest (amd64) | Digest `sha256:204e425077af3289379dd1614b7cfd5ee0bc93d1588a13bd25958a77b958ffef` |
| ACI-004 validation | Image tag `deployable` validated in CI pull-validate job |

**Note:** Runtime container ID not inspected via SSH (disabled by design). Source is **configuration-proven** via Terraform user_data and immutable deploy tag `deployable`.

---

## 6. Terraform State Validation

**Command:** `terraform state list`

```
data.aws_ssm_parameter.al2023_ami[0]
data.aws_subnet.default[0]
data.aws_subnets.default[0]
data.aws_vpc.default[0]
aws_ecr_repository.tsp
aws_instance.tsp[0]
aws_security_group.tsp_ec2[0]
```

| Expectation | Result |
|-------------|--------|
| EC2 instance in state | **Yes** |
| Security group in state | **Yes** |
| ECR (legacy from PE-004) | **Yes** |
| App Runner resources | **None** |
| IAM roles | **None** |

**State:** **VALID**

---

## 7. Reboot Resilience Test

| Step | Result |
|------|--------|
| Action | `aws ec2 reboot-instances --instance-ids i-04db848abd1bd57f7` |
| Initiated | 2026-06-23T00:11:16-04:00 |
| First `/health` after reboot | Timeout (instance restarting) |
| Recovery `/health` | **PASS** — HTTP 200, `{"status":"ok"}` |
| Recovery time | **~20 seconds** (attempt 2, 10s interval) |
| Post-reboot smoke test | **6/6 PASS** |

Docker `--restart unless-stopped` policy restores container after reboot.

---

## 8. Cost Assessment

### Resource inventory

| Resource | ID / type | Billing impact |
|----------|-----------|----------------|
| EC2 | t3.micro `i-04db848abd1bd57f7` | ~$0.0104/hr |
| EBS | 8 GB gp3 (root) | ~$0.64/month |
| ECR | `taig-service-portal-tsp` | ~<$1/month storage |
| Elastic IP | None | $0 |
| Load balancer | None | $0 |
| App Runner | None | $0 |

### Estimates

| Period | Estimate |
|--------|----------|
| One day | ~$0.25–0.35 (compute + EBS prorate) |
| Monthly (steady) | ~$8–9 (t3.micro + EBS + ECR) |
| Free tier | t3.micro 750 hrs/mo may apply (12-month new account) |

---

## 9. Risks

| Risk | Severity | Notes |
|------|----------|-------|
| HTTP only (no TLS) | Medium | Acceptable for broke-mode PE; address in future ACI |
| Ephemeral public IP | Medium | URL changes on instance replace |
| Open SG :80 worldwide | Low–Med | MVP PE; tighten for production hardening |
| No SSH/SSM | Low | Operational trade-off for broke-mode |
| Single instance (no HA) | Low | Expected for PE Phase 1 |
| Container source not SSH-verified | Low | Proven via Terraform + validated tag |

---

## 10. Recommendation

| Criterion | Status |
|-----------|--------|
| Application reachable | **PASS** |
| All routes function | **PASS** |
| Smoke tests pass | **PASS** |
| Terraform state valid | **PASS** |
| Reboot resilience | **PASS** |
| Cost documented | **PASS** |

**PAPEV readiness:** **APPROVE** — TSP is proven operational in AWS with repeatable validation commands and documented evidence.

---

## 11. Reproducibility Commands

```bash
# Availability
curl -f http://32.197.194.117/health

# Full smoke test
node scripts/smoke-test.js "http://32.197.194.117"

# Terraform state (from terraform/)
terraform state list
terraform output future_service_url
```

---

## 12. Related Reports

- [PE_creation_report.md](PE_creation_report.md)
- [ACI-PE-004C-completion-report.md](ACI-PE-004C-completion-report.md)
- [PE_architecture_pivot_review.md](PE_architecture_pivot_review.md)
