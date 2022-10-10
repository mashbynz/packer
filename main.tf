terraform {
  required_version = ">= 0.12.20"
  backend "azurerm" {
  }
}

provider "azurerm" {
  version = "= 2.0.0"
  features {}

  # Required if deploying via service principal
  # subscription_id = var.subscription_id
  # client_id       = var.client_id
  # client_secret   = var.client_secret
  # tenant_id       = var.tenant_id
}

data "terraform_remote_state" "landingzone_spoke" {
  backend = "azurerm"
  config = {
    storage_account_name = var.lowerlevel_storage_account_name
    container_name       = var.lowerlevel_container_name
    resource_group_name  = var.lowerlevel_resource_group_name
    key                  = var.lowerlevel_key
  }
}

data "azurerm_client_config" "current" {
}

module "spoke_network" {
  source = "./network/"

  rg_suffix   = var.rg_suffix
  vnet_suffix = var.vnet_suffix
  nsg_suffix  = var.nsg_suffix
  rt_suffix   = var.rt_suffix
  ip_suffix   = var.ip_suffix

  networking_object = var.networking_object
  resource_groups   = var.resource_groups
  IP_address_object = var.IP_address_object
}

module "spoke_vm" {
  source = "./vm/"

  vm_suffix      = var.vm_suffix
  os_disk_suffix = var.os_disk_suffix
  disk_suffix    = var.disk_suffix
  nic_suffix     = var.nic_suffix

  spoke_vnets        = module.spoke_network.virtual_networks
  spoke_subnets      = module.spoke_network.subnets
  spoke_ip_addresses = module.spoke_network.ip_addresses

  vm_object = var.vm_object
}
