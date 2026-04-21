variable "prefix" {
  type        = string
  default     = "ansible-lab"
  description = "Prefix for all resources created by this module. For easy managing name of project "
}

variable "location" {
  type        = string
  default     = "italynorth"
  description = "Azure region where resources will be created."
}


