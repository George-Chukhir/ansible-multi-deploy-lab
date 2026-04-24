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




