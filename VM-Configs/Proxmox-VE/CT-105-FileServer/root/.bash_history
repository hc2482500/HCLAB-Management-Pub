systemctl restart smbd nmbd
systemctl enable smbd nmbd
id admin
smbpasswd -a admin
systemctl restart smbd
systemctl status smbd
systemctl restart smbd
testparm -s
tail -n 20 /var/log/samba/log.smbd
cat << 'EOF' > /etc/samba/smb.conf
[global]
   workgroup = HCRO04
   server string = Enterprise File Server
   security = user
   passdb backend = tdbsam
   map to guest = Never
   
   # Protocolli moderni per Windows 11 (Escluso SMB1 insicuro)
   server min protocol = SMB2_10
   server max protocol = SMB3_11
   
   # Disattivazione NetBIOS (Inutile su reti moderne, velocizza il tunnel)
   disable netbios = yes
   smb ports = 445

   # Configurazione Log pulita
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file

[Condivisa-Enterprise]
   comment = Cartella Condivisa FreeIPA Network
   path = /srv/samba/condivisa_ipashare
   browseable = yes
   writable = yes
   guest ok = no
   valid users = @admins admin
EOF

testparm -s
systemctl restart smbd
apt install openssh-server -y
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl enable ssh
systemctl restart ssh
smbpasswd -a utest01
docker ps
cd /opt/nginx-proxy-manager
useradd -m -s /bin/bash utest02
passwd utest02
smbpasswd -a utest02
systemctl restart smbd
ls -ld /etc/samba/smb.conf
tail -f /var/log/samba/log.smbd
ls -l /var/log/samba/ls -l /var/log/samba/
grep -v '^#' /etc/samba/smb.conf | grep -v '^;' | grep -v '^$'
cat /var/log/samba/log.smbd
systemctl restart smbd
chown -R utest02:admins /srv/samba/condivisa_ipashare
chmod -R 770 /srv/samba/condivisa_ipashare
exit
exit
