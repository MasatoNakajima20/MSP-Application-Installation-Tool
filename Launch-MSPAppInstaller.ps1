#Requires -Version 5.1

<#
.SYNOPSIS
    MSP Application Installation Tool - GUI launcher.

.DESCRIPTION
    Single-file WinForms launcher. Lists supported applications grouped by
    category (Browsers / Productivity / Media). Each app card shows current
    install state and offers Install, Uninstall, or Update, which downloads the
    matching module from GitHub on demand and runs it in its own PowerShell
    window. Detection is winget-only (no registry checks).

.EXAMPLE
    # Run on any Windows machine - no local clone needed:
    iex (irm "https://raw.githubusercontent.com/MasatoNakajima20/MSP-Application-Installation-Tool/main/Launch-MSPAppInstaller.ps1")

.NOTES
    Repo : https://github.com/MasatoNakajima20/MSP-Application-Installation-Tool
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
$script:RepoOwner  = 'MasatoNakajima20'
$script:RepoName   = 'MSP-Application-Installation-Tool'
$script:Branch     = 'main'
$script:Version    = '0.3.0-beta'
$script:TaskName   = 'Launch-MSPAppInstaller'
$script:BaseRawUrl = "https://raw.githubusercontent.com/$script:RepoOwner/$script:RepoName/$script:Branch"

# winget module-download cache (a cache, not a log): stays under %LocalAppData%\Temp\AIT.
$script:WorkDir    = Join-Path $env:USERPROFILE 'AppData\Local\Temp\AIT'

# Logs go to C:\Logging\<Project>\ per the project standard.
$script:LogDir     = 'C:\Logging\MSP Application Installation Tool'
if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null }
$script:LogFile    = Join-Path $script:LogDir ("{0}_{1}_{2}.log" -f $env:COMPUTERNAME, (Get-Date).ToString('yyyyMMdd_HHmmss'), $script:TaskName)

# Category display order for the grouped list.
$script:Categories = @('Browsers', 'Productivity', 'Utilities', 'Media')

