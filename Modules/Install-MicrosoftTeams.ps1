#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Microsoft Teams via winget.

.DESCRIPTION
    Checks if Microsoft Teams is already installed (winget + registry uninstall keys).
    If present, prints the current version and exits without action.
    If absent, installs Microsoft.Teams via winget in machine scope when running
    elevated, otherwise user scope.

.NOTES
    Part of MSP Application Installation Tool.
    Repo: https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
#>

$ErrorActionPreference = 'Stop'

$AppName       = 'Microsoft Teams'
$WingetId      = 'Microsoft.Teams'

$AITDir = Join-Path $env:USERPROFILE 'AppData\Local\Temp\AIT'
if (-not (Test-Path $AITDir)) {
    New-Item -ItemType Directory -Path $AITDir -Force | Out-Null
}
$LogFile = Join-Path $AITDir ("Install-MicrosoftTeams_{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
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
    # Detection is winget-only - no registry checks.
    $state = [PSCustomObject]@{ Installed = $false; Version = $null; Source = $null }

    if (Test-WingetAvailable) {
        try {
            $out = winget list --id $WingetId -e --accept-source-agreements 2>$null
            if ($LASTEXITCODE -eq 0) {
                $line = $out | Where-Object { $_ -match [regex]::Escape($WingetId) } | Select-Object -First 1
                if ($line) {
                    $idx  = $line.IndexOf($WingetId)
                    $rest = $line.Substring($idx + $WingetId.Length).Trim()
                    $ver  = ($rest -split '\s+' | Select-Object -First 1)
                    if ($ver -notmatch '^[\d]') { $ver = $null }
                    $state.Installed = $true
                    $state.Version   = $ver
                    $state.Source    = 'winget'
                }
            }
        } catch { }
    }

    return $state
}

Write-Header "Install: $AppName"
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

if ($state.Installed) {
    Write-Host ''
    Write-Host "$AppName is already installed." -ForegroundColor Green
    if ($state.Version) { Write-Host "  Version : $($state.Version)" -ForegroundColor Gray }
    Write-Host "  Source  : $($state.Source)" -ForegroundColor Gray
    Write-Host ''
    Write-Host "Nothing to do. To remove it, run the Uninstall $AppName module." -ForegroundColor Yellow
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 0
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
$scope = if ($isAdmin) { 'machine' } else { 'user' }

Write-Host ''
Write-Host "Installing $AppName via winget ..." -ForegroundColor Cyan
Write-Host "  Package ID : $WingetId" -ForegroundColor Gray
Write-Host "  Scope      : $scope" -ForegroundColor Gray
Write-Host ''

$wingetArgs = @(
    'install',
    '--id', $WingetId,
    '-e',
    '--scope', $scope,
    '--accept-source-agreements',
    '--accept-package-agreements',
    '--silent'
)

& winget @wingetArgs
$code = $LASTEXITCODE

Write-Host ''
if ($code -eq 0) {
    $after = Get-AppInstallState
    Write-Host "Install completed." -ForegroundColor Green
    if ($after.Version) { Write-Host "  Installed version: $($after.Version)" -ForegroundColor Gray }
} else {
    Write-Host "winget exited with code $code." -ForegroundColor Red
    Write-Host "Review the output above for the cause." -ForegroundColor Yellow
}

Write-Host ''
Write-Host "Log saved to: $LogFile" -ForegroundColor DarkGray
try { Stop-Transcript | Out-Null } catch { }
Read-Host "`nPress Enter to close"
