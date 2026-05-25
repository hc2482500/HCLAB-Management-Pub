$PathGitHub = "C:\install-my-rsat.ps1"

# Genera lo script su misura per te
Get-WindowsCapability -Online -Name Rsat* | Where-Object {$_.State -eq 'Installed'} | ForEach-Object {
    "Add-WindowsCapability -Online -Name '$($_.Name)'"
} | Out-File -FilePath $PathGitHub

Write-Host "Script generato con successo in $PathGitHub!" -ForegroundColor Green