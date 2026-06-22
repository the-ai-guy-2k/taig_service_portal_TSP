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

### Automated publication (recommended)

Publication runs automatically via GitHub Actions when changes are pushed to the `deployable` branch.

**Workflow file:** `.github/workflows/docker-publish.yml`

#### Enable automated publishing

1. Configure secrets (above)
2. Set repository variable **`DOCKER_PUBLISH_ENABLED`** to `true` in **Settings → Secrets and variables → Actions → Variables**

Publishing is skipped when this variable is not `true`, allowing workflow validation without credentials.

#### Required GitHub Secrets

Configure in repository **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username (`taig2k`) |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not password) |

#### Required repository variable

| Variable | Value | Purpose |
|----------|-------|---------|
| `DOCKER_PUBLISH_ENABLED` | `true` | Enables push job after secrets are configured |

Create a Docker Hub access token at: https://hub.docker.com/settings/security

#### Published tags

On each successful `deployable` push:

| Tag | Description |
|-----|-------------|
| `latest` | Current production candidate |
| `deployable` | Release branch marker |
| `<short-sha>` | Git commit identifier |

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
| Docker publish fails in CI | Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets |
| Port 3000 in use | Set `PORT` env var or map a different host port |

---

## Related Documents

- [aws_deployment_guide.md](./aws_deployment_guide.md) — AWS hosting documentation
- [PA_validation_report.md](./PA_validation_report.md) — Production Artifact assessment
- [../aci_history/README.md](../aci_history/README.md) — ACI tracking
