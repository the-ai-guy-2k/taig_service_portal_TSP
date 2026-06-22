# TAIG Service Portal (TSP)

Production Artifact for the TAIG Service Portal — a public-facing web application for The AI Guy (TAIG) service operations.

## Project Purpose

TSP is the central web platform for The AI Guy (TAIG). It presents TAIG services, philosophy, and contact information to visitors. The repository is certified as a **Production Artifact (PA)** for its MVP scope.

## Current State

| Phase | Status |
|-------|--------|
| ACI-001 Foundation | Complete |
| ACI-002 MVP Website | Complete |
| ACI-003 DevOps to PA | Complete — **PA Approved** |

**MVP includes:** Home, About, Services, Contact pages; shared navigation and branding; Nebula overview; contact form UI (no backend).

## MVP Scope (Delivered)

- Public-facing landing and informational pages
- Service descriptions and Nebula content
- Contact form UI
- Containerized deployment with CI/CD validation
- Docker Hub publishing from `deployable` branch

## Out Of Scope

Deferred to future work:

- Contact form backend processing
- Client authentication and portal access
- Support ticketing and billing integration
- Database integration
- Production AWS deployment (documented, not provisioned)
- AI features

## Local Development Instructions

### Prerequisites

- [Node.js](https://nodejs.org/) 20 or later
- [npm](https://www.npmjs.com/) (included with Node.js)

### Install and run

```bash
git clone https://github.com/the-ai-guy-2k/taig_service_portal_TSP.git
cd taig_service_portal_TSP
npm ci
npm start
```

The application listens on `http://localhost:3000` by default.

### Validation

```bash
npm run validate
npm start &
npm run smoke-test
```

### Docker

```bash
docker build -t taig2k/taig_service_portal_tsp:local .
docker run -p 3000:3000 taig2k/taig_service_portal_tsp:local
```

## Deployment Philosophy

- **Branch model:** The `deployable` branch is the release candidate branch for production deployments.
- **Container-first:** All environments run the same Docker image (`taig2k/taig_service_portal_tsp:<tag>`).
- **CI-gated:** GitHub Actions validates build, routes, and Docker image on every push and pull request.
- **Automated publish:** Pushes to `deployable` trigger Docker Hub publication via GitHub Actions secrets.
- **ACI-driven:** Work is scoped, tracked, and completed via ACI with completion reports in `/docs/reports`.

## Deployment Documentation

| Document | Purpose |
|----------|---------|
| [deployment_runbook.md](docs/reports/deployment_runbook.md) | Clone, build, validate, Docker, publish |
| [aws_deployment_guide.md](docs/reports/aws_deployment_guide.md) | AWS S3, CloudFront, deployment sequence |
| [PA_validation_report.md](docs/reports/PA_validation_report.md) | Production Artifact certification |

## Future Expansion Direction

1. Contact form backend and integrations
2. Authentication, client portal, ticketing, billing
3. AWS infrastructure provisioning per deployment guide
4. AI-powered features

## Repository Structure

```
/docs/aci_history   — ACI tracking and governance
/docs/reports       — Completion reports, runbooks, PA validation
/scripts            — Operational validation scripts
/src                — Application source
/.github/workflows  — CI and Docker publish pipelines
```

## License

Private — The AI Guy (TAIG). All rights reserved.
