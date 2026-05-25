# =========================================================================
# SCRIPT WAC: Automazione Installazione Windows Admin Center con SSL Dominio
# =========================================================================

Start-Transcript -Path "C:\Log_Automazione_WAC.txt" -Append
Set-TimeZone -Id "W. Europe Standard Time" -ErrorAction SilentlyContinue

Write-Host "Inizio configurazione Windows Admin Center (WAC)..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# FASE 1: ATTESA E RECUPERO CERTIFICATO DI DOMINIO
# ---------------------------------------------------------------------
Write-Host "Attesa eventuale auto-enrollment del certificato..."
Start-Sleep -Seconds 10

$fqdn = [System.Net.Dns]::GetHostEntry($env:computername).HostName
Write-Host "Cerco certificato per $fqdn emesso da HCLAB02-CA..."

$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { 
    $_.Subject -like "*CN=$fqdn*" -and $_.Issuer -like "*HCLAB02-CA*" -and $_.NotAfter -gt (Get-Date) 
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $cert) {
    Write-Host "ERRORE CRITICO: Nessun certificato di dominio trovato per questa macchina. Assicurati che l'auto-enrollment della CA sia attivo." -ForegroundColor Red
    Stop-Transcript
    exit
}

$tp = $cert.Thumbprint
Write-Host "Certificato trovato! Thumbprint: $tp" -ForegroundColor Green

# ---------------------------------------------------------------------
# FASE 2: DOWNLOAD DI WINDOWS ADMIN CENTER (Aggiornato per EXE)
# ---------------------------------------------------------------------
$wacInstaller = "C:\WindowsAdminCenter.exe"
if (-not (Test-Path $wacInstaller)) {
    Write-Host "Download di Windows Admin Center in corso..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://aka.ms/WACDownload" -OutFile $wacInstaller -UseBasicParsing
    Write-Host "Download completato." -ForegroundColor Green
} else {
    Write-Host "Installer di WAC gia' presente in C:\" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# FASE 3: INSTALLAZIONE SILENZIOSA CON INIEZIONE CERTIFICATO
# ---------------------------------------------------------------------
Write-Host "Installazione di WAC sulla porta 443 in corso. Potrebbe richiedere qualche minuto..." -ForegroundColor Yellow

# Argomenti per l'EXE: Installa sulla 443 in modo silenzioso, usa il thumbprint del certificato
$exeArgs = "/quiet SME_PORT=443 SME_THUMBPRINT=`"$tp`" SSL_CERTIFICATE_OPTION=installed"

$process = Start-Process -FilePath $wacInstaller -ArgumentList $exeArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0) {
    Write-Host "Windows Admin Center installato con successo con il certificato HCLAB02!" -ForegroundColor Green
} else {
    Write-Host "Errore durante l'installazione. Codice di uscita: $($process.ExitCode)" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# FASE 4: APERTURA FIREWALL
# ---------------------------------------------------------------------
Write-Host "Verifica regole Firewall..."
if (!(Get-NetFirewallRule -DisplayName "WAC HTTPS Auto-Open" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "WAC HTTPS Auto-Open" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443 | Out-Null
    Write-Host "Firewall configurato." -ForegroundColor Green
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "WAC e' pronto! Dal tuo PC fisico apri Edge o Chrome e vai su:" -ForegroundColor White
Write-Host "https://$fqdn" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

Stop-Transcript