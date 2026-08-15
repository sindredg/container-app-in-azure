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

## Compose could not bind port 8080

**Symptom:** The web container failed to start with `Bind for 0.0.0.0:8080 failed: port is already allocated`.

**Cause:** A container from an earlier single-image test was still running and holding the published port.

**Fix:** Identify the holder with `docker ps --filter publish=8080` and remove it before starting the composition.

## Header check returned 405 against the API

**Symptom:** `curl -I` against `/api/status` returned `405 Method Not Allowed`.

**Cause:** FastAPI registers only `GET` for a `@app.get` route and does not add `HEAD` automatically, unlike plain Starlette.

**Fix:** Inspect headers with a `GET` that discards the body, using `curl -sD - -o /dev/null`. Add `HEAD` to the route only where a monitor needs it.

## Web image build failed on a deleted file

**Symptom:** The build stopped with `"/app.js": not found`.

**Cause:** The file was removed while the Dockerfile still copied it, because an instruction block was pasted into the shell and the editing step was a comment line rather than a command.

**Fix:** Restore the file or drop it from the `COPY` instruction. Treat pasted blocks containing comments as unreliable, and confirm the file list before building.

## Git refused to rename the Nginx config

**Symptom:** `git mv` reported a bad source path for `nginx.conf`.

**Cause:** The command ran from the repository root while the path was relative to `app/web`.

**Fix:** Run the rename from the directory holding the file, or give the full path from the repository root.
