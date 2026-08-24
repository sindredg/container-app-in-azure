resource "azurerm_mssql_server" "main" {
  # Public by decision, with Entra-only auth as the control instead of the network.
  #checkov:skip=CKV_AZURE_113: public access is deliberate, Entra-only auth replaces the network control.
  #checkov:skip=CKV2_AZURE_45: a private endpoint needs a VNet and workload profiles environment, rejected as a rebuild.
  #checkov:skip=CKV2_AZURE_2: vulnerability assessment requires a storage account, out of scope for this lab.
  #checkov:skip=CKV_AZURE_24: audit retention is the workspace 30 days, short of 90 and accepted for a lab.
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "12.0"

  minimum_tls_version = "1.2"

  # No SQL login exists, not even a disabled one. Entra is the only way in.
  azuread_administrator {
    login_username              = var.admin_login_name
    object_id                   = var.admin_object_id
    azuread_authentication_only = true
  }

  tags = var.tags
}

# Serverless with auto-pause, so an idle database bills like the apps that scale to zero.
resource "azurerm_mssql_database" "main" {
  #checkov:skip=CKV_AZURE_229: zone redundancy costs more than a lab database justifies.
  #checkov:skip=CKV_AZURE_224: the ledger feature answers a requirement this project does not have.
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id

  sku_name    = "GP_S_Gen5_1"
  max_size_gb = 32

  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60

  storage_account_type = "Local"

  tags = var.tags
}

# The only rule. Administration runs from Cloud Shell, which is inside Azure already.
resource "azurerm_mssql_firewall_rule" "azure_services" {
  #checkov:skip=CKV2_AZURE_34: per-address rules cannot work when Consumption plan egress rotates.
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Server level, so failed authentication against the server is captured too.
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  log_monitoring_enabled = true
}

# Server level audit events surface through master, so the setting targets it.
resource "azurerm_monitor_diagnostic_setting" "audit" {
  name                       = "audit-to-log-analytics"
  target_resource_id         = "${azurerm_mssql_server.main.id}/databases/master"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
}
