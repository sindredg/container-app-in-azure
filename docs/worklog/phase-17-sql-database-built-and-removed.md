# Phase 17 worklog: SQL Database, Built and Removed

## Goal

Give the platform a database. Azure SQL with Entra-only authentication, reached by the API through its managed identity rather than a connection string holding a password.

## Result

It was built, it worked, and it was removed. Nothing had connected to it, and an endpoint with no consumer is attack surface without a purpose.

The attempt was worth more than the resource. It found a fault in the pipeline that had been present since the pipeline was built, killed a security design before it reached Azure, and surfaced two Azure behaviours that only appear at apply time.

## The plan check had been reporting success on failing plans

The first sign was a pull request where Terraform failed and the check went green.

```yaml
terraform plan -input=false -no-color -out=tfplan | tee plan.txt
echo "exitcode=$?" >> "$GITHUB_OUTPUT"
```

A pipeline reports the exit status of the last command in it. That is `tee`, which succeeds whenever it can write the file. Terraform's exit status was discarded before anything looked at it.

This had been true since the pipeline was built in phase 12. Every pull request from then until now had its plan checked by something that could not fail.

It surfaced only because the new database needed a variable with no default. Terraform stopped with `No value for required variable`, the step wrote an empty plan, and the check reported pass. Without a change that made the plan fail outright, there was no reason to look.

```yaml
set -o pipefail
terraform plan -input=false -no-color -out=tfplan | tee plan.txt
```

The `exitcode` output went with it. Nothing read it, and its presence suggested the exit status was being handled.

Worth stating plainly: no bad plan was merged because of this. Every plan in those phases was also read by a human in the pull request comment. The check was decoration, and decoration that looks like a control is worse than no control.

## The firewall could not exist

The design was a public database endpoint with a firewall pinned to the Container Apps egress address, so only the platform could reach it.

Checking the address before applying it produced the first problem. The environment's inbound static IP and its actual outbound address are different, so the rule as written would have blocked the API rather than admitting it.

The documentation produced the second and larger one. Outbound addresses on the Consumption plan are documented as subject to change, and a fixed egress address requires VNet integration with a NAT gateway, which requires a workload profiles environment. This platform has neither.

So the rule was not merely wrong, it could not be made right. Pinned to any address, it would work until Azure rotated the address and then fail with no warning. A control that expires silently is worse than an absent one, because the absent one is visible.

The database went to Entra-only authentication with no SQL login at all. Not a disabled one, none. There is no password to leak or rotate, and reaching the endpoint without an Entra identity holding a contained user achieves nothing.

Administration ran from Cloud Shell, which is inside Azure and therefore already covered by the Azure services rule. That removed the last reason to put a personal address into a public repository.

## A region that accepts requests it will not honour

The first apply failed.

```text
Status: "ProvisioningDisabled"
Message: "Provisioning is restricted in this region. Please choose a different region."
```

The subscription is not permitted to provision Azure SQL in norwayeast, nor in westeurope, northeurope or uksouth.

The capabilities API explains why the plan passed:

```text
az rest --method get --url ".../providers/Microsoft.Sql/locations/<region>/capabilities?api-version=2023-08-01"
```

It reports norwayeast as `Visible` rather than `Available`, and its `reason` string is word for word the message the apply failed with. `Visible` means the region appears, accepts the request, and refuses at provisioning time. A plan cannot see it. Only an apply can.

`swedencentral` reported `Available`, and `GP_S_Gen5_1` was confirmed there specifically rather than assumed, so the move did not force a change of tier.

That made the database the only resource outside the platform region, which is why the region became its own variable rather than an inherited value.

## A name bound to a region where nothing was created

The retry in swedencentral failed too.

```text
InvalidResourceLocation: The resource 'sql-container-scale-lab-dev' already exists
in location 'norwayeast' in resource group 'rg-container-scale-lab-dev'.
```

Nothing existed in norwayeast. ARM returned 404 for the resource, `az resource list` returned an empty array, the SQL provider listed nothing, and Terraform state held no database resources.

What survived was a name to location binding in the resource group scoped registry, written when ARM accepted the create and kept after provisioning refused it. The resource never existed. The reservation of its name did.

The check that should have caught this did not. `checkNameAvailability` returned `available: true` before the first attempt, and returned `available: true` while the 409 was being raised. It answers for the global DNS namespace that SQL server names live in. `InvalidResourceLocation` comes from the per resource group registry. Two systems, and a pass from one says nothing about the other.

The fix was to derive the server name from the region:

```text
sql-container-scale-lab-swedencentral-dev
```

That cleared the block and stops it recurring, because a future region change now produces a new name rather than meeting whatever binding the last region left behind.

## What was verified before it was removed

The deployed server was checked rather than assumed.

| Property | Result |
|---|---|
| Location | `swedencentral`, state `Ready` |
| Entra-only authentication | `true` |
| Minimum TLS | 1.2 |
| Firewall rules | one, the Azure services rule |
| Audit policy | enabled, Azure Monitor target on |
| Diagnostic setting | on the `master` database, `SQLSecurityAuditEvents` |
| Database | online, serverless, auto-pause at 60 minutes |

The diagnostic setting is the part worth keeping in mind for any future attempt. Server level audit events are delivered through the `master` database rather than the server resource. Point the setting at the server and the audit policy applies cleanly and delivers nothing at all, which fails in the direction that looks like success.

## Why it was removed

The API was never wired to it. What existed was a public endpoint with no consumer, and the shortest defensible description of an unused public endpoint is attack surface.

Keeping it would have meant carrying an unused component to justify the effort already spent on it. The effort is not lost, it is this page.

```text
Plan: 0 to add, 0 to change, 5 to destroy.
```

## What outlived the database

Two changes to the pipeline stay, and both improve every phase that follows:

- A failing plan now fails its check.
- The plan comment no longer publishes the subscription ID, which had appeared in cleartext in every plan comment on a public repository while being blacked out of every screenshot.

## Notes

Three applies failed for three unrelated reasons, none of them a mistake in the configuration. Every one was environmental: a subscription restriction, a regional refusal, and a stale ARM record.

Terraform validated, formatted, linted, scanned and planned cleanly through all three. That is the honest limit of a plan. It proves the configuration is coherent and that the provider will accept it. It cannot prove Azure will carry it out.
