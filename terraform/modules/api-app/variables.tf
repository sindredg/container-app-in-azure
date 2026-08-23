variable "name" {
  description = "Name of the API Container App."
  type        = string
}

variable "container_app_environment_id" {
  description = "Container Apps environment to deploy into."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the app."
  type        = string
}

variable "identity_id" {
  description = "User-assigned identity used to pull the image."
  type        = string
}

variable "registry_login_server" {
  description = "Registry the image is pulled from."
  type        = string
}

variable "image_tag" {
  description = "Immutable version tag of the API image."
  type        = string
}

variable "shared_secret" {
  description = "Secret the web proxy must present on every request except /health."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to the app."
  type        = map(string)
}