# ---------------------------------------------------------------------------
# APPLICATION CATALOG
# ---------------------------------------------------------------------------
# Add a new entry per application. Each app is backed by three modules
# (Install-/Uninstall-/Upgrade-<Suffix>.ps1) and belongs to one Category.
$script:Apps = @(
    [PSCustomObject]@{
        Name           = 'Google Chrome'
        Publisher      = 'Google'
        Category       = 'Browsers'
        WingetId       = 'Google.Chrome'
        Description    = "Google's web browser. Silent install via winget."
        InstallModule  = 'Modules/Install-GoogleChrome.ps1'
        UninstallModule= 'Modules/Uninstall-GoogleChrome.ps1'
        UpgradeModule  = 'Modules/Upgrade-GoogleChrome.ps1'
    }
    [PSCustomObject]@{
        Name           = 'Mozilla Firefox'
        Publisher      = 'Mozilla'
        Category       = 'Browsers'
        WingetId       = 'Mozilla.Firefox'
        Description    = "Mozilla Firefox web browser. Silent install via winget."
        InstallModule  = 'Modules/Install-MozillaFirefox.ps1'
        UninstallModule= 'Modules/Uninstall-MozillaFirefox.ps1'
        UpgradeModule  = 'Modules/Upgrade-MozillaFirefox.ps1'
    }
    [PSCustomObject]@{
        Name           = 'Microsoft Teams'
        Publisher      = 'Microsoft'
        Category       = 'Productivity'
        WingetId       = 'Microsoft.Teams'
        Description    = "Microsoft Teams desktop client. Silent install via winget."
        InstallModule  = 'Modules/Install-MicrosoftTeams.ps1'
        UninstallModule= 'Modules/Uninstall-MicrosoftTeams.ps1'
        UpgradeModule  = 'Modules/Upgrade-MicrosoftTeams.ps1'
    }
    [PSCustomObject]@{
        Name           = 'Microsoft Office'
        Publisher      = 'Microsoft'
        Category       = 'Productivity'
        WingetId       = 'Microsoft.Office'
        Description    = "Microsoft 365 Apps (Office). Requires admin; self-updates."
        InstallModule  = 'Modules/Install-MicrosoftOffice.ps1'
        UninstallModule= 'Modules/Uninstall-MicrosoftOffice.ps1'
        UpgradeModule  = 'Modules/Upgrade-MicrosoftOffice.ps1'
    }
    [PSCustomObject]@{
        Name           = 'Claude AI'
        Publisher      = 'Anthropic'
        Category       = 'Productivity'
        WingetId       = 'Anthropic.Claude'
        Description    = "Anthropic's Claude desktop app. Silent install via winget."
        InstallModule  = 'Modules/Install-ClaudeAI.ps1'
        UninstallModule= 'Modules/Uninstall-ClaudeAI.ps1'
        UpgradeModule  = 'Modules/Upgrade-ClaudeAI.ps1'
    }
    [PSCustomObject]@{
        Name           = 'Adobe Acrobat Reader'
        Publisher      = 'Adobe'
        Category       = 'Productivity'
        WingetId       = 'Adobe.Acrobat.Reader.64-bit'
        Description    = "Adobe Acrobat Reader (64-bit). Silent install via winget."
        InstallModule  = 'Modules/Install-AdobeReader.ps1'
        UninstallModule= 'Modules/Uninstall-AdobeReader.ps1'
        UpgradeModule  = 'Modules/Upgrade-AdobeReader.ps1'
    }
    [PSCustomObject]@{
        Name           = '7-Zip'
        Publisher      = 'Igor Pavlov'
        Category       = 'Utilities'
        WingetId       = '7zip.7zip'
        Description    = "7-Zip file archiver / extractor. Silent install via winget."
        InstallModule  = 'Modules/Install-7Zip.ps1'
        UninstallModule= 'Modules/Uninstall-7Zip.ps1'
        UpgradeModule  = 'Modules/Upgrade-7Zip.ps1'
    }
    [PSCustomObject]@{
        Name           = 'Microsoft PowerToys'
        Publisher      = 'Microsoft'
        Category       = 'Utilities'
        WingetId       = 'Microsoft.PowerToys'
        Description    = "Microsoft PowerToys - Windows power-user utilities. Silent install via winget."
        InstallModule  = 'Modules/Install-PowerToys.ps1'
        UninstallModule= 'Modules/Uninstall-PowerToys.ps1'
        UpgradeModule  = 'Modules/Upgrade-PowerToys.ps1'
    }
    [PSCustomObject]@{
        Name           = 'VLC Media Player'
        Publisher      = 'VideoLAN'
        Category       = 'Media'
        WingetId       = 'VideoLAN.VLC'
        Description    = "VLC media player. Silent install via winget."
        InstallModule  = 'Modules/Install-VLC.ps1'
        UninstallModule= 'Modules/Uninstall-VLC.ps1'
        UpgradeModule  = 'Modules/Upgrade-VLC.ps1'
    }
)

# ---------------------------------------------------------------------------
# BRAND PALETTE
# ---------------------------------------------------------------------------
$BrandBlue       = [System.Drawing.ColorTranslator]::FromHtml('#008BC7')
$BrandBlueDark   = [System.Drawing.ColorTranslator]::FromHtml('#00577E')
$BrandBlueLight  = [System.Drawing.ColorTranslator]::FromHtml('#E6F4FA')
$BrandTextDark   = [System.Drawing.ColorTranslator]::FromHtml('#262626')
$BrandTextMuted  = [System.Drawing.ColorTranslator]::FromHtml('#999999')
$BrandGreen      = [System.Drawing.ColorTranslator]::FromHtml('#28A745')
$BrandRed        = [System.Drawing.ColorTranslator]::FromHtml('#C0392B')

# ---------------------------------------------------------------------------
# FUNCTIONS
# ---------------------------------------------------------------------------

# Writes a timestamped INFO/WARN/ERROR entry to both the console and the log file.
function Write-Log {
    param(
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO',
        [Parameter(Mandatory)][string]$Message
    )
    $ts   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$ts [$Level] $Message"
    switch ($Level) {
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line -ForegroundColor Gray }
    }
    try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch { }
}

