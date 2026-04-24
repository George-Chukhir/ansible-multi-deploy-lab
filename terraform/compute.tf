
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





resource "azurerm_linux_virtual_machine" "lb_vm" {
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
        public_key = file("~/.ssh/id_rsa.pub") // path to your public SSH key
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
    count = 2
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
        public_key = file("~/.ssh/id_rsa.pub") // path to your public SSH key
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