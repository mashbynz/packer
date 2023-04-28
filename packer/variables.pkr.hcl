# General Variables
variable "communicator" {
  description = "(Required) How packer will communicate with the provisioner"
}

variable "subscription_id" {
description = "(Optional) Subscription ID"
}

variable "tenant_id" {
  description = "(Optional) Tenant ID"
}

variable "vm_size" {
  description = "(Optional) SKU for the VM used to buid the Image"
}

variable "winrm_insecure" {
  description = "(Optional) Boot mode for the Image"
  type        = bool
}

variable "winrm_timeout" {
  description = "(Optional) Period to wait while executing inline PowerShell script(s)"
}

variable "winrm_use_ssl" {
  description = "(Required) Enable SSL in the built Image?"
  type        = bool
}

variable "winrm_username" {
  description = "(Required) Admin Username for the built Image"
}

variable "winrm_password" {
  description = "(Required) List the tags for the Image object"
}

variable "use_azure_cli_auth" {
  description = "(Required) use the user context for auth to the RG"
  type        = bool
}

# Windows Server
variable "w22build_resource_group_name" {
  description = "(Required) Resource Group to deploy the Image into"
}

variable "w22image_offer" {
  description = "(Required) Offer ID for the built Image"
}

variable "w22image_publisher" {
  description = "(Optional) Publisher for the built Image"
}

variable "w22image_sku" {
  description = "(Optional) Image SKU"
}

variable "w22managed_image_name" {
description = "(Optional) Name for the built Image"
}

variable "w22managed_image_resource_group_name" {
description = "(Required) RG to deploy the built Image into"
}

variable "w22os_type" {
description = "(Required) OS for the built Image"
}

variable "w22azure_tags" {
  description = "(Required) List the tags for the Image object"
}
