# PROJECT_STATE

Project: MSP Application Installation Tool
Current version: 0.3.0-beta (built locally; not yet committed/pushed)
Last pushed: 0.2.0-beta
Last updated: 2026-09-25

## In Progress

(none)

## Done

- v0.3.0-beta - 2026-09-25 (local; pending commit/push to branch v0.3.0)
  - Added Mozilla Firefox, Microsoft Office, VLC Media Player, 7-Zip, Microsoft PowerToys
    (Install/Uninstall/Upgrade = 15 new modules)
  - Added category grouping on the form (Browsers / Productivity / Utilities / Media section headers)
  - Adopted the CLAUDE.md script standard across all scripts: cyan banner, dashed section
    dividers, Write-Log (INFO/WARN/ERROR), per-function header comments
  - Moved logging to C:\Logging\MSP Application Installation Tool\ (ComputerName_Date_Time_TaskName.log);
    winget download cache stays in %LocalAppData%\Temp\AIT
  - Retrofitted all 12 existing modules to the standard; launcher bumped to 0.3.0-beta
  - Created ARCHITECTURE.md, CHANGELOG.md, PROJECT_STATE.md; updated README.md
  - Verified: all 22 .ps1 files parse; modules are ASCII-only; category grouping and
    winget detection validated live for all 7 apps
- v0.2.0-beta - 2026-06-03 - Added Teams, Claude, Adobe; dynamic Install/Uninstall/Update
  buttons; winget-only detection (dropped registry checks); Update button + upgrade modules
- v0.1.0-beta - 2026-06-03 - Initial: WinForms launcher + Google Chrome Install/Uninstall modules

## Notes / Decisions

- Detection is winget-only (no registry checks) across launcher and all modules.
- Logs: C:\Logging\MSP Application Installation Tool\ named ComputerName_Date_Time_TaskName.log.
  Supersedes the earlier %LocalAppData%\Temp\AIT log location per the updated CLAUDE.md.
- Module download cache (launcher fetch target) remains %LocalAppData%\Temp\AIT (a cache, not a log).
- Each app is self-contained across three modules (Install-/Uninstall-/Upgrade-<Suffix>.ps1),
  fetched from GitHub on demand by the launcher.
- Categories are data-driven: Category field per app + $script:Categories for display order.
- Git (per CLAUDE.md): push to a version branch (v0.3.0), never direct to main; no AI co-author;
  ask for the commit message; commit/push only when explicitly instructed.

## Next step

- Awaiting instruction to commit and push v0.3.0-beta to a new branch (v0.3.0).
