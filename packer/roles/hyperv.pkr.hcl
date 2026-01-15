# =============================================================================
# Packer Configuration - Windows Server 2022 Core - Hyper-V Role
# =============================================================================
# Hyper-V Virtualisation
# IMPORTANT: Requires Azure VM size with nested virtualisation support (Dv3, Ev3+)
# Build: packer build -only="*.hyperv" -var-file=examples/hyperv.pkrvars.hcl .
# =============================================================================

source "azure-arm" "hyperv" {
  # Azure Authentication
  subscription_id    = var.subscription_id
  tenant_id          = var.tenant_id
  use_azure_cli_auth = var.use_azure_cli_auth

  # Build Infrastructure - Use larger VM for nested virtualisation
  build_resource_group_name = var.build_resource_group_name
  vm_size                   = local.effective_vm_size

  # Source Image - Windows Server 2022 Core
  os_type         = var.os_type
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku

  # Output Image
  managed_image_name                = "${var.image_name_prefix}WindowsServer2022-Core-HyperV"
  managed_image_resource_group_name = var.managed_image_resource_group_name

  # WinRM Communication - Longer timeout for Hyper-V installation
  communicator   = var.communicator
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "20m"
  winrm_use_ssl  = var.winrm_use_ssl
  winrm_insecure = var.winrm_insecure

  # Tags
  azure_tags = merge(local.tags, {
    ServerRole              = "HyperV"
    NestedVirtualisation    = "Required"
  })
}

build {
  name = "hyperv"

  sources = ["source.azure-arm.hyperv"]

  # Step 1: Common Windows configuration
  provisioner "powershell" {
    script = "${path.root}/scripts/common/Set-CommonConfiguration.ps1"
  }

  # Step 2: Install ConnectWise Manage Agent
  provisioner "powershell" {
    script = "${path.root}/scripts/common/Install-ConnectWiseAgent.ps1"
    environment_vars = [
      "CONNECTWISE_TOKEN=${var.connectwise_token}",
      "CONNECTWISE_REPO_URL=${var.connectwise_repo_url}",
      "INSTALL_AGENT=${var.install_connectwise_agent}"
    ]
  }

  # Step 3: Install Hyper-V Role
  provisioner "powershell" {
    script = "${path.root}/scripts/roles/Install-HyperV.ps1"
  }

  # Step 4: Sysprep and generalise
  provisioner "powershell" {
    script = "${path.root}/scripts/common/Invoke-Sysprep.ps1"
  }

  post-processor "manifest" {
    output     = "packer-manifest-hyperv.json"
    strip_path = true
  }
}
