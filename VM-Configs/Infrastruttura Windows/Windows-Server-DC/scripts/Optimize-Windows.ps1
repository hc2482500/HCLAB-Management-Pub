# Disabilita i servizi superflui per risparmiare RAM
$Services = @("SysMain", "DiagTrack", "MapsBroker", "Spooler")
foreach ($Service in $Services) {
    Set-Service -Name $Service -StartupType Disabled
}

# Ottimizzazione Effetti Visivi (VisualFXSetting)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2