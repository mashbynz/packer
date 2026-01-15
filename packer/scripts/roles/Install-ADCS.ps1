#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Active Directory Certificate Services role.

.DESCRIPTION
    Installs ADCS binaries including Certificate Authority and Web Enrollment.
    CA configuration must be performed post-deployment using
    Install-AdcsCertificationAuthority.

.NOTES
    File Name : Install-ADCS.ps1
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
    Write-Log "Starting Active Directory Certificate Services installation..."

    # Define features to install
    $features = @(
        'ADCS-Cert-Authority',     # Certification Authority
        'ADCS-Web-Enrollment',     # Certificate Authority Web Enrollment
        'ADCS-Online-Cert',        # Online Responder
        'RSAT-ADCS',               # AD CS management tools
        'RSAT-ADCS-Mgmt'           # Certification Authority management tools
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "ADCS role installed successfully"

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
        Write-Log "Configure as Enterprise Root CA:"
        Write-Log "  Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -CACommonName 'Corp-Root-CA' -KeyLength 4096 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 10"
        Write-Log ""
        Write-Log "Configure as Enterprise Subordinate CA:"
        Write-Log "  Install-AdcsCertificationAuthority -CAType EnterpriseSubordinateCa -CACommonName 'Corp-Issuing-CA' -KeyLength 4096 -HashAlgorithmName SHA256"
        Write-Log ""
        Write-Log "Configure Web Enrollment (after CA is configured):"
        Write-Log "  Install-AdcsWebEnrollment"
        Write-Log "===================================="
    } else {
        throw "Failed to install ADCS role - installation reported unsuccessful"
    }

    Write-Log "ADCS installation completed successfully"
    exit 0
}
catch {
    Write-Log "ADCS installation failed: $_" -Level Error
    exit 1
}
