source "azure-arm" "Server2022" {
  build_resource_group_name         = var.build_resource_group_name
  communicator                      = var.communicator
  image_offer                       = var.image_offer
  image_publisher                   = var.image_publisher
  image_sku                         = var.image_sku
  managed_image_name                = var.managed_image_name
  managed_image_resource_group_name = var.managed_image_resource_group_name
  os_type                           = var.os_type
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  vm_size                           = var.vm_size
  winrm_insecure                    = var.winrm_insecure
  winrm_timeout                     = var.winrm_timeout
  winrm_use_ssl                     = var.winrm_use_ssl
  winrm_username                    = var.winrm_username
  use_azure_cli_auth                = var.true # uses the az login user context to build the VM. User account must have access to build a new VM in the target RG
  # floppy_files                      = ["./scripts/webServer.ps1"]
  # floppy_files                      = ["./scripts/webServer.ps1", "./scripts/sysprep.ps1"]

  azure_tags = lookup(each.value, "tags", null)
}

build {
  sources = ["source.azure-arm.Server2022"]

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

