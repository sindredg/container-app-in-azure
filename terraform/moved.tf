# Moving a resource into a module changes its address. Without these blocks
# Terraform reads that as "the old one is gone, create a new one", which for
# the registry would mean deleting it and every image the apps pull from.
#
# These say the address was renamed, not replaced. A correct refactor plans
# as 0 to add, 0 to change, 0 to destroy.
#
# Delete this file once the move has been applied. It has no further purpose.

moved {
  from = azurerm_resource_group.main
  to   = module.platform.azurerm_resource_group.main
}

moved {
  from = azurerm_log_analytics_workspace.main
  to   = module.platform.azurerm_log_analytics_workspace.main
}

moved {
  from = azurerm_container_app_environment.main
  to   = module.platform.azurerm_container_app_environment.main
}

moved {
  from = azurerm_container_registry.main
  to   = module.registry.azurerm_container_registry.main
}

moved {
  from = azurerm_user_assigned_identity.container_pull
  to   = module.registry.azurerm_user_assigned_identity.container_pull
}

moved {
  from = azurerm_role_assignment.container_pull
  to   = module.registry.azurerm_role_assignment.container_pull
}

moved {
  from = azurerm_container_app.api
  to   = module.api_app.azurerm_container_app.api
}

moved {
  from = azurerm_container_app.web
  to   = module.web_app.azurerm_container_app.web
}
