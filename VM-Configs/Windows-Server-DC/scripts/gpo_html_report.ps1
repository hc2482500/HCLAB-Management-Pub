# Creiamo una cartella dedicata per i report HTML
$ReportPath = "C:\scripts\GPO_Reports"
New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null

$AllGPOs = Get-GPO -All

foreach ($GPO in $AllGPOs) {
    Write-Host "Generazione report: $($GPO.DisplayName)..." -NoNewline
    try {
        # Rimuove eventuali caratteri strani dal nome per creare un file valido
        $SafeName = $GPO.DisplayName -replace '[\\/:\*\?"<>\|]', '_'
        $FinalPath = "$ReportPath\$SafeName.html"
        
        # Genera il report per la singola GPO
        Get-GPOReport -Guid $GPO.Id -ReportType Html -Path $FinalPath -ErrorAction Stop | Out-Null
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " FALLITO (GPO Corrotta saltata)" -ForegroundColor Red
    }
}