#Requires -Version 5.1

<#
.SYNOPSIS
    Uninstalls VLC Media Player via winget.
.DESCRIPTION
    Detects current state via winget (no registry checks). If VLC Media Player is
    installed, prompts to confirm and then runs winget uninstall.
.NOTES
    Part of MSP Application Installation Tool.
    Repo: https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
$AppName  = 'VLC Media Player'
$WingetId = 'VideoLAN.VLC'
$TaskName = 'Uninstall-VLC'

$LogDir = 'C:\Logging\MSP Application Installation Tool'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$stamp   = (Get-Date).ToString('yyyyMMdd_HHmmss')
$LogFile = Join-Path $LogDir "$($env:COMPUTERNAME)_${stamp}_$TaskName.log"

# ---------------------------------------------------------------------------
# FUNCTIONS
# ---------------------------------------------------------------------------

# Writes a timestamped INFO/WARN/ERROR entry to both the console and the log file.
function Write-Log {
    param(
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO',
        [Parameter(Mandatory)][string]$Message
    )
    $ts   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$ts [$Level] $Message"
    switch ($Level) {
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line -ForegroundColor Gray }
    }
    try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 } catch { }
}

# Prints the cyan banner block identifying this task when run interactively.
function Show-Banner {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' MSP Application Installation Tool' -ForegroundColor Cyan
    Write-Host " Task: $TaskName" -ForegroundColor Cyan
    Write-Host " App : $AppName ($WingetId)" -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}

# Returns $true when the winget CLI is available on this machine.
function Test-WingetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

# Queries winget (winget-only, no registry) for install state; returns
# Installed, Version (installed), Available (newer, if any) and Source.
function Get-AppInstallState {
    $state = [PSCustomObject]@{ Installed = $false; Version = $null; Available = $null; Source = $null }
    if (Test-WingetAvailable) {
        try {
            $out = winget list --id $WingetId -e --accept-source-agreements 2>$null
            if ($LASTEXITCODE -eq 0) {
                $wLine = $out | Where-Object { $_ -match [regex]::Escape($WingetId) } | Select-Object -First 1
                if ($wLine) {
                    $idx    = $wLine.IndexOf($WingetId)
                    $rest   = $wLine.Substring($idx + $WingetId.Length).Trim()
                    $tokens = $rest -split '\s+'
                    $ver    = $tokens[0]
                    if ($ver -notmatch '^[\d]') { $ver = $null }
                    $avail = $null
                    if ($tokens.Count -ge 2 -and $tokens[1] -match '^[\d]') { $avail = $tokens[1] }
                    $state.Installed = $true
                    $state.Version   = $ver
                    $state.Available = $avail
                    $state.Source    = 'winget'
                }
            }
        } catch { }
    }
    return $state
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
Show-Banner
Write-Log INFO "Log file: $LogFile"

if (-not (Test-WingetAvailable)) {
    Write-Log ERROR "winget is not available. Install 'App Installer' from the Microsoft Store, or upgrade Windows, then retry."
    Read-Host "`nPress Enter to close"
    exit 1
}

Write-Log INFO "Checking current install state ..."
$state = Get-AppInstallState

if (-not $state.Installed) {
    Write-Log INFO "$AppName is not installed. Nothing to do."
    Read-Host "`nPress Enter to close"
    exit 0
}

Write-Log INFO "$AppName is installed (version: $($state.Version))."
$confirm = Read-Host "Proceed with uninstall of $AppName? (Y/N)"
if ($confirm -notmatch '^(?i)y(es)?$') {
    Write-Log WARN "Cancelled by user. No changes made."
    Read-Host "`nPress Enter to close"
    exit 0
}

Write-Log INFO "Uninstalling $AppName via winget ..."
$wingetArgs = @(
    'uninstall',
    '--id', $WingetId,
    '-e',
    '--accept-source-agreements',
    '--silent'
)
& winget @wingetArgs
$code = $LASTEXITCODE

if ($code -eq 0) {
    $after = Get-AppInstallState
    if ($after.Installed) {
        Write-Log WARN "winget reported success but $AppName still appears present. A reboot or per-profile copies may remain."
    } else {
        Write-Log INFO "Uninstall completed."
    }
} else {
    Write-Log ERROR "winget exited with code $code. Review the output above for the cause."
}

Write-Log INFO "Done. Log saved to: $LogFile"
Read-Host "`nPress Enter to close"