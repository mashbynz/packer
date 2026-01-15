# Azure Packer Windows Server Image Builder

Build custom Windows Server Core images on Azure using HashiCorp Packer with Terraform-managed infrastructure.

## Overview

This repository provides:

- **Terraform**: Deploys Azure infrastructure (VNet, Bastion, Resource Groups) in Australia East
- **Packer**: Creates custom Windows Server Core images with pre-configured server roles
- **Azure Bastion**: Secure RDP access to test VMs built from custom images
- **ConnectWise Manage**: All images include the ConnectWise Manage agent for remote management

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0.0
- [Packer](https://www.packer.io/downloads) >= 1.9.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.40.0
- Azure subscription with Contributor access

## Supported Server Roles

All images are Windows Server 2022 Core (no GUI) with ConnectWise Manage agent pre-installed.

| Role | Build Target | Description |
|------|--------------|-------------|
| Web Server | `*.webserver` | IIS Web Server |
| ADDS | `*.adds` | Active Directory Domain Services |
| File Services | `*.fileservices` | File and Storage Services with DFS |
| Print Services | `*.printservices` | Print and Document Services |
| DNS | `*.dns` | DNS Server |
| DHCP | `*.dhcp` | DHCP Server |
| Hyper-V | `*.hyperv` | Hyper-V (requires nested virtualisation) |
| ADCS | `*.adcs` | Active Directory Certificate Services |

## Quick Start

### 1. Authenticate to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Deploy Infrastructure with Terraform

```bash
terraform init
terraform plan
terraform apply
```

### 3. Build a Server Role Image

```bash
cd packer

# Set required credentials
export PKR_VAR_connectwise_token="your-connectwise-token"
export PKR_VAR_winrm_password="YourSecurePassword123!"

# Initialize Packer plugins
packer init .

# Build a specific role (e.g., DNS Server)
packer build -only="*.dns" -var-file=examples/dns.pkrvars.hcl .
```

## Packer Configuration

### Directory Structure

```
packer/
├── variables.pkr.hcl              # Shared variable definitions
├── locals.pkr.hcl                 # Shared local values
├── roles/                         # Role-specific build files
│   ├── webserver.pkr.hcl
│   ├── adds.pkr.hcl
│   ├── fileservices.pkr.hcl
│   ├── printservices.pkr.hcl
│   ├── dns.pkr.hcl
│   ├── dhcp.pkr.hcl
│   ├── hyperv.pkr.hcl
│   └── adcs.pkr.hcl
├── scripts/
│   ├── common/                    # Shared provisioning scripts
│   │   ├── Install-ConnectWiseAgent.ps1
│   │   ├── Set-CommonConfiguration.ps1
│   │   └── Invoke-Sysprep.ps1
│   └── roles/                     # Role-specific install scripts
│       ├── Install-WebServer.ps1
│       ├── Install-ADDS.ps1
│       ├── Install-FileServices.ps1
│       ├── Install-PrintServices.ps1
│       ├── Install-DNS.ps1
│       ├── Install-DHCP.ps1
│       ├── Install-HyperV.ps1
│       └── Install-ADCS.ps1
└── examples/                      # Example variable files per role
    ├── webserver.pkrvars.hcl
    ├── adds.pkrvars.hcl
    ├── fileservices.pkrvars.hcl
    ├── printservices.pkrvars.hcl
    ├── dns.pkrvars.hcl
    ├── dhcp.pkrvars.hcl
    ├── hyperv.pkrvars.hcl
    └── adcs.pkrvars.hcl
```

### Building Role-Specific Images

```bash
cd packer

# Set credentials (required)
export PKR_VAR_connectwise_token="your-token"
export PKR_VAR_winrm_password="SecurePassword123!"

# Initialize Packer plugins (once)
packer init .

# Build specific roles
packer build -only="*.adds" -var-file=examples/adds.pkrvars.hcl .
packer build -only="*.dns" -var-file=examples/dns.pkrvars.hcl .
packer build -only="*.dhcp" -var-file=examples/dhcp.pkrvars.hcl .
packer build -only="*.fileservices" -var-file=examples/fileservices.pkrvars.hcl .
packer build -only="*.printservices" -var-file=examples/printservices.pkrvars.hcl .
packer build -only="*.hyperv" -var-file=examples/hyperv.pkrvars.hcl .
packer build -only="*.adcs" -var-file=examples/adcs.pkrvars.hcl .
packer build -only="*.webserver" -var-file=examples/webserver.pkrvars.hcl .
```

### ConnectWise Manage Agent

All images include the ConnectWise Manage agent installed from a private winget repository.

**Required Environment Variable:**
```bash
export PKR_VAR_connectwise_token="your-authentication-token"
```

The agent is installed using:
```
winget install --source https://myrepo.company.com --header "{'Token': '<token>'}" --silent
```

To skip agent installation, set in your `.pkrvars.hcl`:
```hcl
install_connectwise_agent = false
```

### Example: Building a Windows Server 2022 ADDS Image

1. Create or copy the example variables file:
```bash
cp examples/adds.pkrvars.hcl my-adds.auto.pkrvars.hcl
```

2. Edit the file with your settings:
```hcl
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

# Windows Server 2022 Core
image_publisher = "MicrosoftWindowsServer"
image_offer     = "WindowsServer"
image_sku       = "2022-datacenter-core"
os_type         = "Windows"

# Output Image
managed_image_name                = "WindowsServer2022-Core-ADDS"
managed_image_resource_group_name = "packer-rg"
image_name_prefix                 = "VM"

# Server Role
server_role               = "adds"
install_connectwise_agent = true

# Tags
azure_tags = {
  Project     = "Infrastructure"
  Application = "DomainController"
  Role        = "ADDS"
}
```

3. Build the image:
```bash
export PKR_VAR_connectwise_token="your-token"
export PKR_VAR_winrm_password="SecurePassword123!"

packer build -only="*.adds" -var-file=my-adds.auto.pkrvars.hcl .
```

### Special Requirements

**Hyper-V Images:**
- Require Azure VM sizes with nested virtualisation support
- Use `Standard_D4s_v3` or larger (Dv3, Ev3, or newer series)
- Default timeout increased to 20 minutes

**ADDS/ADCS Images:**
- Server roles are installed but NOT configured
- Domain promotion or CA configuration must be performed post-deployment

## Packer Commands Reference

```bash
# Initialize plugins (required once)
packer init .

# Validate a specific role
packer validate -only="*.dns" -var-file=examples/dns.pkrvars.hcl .

# Build with debug logging
PACKER_LOG=1 packer build -only="*.dns" -var-file=examples/dns.pkrvars.hcl .

# Build with variable overrides
packer build \
  -only="*.dns" \
  -var "managed_image_name=CustomDNSImage" \
  -var-file=examples/dns.pkrvars.hcl .
```

## Terraform Configuration

### Architecture Diagram

![Architecture](assets/Packer%20Demo.png)

### State File Configuration

```hcl
lowerlevel_storage_account_name = "tfstorageaccount"
lowerlevel_container_name       = "tfstate"
lowerlevel_resource_group_name  = "tfstate-rg"
lowerlevel_key                  = "packer/state.tfstate"
subscription_id                 = "<subscription-id>"
```

### Resource Group Configuration

```hcl
rg_suffix = "-rg"

resource_groups = {
  region1_spoke_resource_group = {
    name     = "packer"
    location = "australiaeast"
    tags = {
      IsBillable   = "false"
      CreatedBy    = "your-email@domain.com"
      Environment  = "dev"
      Project      = "Internal"
    }
  }
}
```

### Network Configuration

```hcl
vnet_suffix = "-vnet"
nsg_suffix  = "-nsg"
rt_suffix   = "-rt"

networking_object = {
  vnet = {
    region1_packer_vnet = {
      name               = "packer"
      location           = "australiaeast"
      virtual_network_rg = "packer-rg"
      address_space      = ["10.0.0.0/25"]
      enable_ddos_std    = false
      tags = { product = "packer" }
    }
  }
  specialsubnets = {
    region1_BastionSubnet = {
      name                 = "AzureBastionSubnet"
      cidr                 = ["10.0.0.0/26"]
      location             = "australiaeast"
      virtual_network_rg   = "packer-rg"
      virtual_network_name = "packer-vnet"
      service_endpoints    = []
      nsg_inbound          = []
      nsg_outbound         = []
    }
  }
  bastion = {
    region1_packer_bastion = {
      name                   = "bastion"
      location               = "australiaeast"
      virtual_network_rg     = "packer-rg"
      copy_paste_enabled     = true
      file_copy_enabled      = false
      sku                    = "Standard"
      ip_connect_enabled     = false
      scale_units            = "2"
      shareable_link_enabled = false
      tunneling_enabled      = false
      ip_configuration = {
        name                 = "ip_config_1"
        subnet_id            = "region1_BastionSubnet"
        public_ip_address_id = "region1_bastion_ip"
      }
    }
  }
  subnets = {
    region1_packer_subnet = {
      name                 = "subnet"
      cidr                 = ["10.0.0.64/27"]
      location             = "australiaeast"
      virtual_network_rg   = "packer-rg"
      virtual_network_name = "packer-vnet"
      service_endpoints    = []
      nsg_inbound          = []
      nsg_outbound         = []
      route_entries        = []
      tags = { product = "packer" }
    }
  }
  peerings = {}
}
```

## Post-Deployment Configuration

### ADDS (Domain Controller)

After deploying a VM from the ADDS image:

```powershell
# Promote to new forest
Install-ADDSForest -DomainName "domain.local" -InstallDns

# Or join existing domain as DC
Install-ADDSDomainController -DomainName "domain.local" -InstallDns -Credential (Get-Credential)
```

### DHCP Server

```powershell
# Authorise in AD
Add-DhcpServerInDC -DnsName "dhcp.domain.local" -IPAddress "10.0.0.2"

# Create scope
Add-DhcpServerv4Scope -Name "LAN" -StartRange 10.0.0.100 -EndRange 10.0.0.200 -SubnetMask 255.255.255.0

# Set options
Set-DhcpServerv4OptionValue -ScopeId 10.0.0.0 -Router 10.0.0.1 -DnsServer 10.0.0.2
```

### ADCS (Certificate Authority)

```powershell
# Configure as Enterprise Root CA
Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -CACommonName "Corp-Root-CA" -KeyLength 4096 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 10

# Configure Web Enrollment
Install-AdcsWebEnrollment
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| WinRM connection timeout | Increase `winrm_timeout` (e.g., `20m` for Hyper-V) |
| Authentication failure | Verify `az login` session is active |
| Resource group not found | Deploy Terraform infrastructure first |
| ConnectWise agent not installing | Check `PKR_VAR_connectwise_token` is set |
| Hyper-V install fails | Use VM size with nested virtualisation (Dv3+) |

### Enable Debug Logging

```bash
export PACKER_LOG=1
export PACKER_LOG_PATH="packer-debug.log"
packer build -only="*.dns" -var-file=examples/dns.pkrvars.hcl .
```

## Security Considerations

- Store `PKR_VAR_connectwise_token` and `PKR_VAR_winrm_password` securely
- Use Azure Key Vault for production credential management
- Review provisioning scripts before deployment
- Use strong passwords (minimum 12 characters)
- Consider Azure Private Endpoints for production builds

## License

This project is for internal testing and demonstration purposes.
