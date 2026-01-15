#Requires -Version 5.1
<#
.SYNOPSIS
    Installs DHCP Server role.

.DESCRIPTION
    Installs DHCP Server binaries and management tools. DHCP authorisation
    in Active Directory and scope configuration must be performed post-deployment.

.NOTES
    File Name : Install-DHCP.ps1
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
    Write-Log "Starting DHCP Server installation..."

    # Define features to install
    $features = @(
        'DHCP',                    # DHCP Server
        'RSAT-DHCP'                # DHCP Server management tools
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "DHCP Server role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        # Verify DHCP service
        $dhcpService = Get-Service -Name 'DHCPServer' -ErrorAction SilentlyContinue
        if ($dhcpService) {
            Write-Log "DHCP Server service status: $($dhcpService.Status)"
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "A restart may be required after deployment" -Level Warning
        }

        Write-Log ""
        Write-Log "=== POST-DEPLOYMENT INSTRUCTIONS ==="
        Write-Log "1. Authorise DHCP server in Active Directory:"
        Write-Log "   Add-DhcpServerInDC -DnsName 'dhcp.domain.local' -IPAddress '10.0.0.2'"
        Write-Log ""
        Write-Log "2. Create a DHCP scope:"
        Write-Log "   Add-DhcpServerv4Scope -Name 'LAN' -StartRange 10.0.0.100 -EndRange 10.0.0.200 -SubnetMask 255.255.255.0"
        Write-Log ""
        Write-Log "3. Set scope options (router, DNS):"
        Write-Log "   Set-DhcpServerv4OptionValue -ScopeId 10.0.0.0 -Router 10.0.0.1 -DnsServer 10.0.0.2"
        Write-Log "===================================="
    } else {
        throw "Failed to install DHCP Server role - installation reported unsuccessful"
    }

    Write-Log "DHCP Server installation completed successfully"
    exit 0
}
catch {
    Write-Log "DHCP Server installation failed: $_" -Level Error
    exit 1
}
