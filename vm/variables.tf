variable "spoke_vnets" {}
variable "spoke_subnets" {}
variable "spoke_ip_addresses" {}
# variable "diagnostics_storage_accounts" {}

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

# -----------------------------------------------------------------------------
# Packer Image Variables
# -----------------------------------------------------------------------------

variable "packer_images" {
  description = "Map of Packer-built managed images to use for VMs. Key is the server role (e.g., 'adds', 'dns')"
  type = map(object({
    name                = string
    resource_group_name = string
  }))
  default = {}
}

variable "packer_image_resource_group" {
  description = "Default resource group containing Packer-built images"
  type        = string
  default     = "packer-rg"
}
