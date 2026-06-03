#Requires -Version 5.1

<#
.SYNOPSIS
    Updates Microsoft Teams to the latest version via winget.

.DESCRIPTION
    Checks the installed and latest-available versions via winget. If an update
    is available, runs winget upgrade. If the app is not installed, or already
    up to date, it exits without action.

.NOTES
    Part of MSP Application Installation Tool.
    Repo: https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
#>

$ErrorActionPreference = 'Stop'

$AppName  = 'Microsoft Teams'
$WingetId = 'Microsoft.Teams'

$AITDir = Join-Path $env:USERPROFILE 'AppData\Local\Temp\AIT'
if (-not (Test-Path $AITDir)) {
    New-Item -ItemType Directory -Path $AITDir -Force | Out-Null
}
$LogFile = Join-Path $AITDir ("Upgrade-MicrosoftTeams_{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
try { Start-Transcript -Path $LogFile -Force | Out-Null } catch { }

function Write-Header {
    param([string]$Text)
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host ('=' * 60) -ForegroundColor Cyan
}

function Test-WingetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Get-AppInstallState {
    # winget-only: Installed, Version (installed), Available (newer), Source
    $state = [PSCustomObject]@{ Installed = $false; Version = $null; Available = $null; Source = $null }

    if (Test-WingetAvailable) {
        try {
            $out = winget list --id $WingetId -e --accept-source-agreements 2>$null
            if ($LASTEXITCODE -eq 0) {
                $line = $out | Where-Object { $_ -match [regex]::Escape($WingetId) } | Select-Object -First 1
                if ($line) {
                    $idx    = $line.IndexOf($WingetId)
                    $rest   = $line.Substring($idx + $WingetId.Length).Trim()
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

Write-Header "Update: $AppName"
Write-Host "Log file: $LogFile" -ForegroundColor DarkGray

if (-not (Test-WingetAvailable)) {
    Write-Host "winget is not available on this machine." -ForegroundColor Red
    Write-Host "Install 'App Installer' from the Microsoft Store, or upgrade Windows, then try again." -ForegroundColor Yellow
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 1
}

Write-Host "Checking current install state ..." -ForegroundColor Gray
$state = Get-AppInstallState

if (-not $state.Installed) {
    Write-Host ''
    Write-Host "$AppName is not installed. Use the Install module first." -ForegroundColor Yellow
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 0
}

if (-not $state.Available) {
    Write-Host ''
    Write-Host "$AppName is already up to date." -ForegroundColor Green
    if ($state.Version) { Write-Host "  Installed version: $($state.Version)" -ForegroundColor Gray }
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 0
}

Write-Host ''
Write-Host "$AppName update available." -ForegroundColor Cyan
Write-Host "  Installed : $($state.Version)" -ForegroundColor Gray
Write-Host "  Available : $($state.Available)" -ForegroundColor Gray
Write-Host ''
Write-Host "Updating $AppName via winget ..." -ForegroundColor Cyan

$wingetArgs = @(
    'upgrade',
    '--id', $WingetId,
    '-e',
    '--accept-source-agreements',
    '--accept-package-agreements',
    '--silent'
)

& winget @wingetArgs
$code = $LASTEXITCODE

Write-Host ''
if ($code -eq 0) {
    $after = Get-AppInstallState
    Write-Host "Update completed." -ForegroundColor Green
    if ($after.Version) { Write-Host "  Installed version: $($after.Version)" -ForegroundColor Gray }
} else {
    Write-Host "winget exited with code $code." -ForegroundColor Red
    Write-Host "Review the output above for the cause." -ForegroundColor Yellow
}

Write-Host ''
Write-Host "Log saved to: $LogFile" -ForegroundColor DarkGray
try { Stop-Transcript | Out-Null } catch { }
Read-Host "`nPress Enter to close"