# Prints the cyan banner block identifying this tool when run interactively.
function Show-Banner {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' MSP Application Installation Tool' -ForegroundColor Cyan
    Write-Host " Task: $script:TaskName   Version: $script:Version" -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}

# Ensures the winget module-download cache directory exists.
function Ensure-WorkDir {
    if (-not (Test-Path $script:WorkDir)) {
        New-Item -ItemType Directory -Path $script:WorkDir -Force | Out-Null
    }
}

# Returns $true when the winget CLI is available on this machine.
function Test-WingetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

# Returns the installed winget version string, or $null when winget is missing.
function Get-WingetVersion {
    if (-not (Test-WingetAvailable)) { return $null }
    try {
        $v = (winget --version 2>$null)
        if ($LASTEXITCODE -eq 0) { return ($v -replace '^v','').Trim() }
    } catch { }
    return $null
}

# Detects install state for a package (winget-only). Returns Installed, Version
# (installed) and Available (newer version, present only when an upgrade exists).
function Test-AppInstalled {
    param([string]$WingetId)

    if ($WingetId -and (Test-WingetAvailable)) {
        try {
            $out = winget list --id $WingetId -e --accept-source-agreements 2>$null
            if ($LASTEXITCODE -eq 0) {
                $line = $out | Where-Object { $_ -match [regex]::Escape($WingetId) } | Select-Object -First 1
                if ($line) {
                    # Tokens after the package ID are: <installed> [<available>] <source>.
                    $idx    = $line.IndexOf($WingetId)
                    $rest   = $line.Substring($idx + $WingetId.Length).Trim()
                    $tokens = $rest -split '\s+'
                    $ver    = $tokens[0]
                    if ($ver -notmatch '^[\d]') { $ver = $null }
                    $avail = $null
                    if ($tokens.Count -ge 2 -and $tokens[1] -match '^[\d]') { $avail = $tokens[1] }
                    return [PSCustomObject]@{ Installed = $true; Version = $ver; Available = $avail }
                }
            }
        } catch { }
    }

    return [PSCustomObject]@{ Installed = $false; Version = $null; Available = $null }
}

# Downloads a module from the repo into the cache and launches it in its own
# PowerShell window so the module's interactive prompts work normally.
function Invoke-RemoteModule {
    param([string]$ModuleFile, [System.Windows.Forms.Label]$StatusLabel)

    Ensure-WorkDir
    $url       = "$script:BaseRawUrl/$ModuleFile"
    $leaf      = Split-Path $ModuleFile -Leaf
    $localPath = Join-Path $script:WorkDir $leaf

    $StatusLabel.Text = "Downloading $leaf ..."
    $StatusLabel.Refresh()
    Write-Log INFO "Downloading module: $url"

    try {
        Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Log ERROR "Download failed for ${url}: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Could not download module from:`n$url`n`n$($_.Exception.Message)",
            'Download Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        $StatusLabel.Text = 'Ready.'
        return
    }

    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    try {
        Start-Process -FilePath $psExe -ArgumentList @(
            '-NoExit',
            '-ExecutionPolicy', 'Bypass',
            '-File', $localPath
        ) | Out-Null
        $StatusLabel.Text = "Launched: $leaf"
        Write-Log INFO "Launched module: $leaf"
    } catch {
        Write-Log ERROR "Launch failed for ${leaf}: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Could not launch $psExe.`n`n$($_.Exception.Message)",
            'Launch Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        $StatusLabel.Text = 'Ready.'
    }
}

