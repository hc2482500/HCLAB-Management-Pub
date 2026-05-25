$disks = Get-Disk | Where-Object PartitionStyle -eq 'RAW'
if ($disks) {
    # Primo disco da 3GB -> Dati Destinazione (E:)
    Initialize-Disk -Number $disks[0].Number -PartitionStyle GPT
    New-Partition -DiskNumber $disks[0].Number -UseMaximumSize -DriveLetter E | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Dati_Destinazione" -Confirm:$false
    
    # Secondo disco da 3GB -> Log Destinazione (F:)
    Initialize-Disk -Number $disks[1].Number -PartitionStyle GPT
    New-Partition -DiskNumber $disks[1].Number -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Log_Destinazione" -Confirm:$false
    Write-Host "Nuovi dischi Destinazione pronti su E: e F:!" -ForegroundColor Green
}