# =============================================================================
# Packer Variables - Windows Server Image Build
# =============================================================================
# This file defines all variables for building Windows Server images on Azure.
# Use a .pkrvars.hcl or .auto.pkrvars.hcl file to set variable values.
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Authentication Variables
# -----------------------------------------------------------------------------

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID for image deployment"
  default     = null

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID for authentication"
  default     = null

  validation {
    condition     = var.tenant_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "use_azure_cli_auth" {
  type        = bool
  description = "Use Azure CLI authentication context instead of service principal"
  default     = true
}

# -----------------------------------------------------------------------------
# Build Infrastructure Variables
# -----------------------------------------------------------------------------

variable "build_resource_group_name" {
  type        = string
  description = "Resource Group where the temporary build VM will be created"

  validation {
    condition     = length(var.build_resource_group_name) > 0 && length(var.build_resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "vm_size" {
  type        = string
  description = "Azure VM SKU for the temporary build VM"
  default     = "Standard_D2s_v3"

  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "VM size must be a valid Azure VM SKU (e.g., Standard_D2s_v3)."
  }
}

# -----------------------------------------------------------------------------
# WinRM Communication Variables
# -----------------------------------------------------------------------------

variable "communicator" {
  type        = string
  description = "Communication method for provisioners (winrm for Windows)"
  default     = "winrm"

  validation {
    condition     = contains(["winrm", "ssh", "none"], var.communicator)
    error_message = "Communicator must be one of: winrm, ssh, none."
  }
}

variable "winrm_username" {
  type        = string
  description = "Administrator username for WinRM connection"
  default     = "packer"

  validation {
    condition     = length(var.winrm_username) >= 1 && length(var.winrm_username) <= 20
    error_message = "WinRM username must be between 1 and 20 characters."
  }
}

variable "winrm_password" {
  type        = string
  description = "Administrator password for WinRM connection"
  sensitive   = true

  validation {
    condition     = length(var.winrm_password) >= 12
    error_message = "WinRM password must be at least 12 characters for security compliance."
  }
}

variable "winrm_timeout" {
  type        = string
  description = "Timeout duration for WinRM connection and provisioner execution"
  default     = "10m"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.winrm_timeout))
    error_message = "WinRM timeout must be a valid duration (e.g., 5m, 10m, 1h)."
  }
}

variable "winrm_use_ssl" {
  type        = bool
  description = "Enable SSL/TLS for WinRM connection"
  default     = true
}

variable "winrm_insecure" {
  type        = bool
  description = "Allow insecure WinRM connections (skip certificate validation)"
  default     = true
}

# -----------------------------------------------------------------------------
# Windows Server Image Source Variables
# -----------------------------------------------------------------------------

variable "image_publisher" {
  type        = string
  description = "Azure Marketplace image publisher"
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  type        = string
  description = "Azure Marketplace image offer"
  default     = "WindowsServer"
}

variable "image_sku" {
  type        = string
  description = "Azure Marketplace image SKU (e.g., 2022-datacenter, 2022-datacenter-core)"
  default     = "2022-datacenter-core"

  validation {
    condition     = can(regex("^[0-9]{4}-", var.image_sku))
    error_message = "Image SKU should follow Windows Server naming convention (e.g., 2022-datacenter)."
  }
}

variable "os_type" {
  type        = string
  description = "Operating system type for the image"
  default     = "Windows"

  validation {
    condition     = contains(["Windows", "Linux"], var.os_type)
    error_message = "OS type must be either Windows or Linux."
  }
}

# -----------------------------------------------------------------------------
# Output Image Variables
# -----------------------------------------------------------------------------

variable "managed_image_name" {
  type        = string
  description = "Name for the output managed image"

  validation {
    condition     = length(var.managed_image_name) > 0 && length(var.managed_image_name) <= 80
    error_message = "Managed image name must be between 1 and 80 characters."
  }
}

variable "managed_image_resource_group_name" {
  type        = string
  description = "Resource Group where the managed image will be stored"

  validation {
    condition     = length(var.managed_image_resource_group_name) > 0 && length(var.managed_image_resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix to prepend to the managed image name"
  default     = "VM"
}

# -----------------------------------------------------------------------------
# Tagging Variables
# -----------------------------------------------------------------------------

variable "azure_tags" {
  type        = map(string)
  description = "Tags to apply to the managed image"
  default     = {}
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags applied to all resources (merged with azure_tags)"
  default = {
    ManagedBy   = "Packer"
    Environment = "non-prod"
  }
}

# -----------------------------------------------------------------------------
# ConnectWise Manage Agent Variables
# -----------------------------------------------------------------------------

variable "connectwise_token" {
  type        = string
  description = "ConnectWise Manage agent authentication token for winget repository"
  sensitive   = true
  default     = null
}

variable "connectwise_repo_url" {
  type        = string
  description = "URL of the private winget repository for ConnectWise agent"
  default     = "https://myrepo.company.com"

  validation {
    condition     = can(regex("^https://", var.connectwise_repo_url))
    error_message = "ConnectWise repo URL must use HTTPS."
  }
}

variable "install_connectwise_agent" {
  type        = bool
  description = "Whether to install ConnectWise Manage agent on the image"
  default     = true
}

# -----------------------------------------------------------------------------
# Server Role Configuration Variables
# -----------------------------------------------------------------------------

variable "server_role" {
  type        = string
  description = "Windows Server role identifier for the image"
  default     = "base"

  validation {
    condition = contains([
      "base",
      "webserver",
      "adds",
      "fileservices",
      "printservices",
      "dns",
      "dhcp",
      "hyperv",
      "adcs"
    ], var.server_role)
    error_message = "Server role must be one of: base, webserver, adds, fileservices, printservices, dns, dhcp, hyperv, adcs."
  }
}
