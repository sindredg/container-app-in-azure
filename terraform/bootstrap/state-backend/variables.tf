variable "location" {
  description = "Azure region for the Terraform state resources."
  type        = string
  default     = "norwayeast"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for Terraform state."
  type        = string
  default     = "stcslabsindredgtf"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "The storage account name must contain 3 to 24 lowercase letters or numbers."
  }
}

variable "github_owner" {
  description = "GitHub account that owns the application repository."
  type        = string
  default     = "sindredg"
}

variable "github_repository" {
  description = "Repository GitHub Actions authenticates from."
  type        = string
  default     = "container-app-in-azure"
}

variable "platform_resource_group_name" {
  description = "Resource group holding the application platform that CI deploys to."
  type        = string
  default     = "rg-container-scale-lab-dev"
}

variable "container_registry_name" {
  description = "Registry CI pushes images to."
  type        = string
  default     = "acrcslabsindredgdev"
}
