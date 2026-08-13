# Container Scale Lab

A small container platform built on Azure Container Apps with Terraform.

The project follows a realistic engineering workflow using issues, feature branches, reviewed Terraform plans, pull requests, and infrastructure verification.

## Current status

The Azure platform foundation is deployed.

| Component | Status |
|---|---|
| Resource group | Deployed |
| Log Analytics | Deployed |
| Container Apps environment | Deployed |
| Azure Container Registry | Deployed |
| Managed pull identity | Deployed |
| Public web Container App | Next |
| Internal API Container App | Planned |
| Microsoft Sentinel Integration | Potentially |

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

The web app will expose an HTTPS endpoint. The API will use internal ingress and will not be directly accessible from the internet.

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

Saved Terraform plans are stored locally under `terraform/plans/`. Plan files and Terraform state are not committed to Git.

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

The registry uses ABAC repository permissions. Administrator credentials are disabled. The runtime identity has read-only repository access.

## Terraform workflow

From the `terraform/` directory:

```bash
terraform fmt
terraform validate
terraform plan -out=plans/change.tfplan
terraform apply plans/change.tfplan
terraform plan
```

A final plan should report:

```text
No changes. Your infrastructure matches the configuration.
```

## Next milestone

Build and test the first web container locally, push a versioned image to Azure Container Registry, and deploy it as a public Azure Container App.