# Shows the modal About dialog with repo and release links.
function Show-AboutDialog {
    $about               = New-Object System.Windows.Forms.Form
    $about.Text          = 'About MSP Application Installation Tool'
    $about.Size          = New-Object System.Drawing.Size(460, 320)
    $about.StartPosition = 'CenterParent'
    $about.FormBorderStyle = 'FixedDialog'
    $about.MinimizeBox   = $false
    $about.MaximizeBox   = $false
    $about.BackColor     = [System.Drawing.Color]::White
    $about.Font          = New-Object System.Drawing.Font('Segoe UI', 9)

    $hdr           = New-Object System.Windows.Forms.Panel
    $hdr.Size      = New-Object System.Drawing.Size(460, 60)
    $hdr.Location  = New-Object System.Drawing.Point(0, 0)
    $hdr.BackColor = $BrandBlue
    $about.Controls.Add($hdr)

    $hdrTitle           = New-Object System.Windows.Forms.Label
    $hdrTitle.Text      = 'MSP Application Installation Tool'
    $hdrTitle.Font      = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
    $hdrTitle.ForeColor = [System.Drawing.Color]::White
    $hdrTitle.Location  = New-Object System.Drawing.Point(18, 8)
    $hdrTitle.Size      = New-Object System.Drawing.Size(420, 26)
    $hdrTitle.BackColor = [System.Drawing.Color]::Transparent
    $hdr.Controls.Add($hdrTitle)

    $hdrVer           = New-Object System.Windows.Forms.Label
    $hdrVer.Text      = "Version $script:Version"
    $hdrVer.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
    $hdrVer.ForeColor = [System.Drawing.Color]::White
    $hdrVer.Location  = New-Object System.Drawing.Point(20, 36)
    $hdrVer.Size      = New-Object System.Drawing.Size(420, 18)
    $hdrVer.BackColor = [System.Drawing.Color]::Transparent
    $hdr.Controls.Add($hdrVer)

    $descLbl          = New-Object System.Windows.Forms.Label
    $descLbl.Text     = "GUI launcher for installing, removing, and updating applications via winget. Fetches each module from GitHub on demand and runs it in its own PowerShell window."
    $descLbl.Font     = New-Object System.Drawing.Font('Segoe UI', 9)
    $descLbl.ForeColor= $BrandTextDark
    $descLbl.Location = New-Object System.Drawing.Point(20, 76)
    $descLbl.Size     = New-Object System.Drawing.Size(415, 44)
    $about.Controls.Add($descLbl)

    $repoCaption          = New-Object System.Windows.Forms.Label
    $repoCaption.Text     = 'Repository:'
    $repoCaption.Font     = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    $repoCaption.ForeColor= $BrandTextDark
    $repoCaption.Location = New-Object System.Drawing.Point(20, 130)
    $repoCaption.Size     = New-Object System.Drawing.Size(100, 18)
    $about.Controls.Add($repoCaption)

    $repoUrl  = "https://github.com/$script:RepoOwner/$script:RepoName"
    $repoLink           = New-Object System.Windows.Forms.LinkLabel
    $repoLink.Text      = $repoUrl
    $repoLink.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
    $repoLink.LinkColor = $BrandBlue
    $repoLink.ActiveLinkColor = $BrandBlueDark
    $repoLink.Location  = New-Object System.Drawing.Point(20, 150)
    $repoLink.Size      = New-Object System.Drawing.Size(415, 18)
    $repoLink.Add_LinkClicked({ Start-Process $repoUrl | Out-Null }.GetNewClosure())
    $about.Controls.Add($repoLink)

    $relCaption          = New-Object System.Windows.Forms.Label
    $relCaption.Text     = 'Releases:'
    $relCaption.Font     = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    $relCaption.ForeColor= $BrandTextDark
    $relCaption.Location = New-Object System.Drawing.Point(20, 175)
    $relCaption.Size     = New-Object System.Drawing.Size(100, 18)
    $about.Controls.Add($relCaption)

    $relUrl   = "https://github.com/$script:RepoOwner/$script:RepoName/releases"
    $relLink           = New-Object System.Windows.Forms.LinkLabel
    $relLink.Text      = $relUrl
    $relLink.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
    $relLink.LinkColor = $BrandBlue
    $relLink.ActiveLinkColor = $BrandBlueDark
    $relLink.Location  = New-Object System.Drawing.Point(20, 195)
    $relLink.Size      = New-Object System.Drawing.Size(415, 18)
    $relLink.Add_LinkClicked({ Start-Process $relUrl | Out-Null }.GetNewClosure())
    $about.Controls.Add($relLink)

    $okBtn           = New-Object System.Windows.Forms.Button
    $okBtn.Text      = 'OK'
    $okBtn.Size      = New-Object System.Drawing.Size(90, 30)
    $okBtn.Location  = New-Object System.Drawing.Point(335, 235)
    $okBtn.BackColor = $BrandBlue
    $okBtn.ForeColor = [System.Drawing.Color]::White
    $okBtn.FlatStyle = 'Flat'
    $okBtn.FlatAppearance.BorderSize = 0
    $okBtn.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $okBtn.Add_Click({ $about.Close() })
    $about.AcceptButton = $okBtn
    $about.Controls.Add($okBtn)

    [void]$about.ShowDialog()
    $about.Dispose()
}

