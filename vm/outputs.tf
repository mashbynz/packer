output "virtual_machines" {
  description = "Returns the full set of virtual machines created"
  depends_on  = [azurerm_windows_virtual_machine.vm]

  value = azurerm_windows_virtual_machine.vm
}

output "virtual_machine_names" {
  description = "Returns a map of virtual_machine key -> virtual_machine name"
  depends_on  = [azurerm_windows_virtual_machine.vm]

  value = {
    for group in keys(azurerm_windows_virtual_machine.vm) :
    group => azurerm_windows_virtual_machine.vm[group].name
  }
}

output "virtual_machine_ids" {
  description = "Returns a map of virtual_machine key -> virtual_machine id"
  depends_on  = [azurerm_windows_virtual_machine.vm]

  value = {
    for group in keys(azurerm_windows_virtual_machine.vm) :
    group => azurerm_windows_virtual_machine.vm[group].id
  }
}

output "network_interface_cards" {
  description = "Returns the full set of NICs created"
  depends_on  = [azurerm_network_interface.nic]

  value = azurerm_network_interface.nic
}

output "network_interface_card_names" {
  description = "Returns a map of network_interface_cards key -> network_interface_cards name"
  depends_on  = [azurerm_network_interface.nic]

  value = {
    for group in keys(azurerm_network_interface.nic) :
    group => azurerm_network_interface.nic[group].name
  }
}

output "network_interface_card_ids" {
  description = "Returns a map of network_interface_cards key -> network_interface_cards id"
  depends_on  = [azurerm_network_interface.nic]

  value = {
    for group in keys(azurerm_network_interface.nic) :
    group => azurerm_network_interface.nic[group].id
  }
}

# -----------------------------------------------------------------------------
# Packer Image Outputs
# -----------------------------------------------------------------------------

output "packer_images" {
  description = "Returns the Packer images data source results"
  value       = data.azurerm_image.packer
}

output "packer_image_ids" {
  description = "Returns a map of packer image role -> image id"
  value = {
    for role, image in data.azurerm_image.packer :
    role => image.id
  }
}
