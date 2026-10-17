# Log Analytics and Route Validation

> **Historical baseline, before Phase 8.** This record preserves the initial routing finding.
> [Phase 8](../worklog/phase-08-web-routing-and-log-privacy.md#azure-verification) records the
> later routing update and an observed Azure `404`; the original five-path Azure retest remained open.

## Goal

Validate the public Container App through generated traffic, Azure logs, scale events, and negative-path requests.

## Tests

| Test | Result |
|---|---|
| Ten tagged HTTPS requests | All returned HTTP `200`. |
| Console-log correlation | Requests appeared under the active revision and `web` container. |
| System-log inspection | Azure recorded scale from zero to one, replica scheduling, image pull, creation, and startup. |
| Private ACR retrieval | Image `web:0.1.1` was pulled successfully through the runtime configuration. |
| Negative-path requests | All were logged, but returned HTTP `200` instead of `404`. |

## Evidence

![Ten generated requests return HTTP 200](../images/validation-http-traffic-200.png)

![Log Analytics correlates tagged requests with the active revision](../images/validation-request-correlation.png)

![Azure records the scale-from-zero lifecycle](../images/validation-scale-from-zero.png)

## Finding

Requests to `/admin`, `/login`, `/.env`, `/.git/config`, and `/server-status` returned HTTP `200`.

![Negative paths return HTTP 200](../images/validation-negative-path-200.png)

![Log Analytics captures the negative-path requests](../images/validation-negative-path-logs.png)

No sensitive file exposure was demonstrated. Nginx served the normal `index.html` fallback because the configuration at that stage used:

```nginx
try_files $uri $uri/ /index.html;
```

This is useful for a client-routed single-page application. The site was static, so a real `404` response was more accurate. This finding prompted the
routing correction in Phase 8; it does not describe the final Nginx configuration.

## Outcome

Log ingestion, request correlation, private image retrieval, and scale-from-zero were verified. The test also produced an actionable routing finding for the next web release.