# ---------------------------------------------------------------------------
# FORM
# ---------------------------------------------------------------------------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "MSP Application Installation Tool  -  $script:Version"
$form.Size          = New-Object System.Drawing.Size(1100, 780)
$form.AutoScaleMode = 'Dpi'
$form.StartPosition = 'CenterScreen'
$form.BackColor     = [System.Drawing.Color]::White
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox   = $false
$form.Font          = New-Object System.Drawing.Font('Segoe UI', 9)

# ----- header -----
$header           = New-Object System.Windows.Forms.Panel
$header.Size      = New-Object System.Drawing.Size(1100, 72)
$header.Location  = New-Object System.Drawing.Point(0, 0)
$header.BackColor = $BrandBlue
$form.Controls.Add($header)

$titleLbl          = New-Object System.Windows.Forms.Label
$titleLbl.Text     = 'MSP Application Installation Tool'
$titleLbl.Font     = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$titleLbl.ForeColor= [System.Drawing.Color]::White
$titleLbl.Location = New-Object System.Drawing.Point(20, 10)
$titleLbl.Size     = New-Object System.Drawing.Size(800, 30)
$titleLbl.BackColor= [System.Drawing.Color]::Transparent
$header.Controls.Add($titleLbl)

$subLbl          = New-Object System.Windows.Forms.Label
$subLbl.Text     = 'Install, remove, or update supported applications via winget. Each action opens in its own PowerShell window.'
$subLbl.Font     = New-Object System.Drawing.Font('Segoe UI', 9)
$subLbl.ForeColor= [System.Drawing.Color]::White
$subLbl.Location = New-Object System.Drawing.Point(22, 42)
$subLbl.Size     = New-Object System.Drawing.Size(900, 20)
$subLbl.BackColor= [System.Drawing.Color]::Transparent
$header.Controls.Add($subLbl)

# Forward-declare for closures
$statusLbl = New-Object System.Windows.Forms.Label

# ---------------------------------------------------------------------------
# PREREQUISITE BANNER
# ---------------------------------------------------------------------------
$wingetVer = Get-WingetVersion
$wingetOk  = [bool]$wingetVer

$pill              = New-Object System.Windows.Forms.Panel
$pill.Size         = New-Object System.Drawing.Size(1065, 36)
$pill.Location     = New-Object System.Drawing.Point(15, 85)
$pill.BackColor    = if ($wingetOk) { $BrandGreen } else { $BrandRed }
$form.Controls.Add($pill)

$pillTag               = New-Object System.Windows.Forms.Label
$pillTag.Text          = if ($wingetOk) { 'OK' } else { 'MISSING' }
$pillTag.Font          = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$pillTag.ForeColor     = [System.Drawing.Color]::White
$pillTag.BackColor     = [System.Drawing.Color]::Transparent
$pillTag.Location      = New-Object System.Drawing.Point(12, 8)
$pillTag.Size          = New-Object System.Drawing.Size(80, 20)
$pillTag.TextAlign     = 'MiddleLeft'
$pill.Controls.Add($pillTag)

$pillLbl               = New-Object System.Windows.Forms.Label
$pillLbl.Text          = 'winget'
$pillLbl.Font          = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$pillLbl.ForeColor     = [System.Drawing.Color]::White
$pillLbl.BackColor     = [System.Drawing.Color]::Transparent
$pillLbl.Location      = New-Object System.Drawing.Point(85, 4)
$pillLbl.Size          = New-Object System.Drawing.Size(140, 28)
$pillLbl.TextAlign     = 'MiddleLeft'
$pill.Controls.Add($pillLbl)

