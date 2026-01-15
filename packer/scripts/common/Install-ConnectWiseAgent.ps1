#Requires -Version 5.1
<#
.SYNOPSIS
    Installs ConnectWise Manage agent from private winget repository.

.DESCRIPTION
    This script installs the ConnectWise Manage agent using winget from a private
    repository with token-based authentication. The script is designed to be run
    by Packer during image creation.

.NOTES
    File Name : Install-ConnectWiseAgent.ps1
    Author    : Packer Build Process
    Requires  : PowerShell 5.1+, Windows Server 2022+

.ENVIRONMENT VARIABLES
    CONNECTWISE_TOKEN    - Authentication token for the winget repository
    CONNECTWISE_REPO_URL - URL of the private winget repository
    INSTALL_AGENT        - Set to 'false' to skip installation
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
    Write-Log "Starting ConnectWise Manage agent installation process..."

    # Check if installation is enabled
    $installAgent = $env:INSTALL_AGENT
    if ($installAgent -eq 'false') {
        Write-Log "ConnectWise agent installation skipped (INSTALL_AGENT=false)"
        exit 0
    }

    # Get configuration from environment variables
    $token = $env:CONNECTWISE_TOKEN
    $repoUrl = $env:CONNECTWISE_REPO_URL

    # Validate token
    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Log "CONNECTWISE_TOKEN environment variable not set - skipping agent installation" -Level Warning
        exit 0
    }

    # Validate repository URL
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        throw "CONNECTWISE_REPO_URL environment variable is required"
    }

    Write-Log "Repository URL: $repoUrl"

    # Ensure winget is available (Server Core may need App Installer)
    Write-Log "Verifying winget availability..."
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue

    if (-not $wingetPath) {
        Write-Log "winget not found - attempting to install App Installer..." -Level Warning

        # Download and install the latest App Installer for Server Core
        $appInstallerUrl = "https://aka.ms/getwinget"
        $appInstallerPath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"

        Write-Log "Downloading App Installer from $appInstallerUrl..."
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $appInstallerPath -UseBasicParsing

        Write-Log "Installing App Installer..."
        Add-AppxPackage -Path $appInstallerPath -ErrorAction Stop

        # Verify winget is now available
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetPath) {
            throw "Failed to install winget - App Installer installation unsuccessful"
        }

        Write-Log "winget installed successfully"
    } else {
        Write-Log "winget found at: $($wingetPath.Source)"
    }

    # Build the authentication header JSON
    $headerJson = "{'Token': '$token'}"

    Write-Log "Installing ConnectWise Manage agent..."

    # Execute winget install with authentication header
    $wingetArgs = @(
        'install',
        '--source', $repoUrl,
        '--header', $headerJson,
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--silent'
    )

    Write-Log "Executing: winget $($wingetArgs -join ' ' -replace $token, '***TOKEN***')"

    $process = Start-Process -FilePath 'winget' -ArgumentList $wingetArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "winget install failed with exit code $($process.ExitCode)"
    }

    # Verify agent service is installed
    Write-Log "Verifying ConnectWise agent installation..."
    $cwService = Get-Service -Name 'LTService' -ErrorAction SilentlyContinue
    if ($cwService) {
        Write-Log "ConnectWise agent service found: $($cwService.DisplayName) - Status: $($cwService.Status)"
    } else {
        Write-Log "ConnectWise agent service not found - this may be expected depending on agent type" -Level Warning
    }

    Write-Log "ConnectWise Manage agent installed successfully"
    exit 0
}
catch {
    Write-Log "ConnectWise agent installation failed: $_" -Level Error
    exit 1
}
