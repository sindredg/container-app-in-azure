variable "registry_name" {
  description = "Globally unique name of the container registry."
  type        = string
}

variable "identity_name" {
  description = "Name of the shared pull identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the registry and identity."
  type        = string
}

variable "location" {
  description = "Azure region for the registry and identity."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
}
