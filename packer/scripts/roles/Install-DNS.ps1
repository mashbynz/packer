#Requires -Version 5.1
<#
.SYNOPSIS
    Installs DNS Server role.

.DESCRIPTION
    Installs the DNS Server role with management tools. DNS zones and
    records must be configured post-deployment.

.NOTES
    File Name : Install-DNS.ps1
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
    Write-Log "Starting DNS Server installation..."

    # Define features to install
    $features = @(
        'DNS',                     # DNS Server
        'RSAT-DNS-Server'          # DNS Server management tools
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "DNS Server role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        # Verify DNS service
        $dnsService = Get-Service -Name 'DNS' -ErrorAction SilentlyContinue
        if ($dnsService) {
            Write-Log "DNS Server service status: $($dnsService.Status)"
            if ($dnsService.Status -ne 'Running') {
                Write-Log "Starting DNS Server service..."
                Start-Service -Name 'DNS' -ErrorAction SilentlyContinue
            }
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "A restart may be required after deployment" -Level Warning
        }

        Write-Log ""
        Write-Log "=== POST-DEPLOYMENT INSTRUCTIONS ==="
        Write-Log "Configure DNS zones using:"
        Write-Log "  Add-DnsServerPrimaryZone -Name 'domain.local' -ZoneFile 'domain.local.dns'"
        Write-Log "  Add-DnsServerResourceRecordA -Name 'server' -ZoneName 'domain.local' -IPv4Address '10.0.0.1'"
        Write-Log "===================================="
    } else {
        throw "Failed to install DNS Server role - installation reported unsuccessful"
    }

    Write-Log "DNS Server installation completed successfully"
    exit 0
}
catch {
    Write-Log "DNS Server installation failed: $_" -Level Error
    exit 1
}
