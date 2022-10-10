variable "tags" {
  default     = ""
  description = "(Required) tags for the deployment"
}

variable "rg_suffix" {
  description = "(Optional) You can use a suffix to add to the list of Resource Groups you want to create"
}

variable "resource_groups" {
  description = "(Required) Map of the Resource Groups to create"
}

variable "nsg_suffix" {
  description = "(Optional) You can use a suffix to add to the Network Security Groups you want to create"
  type        = string
}

variable "vnet_suffix" {
  description = "(Optional) You can use a suffix to add to the list of Virtual Networks you want to create"
  type        = string
}

variable "rt_suffix" {
  description = "(Optional) You can use a suffix to add to the list of Route Tables you want to create"
  type        = string
}

variable "networking_object" {
  description = "(Required) configuration object describing the networking configuration, as described in README"
}

variable "IP_address_object" {
  description = "(Required) configuration object describing the IP Address configuration"
}

variable "ip_suffix" {
  description = "(Optional) You can use a suffix to add to the list of IP Addresses you want to create"
  type        = string
}
