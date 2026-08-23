output "login_server" {
  description = "Login server used in container image addresses."
  value       = azurerm_container_registry.main.login_server
}

output "registry_name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.main.name
}
