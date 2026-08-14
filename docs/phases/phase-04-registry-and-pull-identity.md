# Phase 4: Registry and Pull Identity

## Goal

Create private image storage and password-free runtime pulls.

## Completed

- Deployed a Basic Azure Container Registry.
- Disabled registry administrator credentials.
- Enabled ABAC repository permissions.
- Created a user-assigned managed identity.
- Granted `Container Registry Repository Reader` at registry scope.

## Validated

- Terraform added the registry, identity, and role assignment.
- Registry security settings matched the design.
- The runtime identity had read-only repository access.
- A final plan reported no changes.

![Private ACR security settings](../images/phase-04-acr-security.png)
