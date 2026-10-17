# Azure Container Apps: public web, internal API

A public Nginx app served a static site and proxied requests to a FastAPI service with internal
ingress. Terraform defined the platform, and GitHub Actions built, deployed, and checked releases
using federated Azure authentication.

> **Completed lab; environment torn down.** The results below are historical tests with retained
> evidence. This documentation update does not represent a new deployment.

## How it fits together

![Container Apps overview: public HTTPS reaches Nginx, which proxies over verified HTTPS to internal API ingress with X-Api-Key. Direct browser calls to the API hostname stop at ingress with 404 before FastAPI. Containers listen on HTTP port 8080. Separate identities and conditional Reader roles authorize image pulls; GitHub Actions runs Terraform with Blob Storage state, and logs flow to Log Analytics.](docs/diagrams/platform-overview.svg)

- **Request path:** the browser uses the web origin for both the page and `/api/status`.
  Nginx adds `X-Api-Key` and verifies the API endpoint's TLS certificate. Managed ingress
  terminates HTTPS; containers listen on HTTP port 8080. A direct browser call to the API hostname
  is rejected by ingress with `404` before reaching FastAPI.
- **Image access:** each app uses a managed identity and a registry Reader role. Azure ABAC
  conditions check the repository name, limiting reads to `web` or `api`. The registry admin
  account is disabled; its endpoint is public.
- **Delivery and state:** Terraform changes receive a PR plan. Relevant merges queue deployment
  for approval, followed by image publication, apply, and smoke tests. Azure sign-in uses OIDC.
  Human-applied bootstrap owns permission grants; workload CI runs the platform root. Blob leases lock state.
- **Logs:** console and platform logs go to Log Analytics. Nginx records IPv4 `/24` prefixes;
  API request logs omit addresses, with Uvicorn access logging disabled.

The [architecture notes](docs/architecture.md) trace requests, identities, scaling, and delivery.
The [decision log](docs/decisions.md) explains the choices with links to Microsoft, Terraform,
and application documentation.

## What was verified

Selected historical results; each record identifies the test environment and release.

| Behavior checked | Observed result | Evidence |
| --- | --- | --- |
| Public proxy and internal ingress | `/api/status` returned `200` through the site; the API hostname returned an Azure-front-end `404` from outside the environment | [Ingress and proxy checks](docs/worklog/phase-10-internal-api-container-app.md#verification) |
| API key and upstream TLS | A local call bypassing the proxy returned `401` without the key; the Azure proxy path returned `200` with certificate verification enabled | [Key check](docs/worklog/phase-11-api-authentication-and-upstream-tls.md#authentication), [TLS](docs/worklog/phase-11-api-authentication-and-upstream-tls.md#upstream-tls) |
| Scale-out under load | The web app reached five replicas in about three minutes at 20 concurrent requests; no failed requests were observed in that test | [Scale test](docs/worklog/phase-13-scaling-and-release-mechanics.md#scale-test) |
| Routing and log privacy | Azure logs showed a missing asset returning `404` and truncated IPv4 addresses after the routing update | [Azure verification](docs/worklog/phase-08-web-routing-and-log-privacy.md#azure-verification) |
| Per-app image identities | Separate repository conditions replaced the shared registry-wide app reader; site and API returned `200` after migration | [Identity migration](docs/worklog/phase-16-per-app-pull-identities.md#result) |

## Limits that matter

- **Network scope:** API ingress is environment-scoped; there is no custom VNet integration.
  Other apps in that environment can reach the ingress and need the key for protected routes.
- **Service authentication:** public clients can use the proxy without a user login. The key
  authenticates the service call; `/health` is exempt from the check. The key exists in Terraform state.
- **Release discipline:** the pipeline avoids overwriting published tags; the registry does not
  lock them. Checkov and Trivy report without severity-based blocking. See
  [tags](docs/decisions.md#image-tags) and [scan enforcement](docs/decisions.md#security-scanning-enforcement).
- **Evidence scope:** post-migration health does not demonstrate cross-repository denial. Load
  results describe one run. Sentinel detection rules were not implemented.

## Find your way around

| To understand | Start here |
| --- | --- |
| Components, boundaries, and request flow | [Architecture](docs/architecture.md) |
| Build order and the evidence for each phase | [Documentation index](docs/README.md) |
| Why the design uses these controls | [Decisions](docs/decisions.md) |
| Failures, diagnoses, and fixes | [Troubleshooting](docs/troubleshooting.md) |
| Infrastructure and permission ownership | [Platform root](terraform/main.tf), [bootstrap root](terraform/bootstrap/state-backend/) |
| Delivery, plans, and scanning | [Workflows](.github/workflows/) |
| Local web-to-API composition | [Compose file](compose.yaml) |

Compose publishes only the web port and uses HTTP for the local upstream. It exercises the proxy
and key checks, while Azure ingress, TLS, and registry identity are covered by their own records.
