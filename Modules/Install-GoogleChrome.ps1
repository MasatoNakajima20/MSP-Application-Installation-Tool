#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Google Chrome via winget.

.DESCRIPTION
    Checks if Google Chrome is already installed (winget + registry uninstall keys).
    If present, prints the current version and exits without action.
    If absent, installs Google.Chrome via winget in machine scope when running
    elevated, otherwise user scope.

.NOTES
    Part of MSP Application Installation Tool.
    Repo: https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
#>

$ErrorActionPreference = 'Stop'

$AppName    = 'Google Chrome'
$WingetId   = 'Google.Chrome'

# All logs and temp files live here (per AIT convention)
$AITDir = Join-Path $env:USERPROFILE 'AppData\Local\Temp\AIT'
if (-not (Test-Path $AITDir)) {
    New-Item -ItemType Directory -Path $AITDir -Force | Out-Null
}
$LogFile = Join-Path $AITDir ("Install-GoogleChrome_{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
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

function Get-ChromeInstallState {
    # Returns @{ Installed = $bool; Version = $string; Source = $string }
    $state = [PSCustomObject]@{ Installed = $false; Version = $null; Source = $null }

    # 1) Registry uninstall keys (machine + user)
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($p in $uninstallPaths) {
        $hit = Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
               Where-Object { $_.DisplayName -like 'Google Chrome*' } |
               Select-Object -First 1
        if ($hit) {
            $state.Installed = $true
            $state.Version   = $hit.DisplayVersion
            $state.Source    = 'Registry'
            return $state
        }
    }

    # 2) winget fallback
    if (Test-WingetAvailable) {
        try {
            $out = winget list --id $WingetId -e --accept-source-agreements 2>$null
            if ($LASTEXITCODE -eq 0 -and ($out -match $WingetId)) {
                $state.Installed = $true
                $state.Source    = 'winget'
                return $state
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
$state = Get-ChromeInstallState

if ($state.Installed) {
    Write-Host ''
    Write-Host "$AppName is already installed." -ForegroundColor Green
    if ($state.Version) { Write-Host "  Version : $($state.Version)" -ForegroundColor Gray }
    Write-Host "  Source  : $($state.Source)" -ForegroundColor Gray
    Write-Host ''
    Write-Host "Nothing to do. To remove it, run the Uninstall Google Chrome module." -ForegroundColor Yellow
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 0
}

# Decide scope based on elevation
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
    $after = Get-ChromeInstallState
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
