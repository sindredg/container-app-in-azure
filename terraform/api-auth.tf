# The shared secret the web proxy presents to the API.
#
# Generated rather than authored, so no human ever handles the value and it
# never appears in Git. It lives in Terraform state, which is already private,
# Entra authenticated, versioned, and soft deleted.
#
# Rotating it means tainting this resource and applying. Both apps read the
# same value, so they move together in one apply.
resource "random_password" "api_shared_secret" {
  length = 48

  # letters and digits only. The value is interpolated into an Nginx config
  # by envsubst, where quoting rules would make punctuation a hazard.
  special = false
}