$pillDet               = New-Object System.Windows.Forms.Label
$pillDet.Text          = if ($wingetOk) { "v$wingetVer detected" } else { "winget not found. Install 'App Installer' from the Microsoft Store." }
$pillDet.Font          = New-Object System.Drawing.Font('Segoe UI', 9)
$pillDet.ForeColor     = [System.Drawing.Color]::White
$pillDet.BackColor     = [System.Drawing.Color]::Transparent
$pillDet.Location      = New-Object System.Drawing.Point(225, 4)
$pillDet.Size          = New-Object System.Drawing.Size(820, 28)
$pillDet.TextAlign     = 'MiddleLeft'
$pill.Controls.Add($pillDet)

# ---------------------------------------------------------------------------
# APPLICATION LIST
# ---------------------------------------------------------------------------
$list                 = New-Object System.Windows.Forms.FlowLayoutPanel
$list.Location        = New-Object System.Drawing.Point(15, 130)
$list.Size            = New-Object System.Drawing.Size(1065, 545)
$list.FlowDirection   = 'TopDown'
$list.WrapContents    = $false
$list.AutoScroll      = $true
$list.BackColor       = [System.Drawing.Color]::White
$form.Controls.Add($list)

# Builds a full-width category section header band for the grouped list.
function New-CategoryHeader {
    param ([string]$Title, [int]$Count)

    $hdr           = New-Object System.Windows.Forms.Panel
    $hdr.Size      = New-Object System.Drawing.Size(1040, 30)
    $hdr.Margin    = New-Object System.Windows.Forms.Padding(0, 6, 0, 4)
    $hdr.BackColor = $BrandBlueDark

    $hdrLbl           = New-Object System.Windows.Forms.Label
    $hdrLbl.Text      = "$($Title.ToUpper())   ($Count)"
    $hdrLbl.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $hdrLbl.ForeColor = [System.Drawing.Color]::White
    $hdrLbl.BackColor = [System.Drawing.Color]::Transparent
    $hdrLbl.Location  = New-Object System.Drawing.Point(12, 4)
    $hdrLbl.Size      = New-Object System.Drawing.Size(1000, 22)
    $hdrLbl.TextAlign = 'MiddleLeft'
    $hdr.Controls.Add($hdrLbl)

    return $hdr
}

