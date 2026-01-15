# =============================================================================
# Packer Configuration - Windows Server Image Build for Azure
# =============================================================================
# This configuration builds Windows Server images using the Azure ARM builder.
# Run `packer init .` to download required plugins before building.
# =============================================================================

packer {
  required_version = ">= 1.9.0"

  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 2.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

locals {
  # Timestamp for unique image naming
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())

  # Computed image name with optional prefix
  image_name = "${var.image_name_prefix}${var.managed_image_name}"

  # Merge default tags with user-provided tags
  tags = merge(var.default_tags, var.azure_tags, {
    BuildDate = local.timestamp
    ImageSKU  = var.image_sku
  })
}

# -----------------------------------------------------------------------------
# Azure ARM Source - Windows Server 2022
# -----------------------------------------------------------------------------

source "azure-arm" "windows_server" {
  # Azure Authentication
  subscription_id    = var.subscription_id
  tenant_id          = var.tenant_id
  use_azure_cli_auth = var.use_azure_cli_auth

  # Build Infrastructure
  build_resource_group_name = var.build_resource_group_name
  vm_size                   = var.vm_size

  # Source Image Configuration
  os_type         = var.os_type
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku

  # Output Image Configuration
  managed_image_name                = local.image_name
  managed_image_resource_group_name = var.managed_image_resource_group_name

  # WinRM Communication Settings
  communicator   = var.communicator
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = var.winrm_timeout
  winrm_use_ssl  = var.winrm_use_ssl
  winrm_insecure = var.winrm_insecure

  # Resource Tags
  azure_tags = local.tags
}

# -----------------------------------------------------------------------------
# Build Definition
# -----------------------------------------------------------------------------

build {
  name = "windows-server"

  sources = [
    "source.azure-arm.windows_server"
  ]

  # Provisioner: Configure the Windows Server
  provisioner "powershell" {
    script = "${path.root}/scripts/webServer.ps1"
  }

  # Provisioner: Sysprep and generalize the image
  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for Azure agents to start...'",
      "",
      "# Wait for RdAgent service",
      "$timeout = 300",
      "$timer = [Diagnostics.Stopwatch]::StartNew()",
      "while ((Get-Service RdAgent -ErrorAction SilentlyContinue).Status -ne 'Running') {",
      "  if ($timer.Elapsed.TotalSeconds -gt $timeout) {",
      "    throw 'Timeout waiting for RdAgent service'",
      "  }",
      "  Write-Host 'Waiting for RdAgent service...'",
      "  Start-Sleep -Seconds 5",
      "}",
      "Write-Host 'RdAgent service is running'",
      "",
      "# Wait for Windows Azure Guest Agent",
      "$timer.Restart()",
      "while ((Get-Service WindowsAzureGuestAgent -ErrorAction SilentlyContinue).Status -ne 'Running') {",
      "  if ($timer.Elapsed.TotalSeconds -gt $timeout) {",
      "    throw 'Timeout waiting for WindowsAzureGuestAgent service'",
      "  }",
      "  Write-Host 'Waiting for WindowsAzureGuestAgent service...'",
      "  Start-Sleep -Seconds 5",
      "}",
      "Write-Host 'WindowsAzureGuestAgent service is running'",
      "",
      "# Execute Sysprep",
      "Write-Host 'Starting Sysprep generalization...'",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "",
      "# Wait for Sysprep to complete",
      "$timer.Restart()",
      "while ($true) {",
      "  $imageState = (Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State' -ErrorAction SilentlyContinue).ImageState",
      "  if ($imageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') {",
      "    Write-Host 'Sysprep completed successfully'",
      "    break",
      "  }",
      "  if ($timer.Elapsed.TotalSeconds -gt $timeout) {",
      "    throw 'Timeout waiting for Sysprep to complete'",
      "  }",
      "  Write-Host \"Current image state: $imageState\"",
      "  Start-Sleep -Seconds 10",
      "}"
    ]
  }

  # Post-processor: Display build information
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
