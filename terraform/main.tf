// specify the cloud provider;
//provider convert tf code to cloud specific API calls
terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm" // like the link to azure plugin for terraform registry
            version = "~> 3.0"
        }
    }


    // account storage 
    backend "azurerm" {
        resource_group_name  = "terraform_state-rg"
        storage_account_name = "tfstatechukhir"
        container_name       = "tfstatecontainer"
        key                  = "terraform.tfstate" // name of the file in cloud storage 
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




// Code for creating storage account

# resource "random_string" "storage_account_name" {
#     length = 8
#     special = false
#     upper = false
#     lower = true
#     numeric = true

#     public_network_access_enabled = true // allow jenkins to store tfstate 
# }

# resource "azurerm_storage_account" "storage_account" {
#     name = "tfstate${random_string.storage_account_name.result}"
#     resource_group_name = azurerm_resource_group.rg.name
#     location = azurerm_resource_group.rg.location
#     account_tier = "Standard"
#     account_replication_type = "LRS"
#     account_kind = "StorageV2"
#     min_tls_version = "TLS1_2"
#     allow_nested_items_to_be_public = false
# }

# //create folder in it  
# resource "azurerm_storage_container" "tfstate_container" {
#     name = "tfstate"
#     storage_account_name = azurerm_storage_account.storage_account.name
#     container_access_type = "private"
# }