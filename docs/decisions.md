# Decision Log

The decisions worth explaining. Each one had a reasonable alternative that was not taken.

## Compute platform

Decision: [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/overview), with both applications in one [managed environment](https://learn.microsoft.com/en-us/azure/container-apps/environment).

Why: the workload is two small containers needing ingress, scaling, revisions, and [health probes](https://learn.microsoft.com/en-us/azure/container-apps/health-probes), and the managed service provides all four.

Alternatives: [AKS](https://learn.microsoft.com/en-us/azure/aks/what-is-aks), which adds control over networking, scheduling, and extensions at the price of operating a cluster, or [Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-overview), which has no ingress, revision, or scaling model.

## Terraform structure

Decision: a root configuration composed from [local modules](https://developer.hashicorp.com/terraform/language/modules) grouped by capability: `platform`, `registry`, `web-app`, and `api-app`.

Why: it matches the layout used in the networking project, and makes a second environment a matter of calling the same modules with different inputs.

Alternatives: a flat configuration, which is readable at this size and needs no migration, or one generic application module used twice, which repeats less but needs a dozen optional settings to describe how the two apps differ.

## State backend ownership

Decision: a separate `bootstrap/state-backend` root that creates the [azurerm backend](https://developer.hashicorp.com/terraform/language/backend/azurerm) the platform root then consumes.

Why: the backend cannot store its own first state until the storage account exists.

Alternatives: create the storage account by hand, which hides infrastructure from Terraform and leaves the backend undocumented and unreproducible.

## State layout

Decision: two [state](https://developer.hashicorp.com/terraform/language/state) keys, `bootstrap/dev.tfstate` and `platform/dev.tfstate`, in one private container.

Why: the two roots cannot see each other's resources, and the naming leaves room for later environments.

Alternatives: one shared state, where a command run in the wrong directory plans changes against everything at once.

## API reachability

Decision: [internal ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) on the API, reached through `/api/` on the web origin by an nginx `proxy_pass`.

Why: the API hostname never reaches client code, and the request stays inside the site's own Content Security Policy.

Alternatives: external ingress called directly, which needs [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS) configuration and publishes a second public entry point.

## API authentication

Decision: a shared secret that Terraform generates with [`random_password`](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) and sets as a [container app secret](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets) on both apps, sent by the proxy and required by API middleware.

Why: internal ingress protects the API from the internet but not from anything already running inside the environment.

Alternatives: internal ingress alone, which was the earlier position, or [Microsoft Entra](https://learn.microsoft.com/en-us/entra/identity/), which is stronger again at the price of an app registration and token handling this project does not need yet.

Notes: `/health` stays open, because the platform probes call the container directly rather than through the proxy. An unset secret fails closed.

## Unknown paths

Decision: [`try_files $uri $uri/ =404`](https://nginx.org/en/docs/http/ngx_http_core_module.html#try_files), so a missing path is an honest not-found.

Why: the status code keeps its meaning, and error-rate monitoring sees failed requests.

Alternatives: the `/index.html` fallback, which is correct for a single-page application where the browser owns routing, and provides nothing for a static site.

Notes: before this, every unknown path returned the homepage with `200`, so a scanner probing for `/.env` got `200` and monitoring saw nothing.

## Content Security Policy

Decision: [`default-src 'self'`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/default-src) with `object-src 'none'`, `base-uri 'none'`, `frame-ancestors 'none'`, and no inline script exception.

Why: starting strict is easier than tightening later, because the constraint shapes the code that gets written.

Alternatives: [`'unsafe-inline'`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP), which suits snippets embedded in the page and permits most of what a policy is meant to prevent.

Notes: the cost is real. The API panel's JavaScript has to be served as its own file.

## Generated API schema

Decision: the [OpenAPI schema](https://fastapi.tiangolo.com/tutorial/metadata/) is behind a flag, off in Azure and on for local work.

Why: nothing consumes it in Azure, so publishing the route surface bought nothing.

Alternatives: leave it public, which makes the service self-describing and was the earlier position, or block it at the proxy, which hides the path while leaving the route live on the API itself.

Notes: the interactive docs were already off, because their assets load from a CDN the Content Security Policy blocks.

## Client address logging

Decision: a [custom `log_format`](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) that records the `/24` network from `X-Forwarded-For` rather than the full address.

Why: repeated failed requests from one source still group together, so the signal needed for later detection work survives.

Alternatives: drop the field entirely, which removes more personal data and also removes the ability to detect scanning.

Notes: the honest description of the result is less identifying, not anonymous.

## Registry authentication

Decision: [managed identity image pull](https://learn.microsoft.com/en-us/azure/container-apps/managed-identity-image-pull), with `admin_enabled = false` on the registry.

Why: no registry password exists in Terraform, in state, in environment variables, or in the image.

Alternatives: the [registry admin account](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication#admin-account), which works immediately and creates a long-lived credential to store, rotate, and keep out of logs and state files.

## Image tags

Decision: [immutable version tags](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-image-tag-version). Each release is published once and never overwritten.

Why: a deployment names an exact artifact, and rollback means redeploying the previous tag.

Alternatives: a moving `latest` tag, which removes a step from every release, makes the running image unidentifiable from the configuration, and lets two deployments of identical config produce different results.

Notes: immutability is enforced by the pipeline skipping any tag already in the registry, not by a registry policy. The [Basic tier](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus) has none.

## Release version enforcement

Decision: the build fails, and names the variable to bump, when application source changed in a push but its image tag is already published.

Why: tags are immutable, so the build skips existing tags, and changing code without bumping the tag would otherwise deploy the old image.

Alternatives: tag every build with the commit hash, which removes the failure and the readable release numbers with it, or rebuild and overwrite the tag, which abandons immutability.

Notes: the first pipeline run did exactly this and shipped a web image older than the change it was meant to carry.

## Rollback

Decision: `revision_mode = "Multiple"` on the web app with [traffic splitting](https://learn.microsoft.com/en-us/azure/container-apps/traffic-splitting), keeping the previous revision alive.

Why: rolling back is moving traffic back to a running revision, which takes seconds rather than the minutes a redeploy needs.

Alternatives: `Single` mode, which the API uses, where undoing a bad release means deploying the old version again and the site stays broken until it starts.

## Revision naming

Decision: a [`revision_suffix`](https://learn.microsoft.com/en-us/azure/container-apps/revisions) of the image tag plus a short hash of the container configuration.

Why: a revision name should say which release it is running, and the version stays readable at the front.

Alternatives: the generated names, which are unique and tell you nothing, or bumping the version for configuration changes, which would make version numbers meaningless.

Notes: naming by version alone only produces a new name when the image changes, and most changes are configuration. Azure will not reuse a name, so it quietly fell back to numbering.

## Registry access per application

Decision: one [user-assigned identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation) per app holding `Container Registry Repository Reader`, restricted by an [ABAC condition](https://learn.microsoft.com/en-us/azure/role-based-access-control/conditions-overview) to the single repository it runs, on a registry in [`AbacRepositoryPermissions`](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-rbac-abac-repository-permissions) mode.

Why: compromising either container previously granted read on every repository, and the audit trail could not say which application pulled what.

Alternatives: one shared identity, which is simpler and was the position for most of this project. Splitting without conditions would fix attribution but not access, because a role assigned without a condition applies to the whole registry.

## Pipeline permission ownership

Decision: the pipeline's identity, its federated credentials, and every role assignment it holds live in the bootstrap root, which only a human applies.

Why: the pipeline cannot grant itself more access, because its own permissions are outside what it is able to change.

Alternatives: keep the identity beside the resources it manages, which is simpler and means a change to the pipeline can change what the pipeline is allowed to do.

## Pipeline role assignment scope

Decision: the pipeline holds [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged#contributor), `Storage Blob Data Contributor`, and `Container Registry Repository Writer`, and nothing that manages role assignments.

Why: destruction is loud and rebuilt from code in minutes, while a quietly granted permission persists and nobody notices.

Alternatives: grant it permission to manage role assignments on the registry. One line, and it could then change who has access to anything, including granting itself more.

Notes: the cost is that some changes need a person and cannot deploy unattended.

## Deployment concurrency

Decision: a [`concurrency` group](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency) with `cancel-in-progress: false`, so deployment runs queue.

Why: Terraform [locks its state](https://developer.hashicorp.com/terraform/language/state/locking) while it works, and two runs at once means one fails on the lock for a reason unrelated to its own change.

Alternatives: cancel the older run so the newest wins, which is the usual instinct and is how this project once left a lock stranded and needed manual recovery.

## Security scanning enforcement

Decision: only [TFLint](https://github.com/terraform-linters/tflint) fails a pull request. [Checkov](https://www.checkov.io/) and [Trivy](https://trivy.dev/) [upload SARIF](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github) to the Security tab instead.

Why: the linter catches configuration errors rather than opinions.

Alternatives: fail on high severity immediately, which sounds stricter and in practice teaches people to disable the check.

Notes: the first scan returned 100 findings. Seven were in a dependency this project chose. The other ninety three came from the base image, and all three criticals were Perl vulnerabilities in a Python image that never runs Perl.

## Plan comment redaction

Decision: the plan output has every `/subscriptions/<guid>` replaced with `/subscriptions/<redacted>` before the pull request comment is built.

Why: Terraform prints full resource IDs, every one of them carries the subscription ID, and this repository is public.

Alternatives: leave it. A subscription ID is an identifier rather than a credential, and the cost is a redaction standard the project applies to its screenshots and not to its pipeline.

Notes: Actions [masks repository secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) in job logs, but a comment is posted through the API, where masking does not reach.

## Relationship to the hub and spoke lab

Decision: unconnected. This platform stays publicly reachable and [scales to zero](https://learn.microsoft.com/en-us/azure/container-apps/scale-app); the [hub and spoke](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke) lab is destroyed after each session.

Why: joining them forces a choice between a site that disappears and a lab that bills around the clock, and a Container Apps environment has to share a region with its subnet.

Alternatives: rebuild here in the network project's region and attach to the spoke, which buys [private networking](https://learn.microsoft.com/en-us/azure/container-apps/networking) at the cost of scale to zero, a continuously billed environment, and a live site depending on another project's state.

Notes: private networking is already demonstrated in that project, so the gap is in this repository rather than in the work overall.
