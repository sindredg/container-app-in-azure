resource "azurerm_mssql_server" "main" {
  # Public endpoint with no private link is the recorded decision. Consumption-plan
  # egress addresses rotate, so a network control cannot be made to work here.
  # Entra-only authentication carries the security instead.
  #checkov:skip=CKV_AZURE_113: public access is deliberate; Entra-only authentication replaces the network control.
  #checkov:skip=CKV2_AZURE_45: a private endpoint needs a VNet and a workload profiles environment, rejected as a rebuild.
  #checkov:skip=CKV2_AZURE_2: vulnerability assessment requires a storage account, out of scope for this lab.
  #checkov:skip=CKV_AZURE_24: audit lands in Log Analytics at 30-day retention. Genuinely short of the 90 the check asks for, accepted for a lab.
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
  #checkov:skip=CKV_AZURE_224: the ledger feature answers a tamper-evidence requirement this project does not have.
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
  #checkov:skip=CKV2_AZURE_34: 0.0.0.0 is the Azure services rule, and per-address rules cannot work on a Consumption plan.
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

# Server level rather than database level, so failed authentication against the
# server is captured too, not just activity inside the one database. A database
# policy alongside this one would duplicate every record.
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  log_monitoring_enabled = true
}

# Server level audit events surface through the master database, not the server
# resource. Without this setting the audit policy above succeeds and silently
# delivers nothing.
resource "azurerm_monitor_diagnostic_setting" "audit" {
  name                       = "audit-to-log-analytics"
  target_resource_id         = "${azurerm_mssql_server.main.id}/databases/master"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
}
