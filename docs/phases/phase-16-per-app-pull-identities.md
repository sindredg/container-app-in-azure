# Phase 16: Per-App Pull Identities

## Goal

Replace one shared registry identity with one per application, each able to read only the repository it runs.

## Completed

- Created a pull identity per application, scoped by an ABAC condition to a single repository.
- Moved the identities and their grants to the bootstrap root, which only a human applies.
- Attached each application to its own identity.
- Removed the shared identity and its registry-wide grant.

## Validated

- Each identity can read one repository and no others.
- No registry-wide reader remains on the registry.
- Both roots plan with no changes, and the site and API return `200`.

## What the pipeline could not do

The first attempt placed the grants where the pipeline applies them, and failed with a 403 on `roleAssignments/write`. The CI identity holds Contributor, which excludes managing role assignments.

That is deliberate. The pipeline can already delete everything in the resource group, so this is not about limiting damage. Destruction is loud and rebuildable from code. A quiet grant of access is neither.

![Three identities once the per-app ones exist](../images/phase-16-identities-after.png)

![The API answers through the public site](../images/phase-16-api-through-own-identity.png)

The result is two apply paths with different trust levels. Workload changes deploy automatically. Identity and permission changes need a person, and always will.
