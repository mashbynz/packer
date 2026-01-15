#Requires -Version 5.1
<#
.SYNOPSIS
    Applies common Windows Server configuration settings.

.DESCRIPTION
    This script configures common settings for all Windows Server Core images:
    - Remote Desktop configuration
    - Windows Remote Management (WinRM)
    - Timezone settings
    - Windows Update policy
    - Server Core optimisations

.NOTES
    File Name : Set-CommonConfiguration.ps1
    Author    : Packer Build Process
    Requires  : PowerShell 5.1+, Windows Server 2022+
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
    Write-Log "Starting common Windows Server configuration..."

    # -------------------------------------------------------------------------
    # Remote Desktop Configuration
    # -------------------------------------------------------------------------
    Write-Log "Configuring Remote Desktop..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0 -ErrorAction SilentlyContinue

    # Enable Remote Desktop firewall rules
    $rdpRules = Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
    if ($rdpRules) {
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
        Write-Log "Remote Desktop firewall rules enabled"
    }

    # -------------------------------------------------------------------------
    # Windows Remote Management (WinRM)
    # -------------------------------------------------------------------------
    Write-Log "Configuring Windows Remote Management..."
    Enable-PSRemoting -Force -SkipNetworkProfileCheck -ErrorAction SilentlyContinue
    Write-Log "PowerShell Remoting enabled"

    # -------------------------------------------------------------------------
    # Timezone Configuration
    # -------------------------------------------------------------------------
    Write-Log "Setting timezone to UTC (Azure best practice)..."
    Set-TimeZone -Id 'UTC' -ErrorAction SilentlyContinue
    Write-Log "Timezone set to UTC"

    # -------------------------------------------------------------------------
    # Windows Update Policy
    # -------------------------------------------------------------------------
    Write-Log "Configuring Windows Update policy..."
    $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

    if (-not (Test-Path $auPath)) {
        New-Item -Path $auPath -Force | Out-Null
    }

    # Configure to download updates but not auto-install (AUOptions = 3)
    Set-ItemProperty -Path $auPath -Name 'AUOptions' -Value 3
    Set-ItemProperty -Path $auPath -Name 'NoAutoUpdate' -Value 0

    Write-Log "Windows Update configured for download-only mode"

    # -------------------------------------------------------------------------
    # Server Core Optimisations
    # -------------------------------------------------------------------------
    Write-Log "Applying Server Core optimisations..."

    # Disable unnecessary services for Server Core
    $servicesToDisable = @(
        'DiagTrack',           # Connected User Experiences and Telemetry
        'dmwappushservice'     # Device Management WAP Push message Routing Service
    )

    foreach ($serviceName in $servicesToDisable) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log "Disabled service: $serviceName"
        }
    }

    # -------------------------------------------------------------------------
    # PowerShell Configuration
    # -------------------------------------------------------------------------
    Write-Log "Configuring PowerShell defaults..."

    # Set execution policy for scripts
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction SilentlyContinue
    Write-Log "PowerShell execution policy set to RemoteSigned"

    # -------------------------------------------------------------------------
    # Windows Defender Configuration
    # -------------------------------------------------------------------------
    Write-Log "Configuring Windows Defender..."

    # Ensure Windows Defender is enabled
    $defenderService = Get-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
    if ($defenderService -and $defenderService.Status -ne 'Running') {
        Start-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
        Write-Log "Windows Defender service started"
    }

    # Update Windows Defender signatures
    Write-Log "Updating Windows Defender signatures..."
    Update-MpSignature -ErrorAction SilentlyContinue
    Write-Log "Windows Defender signatures updated"

    Write-Log "Common configuration completed successfully"
    exit 0
}
catch {
    Write-Log "Common configuration failed: $_" -Level Error
    exit 1
}
