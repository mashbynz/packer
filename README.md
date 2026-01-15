# Azure Packer Windows Server Image Builder

Build custom Windows Server images on Azure using HashiCorp Packer with Terraform-managed infrastructure.

## Overview

This repository provides:

- **Terraform**: Deploys Azure infrastructure (VNet, Bastion, Resource Groups) in Australia East
- **Packer**: Creates custom Windows Server images with pre-configured software
- **Azure Bastion**: Secure RDP access to test VMs built from custom images

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0.0
- [Packer](https://www.packer.io/downloads) >= 1.9.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.40.0
- Azure subscription with Contributor access

## Quick Start - Building a Windows Server 2022 Image

### 1. Authenticate to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply infrastructure
terraform apply
```

### 3. Build the Windows Server Image with Packer

```bash
cd packer

# Initialize Packer plugins
packer init .

# Validate the configuration
packer validate -var-file=example.pkrvars.hcl .

# Build the image
packer build -var-file=example.pkrvars.hcl .
```

## Packer Configuration

### Directory Structure

```
packer/
├── windows.pkr.hcl          # Main build configuration
├── variables.pkr.hcl        # Variable definitions with validation
├── example.pkrvars.hcl      # Example variable values
└── scripts/
    └── webServer.ps1        # PowerShell provisioning script
```

### Windows Server 2022 Standard Example

Create a file named `windows-server.auto.pkrvars.hcl` in the `packer/` directory:

```hcl
# Azure Authentication (uses Azure CLI by default)
use_azure_cli_auth = true

# Build Infrastructure
build_resource_group_name = "packer-rg"
vm_size                   = "Standard_D2s_v3"

# WinRM Communication
communicator   = "winrm"
winrm_username = "packer"
winrm_password = "YourSecurePassword123!"  # Use a strong password
winrm_timeout  = "10m"
winrm_use_ssl  = true
winrm_insecure = true

# Windows Server 2022 Standard Image
image_publisher = "MicrosoftWindowsServer"
image_offer     = "WindowsServer"
image_sku       = "2022-datacenter"
os_type         = "Windows"

# Output Image
managed_image_name                = "WindowsServer2022-Standard"
managed_image_resource_group_name = "packer-rg"
image_name_prefix                 = "VM"

# Tags
azure_tags = {
  Project     = "Packer-Demo"
  Owner       = "your-email@domain.com"
  Application = "WebServer"
}
```

### Alternative Windows Server SKUs

| SKU | Description |
|-----|-------------|
| `2022-datacenter` | Windows Server 2022 Datacenter (Desktop Experience) |
| `2022-datacenter-core` | Windows Server 2022 Datacenter Core |
| `2022-datacenter-smalldisk` | Windows Server 2022 with smaller OS disk |
| `2022-datacenter-azure-edition` | Azure-optimised Windows Server 2022 |
| `2019-datacenter` | Windows Server 2019 Datacenter |

### Packer Commands Reference

```bash
# Initialize plugins (required once)
packer init .

# Validate configuration syntax
packer validate -var-file=<your-vars>.pkrvars.hcl .

# Build with verbose output
packer build -var-file=<your-vars>.pkrvars.hcl .

# Build with debug logging
PACKER_LOG=1 packer build -var-file=<your-vars>.pkrvars.hcl .

# Build with specific variables
packer build \
  -var "managed_image_name=MyCustomImage" \
  -var "image_sku=2022-datacenter-core" \
  -var-file=<your-vars>.pkrvars.hcl .
```

### Sensitive Variables

For production use, pass sensitive values via environment variables:

```bash
export PKR_VAR_winrm_password="YourSecurePassword123!"
packer build -var-file=<your-vars>.pkrvars.hcl .
```

## Terraform Configuration

### Architecture Diagram

![Architecture](assets/Packer%20Demo.png)

### State File Configuration

Configure backend storage in your `.auto.tfvars`:

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
      CustomerName = "Internal"
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
      tags = {
        product = "packer"
      }
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
      tags = {
        product = "packer"
      }
    }
  }
  peerings = {}
}
```

### Public IP Configuration

```hcl
ip_suffix = "-pip"

IP_address_object = {
  public = {
    region1_bastion_ip = {
      name                = "packer"
      resource_group_name = "packer-rg"
      location            = "australiaeast"
      allocation_method   = "Static"
      sku                 = "Standard"
      ip_version          = "IPv4"
      tags = {
        product = "packer"
      }
    }
  }
}
```

### Test VM Configuration

Deploy a VM from your custom image to verify the build:

```hcl
vm_suffix      = "-vm"
os_disk_suffix = "-osdisk"
disk_suffix    = "-disk"
nic_suffix     = "-nic"

vm_object = {
  vms = {
    region1_vm1 = {
      name                          = "packer"
      resource_group_name           = "packer-rg"
      location                      = "australiaeast"
      size                          = "Standard_D2s_v3"
      os                            = "Windows"
      delete_os_disk_on_termination = true
      network_interface_ids         = "region1_vm1_nic"
      admin_username                = "packeradm"
      admin_password                = "P@ssw0rd1!"
      os_profile = {
        provision_vm_agent = true
        license_type       = "Windows_Server"
      }
      storage_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
      }
      storage_os_disk = {
        caching              = "ReadWrite"
        create_option        = "FromImage"
        storage_account_type = "Standard_LRS"
        disk_size_gb         = "128"
      }
      boot_diagnostics = {
        storage_account_uri = "region1_diagnostics_storage"
      }
      tags = {
        product  = "packer"
        role     = "packer demo"
        location = "Australia East"
      }
    }
  }
  nics = {
    region1_vm1_nic = {
      name                = "packer"
      resource_group_name = "packer-rg"
      location            = "australiaeast"
      ip_configuration = {
        config_1 = {
          name                          = "ip_config_1"
          subnet_id                     = "region1_packer_subnet"
          private_ip_address_allocation = "Dynamic"
          public_ip_address_id          = null
          primary                       = true
        }
      }
      tags = {
        product  = "packer"
        role     = "packer demo"
        location = "Australia East"
      }
    }
  }
  data_disks = {
    region1_vm1_disk1 = {
      name                 = "packer"
      virtual_machine      = "region1_vm1"
      resource_group_name  = "packer-rg"
      location             = "australiaeast"
      storage_account_type = "Premium_LRS"
      create_option        = "Empty"
      disk_size_gb         = 128
      disk_letter          = "-F"
      disk_count           = "01"
      lun                  = "10"
      caching              = "ReadWrite"
      tags = {
        product  = "packer"
        role     = "packer demo"
        location = "Australia East"
      }
    }
  }
}
```

## Customising the Image

### Adding Software

Edit `packer/scripts/webServer.ps1` to install additional software:

```powershell
# Install additional Windows features
Install-WindowsFeature -Name NET-Framework-45-Core -IncludeManagementTools

# Install software via Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install -y 7zip
choco install -y notepadplusplus
```

### Adding Multiple Provisioning Scripts

Add additional provisioners in `windows.pkr.hcl`:

```hcl
build {
  # ... existing configuration ...

  provisioner "powershell" {
    script = "${path.root}/scripts/webServer.ps1"
  }

  provisioner "powershell" {
    script = "${path.root}/scripts/security-hardening.ps1"
  }

  provisioner "powershell" {
    script = "${path.root}/scripts/install-monitoring.ps1"
  }

  # Sysprep provisioner (must be last)
  provisioner "powershell" {
    inline = [
      # ... sysprep commands ...
    ]
  }
}
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| WinRM connection timeout | Increase `winrm_timeout` value (e.g., `15m`) |
| Authentication failure | Verify `az login` session is active |
| Resource group not found | Ensure Terraform infrastructure is deployed first |
| Sysprep failure | Check Azure agent services are running |

### Enable Debug Logging

```bash
export PACKER_LOG=1
export PACKER_LOG_PATH="packer-debug.log"
packer build -var-file=<your-vars>.pkrvars.hcl .
```

## Security Considerations

- Store sensitive values in environment variables or Azure Key Vault
- Use strong passwords for WinRM (minimum 12 characters)
- Review and customise the provisioning scripts for your security requirements
- Consider using Azure Private Endpoints for production builds

## License

This project is for internal testing and demonstration purposes.
