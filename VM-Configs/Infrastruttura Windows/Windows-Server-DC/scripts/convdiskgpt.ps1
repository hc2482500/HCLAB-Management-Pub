# 1. Forza Windows a fare una scansione dei nuovi dischi
Update-HostStorageCache

# 2. Trova tutti i dischi presenti TRANNE il disco di sistema (Disco 0)
$dischiAggiuntivi = Get-Disk | Where-Object Number -ne 0

if ($dischiAggiuntivi.Count -ge 2) {
    $num1 = $dischiAggiuntivi[0].Number
    $num2 = $dischiAggiuntivi[1].Number
    
    Write-Host "Ho scovato i dischi! Sono il Disco $num1 e il Disco $num2. Li converto in GPT..." -ForegroundColor Cyan

    # 3. Pialla e converte
    Set-Disk -Number $num1 -IsOffline $false -ErrorAction SilentlyContinue
    Set-Disk -Number $num2 -IsOffline $false -ErrorAction SilentlyContinue
    Clear-Disk -Number $num1 -RemoveData -Confirm:$false
    Clear-Disk -Number $num2 -RemoveData -Confirm:$false
    Initialize-Disk -Number $num1 -PartitionStyle GPT
    Initialize-Disk -Number $num2 -PartitionStyle GPT

    # 4. Formatta con le lettere corrette
    New-Partition -DiskNumber $num1 -UseMaximumSize -DriveLetter E | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Dati_Sorgente" -Confirm:$false
    New-Partition -DiskNumber $num2 -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Log_Sorgente" -Confirm:$false
    
    Write-Host "Vittoria! Dischi $num1 e $num2 convertiti in GPT e lettere assegnate." -ForegroundColor Green
} else {
    Write-Host "ERRORE: Windows vede solo $($dischiAggiuntivi.Count) dischi oltre a C:. Lancia 'Get-Disk' per capire cosa vede il sistema!" -ForegroundColor Red
}