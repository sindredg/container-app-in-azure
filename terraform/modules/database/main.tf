resource "azurerm_mssql_server" "main" {
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
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id

  sku_name    = "GP_S_Gen5_1"
  max_size_gb = 32

  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60

  storage_account_type = "Local"

  tags = var.tags
}

# 0.0.0.0 is the Azure services rule. Consumption plan egress addresses are not
# stable, so a per-address rule would fail silently whenever Azure rotates them.
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Administrator addresses, needed to run the contained user grants by hand.
resource "azurerm_mssql_firewall_rule" "admin" {
  for_each = var.admin_ip_addresses

  name             = each.key
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id            = azurerm_mssql_database.main.id
  log_monitoring_enabled = true
}

resource "azurerm_monitor_diagnostic_setting" "audit" {
  name                       = "audit-to-log-analytics"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
}
