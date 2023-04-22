source "azure-arm" "Server2022" {
  azure_tags = {
    product = "packer"
    role    = "packer demo"
  }
  build_resource_group_name         = "packer-rg"
  communicator                      = "winrm"
  image_offer                       = "WindowsServer"
  image_publisher                   = "MicrosoftWindowsServer"
  image_sku                         = "2022-Datacenter"
  managed_image_name                = "myPackerImage"
  managed_image_resource_group_name = "packer-rg"
  os_type                           = "Windows"
  subscription_id                   = "635b2aee-1f07-404d-9851-5b4f8a84cf13"
  tenant_id                         = "a4d44117-bb20-4668-a0dc-16fcb91100b7"
  vm_size                           = "Standard_D2s_v3"
  winrm_insecure                    = true
  winrm_timeout                     = "5m"
  winrm_use_ssl                     = true
  winrm_username                    = "packer"
  use_azure_cli_auth                = true # uses the az login user context to build the VM. User account must have access to build a new VM in the target RG
  # floppy_files                      = ["./scripts/webServer.ps1"]
  # floppy_files                      = ["./scripts/webServer.ps1", "./scripts/sysprep.ps1"]
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

