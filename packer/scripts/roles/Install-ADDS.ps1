#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Active Directory Domain Services role.

.DESCRIPTION
    Installs AD DS binaries and management tools. Domain configuration
    (promotion to DC) is NOT performed - this creates a "promotion-ready" image.

    Post-deployment, use Install-ADDSForest or Install-ADDSDomainController
    to configure the domain controller.

.NOTES
    File Name : Install-ADDS.ps1
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
    Write-Log "Starting Active Directory Domain Services installation..."

    # Define features to install
    $features = @(
        'AD-Domain-Services',      # Core AD DS
        'RSAT-AD-Tools',           # AD management tools
        'RSAT-ADDS',               # AD DS tools
        'RSAT-AD-PowerShell',      # AD PowerShell module
        'RSAT-ADDS-Tools'          # Additional AD DS tools
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeAllSubFeature -ErrorAction Stop

    if ($result.Success) {
        Write-Log "AD DS role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "A restart may be required after deployment" -Level Warning
        }

        Write-Log ""
        Write-Log "=== POST-DEPLOYMENT INSTRUCTIONS ==="
        Write-Log "To promote to a new forest:"
        Write-Log "  Install-ADDSForest -DomainName 'domain.local' -InstallDns"
        Write-Log ""
        Write-Log "To add as a domain controller to existing domain:"
        Write-Log "  Install-ADDSDomainController -DomainName 'domain.local' -InstallDns -Credential (Get-Credential)"
        Write-Log "===================================="
    } else {
        throw "Failed to install AD DS role - installation reported unsuccessful"
    }

    Write-Log "AD DS installation completed successfully"
    exit 0
}
catch {
    Write-Log "AD DS installation failed: $_" -Level Error
    exit 1
}
