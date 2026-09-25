# Changelog

All notable changes to the MSP Application Installation Tool are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to Semantic Versioning.

## [0.3.0-beta] - 2026-09-25

### Added
- New applications with Install / Uninstall / Upgrade modules: Mozilla Firefox
  (`Mozilla.Firefox`), Microsoft Office / Microsoft 365 Apps (`Microsoft.Office`),
  VLC Media Player (`VideoLAN.VLC`), 7-Zip (`7zip.7zip`), and Microsoft PowerToys
  (`Microsoft.PowerToys`).
- Category grouping on the launcher form: app cards are grouped under Browsers /
  Productivity / Utilities / Media section headers, driven by a `Category` field on
  each catalog entry and a `$script:Categories` display order.
- `Write-Log` function (INFO / WARN / ERROR, timestamped) in every module and the
  launcher; a cyan banner block and dashed section dividers in every script.

### Changed
- Logging moved from `%LocalAppData%\Temp\AIT` transcripts to
  `C:\Logging\MSP Application Installation Tool\` with `ComputerName_Date_Time_TaskName.log`
  naming. The winget module-download cache still uses `%LocalAppData%\Temp\AIT`.
- All 12 existing modules retrofitted to the project script standard (banner,
  dividers, `Write-Log`, a comment above every function).
- Launcher form enlarged to fit the grouped list.

### Notes
- Office (Microsoft 365 Apps) is Click-to-Run and self-manages updates; winget may
  report no update even when Office updates via its own channel. Install/uninstall
  of Office requires administrator rights.

## [0.2.0-beta] - 2026-06-03

### Added
- Microsoft Teams, Claude AI, and Adobe Acrobat Reader with Install / Uninstall modules.
- Update capability: `winget upgrade` modules per app, an "Update Available v<version>"
  notice on cards, and an Update button shown only when a newer version exists.

### Changed
- Detection switched to winget-only (registry checks removed) across the launcher
  and all modules, fixing detection for Squirrel / MSIX apps such as Claude.
- Dynamic action buttons: Install shown when absent, Uninstall when present.

## [0.1.0-beta] - 2026-06-03

### Added
- Initial release: single-file WinForms launcher and Google Chrome Install /
  Uninstall modules, fetched from GitHub on demand and run via winget.
