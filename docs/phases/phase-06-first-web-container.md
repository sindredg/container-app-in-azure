# Phase 6: First Web Container

## Goal

Build and verify the web application locally before publishing it.

## Completed

- Created a static HTML and CSS page.
- Used Nginx as the web server.
- Configured port `8080` and `/health`.
- Added a Docker health check.
- Built immutable image tag `0.1.0`.
- Corrected the Nginx configuration path and IPv4 health address.

## Validated

- `nginx -t` accepted the configuration.
- The container stayed running.
- `/` returned HTTP `200`.
- `/health` returned HTTP `200` and `healthy`.
- Docker reported the container as healthy.

![The local web container passes its health check](../images/phase-06-local-health.png)
