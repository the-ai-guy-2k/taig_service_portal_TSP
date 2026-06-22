# ACI-004 Completion Report — Docker Hub Publish Validation

**ACI:** ACI-004  
**Title:** Docker Hub Publish Validation  
**Status:** Completed  
**Date:** 2026-06-22

---

## 1. Summary of Work Performed

Validated end-to-end Docker Hub publication for TSP:

- Reviewed and improved `.github/workflows/docker-publish.yml`
- Removed `DOCKER_PUBLISH_ENABLED` gate so publish runs on every `deployable` push (secrets required)
- Added **Pull & Smoke Validate** job that pulls `deployable` tag from Docker Hub and runs smoke tests
- Triggered publish via push to `deployable` (commit `d18370d`)
- Confirmed image tags on Docker Hub
- Performed local `docker pull` and smoke test validation
- Updated deployment runbook and PA validation report with publication evidence

No new application features were introduced.

---

## 2. Workflow Changes

| Change | Rationale |
|--------|-----------|
| Removed `DOCKER_PUBLISH_ENABLED` variable gate | ACI-004 requires confirmed publish; secrets are configured |
| Added `pull-validate` job | Validates published image is pullable and runnable from Docker Hub |
| Added workflow outputs for tags | Clearer publish evidence in Actions logs |
| Optional `workflow_dispatch` tag input | Supports manual additional tags |

**Workflow review confirmed:**

- Runs on `deployable` branch push and `workflow_dispatch`
- Docker Hub login uses `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets only
- No hardcoded credentials
- Tags: `latest`, `deployable`, `sha-<commit>`

---

## 3. GitHub Actions Evidence

| Item | Value |
|------|-------|
| Workflow | Docker Publish |
| Run | [#4](https://github.com/the-ai-guy-2k/taig_service_portal_TSP/actions/runs/27975312056) |
| Branch | `deployable` |
| Commit | `d18370d6a29ade2c012edab7a5d15eb05e846eb5` |
| Result | **success** |

| Job | Result |
|-----|--------|
| Build & Validate Image | success |
| Publish to Docker Hub | success |
| Pull & Smoke Validate | success |

---

## 4. Docker Hub Publish Evidence

| Item | Value |
|------|-------|
| Repository | https://hub.docker.com/r/taig2k/taig_service_portal_tsp |
| Tags published | `latest`, `deployable`, `sha-d18370d` |
| Publish timestamp | 2026-06-22T18:35:36Z (approx.) |

---

## 5. Image Tag Published

**Primary validation tag:** `taig2k/taig_service_portal_tsp:deployable`

Additional tags from the same publish:

- `taig2k/taig_service_portal_tsp:latest`
- `taig2k/taig_service_portal_tsp:sha-d18370d`

**Image digest:** `sha256:a2add4621e7be108cb4fb0e9636177fd3bc8105f5a0e287e67cc40b014d7d9ab`

---

## 6. Pull Validation Evidence

### GitHub Actions (pull-validate job)

```
docker pull taig2k/taig_service_portal_tsp:deployable
```

Job result: **success**

### Local validation

```
docker pull taig2k/taig_service_portal_tsp:deployable
Status: Downloaded newer image for taig2k/taig_service_portal_tsp:deployable
```

---

## 7. Smoke Test Evidence

### GitHub Actions pull-validate job

- Health check: `curl -f http://localhost:3000/health` — success
- Route smoke test: `node scripts/smoke-test.js` — 6/6 passed

### Local validation (pulled image)

```
PASS [Health endpoint] /health
PASS [Home page] /
PASS [Home Nebula section] /
PASS [About page] /about
PASS [Services page] /services
PASS [Contact page] /contact

All 6 smoke tests passed.
```

---

## 8. Risks Discovered

| Risk | Severity | Notes |
|------|----------|-------|
| Docker Hub propagation delay | Low | Allow brief delay between publish and pull in manual workflows |
| Secrets rotation | Low | Document token rotation in Docker Hub settings |
| Public image visibility | Low | Repository is public on Docker Hub; acceptable for MVP marketing site |

---

## 9. PA Status Recommendation

**PA status reaffirmed — APPROVE**

ACI-004 closes the Docker Hub publication evidence gap identified after ACI-003. TSP is now a fully validated Production Artifact with confirmed container registry publication and pull validation.

---

## 10. Commit ID(s)

| Commit | Description |
|--------|-------------|
| `d18370d6a29ade2c012edab7a5d15eb05e846eb5` | Enable publish + pull-validate workflow |
| _pending_ | Documentation and ACI-004 completion report |
