# Decision Log

The decisions worth explaining. Each one had a reasonable alternative that was not taken.

## Why Container Apps instead of Kubernetes?

The workload is two small containers that need ingress, scaling, revisions, and health probes. Container Apps provides all of that as a managed service.

**Alternative:** AKS, which gives far more control over networking, scheduling, and extensions. It also means operating a cluster, and nothing here needs that yet. Container Instances was the other option, but it has no ingress, revision, or scaling model.

## Why managed identity instead of registry credentials?

The Container App authenticates to the registry as itself. No registry password exists in Terraform, in state, in environment variables, or in the image.

**Alternative:** Enable the registry admin account and store the password as a secret. That works immediately, but it creates a long-lived credential that has to be stored, rotated, and kept out of logs and state files.

## Why immutable tags instead of latest?

Each release is published once under a version tag and never overwritten, so a deployment names an exact artifact and rollback means redeploying the previous tag.

**Alternative:** A moving `latest` tag, which removes a step from every release. It also makes the running image unidentifiable from the configuration, and lets two deployments of identical config produce different results.

## Why does the state backend have its own Terraform root?

The backend cannot store its own first state until the storage account exists. A separate bootstrap root creates the backend, and the platform root consumes it.

**Alternative:** Create the storage by hand and let one root use it. That hides infrastructure from Terraform and leaves the backend undocumented and unreproducible.

## Why two state keys in one container?

`bootstrap/dev.tfstate` and `platform/dev.tfstate` sit in the same private container under different keys, so the two roots cannot see each other's resources.

**Alternative:** One shared state. A command run in the wrong directory could then plan changes against everything at once, and the naming leaves no room for later environments.

## Why does the site return a real 404 instead of falling back to the homepage?

`try_files $uri $uri/ =404` makes a missing path an honest not-found. Before this, every unknown path returned the homepage with `200`, so a scanner probing for `/.env` got `200` and error-rate monitoring saw nothing.

**Alternative:** Keep the `/index.html` fallback, which is correct for a single-page application where the browser owns routing. This site is static, so the fallback provided no benefit and broke the meaning of the status code.

## Why truncate the client address instead of removing it?

The access log records the `/24` network rather than the full address. Repeated failed requests from one source still group together, so the signal needed for later detection work survives.

**Alternative:** Drop the field entirely, which removes more personal data but also removes the ability to detect scanning. The honest description of the result is less identifying, not anonymous.

## Why is the API reached through the web origin instead of its own hostname?

The browser calls `/api/` on the site it already loaded, and nginx proxies to the API's internal address. The API hostname never reaches client code, and the request stays inside the site's own Content Security Policy.

**Alternative:** Give the API external ingress and call it directly. That needs CORS configuration and publishes a second public entry point, which is the opposite of the intent.

## Why does the API need a secret when it has no public address?

Internal ingress protects it from the internet. It does not protect it from anything already running inside the environment. The proxy sends a secret that Terraform generates and both apps hold, so the API answers only the caller it is meant to. `/health` stays open because the platform probes call the container directly rather than through the proxy.

**Alternative:** Keep relying on internal ingress alone, which was the earlier position. It is one control where two cost almost nothing, since nobody ever handles the generated value. Microsoft Entra would be stronger again, at the price of an app registration and token handling this project does not need yet.

## Why is the generated API schema switched off?

Nothing consumes it in Azure, so publishing the route surface bought nothing. It is now behind a flag, off in Azure and on for local work. The interactive docs were already off, because their assets load from a CDN the Content Security Policy blocks.

**Alternative:** Leave it public, which makes the service self-describing and was the earlier position. Blocking it at the proxy instead would hide the path while leaving the route live on the API itself, which is the weaker of the two fixes.

## Why does the Content Security Policy allow no inline script?

`default-src 'self'` with no inline exception. Starting strict is easier than tightening later, because the constraint shapes the code that gets written.

