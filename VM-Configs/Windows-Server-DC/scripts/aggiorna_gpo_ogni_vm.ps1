# Carica il modulo di Active Directory
Import-Module ActiveDirectory

# Trova tutti i computer e forza l'aggiornamento GPO con ritardo ZERO
Get-ADComputer -Filter * | ForEach-Object {
    Write-Host "Invio comando di aggiornamento GPO a: $($_.Name)..." -ForegroundColor Cyan
    Invoke-GPUpdate -Computer $_.Name -RandomDelayInMinutes 0 -Force -ErrorAction SilentlyContinue
    Write-Host "Comando inviato!" -ForegroundColor Green
}