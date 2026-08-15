# Phase 8: Web Routing, Response Hardening, and Log Privacy

## Goal

Correct the missing-route behavior found during validation, stop responses advertising the web server version, add protective response headers, and record the client network rather than the client address.

## Completed

- Published immutable image tag `0.1.2` to ACR.
- Changed the static fallback to `try_files $uri $uri/ =404`.
- Disabled version disclosure with `server_tokens off`.
- Added `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, and `Content-Security-Policy`.
- Truncated the logged client address to its `/24` network, with `unknown` as the default.
- Added a footer notice describing what the site logs and for how long.
- Deployed the release as a single in-place Terraform change.

## Validated

- `nginx -t` accepted the configuration inside the running container.
- Missing paths returned a genuine `404` instead of the homepage with `200`.
- The four headers were present on both successful and error responses.
- A request from `203.0.113.45` was logged as `203.0.113.0`, and a request with no forwarded header was logged as `unknown`.
- The deployed site returned no version string over HTTP/2.
- Log Analytics showed the new format, including a browser request for `/favicon.ico` returning `404`.

## Related decisions

- Return real `404` responses for missing static-site paths.
- Record the client network rather than the client address.
- Set a Content Security Policy that allows no inline script, so later JavaScript must be served as its own file.

## Not yet verified

The five recon paths from the earlier validation round have not been re-run against the deployed site.

![A missing path returns a real 404 with the protective headers applied](../images/phase-08-local-missing-path-404.png)

![The deployed site returns no version string and four protective headers](../images/phase-08-azure-root-200-headers.png)
