# =========================================================================
# SCRIPT 5.0: IIS-Base-Provisioning.ps1 (Solo Infrastruttura Base)
# =========================================================================

Start-Transcript -Path "C:\Windows\Temp\Log_IIS_Provisioning.txt" -Append
Set-TimeZone -Id "W. Europe Standard Time" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------
# FASE 1: INSTALLAZIONE E AVVIO IIS
# ---------------------------------------------------------------------
Write-Host "Controllo presenza IIS..."
if (-not (Get-Service -Name W3SVC -ErrorAction SilentlyContinue)) {
    Write-Host "IIS non trovato. Installazione in corso..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-ManagementConsole -All -NoRestart | Out-Null
}

Set-Service W3SVC -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service W3SVC -ErrorAction SilentlyContinue

Import-Module WebAdministration

# ---------------------------------------------------------------------
# FASE 2: PULIZIA E PREPARAZIONE
# ---------------------------------------------------------------------
# Rimuoviamo il "Default Web Site" di Windows per evitare conflitti sulla porta 80
if (Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue) {
    Write-Host "Rimozione sito predefinito..." -ForegroundColor Yellow
    Remove-Website -Name "Default Web Site"
}

# Assicuriamoci che il firewall sia aperto sia per HTTP che per HTTPS
if (!(Get-NetFirewallRule -DisplayName "IIS Web Traffic (80/443)" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "IIS Web Traffic (80/443)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80,443 | Out-Null
}

Write-Host "IIS Installato. Server pronto per essere configurato dagli utenti." -ForegroundColor Green
Stop-Transcript