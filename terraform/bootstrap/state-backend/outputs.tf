output "resource_group_name" {
  description = "Resource group containing the Terraform backend."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Storage account containing Terraform state."
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Private blob container containing Terraform state."
  value       = azurerm_storage_container.state.name
}