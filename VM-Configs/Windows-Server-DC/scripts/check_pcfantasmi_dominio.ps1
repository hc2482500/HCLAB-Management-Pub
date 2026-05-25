$GiorniInattivita = 60 # Imposta il limite (es. se non dà segni di vita da 60 giorni, è un fantasma)
$DataLimite = (Get-Date).AddDays(-$GiorniInattivita)

Write-Host "--- Caccia ai Computer Fantasma (Inattivi da più di $GiorniInattivita giorni) ---" -ForegroundColor Cyan

# Peschiamo i computer controllando il loro "LastLogonTimeStamp"
$Fantasmi = Get-ADComputer -Filter {LastLogonTimeStamp -lt $DataLimite} -Properties LastLogonTimeStamp, OperatingSystem | 
    Select-Object Name, OperatingSystem, @{Name="Ultimo Contatto"; Expression={[DateTime]::FromFileTime($_.LastLogonTimeStamp)}}

if ($Fantasmi) {
    $Fantasmi | Format-Table -AutoSize
    Write-Host "Trovati $($Fantasmi.Count) computer fantasma da eliminare dal Dominio e da WAC!" -ForegroundColor Red
} else {
    Write-Host "Il Dominio è pulito! Nessuna macchina morta rilevata." -ForegroundColor Green
}