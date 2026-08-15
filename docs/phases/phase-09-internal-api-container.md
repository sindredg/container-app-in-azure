# Phase 9: Internal API Container

## Goal

Build the second service as a container, give it a JSON contract the web tier can render, and prove the web-to-API path locally before any of it reaches Azure.

The split follows phases 6 and 7, where the web container was built and verified locally before it was deployed.

## Completed

- Added a FastAPI service on port `8080` with `/health` and `/status`, matching the web container so Docker, ingress, and the probes share one port and one path.
- Returned the platform identity in `/status` from `CONTAINER_APP_NAME`, `CONTAINER_APP_REVISION`, and `CONTAINER_APP_REPLICA_NAME`, defaulting to `local` so the same image runs under Docker.
- Disabled the interactive API documentation, whose assets load from a public CDN the site's Content Security Policy forbids. The OpenAPI schema is still served.
- Ran Uvicorn with `--no-access-log` and logged method, path, status, and duration from middleware instead, so no caller address is recorded.
- Ran the API as a non-root user, which the Nginx base image already provides for the web container.
- Converted `nginx.conf` to `default.conf.template`, processed by `envsubst` at container start, so the API address is injected per environment rather than baked into an immutable image.
- Restricted substitution with `NGINX_ENVSUBST_FILTER=^API_`, which protects `$uri`, `$status`, and the privacy log format.
- Added an `/api/` proxy location that publishes the API on the site's own origin.
- Removed `X-Forwarded-For` at the proxy and passed the already-truncated `/24` network as `X-Client-Network`.
- Added `app.js` as its own file, since the Content Security Policy allows no inline script, to render the API card from `/api/status`.
- Added `compose.yaml`, where the API publishes no ports and the web container waits on the API's health check.

## Validated

- Both images built, and both containers reported healthy.
- `/health` returned `200`, and `/status` returned the contract with `local` platform values.
- Through the proxy, `/api/status` returned the API's JSON and `/api/nothing` returned the API's own `404`, confirming the `/api/` prefix is stripped correctly.
- `/api/status` carried all four protective response headers, so the server-level directives still reach proxied responses.
- The same response reported `Server: nginx` rather than `Server: uvicorn`, so the upstream server name does not leak and phase 8's version suppression still holds.
- The API log recorded method, path, status, and duration with no address, while the web log recorded the truncated network.

## Related decisions

- Use FastAPI for the internal API runtime.
- Reach the API through the web container's own origin rather than calling it from the browser.
- Remove the client address at the proxy and forward only the truncated network.
- Disable the interactive API documentation so the Content Security Policy needs no exception.
- Inject the API address at container start rather than baking it into the image.

## Not yet verified

- The API card has not been recorded rendering in a browser; the path was confirmed with `curl`.
- `proxy_ssl_verify` is off. Whether the internal Container Apps FQDN presents a publicly trusted certificate chain is settled during deployment.
- `HEAD /status` returns `405`, because FastAPI registers `GET` only and does not add `HEAD` automatically. Harmless for the browser and the probes, but it means `curl -I` is not a usable header check.
- Nothing from this phase is deployed. Phase 10 covers the internal Container App, ingress, and Azure validation.
