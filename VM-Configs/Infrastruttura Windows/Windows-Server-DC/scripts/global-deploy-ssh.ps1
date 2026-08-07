# Script GPO per standardizzare SSH su tutti i server
$PubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6Ith7HZrw976DKKkJAF7MNJG6uep/DRtrNIJwAvwHQ windows-toubuntu"
$SshFolder = "C:\ssh_keys_global"
$KeyFile = "$SshFolder\authorized_keys"

# 1. Creazione cartella neutra (che aggira i bug della lingua o dei profili utente)
if (-not (Test-Path $SshFolder)) { New-Item -Path $SshFolder -ItemType Directory | Out-Null }

# 2. Iniezione della chiave (solo se non c'è già)
if (-not (Test-Path $KeyFile) -or (Get-Content $KeyFile) -notmatch "windows-toubuntu") {
    $PubKey.Trim() | Out-File $KeyFile -Encoding ascii -Append
}

# 3. Permessi chirurgici
icacls.exe $SshFolder /inheritance:r /q
icacls.exe $SshFolder /grant "SYSTEM:(F)" /q
icacls.exe $SshFolder /grant "BUILTIN\Administrators:(F)" /q
icacls.exe $KeyFile /inheritance:r /q
icacls.exe $KeyFile /grant "SYSTEM:(F)" /q
icacls.exe $KeyFile /grant "BUILTIN\Administrators:(F)" /q

# 4. Forziamo sshd_config a leggere da questa cartella globale sicura
$ConfigPath = "C:\ProgramData\ssh\sshd_config"
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath -Raw
    if ($Config -notmatch "C:/ssh_keys_global/authorized_keys") {
        $Config = $Config -replace '(?m)^\s*AuthorizedKeysFile.*', ''
        $Config += "`nPubkeyAuthentication yes`nStrictModes no`nAuthorizedKeysFile C:/ssh_keys_global/authorized_keys"
        $Config | Out-File $ConfigPath -Encoding ascii
        Restart-Service sshd -ErrorAction SilentlyContinue
    }
}