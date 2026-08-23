variable "registry_name" {
  description = "Globally unique name of the container registry."
  type        = string
}

variable "identity_name" {
  description = "Name of the shared pull identity. Retained until every app has moved to its own."
  type        = string
}

variable "pull_identities" {
  description = "One passwordless identity per application, each scoped to the single repository it pulls. The key names the identity, the value is the repository it may read."
  type        = map(string)
}

variable "resource_group_name" {
  description = "Resource group holding the registry and identities."
  type        = string
}

variable "location" {
  description = "Azure region for the registry and identities."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
}
