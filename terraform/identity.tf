resource "azurerm_user_assigned_identity" "container_pull" {
  name                = "id-${local.project_name}-pull-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = local.common_tags
}

resource "azurerm_role_assignment" "container_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "Container Registry Repository Reader"
  principal_id                     = azurerm_user_assigned_identity.container_pull.principal_id
  skip_service_principal_aad_check = true
}