# build_resource_group_name         = "packer-rg"
# communicator                      = "winrm"
# image_offer                       = "WindowsServer"
# image_publisher                   = "MicrosoftWindowsServer"
# image_sku                         = "2022-Datacenter"
# managed_image_name                = "myPackerImage"
# managed_image_resource_group_name = "packer-rg"
# os_type                           = "Windows"
# subscription_id                   = "635b2aee-1f07-404d-9851-5b4f8a84cf13"
# tenant_id                         = "a4d44117-bb20-4668-a0dc-16fcb91100b7"
# vm_size                           = "Standard_D2s_v3"
# winrm_insecure                    = true
# winrm_timeout                     = "5m"
# winrm_use_ssl                     = true
# winrm_username                    = "packer"
# use_azure_cli_auth                = true # uses the az login user context to build the VM. User account must have access to build a new VM in the target RG
# azure_tags = {
#   product = "packer"
#   role    = "packer demo"
# }

# Windows Server
variable "w22build_resource_group_name" {
  description = "(Required) Resource Group to deploy the Image into"
}

variable "w22communicator" {
  description = "(Required) How packer will communicate with the provisioner"
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

variable "w22subscription_id" {
description = "(Optional) Subscription ID"
}

variable "w22tenant_id" {
  description = "(Optional) Tenant ID"
}

variable "w22vm_size" {
  description = "(Optional) SKU for the VM used to buid the Image"
}

variable "w22winrm_insecure" {
  description = "(Optional) Boot mode for the Image"
  type        = bool
}

variable "w22winrm_timeout" {
  description = "(Optional) Period to wait while executing inline PowerShell script(s)"
}

variable "w22winrm_use_ssl" {
  description = "(Required) Enable SSL in the built Image?"
  type        = bool
}

variable "w22winrm_username" {
  description = "(Required) Admin Username for the built Image"
}

variable "w22use_azure_cli_auth" {
  description = "(Required) use the user context for auth to the RG"
  type        = bool
}

variable "w22azure_tags" {
  description = "(Required) List the tags for the Image object"
}
