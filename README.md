# Cloud Operations Lab | Azure Container Apps & Terraform

An ongoing cloud engineering project for building, deploying, and validating container workloads on Azure.

The project covers infrastructure as code, private image delivery, managed identity, health probes, revisions, scaling, and observability through a documented Git, Terraform, testing, and troubleshooting workflow.

## Live site

[Open the Cloud Operations Lab](https://ca-container-scale-lab-web-dev.graysand-e63d8c5e.norwayeast.azurecontainerapps.io/)

[Health endpoint](https://ca-container-scale-lab-web-dev.graysand-e63d8c5e.norwayeast.azurecontainerapps.io/health)

> **Availability note:** This is a personal lab environment. The site may be temporarily unavailable during deployments, maintenance, or Azure cost-control cleanup. After inactivity, the first request may take a few seconds while the application scales from zero.

## Current status

| Component | Status |
|---|---|
| Resource group | Deployed |
| Log Analytics | Deployed |
| Container Apps environment | Deployed |
| Azure Container Registry | Deployed |
| Managed pull identity | Deployed |
| Public web Container App | Deployed |
| Internal API Container App | Planned |

## Architecture

```text
Internet
   |
   | HTTPS
   v
Public web Container App
   |
   | internal service discovery
   v
Internal API Container App
   Planned

Private Azure Container Registry
   |
   | managed identity
   v
Azure Container Apps
```

The web application uses external ingress. The future API will use internal ingress and will not be directly accessible from the internet.

## Implementation

The deployed web application uses:

- Nginx on port `8080`
- `/health` for health checks
- Startup, readiness, and liveness probes
- Immutable image tag `0.1.1`
- `linux/amd64` container image
- Managed identity for private ACR pulls
- Single revision mode
- Zero-to-one replica scaling
- Azure-managed HTTPS ingress

Terraform state is stored remotely in protected Azure Blob Storage.

## Technology

- Terraform
- Azure Container Apps
- Azure Container Registry
- Managed identity
- Log Analytics
- Docker
- Nginx
- HTML and CSS

## Repository structure

```text
container-app-in-azure/
|-- app/
|   `-- web/
|       |-- .dockerignore
|       |-- Dockerfile
|       |-- index.html
|       |-- nginx.conf
|       `-- styles.css
|-- docs/
|   |-- phases/
|   |-- images/
|   |-- decisions.md
|   |-- troubleshooting.md
|   `-- README.md
|-- terraform/
|   |-- bootstrap/
|   |-- identity.tf
|   |-- main.tf
|   |-- outputs.tf
|   |-- providers.tf
|   |-- registry.tf
|   |-- variables.tf
|   |-- versions.tf
|   `-- web-container-app.tf
|-- .gitignore
`-- README.md
```

Saved Terraform plans, local Terraform data, and state files are not committed.

## Documentation

Detailed project evidence is available under [`docs/`](docs/README.md).

The documentation includes:

- Phase summaries
- Architecture and implementation decisions
- Validation evidence
- Troubleshooting records
- Selected screenshots

## Validation

The deployment has been verified through:

- Terraform formatting and validation
- Reviewed Terraform plans
- Final no-change Terraform plan
- ACR image manifest inspection
- Public website HTTP checks
- Public health endpoint checks
- Container Apps revision health
- Managed-identity image pulls

## Next milestone

Build and deploy an internal API as a separate Container App with independent scaling and internal ingress.
