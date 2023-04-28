locals {
  azure_tags = {
    ChargeTo    = "Internal"
    environment = "non prod"
  }
  vmprefix = "VM"
}

# Separate definition for this variable so it can be treated as sensitive
local "winrm_password" {
  expression = var.winrm_password
  sensitive  = true
}

source "azure-arm" "Server2022" {
  build_resource_group_name         = var.w22build_resource_group_name
  communicator                      = var.communicator
  image_offer                       = var.w22image_offer
  image_publisher                   = var.w22image_publisher
  image_sku                         = var.w22image_sku
  managed_image_name                = join("", [local.vmprefix, var.w22managed_image_name])
  managed_image_resource_group_name = var.w22managed_image_resource_group_name
  os_type                           = var.w22os_type
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  vm_size                           = var.vm_size
  winrm_insecure                    = var.winrm_insecure
  winrm_timeout                     = var.winrm_timeout
  winrm_use_ssl                     = var.winrm_use_ssl
  winrm_username                    = var.winrm_username
  winrm_password                    = local.winrm_password
  use_azure_cli_auth                = var.use_azure_cli_auth # uses the az login user context to build the VM. User account must have access to build a new VM in the target RG
  # floppy_files                      = ["./scripts/webServer.ps1", "./scripts/sysprep.ps1"] # VMWare source only

  azure_tags = var.w22azure_tags == null ? local.azure_tags : merge(local.azure_tags, var.w22azure_tags)
}

build {
  name = "windows"
  sources = [
    # A different VM name will be used for each line when saving the image
    "source.azure-arm.Server2022",
  ]

  provisioner "powershell" {
    # Apply config
    script = "./scripts/webServer.ps1"
  }

  provisioner "powershell" {
    # post-processor "powershell" {} Option if using a different provisioner
    # Generalise and sysprep
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}

