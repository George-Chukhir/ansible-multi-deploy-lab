
output "lb_public_ip" {
    value = azurerm_public_ip.lb_public_ip.ip_address
    description = "Public IP address of the load balancer VM"
}


// We will use ProxyJump.
// Ansible can't connect to private IPs, but he can see prublic ip of load balancer VM. 
// And via pip of load balancer VM Ansible can connect to private IPs of web application VMs.

output "web_app_private_ips" {
    // "*" says to terraform "get all elements of the list"
    value = azurerm_network_interface.web_app_nic[*].private_ip_address
    description = "Private IP addresses of the web application VMs"
}


output "web_app_count" {
    value = var.web_app_count
    description = "Number of web application VMs created"
}

output "db_fqdn" {
    value = azurerm_postgresql_flexible_server.postgresql_server.fqdn
    description = "Private IP address of the PostgreSQL database"
}


output "resource_group_name" {
    value = azurerm_resource_group.rg.name
    description = "Name of the resource group where all resources are created"
}
