terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.51.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "1.2.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

provider "azurerm" {
  alias                      = "Infrastructure"
  subscription_id            = "7d94d49b-5cc8-43ed-95bc-0c8e0a16164f"
  skip_provider_registration = "true"
  features {}
}