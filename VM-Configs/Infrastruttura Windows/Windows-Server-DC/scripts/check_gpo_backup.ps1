$BackupPath = "C:\scripts\GPO_Backups"
$AllGPOs = Get-GPO -All

foreach ($GPO in $AllGPOs) {
    Write-Host "Tentativo di backup: $($GPO.DisplayName)..." -NoNewline
    try {
        Backup-GPO -Guid $GPO.Id -Path $BackupPath -Comment "Backup automatico per GitHub" -ErrorAction Stop | Out-Null
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " FALLITO (GPO Corrotta o Dati non validi)" -ForegroundColor Red
    }
}