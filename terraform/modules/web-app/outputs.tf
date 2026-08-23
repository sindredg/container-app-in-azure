output "name" {
  description = "Name of the web Container App."
  value       = azurerm_container_app.web.name
}

output "url" {
  description = "Public HTTPS URL."
  value       = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}
