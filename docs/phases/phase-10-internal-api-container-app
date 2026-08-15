# Phase 10: Internal API Container App

## Goal

Deploy the API to Azure with no public address, and reach it from the browser through the existing public website.

## Completed

- Deployed the API as a second Container App with internal ingress only.
- Reused the existing pull identity, so no second role assignment was needed.
- Passed the image tag through as `SERVICE_VERSION`, so the reported version cannot drift from the running image.
- Derived the web app's `API_UPSTREAM` from the API's own address in Terraform.
- Tagged both apps by component so they stay separable in cost and inventory views.
- Published `api:0.1.0` and `web:0.2.0`.

## Validated

- The API's own address returned `404` from outside the environment, confirming it is not publicly reachable.
- `/api/status` through the public website returned the API's real revision and replica names.
- The security headers and the version-free `server` header were present on proxied responses.
- Nothing was destroyed. The release applied in two steps, the second correcting an image tag that had not been raised alongside the code.

## Related decisions

- Reach the API through the web container's own origin rather than from the browser.
- Reuse the shared pull identity, leaving per-app identities as their own phase.
- Leave upstream TLS verification off until the certificate chain is checked.

## Not yet verified

- Upstream TLS verification is disabled, pending a check on whether the internal endpoint presents a chain the web container trusts.
- The five recon paths have not been re-run against the deployed site.

![The API's own address is not reachable from outside the environment](../images/phase-10-internal-fqdn-not-public.png)

![The API answers through the public site with its real Azure revision and replica](../images/phase-10-api-status-through-public-site.png)