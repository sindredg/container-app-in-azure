# Tagged for the platform, not for the state infrastructure around them.
locals {
  app_pull_tags = {
    environment = "dev"
    managed_by  = "terraform"
    project     = "container-scale-lab"
    purpose     = "container-registry-pull"
  }
}

# Granted from this root so the pipeline cannot change who has registry access.
resource "azurerm_user_assigned_identity" "app_pull" {
  for_each = var.app_pull_identities

  name                = each.key
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = data.azurerm_resource_group.platform.location

  tags = local.app_pull_tags
}

# Read only, and scoped to one repository. Without a condition this role is registry wide.
resource "azurerm_role_assignment" "app_pull" {
  for_each = var.app_pull_identities

  scope                            = data.azurerm_container_registry.platform.id
  role_definition_name             = "Container Registry Repository Reader"
  principal_id                     = azurerm_user_assigned_identity.app_pull[each.key].principal_id
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
