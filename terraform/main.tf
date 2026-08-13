locals {
  project_name        = "container-scale-lab"
  resource_group_name = "rg-${local.project_name}-${var.environment}"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = local.project_name
  }
}

