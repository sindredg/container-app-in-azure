# CI identity. Lives here because a human applies this root, so the pipeline cannot widen its own grants.

resource "azurerm_user_assigned_identity" "ci" {
  name                = "id-container-scale-lab-ci"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = local.common_tags
}

# Subjects must match GitHub byte for byte: numeric IDs are included, and an environment claim replaces the ref claim.
locals {
  github_repo_claim = join("", [
    "repo:",
    var.github_owner, "@", var.github_owner_id,
    "/",
    var.github_repository, "@", var.github_repository_id,
  ])
}

# terraform-plan.yml, which runs on pull requests and targets no environment.
resource "azurerm_federated_identity_credential" "pull_request" {
  name                      = "github-pull-request"
  user_assigned_identity_id = azurerm_user_assigned_identity.ci.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "${local.github_repo_claim}:pull_request"
}

# deploy.yml, which targets the dev environment so the run waits for approval.
resource "azurerm_federated_identity_credential" "environment" {
  name                      = "github-environment-${var.github_environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.ci.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "${local.github_repo_claim}:environment:${var.github_environment}"
}

# Read and write the state blobs, and take the lease during an operation.
resource "azurerm_role_assignment" "ci_state_access" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
}

# Looked up rather than created, because the platform root owns them.
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

# Push only. This role cannot delete tags and does not include catalog listing.
resource "azurerm_role_assignment" "ci_registry_writer" {
  scope                = data.azurerm_container_registry.platform.id
  role_definition_name = "Container Registry Repository Writer"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
}
