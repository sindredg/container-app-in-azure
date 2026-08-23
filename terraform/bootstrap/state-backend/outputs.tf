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
output "ci_client_id" {
  description = "Client ID for the AZURE_CLIENT_ID GitHub repository variable."
  value       = azurerm_user_assigned_identity.ci.client_id
}

output "ci_principal_id" {
  description = "Object ID of the CI identity, for checking role assignments."
  value       = azurerm_user_assigned_identity.ci.principal_id
}

output "tenant_id" {
  description = "Tenant ID for the AZURE_TENANT_ID GitHub repository variable."
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Subscription ID for the AZURE_SUBSCRIPTION_ID GitHub repository variable."
  value       = data.azurerm_client_config.current.subscription_id
  sensitive   = true
}

output "app_pull_identity_ids" {
  description = "Resource ID of each per-app pull identity, keyed by identity name."
  value       = { for k, v in azurerm_user_assigned_identity.app_pull : k => v.id }
}
