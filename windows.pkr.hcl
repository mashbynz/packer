locals {
  azure_tags = {
    ChargeTo    = "Internal"
    environment = "non prod"
  }
}

source "azure-arm" "Server2022" {
  build_resource_group_name         = var.w22build_resource_group_name
  communicator                      = var.w22communicator
  image_offer                       = var.w22image_offer
  image_publisher                   = var.w22image_publisher
  image_sku                         = var.w22image_sku
  managed_image_name                = var.w22managed_image_name
  managed_image_resource_group_name = var.w22managed_image_resource_group_name
  os_type                           = var.w22os_type
  subscription_id                   = var.w22subscription_id
  tenant_id                         = var.w22tenant_id
  vm_size                           = var.w22vm_size
  winrm_insecure                    = var.w22winrm_insecure
  winrm_timeout                     = var.w22winrm_timeout
  winrm_use_ssl                     = var.w22winrm_use_ssl
  winrm_username                    = var.w22winrm_username
  use_azure_cli_auth                = var.w22use_azure_cli_auth # uses the az login user context to build the VM. User account must have access to build a new VM in the target RG
  # floppy_files                      = ["./scripts/webServer.ps1"]
  # floppy_files                      = ["./scripts/webServer.ps1", "./scripts/sysprep.ps1"]

  azure_tags = var.w22azure_tags == null ? local.azure_tags : merge(local.azure_tags, var.w22azure_tags)
}

build {
  # packer build -only='windows.*' .
  # packer build .
  name = "windows"
  sources = [
    # A different VM name will be used for each line when saving the image
    "source.azure-arm.Server2022",
  ]

  provisioner "powershell" {
    inline = [
      "Add-WindowsFeature Web-Server",
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}

