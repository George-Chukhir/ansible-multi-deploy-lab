
// Create public IP for load balancer 
resource "azurerm_public_ip" "lb_public_ip" {
    name = "${var.prefix}-lb-pip"

    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    sku = "Standard" // Microsoft resricts Basic SKU 
    allocation_method = "Static" // required for Standard SKU 
    
}


// Create network interface for load balancer
resource "azurerm_network_interface" "lb_nic" {
    name = "${var.prefix}-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.subnet.id

        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.lb_public_ip.id
    }
}


// Create network interfaces for each web application VMs
resource "azurerm_network_interface" "web_app_nic"{
    count = 2
    name = "${var.prefix}-web-app${count.index + 1}-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.subnet.id

        private_ip_address_allocation = "Dynamic"
    }
    
}



// Prepare for DB

resource "azurerm_private_dns_zone" "dns_zone" {
    name = "${var.prefix}.postgres.database.azure.com"
    resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
    name = "${var.prefix}-dns-link"
    resource_group_name = azurerm_resource_group.rg.name
    private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
    virtual_network_id = azurerm_virtual_network.vnet.id
    depends_on = [azurerm_subnet.db_subnet] // Ensure the subnet is created before linking the DNS zone
}





resource "azurerm_linux_virtual_machine" "lb_vm" {

    tags = {
        role = "loadbalancer"
    }

    name = "${var.prefix}-lb-vm"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    size = var.vm_size // cheap for testing
    admin_username = "azureuser" // The username of the local administrator used for the Virtual Machine

    // bind VM with network interface
    network_interface_ids = [azurerm_network_interface.lb_nic.id]  

    // add mine ssh key to have ability to connect to VM for me and Ansible 
    admin_ssh_key {
        username = "azureuser"
        public_key = var.ssh_rsa_public_key // path to your public SSH key
    }

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 30 // optional, bcs defalt is 30 GB
    }

    // specify image type for VM
    source_image_reference {
        publisher = "Canonical"
        offer = "0001-com-ubuntu-server-jammy"
        sku = "22_04-lts-gen2"
        version = "latest"
    }

}


resource "azurerm_linux_virtual_machine" "web_app_vm" {

    tags = {
        role = "web-server"
    }

    count = var.web_app_count
    
    name = "${var.prefix}-web-app${count.index + 1}-vm"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    size = var.vm_size 
    admin_username = "azureuser" 

    // bind VM with network interface
    network_interface_ids = [azurerm_network_interface.web_app_nic[count.index].id]  

    // add mine ssh key to have ability to connect to VM for me and Ansible 
    admin_ssh_key {
        username = "azureuser"
        public_key = var.ssh_rsa_public_key // path to your public SSH key
    }

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 30 // optional, bcs defalt is 30 GB
    }

    // specify image type for VM
    source_image_reference {
        publisher = "Canonical"
        offer = "0001-com-ubuntu-server-jammy"
        sku = "22_04-lts-gen2"
        version = "latest"
    }

}



resource "azurerm_postgresql_flexible_server" "postgresql_server" {

    tags = {
        role = "postgresql-database"
    }

    name = "${var.prefix}-postgresql-server"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    version = "12"

    delegated_subnet_id = azurerm_subnet.db_subnet.id
   
    private_dns_zone_id = azurerm_private_dns_zone.dns_zone.id
    public_network_access_enabled = false 

    administrator_login = var.db_admin_username
    administrator_password = var.db_admin_password    

    storage_mb = 32768 // minimum for PostgreSQL Flexible Server

    sku_name = var.postgre_db_size 
    depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_link] // Ensure the DNS zone is created before the PostgreSQL server]
}