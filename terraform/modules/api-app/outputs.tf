output "name" {
  description = "Name of the API Container App."
  value       = azurerm_container_app.api.name
}

output "internal_fqdn" {
  description = "Internal FQDN. Resolvable only inside the Container Apps environment."
  value       = azurerm_container_app.api.ingress[0].fqdn
}
