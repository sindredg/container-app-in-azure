output "login_server" {
  description = "Login server used in container image addresses."
  value       = azurerm_container_registry.main.login_server
}

output "registry_name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.main.name
}

output "identity_id" {
  description = "Resource ID of the pull identity."
  value       = azurerm_user_assigned_identity.container_pull.id
}

output "role_assignment_id" {
  description = "Resource ID of the pull role assignment. Apps depend on this so registry access exists before the first pull."
  value       = azurerm_role_assignment.container_pull.id
}
