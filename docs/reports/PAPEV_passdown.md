# PAPEV Passdown

**Project:** TAIG Service Portal (TSP)  
**Certification:** PAPEV (Production Artifact in Production Environment Verified)  
**Date:** 2026-06-23  
**ACI:** ACI-PE-006

This document is the operational handoff for anyone maintaining or extending TSP after PE build mission closure.

---

## Current Truth

TSP is **PAPEV certified** and **live** at:

**http://32.197.194.117**

| Fact | Value |
|------|-------|
| Status | Operational |
| Smoke test | 6/6 pass (last verified ACI-PE-006) |
| Image | `taig2k/taig_service_portal_tsp:deployable` |
| Compute | EC2 t3.micro (`compute_platform = ec2`) |
| PE build mission | **Closed** |

---

## Environment Information

| Field | Value |
|-------|-------|
| AWS account | `526123657916` |
| AWS profile (operator) | `nebula` |
| Region | `us-east-1` |
| Instance ID | `i-04db848abd1bd57f7` |
| Instance type | `t3.micro` |
| Public IP | `32.197.194.117` |
| Security group | `sg-01ae803e7f43f286e` (`tsp-production-ec2`) |
| VPC | Default VPC `vpc-09d62a55b1a681ef1` |
| AMI | Amazon Linux 2023 x86_64 (SSM parameter) |
| Ingress | TCP 80 → container 3000 |
| SSH | Disabled (no key pair) |
| IAM roles | None on EC2 path |

---

## Terraform Information

### Location

`terraform/`

### Key variables (`terraform.tfvars` — local, not committed)

| Variable | Typical value |
|----------|---------------|
| `compute_platform` | `ec2` |
| `ec2_instance_type` | `t3.micro` |
| `ec2_image_source` | `docker_hub` |
| `ec2_host_port` | `80` |
| `docker_hub_image` | `taig2k/taig_service_portal_tsp` |
| `docker_image_tag` | `deployable` |
| `aws_region` | `us-east-1` |
| `service_name` | `tsp-production` |

### State (local, gitignored)

```
data.aws_ssm_parameter.al2023_ami[0]
data.aws_subnet.default[0]
data.aws_subnets.default[0]
data.aws_vpc.default[0]
aws_ecr_repository.tsp
aws_instance.tsp[0]
aws_security_group.tsp_ec2[0]
```

**Backup `terraform/terraform.tfstate` before any apply or destroy.**

### Common commands

```powershell
$env:AWS_PROFILE = "nebula"
cd terraform

terraform state list
terraform output
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Teardown (when approved)

```powershell
cd terraform
terraform destroy -var-file=terraform.tfvars
```

---

## Deployment Information

### Production Artifact (PA)

| Item | Detail |
|------|--------|
| Repository | https://github.com/the-ai-guy-2k/taig_service_portal_TSP |
| Branch | `deployable` |
| Docker image | `taig2k/taig_service_portal_tsp:deployable` |
| CI publish | `.github/workflows/docker-publish.yml` |
| Local build | `docker build -t taig2k/taig_service_portal_tsp:local .` |
| Smoke test | `node scripts/smoke-test.js [baseUrl]` |

### Production Environment (PE) — EC2 path

1. EC2 boots Amazon Linux 2023
2. `user_data` installs Docker, pulls `taig2k/taig_service_portal_tsp:deployable`
3. Container runs with `-p 80:3000`, `--restart unless-stopped`
4. Template: `terraform/templates/ec2-user-data.sh.tpl`

### Updating the running app

1. Publish new image to Docker Hub (`deployable` tag) via CI on `deployable` branch
2. Either:
   - **Replace instance:** `terraform apply` with `user_data_replace_on_change` (may recreate), or
   - **Reboot instance** after manual image update (requires SSH/SSM — not configured), or
   - **Recreate:** `terraform taint aws_instance.tsp[0]` then `terraform apply`

For broke-mode PE, simplest path: taint + apply to pull latest `deployable` on new instance.

---

## Validation Status

| Check | Status | Command |
|-------|--------|---------|
| Health | Pass | `curl http://32.197.194.117/health` |
| Smoke (full) | Pass | `node scripts/smoke-test.js http://32.197.194.117` |
| Routes | Pass | `/`, `/about`, `/services`, `/contact`, `/health` |
| Reboot resilience | Pass (PE-005) | EC2 reboot; `/health` ~20s recovery |

Last formal validation: [PE_validation_report.md](PE_validation_report.md) (ACI-PE-005).

---

## Cost Estimate

| Component | Monthly (approx.) |
|-----------|-------------------|
| t3.micro | ~$7.50 |
| 8 GB gp3 EBS | ~$0.64 |
| ECR (optional) | ~<$1 |
| **Total** | **~$8–9/month** |

One-day test: ~$0.25–0.35. Free tier may reduce EC2 cost for eligible accounts.

---

## Risks

| Risk | Mitigation |
|------|------------|
| Ephemeral IP | Note IP after apply; consider Elastic IP in future ACI |
| No TLS | Add ALB + ACM or CloudFront in future ACI |
| Local state | Migrate to S3 backend (`backend.tf.example`) when team grows |
| Single instance | Accept for MVP; scale in future ACI |
| Open port 80 | Restrict CIDR when access pattern known |

---

## Recommended Next Actions

These are **out of scope** for PAPEV certification but typical follow-ons:

| Priority | Action |
|----------|--------|
| Optional | Custom domain + HTTPS (Route53, ACM, ALB or CloudFront) |
| Optional | Remote Terraform state (S3 + DynamoDB lock) |
| Optional | SSM Session Manager for ops (requires instance profile) |
| Optional | Teardown PE when test complete (`terraform destroy`) |
| Optional | Contact backend, auth, client portal (product ACIs) |
| Maintenance | Re-run smoke test after any infrastructure change |
| Maintenance | Monitor Docker Hub `deployable` tag for PA updates |

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [PAPEV_certification_report.md](PAPEV_certification_report.md) | Certification decision and evidence |
| [PE_validation_report.md](PE_validation_report.md) | Operational validation evidence |
| [PE_creation_report.md](PE_creation_report.md) | How PE was created |
| [PA_validation_report.md](PA_validation_report.md) | PA assessment |
| [deployment_runbook.md](deployment_runbook.md) | Build and deploy procedures |
| [docs/aci_history/README.md](../aci_history/README.md) | Full ACI index |

---

## PE Build Mission Closure

**Mission status:** **CLOSED**

TSP has achieved PAPEV certification. Further work proceeds under new ACIs outside the PE build mission.
