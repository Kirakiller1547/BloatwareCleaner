#Requires -Version 5.1
<#
.SYNOPSIS
    Bulk-Deinstallierer / Bloatware-Cleaner Windows 10/11
.DESCRIPTION
    Listed installed programs
.NOTES
   run with:  powershell -ExecutionPolicy Bypass -File .\BloatwareCleaner.ps1
#>





trap {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host "FEHLER: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Zeile: $($_.InvocationInfo.ScriptLineNumber)  Befehl: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

# ------------------------------------------------------------
# 0b) Selbst-Elevation: Neustart mit Admin-Rechten falls noetig
# ------------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "Admin-Rechte wurden abgelehnt oder der Start ist fehlgeschlagen." -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Druecke Enter zum Beenden"
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# 1) Known Bloatware
# ------------------------------------------------------------
$BloatwarePatterns = @(
    "McAfee", "Norton", "WildTangent", "Candy Crush", "Xbox Game Bar Assist",
    "Disney Magic Kingdoms", "Booking.com", "Netflix", "Spotify Music",
    "Dropbox Promotion", "CyberLink", "PC Accelerate", "Registry Cleaner",
    "Driver Booster", "Coupon", "Toolbar", "PowerDVD", "Skype for Business",
    "OneDrive", "Edge", "Microsoft Edge", "Ccleaner"
)

# ------------------------------------------------------------
# 2) Installed Programs
# ------------------------------------------------------------
function Get-InstalledPrograms {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $results = foreach ($path in $paths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne "" -and -not $_.SystemComponent } |
            Select-Object `
                @{N='Name';E={$_.DisplayName}},
                @{N='Publisher';E={$_.Publisher}},
                @{N='Version';E={$_.DisplayVersion}},
                @{N='SizeMB';E={ if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1024, 1) } else { $null } }},
                @{N='InstallDate';E={
                    if ($_.InstallDate -match '^\d{8}$') {
                        [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null).ToString('yyyy-MM-dd')
                    } else { "" }
                }},
                @{N='UninstallString';E={$_.UninstallString}},
                @{N='QuietUninstallString';E={$_.QuietUninstallString}},
                @{N='PSPath';E={$_.PSPath}}
    }

    $results | Sort-Object Name -Unique
}

# ------------------------------------------------------------
# 3) Uninstall Single Didget
# ------------------------------------------------------------
function Uninstall-Program {
    param($Program, [ref]$LogBox)

    $cmd = if ($Program.QuietUninstallString) { $Program.QuietUninstallString } else { $Program.UninstallString }
    if (-not $cmd) {
        $LogBox.Value.AppendText("  [FEHLER] Kein Uninstall-Befehl gefunden fuer '$($Program.Name)'`r`n")
        return $false
    }

    try {
        if ($cmd -match '^"?msiexec') {
            # MSI-Pakete: clean uninstall background
            $guidMatch = [regex]::Match($cmd, '\{[0-9A-Fa-f\-]+\}')
            if ($guidMatch.Success) {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($guidMatch.Value) /qn /norestart" -Wait -ErrorAction Stop
            } else {
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`" /qn" -Wait -ErrorAction Stop
            }
        } else {
            # EXE based uninstaller 
            $exePath = $cmd
            $args = ""
            if ($cmd -match '^"([^"]+)"\s*(.*)$') {
                $exePath = $matches[1]
                $args = $matches[2]
            }
            if (-not $Program.QuietUninstallString -and $args -notmatch '/S|/silent|/quiet|/qn') {
                $args = "$args /S"  
            }
            Start-Process -FilePath $exePath -ArgumentList $args -Wait -ErrorAction Stop
        }
        $LogBox.Value.AppendText("  [OK] '$($Program.Name)' deinstalliert`r`n")
        return $true
    } catch {
        $LogBox.Value.AppendText("  [FEHLER] '$($Program.Name)': $($_.Exception.Message)`r`n")
        return $false
    }
}

# ------------------------------------------------------------
# 4) APPLICATION GUI
# ------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Bloatware Cleaner"
$form.Size = New-Object System.Drawing.Size(920, 640)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(760, 480)

