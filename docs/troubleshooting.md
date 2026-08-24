# Troubleshooting Log

## Container Apps provider was not registered

**Symptom:** Azure returned `MissingSubscriptionRegistration` for `Microsoft.App`.

**Cause:** The subscription had not enabled the resource provider used by Container Apps.

**Fix:** Register `Microsoft.App`, create a fresh Terraform plan, and apply the remaining change.

![Microsoft.App registration failure](images/microsoft-app-registration-error.png)

## Nginx container exited immediately

**Symptom:** Nginx reported that the `server` directive was not allowed in `/etc/nginx/nginx.conf`.

**Cause:** A site-level `server` block replaced the complete top-level Nginx configuration.

**Fix:** Copy the site file to `/etc/nginx/conf.d/default.conf`, rebuild the image, and verify it with `nginx -t`.

![Nginx configuration path failure](images/nginx-server-directive-error.png)

## Docker marked a working site unhealthy

**Symptom:** Host requests returned HTTP `200`, but Docker health checks received connection refused.

**Cause:** The in-container check used `localhost`. The application was reachable through the IPv4 loopback listener.

**Fix:** Use `http://127.0.0.1:8080/health`, rebuild the image, and recreate the container.

![Docker health check failure](images/docker-health-unhealthy.png)

## Cancelled Terraform plan left a state lease

**Symptom:** Terraform reported that the state blob was already locked and provided no lock ID.

**Cause:** A cancelled plan ended before releasing its Azure Blob lease.

**Fix:** Confirm no Terraform process is active. Break the lease on the exact state blob. Run the plan again with normal locking enabled.

![Terraform stale state lease](images/terraform-stale-lock-error.png)

## Saved plan appeared in Git status

**Symptom:** The local plans directory appeared as untracked.

**Cause:** A filename used `.tfoplan` instead of the ignored `.tfplan` extension.

**Fix:** Inspect the exact untracked path and remove the disposable misspelled plan.

## Header check against the API returned 405

**Symptom:** `curl -I` against an API route returned `405 Method Not Allowed` with `allow: GET`.

**Cause:** `curl -I` sends `HEAD`. FastAPI's `@app.get` registers `GET` only, unlike plain Starlette, which answers `HEAD` for a `GET` route.

**Fix:** Use a `GET` that discards the body: `curl -sD - -o /dev/null <url>`.

![HEAD rejected with 405 and allow: GET](images/phase-09-head-405-method-not-allowed.png)

## Proxied API path returned 404 instead of reaching the API

**Symptom:** `/api/status` returned `404` from nginx on the public site, while the API itself was healthy.

**Cause:** The `API_UPSTREAM` environment variable applied, but the image tag was never moved, so the running web image predated the `/api/` proxy block.

**Fix:** Move `web_image_tag` to the image that contains the proxy configuration and apply.

![Nginx returns its own 404 because no location matched](images/phase-10-api-status-404-stale-web.png)

## GitHub Actions login found no matching federated credential

**Symptom:** `AADSTS700213: No matching federated identity record found for presented assertion subject`.

**Cause:** Two faults. GitHub qualifies the owner and repository in the subject with their numeric IDs, and the credentials used the plain `repo:owner/repo` form. Separately, a job targeting a deployment environment receives an environment claim instead of a ref claim, so the credential written for `ref:refs/heads/main` could never match.

**Fix:** Read the subject out of the error and match it exactly. Replace the ref credential with an environment one.

![No matching federated identity record for the presented subject](images/phase-12-oidc-subject-mismatch.png)

## Pipeline deployed images that did not match the commit

**Symptom:** Login, build, and apply all passed, then the smoke test reported the site at `200` and the API path at `401`.

**Cause:** The build skips any image tag already published, which is correct for immutable tags. Nothing checked whether the source had changed without its tag changing too, so a release shipped a web image that predated the change it was meant to carry.

**Fix:** Fail the build when a service's source changed in the push but its tag is already published, and name the variable to bump.

![The smoke test catches the mismatched image](images/phase-12-smoke-test-catches-stale-image.png)

