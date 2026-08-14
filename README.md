# Azure Container App

A small container platform built on Azure Container Apps with Terraform.

The project follows a realistic engineering workflow using issues, feature branches, Terraform plans, pull requests, and infrastructure verification.

## Current status

The Azure platform foundation is deployed. The first web container has been built and tested locally.

| Component | Status |
|---|---|
| Resource group | Deployed |
| Log Analytics | Deployed |
| Container Apps environment | Deployed |
| Azure Container Registry | Deployed |
| Managed pull identity | Deployed |
| Web container | Built and tested locally |
| Public web Container App | Next |
| Internal API Container App | Planned |
| Microsoft Sentinel integration | Potential |

## Target architecture

```text
Internet
   |
   v
Public web Container App
   |
   | internal service discovery
   v
Internal API Container App

Both apps
   |
   +-> Azure Container Registry
   |      via managed identity
   |
   `-> Log Analytics
```

The web app will expose a public HTTPS endpoint. The API will use internal ingress and will not be directly accessible from the internet.

## Technology

- Terraform
- Azure Container Apps
- Azure Container Registry
- Managed identities
- Azure RBAC and ABAC
- Log Analytics
- Docker
- Nginx

## Repository structure

```text
container-app-in-azure/
|-- app/
|   `-- web/
|       |-- Dockerfile
|       |-- nginx.conf
|       |-- index.html
|       `-- styles.css
|-- terraform/
|   |-- identity.tf
|   |-- main.tf
|   |-- outputs.tf
|   |-- providers.tf
|   |-- registry.tf
|   |-- variables.tf
|   `-- versions.tf
`-- README.md
```

Terraform state is stored remotely in Azure Storage. Saved Terraform plans are stored locally under `terraform/plans/`. State and plan files are not committed to Git.

## Deployed infrastructure

Terraform currently manages:

```text
azurerm_resource_group.main
azurerm_log_analytics_workspace.main
azurerm_container_app_environment.main
azurerm_container_registry.main
azurerm_user_assigned_identity.container_pull
azurerm_role_assignment.container_pull
```

The registry uses ABAC repository permissions. Administrator credentials are disabled. The managed identity has read-only access to container images.

## Web container

The first container serves a static web page using Nginx on port `8080`.

It includes a `/health` endpoint and a Docker health check. The container has been built, started, and verified locally.

## Next milestone

Build the web image for `linux/amd64`, push a versioned image to Azure Container Registry, and deploy it as a public Azure Container App.