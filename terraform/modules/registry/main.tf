resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  role_assignment_mode = "AbacRepositoryPermissions"

  tags = var.tags
}

# Previous shared identity, kept as a rollback target until per-app identities are proven.
resource "azurerm_user_assigned_identity" "container_pull" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_role_assignment" "container_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "Container Registry Repository Reader"
  principal_id                     = azurerm_user_assigned_identity.container_pull.principal_id
  skip_service_principal_aad_check = true
}

# One identity per app, so a compromise is contained and pulls are attributable.
resource "azurerm_user_assigned_identity" "app" {
  for_each = var.pull_identities

  name                = "id-${each.key}-pull"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Read only, and scoped to one repository. Without a condition this role is registry wide.
resource "azurerm_role_assignment" "app" {
  for_each = var.pull_identities

  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "Container Registry Repository Reader"
  principal_id                     = azurerm_user_assigned_identity.app[each.key].principal_id
  skip_service_principal_aad_check = true
  description                      = "Pull ${each.value} images only"

  condition_version = "2.0"
  condition         = <<-CONDITION
    (
     (
      !(ActionMatches{'Microsoft.ContainerRegistry/registries/repositories/content/read'})
      AND
      !(ActionMatches{'Microsoft.ContainerRegistry/registries/repositories/metadata/read'})
     )
     OR
     (
      @Request[Microsoft.ContainerRegistry/registries/repositories:name] StringEqualsIgnoreCase '${each.value}'
     )
    )
  CONDITION
}
