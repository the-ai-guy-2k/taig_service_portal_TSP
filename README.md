# TAIG Service Portal (TSP)

Deployable foundation for the TAIG Service Portal — a web application for TAIG client-facing services, support, and portal capabilities.

## Project Purpose

TSP is the central web platform for The AI Guy (TAIG) service operations. This repository provides the structural, operational, and deployment foundation upon which MVP features will be built in subsequent ACIs.

## MVP Scope

Future MVP work (not yet implemented) will include:

- Public-facing landing and informational pages
- Service descriptions and Nebula content
- Contact form
- Client authentication and portal access
- Support ticketing and billing integration

**Current state (ACI-001):** Minimal application shell with a placeholder home page, health endpoint, containerization, and CI validation only.

## Out Of Scope (ACI-001)

The following are explicitly deferred to future ACIs:

- Landing page design and production content
- About, services, and Nebula pages
- Contact form logic
- Authentication, ticketing, billing, and client portal
- Database integration
- AWS, CloudFront, and S3 deployment

## Local Development Instructions

### Prerequisites

- [Node.js](https://nodejs.org/) 20 or later
- [npm](https://www.npmjs.com/) (included with Node.js)

### Install and run

```bash
git clone https://github.com/the-ai-guy-2k/taig_service_portal_TSP.git
cd taig_service_portal_TSP
npm install
npm start
```

The application listens on `http://localhost:3000` by default. Override the port with the `PORT` environment variable.

### Development mode

```bash
npm run dev
```

Runs the server with Node's `--watch` flag for automatic restarts on file changes.

### Health check

```bash
curl http://localhost:3000/health
```

Expected response: `{"status":"ok"}`

### Docker

Docker image builds are validated in GitHub Actions. To build locally (optional):

```bash
docker build -t taig2k/taig_service_portal_tsp:local .
docker run -p 3000:3000 taig2k/taig_service_portal_tsp:local
```

## Deployment Philosophy

- **Branch model:** The `deployable` branch is the release candidate branch for production deployments.
- **Container-first:** All environments run the same Docker image (`taig2k/taig_service_portal_tsp:<tag>`).
- **CI-gated:** GitHub Actions validates repository structure, build integrity, and Docker image builds on every push and pull request.
- **ACI-driven:** Work is scoped, tracked, and completed via ACI (Approved Change Instructions) with completion reports in `/docs/reports`.
- **Incremental delivery:** Foundation first, then MVP features, then infrastructure — each ACI produces a verifiable, deployable increment.

## Future Expansion Direction

Planned evolution of this repository:

1. **ACI-002+** — Public site content, layout, and branding
2. **Subsequent ACIs** — Authentication, client portal, ticketing, billing
3. **Infrastructure ACIs** — AWS deployment pipeline targeting the `deployable` branch

The `src/` directory will grow to accommodate routes, views, API handlers, and shared modules as features are added.

## Repository Structure

```
/docs/aci_history   — ACI tracking and governance
/docs/reports       — ACI completion reports
/src                — Application source
/.github/workflows  — CI pipelines
```

## License

Private — The AI Guy (TAIG). All rights reserved.
