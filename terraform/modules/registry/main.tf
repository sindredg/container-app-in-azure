# The private image supply path: where images live, and the passwordless
# identities allowed to read them.

resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  role_assignment_mode = "AbacRepositoryPermissions"

  tags = var.tags
}

# The shared identity both apps used before they had their own. Kept until the
# per-app identities are confirmed working, so a failed pull has somewhere to
# roll back to. Removed in a follow-up.
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

# One identity per application.
#
# Sharing one identity meant compromising either container granted the same
# access, and an audit log could not say which application pulled what.
resource "azurerm_user_assigned_identity" "app" {
  for_each = var.pull_identities

  name                = "id-${each.key}-pull"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Read only, and only the one repository this application runs.
#
# An ABAC-enabled role assigned without a condition is registry wide. The
# condition is what scopes it, so leaving it off would grant exactly what
# this change exists to remove.
#
# The expression reads: unless the action is reading repository content or
# metadata, allow it. If it is, the repository name must match. That shape
# keeps actions the condition does not describe from being denied outright.
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
