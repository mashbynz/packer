#Requires -Version 5.1
<#
.SYNOPSIS
    Configures a Windows Server with IIS Web Server role.

.DESCRIPTION
    This script installs and configures the IIS Web Server feature on Windows Server.
    It is designed to be run by Packer during image creation.

.NOTES
    File Name : webServer.ps1
    Author    : Packer Build Process
    Requires  : PowerShell 5.1+, Windows Server 2016+
#>

[CmdletBinding()]
param()

# Set strict error handling
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
    Write-Log "Starting Windows Server configuration..."

    # Install IIS Web Server feature with management tools
    Write-Log "Installing Web-Server feature..."
    $result = Install-WindowsFeature -Name Web-Server -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "Web-Server feature installed successfully"
        Write-Log "Features installed: $($result.FeatureResult.Name -join ', ')"
    } else {
        throw "Failed to install Web-Server feature"
    }

    # Verify IIS is running
    Write-Log "Verifying IIS service status..."
    $iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
    if ($iisService -and $iisService.Status -eq 'Running') {
        Write-Log "IIS service (W3SVC) is running"
    } else {
        Write-Log "Starting IIS service..." -Level Warning
        Start-Service -Name W3SVC -ErrorAction Stop
    }

    Write-Log "Windows Server configuration completed successfully"
    exit 0
}
catch {
    Write-Log "Configuration failed: $_" -Level Error
    exit 1
}
