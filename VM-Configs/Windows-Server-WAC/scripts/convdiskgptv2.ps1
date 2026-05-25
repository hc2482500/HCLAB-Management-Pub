Update-HostStorageCache
$dischiAggiuntivi = Get-Disk | Where-Object Number -ne 0

if ($dischiAggiuntivi.Count -ge 2) {
    $num1 = $dischiAggiuntivi[0].Number
    $num2 = $dischiAggiuntivi[1].Number
    
    Set-Disk -Number $num1 -IsOffline $false -ErrorAction SilentlyContinue
    Set-Disk -Number $num2 -IsOffline $false -ErrorAction SilentlyContinue
    Clear-Disk -Number $num1 -RemoveData -Confirm:$false
    Clear-Disk -Number $num2 -RemoveData -Confirm:$false
    Initialize-Disk -Number $num1 -PartitionStyle GPT
    Initialize-Disk -Number $num2 -PartitionStyle GPT

    New-Partition -DiskNumber $num1 -UseMaximumSize -DriveLetter E | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Dati_Destinazione" -Confirm:$false
    New-Partition -DiskNumber $num2 -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Log_Destinazione" -Confirm:$false
    
    Write-Host "Gateway pronto! Dischi $num1 e $num2 in GPT." -ForegroundColor Green
}