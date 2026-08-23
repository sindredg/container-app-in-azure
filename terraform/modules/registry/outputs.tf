output "login_server" {
  description = "Login server used in container image addresses."
  value       = azurerm_container_registry.main.login_server
}

output "registry_name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.main.name
}

output "identity_id" {
  description = "Resource ID of the shared pull identity. Retained during the move to per-app identities."
  value       = azurerm_user_assigned_identity.container_pull.id
}

output "app_identity_ids" {
  description = "Resource ID of each per-app pull identity, keyed by application."
  value       = { for k, v in azurerm_user_assigned_identity.app : k => v.id }
}
