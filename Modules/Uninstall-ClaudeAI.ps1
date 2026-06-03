#Requires -Version 5.1

<#
.SYNOPSIS
    Uninstalls Claude AI desktop via winget.

.DESCRIPTION
    Detects Claude (registry uninstall keys + winget). If present, prompts to
    confirm and then runs winget uninstall. If absent, exits cleanly.

.NOTES
    Part of MSP Application Installation Tool.
    Repo: https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
#>

$ErrorActionPreference = 'Stop'

$AppName     = 'Claude AI'
$WingetId    = 'Anthropic.Claude'
$DisplayLike = 'Claude*'

$AITDir = Join-Path $env:USERPROFILE 'AppData\Local\Temp\AIT'
if (-not (Test-Path $AITDir)) {
    New-Item -ItemType Directory -Path $AITDir -Force | Out-Null
}
$LogFile = Join-Path $AITDir ("Uninstall-ClaudeAI_{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
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
    $state = [PSCustomObject]@{ Installed = $false; Version = $null; Source = $null }

    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($p in $uninstallPaths) {
        $hit = Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
               Where-Object {
                   $_.DisplayName -like $DisplayLike -and
                   ($_.Publisher -like 'Anthropic*' -or $_.DisplayName -like '*Claude*')
               } |
               Select-Object -First 1
        if ($hit) {
            $state.Installed = $true
            $state.Version   = $hit.DisplayVersion
            $state.Source    = 'Registry'
            return $state
        }
    }

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

Write-Header "Uninstall: $AppName"
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
    Write-Host "$AppName is not installed. Nothing to do." -ForegroundColor Yellow
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 0
}

Write-Host ''
Write-Host "$AppName is currently installed." -ForegroundColor Green
if ($state.Version) { Write-Host "  Version : $($state.Version)" -ForegroundColor Gray }
Write-Host "  Source  : $($state.Source)" -ForegroundColor Gray
Write-Host ''

$confirm = Read-Host "Proceed with uninstall? (Y/N)"
if ($confirm -notmatch '^(?i)y(es)?$') {
    Write-Host "Cancelled. No changes made." -ForegroundColor Yellow
    try { Stop-Transcript | Out-Null } catch { }
    Read-Host "`nPress Enter to close"
    exit 0
}

Write-Host ''
Write-Host "Uninstalling $AppName via winget ..." -ForegroundColor Cyan

$wingetArgs = @(
    'uninstall',
    '--id', $WingetId,
    '-e',
    '--accept-source-agreements',
    '--silent'
)

& winget @wingetArgs
$code = $LASTEXITCODE

Write-Host ''
if ($code -eq 0) {
    $after = Get-AppInstallState
    if ($after.Installed) {
        Write-Host "winget reported success but $AppName still appears to be present." -ForegroundColor Yellow
        Write-Host "It may require an additional reboot, or per-user copies may remain on other profiles." -ForegroundColor Yellow
    } else {
        Write-Host "Uninstall completed." -ForegroundColor Green
    }
} else {
    Write-Host "winget exited with code $code." -ForegroundColor Red
    Write-Host "Review the output above for the cause." -ForegroundColor Yellow
}

Write-Host ''
Write-Host "Log saved to: $LogFile" -ForegroundColor DarkGray
try { Stop-Transcript | Out-Null } catch { }
Read-Host "`nPress Enter to close"
