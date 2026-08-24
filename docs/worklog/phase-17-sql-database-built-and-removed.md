# Phase 17 worklog: SQL Database, Built and Removed

## Goal

Give the platform a database. Azure SQL with Entra-only authentication, reached by the API through its managed identity rather than a connection string holding a password.

## Result

Built, verified, removed. Nothing had connected to it, and an endpoint with no consumer is attack surface without a purpose.

The attempt was worth more than the resource. It found a fault in the pipeline present since phase 12, killed a security design before it reached Azure, and surfaced two Azure behaviours that only appear at apply time.

## The plan check could not fail

A pull request showed Terraform failing while the check reported pass.

```yaml
terraform plan -input=false -no-color -out=tfplan | tee plan.txt
```

A pipeline reports the exit status of its last command. That is `tee`, which succeeds whenever it can write the file. Terraform's status was discarded before anything read it, and had been since the pipeline was built in phase 12.

It surfaced only because the database needed a variable with no default. Terraform stopped, the step wrote an empty plan, and the check went green. `set -o pipefail` fixed it.

No bad plan reached main. Every plan was also posted to its pull request and read by a person. The check was decoration, and decoration resembling a control is worse than no control.

## The firewall could not exist

The design was a public endpoint with the firewall pinned to the Container Apps egress address.

Checking that address first showed the environment's inbound static IP and its outbound address differ, so the rule would have blocked the API rather than admitting it.

The documentation settled it. Consumption plan outbound addresses are subject to change, and a fixed egress address needs VNet integration with a NAT gateway, which needs a workload profiles environment. The rule was not wrong, it was impossible. Pinned to any address it would work until Azure rotated that address, then fail with no warning.

The database went to Entra-only authentication with no SQL login, not even a disabled one. Administration ran from Cloud Shell, which is inside Azure and already covered by the Azure services rule, so no personal address was ever needed.

## Two failures a plan cannot predict

The first apply hit `ProvisioningDisabled`. This subscription cannot provision Azure SQL in norwayeast, westeurope, northeurope or uksouth. The capabilities API reports those regions as `Visible` rather than `Available`, meaning the region accepts the request and refuses at provisioning time.

The retry in `swedencentral` hit `InvalidResourceLocation`, claiming the server already existed in norwayeast. It did not. ARM returned 404, the resource list was empty, and state held nothing. What survived was a name to location binding, written when ARM accepted the first create and kept after provisioning refused it.

`checkNameAvailability` reported the name available before the first attempt, and again while the 409 was being raised. It answers for the global DNS namespace, not the per resource group registry.

Deriving the server name from its region cleared both. Details are in the [troubleshooting log](../troubleshooting.md).

## What was verified

| Property | Result |
|---|---|
| Location | `swedencentral`, state `Ready` |
| Entra-only authentication | `true` |
| Minimum TLS | 1.2 |
| Firewall rules | one, the Azure services rule |
| Audit policy | enabled, Azure Monitor target on |
| Diagnostic setting | `master` database, `SQLSecurityAuditEvents` |
| Database | online, serverless, auto-pause at 60 minutes |

The diagnostic setting matters for any future attempt. Server level audit events are delivered through `master`, not the server resource. Point it at the server and the policy applies cleanly and delivers nothing, failing in the direction that looks like success.

## Why it was removed

The API was never wired to it, so what existed was a public endpoint with no consumer. Keeping it would have meant carrying an unused component to justify the effort already spent. The effort is not lost, it is this page.

```text
Plan: 0 to add, 0 to change, 5 to destroy.
```

Two pipeline changes outlived it. A failing plan now fails its check, and the plan comment no longer publishes the subscription ID on a public repository.

## Notes

Three applies failed for three unrelated reasons, none of them a mistake in the configuration. All three were environmental.

Terraform validated, formatted, linted, scanned and planned cleanly throughout. That is the honest limit of a plan. It proves the configuration is coherent and that the provider will accept it. It cannot prove Azure will carry it out.
