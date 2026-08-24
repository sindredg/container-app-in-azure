# Phase 14 worklog: Supply Chain Scanning

## Goal

Close the gap where this project built and shipped two images on every release and never inspected what was in them, and had no Terraform scanning despite the network project already running it.

## What was added

Three checks on every pull request.

| Check | Blocks merge | Reason |
|---|---|---|
| TFLint | Yes | Catches configuration errors rather than opinions. |
| Checkov | No | Reports into the Security tab. |
| Trivy, both images | No | Reports into the Security tab. |

Only TFLint blocks. Turning enforcement on before seeing the finding volume usually ends with the check being disabled rather than the findings being fixed.

Images are built inside the job rather than pulled from the registry, so a pull request is scanned before its image is ever published.

## What the first scan found

100 findings, splitting cleanly in two.

**Seven were ours.** Starlette CVEs in `0.41.3`, pinned transitively by `fastapi 0.115.6`. Starlette is the layer that handles every request, and it is a dependency this project chose.

**Ninety three were the base image.** All three criticals were Perl, in `python:3.13-slim`. The API does not use Perl. The rest were `libblkid`, `setuptools`, and similar Debian userland packages that were never installed deliberately and are never invoked.

This is the argument for reporting before enforcing, stated concretely. Failing on CRITICAL would have blocked the pipeline over Perl in a Python image on the first run.

## The dependency upgrade

| Package | From | To |
|---|---|---|
| fastapi | 0.115.6 | 0.141.1 |
| uvicorn | 0.34.0 | 0.52.4 |
| starlette | 0.41.3 transitive | 1.6.0 pinned |

The highest fix version required across the seven was 1.3.1. `fastapi 0.141.1` requires `starlette>=0.46.0` with no ceiling, so it resolves to 1.6.0.

Starlette is now pinned directly rather than left to FastAPI. It carried the findings and it serves the requests, so its version belongs where a reviewer sees it.

## Honest note on exposure

Most of those seven do not apply to this API. The SSRF is Windows only, and others concern `StaticFiles`, form parsing, or `HTTPEndpoint` subclasses. This service has two GET routes, no static files, and no form handling. Real exposure was low.

Upgrading is still correct. The cost was a version bump, and the alternative was carrying known vulnerabilities in the request path.

## Verification

Starlette moved from `0.41` to `1.6`, a major version jump. The authentication added in phase 11 depends on Starlette middleware ordering, specifically that the last registered middleware is outermost. If that semantic had changed, authentication would have stopped being enforced while the happy path looked identical.

![A direct call is still refused after the upgrade](../images/phase-14-auth-survives-dependency-upgrade.png)

The closed path still closes. A call to the API bypassing the proxy returns `401` on the upgraded dependencies.

Checking the success path alone would not have caught a regression here. A working `/api/status` proves the key is accepted, not that a missing key is rejected.

Released as `api:0.3.0`.
