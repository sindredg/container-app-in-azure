# Phase 9: Internal API Container, Local

## Goal

Add a second service to the platform and prove the two-container topology locally before deploying it to Azure.

## Completed

- Built a FastAPI service on port `8080` with `/health` and `/status`.
- Made `/status` report the service name, version, and the Azure revision and replica values.
- Ran the API image as a non-root user on a slim Python base.
- Converted the web site config into a template so the API address is supplied at runtime.
- Added an `/api/` proxy so the browser calls the API from the website's own origin.
- Removed the client address before proxying, forwarding only the `/24` network.
- Ran both containers together with Docker Compose, publishing only the web port.

## Validated

- The API answered `/health` and `/status` directly during its own container test.
- `/api/status` through the web port returned the API's response.
- The four security headers and the version-free `server` header survived on proxied responses.
- A missing API path returned the API's own JSON `404`, not the website's HTML page.
- The access log kept the phase 8 privacy format across proxied requests.

![Only the web container publishes a port, the API is reachable only inside the network](../images/phase-09-compose-both-running.png)

![The API answers through the website's own origin](../images/phase-09-api-status-through-proxy.png)