**Alternative:** Allow `'unsafe-inline'`, which suits small snippets embedded in the page and permits most of what a CSP is meant to prevent. The cost of the strict version is real: the API panel's JavaScript has to be served as its own file.
## Why does CI get its permissions from a separate Terraform root?

The pipeline's identity and every role assignment it holds live in the bootstrap configuration, which only a human applies. CI applies the platform configuration and nothing else. It therefore cannot grant itself more access, because its own permissions are outside what it is able to change.

**Alternative:** Keep the identity beside the resources it manages, which is simpler and puts related things together. It also means a change to the pipeline can change what the pipeline is allowed to do, which is the property worth giving up simplicity for.

## Why does the pipeline refuse to deploy when source changed without a version bump?

Image tags are immutable, so the build skips any tag already in the registry. That is correct, but it means changing application code without bumping the tag deploys the old image. The first pipeline run did exactly that and shipped a web image older than the change it was meant to carry. The build now fails and names the variable to bump.

**Alternative:** Tag every build with the commit hash, which removes the failure entirely but also removes readable release numbers. Or rebuild and overwrite the tag, which abandons immutability and makes a deployed version unidentifiable.

## Why keep more than one version of the app alive?

Only one version can be live at a time in the default mode, so undoing a bad release means deploying the old one again and waiting for it to start. Keeping the previous version running means rolling back is just moving traffic back to it, which takes seconds instead of minutes.

**Alternative:** Redeploy the previous version when something goes wrong. Simpler, and no old versions sitting around, but the site stays broken for as long as the deployment takes.

## Why do revision names include a hash?

A revision name should say which release it is running. Naming it after the version alone looked right, but it only produces a new name when the image changes, and most changes are configuration. Azure will not reuse an existing name, so it quietly fell back to numbering them. Adding a short hash of the settings keeps every revision distinct while the version stays readable at the front.

**Alternative:** Accept the generated names, which are unique but tell you nothing. Or bump the version for configuration changes, which would make version numbers meaningless.

## Why is this platform not connected to the hub and spoke network project?

The two are built to live differently. This platform is meant to stay reachable, scale to zero, and cost almost nothing. The network lab is meant to be destroyed after each session, because a VPN gateway and firewall are expensive to leave running. Joining them forces a choice between a site that disappears and a lab that bills around the clock. They are also in different regions, and a Container Apps environment has to share a region with its subnet.

**Alternative:** Rebuild this platform in the network project's region and attach it to the spoke. That means private networking here, at the cost of scale to zero, a continuously billed environment, and a live site that depends on another project's state. Private networking is already demonstrated in that project, so the gap is in this repository rather than in the work overall.

## Why do the scanners report instead of blocking?

Only the Terraform linter fails a pull request, because it catches configuration errors rather than opinions. The security scanners report into the Security tab instead.

The first scan returned 100 findings. Seven were in a dependency this project chose. The other ninety three came from the base image, and all three criticals were Perl vulnerabilities in a Python image that never runs Perl. Blocking on severity would have stopped the pipeline on day one for something nobody could fix.

**Alternative:** Fail on high severity immediately, which sounds stricter and in practice teaches people to disable the check. Reporting first shows the real volume, so enforcement can be set where it will actually be obeyed.

## Why is Terraform split into modules?

The configuration is grouped by capability: platform, registry, and one module per application. It matches the layout used in the networking project, and it makes a second environment a matter of calling the same modules with different inputs.

**Alternative:** Keep it flat, which is perfectly readable at this size and needs no migration. Or write one generic application module used twice, which repeats less code but needs a dozen optional settings to describe how the two apps differ, so every reader has to hold both cases in their head.

## Why do deployment runs queue instead of running in parallel?

Terraform locks its state while it works, so two runs at once means one fails on the lock for a reason that has nothing to do with its own change. That is how people learn to ignore red builds.

**Alternative:** Cancel the older run so the newest wins, which is the usual instinct. It is the wrong answer here, because cancelling a run mid-apply is exactly how this project once left a lock stranded and needed manual recovery.
