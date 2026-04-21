// specify the cloud provider;
//provider convert tf code to cloud specific API calls
terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm" // like the link to azure plugin for terraform registry
            version = "~> 3.0"
        }
    }
}

// configure the provider 
provider "azurerm" {
    features {}
}

// create a resource group (as in azure web portal)
resource "azurerm_resource_group" "rg" {
    name     = "${var.prefix}-rg"
    location = "${var.location}" //location of resource group, not the location of the resources
}