# -- Suchfeld --
$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "Suche:"
$searchLabel.Location = New-Object System.Drawing.Point(10, 15)
$searchLabel.AutoSize = $true
$form.Controls.Add($searchLabel)

$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(60, 12)
$searchBox.Size = New-Object System.Drawing.Size(250, 20)
$searchBox.Anchor = 'Top,Left'
$form.Controls.Add($searchBox)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Aktualisieren"
$btnRefresh.Location = New-Object System.Drawing.Point(320, 10)
$btnRefresh.Size = New-Object System.Drawing.Size(100, 25)
$form.Controls.Add($btnRefresh)

$btnMarkBloat = New-Object System.Windows.Forms.Button
$btnMarkBloat.Text = "Bekannte Bloatware markieren"
$btnMarkBloat.Location = New-Object System.Drawing.Point(430, 10)
$btnMarkBloat.Size = New-Object System.Drawing.Size(190, 25)
$form.Controls.Add($btnMarkBloat)

$btnExportCsv = New-Object System.Windows.Forms.Button
$btnExportCsv.Text = "Liste als CSV exportieren"
$btnExportCsv.Location = New-Object System.Drawing.Point(630, 10)
$btnExportCsv.Size = New-Object System.Drawing.Size(170, 25)
$btnExportCsv.Anchor = 'Top,Right'
$form.Controls.Add($btnExportCsv)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Lade..."
$statusLabel.Location = New-Object System.Drawing.Point(810, 15)
$statusLabel.AutoSize = $true
$statusLabel.Anchor = 'Top,Right'
$form.Controls.Add($statusLabel)

# -- DataGridView --
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10, 45)
$grid.Size = New-Object System.Drawing.Size(890, 420)
$grid.Anchor = 'Top,Bottom,Left,Right'
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.ReadOnly = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $true
$grid.AutoSizeColumnsMode = 'Fill'
$grid.RowHeadersVisible = $false

$colCheck = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colCheck.Name = "Selected"
$colCheck.HeaderText = ""
$colCheck.Width = 30
$colCheck.FillWeight = 5
$grid.Columns.Add($colCheck) | Out-Null

foreach ($c in @(
        @{N='Name'; H='Name'; W=30},
        @{N='Publisher'; H='Hersteller'; W=18},
        @{N='Version'; H='Version'; W=10},
        @{N='SizeMB'; H='Groesse (MB)'; W=10},
        @{N='InstallDate'; H='Installiert am'; W=12},
        @{N='Bloat'; H='Bloatware?'; W=10}
    )) {
    $col = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $col.Name = $c.N
    $col.HeaderText = $c.H
    $col.FillWeight = $c.W
    $col.ReadOnly = $true
    $grid.Columns.Add($col) | Out-Null
}
$form.Controls.Add($grid)

# -- Action Buttons --
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Alle auswaehlen"
$btnSelectAll.Location = New-Object System.Drawing.Point(10, 475)
$btnSelectAll.Size = New-Object System.Drawing.Size(120, 28)
$btnSelectAll.Anchor = 'Bottom,Left'
$form.Controls.Add($btnSelectAll)

$btnSelectNone = New-Object System.Windows.Forms.Button
$btnSelectNone.Text = "Auswahl aufheben"
$btnSelectNone.Location = New-Object System.Drawing.Point(140, 475)
$btnSelectNone.Size = New-Object System.Drawing.Size(120, 28)
$btnSelectNone.Anchor = 'Bottom,Left'
$form.Controls.Add($btnSelectNone)

$btnUninstall = New-Object System.Windows.Forms.Button
$btnUninstall.Text = "Ausgewaehlte deinstallieren"
$btnUninstall.Location = New-Object System.Drawing.Point(700, 475)
$btnUninstall.Size = New-Object System.Drawing.Size(200, 32)
$btnUninstall.Anchor = 'Bottom,Right'
$btnUninstall.BackColor = [System.Drawing.Color]::IndianRed
$btnUninstall.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnUninstall)

