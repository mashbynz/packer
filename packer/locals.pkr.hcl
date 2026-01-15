# =============================================================================
# Shared Local Values - Windows Server Role-Based Images
# =============================================================================
# This file contains shared local values used across all role-specific builds.
# =============================================================================

locals {
  # Timestamp for unique image naming
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())

  # Role-based default image names
  role_image_names = {
    base          = "WindowsServer2022-Core-Base"
    webserver     = "WindowsServer2022-Core-WebServer"
    adds          = "WindowsServer2022-Core-ADDS"
    fileservices  = "WindowsServer2022-Core-FileServices"
    printservices = "WindowsServer2022-Core-PrintServices"
    dns           = "WindowsServer2022-Core-DNS"
    dhcp          = "WindowsServer2022-Core-DHCP"
    hyperv        = "WindowsServer2022-Core-HyperV"
    adcs          = "WindowsServer2022-Core-ADCS"
  }

  # Role-specific VM sizes (some roles need specific capabilities)
  role_vm_sizes = {
    hyperv = "Standard_D4s_v3" # Requires nested virtualization support
  }

  # Computed image name with optional prefix
  computed_image_name = "${var.image_name_prefix}${lookup(local.role_image_names, var.server_role, var.managed_image_name)}"

  # Determine VM size (role-specific override or default)
  effective_vm_size = lookup(local.role_vm_sizes, var.server_role, var.vm_size)

  # Merge default tags with user-provided tags and build metadata
  tags = merge(var.default_tags, var.azure_tags, {
    BuildDate  = local.timestamp
    ImageSKU   = var.image_sku
    ServerRole = var.server_role
  })

  # Script paths for provisioners
  scripts_common = "${path.root}/scripts/common"
  scripts_roles  = "${path.root}/scripts/roles"
}
