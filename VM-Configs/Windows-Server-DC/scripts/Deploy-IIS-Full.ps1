# =========================================================================
# SCRIPT 4.4: IIS-SSL-Maintenance.ps1 (Aesthetic Update & Timestamp)
# =========================================================================

Start-Transcript -Path "C:\Log_Automazione_SSL.txt" -Append

Set-TimeZone -Id "W. Europe Standard Time" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------
# FASE 0: INSTALLAZIONE E AVVIO IIS
# ---------------------------------------------------------------------
Write-Host "Controllo presenza IIS..."
if (-not (Get-Service -Name W3SVC -ErrorAction SilentlyContinue)) {
    Write-Host "IIS non trovato. Installazione in corso..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-ManagementConsole, IIS-HttpRedirect -All -NoRestart | Out-Null
}

Set-Service W3SVC -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service W3SVC -ErrorAction SilentlyContinue

Import-Module WebAdministration

# ---------------------------------------------------------------------
# FASE 1: SOSTITUZIONE SITO DI DEFAULT CON PORTALE DOMINIO
# ---------------------------------------------------------------------
$newName = "HCLAB02-Portal"
$rootPath = "C:\inetpub\wwwroot"

if (!(Test-Path $rootPath)) { New-Item -ItemType Directory -Force -Path $rootPath | Out-Null }

if (Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue) {
    Remove-Website -Name "Default Web Site"
}

if (!(Get-Website -Name $newName -ErrorAction SilentlyContinue)) {
    New-Website -Name $newName -PhysicalPath $rootPath -Force | Out-Null
}

# --- NUOVA GRAFICA HTML 4.4 ---
$provisionDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

$htmlContent = @"
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>HCLAB02 - Portale Istituzionale</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #e9ecef 0%, #dee2e6 100%); color: #212529; text-align: center; padding-top: 60px; min-height: 100vh; margin: 0; }
        .card { background: white; padding: 50px; border-radius: 15px; box-shadow: 0 15px 30px rgba(0,0,0,0.15); display: inline-block; border-top: 6px solid #0056b3; max-width: 600px; }
        h1 { color: #0056b3; margin-bottom: 5px; font-size: 2.5em; text-transform: uppercase; letter-spacing: 2px;}
        .domain { color: #28a745; font-weight: bold; font-size: 1.3em; margin-bottom: 25px; }
        .info { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 5px solid #0056b3; text-align: left; margin-top: 25px; line-height: 1.6; }
        .badge { background-color: #28a745; color: white; padding: 5px 10px; border-radius: 20px; font-size: 0.9em; font-weight: bold; margin-left: 10px; }
        .footer { margin-top: 30px; font-size: 0.85em; color: #6c757d; border-top: 1px solid #eee; padding-top: 15px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>$env:computername</h1>
        <div class="domain">Membro del Dominio HCLAB02.LOCAL</div>
        <p>Questo nodo Web e' stato configurato e aggiornato tramite <strong>Zero-Touch Provisioning</strong>.</p>
        <div class="info">
            <strong>Stato Sicurezza:</strong> <span class="badge">SSL Attivo ✓</span><br>
            <strong>Ruolo Server:</strong> IIS Web Server Standard<br>
            <strong>Ultimo Aggiornamento:</strong> $provisionDate
        </div>
        <div class="footer">
            Automazione gestita da HCLAB02 Group Policy
        </div>
    </div>
</body>
</html>
"@
Set-Content -Path "$rootPath\index.html" -Value $htmlContent -Force

# ---------------------------------------------------------------------
# FASE 2: CONFIGURAZIONE SSL E VIGILE URBANO
# ---------------------------------------------------------------------
Write-Host "Attesa per emissione certificato..."
Start-Sleep -Seconds 10

$fqdn = [System.Net.Dns]::GetHostEntry($env:computername).HostName
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { 
    $_.Subject -like "*CN=$fqdn*" -and $_.Issuer -like "*HCLAB02-CA*" -and $_.NotAfter -gt (Get-Date) 
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if ($cert) {
    $tp = $cert.Thumbprint
    $redirectSite = "HTTP-to-HTTPS-Redirector"
    
    $sites = Get-Website | Where-Object { $_.Name -ne $redirectSite }
    
    foreach ($site in $sites) {
        $siteName = $site.Name
        Set-WebConfigurationProperty -filter /system.webServer/httpRedirect -name enabled -value $false -PSPath "IIS:\Sites\$siteName" -ErrorAction SilentlyContinue
        
        Get-WebBinding -Name $siteName -Port 80 -Protocol "http" -ErrorAction SilentlyContinue | Remove-WebBinding
        if (!(Get-WebBinding -Name $siteName -Port 443 -Protocol "https" -ErrorAction SilentlyContinue)) {
            New-WebBinding -Name $siteName -IPAddress "*" -Port 443 -Protocol "https"
        }
        
        (Get-WebBinding -Name $siteName -Port 443 -Protocol "https").AddSslCertificate($tp, "My")
        Start-Website -Name $siteName -ErrorAction SilentlyContinue
    }

    $dummyPath = "C:\inetpub\redirect"
    if (!(Test-Path $dummyPath)) { New-Item -ItemType Directory -Force -Path $dummyPath | Out-Null }
    if (!(Get-Website -Name $redirectSite -ErrorAction SilentlyContinue)) {
        New-Website -Name $redirectSite -PhysicalPath $dummyPath -Port 80 -Force | Out-Null
    }
    
    Start-Website -Name $redirectSite -ErrorAction SilentlyContinue
    Set-WebConfigurationProperty -filter /system.webServer/httpRedirect -name enabled -value $true -PSPath "IIS:\Sites\$redirectSite"
    Set-WebConfigurationProperty -filter /system.webServer/httpRedirect -name destination -value "https://$fqdn" -PSPath "IIS:\Sites\$redirectSite"
}

if (!(Get-NetFirewallRule -DisplayName "IIS HTTPS Auto-Open" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "IIS HTTPS Auto-Open" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443 | Out-Null
}

Stop-Transcript