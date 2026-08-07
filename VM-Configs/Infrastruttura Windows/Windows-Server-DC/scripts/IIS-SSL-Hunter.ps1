# =========================================================================
# SCRIPT: IIS-SSL-Hunter.ps1 (Forza SSL su tutte le porte personalizzate)
# =========================================================================

Write-Host "--- Avvio caccia ai siti non sicuri... ---" -ForegroundColor Cyan
Import-Module WebAdministration

$fqdn = [System.Net.Dns]::GetHostEntry($env:computername).HostName
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { 
    $_.Subject -like "*CN=$fqdn*" -and $_.Issuer -like "*HCLAB02-CA*" -and $_.NotAfter -gt (Get-Date) 
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $cert) {
    Write-Host "Nessun certificato CA valido trovato per questa macchina." -ForegroundColor Red
    exit
}

$tp = $cert.Thumbprint

# 1. Escludiamo i siti che gestiamo già con l'altro script
$sitiEsclusi = @("HCLAB02-Portal", "HTTP-to-HTTPS-Redirector", "Default Web Site")

# 2. Peschiamo tutti gli altri siti "creati a mano" dagli utenti/sviluppatori
$sitiSconosciuti = Get-Website | Where-Object { $_.Name -notin $sitiEsclusi }

if ($sitiSconosciuti.Count -eq 0) {
    Write-Host "Nessun sito aggiuntivo rilevato. Il server e' pulito." -ForegroundColor Green
    exit
}

foreach ($site in $sitiSconosciuti) {
    $siteName = $site.Name
    Write-Host "Analisi del sito: $siteName" -ForegroundColor Yellow
    
    # Prendiamo tutti i binding (le porte) associate a questo sito
    $bindings = Get-WebBinding -Name $siteName
    
    foreach ($binding in $bindings) {
        # Estraiamo il numero di porta (Il formato è IP:Porta:HostHeader)
        $port = $binding.bindingInformation.Split(":")[1]
        $protocol = $binding.protocol
        
        # Se troviamo una porta aperta in HTTP in chiaro...
        if ($protocol -eq "http") {
            Write-Host " -> Rilevata porta insicura ($port). Conversione in HTTPS..." -ForegroundColor Magenta
            
            # Rimuoviamo il binding insicuro e creiamo quello crittografato
            Remove-WebBinding -Name $siteName -Port $port -Protocol "http"
            New-WebBinding -Name $siteName -IPAddress "*" -Port $port -Protocol "https"
        }
        
        # Ora che la porta è sicuramente HTTPS, applichiamo il certificato della nostra CA
        try {
            $httpsBinding = Get-WebBinding -Name $siteName -Port $port -Protocol "https"
            if ($httpsBinding) {
                # Riapplichiamo il certificato (se c'era un certificato auto-firmato vecchio, viene sovrascritto)
                $httpsBinding.AddSslCertificate($tp, "My")
                Write-Host " -> Certificato HCLAB02 blindato sulla porta $port!" -ForegroundColor Green
                
                # Apriamo anche il firewall per questa nuova porta crittografata!
                $fwRuleName = "IIS HTTPS Personalizzata - Porta $port"
                if (!(Get-NetFirewallRule -DisplayName $fwRuleName -ErrorAction SilentlyContinue)) {
                    New-NetFirewallRule -DisplayName $fwRuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port | Out-Null
                    Write-Host " -> Regola Firewall creata per la porta $port." -ForegroundColor Cyan
                }
            }
        } catch {
            Write-Host " -> Certificato gia' presente o errore minore sulla porta $port." -ForegroundColor DarkGray
        }
    }
    
    # Riaccendiamo il sito per assicurarci che non sia andato in pausa
    Start-Website -Name $siteName -ErrorAction SilentlyContinue
}

Write-Host "--- Pulizia completata! Tutti i siti sono ora in HTTPS. ---" -ForegroundColor Green