variable "server_name" {
  description = "Globally unique name of the SQL server."
  type        = string
}

variable "database_name" {
  description = "Name of the database."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the server and database."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "admin_object_id" {
  description = "Object ID of the Entra principal administering the server. Needed to create contained users, which is a human step."
  type        = string
}

variable "admin_login_name" {
  description = "Display name of the Entra administrator, shown in the portal."
  type        = string
}

variable "admin_ip_addresses" {
  description = "Administrator addresses permitted through the firewall, keyed by a name describing each."
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Workspace receiving the database audit log."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
}
