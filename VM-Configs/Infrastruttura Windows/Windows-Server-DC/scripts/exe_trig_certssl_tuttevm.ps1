# 1. Recuperiamo tutte le macchine virtuali
$VMs = Get-ADComputer -Filter {OperatingSystem -notlike "*Server*"} | Select-Object -ExpandProperty Name

Write-Host "Trovate $($VMs.Count) macchine virtuali. Inizio orchestrazione via WMI/DCOM..." -ForegroundColor Cyan

# 2. Creiamo un'opzione per forzare il protocollo DCOM (che passa per il firewall WMI che abbiamo aperto)
$dcomOption = New-CimSessionOption -Protocol Dcom

foreach ($vm in $VMs) {
    try {
        # Creiamo un "tunnel" WMI verso la VM
        $cimSession = New-CimSession -ComputerName $vm -SessionOption $dcomOption -ErrorAction Stop
        
        # Lanciamo il task attraverso il tunnel
        Start-ScheduledTask -TaskName "Aggiorna SSL IIS" -CimSession $cimSession -ErrorAction Stop
        
        # Chiudiamo il tunnel
        Remove-CimSession -CimSession $cimSession
        
        Write-Host "✅ Task avviato con successo tramite WMI su: $vm" -ForegroundColor Green
    } catch {
        Write-Host "❌ Errore su $vm : $($_.Exception.Message)" -ForegroundColor Red
    }
}