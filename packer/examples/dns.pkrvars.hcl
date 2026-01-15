# =============================================================================
# Packer Variables - Windows Server 2022 Core - DNS Server Role
# =============================================================================
# DNS Server
# Usage: packer build -only="*.dns" -var-file=examples/dns.pkrvars.hcl .
#
# Required environment variables:
#   PKR_VAR_connectwise_token  - ConnectWise agent authentication token
#   PKR_VAR_winrm_password     - WinRM administrator password
# =============================================================================

# Azure Authentication
use_azure_cli_auth = true

# Build Infrastructure
build_resource_group_name = "packer-rg"
vm_size                   = "Standard_D2s_v3"

# WinRM Communication
communicator   = "winrm"
winrm_username = "packer"
winrm_timeout  = "15m"
winrm_use_ssl  = true
winrm_insecure = true

# Windows Server 2022 Core Image
image_publisher = "MicrosoftWindowsServer"
image_offer     = "WindowsServer"
image_sku       = "2022-datacenter-core"
os_type         = "Windows"

# Output Image
managed_image_name                = "WindowsServer2022-Core-DNS"
managed_image_resource_group_name = "packer-rg"
image_name_prefix                 = "VM"

# Server Role
server_role               = "dns"
install_connectwise_agent = true

# Tags
azure_tags = {
  Project     = "Packer-ServerRoles"
  Application = "DNSServer"
  Role        = "DNS"
}
