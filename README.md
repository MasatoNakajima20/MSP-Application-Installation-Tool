# MSP Application Installation Tool

GUI launcher for installing, removing, and updating Windows applications via **winget**. Mirrors the architecture of the [MSP M365 Utility](https://github.com/MasatoNakajima20/MSP-M365-Utility): a single-file WinForms launcher with per-app modules fetched from GitHub on demand.

Current version: **0.3.0-beta**

## Quick start

Run on any Windows machine, no local clone required:

```powershell
iex (irm "https://raw.githubusercontent.com/MasatoNakajima20/MSP-Application-Installation-Tool/main/Launch-MSPAppInstaller.ps1")
```

Or run locally:

```powershell
.\Launch-MSPAppInstaller.ps1
```

## What it does

- Lists supported applications as cards, grouped under category section headers (Browsers, Productivity, Utilities, Media)
- For each app, shows current install state (Installed / Not installed) and version when available
- When a newer version is available, the card shows **Update Available v<version>**
- **Install** button: shown when the app is not installed. Runs the install module in a new PowerShell window (silent install via winget)
- **Uninstall** button: shown when the app is installed. Runs the uninstall module in a new PowerShell window (prompts for confirmation, then silent uninstall via winget)
- **Update** button: shown only when a newer version is available. Runs the upgrade module in a new PowerShell window (silent `winget upgrade`)
- **Refresh** button: re-checks install/update state for every app in the catalog
- Prerequisite banner at the top of the form confirms winget is available

## Detection

Detection is **winget-only** (no registry checks). Each app is detected by running:

```
winget list --id <PackageId> -e --accept-source-agreements
```

If winget reports the exact package ID as present, the app is treated as installed and the installed (and, when newer, available) version is parsed from winget's output. This reliably catches every install type winget tracks, including Squirrel / MSIX apps (e.g. Claude) that write no classic uninstall registry key.

## Logging

Every module and the launcher write a timestamped log via a `Write-Log` function (INFO / WARN / ERROR) to:

```
C:\Logging\MSP Application Installation Tool\
```

Log file naming: `ComputerName_Date_Time_TaskName.log`, for example:

```
DESKTOP01_20260925_093000_Install-GoogleChrome.log
DESKTOP01_20260925_093512_Upgrade-VLC.log
```

The winget module-download cache (files the launcher fetches before running) stays under `%LocalAppData%\Temp\AIT\`. That is a cache, not a log.

## Currently supported

Each app has Install, Uninstall, and Upgrade modules (`Modules/Install-*.ps1`, `Uninstall-*.ps1`, `Upgrade-*.ps1`).

| Application           | Category     | winget ID                      | Module suffix     |
| --------------------- | ------------ | ------------------------------ | ----------------- |
| Google Chrome         | Browsers     | `Google.Chrome`                | `GoogleChrome`    |
| Mozilla Firefox       | Browsers     | `Mozilla.Firefox`              | `MozillaFirefox`  |
| Microsoft Teams       | Productivity | `Microsoft.Teams`              | `MicrosoftTeams`  |
| Microsoft Office      | Productivity | `Microsoft.Office`             | `MicrosoftOffice` |
| Claude AI             | Productivity | `Anthropic.Claude`             | `ClaudeAI`        |
| Adobe Acrobat Reader  | Productivity | `Adobe.Acrobat.Reader.64-bit`  | `AdobeReader`     |
| 7-Zip                 | Utilities    | `7zip.7zip`                    | `7Zip`            |
| Microsoft PowerToys   | Utilities    | `Microsoft.PowerToys`          | `PowerToys`       |
| VLC Media Player      | Media        | `VideoLAN.VLC`                 | `VLC`             |

Note: Microsoft Office (`Microsoft.Office`, the Microsoft 365 Apps) is Click-to-Run and self-manages updates; winget may report no update even when Office updates via its own channel. Installing or removing Office requires administrator rights.

## Adding a new application

1. Add an entry to `$script:Apps` in `Launch-MSPAppInstaller.ps1`:
   ```powershell
   [PSCustomObject]@{
       Name           = '<App Display Name>'
       Publisher      = '<Publisher>'
       Category       = '<Browsers | Productivity | Media>'
       WingetId       = '<winget package id>'
       Description    = '<one-line description>'
       InstallModule  = 'Modules/Install-<Suffix>.ps1'
       UninstallModule= 'Modules/Uninstall-<Suffix>.ps1'
       UpgradeModule  = 'Modules/Upgrade-<Suffix>.ps1'
   }
   ```
   To add a new category, also add its name to `$script:Categories` (this sets display order).
2. Create `Modules/Install-<Suffix>.ps1`, `Modules/Uninstall-<Suffix>.ps1`, and `Modules/Upgrade-<Suffix>.ps1` using an existing app's modules as a template.
3. Bump `$script:Version` and add a CHANGELOG entry.

## Requirements

- Windows 10 1809+ or Windows 11
- PowerShell 5.1 or PowerShell 7
- **winget** (App Installer 1.4+); install from the Microsoft Store if missing
- Admin rights recommended for machine-scope installs and uninstalls; user-scope is used as a fallback when not elevated

## Repository

https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
