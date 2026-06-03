# MSP Application Installation Tool

GUI launcher for installing and removing Windows applications via **winget**. Mirrors the architecture of the [MSP M365 Utility](https://github.com/MasatoNakajima20/MSP-M365-Utility): a single-file WinForms launcher with per-app modules fetched from GitHub on demand.

Current version: **0.1.0-beta**

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

- Lists supported applications as cards on a single landing form
- For each app, shows current install state (Installed / Not installed) and version when available
- **Install** button: downloads the install module and runs it in a new PowerShell window (silent install via winget)
- **Uninstall** button: downloads the uninstall module and runs it in a new PowerShell window (prompts for confirmation, then silent uninstall via winget)
- **Refresh** button: re-checks install state for every app in the catalog
- Prerequisite banner at the top of the form confirms winget is available

## Logs and temp files

All cached module files and per-run transcript logs are stored under:

```
C:\Users\<Username>\AppData\Local\Temp\AIT\
```

Each install/uninstall run writes a timestamped log, e.g.:

```
Install-GoogleChrome_20260603-141207.log
Uninstall-GoogleChrome_20260603-141554.log
```

## Detection

Each app is detected via:

1. Windows uninstall registry keys (`HKLM` and `HKCU`, both 64-bit and WOW6432Node)
2. `winget list --id <PackageId> -e` as a fallback

Version is reported from the registry `DisplayVersion` when available.

## Currently supported

| Application           | winget ID                       | Install                                  | Uninstall                                  |
| --------------------- | ------------------------------- | ---------------------------------------- | ------------------------------------------ |
| Google Chrome         | `Google.Chrome`                 | `Modules/Install-GoogleChrome.ps1`       | `Modules/Uninstall-GoogleChrome.ps1`       |
| Microsoft Teams       | `Microsoft.Teams`               | `Modules/Install-MicrosoftTeams.ps1`     | `Modules/Uninstall-MicrosoftTeams.ps1`     |
| Claude AI             | `Anthropic.Claude`              | `Modules/Install-ClaudeAI.ps1`           | `Modules/Uninstall-ClaudeAI.ps1`           |
| Adobe Acrobat Reader  | `Adobe.Acrobat.Reader.64-bit`   | `Modules/Install-AdobeReader.ps1`        | `Modules/Uninstall-AdobeReader.ps1`        |

## Adding a new application

1. Add an entry to `$script:Apps` in `Launch-MSPAppInstaller.ps1`:
   ```powershell
   [PSCustomObject]@{
       Name           = '<App Display Name>'
       Publisher      = '<Publisher>'
       WingetId       = '<winget package id>'
       Description    = '<one-line description>'
       InstallModule  = 'Modules/Install-<App>.ps1'
       UninstallModule= 'Modules/Uninstall-<App>.ps1'
       DetectNameLike = '<DisplayName wildcard>'
   }
   ```
2. Create `Modules/Install-<App>.ps1` and `Modules/Uninstall-<App>.ps1` using the Chrome modules as a template.
3. Bump `$script:Version`.

## Requirements

- Windows 10 1809+ or Windows 11
- PowerShell 5.1 or PowerShell 7
- **winget** (App Installer 1.4+) — install from the Microsoft Store if missing
- Admin rights recommended for machine-scope installs and uninstalls; user-scope is used as a fallback when not elevated

## Repository

https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
