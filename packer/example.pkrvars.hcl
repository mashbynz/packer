# =============================================================================
# Example Packer Variables File - Windows Server 2022 Standard
# =============================================================================
# Copy this file to windows-server.auto.pkrvars.hcl and update the values.
# Files with .auto.pkrvars.hcl extension are automatically loaded by Packer.
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Authentication
# -----------------------------------------------------------------------------
# Uncomment and set these if not using Azure CLI authentication
# subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Use Azure CLI authentication (az login)
use_azure_cli_auth = true

# -----------------------------------------------------------------------------
# Build Infrastructure
# -----------------------------------------------------------------------------
# Resource group must exist before running Packer
build_resource_group_name = "packer-rg"

# VM size for the temporary build VM
vm_size = "Standard_D2s_v3"

# -----------------------------------------------------------------------------
# WinRM Communication
# -----------------------------------------------------------------------------
communicator   = "winrm"
winrm_username = "packer"
winrm_password = "YourSecurePassword123!"  # Change this!
winrm_timeout  = "10m"
winrm_use_ssl  = true
winrm_insecure = true

# -----------------------------------------------------------------------------
# Windows Server 2022 Standard Image Source
# -----------------------------------------------------------------------------
image_publisher = "MicrosoftWindowsServer"
image_offer     = "WindowsServer"
image_sku       = "2022-datacenter"
os_type         = "Windows"

# -----------------------------------------------------------------------------
# Output Image Configuration
# -----------------------------------------------------------------------------
managed_image_name                = "WindowsServer2022-Standard"
managed_image_resource_group_name = "packer-rg"
image_name_prefix                 = "VM"

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
azure_tags = {
  Project     = "Packer-Demo"
  Owner       = "your-email@domain.com"
  CostCenter  = "IT"
  Application = "WebServer"
}
