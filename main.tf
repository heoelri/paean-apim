terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.26.0"
    }
  }

  #backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      # Allows the deletion of non-empty resource groups
      # This is required to delete rgs with stale resources left
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  prefix = "paean"
}

resource "azurerm_resource_group" "stamp" {
  name     = "${local.prefix}-rg"
  location = var.location
}