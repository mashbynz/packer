output "resource_groups" {
  description = "Returns the full set of Resource Groups created"
  depends_on  = [azurerm_resource_group.rg]

  value = azurerm_resource_group.rg
}

output "resource_group_names" {
  description = "Returns a map of resource_group key -> resource_group name"
  depends_on  = [azurerm_resource_group.rg]

  value = {
    for group in keys(azurerm_resource_group.rg) :
    group => azurerm_resource_group.rg[group].name
  }
}

output "resource_group_ids" {
  description = "Returns a map of resource_group key -> resource_group id"
  depends_on  = [azurerm_resource_group.rg]

  value = {
    for group in keys(azurerm_resource_group.rg) :
    group => azurerm_resource_group.rg[group].id
  }
}

output "virtual_networks" {
  description = "Returns the full set of Virtual Networks created"
  depends_on  = [azurerm_virtual_network.vnet]

  value = azurerm_virtual_network.vnet
}

output "virtual_network_names" {
  description = "Returns a map of virtual_network key -> virtual_network name"
  depends_on  = [azurerm_virtual_network.vnet]

  value = {
    for group in keys(azurerm_virtual_network.vnet) :
    group => azurerm_virtual_network.vnet[group].name
  }
}

output "virtual_network_ids" {
  description = "Returns a map of virtual_network key -> virtual_network id"
  depends_on  = [azurerm_virtual_network.vnet]

  value = {
    for group in keys(azurerm_virtual_network.vnet) :
    group => azurerm_virtual_network.vnet[group].id
  }
}

output "subnets" {
  description = "Returns the full set of subnets created"
  depends_on  = [azurerm_subnet.v_subnet]

  value = azurerm_subnet.v_subnet
}

output "special_subnets" {
  description = "Returns the set of special subnets (GatewaySubnet, AzureFirewallSubnet etc.) created"
  depends_on  = [azurerm_subnet.s_subnet]

  value = azurerm_subnet.s_subnet
}

output "bastion" {
  description = "Returns the details of the bastion host created"
  depends_on  = [azurerm_bastion_host.bastion]

  value = azurerm_bastion_host.bastion
}

output "nsgs" {
  description = "Returns the full set of NSGs created"
  depends_on  = [azurerm_network_security_group.nsg]

  value = azurerm_network_security_group.nsg
}

output "nsg_names" {
  description = "Returns a map of NSG key -> nsg name"
  depends_on  = [azurerm_network_security_group.nsg]

  value = {
    for group in keys(azurerm_network_security_group.nsg) :
    group => azurerm_network_security_group.nsg[group].name
  }
}

output "nsg_ids" {
  description = "Returns a map of NSG key -> nsg id"
  depends_on  = [azurerm_network_security_group.nsg]

  value = {
    for group in keys(azurerm_network_security_group.nsg) :
    group => azurerm_network_security_group.nsg[group].id
  }
}

output "route_tables" {
  description = "Returns the full set of Route Tables created"
  depends_on  = [azurerm_route_table.route_table]

  value = azurerm_route_table.route_table
}

output "route_table_names" {
  description = "Returns a map of route_table key -> route_table name"
  depends_on  = [azurerm_route_table.route_table]

  value = {
    for group in keys(azurerm_route_table.route_table) :
    group => azurerm_route_table.route_table[group].name
  }
}

output "route_table_ids" {
  description = "Returns a map of route_table key -> route_table id"
  depends_on  = [azurerm_route_table.route_table]

  value = {
    for group in keys(azurerm_route_table.route_table) :
    group => azurerm_route_table.route_table[group].id
  }
}

output "ip_addresses" {
  description = "Returns the full set of IP Addresses created"
  depends_on  = [azurerm_public_ip.public_ip]

  value = azurerm_public_ip.public_ip
}

output "ip_address_names" {
  description = "Returns a map of IP_address keys -> IP_address name"
  depends_on  = [azurerm_public_ip.public_ip]

  value = {
    for group in keys(azurerm_public_ip.public_ip) :
    group => azurerm_public_ip.public_ip[group].name
  }
}

output "ip_address_ids" {
  description = "Returns a map of IP_address keys -> IP_address id"
  depends_on  = [azurerm_public_ip.public_ip]

  value = {
    for group in keys(azurerm_public_ip.public_ip) :
    group => azurerm_public_ip.public_ip[group].id
  }
}
