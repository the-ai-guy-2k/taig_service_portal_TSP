# ACI-PE-004C Completion Report — EC2 PE Creation

**ACI:** ACI-PE-004C  
**Title:** EC2 PE Creation  
**Status:** **Completed**  
**Date:** 2026-06-22

---

## 1. Summary of Work Performed

Confirmed AWS identity (`nebula`), verified Terraform state (ECR only), ran plan (2 to add), applied EC2 PE with `-auto-approve`, captured outputs, polled `/health` until HTTP 200, ran full smoke test (6/6 pass). Updated `PE_creation_report.md`. No secrets committed. No App Runner or IAM resources created.

---

## 2. AWS Identity Confirmation

| Field | Value |
|-------|-------|
| Profile | `nebula` |
| Account | `526123657916` |
| Arn | `arn:aws:iam::526123657916:user/nebula` |

---

## 3. Terraform State Before Apply

```
aws_ecr_repository.tsp
```

Safe; ECR preserved.

---

## 4. Terraform Plan Result

| Metric | Result |
|--------|--------|
| Plan | **2 to add, 0 to change, 0 to destroy** |
| Resources | `aws_security_group.tsp_ec2[0]`, `aws_instance.tsp[0]` |
| App Runner / IAM | **Not in plan** |

---

## 5. Terraform Apply Result

| Metric | Result |
|--------|--------|
| Command | `terraform apply -var-file=terraform.tfvars -auto-approve` |
| Outcome | **Success** |
| Resources added | 2 |

---

## 6. Resources Created

| Resource | ID / Name |
|----------|-----------|
| `aws_security_group.tsp_ec2[0]` | `sg-01ae803e7f43f286e` |
| `aws_instance.tsp[0]` | `i-04db848abd1bd57f7` (t3.micro) |

---

## 7. Terraform Outputs

```
future_service_url    = http://32.197.194.117:80
ec2_public_ip         = 32.197.194.117
ec2_instance_id       = i-04db848abd1bd57f7
compute_platform      = ec2
ec2_container_image   = taig2k/taig_service_portal_tsp:deployable
planned_region        = us-east-1
planned_service_name  = tsp-production
```

---

## 8. Initial Health Check Result

| Test | Result |
|------|--------|
| `curl http://32.197.194.117/health` | **PASS** — HTTP 200, `{"status":"ok"}` |
| `node scripts/smoke-test.js http://32.197.194.117` | **PASS** — 6/6 routes |
| Time to healthy | ~50 seconds post-apply |

---

## 9. Cost Notes

~$7.50/month t3.micro + ~$0.64/month EBS; free-tier eligible. One-day test ~$0.25–0.35. No App Runner/LB/NAT costs.

---

## 10. Risks Discovered

| Risk | Impact |
|------|--------|
| Ephemeral public IP | URL changes on instance replacement |
| HTTP only | No TLS until future ACI |
| Open SG :80 | Acceptable for MVP PE |
| Boot-time Docker pull | ~50s cold start observed |

---

## 11. Readiness For ACI-PE-005

**Ready.** PE URL `http://32.197.194.117` is live with 6/6 smoke pass. Proceed with formal PE validation ACI.

---

## 12. Commit ID(s)

`7895d91` — ACI-PE-004C: Document EC2 PE creation and live smoke-validated URL.

---

## PASS / FAIL Assessment

| Criterion | Result |
|-----------|--------|
| AWS identity confirmed | **PASS** |
| State safe | **PASS** |
| Plan expected EC2 only | **PASS** |
| Apply succeeded | **PASS** |
| EC2 + SG exist | **PASS** |
| Public IP/URL available | **PASS** |
| Health check attempted | **PASS** |
| PE creation report | **PASS** |
| Completion report | **PASS** |
| No secrets committed | **PASS** |

**Overall ACI-PE-004C:** **PASS**
