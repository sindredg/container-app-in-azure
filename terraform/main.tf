locals {
  project_name = "container-scale-lab"

  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = local.project_name
  }
}

# Shared secret for both apps, generated so no human handles it and it never reaches Git.
resource "random_password" "api_shared_secret" {
  length = 48

  # Letters and digits only, since envsubst interpolates this into Nginx config.
  special = false
}

# Created by the bootstrap root, which a human applies, so they are read rather than managed here.
data "azurerm_user_assigned_identity" "app_pull" {
  for_each = toset(["web", "api"])

  name                = "id-${local.project_name}-${each.key}-pull-${var.environment}"
  resource_group_name = module.platform.resource_group_name
}

module "platform" {
  source = "./modules/platform"

  resource_group_name            = "rg-${local.project_name}-${var.environment}"
  log_analytics_name             = "log-${local.project_name}-${var.environment}"
  container_app_environment_name = "cae-${local.project_name}-${var.environment}"
  location                       = var.location
  tags                           = local.common_tags
}

module "registry" {
  source = "./modules/registry"

  registry_name       = var.container_registry_name
  resource_group_name = module.platform.resource_group_name
  location            = module.platform.location
  tags                = local.common_tags
}

module "api_app" {
  source = "./modules/api-app"

  name                         = "ca-${local.project_name}-api-${var.environment}"
  container_app_environment_id = module.platform.container_app_environment_id
  resource_group_name          = module.platform.resource_group_name
  identity_id                  = data.azurerm_user_assigned_identity.app_pull["api"].id
  registry_login_server        = module.registry.login_server
  image_tag                    = var.api_image_tag
  shared_secret                = random_password.api_shared_secret.result
  tags                         = merge(local.common_tags, { component = "api" })

}

module "database" {
  source = "./modules/database"

  server_name         = "sql-${local.project_name}-${var.sql_location}-${var.environment}"
  database_name       = "sqldb-${local.project_name}-${var.environment}"
  resource_group_name = module.platform.resource_group_name
  location            = var.sql_location

  admin_object_id  = var.sql_admin_object_id
  admin_login_name = var.sql_admin_login_name

  log_analytics_workspace_id = module.platform.log_analytics_workspace_id

  tags = merge(local.common_tags, { component = "database" })
}

module "web_app" {
  source = "./modules/web-app"

  name                         = "ca-${local.project_name}-web-${var.environment}"
  container_app_environment_id = module.platform.container_app_environment_id
  resource_group_name          = module.platform.resource_group_name
  identity_id                  = data.azurerm_user_assigned_identity.app_pull["web"].id
  registry_login_server        = module.registry.login_server
  image_tag                    = var.web_image_tag
  api_fqdn                     = module.api_app.internal_fqdn
  shared_secret                = random_password.api_shared_secret.result
  max_replicas                 = var.web_max_replicas
  concurrent_requests          = var.web_concurrent_requests
  latest_traffic_percentage    = var.web_latest_traffic_percentage
  previous_revision_suffix     = var.web_previous_revision_suffix
  tags                         = merge(local.common_tags, { component = "web" })

}
