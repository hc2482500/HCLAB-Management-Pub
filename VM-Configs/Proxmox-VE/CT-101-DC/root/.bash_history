ipa-server-install -U   -r HCRO04.LAN   -n hcro04.lan   -p Nuova-password   -a Nuova-Password   --setup-dns   --forwarder=192.168.79.2   --no-host-dns
ipa-server-install --uninstall -U
ipa-server-install -U   -r HCRO04.LAN   -n hcro04.lan   -p Nuova-Password   -a Nuova-Password   --setup-dns   --forwarder=192.168.79.2   --no-host-dns   --no-ntp
kinit admin
klist
dnf install openssh-server -y
systemctl enable --now sshd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
sudo poweroff
ip a
ping -c 4 google.com
ip a
ping -c 4 google.com
sudo pwoeroff
sudo poweroff
exit
