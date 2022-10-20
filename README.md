# Purpose

This repo will build a VNet and Bastion in Azure Australia East and deploy a Windows Server 2022 VM to the network. It will install the DHCP role on the server. The example data structure for the .auto.tfvars file(s) is below.

## Diagram
![](assets/Packer%20Demo.png)

# State file

```State
# state file
lowerlevel_storage_account_name = "tfstorageaccount"
lowerlevel_container_name       = "tfstate"
lowerlevel_resource_group_name  = "tfstate-rg"
lowerlevel_key                  = "packer/state.tfstate"
subscription_id                 = <Sub ID>
```

# Resource Group Object
```Resource Groups
rg_suffix = "-rg"

resource_groups = {
  region1_spoke_resource_group = {
    name     = "packer"
    location = "australiaeast"
    tags = {
      IsBillable   = "false"
      CreatedBy    = "matt.ashby@theinstillery.com"
      Environment  = "dev"
      Project      = "Internal"
      CustomerName = "Internal"
    }
  },
}
```

# Network Object
```Network
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
    },
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
    },
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
    },
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
    },
  }
  peerings = {
  }
}
```

# IP Object
```IP Object

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
    },
  }
}
```

# Virtual Machine Object
```VM
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
    },
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
        },
      }
      tags = {
        product  = "packer"
        role     = "packer demo"
        location = "Australia East"
      }
    },
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
    },
  }
}
```