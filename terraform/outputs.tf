output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azurerm_resource_group.main.name
}

output "container_app_environment_name" {
  description = "Name of the shared Container Apps environment."
  value       = azurerm_container_app_environment.main.name
}

output "container_app_environment_default_domain" {
  description = "Default domain assigned to the Container Apps environment."
  value       = azurerm_container_app_environment.main.default_domain
}