# Documentation

How the platform was built, why it was built that way, and what was verified.

## Phases

Each phase page is a summary: goal, what was completed, what was validated, and what was left open.

| Phase | Result |
|---|---|
| [1. Repository and Terraform bootstrap](phases/phase-01-repository-and-terraform-bootstrap.md) | Git, GitHub, Terraform, and the Azure provider workflow established. |
| [2. First Azure resource](phases/phase-02-first-azure-resource.md) | Development resource group deployed with Terraform. |
| [3. Container Apps environment](phases/phase-03-container-apps-environment.md) | Log Analytics and the shared Container Apps environment deployed. |
| [4. Registry and pull identity](phases/phase-04-registry-and-pull-identity.md) | Private registry and read-only managed pull identity deployed. |
| [5. Remote Terraform state](phases/phase-05-remote-terraform-state.md) | State migrated to protected Azure Blob Storage. |
| [6. First web container](phases/phase-06-first-web-container.md) | Nginx image built and verified locally. |
| [7. Public web Container App](phases/phase-07-public-web-container-app.md) | Versioned image deployed through public HTTPS ingress. |
| [8. Routing, hardening, and log privacy](phases/phase-08-web-routing-and-log-privacy.md) | Real `404` responses, protective headers, network-level request logging. |
| [9. Internal API container](phases/phase-09-internal-api-container-local.md) | API service and same-origin proxy built and verified locally. |
| [10. Internal API Container App](phases/phase-10-internal-api-container-app.md) | API deployed behind internal ingress, reached through the public site. |
| [11. API authentication and upstream TLS](phases/phase-11-api-authentication-and-upstream-tls.md) | Shared secret between proxy and API, verified upstream certificate, schema closed. |
| [12. GitHub Actions pipeline](phases/phase-12-github-actions-pipeline.md) | Plan on every pull request, gated deploy with build, apply, and smoke test. |
| [13. Scaling and release mechanics](phases/phase-13-scaling-and-release-mechanics.md) | Scale test to five replicas, and rollback by traffic weight. |
| [14. Supply chain scanning](phases/phase-14-supply-chain-scanning.md) | Image and Terraform scanning on every pull request, dependencies brought current. |
| [15. Terraform module migration](phases/phase-15-terraform-module-migration.md) | Configuration split into modules, provider upgraded to 5.x. |
| [16. Per-app pull identities](phases/phase-16-per-app-pull-identities.md) | One registry identity per app, each scoped to a single repository. |

## Worklog

The phase pages say what happened. The worklog says how it went, step by step, with the screenshot behind every claim, including the parts that went wrong.

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
| 9 | [Internal API container](worklog/phase-09-internal-api-container-local.md) |
| 10 | [Internal API Container App](worklog/phase-10-internal-api-container-app.md) |
| 11 | [API authentication and upstream TLS](worklog/phase-11-api-authentication-and-upstream-tls.md) |
| 12 | [GitHub Actions pipeline](worklog/phase-12-github-actions-pipeline.md) |
| 13 | [Scaling and release mechanics](worklog/phase-13-scaling-and-release-mechanics.md) |
| 14 | [Supply chain scanning](worklog/phase-14-supply-chain-scanning.md) |
| 15 | [Terraform module migration](worklog/phase-15-terraform-module-migration.md) |
| 16 | [Per-app pull identities](worklog/phase-16-per-app-pull-identities.md) |

## Supporting logs

- [Decision log](decisions.md) lists every significant choice, with the alternative that was rejected
- [Troubleshooting log](troubleshooting.md) records what broke, why, and what fixed it
- [Validation and testing](validation-testing/README.md) covers operational tests against the deployed platform
