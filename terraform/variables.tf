variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "norwayeast"
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "container_registry_name" {
  description = "Globally unique name of the Azure Container Registry."
  type        = string
  default     = "acrcslabsindredgdev"

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.container_registry_name))
    error_message = "The registry name must contain 5 to 50 lowercase letters or numbers."
  }
}

variable "web_image_tag" {
  description = "Immutable version tag of the web image stored in ACR."
  type        = string
  default     = "0.1.0"
}