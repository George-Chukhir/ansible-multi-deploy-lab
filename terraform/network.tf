
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.prefix}-vnet"
    address_space       = ["10.0.0.0/16"]

    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name

    address_prefixes     = ["10.0.1.0/24"] // 256 addresses, 254 for hosts
}


resource "azurerm_subnet" "db_subnet" {
    name                 = "${var.prefix}-db-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name

    address_prefixes     = ["10.0.2.0/24"] 


    // Flexible Server won't "accomodate" in common subnet, so we have to declare that this subnet is delegated to PostgreSQL service
    delegation {
        name = "postgre_db_delegation"
        service_delegation {
            name = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
    }

}


