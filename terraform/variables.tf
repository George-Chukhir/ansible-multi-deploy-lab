variable "prefix" {
  type        = string
  default     = "ansible-lab"
  description = "Prefix for all resources created by this module. For easy managing name of project "
}

variable "location" {
  type        = string
  default     = "Spain Central"
  description = "Azure region where resources will be created."
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2as_v2"
  description = "Size of the virtual machine. Standard_B2as_v2 is a cost-effective option for testing and development purposes."
}


variable "web_app_count" {
  type        = number
  default     = 2
  description = "Number of web application VMs to create."
}

variable "postgre_db_size" {
  type       = string
  default     = "B_Standard_B1ms"
  description = "Size of the PostgreSQL database."
}


variable "db_admin_username" {
  type       = string
  description = "The username of the local administrator used for the PostgreSQL database."
  sensitive   = true // will prevent displaying the value in logs, tfstate, etc.
}


variable "db_admin_password" {
  type       = string
  description = "The password of the local administrator used for the PostgreSQL database."
  sensitive   = true
}

