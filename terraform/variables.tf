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

variable "api_image_tag" {
  description = "Immutable version tag of the API image stored in ACR."
  type        = string
  default     = "0.3.0"

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.api_image_tag))
    error_message = "The image tag must be a three-part version such as 1.2.3."
  }
}

variable "web_image_tag" {
  description = "Immutable version tag of the web image stored in ACR."
  type        = string
  default     = "0.3.0"

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.web_image_tag))
    error_message = "The image tag must be a three-part version such as 1.2.3."
  }
}

variable "web_latest_traffic_percentage" {
  description = "Percent of web traffic sent to the newest revision. Lower it to split, set 0 to roll back."
  type        = number
  default     = 100

  validation {
    condition     = var.web_latest_traffic_percentage >= 0 && var.web_latest_traffic_percentage <= 100
    error_message = "Traffic percentage must be between 0 and 100."
  }
}

variable "web_previous_revision_suffix" {
  description = "Revision suffix receiving the remaining traffic, such as 0-2-0. Empty means the newest revision takes everything."
  type        = string
  default     = ""
}


variable "web_max_replicas" {
  description = "Ceiling on web replicas. Raised temporarily during a scale test, then returned to the baseline."
  type        = number
  default     = 1

  validation {
    condition     = var.web_max_replicas >= 1 && var.web_max_replicas <= 5
    error_message = "Keep the ceiling between 1 and 5 so a test cannot run up an unexpected bill."
  }
}

variable "web_concurrent_requests" {
  description = "Concurrent requests per replica before Azure adds another."
  type        = number
  default     = 10
}

variable "sql_admin_object_id" {
  description = "Object ID of the Entra principal administering SQL. Supplied at apply time, never committed."
  type        = string
  sensitive   = true
}

variable "sql_admin_login_name" {
  description = "Label shown against the Entra SQL administrator in the portal. The object ID decides the actual identity."
  type        = string
  default     = "cslab-sql-admin"
}

variable "sql_admin_ip_addresses" {
  description = "Administrator addresses permitted through the SQL firewall, keyed by a name describing each."
  type        = map(string)
  default     = {}
}
