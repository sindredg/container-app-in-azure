# The identity GitHub Actions uses to reach Azure.
#
# It lives in the bootstrap root on purpose. A human applies this root, and CI
# only ever applies the platform root. That means the pipeline cannot widen its
# own permissions, because the grants below are outside what it can change.
#
# There is no client secret anywhere. GitHub presents a short-lived OIDC token,
# Entra checks it against the federated credentials, and issues an access token.

resource "azurerm_user_assigned_identity" "ci" {
  name                = "id-container-scale-lab-ci"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = local.common_tags
}

# parent_id is correct for AzureRM 4.x. Version 5 renames it to
# user_assigned_identity_id and drops resource_group_name entirely,
# so this block changes when the provider constraint moves.
#
# Subject strings must match exactly what GitHub sends. A pull request token
# always carries subject repo:OWNER/REPO:pull_request regardless of branch,
# while a push to main carries the ref form.
resource "azurerm_federated_identity_credential" "pull_request" {
  name      = "github-pull-request"
  parent_id = azurerm_user_assigned_identity.ci.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_owner}/${var.github_repository}:pull_request"
}

resource "azurerm_federated_identity_credential" "main_branch" {
  name      = "github-main-branch"
  parent_id = azurerm_user_assigned_identity.ci.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/main"
}

# Read and write the state blobs, and take the lease during an operation.
resource "azurerm_role_assignment" "ci_state_access" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
}

# The platform resources CI manages. Looked up rather than created here,
# because the platform root owns them.
data "azurerm_resource_group" "platform" {
  name = var.platform_resource_group_name
}

data "azurerm_container_registry" "platform" {
  name                = var.container_registry_name
  resource_group_name = data.azurerm_resource_group.platform.name
}

# Scoped to the one resource group, never the subscription.
resource "azurerm_role_assignment" "ci_platform_contributor" {
  scope                = data.azurerm_resource_group.platform.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
}

# Push only. Under ABAC repository permissions this role cannot delete tags,
# and it does not include catalog listing.
resource "azurerm_role_assignment" "ci_registry_writer" {
  scope                = data.azurerm_container_registry.platform.id
  role_definition_name = "Container Registry Repository Writer"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
}
