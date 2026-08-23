output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Region the resource group was created in."
  value       = azurerm_resource_group.main.location
}

output "container_app_environment_id" {
  description = "Resource ID of the Container Apps environment."
  value       = azurerm_container_app_environment.main.id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps environment."
  value       = azurerm_container_app_environment.main.name
}

output "container_app_environment_default_domain" {
  description = "Default domain assigned to the Container Apps environment."
  value       = azurerm_container_app_environment.main.default_domain
}