# Builds one application card (status chip, version, update notice, action buttons).
function New-AppCard {
    param ([PSCustomObject]$App, [System.Windows.Forms.Label]$StatusLabel)

    $state = Test-AppInstalled -WingetId $App.WingetId

    $card             = New-Object System.Windows.Forms.Panel
    $card.Size        = New-Object System.Drawing.Size(1040, 92)
    $card.Margin      = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
    $card.BackColor   = $BrandBlueLight
    $card.BorderStyle = 'FixedSingle'

    # Status chip (top-left)
    $chip              = New-Object System.Windows.Forms.Panel
    $chip.Size         = New-Object System.Drawing.Size(110, 22)
    $chip.Location     = New-Object System.Drawing.Point(12, 8)
    $chip.BackColor    = if ($state.Installed) { $BrandGreen } else { $BrandTextMuted }
    $card.Controls.Add($chip)

    $chipLbl           = New-Object System.Windows.Forms.Label
    $chipLbl.Text      = if ($state.Installed) { 'INSTALLED' } else { 'NOT INSTALLED' }
    $chipLbl.Font      = New-Object System.Drawing.Font('Segoe UI', 8, [System.Drawing.FontStyle]::Bold)
    $chipLbl.ForeColor = [System.Drawing.Color]::White
    $chipLbl.BackColor = [System.Drawing.Color]::Transparent
    $chipLbl.Location  = New-Object System.Drawing.Point(0, 0)
    $chipLbl.Size      = New-Object System.Drawing.Size(110, 22)
    $chipLbl.TextAlign = 'MiddleCenter'
    $chip.Controls.Add($chipLbl)

    # Installed version (next to chip)
    $verLbl           = New-Object System.Windows.Forms.Label
    $verLbl.Text      = if ($state.Installed -and $state.Version) { "v$($state.Version)" } else { '' }
    $verLbl.Font      = New-Object System.Drawing.Font('Segoe UI', 8)
    $verLbl.ForeColor = $BrandTextMuted
    $verLbl.Location  = New-Object System.Drawing.Point(128, 10)
    $verLbl.Size      = New-Object System.Drawing.Size(120, 18)
    $verLbl.BackColor = [System.Drawing.Color]::Transparent
    $card.Controls.Add($verLbl)

    # Update-available notice (shown only when winget reports a newer version)
    $updateAvailable  = [bool]($state.Installed -and $state.Available)
    $updLbl           = New-Object System.Windows.Forms.Label
    $updLbl.Text      = if ($updateAvailable) { "Update Available v$($state.Available)" } else { '' }
    $updLbl.Font      = New-Object System.Drawing.Font('Segoe UI', 8, [System.Drawing.FontStyle]::Bold)
    $updLbl.ForeColor = $BrandBlueDark
    $updLbl.Location  = New-Object System.Drawing.Point(250, 10)
    $updLbl.Size      = New-Object System.Drawing.Size(260, 18)
    $updLbl.BackColor = [System.Drawing.Color]::Transparent
    $card.Controls.Add($updLbl)

    $titleLbl2          = New-Object System.Windows.Forms.Label
    $titleLbl2.Text     = "$($App.Name)"
    $titleLbl2.Font     = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $titleLbl2.ForeColor= $BrandTextDark
    $titleLbl2.Location = New-Object System.Drawing.Point(12, 32)
    $titleLbl2.Size     = New-Object System.Drawing.Size(720, 22)
    $titleLbl2.BackColor= [System.Drawing.Color]::Transparent
    $card.Controls.Add($titleLbl2)

    $descLbl          = New-Object System.Windows.Forms.Label
    $descLbl.Text     = "$($App.Description)   (winget: $($App.WingetId))"
    $descLbl.Font     = New-Object System.Drawing.Font('Segoe UI', 9)
    $descLbl.ForeColor= $BrandTextDark
    $descLbl.Location = New-Object System.Drawing.Point(12, 58)
    $descLbl.Size     = New-Object System.Drawing.Size(720, 28)
    $descLbl.BackColor= [System.Drawing.Color]::Transparent
    $card.Controls.Add($descLbl)

    # Action buttons. Install and Uninstall share the rightmost slot (only one
    # shows, by install state). The Update button sits to its left and appears
    # only when winget reports a newer version is available.

    # Update button (visible only when an update is available)
    $updateBtn           = New-Object System.Windows.Forms.Button
    $updateBtn.Text      = 'Update'
    $updateBtn.Size      = New-Object System.Drawing.Size(140, 36)
    $updateBtn.Location  = New-Object System.Drawing.Point(745, 28)
    $updateBtn.BackColor = $BrandBlueDark
    $updateBtn.ForeColor = [System.Drawing.Color]::White
    $updateBtn.FlatStyle = 'Flat'
    $updateBtn.FlatAppearance.BorderSize = 0
    $updateBtn.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $updateBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $updateBtn.Visible   = $updateAvailable
    $localUpgradeFile     = $App.UpgradeModule
    $localStatusUp        = $StatusLabel
    $updateBtn.Add_Click({ Invoke-RemoteModule -ModuleFile $localUpgradeFile -StatusLabel $localStatusUp }.GetNewClosure())
    $card.Controls.Add($updateBtn)

    # Install button (visible only when NOT installed)
    $installBtn           = New-Object System.Windows.Forms.Button
    $installBtn.Text      = 'Install'
    $installBtn.Size      = New-Object System.Drawing.Size(140, 36)
    $installBtn.Location  = New-Object System.Drawing.Point(890, 28)
    $installBtn.BackColor = $BrandBlue
    $installBtn.ForeColor = [System.Drawing.Color]::White
    $installBtn.FlatStyle = 'Flat'
    $installBtn.FlatAppearance.BorderSize = 0
    $installBtn.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $installBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $installBtn.Visible   = -not $state.Installed
    $localInstallFile     = $App.InstallModule
    $localStatusI         = $StatusLabel
    $installBtn.Add_Click({ Invoke-RemoteModule -ModuleFile $localInstallFile -StatusLabel $localStatusI }.GetNewClosure())
    $card.Controls.Add($installBtn)

    # Uninstall button (visible only when installed)
    $uninstallBtn           = New-Object System.Windows.Forms.Button
    $uninstallBtn.Text      = 'Uninstall'
    $uninstallBtn.Size      = New-Object System.Drawing.Size(140, 36)
    $uninstallBtn.Location  = New-Object System.Drawing.Point(890, 28)
    $uninstallBtn.BackColor = $BrandRed
    $uninstallBtn.ForeColor = [System.Drawing.Color]::White
    $uninstallBtn.FlatStyle = 'Flat'
    $uninstallBtn.FlatAppearance.BorderSize = 0
    $uninstallBtn.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $uninstallBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $uninstallBtn.Visible   = $state.Installed
    $localUninstallFile     = $App.UninstallModule
    $localStatusU           = $StatusLabel
    $uninstallBtn.Add_Click({ Invoke-RemoteModule -ModuleFile $localUninstallFile -StatusLabel $localStatusU }.GetNewClosure())
    $card.Controls.Add($uninstallBtn)

    return $card
}

