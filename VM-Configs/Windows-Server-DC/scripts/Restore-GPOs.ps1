# =================================================================
# Script: Restore-GPOs.ps1
# Descrizione: Ripristino massivo delle GPO da un backup esistente
# =================================================================

$Dominio = "hclab02.local"
$BackupPath = "C:\Users\Hao Chen\Documents\HCLAB-Management\VM-Configs\Windows-Server-HC02\GPO_Backups"

Write-Host "Inizio procedura di DISASTER RECOVERY per le GPO..." -ForegroundColor Red

if (-not (Test-Path $BackupPath)) {
    Write-Host "ERRORE: Cartella di backup non trovata in $BackupPath" -ForegroundColor Red
    exit
}

Write-Host "Ripristino delle policy nel dominio $Dominio in corso..." -ForegroundColor Yellow
Restore-GPO -All -Path $BackupPath -Domain $Dominio

Write-Host "Ripristino completato! Assicurati di ricollegare (Link) le GPO alle relative OU." -ForegroundColor Green
