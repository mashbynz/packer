#Requires -Version 5.1
<#
.SYNOPSIS
    Installs IIS Web Server role.

.DESCRIPTION
    Installs the IIS Web Server feature with management tools. This script
    is designed to be run by Packer during image creation.

.NOTES
    File Name : Install-WebServer.ps1
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
    Write-Log "Starting IIS Web Server installation..."

    # Define features to install
    $features = @(
        'Web-Server',              # IIS Web Server
        'Web-WebServer',           # Web Server role service
        'Web-Common-Http',         # Common HTTP features
        'Web-Default-Doc',         # Default document
        'Web-Dir-Browsing',        # Directory browsing
        'Web-Http-Errors',         # HTTP errors
        'Web-Static-Content',      # Static content
        'Web-Health',              # Health and diagnostics
        'Web-Http-Logging',        # HTTP logging
        'Web-Performance',         # Performance features
        'Web-Stat-Compression',    # Static content compression
        'Web-Security',            # Security features
        'Web-Filtering',           # Request filtering
        'Web-Mgmt-Tools',          # Management tools
        'Web-Mgmt-Console'         # IIS Management Console
    )

    Write-Log "Installing features: Web-Server with management tools"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "IIS Web Server role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        # Verify IIS service is running
        Write-Log "Verifying IIS service status..."
        $iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
        if ($iisService) {
            Write-Log "IIS service (W3SVC) status: $($iisService.Status)"
            if ($iisService.Status -ne 'Running') {
                Write-Log "Starting IIS service..."
                Start-Service -Name W3SVC -ErrorAction SilentlyContinue
            }
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "A restart may be required after deployment" -Level Warning
        }
    } else {
        throw "Failed to install IIS Web Server role - installation reported unsuccessful"
    }

    Write-Log "IIS Web Server installation completed successfully"
    exit 0
}
catch {
    Write-Log "IIS Web Server installation failed: $_" -Level Error
    exit 1
}
