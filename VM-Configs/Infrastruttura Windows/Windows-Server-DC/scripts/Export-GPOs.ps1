# =================================================================
# Script: Export-GPOs.ps1
# Descrizione: Backup massivo di tutte le GPO e generazione report
# =================================================================

$Dominio = "hclab02.local"
$BasePath = "C:\Users\Hao Chen\Documents\HCLAB-Management\VM-Configs\Windows-Server-HC02"
$BackupPath = "$BasePath\GPO_Backups"
$ReportPath = "$BasePath\GPO_Reports"

Write-Host "Inizio esportazione delle Group Policy Object (GPO)..." -ForegroundColor Cyan

if (-not (Test-Path $BackupPath)) { New-Item -ItemType Directory -Path $BackupPath | Out-Null }
if (-not (Test-Path $ReportPath)) { New-Item -ItemType Directory -Path $ReportPath | Out-Null }

Write-Host "Esecuzione backup dei dati grezzi..." -ForegroundColor Yellow
Backup-Gpo -All -Path $BackupPath -Domain $Dominio | Out-Null

Write-Host "Generazione del report HTML leggibile..." -ForegroundColor Yellow
Get-GPOReport -All -Domain $Dominio -ReportType HTML -Path "$ReportPath\GPO_Domain_Report.html"

Write-Host "Esportazione completata con successo! I file sono pronti per Git." -ForegroundColor Green
