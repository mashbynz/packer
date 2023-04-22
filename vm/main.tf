resource "azurerm_network_interface" "nic" {
  for_each = var.vm_object.nics

  name                = "${each.value.name}${var.nic_suffix}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  tags = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  dynamic "ip_configuration" {
    for_each = lookup(each.value, "ip_configuration", {}) #!= {} ? [1] : []

    content {
      name                          = lookup(ip_configuration.value, "name", null)
      subnet_id                     = var.spoke_subnets[lookup(ip_configuration.value, "subnet_id", null)].id
      private_ip_address_allocation = lookup(ip_configuration.value, "private_ip_address_allocation", null)
      private_ip_address            = lookup(ip_configuration.value, "private_ip_address_allocation", null) == "Static" ? lookup(ip_configuration.value, "private_ip_address", "") : null
      public_ip_address_id          = lookup(ip_configuration.value, "public_ip_address_id", null) != null ? var.spoke_ip_addresses[lookup(ip_configuration.value, "public_ip_address_id", "")].id : null
      primary                       = lookup(ip_configuration.value, "primary", null)
    }
  }

  depends_on = [
    var.spoke_vnets
  ]
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = var.vm_object.vms

  name                  = "${each.value.name}${var.vm_suffix}"
  resource_group_name   = each.value.resource_group_name
  location              = each.value.location
  size                  = each.value.size
  admin_username        = each.value.admin_username
  admin_password        = each.value.admin_password
  network_interface_ids = [azurerm_network_interface.nic[each.value.network_interface_ids].id]
  license_type          = each.value.os_profile.license_type
  provision_vm_agent    = each.value.os_profile.provision_vm_agent

  tags = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  os_disk {
    name                 = "${each.value.name}${var.os_disk_suffix}"
    caching              = each.value.storage_os_disk.caching
    storage_account_type = each.value.storage_os_disk.storage_account_type
    disk_size_gb         = each.value.storage_os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.storage_image_reference.publisher
    offer     = each.value.storage_image_reference.offer
    sku       = each.value.storage_image_reference.sku
    version   = each.value.storage_image_reference.version
  }

  # source_image_id = each.value.source_image_id

  # boot_diagnostics {
  #   storage_account_uri = var.governance_storage_accounts[each.value.boot_diagnostics.storage_account_uri].primary_blob_endpoint
  # }

  depends_on = [
    azurerm_network_interface.nic
  ]
}

resource "azurerm_managed_disk" "disk" {
  for_each = var.vm_object.data_disks

  name                 = "${each.value.name}${var.disk_suffix}${each.value.disk_count}${each.value.disk_letter}"
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb

  tags = lookup(each.value, "tags", null) == null ? local.tags : merge(local.tags, each.value.tags)

  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  for_each = var.vm_object.data_disks

  managed_disk_id    = azurerm_managed_disk.disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.value.virtual_machine].id
  lun                = each.value.lun
  caching            = each.value.caching

  depends_on = [
    azurerm_windows_virtual_machine.vm, azurerm_managed_disk.disk
  ]
}
