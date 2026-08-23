# Phase 15: Terraform Module Migration

## Goal

Restructure a flat Terraform root into modules grouped by capability, then bring the provider to 5.x.

## Completed

- Split the configuration into `platform`, `registry`, `web-app`, and `api-app`.
- Used `moved` blocks so changing every resource address did not destroy and recreate the registry.
- Kept the shared secret at the root, since both applications hold it.
- Kept the two apps as separate modules rather than one generic module used twice.
- Upgraded both Terraform roots from AzureRM 4.x to 5.x.
- Added a concurrency group so workflow runs queue instead of racing for the state lock.

## Validated

- The refactor planned as address moves only. Running plan on the unchanged branch produced the same single unrelated drift, proving the restructure contributed nothing else.
- The registry survived with every published image.
- Both roots plan with no changes under the new provider.
- The pipeline runs green end to end.

## What the plan could not show

The provider upgrade planned clean and still broke the pipeline. State written by the old provider carried an attribute the new schema had removed. `plan` tolerated it because it refreshes from Azure, while the step that reads state directly did not.

A clean plan is evidence about infrastructure, not about every code path around it. Recorded in the troubleshooting log.

![The pipeline runs green after the fixes](../images/phase-15-pipeline-green.png)
