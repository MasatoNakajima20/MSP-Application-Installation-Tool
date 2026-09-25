# Architecture

MSP Application Installation Tool - system structure and design decisions.
For task history see PROJECT_STATE.md; for the version log see CHANGELOG.md.

## Overview

A self-contained WinForms launcher plus a set of standalone PowerShell modules,
one triple (Install / Uninstall / Upgrade) per supported application. The launcher
presents each app as a card grouped by category (Browsers / Productivity / Utilities /
Media); clicking an action downloads the
matching module from GitHub on demand and runs it in its own PowerShell window.
Everything is driven through **winget**.

## Components

### Launch-MSPAppInstaller.ps1 (launcher)
Single-file WinForms GUI. Responsibilities:
- Holds the application catalog (`$script:Apps`) and category order (`$script:Categories`).
- Renders the form: header, winget prerequisite banner, a scrolling list of category
  section headers and app cards, and a footer (Refresh / About / Close).
- Detects install/update state per app (`Test-AppInstalled`, winget-only).
- Downloads and launches modules (`Invoke-RemoteModule`) from the repo raw URL into
  the local cache, then starts each in a new PowerShell window with `-NoExit`.
- Logs its own events via `Write-Log`.

Key functions: `Write-Log`, `Show-Banner`, `Ensure-WorkDir`, `Test-WingetAvailable`,
`Get-WingetVersion`, `Test-AppInstalled`, `Invoke-RemoteModule`, `Show-AboutDialog`,
`New-CategoryHeader`, `New-AppCard`, `Update-AppList`.

### Modules/*.ps1 (per-app action modules)
Named `<Verb>-<Suffix>.ps1` where Verb is Install / Uninstall / Upgrade. Each module
is standalone (no shared library) so it can be fetched and run on its own. Every module:
- Prints a cyan banner (`Show-Banner`) and logs via `Write-Log`.
- Detects state with `Get-AppInstallState` (winget-only).
- Runs the corresponding winget command, then reports and logs the result.

Install uses `winget install --scope machine|user`, Uninstall uses `winget uninstall`
(after a Y/N confirmation), Upgrade uses `winget upgrade` only when a newer version
is reported.

## Data flow

1. User runs the launcher (locally or via the `iex (irm ...)` one-liner).
2. For each catalog app, `Test-AppInstalled` runs `winget list --id <id> -e` and parses
   the output line: token 0 = installed version, token 1 (if version-like) = available
   version. This drives the card's chip, version label, update notice, and which buttons show.
3. User clicks Install / Uninstall / Update. `Invoke-RemoteModule` downloads
   `Modules/<Verb>-<Suffix>.ps1` from the repo raw URL into the cache and launches it
   in a new PowerShell window.
4. The module re-detects state, performs the winget action, writes a log, and waits for
   the user to close its window.
5. User clicks Refresh to re-run detection and rebuild the list.

## Key design decisions

- **winget-only detection.** No registry checks. `winget list --id <id> -e` catches all
  install types winget tracks, including Squirrel / MSIX apps (e.g. Claude) that write no
  classic uninstall key. Version and update-availability are parsed from the same output.
- **Standalone modules, fetched on demand.** Each module is fully self-contained and
  downloaded per action, so the launcher one-liner works with no local clone and modules
  can be updated in the repo independently. The trade-off is duplicated boilerplate across
  modules, which is generated from one template for consistency.
- **Own-window execution.** Modules run in a new PowerShell window (`-NoExit`) so their
  interactive prompts (uninstall confirmation, Press Enter to close) behave normally and
  output stays visible.
- **Category-driven UI.** Cards are grouped by the `Category` field; `$script:Categories`
  sets section order. Adding a category is data-only.
- **Logging.** Logs go to `C:\Logging\MSP Application Installation Tool\` named
  `ComputerName_Date_Time_TaskName.log`. The winget download cache is kept separate under
  `%LocalAppData%\Temp\AIT\` (a cache, not a log).

## External dependencies

- **winget** (App Installer) - all detect/install/uninstall/upgrade operations.
- **GitHub raw** - module source, fetched on demand by the launcher.
- **.NET WinForms / System.Drawing** - the launcher GUI.
