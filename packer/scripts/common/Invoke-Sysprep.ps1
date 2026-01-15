#Requires -Version 5.1
<#
.SYNOPSIS
    Executes Sysprep to generalise the Windows image for Azure deployment.

.DESCRIPTION
    This script waits for Azure agents to be ready and then executes Sysprep
    to generalise the image. This prepares the image for deployment as an
    Azure managed image.

.PARAMETER TimeoutSeconds
    Maximum time to wait for each operation (default: 300 seconds)

.NOTES
    File Name : Invoke-Sysprep.ps1
    Author    : Packer Build Process
    Requires  : PowerShell 5.1+, Windows Server 2022+
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'

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

function Wait-ForService {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        [int]$Timeout = 300
    )

    $timer = [Diagnostics.Stopwatch]::StartNew()

    while ($true) {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($service -and $service.Status -eq 'Running') {
            Write-Log "$ServiceName service is running"
            return $true
        }

        if ($timer.Elapsed.TotalSeconds -gt $Timeout) {
            throw "Timeout waiting for $ServiceName service after $Timeout seconds"
        }

        Write-Log "Waiting for $ServiceName service... ($(([int]$timer.Elapsed.TotalSeconds))s)"
        Start-Sleep -Seconds 5
    }
}

try {
    Write-Log "Starting Sysprep preparation..."
    Write-Log "Timeout configured: $TimeoutSeconds seconds per operation"

    # -------------------------------------------------------------------------
    # Wait for Azure agents
    # -------------------------------------------------------------------------
    Write-Log "Waiting for Azure agents to be ready..."

    # Wait for RdAgent service
    Wait-ForService -ServiceName 'RdAgent' -Timeout $TimeoutSeconds

    # Wait for Windows Azure Guest Agent
    Wait-ForService -ServiceName 'WindowsAzureGuestAgent' -Timeout $TimeoutSeconds

    Write-Log "All Azure agents are running"

    # -------------------------------------------------------------------------
    # Execute Sysprep
    # -------------------------------------------------------------------------
    Write-Log "Starting Sysprep generalisation..."

    $sysprepPath = "$env:SystemRoot\System32\Sysprep\Sysprep.exe"

    if (-not (Test-Path $sysprepPath)) {
        throw "Sysprep.exe not found at: $sysprepPath"
    }

    # Sysprep arguments for Azure image generalisation
    # /oobe      - Start OOBE on next boot
    # /generalize - Remove system-specific data
    # /quiet     - No user interaction
    # /quit      - Exit after completion
    # /mode:vm   - VM mode (faster, for virtual machines)
    $sysprepArgs = '/oobe /generalize /quiet /quit /mode:vm'

    Write-Log "Executing: $sysprepPath $sysprepArgs"

    $process = Start-Process -FilePath $sysprepPath -ArgumentList $sysprepArgs -Wait -PassThru -NoNewWindow

    Write-Log "Sysprep process exited with code: $($process.ExitCode)"

    # -------------------------------------------------------------------------
    # Wait for Sysprep to complete
    # -------------------------------------------------------------------------
    Write-Log "Waiting for image generalisation to complete..."

    $timer = [Diagnostics.Stopwatch]::StartNew()
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State'

    while ($true) {
        $imageState = $null

        try {
            $setupState = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
            if ($setupState) {
                $imageState = $setupState.ImageState
            }
        }
        catch {
            Write-Log "Unable to read image state - registry may be updating" -Level Warning
        }

        if ($imageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') {
            Write-Log "Sysprep completed successfully - image is generalised"
            break
        }

        if ($timer.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
            throw "Timeout waiting for Sysprep to complete after $TimeoutSeconds seconds. Last state: $imageState"
        }

        Write-Log "Current image state: $imageState ($(([int]$timer.Elapsed.TotalSeconds))s)"
        Start-Sleep -Seconds 10
    }

    Write-Log "Image generalisation completed successfully"
    exit 0
}
catch {
    Write-Log "Sysprep failed: $_" -Level Error
    exit 1
}
