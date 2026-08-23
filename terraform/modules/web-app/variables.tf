variable "name" {
  description = "Name of the web Container App."
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
  description = "Immutable version tag of the web image."
  type        = string
}

variable "api_fqdn" {
  description = "Internal FQDN of the API, proxied at /api/."
  type        = string
}

variable "shared_secret" {
  description = "Secret sent to the API as X-Api-Key on every proxied request."
  type        = string
  sensitive   = true
}

variable "max_replicas" {
  description = "Replica ceiling."
  type        = number
}

variable "concurrent_requests" {
  description = "Concurrent requests per replica before another is added."
  type        = number
}

variable "latest_traffic_percentage" {
  description = "Percent of traffic sent to the newest revision."
  type        = number
}

variable "previous_revision_suffix" {
  description = "Revision suffix taking the remaining traffic. Empty means the newest revision takes everything."
  type        = string
}

variable "tags" {
  description = "Tags applied to the app."
  type        = map(string)
}
