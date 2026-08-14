# Azure Container Platform

An ongoing cloud engineering project for building, deploying, securing, operating, and validating container workloads on Azure.

The platform is built with Terraform and follows a documented workflow covering infrastructure changes, container releases, managed identity, health checks, revisions, observability, testing, and troubleshooting.

## Live environment

[Open Sindre's Cloud Operations Lab](https://ca-container-scale-lab-web-dev.graysand-e63d8c5e.norwayeast.azurecontainerapps.io/)

> This is a development environment. The application may be unavailable during updates, testing, scale-to-zero periods, or cost-control shutdowns.

## Current status

| Component | Status |
|---|---|
| Resource group | Deployed |
| Log Analytics | Deployed |
| Container Apps environment | Deployed |
| Azure Container Registry | Deployed |
| Managed pull identity | Deployed |
| Public web Container App | Deployed |
| Operational validation | In progress |
| Internal API Container App | Planned |
| Scaling and alerting tests | Next |
| Microsoft Sentinel integration | Potential |

## Architecture

```text
Internet
   |
   v
Public web Container App
   |
   | internal service discovery
   v
Internal API Container App

Both applications
   |
   +-> Private Azure Container Registry
   |      through managed identity
   |
   `-> Log Analytics
```

The public web application uses Azure-managed HTTPS ingress. The planned API will use internal ingress and will not be directly accessible from the internet.

## Technology

- Terraform
- Azure Container Apps
- Azure Container Registry
- Managed identity
- Azure RBAC and ABAC
- Log Analytics
- Docker
- Nginx

## Current deployment

The public application runs as an Nginx container using:

- Immutable image tag `web:0.1.1`
- Linux AMD64 image
- Private ACR delivery
- Password-free managed identity pulls
- Startup, readiness, and liveness probes
- Scale range from zero to one replica
- Azure-managed HTTPS
- Remote Terraform state with locking and recovery controls

## Validation

The deployed application has been validated through:

- Public HTTPS and health requests
- Container revision health
- Scale from zero to one replica
- Private image retrieval
- Application and platform logs
- Log Analytics request correlation
- Negative-path testing
- Terraform drift checks

Validation evidence, implementation phases, decisions, and troubleshooting records are available under [`docs/`](docs/README.md).

## Repository structure

```text
container-app-in-azure/
|-- app/
|   `-- web/
|-- docs/
|   |-- images/
|   |-- phases/
|   `-- validation-testing/
|-- terraform/
`-- README.md
```

Terraform state and saved plan files are not committed to Git.

## Next milestone

Correct or explicitly accept the missing-route response behavior, validate Azure Monitor metrics and horizontal scaling, then deploy an internal API Container App.