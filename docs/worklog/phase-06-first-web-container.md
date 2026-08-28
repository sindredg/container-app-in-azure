# Phase 6 worklog: First Web Container

## Goal

Build and test the first application image locally with Docker through WSL, before anything reaches a registry or Azure. Nginx serves a static page on port `8080` and exposes `/health`.

## Build

Five files under `app/web/`: `.dockerignore`, `Dockerfile`, `nginx.conf`, `index.html`, `styles.css`.

```bash
docker build --tag container-scale-web:0.1.0 .
```

![Docker builds the first web image](../images/phase-06-web-image-build.png)

The image built from `nginx:1.29.8-alpine` and completed all build steps without error.

![The versioned web image exists locally](../images/phase-06-web-image-list.png)

The image was stored under the immutable tag `0.1.0`.

## First failure: wrong configuration level

![The first web container exits with code 1](../images/phase-06-container-exited.png)

The container did not stay running, and no port mapping was established.

![Nginx reports the server directive in the wrong context](../images/phase-06-nginx-server-directive-error.png)

The cause was `"server" directive is not allowed here`, a configuration context error rather than a syntax error.

The custom file held a `server {}` block but had been copied over `/etc/nginx/nginx.conf`, which expects the complete top-level configuration. The destination was corrected to `/etc/nginx/conf.d/default.conf`. Full write-up in the [troubleshooting log](../troubleshooting.md#nginx-container-exited-immediately). The same context rule returns in phase 8.

![Nginx accepts the corrected configuration](../images/phase-06-nginx-config-test-success.png)

`nginx -t` on the rebuilt image passed, isolating configuration validity from runtime behaviour.

![The corrected web container is running on port 8080](../images/phase-06-container-running.png)

The container stayed up with host port `8080` mapped to container port `8080`.

## Second failure: healthy over HTTP, unhealthy to Docker

![The website root returns the custom HTML](../images/phase-06-web-root-200.png)

`/` returned `200` with the project's own page body.

![Docker reports the running web container as unhealthy](../images/phase-06-docker-health-unhealthy.png)

Docker's health status was `unhealthy` at the same time host-side requests were succeeding.

![Docker health-check attempts fail with connection refused](../images/phase-06-health-connection-refused.png)

The health history was five consecutive connection refusals, so the check never reached the server.

![The in-container localhost health request fails](../images/phase-06-localhost-health-fails.png)

The failure reproduced inside the container using `localhost`, isolating the cause to name resolution rather than the web server.

The same request succeeded through `127.0.0.1`, so the `HEALTHCHECK` moved to the explicit IPv4 loopback address. Full write-up in the [troubleshooting log](../troubleshooting.md#docker-marked-a-working-site-unhealthy).

![Docker reports the corrected container as healthy](../images/phase-06-docker-health-healthy.png)

After the fix and a container recreate, Docker reported `healthy`.

![The health endpoint returns HTTP 200 and healthy](../images/phase-06-health-endpoint-200.png)

`/health` returned `200` with an 8-byte `text/plain` body.

![Nginx starts successfully and records an HTTP 200 request](../images/phase-06-nginx-running-logs.png)

Normal startup on `nginx/1.29.8` with worker processes started, and a served request logged at `200`.

A successful host request says nothing about Docker's internal health command. Rebuilding an image does not change a running container.
