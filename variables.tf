# State file variables
variable "lowerlevel_storage_account_name" {}
variable "lowerlevel_container_name" {}
variable "lowerlevel_resource_group_name" {}
variable "lowerlevel_key" {}
variable "subscription_id" {}

variable "tags" {
  default     = ""
  description = "(Required) tags for the deployment"
}

variable "rg_suffix" {
  description = "(Optional) You can use a suffix to add to the list of resource groups you want to create"
}

variable "resource_groups" {
  description = "(Required) Map of the resource groups to create"
}

variable "vnet_suffix" {
  description = "(Optional) You can use a suffix to add to the list of virtual networks you want to create"
  type        = string
}

variable "nsg_suffix" {
  description = "(Optional) You can use a suffix to add to the Network Security Groups you want to create"
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

variable "vm_suffix" {
  description = "(Optional) You can use a suffix to add to the list of Virtual Machines you want to create"
  type        = string
}

variable "os_disk_suffix" {
  description = "(Optional) You can use a suffix to add to the OS Disk of the Virtual Machine you want to create"
  type        = string
}

variable "disk_suffix" {
  description = "(Optional) You can use a suffix to add to the Data Disk(s) of the Virtual Machine you want to create"
  type        = string
}

variable "nic_suffix" {
  description = "(Optional) You can use a suffix to add to the NICs you want to create"
  type        = string
}

variable "vm_object" {
  description = "(Required) configuration object describing the Virtual Machine configuration"
}
