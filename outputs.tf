##################################################################################################
# Network
##################################################################################################

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "object_id" {
  value = data.azurerm_client_config.current.object_id
}

output "spoke_resource_groups" {
  description = "Returns the full set of resource group objects created"

  value = module.spoke_network.resource_groups
}

output "spoke_resource_group_names" {
  description = "Returns the full set of resource group names"

  value = module.spoke_network.resource_group_names
}

output "spoke_resource_group_ids" {
  description = "Returns the full set of resource group ids"

  value = module.spoke_network.resource_group_ids
}

output "spoke_virtual_networks" {
  description = "Returns the full set of virtual network objects created"

  value = module.spoke_network.virtual_networks
}

output "spoke_virtual_network_names" {
  description = "Returns the full set of virtual network names"

  value = module.spoke_network.virtual_network_names
}

output "spoke_virtual_network_ids" {
  description = "Returns the full set of virtual network ids"

  value = module.spoke_network.virtual_network_ids
}

output "spoke_subnets" {
  description = "Returns the full set of subnets created"

  value = module.spoke_network.subnets
}

output "spoke_special_subnets" {
  description = "Returns the full set of special subnets (GatewaySubnet, AzureFirewallSubnet etc.) created"

  value = module.spoke_network.special_subnets
}

output "spoke_bastion" {
  description = "Returns the details of the bastion host created"

  value = module.spoke_network.bastion
}

output "spoke_NSGs" {
  description = "Returns the full set of NSGs created"

  value = module.spoke_network.nsgs
}

output "spoke_NSG_names" {
  description = "Returns the full set of NSG names"

  value = module.spoke_network.nsg_names
}

output "spoke_NSG_ids" {
  description = "Returns the full set of NSG ids"

  value = module.spoke_network.nsg_ids
}

output "spoke_route_tables" {
  description = "Returns the full set of Route Tables created"

  value = module.spoke_network.route_tables
}

output "spoke_route_table_names" {
  description = "Returns the full set of Route Table names"

  value = module.spoke_network.route_table_names
}

output "spoke_route_table_ids" {
  description = "Returns the full set of Route Table ids"

  value = module.spoke_network.route_table_ids
}

output "spoke_ip_addresses" {
  description = "Returns the full set of IP Addresses created"

  value = module.spoke_network.ip_addresses
}

output "spoke_ip_address_names" {
  description = "Returns the full set of IP Address names"

  value = module.spoke_network.ip_address_names
}

output "spoke_ip_address_ids" {
  description = "Returns the full set of IP Address ids"

  value = module.spoke_network.ip_address_ids
}

##################################################################################################
# VM
##################################################################################################
output "spoke_virtual_machines" {
  description = "Returns the full set of Virtual Machines created"
  sensitive   = true

  value = module.spoke_vm.virtual_machines
}

output "spoke_virtual_machine_names" {
  description = "Returns the full set of Virtual Machine names"

  value = module.spoke_vm.virtual_machine_names
}

output "spoke_virtual_machine_ids" {
  description = "Returns the full set of Virtual Machine ids"

  value = module.spoke_vm.virtual_machine_ids
}

output "spoke_network_interface_cards" {
  description = "Returns the full set of NICs created"

  value = module.spoke_vm.network_interface_cards
}

output "spoke_network_interface_card_names" {
  description = "Returns the full set of NIC names"

  value = module.spoke_vm.network_interface_card_names
}

output "spoke_network_interface_card_ids" {
  description = "Returns the full set of NIC ids"

  value = module.spoke_vm.network_interface_card_ids
}
