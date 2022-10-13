## Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name     = "${each.value.name}${var.rg_suffix}"
  location = each.value.location
  tags     = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)
}

## Networks
# VNet
resource "azurerm_virtual_network" "vnet" {
  for_each = var.networking_object.vnet

  name                = "${each.value.name}${var.vnet_suffix}"
  location            = each.value.location
  resource_group_name = each.value.virtual_network_rg
  address_space       = each.value.address_space
  tags                = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  dns_servers = lookup(each.value, "dns", null)

  dynamic "ddos_protection_plan" {
    for_each = lookup(each.value, "enable_ddos_std", false) == true ? [1] : []

    content {
      id     = each.value.ddos_id
      enable = each.value.enable_ddos_std
    }
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

# Special Subnets
resource "azurerm_subnet" "s_subnet" {
  for_each = var.networking_object.specialsubnets

  name                                          = each.value.name
  resource_group_name                           = each.value.virtual_network_rg
  virtual_network_name                          = each.value.virtual_network_name
  address_prefixes                              = each.value.cidr
  service_endpoints                             = lookup(each.value, "service_endpoints", [])
  private_endpoint_network_policies_enabled     = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  private_link_service_network_policies_enabled = lookup(each.value, "enforce_private_link_service_network_policies", null)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", {}) != {} ? [1] : []

    content {
      name = lookup(each.value.delegation, "name", null)

      service_delegation {
        name    = lookup(each.value.delegation.service_delegation, "name", null)
        actions = lookup(each.value.delegation.service_delegation, "actions", null)
      }
    }
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  for_each = var.networking_object.bastion

  name                   = each.value.name
  location               = each.value.location
  resource_group_name    = each.value.virtual_network_rg
  copy_paste_enabled     = each.value.copy_paste_enabled
  file_copy_enabled      = each.value.file_copy_enabled
  sku                    = each.value.sku
  ip_connect_enabled     = each.value.ip_connect_enabled
  scale_units            = each.value.scale_units
  shareable_link_enabled = each.value.shareable_link_enabled
  tunneling_enabled      = each.value.tunneling_enabled
  tags                   = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  dynamic "ip_configuration" {
    for_each = lookup(each.value, "ip_configuration", {}) != {} ? [1] : []

    content {
      name                 = lookup(each.value.ip_configuration, "name", null)
      subnet_id            = lookup(each.value.ip_configuration, "subnet_id", null) != null ? azurerm_subnet.s_subnet[lookup(each.value.ip_configuration, "subnet_id", "")].id : null
      public_ip_address_id = lookup(each.value.ip_configuration, "public_ip_address_id", null) != null ? azurerm_public_ip.public_ip[lookup(each.value.ip_configuration, "public_ip_address_id", "")].id : null

    }
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Other Subnets
resource "azurerm_subnet" "v_subnet" {
  for_each = var.networking_object.subnets

  name                                          = each.value.name
  resource_group_name                           = each.value.virtual_network_rg
  virtual_network_name                          = each.value.virtual_network_name
  address_prefixes                              = each.value.cidr
  service_endpoints                             = lookup(each.value, "service_endpoints", [])
  private_endpoint_network_policies_enabled     = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  private_link_service_network_policies_enabled = lookup(each.value, "enforce_private_link_service_network_policies", null)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", {}) != {} ? [1] : []

    content {
      name = lookup(each.value.delegation, "name", null)

      service_delegation {
        name    = lookup(each.value.delegation.service_delegation, "name", null)
        actions = lookup(each.value.delegation.service_delegation, "actions", null)
      }
    }
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# NSGs
resource "azurerm_network_security_group" "nsg" {
  for_each = var.networking_object.subnets

  name                = "${each.value.name}${var.nsg_suffix}"
  resource_group_name = each.value.virtual_network_rg
  location            = each.value.location
  tags                = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  dynamic "security_rule" {
    for_each = concat(lookup(each.value, "nsg_inbound", []), lookup(each.value, "nsg_outbound", []))
    content {
      name                       = security_rule.value[0]
      priority                   = security_rule.value[1]
      direction                  = security_rule.value[2]
      access                     = security_rule.value[3]
      protocol                   = security_rule.value[4]
      source_port_range          = security_rule.value[5]
      destination_port_range     = security_rule.value[6]
      source_address_prefix      = security_rule.value[7]
      destination_address_prefix = security_rule.value[8]
    }
  }

  depends_on = [
    azurerm_subnet.v_subnet, azurerm_resource_group.rg
  ]
}

# Route Table
resource "azurerm_route_table" "route_table" {
  for_each = var.networking_object.subnets

  name                          = "${each.value.name}${var.rt_suffix}"
  location                      = each.value.location
  resource_group_name           = each.value.virtual_network_rg
  tags                          = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", null)

  dynamic "route" {
    for_each = lookup(each.value, "route_entries", [])
    content {
      name                   = route.value[0]
      address_prefix         = route.value[1]
      next_hop_type          = route.value[2]
      next_hop_in_ip_address = route.value[2] == "VirtualAppliance" ? route.value[3] : null
    }
  }

  depends_on = [
    azurerm_subnet.v_subnet, azurerm_resource_group.rg
  ]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  for_each = var.IP_address_object.public

  name                = "${each.value.name}${var.ip_suffix}"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = each.value.allocation_method
  sku                 = each.value.sku
  ip_version          = each.value.ip_version

  tags = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_association" {
  for_each = azurerm_subnet.v_subnet

  subnet_id                 = azurerm_subnet.v_subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# Route Table association
resource "azurerm_subnet_route_table_association" "rt_subnet_association" {
  for_each = azurerm_subnet.v_subnet

  subnet_id      = azurerm_subnet.v_subnet[each.key].id
  route_table_id = azurerm_route_table.route_table[each.key].id
}
