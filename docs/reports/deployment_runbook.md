# TSP Deployment Runbook

Operational guide for cloning, building, validating, containerizing, and publishing the TAIG Service Portal (TSP).

**Audience:** Operators performing deployment or PA certification  
**Deployment branch:** `deployable`  
**Docker image:** `taig2k/taig_service_portal_tsp:<tag>`

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Git | 2.x+ | Clone repository |
| Node.js | 20.x+ | Local build and validation |
| npm | 10.x+ | Dependency management |
| Docker | 24.x+ | Container build and run |
| curl | any | Health checks |

Optional for Docker Hub publication:

- Docker Hub account with push access to `taig2k/taig_service_portal_tsp`
- GitHub repository secrets configured (see [Docker Hub Publication](#docker-hub-publication))

---

## 1. Clone Instructions

```bash
git clone https://github.com/the-ai-guy-2k/taig_service_portal_TSP.git
cd taig_service_portal_TSP
```

For deployment work, check out the release branch:

```bash
git fetch origin
git checkout deployable
git pull origin deployable
```

Verify branch:

```bash
git branch --show-current
# Expected: deployable
```

---

## 2. Build Instructions

Install dependencies using the lockfile for reproducible builds:

```bash
npm ci
```

Syntax validation:

```bash
npm run validate
```

Start the application:

```bash
npm start
```

The server listens on port `3000` by default. Override with:

```bash
PORT=8080 npm start
```

---

## 3. Validation Instructions

### Health check

With the application running:

```bash
curl -f http://localhost:3000/health
```

Expected response:

```json
{"status":"ok"}
```

### Route smoke test

Run the automated smoke test (application must be running):

```bash
npm run smoke-test
```

This validates:

| Route | Check |
|-------|-------|
| `/health` | JSON health response |
| `/` | Home page content and Nebula section |
| `/about` | About page content |
| `/services` | Services page content |
| `/contact` | Contact form UI |

Against a different host/port:

```bash
node scripts/smoke-test.js http://localhost:8080
```

### Expected result

```
PASS [Health endpoint] /health
PASS [Home page] /
...
All 6 smoke tests passed.
```

Exit code `0` indicates success.

---

## 4. Docker Build Instructions

Build the production image:

```bash
docker build -t taig2k/taig_service_portal_tsp:local .
```

Run the container:

```bash
docker run -d --name tsp -p 3000:3000 taig2k/taig_service_portal_tsp:local
```

Validate the running container:

```bash
curl -f http://localhost:3000/health
npm run smoke-test
```

Stop and remove:

```bash
docker rm -f tsp
```

### Image details

| Property | Value |
|----------|-------|
| Base image | `node:20-alpine` |
| Exposed port | `3000` |
| Health check | `GET /health` |
| Entrypoint | `node src/server.js` |

---

## 5. Docker Hub Publication Instructions

### Confirmed publish process (ACI-004)

Docker Hub publication is **confirmed working** as of 2026-06-22.

| Item | Value |
|------|-------|
| Docker Hub repository | `taig2k/taig_service_portal_tsp` |
| Workflow | `.github/workflows/docker-publish.yml` |
| Trigger | Push to `deployable` branch or manual `workflow_dispatch` |
| Primary validation tag | `deployable` |
| Also published | `latest`, `sha-<commit>` |

**Validated publish run:** [GitHub Actions #4](https://github.com/the-ai-guy-2k/taig_service_portal_TSP/actions/runs/27975312056) — all jobs passed (build, publish, pull-validate).

### Automated publication (recommended)

Publication runs automatically via GitHub Actions when changes are pushed to the `deployable` branch.

**Workflow jobs:**

1. **Build & Validate Image** — builds image, runs container smoke tests
2. **Publish to Docker Hub** — authenticates via secrets, pushes tagged image
3. **Pull & Smoke Validate** — pulls `deployable` tag from Docker Hub, runs smoke tests

#### Required GitHub Secrets

Configure in repository **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username (`taig2k`) |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not password) |

Create a Docker Hub access token at: https://hub.docker.com/settings/security

> **Note:** `DOCKER_PUBLISH_ENABLED` variable was used during ACI-003 staging. As of ACI-004, publish runs automatically on `deployable` push when secrets are configured.

#### Published tags

On each successful `deployable` push:

| Tag | Description | Example |
|-----|-------------|---------|
| `latest` | Current production candidate | `taig2k/taig_service_portal_tsp:latest` |
| `deployable` | Release branch marker (used for pull validation) | `taig2k/taig_service_portal_tsp:deployable` |
| `sha-<commit>` | Git commit identifier | `taig2k/taig_service_portal_tsp:sha-d18370d` |

#### Pull command

```bash
docker pull taig2k/taig_service_portal_tsp:deployable
```

Or use `latest`:

```bash
docker pull taig2k/taig_service_portal_tsp:latest
```

#### Pull validation procedure

```bash
docker pull taig2k/taig_service_portal_tsp:deployable
docker run -d --name tsp -p 3000:3000 taig2k/taig_service_portal_tsp:deployable

# Health check
curl -f http://localhost:3000/health

# Route smoke test (from repository root)
npm run smoke-test

docker rm -f tsp
```

GitHub Actions performs equivalent pull validation automatically in the **Pull & Smoke Validate** job after each publish.

#### Manual trigger

1. Open **Actions → Docker Publish**
2. Click **Run workflow**
3. Optionally provide an additional tag
4. Run on `deployable` branch

### Manual publication (operator fallback)

```bash
docker login
docker build -t taig2k/taig_service_portal_tsp:local .
docker tag taig2k/taig_service_portal_tsp:local taig2k/taig_service_portal_tsp:latest
docker tag taig2k/taig_service_portal_tsp:local taig2k/taig_service_portal_tsp:deployable
docker push taig2k/taig_service_portal_tsp:latest
docker push taig2k/taig_service_portal_tsp:deployable
```

---

## 6. CI Validation

Every push and pull request to `main` or `deployable` triggers the CI workflow (`.github/workflows/ci.yml`):

1. **Build & Route Validation** — `npm ci`, syntax check, smoke tests
2. **Docker Build & Container Validation** — image build, container run, smoke tests

Verify CI status:

https://github.com/the-ai-guy-2k/taig_service_portal_TSP/actions

---

## 7. Deployment Sequence Summary

```
Clone (deployable)
    → npm ci
    → npm run validate
    → npm start & npm run smoke-test
    → docker build
    → docker run & npm run smoke-test
    → push to deployable (triggers Docker Hub publish)
    → deploy image to target environment
```

For AWS hosting options, see [aws_deployment_guide.md](./aws_deployment_guide.md).

---

## 8. Troubleshooting

| Issue | Resolution |
|-------|------------|
| `npm ci` fails | Ensure `package-lock.json` is present; use Node 20+ |
| Smoke test connection refused | Confirm app/container is running on expected port |
| Docker build fails | Verify Docker daemon is running; check Dockerfile context |
| Docker publish fails in CI | Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are set |
| Pull fails after publish | Allow 1–2 minutes for Docker Hub propagation; verify tag at hub.docker.com |
| Port 3000 in use | Set `PORT` env var or map a different host port |

---

## Related Documents

- [aws_deployment_guide.md](./aws_deployment_guide.md) — AWS hosting documentation
- [PA_validation_report.md](./PA_validation_report.md) — Production Artifact assessment
- [../aci_history/README.md](../aci_history/README.md) — ACI tracking