# Rebuilds the list: for each category (in order), a header band then its cards.
function Update-AppList {
    $list.Controls.Clear()
    foreach ($cat in $script:Categories) {
        $inCat = @($script:Apps | Where-Object { $_.Category -eq $cat })
        if ($inCat.Count -eq 0) { continue }
        $list.Controls.Add((New-CategoryHeader -Title $cat -Count $inCat.Count))
        foreach ($app in $inCat) {
            $list.Controls.Add((New-AppCard -App $app -StatusLabel $statusLbl))
        }
    }
}

Update-AppList

# ---------------------------------------------------------------------------
# FOOTER
# ---------------------------------------------------------------------------
$statusLbl.Text      = 'Ready.'
$statusLbl.Location  = New-Object System.Drawing.Point(18, 698)
$statusLbl.Size      = New-Object System.Drawing.Size(580, 22)
$statusLbl.TextAlign = 'MiddleLeft'
$statusLbl.ForeColor = $BrandTextMuted
$statusLbl.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
$form.Controls.Add($statusLbl)

$refreshBtn           = New-Object System.Windows.Forms.Button
$refreshBtn.Text      = 'Refresh'
$refreshBtn.Size      = New-Object System.Drawing.Size(100, 32)
$refreshBtn.Location  = New-Object System.Drawing.Point(610, 693)
$refreshBtn.FlatStyle = 'Flat'
$refreshBtn.BackColor = [System.Drawing.Color]::White
$refreshBtn.ForeColor = $BrandTextDark
$refreshBtn.Add_Click({
    Update-AppList
    $statusLbl.Text = 'State refreshed.'
    Write-Log INFO 'App list refreshed.'
})
$form.Controls.Add($refreshBtn)

$aboutBtn           = New-Object System.Windows.Forms.Button
$aboutBtn.Text      = 'About'
$aboutBtn.Size      = New-Object System.Drawing.Size(90, 32)
$aboutBtn.Location  = New-Object System.Drawing.Point(720, 693)
$aboutBtn.FlatStyle = 'Flat'
$aboutBtn.BackColor = [System.Drawing.Color]::White
$aboutBtn.ForeColor = $BrandTextDark
$aboutBtn.Add_Click({ Show-AboutDialog })
$form.Controls.Add($aboutBtn)

$closeBtn           = New-Object System.Windows.Forms.Button
$closeBtn.Text      = 'Close'
$closeBtn.Size      = New-Object System.Drawing.Size(90, 32)
$closeBtn.Location  = New-Object System.Drawing.Point(980, 693)
$closeBtn.FlatStyle = 'Flat'
$closeBtn.BackColor = [System.Drawing.Color]::White
$closeBtn.ForeColor = $BrandTextDark
$closeBtn.Add_Click({ $form.Close() })
$form.Controls.Add($closeBtn)

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
Show-Banner
Write-Log INFO "Launcher started (winget: $(if ($wingetOk) { "v$wingetVer" } else { 'missing' }))."
[void]$form.ShowDialog()
$form.Dispose()
Write-Log INFO 'Launcher closed.'
