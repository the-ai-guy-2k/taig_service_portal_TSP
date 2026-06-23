# TSP Production Environment — Blocker Resolution Report

**ACI:** ACI-PE-004A  
**Date:** 2026-06-22  
**Status:** **ADMIN ACTION REQUIRED** — blockers diagnosed; remediation documented; apply not yet unblocked

---

## Executive Summary

ACI-PE-004A re-validated AWS identity, Terraform state, and remaining-resource plan. **Both PE-004 blockers remain active** on profile `nebula`. A minimal IAM policy template was added for account admin. App Runner subscription is still not active for account `526123657916` in `us-east-1`. Terraform plan correctly shows **5 resources to add** (ECR already in state). **No `terraform apply` was run.** ACI-PE-004B should proceed only after admin completes the steps below and verification probes pass.

---

## 1. AWS Identity Confirmation

| Field | Value |
|-------|-------|
| Profile | `nebula` |
| Account | `526123657916` |
| Arn | `arn:aws:iam::526123657916:user/nebula` |
| UserId | `AIDAXU73J5K6MACIMBRO2` |
| Region | `us-east-1` |

Secrets were not printed or committed.

---

## 2. IAM Blocker — Cause

During ACI-PE-004, Terraform failed creating:

- `tsp-production-apprunner-access`
- `tsp-production-apprunner-instance`

**Root cause:** IAM user `nebula` lacks `iam:CreateRole` (and related IAM management actions). ECR creation succeeded, indicating partial AWS permissions exist but not IAM/App Runner deploy scope.

### ACI-PE-004A verification (re-probe)

| Probe | Result |
|-------|--------|
| `aws iam create-role` (permission probe) | **AccessDenied** — `iam:CreateRole` |
| `aws iam list-attached-user-policies --user-name nebula` | **AccessDenied** |
| `aws iam simulate-principal-policy` | **AccessDenied** |

**Conclusion:** IAM blocker is **not resolved** in this session.

---

## 3. Selected Resolution Option

**Recommended: Option A — Grant `nebula` temporary least-privilege deploy permissions**

| Option | Assessment |
|--------|------------|
| **A — Extend `nebula`** | **Selected.** Simplest for single-operator PE Phase 1; scoped policy template provided |
| B — Dedicated Terraform deploy role | Valid alternative; requires admin to create role + trust + PassRole setup |
| C — Admin runs apply with elevated creds | Acceptable one-time path; less repeatable for ongoing Terraform |

### Policy template

Minimal policy committed at:

`terraform/iam/tsp-pe-deploy-policy.json`

### Admin action (Option A)

Account admin (root or IAM admin) must attach the policy to user `nebula`:

**Console:**

1. IAM → Users → `nebula` → Add permissions → Create inline policy → JSON
2. Paste contents of `terraform/iam/tsp-pe-deploy-policy.json`
3. Name: `TspPeDeploy`

**CLI (admin credentials):**

```bash
aws iam put-user-policy \
  --user-name nebula \
  --policy-name TspPeDeploy \
  --policy-document file://terraform/iam/tsp-pe-deploy-policy.json
```

### Post-fix verification (operator)

```powershell
$env:AWS_PROFILE = "nebula"
aws iam create-role --role-name tsp-pe-blocker-verify-probe --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"build.apprunner.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam delete-role --role-name tsp-pe-blocker-verify-probe
```

Both commands should succeed; then delete the probe role.

---

## 4. App Runner Activation Status

### ACI-PE-004A verification

| Probe | Result |
|-------|--------|
| `aws apprunner list-services --region us-east-1` | **SubscriptionRequiredException** — service not subscribed/active |

**Conclusion:** App Runner activation is **not confirmed**. Blocker remains.

### Admin action — App Runner first-use activation

1. Sign in to AWS Console as **account admin** (not `nebula` if insufficient).
2. Open **App Runner** in region **US East (N. Virginia) / us-east-1**.
3. Complete any first-use welcome / service activation prompt (creates account-level subscription).
4. If console access is blocked, use root or contact AWS Support to enable App Runner for account `526123657916`.

### Post-fix verification (operator)

```powershell
$env:AWS_PROFILE = "nebula"
aws apprunner list-services --region us-east-1
```

Expected: JSON response with `ServiceSummaryList` (may be empty `[]`). **No** `SubscriptionRequiredException`.

---

## 5. Terraform State Safety Check

**Command:** `terraform state list`

| Resource in state | Expected |
|-------------------|----------|
| `aws_ecr_repository.tsp` | Yes |

**Result:** State contains **only** `aws_ecr_repository.tsp`. No unexpected resources. **Safe to continue** once blockers are cleared.

Local state file (`terraform.tfstate`) remains gitignored.

---

## 6. Updated Terraform Plan Result

**Command:** `terraform plan -var-file=terraform.tfvars`  
**Profile:** `nebula`

| Metric | Result |
|--------|--------|
| Plan | **5 to add, 0 to change, 0 to destroy** |
| Match to expectation | **Yes** |

### Remaining resources in plan

1. `aws_iam_role.apprunner_access`
2. `aws_iam_role_policy_attachment.apprunner_access_ecr`
3. `aws_iam_role.apprunner_instance`
4. `aws_apprunner_auto_scaling_configuration_version.tsp`
5. `aws_apprunner_service.tsp`

ECR repository is refreshed in state; image reference in plan:

`526123657916.dkr.ecr.us-east-1.amazonaws.com/taig-service-portal-tsp:deployable`

Plan output saved locally as `terraform/plan-output-pe004a.txt` (gitignored).

**Note:** Plan succeeds without apply permissions; **apply will still fail** until IAM and App Runner blockers are resolved.

---

## 7. Readiness Recommendation

| Gate | Status |
|------|--------|
| Terraform state safe | **PASS** |
| Plan shows expected 5 resources | **PASS** |
| IAM deploy permissions | **FAIL** — admin must attach policy |
| App Runner subscription | **FAIL** — admin must activate in console |
| Ready for `terraform apply` | **NO** |

**Recommendation:** Issue **ACI-PE-004B** (complete PE apply) only after:

1. Admin attaches `TspPeDeploy` policy to `nebula` (or equivalent Option B/C)
2. Admin activates App Runner in `us-east-1`
3. Operator re-runs verification probes above
4. Operator confirms plan still shows 5 to add

---

## 8. Risks

| Risk | Notes |
|------|-------|
| Blockers unchanged this session | Apply in 004B will fail without admin follow-through |
| Temporary broad App Runner actions in policy | Scoped to TSP PE; remove inline policy after PE is stable if desired |
| Plan vs apply permission gap | Plan success does not imply apply readiness |
| Local state | Backup `terraform.tfstate` before 004B apply |

---

## 9. What Was Not Done (per ACI scope)

- No `terraform apply`
- No App Runner service created
- No TSP deployment to App Runner
- No credentials, `terraform.tfvars`, or state committed
