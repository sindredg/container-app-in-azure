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

output "container_registry_name" {
  description = "Name of the Azure Container Registry."
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server used in container image addresses."
  value       = azurerm_container_registry.main.login_server
}

output "container_pull_identity_id" {
  description = "Resource ID of the managed identity used for image pulls."
  value       = azurerm_user_assigned_identity.container_pull.id
}

output "web_container_app_name" {
  description = "Name of the public web Container App."
  value       = azurerm_container_app.web.name
}

output "web_container_app_url" {
  description = "Public HTTPS URL of the web Container App."
  value       = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}