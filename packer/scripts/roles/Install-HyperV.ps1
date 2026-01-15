#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Hyper-V role.

.DESCRIPTION
    Installs Hyper-V virtualisation role with management tools. Requires
    Azure VM sizes with nested virtualisation support (Dv3, Ev3, or newer).

.NOTES
    File Name : Install-HyperV.ps1
    Author    : Packer Build Process
    Requires  : PowerShell 5.1+, Windows Server 2022+, Nested Virtualisation support
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        'Warning' { Write-Warning $logMessage }
        'Error'   { Write-Error $logMessage }
        default   { Write-Host $logMessage }
    }
}

try {
    Write-Log "Starting Hyper-V installation..."

    # Check for virtualisation support
    Write-Log "Checking virtualisation capabilities..."

    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    Write-Log "Hypervisor present: $($computerSystem.HypervisorPresent)"

    $processor = Get-WmiObject -Class Win32_Processor
    Write-Log "Processor: $($processor.Name)"
    Write-Log "Virtualisation firmware enabled: $($processor.VirtualizationFirmwareEnabled)"

    # Define features to install
    $features = @(
        'Hyper-V',                 # Hyper-V
        'Hyper-V-Tools',           # Hyper-V management tools
        'Hyper-V-PowerShell',      # Hyper-V PowerShell module
        'RSAT-Hyper-V-Tools'       # Remote Server Administration Tools for Hyper-V
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "Hyper-V role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        # Verify Hyper-V service
        $vmmsService = Get-Service -Name 'vmms' -ErrorAction SilentlyContinue
        if ($vmmsService) {
            Write-Log "Hyper-V Virtual Machine Management service status: $($vmmsService.Status)"
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "IMPORTANT: A restart is required for Hyper-V to be fully functional" -Level Warning
        }

        Write-Log ""
        Write-Log "=== DEPLOYMENT REQUIREMENTS ==="
        Write-Log "This image requires Azure VM sizes with nested virtualisation support:"
        Write-Log "  - Dv3 series (e.g., Standard_D4s_v3)"
        Write-Log "  - Ev3 series (e.g., Standard_E4s_v3)"
        Write-Log "  - Or newer series with nested virtualisation"
        Write-Log "================================"
    } else {
        throw "Failed to install Hyper-V role - installation reported unsuccessful"
    }

    Write-Log "Hyper-V installation completed successfully"
    exit 0
}
catch {
    Write-Log "Hyper-V installation failed: $_" -Level Error
    exit 1
}
