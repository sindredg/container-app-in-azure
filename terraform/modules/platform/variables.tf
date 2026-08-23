variable "resource_group_name" {
  description = "Name of the resource group holding the platform."
  type        = string
}

variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "container_app_environment_name" {
  description = "Name of the Container Apps environment."
  type        = string
}

variable "location" {
  description = "Azure region for every resource in this module."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
}
