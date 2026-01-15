#Requires -Version 5.1
<#
.SYNOPSIS
    Installs File and Storage Services role.

.DESCRIPTION
    Installs File Server role with commonly used sub-features including:
    - File Server
    - Data Deduplication
    - BranchCache
    - DFS Namespace and Replication
    - File Server Resource Manager

.NOTES
    File Name : Install-FileServices.ps1
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
    Write-Log "Starting File and Storage Services installation..."

    # Define features to install
    $features = @(
        'File-Services',           # File and Storage Services
        'FS-FileServer',           # File Server
        'FS-Data-Deduplication',   # Data Deduplication
        'FS-BranchCache',          # BranchCache for Network Files
        'FS-DFS-Namespace',        # DFS Namespace
        'FS-DFS-Replication',      # DFS Replication
        'FS-Resource-Manager',     # File Server Resource Manager
        'RSAT-File-Services'       # File Services management tools
    )

    Write-Log "Installing features: $($features -join ', ')"

    $result = Install-WindowsFeature -Name $features -IncludeManagementTools -ErrorAction Stop

    if ($result.Success) {
        Write-Log "File Services role installed successfully"

        if ($result.FeatureResult) {
            Write-Log "Features installed:"
            foreach ($feature in $result.FeatureResult) {
                Write-Log "  - $($feature.Name): $($feature.InstallState)"
            }
        }

        # Verify key services
        $lanmanService = Get-Service -Name 'LanmanServer' -ErrorAction SilentlyContinue
        if ($lanmanService) {
            Write-Log "Server service (LanmanServer) status: $($lanmanService.Status)"
        }

        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "A restart may be required after deployment" -Level Warning
        }
    } else {
        throw "Failed to install File Services role - installation reported unsuccessful"
    }

    Write-Log "File Services installation completed successfully"
    exit 0
}
catch {
    Write-Log "File Services installation failed: $_" -Level Error
    exit 1
}
