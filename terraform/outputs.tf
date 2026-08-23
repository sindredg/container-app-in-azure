output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = module.platform.resource_group_name
}

output "container_app_environment_name" {
  description = "Name of the shared Container Apps environment."
  value       = module.platform.container_app_environment_name
}

output "container_app_environment_default_domain" {
  description = "Default domain assigned to the Container Apps environment."
  value       = module.platform.container_app_environment_default_domain
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry."
  value       = module.registry.registry_name
}

output "container_registry_login_server" {
  description = "Login server used in container image addresses."
  value       = module.registry.login_server
}

output "container_pull_identity_id" {
  description = "Resource ID of the managed identity used for image pulls."
  value       = module.registry.identity_id
}

output "web_container_app_name" {
  description = "Name of the public web Container App."
  value       = module.web_app.name
}

output "web_container_app_url" {
  description = "Public HTTPS URL of the web Container App."
  value       = module.web_app.url
}

output "api_container_app_name" {
  description = "Name of the internal API Container App."
  value       = module.api_app.name
}

output "api_container_app_internal_fqdn" {
  description = "Internal FQDN of the API Container App. Resolvable only inside the Container Apps environment."
  value       = module.api_app.internal_fqdn
}
