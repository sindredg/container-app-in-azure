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