# -- Log-Box --
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(10, 515)
$logBox.Size = New-Object System.Drawing.Size(890, 85)
$logBox.Anchor = 'Bottom,Left,Right'
$logBox.Multiline = $true
$logBox.ScrollBars = 'Vertical'
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::Black
$logBox.ForeColor = [System.Drawing.Color]::LightGreen
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($logBox)

# ------------------------------------------------------------
# 5) Load data
# ------------------------------------------------------------
$allPrograms = @()

function Load-Grid {
    param([string]$filter = "")

    $grid.Rows.Clear()
    $statusLabel.Text = "Lade..."
    $form.Refresh()

    if ($allPrograms.Count -eq 0) {
        $allPrograms = Get-InstalledPrograms
    }

    $filtered = if ($filter) {
        $allPrograms | Where-Object { $_.Name -like "*$filter*" -or $_.Publisher -like "*$filter*" }
    } else {
        $allPrograms
    }

    foreach ($p in $filtered) {
        $isBloat = $false
        foreach ($pattern in $BloatwarePatterns) {
            if ($p.Name -like "*$pattern*") { $isBloat = $true; break }
        }
        $rowIndex = $grid.Rows.Add($false, $p.Name, $p.Publisher, $p.Version, $p.SizeMB, $p.InstallDate, $(if ($isBloat) { "ja" } else { "" }))
        $grid.Rows[$rowIndex].Tag = $p
        if ($isBloat) {
            $grid.Rows[$rowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::MistyRose
        }
    }
    $statusLabel.Text = "$($filtered.Count) Programme"
}

# Initiales
$allPrograms = Get-InstalledPrograms
Load-Grid

# ------------------------------------------------------------
# 6) Event-Handler
# ------------------------------------------------------------
$searchBox.Add_TextChanged({ Load-Grid -filter $searchBox.Text })

$btnRefresh.Add_Click({
    $allPrograms = Get-InstalledPrograms
    Load-Grid -filter $searchBox.Text
})

$btnSelectAll.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells["Selected"].Value = $true }
})

$btnSelectNone.Add_Click({
    foreach ($row in $grid.Rows) { $row.Cells["Selected"].Value = $false }
})

$btnMarkBloat.Add_Click({
    foreach ($row in $grid.Rows) {
        if ($row.Cells["Bloat"].Value -eq "ja") {
            $row.Cells["Selected"].Value = $true
        }
    }
})

$btnExportCsv.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "CSV-Datei (*.csv)|*.csv"
    $sfd.FileName = "installierte_programme.csv"
    if ($sfd.ShowDialog() -eq 'OK') {
        $allPrograms | Select-Object Name, Publisher, Version, SizeMB, InstallDate |
            Export-Csv -Path $sfd.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Liste exportiert nach:`n$($sfd.FileName)", "Export erfolgreich") | Out-Null
    }
})

$btnUninstall.Add_Click({
    $selectedRows = $grid.Rows | Where-Object { $_.Cells["Selected"].Value -eq $true }
    if ($selectedRows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Keine Programme ausgewaehlt.", "Hinweis") | Out-Null
        return
    }

    $names = ($selectedRows | ForEach-Object { $_.Tag.Name }) -join "`r`n"
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Folgende Programme wirklich deinstallieren?`r`n`r`n$names",
        "Deinstallation bestaetigen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne 'Yes') { return }

    $btnUninstall.Enabled = $false
    $logBox.Clear()
    $logBox.AppendText("Starte Deinstallation von $($selectedRows.Count) Programm(en)...`r`n")

    $successCount = 0
    foreach ($row in $selectedRows) {
        $program = $row.Tag
        $logBox.AppendText("-> $($program.Name)`r`n")
        $form.Refresh()
        $ok = Uninstall-Program -Program $program -LogBox ([ref]$logBox)
        if ($ok) { $successCount++ }
    }

    $logBox.AppendText("`r`nFertig: $successCount von $($selectedRows.Count) erfolgreich deinstalliert.`r`n")
    $btnUninstall.Enabled = $true

    # refresh list 
    $allPrograms = Get-InstalledPrograms
    Load-Grid -filter $searchBox.Text
})

# ------------------------------------------------------------
# 7) Start
# ------------------------------------------------------------
[void]$form.ShowDialog()