## Provider upgrade left state the new schema could not read

**Symptom:** After upgrading the Azure provider, a pipeline step failed with `unsupported attribute "trust_policy_enabled"`, while `terraform plan` reported no changes.

**Cause:** State written by the previous provider held an attribute the new version removed. Plan tolerated it because plan refreshes each resource from Azure. The failing step read state directly without refreshing.

**Fix:** `terraform apply -refresh-only`, which updates state from real infrastructure and changes nothing.

![The state could not be decoded under the new provider](images/phase-15-state-decode-error.png)

## Two workflow runs collided on the state lock

**Symptom:** A plan failed with `state blob is already locked`, naming an apply on another runner.

**Cause:** Nothing prevented two workflow runs at once. Terraform locks state for the duration of an operation, so the second could not proceed. The lock worked correctly; the pipeline allowed the collision.

**Fix:** Both workflows share a concurrency group so runs queue. Cancelling in progress is deliberately disabled, because cancelling an apply is how a lock gets stranded.

![Two runs collided on the state lock](images/phase-15-state-lock-collision.png)

## A line continuation became a literal backslash-n

**Symptom:** `terraform console` failed with `Too many command line arguments`.

**Cause:** A shell command written across two lines received a literal backslash followed by the letter n instead of a line break, so bash passed it and everything after it as arguments.

**Fix:** Put the command on one line. A guard added in the same change caught the empty result and failed the step clearly rather than deploying an empty image tag.

![The console command rejected its arguments](images/phase-15-console-argument-error.png)

## A fix pushed to a merged branch never reached main

**Symptom:** The push succeeded, nothing reported an error, and the pipeline on `main` stayed broken.

**Cause:** Pushing to a branch updates the branch. It does not reopen a merged pull request and it does not move `main`, so the commit sat where nothing would merge it again.

**Fix:** Branch from current `main`, apply the fix there, open a new pull request. After pushing to an existing branch, check that its pull request is still open.

## A failing Terraform plan reported success

**Symptom:** A pull request check reported pass while Terraform had failed with `No value for required variable`.

**Cause:** The plan step piped Terraform into `tee`. A shell pipeline reports the exit status of its last command, so the step reported whether `tee` could write a file, never whether Terraform succeeded. This had been the case since the pipeline was built in phase 12.

**Fix:** `set -o pipefail` before the pipeline, so a failure anywhere in it fails the step. The unused `exitcode` output was removed in the same change, because its presence suggested the exit status was being handled when nothing read it.

No bad plan reached main because of this. Every plan was also posted to the pull request and read. The check was decoration, and decoration that resembles a control is worse than no control.

## Azure refused to create a SQL server in the platform region

**Symptom:** `terraform plan` passed. `terraform apply` failed with `ProvisioningDisabled`, saying provisioning is restricted in this region.

**Cause:** The subscription is not permitted to provision Azure SQL in norwayeast, nor in westeurope, northeurope or uksouth. The `Microsoft.Sql/locations/<region>/capabilities` API reports these as `Visible` rather than `Available`, meaning the region appears and accepts the request, then refuses at provisioning time. A plan cannot detect it.

**Fix:** Move the database to `swedencentral`, which reports `Available`. Query the capabilities API before choosing a region rather than assuming a region that hosts other resources will host this one.

## A resource name stayed bound to a region where nothing was created

**Symptom:** After moving the database to another region, the apply failed with `InvalidResourceLocation`, saying the server already exists in norwayeast. It did not exist. ARM returned 404 for it, the resource list was empty, and Terraform state held no database resources.

**Cause:** The failed create was accepted by ARM before provisioning refused it, and acceptance writes a name to location binding in the resource group scoped registry. That record outlived the resource it was for.

`checkNameAvailability` does not detect this. It returned `available: true` before the first attempt and continued to while the 409 was raised, because it answers for the global DNS namespace rather than the per resource group registry.

**Fix:** Derive the server name from its region, so the name changes when the region does. This clears the current binding and prevents a repeat, because a later region change produces a new name instead of meeting the previous region's record.
