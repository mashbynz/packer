# Isolated spoke

The example data structure for the .auto.tfvars file(s) is below.

## State file

```State
# state file
lowerlevel_storage_account_name = "tfstorageaccount"
lowerlevel_container_name       = "tfstate"
lowerlevel_resource_group_name  = "tfstate-rg"
lowerlevel_key                  = "spoke/isolated.tfstate"
subscription_id                 = <Sub ID>
```

## Resource Groups, Networks, Public IP Addresses

```Network
rg_suffix = "-rg"

# Resource Groups
resource_groups = {
  region1_spoke_resource_group = {
    name     = "spoke"
    location = "australiaeast"
    tags = {
      application = "appName"
      role        = "App Function"
      location    = "Australia East"
    }
  },
}

vnet_suffix = "-vnet"
nsg_suffix  = "-nsg"
rt_suffix   = "-rt"

# Networks
networking_object = {
  vnet = {
    region1_spoke_vnet = {
      name               = "spoke"
      location           = "australiaeast"
      virtual_network_rg = "spoke-rg"
      address_space      = ["10.48.16.128/26"]
      dns                = ["10.48.131.69"]
      enable_ddos_std    = false
      ddos_id            = "<to be added later>"
      tags = {
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
  }
  specialsubnets = {
    # region1_GatewaySubnet = {
    #   name                 = "GatewaySubnet"
    #   cidr                 = "10.48.0.0/26"
    #   location             = "australiacentral"
    #   virtual_network_rg   = "spoke-rg"
    #   virtual_network_name = "spoke-vnet"
    #   service_endpoints    = []
    #   nsg_inbound = []
    #   nsg_outbound = []
    # }
  }
  subnets = {
    region1_spoke_subnet = {
      name                 = "subnet"
      cidr                 = "10.48.16.128/26"
      location             = "australiaeast"
      virtual_network_rg   = "spoke-rg"
      virtual_network_name = "spoke-vnet"
      service_endpoints = []
      nsg_inbound = [
        # [name, priority, direction, action, protocol, source_port_range, destination_port_range, source_address_prefix, destination_address_prefix],
        ["ICMP", "100", "Inbound", "Allow", "Icmp", "*", "*", "*", "*"],
      ]
      nsg_outbound = []
      # delegation = {
      #   name = "acctestdelegation1"
      #   service_delegation = {
      #     name    = "Microsoft.ContainerInstance/containerGroups"
      #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
      #   }
      # }
      disable_bgp_route_propagation = true #optional
      route_entries = [
        #[name, prefix, next_hop_type, next_hop_in_ip_address]
        ["Default", "0.0.0.0/0", "VirtualAppliance", "10.48.253.6"],
      ]
      tags = {
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
  }
  peerings = {
    # hubToSpoke = {
    #   name                      = "toSpoke"
    #   resource_group_name       = "hub-rg"
    #   virtual_network_name      = "hub-vnet"
    #   remote_virtual_network_id = "spoke"
    #   allow_forwarded_traffic   = true
    # },
    # spokeToHub = {
    #   name                      = "toHub"
    #   resource_group_name       = "spoke-rg"
    #   virtual_network_name      = "spoke-vnet"
    #   remote_virtual_network_id = "hub"
    #   allow_forwarded_traffic   = false
    # },
  }
}

ip_suffix = "-pip"

IP_address_object = {
  public = {
    # region1_application_ip = {
    #   name                = "appName"
    #   resource_group_name = "appName-rg"
    #   location            = "australiaeast"
    #   allocation_method   = "Static"
    #   sku                 = "Standard"
    #   ip_version          = "IPv4"

    #   tags = {
    #     application = "appName"
    #     role        = "application server"
    #     location    = "Australia East"
    #   }
    # },
  }
}
```

## VMs, Data disks

```VM
vm_suffix      = "-vm"
os_disk_suffix = "-osdisk"
disk_suffix    = "-disk"
nic_suffix     = "-nic"

# Virtual Machines
vm_object = {
  vms = {
    region1_vm1 = {
      name                          = "VMNAME"
      resource_group_name           = "spoke-rg"
      location                      = "australiaeast"
      size                          = "Standard_DS3_v2"
      os                            = "Windows"
      delete_os_disk_on_termination = true
      network_interface_ids         = "region1_vm1_nic"
      admin_username                = "admin"
      admin_password                = "P@ssw0rd1!"
      os_profile = {
        provision_vm_agent = true
        license_type       = "Windows_Server"
        #Support for BYOL (HUB) - values can be "Windows_Server" or "Windows_Client"
      }
      storage_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
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
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
  }
  nics = {
    region1_vm1_nic = {
      name                = "VMNAME"
      resource_group_name = "spoke-rg"
      location            = "australiaeast"
      ip_configuration = {
        config_1 = {
          name                          = "ip_config_1"
          subnet_id                     = "region1_spoke_subnet"
          private_ip_address_allocation = "Static"
          private_ip_address            = "10.48.16.133"
          public_ip_address_id          = null
          primary                       = true
        },
        config_2 = {
          name                          = "ip_config_2"
          subnet_id                     = "region1_spoke_subnet"
          private_ip_address_allocation = "Static"
          private_ip_address            = "10.48.16.134"
          public_ip_address_id          = null
          primary                       = false
        },
        config_3 = {
          name                          = "ip_config_3"
          subnet_id                     = "region1_spoke_subnet"
          private_ip_address_allocation = "Static"
          private_ip_address            = "10.48.16.135"
          public_ip_address_id          = null
          primary                       = false
        },
        config_4 = {
          name                          = "ip_config_4"
          subnet_id                     = "region1_spoke_subnet"
          private_ip_address_allocation = "Static"
          private_ip_address            = "10.48.16.136"
          public_ip_address_id          = null
          primary                       = false
        },
        config_5 = {
          name                          = "ip_config_5"
          subnet_id                     = "region1_spoke_subnet"
          private_ip_address_allocation = "Static"
          private_ip_address            = "10.48.16.137"
          public_ip_address_id          = null
          primary                       = false
        },
      }
      tags = {
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
  }
  data_disks = {
    region1_vm1_disk1 = {
      name                 = "VMNAME"
      virtual_machine      = "region1_vm1"
      resource_group_name  = "spoke-rg"
      location             = "australiaeast"
      storage_account_type = "Premium_LRS"
      create_option        = "Empty"
      disk_size_gb         = 128
      disk_letter          = "-F"
      disk_count           = "01"
      lun                  = "10"
      caching              = "ReadWrite"
      tags = {
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
    region1_vm1_disk2 = {
      name                 = "VMNAME"
      virtual_machine      = "region1_vm1"
      resource_group_name  = "spoke-rg"
      location             = "australiaeast"
      storage_account_type = "Premium_LRS"
      create_option        = "Empty"
      disk_size_gb         = 128
      disk_letter          = "-F"
      disk_count           = "02"
      lun                  = "20"
      caching              = "ReadWrite"
      tags = {
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
    region1_vm1_disk3 = {
      name                 = "VMNAME"
      virtual_machine      = "region1_vm1"
      resource_group_name  = "spoke-rg"
      location             = "australiaeast"
      storage_account_type = "Premium_LRS"
      create_option        = "Empty"
      disk_size_gb         = 128
      disk_letter          = "-F"
      disk_count           = "03"
      lun                  = "30"
      caching              = "ReadWrite"
      tags = {
        application = "appName"
        role        = "App Function"
        location    = "Australia East"
      }
    },
  }
}
```