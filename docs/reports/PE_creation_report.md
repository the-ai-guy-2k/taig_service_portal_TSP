# TSP Production Environment — Creation Report

**ACI:** ACI-PE-004C (supersedes partial PE-004 App Runner attempt)  
**Date:** 2026-06-22  
**Status:** **COMPLETE** — EC2 broke-mode PE live

---

## Executive Summary

TSP Production Environment is deployed on **EC2 t3.micro** via Terraform (`compute_platform = "ec2"`). App Runner path was abandoned after account/IAM blockers (PE-004/004A); EC2 + Docker Hub pivot approved in PE-004B. Terraform apply added security group and instance; **health check and full smoke test passed** against public URL `http://32.197.194.117`.

---

## 1. AWS Identity Confirmation

**Profile:** `nebula` (not committed)

| Field | Value |
|-------|-------|
| Account | `526123657916` |
| Arn | `arn:aws:iam::526123657916:user/nebula` |
| UserId | `AIDAXU73J5K6MACIMBRO2` |
| Region | `us-east-1` |

Secrets were not printed or committed.

---

## 2. Architecture Path

| Aspect | Value |
|--------|-------|
| Compute | EC2 **t3.micro** (x86_64) |
| AMI | Amazon Linux 2023 (SSM parameter) |
| Container | Docker via `user_data` |
| Image source | **Docker Hub** `taig2k/taig_service_portal_tsp:deployable` |
| Ingress | SG TCP 80 → container 3000 |
| SSH | None |
| IAM roles | None created |
| App Runner | Not created |

Prior ECR repository (`taig-service-portal-tsp`) retained in state from PE-004; not used by EC2 runtime.

---

## 3. Terraform State — Before Apply (ACI-PE-004C)

```
aws_ecr_repository.tsp
```

ECR state preserved as required.

---

## 4. Terraform Plan Result (ACI-PE-004C)

**Command:** `terraform plan -var-file=terraform.tfvars`

| Metric | Result |
|--------|--------|
| Plan | **2 to add, 0 to change, 0 to destroy** |
| Unexpected resources | **None** (no App Runner, IAM, LB, NAT, RDS) |

Resources planned:

1. `aws_security_group.tsp_ec2[0]`
2. `aws_instance.tsp[0]`

---

## 5. Terraform Apply Result

**Command:** `terraform apply -var-file=terraform.tfvars -auto-approve`

| Metric | Result |
|--------|--------|
| Outcome | **Success** |
| Added | 2 |
| Changed | 0 |
| Destroyed | 0 |

---

## 6. Resources Created

| Resource | Identifier |
|----------|------------|
| Security group | `sg-01ae803e7f43f286e` (`tsp-production-ec2`) |
| EC2 instance | `i-04db848abd1bd57f7` (`tsp-production`, t3.micro) |
| ECR repository | `taig-service-portal-tsp` (pre-existing, unchanged) |

**Not created:** App Runner, IAM roles, Elastic IP, key pair, load balancer.

---

## 7. Terraform Outputs

| Output | Value |
|--------|-------|
| `future_service_url` | `http://32.197.194.117:80` |
| `ec2_public_ip` | `32.197.194.117` |
| `ec2_instance_id` | `i-04db848abd1bd57f7` |
| `compute_platform` | `ec2` |
| `ec2_container_image` | `taig2k/taig_service_portal_tsp:deployable` |
| `planned_region` | `us-east-1` |
| `planned_service_name` | `tsp-production` |
| `ecr_repository_url` | `526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp` |

Security group ID (from apply): `sg-01ae803e7f43f286e`

---

## 8. Initial Availability Check

| Check | Result |
|-------|--------|
| `GET http://32.197.194.117/health` | **HTTP 200** — `{"status":"ok"}` (~50s after apply, cloud-init + Docker pull) |
| `node scripts/smoke-test.js http://32.197.194.117` | **6/6 PASS** (health, home, about, services, contact) |
| EC2 instance state | `running` |

---

## 9. PE History (Context)

| ACI | Outcome |
|-----|---------|
| PE-004 | ECR + image mirror; App Runner apply failed (IAM + subscription) |
| PE-004A | Blockers documented; admin actions for App Runner path |
| PE-004B | Pivot to EC2 assessed and approved |
| **PE-004C** | **EC2 PE created and smoke-validated** |

---

## 10. Cost Notes

| Component | Estimate |
|-----------|----------|
| t3.micro on-demand | ~$7.50/month (~$0.0104/hr) |
| 8 GB gp3 EBS | ~$0.64/month |
| ECR storage | ~<$1/month (optional, existing) |
| **One-day PE test** | ~$0.25–0.35 compute + pennies EBS |
| Free tier | t3.micro may be covered (750 hrs/mo, 12 mo, new accounts) |

No App Runner, NAT, or load balancer charges.

---

## 11. Risks

| Risk | Notes |
|------|-------|
| Ephemeral public IP | Changes on instance replace; no Elastic IP |
| HTTP only (port 80) | No TLS/custom domain |
| SG open to 0.0.0.0/0:80 | MVP PE acceptable; tighten for long-term |
| No SSH/SSM | Debug via console/cloud-init logs only |
| Docker Hub dependency | EC2 pulls public image at boot |
| Single instance | No HA |

---

## 12. Readiness For ACI-PE-005

**Ready.** Live PE URL available for formal PE validation:

- URL: `http://32.197.194.117`
- Smoke test baseline: 6/6 pass
- Recommended: full PE validation report, uptime monitoring, teardown plan

---

## 13. Secrets and Git Hygiene

Not committed: `terraform.tfvars`, `terraform.tfstate`, `.terraform/`, credentials, plan output files.
