# =============================================================================
# Packer Variables - Windows Server 2022 Core - Hyper-V Role
# =============================================================================
# Hyper-V Virtualisation
# Usage: packer build -only="*.hyperv" -var-file=examples/hyperv.pkrvars.hcl .
#
# IMPORTANT: Requires Azure VM size with nested virtualisation support
#            (Dv3, Ev3, or newer series)
#
# Required environment variables:
#   PKR_VAR_connectwise_token  - ConnectWise agent authentication token
#   PKR_VAR_winrm_password     - WinRM administrator password
# =============================================================================

# Azure Authentication
use_azure_cli_auth = true

# Build Infrastructure - Use VM size with nested virtualisation support
build_resource_group_name = "packer-rg"
vm_size                   = "Standard_D4s_v3"

# WinRM Communication - Longer timeout for Hyper-V installation
communicator   = "winrm"
winrm_username = "packer"
winrm_timeout  = "20m"
winrm_use_ssl  = true
winrm_insecure = true

# Windows Server 2022 Core Image
image_publisher = "MicrosoftWindowsServer"
image_offer     = "WindowsServer"
image_sku       = "2022-datacenter-core"
os_type         = "Windows"

# Output Image
managed_image_name                = "WindowsServer2022-Core-HyperV"
managed_image_resource_group_name = "packer-rg"
image_name_prefix                 = "VM"

# Server Role
server_role               = "hyperv"
install_connectwise_agent = true

# Tags
azure_tags = {
  Project              = "Packer-ServerRoles"
  Application          = "Virtualisation"
  Role                 = "HyperV"
  NestedVirtualisation = "Required"
}
