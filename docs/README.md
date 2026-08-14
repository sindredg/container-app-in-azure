# Azure Container App Project Documentation

This directory contains concise documentation for the project.
The files focus on outcomes, validation, and useful evidence.

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

Both apps pull private images from ACR with managed identity.
Platform and application logs flow to Log Analytics.
```

The public web app is deployed. The internal API is the next milestone.

## Phase documentation

| Phase | Status | Result |
|---|---|---|
| [1. Repository and Terraform bootstrap](phases/phase-01-repository-and-terraform-bootstrap.md) | Complete | Git, GitHub, Terraform, and Azure provider workflow established. |
| [2. First Azure resource](phases/phase-02-first-azure-resource.md) | Complete | Development resource group deployed with Terraform. |
| [3. Container Apps environment](phases/phase-03-container-apps-environment.md) | Complete | Log Analytics and the shared Container Apps environment deployed. |
| [4. Registry and pull identity](phases/phase-04-registry-and-pull-identity.md) | Complete | Private ACR and read-only managed pull identity deployed. |
| [5. Remote Terraform state](phases/phase-05-remote-terraform-state.md) | Complete | Terraform state migrated to protected Azure Blob Storage. |
| [6. First web container](phases/phase-06-first-web-container.md) | Complete | Nginx image built and verified locally. |
| [7. Public web Container App](phases/phase-07-public-web-container-app.md) | Complete | Versioned image published and deployed through public HTTPS ingress. |

## Supporting logs

- [Decision log](decisions.md)
- [Troubleshooting log](troubleshooting.md)

## Current stack

- Terraform
- Azure Container Apps
- Azure Container Registry
- Managed identity
- Log Analytics
- Docker
- Nginx

## Documentation rule

Each phase records the goal, completed work, validation, and evidence.

Sensitive state, credentials, tokens, and saved Terraform plans are not included.
