variable "registry_name" {
  description = "Globally unique name of the container registry."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the registry."
  type        = string
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
}
