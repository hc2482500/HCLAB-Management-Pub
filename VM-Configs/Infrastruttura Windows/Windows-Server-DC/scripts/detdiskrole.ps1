$disks = Get-Disk | Where-Object PartitionStyle -eq 'RAW'
if ($disks) {
    # Primo disco da 3GB -> Dati Sorgente (E:)
    Initialize-Disk -Number $disks[0].Number -PartitionStyle GPT
    New-Partition -DiskNumber $disks[0].Number -UseMaximumSize -DriveLetter E | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Dati_Sorgente" -Confirm:$false
    
    # Secondo disco da 3GB -> Log Sorgente (F:)
    Initialize-Disk -Number $disks[1].Number -PartitionStyle GPT
    New-Partition -DiskNumber $disks[1].Number -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Log_Sorgente" -Confirm:$false
    Write-Host "Nuovi dischi Sorgente pronti su E: e F:!" -ForegroundColor Green
}