# TSP AWS Deployment Guide

Documentation for hosting the TAIG Service Portal (TSP) on AWS using S3 and CloudFront.

**Status:** Documentation only — no AWS resources are provisioned by this repository.  
**Audience:** Operators planning production hosting on AWS.

---

## Overview

TSP is a Node.js Express application that serves server-rendered pages (EJS). AWS deployment options depend on whether the operator runs the **container** (recommended, matches PA workflow) or attempts **static extraction** (not recommended for current architecture).

This guide documents both the **recommended container approach** and the **static S3 approach** for informational purposes.

---

## Required AWS Services

### Recommended (container-based)

| Service | Purpose |
|---------|---------|
| **Amazon ECR** or **Docker Hub** | Container image registry |
| **AWS App Runner** or **Amazon ECS Fargate** | Run Docker container |
| **Application Load Balancer** (ECS) | Traffic routing, TLS termination |
| **Amazon Route 53** | DNS management |
| **AWS Certificate Manager (ACM)** | TLS certificates |
| **Amazon CloudWatch** | Logs and metrics |

### Static alternative (limited)

| Service | Purpose |
|---------|---------|
| **Amazon S3** | Static file hosting |
| **Amazon CloudFront** | CDN, HTTPS, caching |
| **Route 53** | DNS |
| **ACM** | TLS certificates |

> **Note:** The current TSP MVP uses server-side EJS rendering. A pure S3 static deployment would require architectural changes (pre-rendered HTML or frontend migration). S3 + CloudFront is documented here as the standard AWS static pattern for future reference.

---

## S3 Hosting Approach

### When applicable

- Pre-rendered static HTML export, or
- Future migration to a static site generator / SPA

### Architecture

```
Visitor → CloudFront → S3 Bucket (static assets)
```

### Setup sequence

1. **Create S3 bucket**
   - Name: e.g. `tsp.theaiguy.com` or `taig-service-portal-prod`
   - Region: operator choice (e.g. `us-east-1`)
   - Block public access: enabled (CloudFront accesses via OAC)

2. **Upload static content**
   - HTML, CSS, JS, images
   - Set cache headers appropriately

3. **Configure bucket policy**
   - Allow CloudFront Origin Access Control (OAC) read access only

4. **Enable versioning** (optional)
   - Supports rollback of static deployments

### Considerations

- No server-side rendering without Lambda@Edge or architectural change
- Contact form requires separate API (not in current MVP scope)
- Health endpoint (`/health`) not available on pure S3

---

## CloudFront Approach

### Architecture (static)

```
                    ┌─────────────┐
  User ──HTTPS──►   │ CloudFront  │──► S3 Origin (static files)
                    │ Distribution│
                    └─────────────┘
                           │
                    ACM Certificate
                    Route 53 DNS
```

### Architecture (container — recommended)

```
                    ┌─────────────┐
  User ──HTTPS──►   │ CloudFront  │──► ALB ──► ECS/App Runner (Docker container)
                    │ Distribution│
                    └─────────────┘
                           │
                    ACM Certificate
                    Route 53 DNS
```

### CloudFront configuration

| Setting | Recommendation |
|---------|----------------|
| Origin | S3 (static) or ALB/App Runner (container) |
| Viewer protocol policy | Redirect HTTP to HTTPS |
| Allowed methods | GET, HEAD, OPTIONS (+ POST if API added later) |
| Cache policy | CachingOptimized for static assets; no cache for dynamic HTML if applicable |
| Custom error pages | 404 → `/index.html` (SPA/static only) |
| TLS certificate | ACM certificate in `us-east-1` for CloudFront |
| Alternate domain (CNAME) | `www.theaiguy.com` or operator domain |

### Cache behavior

| Path pattern | Cache |
|--------------|-------|
| `/css/*`, `/js/*` | Long TTL |
| `/health` | No cache |
| HTML pages | Short TTL or no cache for dynamic content |

---

## Deployment Sequence

### Phase 1 — Prepare image

1. Merge/release to `deployable` branch
2. CI validates build and Docker image
3. Docker Publish workflow pushes `taig2k/taig_service_portal_tsp:latest`

### Phase 2 — AWS infrastructure (operator)

1. Create VPC, subnets, security groups (ECS path)
2. Create ECR repository or configure Docker Hub pull credentials
3. Provision ECS cluster + Fargate service **or** App Runner service
4. Configure ALB with target group → container port 3000
5. Request ACM certificate for production domain
6. Create CloudFront distribution pointing to ALB origin
7. Create Route 53 A/AAAA alias to CloudFront

### Phase 3 — Validate

1. `curl -f https://<domain>/health`
2. Run smoke tests against production URL:
   ```bash
   node scripts/smoke-test.js https://<domain>
   ```
3. Verify all MVP pages render correctly
4. Confirm TLS certificate is valid

### Phase 4 — Operate

1. Monitor CloudWatch logs from container service
2. Set up alarms on health check failures
3. Document rollback procedure (redeploy previous image tag)

---

## Environment Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | HTTP listen port |
| `NODE_ENV` | `production` | Set in Dockerfile |

No database or external service dependencies in current MVP.

---

## Security Considerations

- Terminate TLS at CloudFront or ALB; do not expose container directly to internet without load balancer
- Restrict security groups to ALB → container traffic only
- Use IAM roles for ECS task execution (avoid long-lived credentials in container)
- Store secrets in AWS Secrets Manager if added in future ACIs
- Enable CloudFront access logging for audit trail

---

## Cost Considerations (high level)

| Service | Cost driver |
|---------|-------------|
| S3 | Storage + requests (low for static site) |
| CloudFront | Data transfer + requests |
| ECS Fargate / App Runner | Compute hours, vCPU/memory |
| ALB | Hourly + LCU usage |
| Route 53 | Hosted zone + queries |

Container hosting costs more than pure S3 static but matches the current application architecture.

---

## Out of Scope (this document)

- Terraform / CloudFormation templates (future ACI)
- Actual AWS resource provisioning
- Contact form backend
- Authentication and client portal
- Database integration

---

## Related Documents

- [deployment_runbook.md](./deployment_runbook.md) — Clone, build, validate, Docker publish
- [PA_validation_report.md](./PA_validation_report.md) — Production Artifact assessment
