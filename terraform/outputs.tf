
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


