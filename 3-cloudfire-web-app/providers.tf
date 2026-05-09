terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~>3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~>2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from environment
}
