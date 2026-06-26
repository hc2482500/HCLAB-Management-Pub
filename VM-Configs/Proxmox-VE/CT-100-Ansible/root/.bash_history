cd ansible-infra
ansible control_node -m ping
export LC_ALL=C.UTF-8
ansible control_node -m ping
apt install locales -y
locale-gen en_US.UTF-8 it_IT.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id root@x.x.x.31
ssh-copy-id hcrocky@x.x.x.31
ssh-copy-id root@x.x.x.31
ansible identity_servers -m ping
ansible-playbook deploy_identity.yml
ssh root@192.168.79.31
sudo poweroff
ip a
ping -c 4 google.com
sudo poweroff
sudo reboot
ansible-playbook -i inventory.ini deploy_local_dns.yml
ssh-copy-id root@x.x.1.7
ansible-playbook -i inventory.ini bootstrap_management.yml
reboot
dhclient -r eth0
dhclient eth0
ip a
exit
