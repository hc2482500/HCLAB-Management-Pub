# Parametro opzionale per il messaggio. Se non scrivi nulla, usa quello di default.
param (
    [string]$Messaggio = "Backup automatico dell'infrastruttura (Automated Commit)"
)

# Recupera dinamicamente l'URL di GitHub impostato per QUESTA specifica cartella
$RepoDestinazione = git remote get-url origin

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " STAI PER SPEDIRE I FILE NELLA SEGUENTE REPOSITORY:" -ForegroundColor Yellow
Write-Host " $RepoDestinazione" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Preparazione dei file in corso..." -ForegroundColor Cyan
git add .

Write-Host "2. Creazione del salvataggio locale..." -ForegroundColor Cyan
git commit -m $Messaggio

Write-Host "3. Spedizione su GitHub in corso..." -ForegroundColor Cyan
git push

Write-Host "✅ Finito! Tutti i file sono al sicuro nel cloud." -ForegroundColor Green