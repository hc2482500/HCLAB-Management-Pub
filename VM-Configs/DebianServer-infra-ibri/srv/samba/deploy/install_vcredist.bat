@echo off
echo === INIZIO DEPLOY GPO %date% %time% === > C:\gpo_install.log

echo [GPO] Installazione Visual C++... >> C:\gpo_install.log
start /wait "" "\\192.168.79.12\deploy\vc_redist.x64.exe" /q /norestart >> C:\gpo_install.log 2>&1
echo [GPO] Esito Visual C++ (Codice errore): %errorlevel% >> C:\gpo_install.log

echo [GPO] Installazione Nextcloud Client... >> C:\gpo_install.log
start /wait "" msiexec /i "\\192.168.79.12\deploy\Nextcloud-33.0.5-x64.msi" /qn /norestart >> C:\gpo_install.log 2>&1
echo [GPO] Esito Nextcloud (Codice errore): %errorlevel% >> C:\gpo_install.log

echo === FINE DEPLOY GPO === >> C:\gpo_install.log
