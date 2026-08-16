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

## Why does the API have no authentication?

It returns its own health and identity data, nothing more, and internal ingress already keeps it unreachable from the internet.

**Alternative:** Add a token mechanism now. That means choosing and operating one before there is anything to protect. This stops being defensible the moment the API returns real data or the environment is shared, and it is tracked as an open item rather than a finished position.

## Why is the whole API published through the proxy?

The `/api/` location forwards every path, so `/api/openapi.json` and `/api/health` are publicly readable alongside `/api/status`. The schema describes two endpoints that return nothing being protected, and blocking it would be theatre.

**Alternative:** Restrict the proxy to the paths the browser needs. That is the safer default, because it withholds by design rather than publishing by default, and it becomes the right answer the moment the API gains a route returning anything private. Accepted for now on the basis that nothing behind it is sensitive.

## Why does the Content Security Policy allow no inline script?

`default-src 'self'` with no inline exception. Starting strict is easier than tightening later, because the constraint shapes the code that gets written.

**Alternative:** Allow `'unsafe-inline'`, which suits small snippets embedded in the page and permits most of what a CSP is meant to prevent. The cost of the strict version is real: the API panel's JavaScript has to be served as its own file.