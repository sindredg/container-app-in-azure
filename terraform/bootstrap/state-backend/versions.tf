terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  backend "azurerm" {
    resource_group_name  = "rg-container-scale-lab-tfstate"
    storage_account_name = "stcslabsindredgtf"
    container_name       = "tfstate"
    key                  = "bootstrap/dev.tfstate"

    use_azuread_auth = true
    use_cli          = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}