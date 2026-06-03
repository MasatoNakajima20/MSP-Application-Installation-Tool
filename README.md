# MSP Application Installation Tool

GUI launcher for installing and removing Windows applications via **winget**. Mirrors the architecture of the [MSP M365 Utility](https://github.com/MasatoNakajima20/MSP-M365-Utility): a single-file WinForms launcher with per-app modules fetched from GitHub on demand.

Current version: **0.2.0-beta**

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
- When a newer version is available, the card shows **Update Available v<version>**
- **Install** button: shown when the app is not installed — runs the install module in a new PowerShell window (silent install via winget)
- **Uninstall** button: shown when the app is installed — runs the uninstall module in a new PowerShell window (prompts for confirmation, then silent uninstall via winget)
- **Update** button: shown only when a newer version is available — runs the upgrade module in a new PowerShell window (silent `winget upgrade`)
- **Refresh** button: re-checks install/update state for every app in the catalog
- Prerequisite banner at the top of the form confirms winget is available

## Logs and temp files

All cached module files and per-run transcript logs are stored under:

```
C:\Users\<Username>\AppData\Local\Temp\AIT\
```

Each install/uninstall/upgrade run writes a timestamped log, e.g.:

```
Install-GoogleChrome_20260603-141207.log
Uninstall-GoogleChrome_20260603-141554.log
Upgrade-GoogleChrome_20260603-142010.log
```

## Detection

Detection is **winget-only** — no registry checks. Each app is detected by running:

```
winget list --id <PackageId> -e --accept-source-agreements
```

If winget reports the exact package ID as present, the app is treated as installed and the installed version is parsed from winget's output. This reliably catches every install type winget tracks, including Squirrel / MSIX apps (e.g. Claude) that write no classic uninstall registry key.

## Currently supported

Each app has Install, Uninstall, and Upgrade modules (`Modules/Install-*.ps1`, `Uninstall-*.ps1`, `Upgrade-*.ps1`).

| Application           | winget ID                       | Module suffix         |
| --------------------- | ------------------------------- | --------------------- |
| Google Chrome         | `Google.Chrome`                 | `GoogleChrome`        |
| Microsoft Teams       | `Microsoft.Teams`               | `MicrosoftTeams`      |
| Claude AI             | `Anthropic.Claude`              | `ClaudeAI`            |
| Adobe Acrobat Reader  | `Adobe.Acrobat.Reader.64-bit`   | `AdobeReader`         |

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
       UpgradeModule  = 'Modules/Upgrade-<App>.ps1'
   }
   ```
2. Create `Modules/Install-<App>.ps1`, `Modules/Uninstall-<App>.ps1`, and `Modules/Upgrade-<App>.ps1` using the Chrome modules as a template.
3. Bump `$script:Version`.

## Requirements

- Windows 10 1809+ or Windows 11
- PowerShell 5.1 or PowerShell 7
- **winget** (App Installer 1.4+) — install from the Microsoft Store if missing
- Admin rights recommended for machine-scope installs and uninstalls; user-scope is used as a fallback when not elevated

## Repository

https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
