# =================================================================
# Script: Deploy-FileShares.ps1
# Descrizione: Crea l'infrastruttura delle cartelle condivise (IaC)
# =================================================================

$CartelleCondivise = @(
    @{
        NomeCondivisione = "Dati_Z"
        PercorsoFisico   = "C:\Condivisioni\Dati_Z"
        Descrizione      = "Cartella mappata come disco Z tramite GPO"
        GruppoAccesso    = "hclab02\Domain Users"
    },
    @{
        NomeCondivisione = "IT_Admin"
        PercorsoFisico   = "C:\Condivisioni\IT_Admin"
        Descrizione      = "Strumenti e script per amministratori"
        GruppoAccesso    = "hclab02\Domain Admins"
    }
)

Write-Host "Inizio creazione infrastruttura File Server..." -ForegroundColor Cyan

foreach ($Cartella in $CartelleCondivise) {
    if (-not (Test-Path -Path $Cartella.PercorsoFisico)) {
        New-Item -ItemType Directory -Path $Cartella.PercorsoFisico | Out-Null
        Write-Host "Creata directory fisica: $($Cartella.PercorsoFisico)" -ForegroundColor Yellow
    }

    if (-not (Get-SmbShare -Name $Cartella.NomeCondivisione -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $Cartella.NomeCondivisione -Path $Cartella.PercorsoFisico -Description $Cartella.Descrizione -FullAccess $Cartella.GruppoAccesso | Out-Null
        Write-Host "Creata condivisione di rete: \\$env:COMPUTERNAME\$($Cartella.NomeCondivisione)" -ForegroundColor Green
    } else {
        Write-Host "La condivisione $($Cartella.NomeCondivisione) esiste gia'. Salto." -ForegroundColor Gray
    }
}
Write-Host "Infrastruttura pronta!" -ForegroundColor Cyan
