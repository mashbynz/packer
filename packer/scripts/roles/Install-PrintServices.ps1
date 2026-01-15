#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Print and Document Services role.

.DESCRIPTION
    Installs Print Server role with management tools for centralised
    printer management and print queue administration.

.NOTES
    File Name : Install-PrintServices.ps1
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
    Write-Log "Starting Print and Document Services installation..."

    # Define features to install
    $features = @(
        'Print-Services',          # Print and Document Services
        'Print-Server',            # Print Server
        'RSAT-Print-Services'      # Print Services management tools
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "Print Services role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        # Verify Print Spooler service
        $spoolerService = Get-Service -Name 'Spooler' -ErrorAction SilentlyContinue
        if ($spoolerService) {
            Write-Log "Print Spooler service status: $($spoolerService.Status)"
            if ($spoolerService.Status -ne 'Running') {
                Write-Log "Starting Print Spooler service..."
                Start-Service -Name 'Spooler' -ErrorAction SilentlyContinue
            }
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "A restart may be required after deployment" -Level Warning
        }
    } else {
        throw "Failed to install Print Services role - installation reported unsuccessful"
    }

    Write-Log "Print Services installation completed successfully"
    exit 0
}
catch {
    Write-Log "Print Services installation failed: $_" -Level Error
    exit 1
}
