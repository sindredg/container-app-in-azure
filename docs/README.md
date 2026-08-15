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

The public web app is deployed. The internal API is built and verified locally; deploying it is the next milestone.

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
| [8. Routing, hardening, and log privacy](phases/phase-08-web-routing-and-log-privacy.md) | Complete | Real `404` responses, protective headers, and network-level request logging. |
| [9. Internal API container](phases/phase-09-internal-api-container.md) | Complete | FastAPI service and same-origin web proxy built and verified locally. |

## Worklog

The phase pages above are summaries. The worklog records how each phase actually went, step by step, with the screenshot evidence behind every claim.

| Phase | Worklog |
|---|---|
| 1 | [Repository and Terraform bootstrap](worklog/phase-01-repository-and-terraform-bootstrap.md) |
| 2 | [First Azure resource](worklog/phase-02-first-azure-resource.md) |
| 3 | [Container Apps environment](worklog/phase-03-container-apps-environment.md) |
| 4 | [Registry and pull identity](worklog/phase-04-registry-and-pull-identity.md) |
| 5 | [Remote Terraform state](worklog/phase-05-remote-terraform-state.md) |
| 6 | [First web container](worklog/phase-06-first-web-container.md) |
| 7 | [Public web Container App](worklog/phase-07-public-web-container-app.md) |
| 8 | [Routing, hardening, and log privacy](worklog/phase-08-web-routing-and-log-privacy.md) |

## Supporting logs

- [Decision log](decisions.md)
- [Troubleshooting log](troubleshooting.md)
- [Validation and testing](validation-testing/README.md)

## Current stack

- Terraform
- Azure Container Apps
- Azure Container Registry
- Managed identity
- Log Analytics
- Docker
- Nginx
- Python and FastAPI
