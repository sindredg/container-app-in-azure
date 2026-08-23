# The private image supply path: where images live, and the passwordless
# identity allowed to read them.

resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  role_assignment_mode = "AbacRepositoryPermissions"

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "container_pull" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Read only. The running applications can pull an image but cannot publish
# or delete one.
resource "azurerm_role_assignment" "container_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "Container Registry Repository Reader"
  principal_id                     = azurerm_user_assigned_identity.container_pull.principal_id
  skip_service_principal_aad_check = true
}
