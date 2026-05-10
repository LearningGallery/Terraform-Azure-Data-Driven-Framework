terraform {
  # Require Terraform Core version 1.2 or higher for lifecycle preconditions
  required_version = ">= 1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Pin to major version 3, allowing minor updates but preventing breaking v4 changes
      version = "~> 3.0"
    }
  }
}