output "server_name" {
  description = "Name of the SQL server."
  value       = azurerm_mssql_server.main.name
}

output "server_fqdn" {
  description = "Fully qualified name used in connection strings."
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_name" {
  description = "Name of the database."
  value       = azurerm_mssql_database.main.name
}
