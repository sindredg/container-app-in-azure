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