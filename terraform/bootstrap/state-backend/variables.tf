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