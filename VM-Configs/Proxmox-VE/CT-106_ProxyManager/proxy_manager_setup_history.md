
cd /opt/grafana-loki
docker compose restart promtail
docker logs promtail --tail 20
cat << 'EOF' > /opt/grafana-loki/promtail-config/promtail-local-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: pfsense_syslog
    syslog:
      listen_address: 0.0.0.0:1514
      listen_protocol: udp
      idle_timeout: 60s
      label_structured_data: yes
      use_rfc5424_message: false
      use_incoming_timestamp: true
      labels:
        job: syslog
        source: pfsense
EOF

cd /opt/grafana-loki
docker compose restart promtail
docker logs promtail --tail 5
cd /opt/grafana-loki
docker compose up -d --remove-orphans
tcpdump -i any udp port 1514 -n -A
cd /opt/grafana-loki
docker compose up -d --remove-orphans
docker ps -a | grep goaccess
docker logs goaccess --tail 20
curl -I http://localhost:7880
ufw status
docker exec crowdsec cscli decisions list
docker stats --no-stream
top -b -n 1 | head -n 15
kill -9 4158 2036
killall -9 rg node
cd grafana-loki/
docker system prune -a -f
journalctl --vacuum-time=3d
apt-get clean
du -h -x / | sort -rh | head -10
mkdir -p /opt/homepage/config
cd /opt/homepage
cat << 'EOF' > /opt/grafana-loki/../homepage/docker-compose.yml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "8085:3000" # Sarà raggiungibile sulla porta 8085
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro # Permette a Homepage di vedere lo stato dei container
    environment:
      - TZ=Europe/Rome
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.20'
          memory: 100M
EOF

cat << 'EOF' > /opt/homepage/config/services.yaml
- Infrastruttura Core:
    - Proxmox VE:
        icon: proxmox
        href: https://192.168.1.X:8006/ # Metti l'IP reale del tuo Proxmox
        description: Hypervisor Nodo PVE

    - pfSense:
        icon: pfsense
        href: https://firewall.hcro04.lan/
        description: Firewall & Router

- Gestione Traffico & Sicurezza:
    - Nginx Proxy Manager:
        icon: nginx-proxy-manager
        href: http://192.168.1.6:81/
        description: Reverse Proxy & Certificati SSL

    - GoAccess Dashboard:
        icon: goaccess
        href: http://192.168.79.166:7880/
        description: Analisi Log Web in Tempo Reale

- Monitoraggio:
    - Uptime Kuma:
        icon: uptime-kuma
        href: http://192.168.1.6:port_di_kuma/ # Cambia con la porta reale di Kuma
        description: Monitoraggio dello Stato dei Servizi
EOF

cd /opt/homepage
docker compose up -d
cat << 'EOF' > /opt/homepage/config/settings.yaml
allowedHosts:
  - 192.168.79.166
  - 192.168.1.6
  - localhost
EOF

cd /opt/homepage
docker compose restart homepage
cat << 'EOF' > /opt/homepage/config/settings.yaml
hostValidation: false
EOF

cd /opt/homepage
docker compose down
docker compose up -d
cat << 'EOF' > /opt/homepage/config/settings.yaml
allowedHosts:
  - 192.168.79.166:8085
  - 192.168.1.6:8085
  - 192.168.79.166:3000
  - 192.168.1.6:3000
  - localhost:8085
EOF

cd /opt/homepage
docker compose restart homepage
docker logs homepage --tail 20
cat << 'EOF' > /opt/homepage/docker-compose.yml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "8085:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - TZ=Europe/Rome
      - HOMEPAGE_ALLOWED_HOSTS=all
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.20'
          memory: 100M
EOF

cd /opt/homepage
docker compose down
docker compose up -d
docker logs homepage --tail 20
cat << 'EOF' > /opt/homepage/docker-compose.yml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "8085:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - TZ=Europe/Rome
      - HOMEPAGE_ALLOWED_HOSTS=192.168.79.166:8085,192.168.1.6:8085,localhost:8085
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.20'
          memory: 100M
EOF

cd /opt/homepage
docker compose down
docker compose up -d
cd /opt/homepage
cd /opt/homepage
cd /opt/nginx-proxy-manager
ls -la
openssl x509 -in /opt/nginx-proxy-manager/certs/local.crt -text -noout | grep "Not After"
/opt/nginx-proxy-manager/certs/local.crt
cd /opt/nginx-proxy-manager
ls -la data/custom_ssl
mv data/custom_ssl data/custom_ssl.bak
docker compose restart
docker compose down
mv data/custom_ssl.bak data/custom_ssl
docker compose up -d
docker ps
docker logs nginx-proxy-manager
cd /opt/nginx-proxy-manager
docker compose down
rm -rf data/nginx/proxy_host/*
rm -rf data/nginx/redirection_host/*
rm -rf data/nginx/dead_host/*
docker compose up -d
docker logs nginx-proxy-manager
docker logs nginx-proxy-manager
docker exec crowdsec cscli decisions list
curl -I http://localhost:81
systemctl restart docker
reboot
docker logs nginx-proxy-manager --tail 20
cd /opt/vaultwarden
docker compose down && docker compose up -d
openssl req -x509 -nodes -days 3650 -newkey rsa:2048   -keyout /opt/nginx-proxy-manager/certs/local.key   -out /opt/nginx-proxy-manager/certs/local.crt   -subj "/CN=*.hcro04.lan"   -addext "subjectAltName=DNS:*.hcro04.lan,DNS:hcro04.lan"   -addext "basicConstraints=CA:TRUE,pathlen:0"   -addext "keyUsage=digitalSignature,keyCertSign,cRLSign"
cat /opt/nginx-proxy-manager/certs/local.crt
cat /opt/nginx-proxy-manager/certs/local.key
openssl genrsa -out /opt/nginx-proxy-manager/certs/rootCA.key 4096
openssl req -x509 -new -nodes -key /opt/nginx-proxy-manager/certs/rootCA.key -sha256 -days 3650   -out /opt/nginx-proxy-manager/certs/rootCA.crt   -subj "/CN=HCRO04 Next-Gen Lab Root CA"
cat <<EOF > /opt/nginx-proxy-manager/certs/local.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.hcro04.lan
DNS.2 = hcro04.lan
EOF

openssl genrsa -out /opt/nginx-proxy-manager/certs/local.key 2048
openssl req -new -key /opt/nginx-proxy-manager/certs/local.key   -out /opt/nginx-proxy-manager/certs/local.csr   -subj "/CN=*.hcro04.lan"
openssl x509 -req -in /opt/nginx-proxy-manager/certs/local.csr   -CA /opt/nginx-proxy-manager/certs/rootCA.crt   -CAkey /opt/nginx-proxy-manager/certs/rootCA.key   -CAcreateserial -out /opt/nginx-proxy-manager/certs/local.crt   -days 3650 -sha256 -extfile /opt/nginx-proxy-manager/certs/local.ext
cat /opt/nginx-proxy-manager/certs/local.key
cat /opt/nginx-proxy-manager/certs/local.crt
cat /opt/nginx-proxy-manager/certs/local.crt /opt/nginx-proxy-manager/certs/rootCA.crt > /opt/nginx-proxy-manager/certs/fullchain.crt
docker compose down
ls
cd opt/vaultwarden/
ls
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker run --rm -it vaultwarden/server /vaultwarden hash
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker run --rm -it vaultwarden/server /vaultwarden hash
docker compose down
docker compose up -d
cd /opt/homepage
docker compose up -d
docker compose down
docker compose up -d
docker compose down
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker logs homepage
docker logs -f homepage
docker logs -f homepage 2>&1 | grep -i "proxmox"
docker exec homepage ping 192.168.79.100
docker logs -f homepage | grep -A 5 "proxmox"
docker logs -f homepage | grep -A 5 "proxmox"
docker logs -f homepage | grep -A 5 "proxmox"
docker compose restart homepage
cd homepage/
docker logs -f homepage | grep -A 5 "proxmox"
docker compose restart homepage
docker logs homepage
docker compose restart homepage
docker logs homepage
docker logs homepage
docker compose restart homepage
docker logs homepage
docker compose restart homepage
docker logs homepage
docker compose restart homepage
docker logs homepage
docker compose restart homepage
docker compose restart homepage
docker logs homepage
docker compose restart homepage
curl -k -H 'Authorization: PVEAPIToken=api-homepage@pve!homepage=<REDACTED_PVE_TOKEN>' https://192.168.79.100:8006/api2/json/version
docker compose restart homepage
docker logs homepage
docker compose restart homepage
docker logs -f homepage
curl -k -H 'Authorization: PVEAPIToken=api-homepage@pve!homepage=<REDACTED_PVE_TOKEN>' https://192.168.79.100:8006/api2/json/cluster/resources
docker compose restart homepage
docker compose restart homepage
docker logs -f homepage
docker compose restart homepage
docker logs -f homepage
docker compose stop homepage
docker compose up -d
docker logs -f homepage
docker compose stop homepage
docker compose up -d
docker logs -f homepage
docker compose down
rm -rf config/logs/*
docker compose up -d
docker logs -f homepage
docker compose down
rm -rf config/logs/*
docker compose up -d
docker logs -f homepage
rm -rf config/logs/*
docker logs -f homepage
docker compose down
rm -rf config/logs/*
docker compose up -d
docker logs -f homepage
curl -k -H 'Authorization: PVEAPIToken=api-homepage@pve!homepage=<REDACTED_PVE_TOKEN>' https://192.168.79.100:8006/api2/json/cluster/resources
docker compose down
rm -rf config/logs/*
docker compose up -d
docker logs -f homepage
rm -rf config/logs/*
docker logs -f homepage
netstat -tulpn | grep 7880
curl -I http://127.0.0.1:7880
cd /opt/uptime-kuma/
docker restart uptime-kuma
nano /etc/hosts
nano /etc/hosts
docker compose down
docker compose up -d
docker compose down
docker compose up -d
docker compose down
docker compose up -d
wget -O /opt/headscale/config/config.yaml https://raw.githubusercontent.com/juanfont/headscale/main/config-example.yaml
cd headscale/
docker compose up -d
docker compose up -d
docker exec headscale headscale users create admin
docker exec headscale headscale users create admin
docker logs headscale
docker compose up -d
docker logs headscale
docker exec headscale headscale users create admin
cat << 'EOF' > /opt/headscale/config/acl.hujson
{
  "acls": [
    { "action": "accept", "src": ["*"], "dst": ["*:*"] }
  ]
}
EOF

docker compose restart headscale
docker exec headscale headscale users create admin
docker exec headscale headscale users create admin
sed -i 's|path: "/var/lib/headscale/db.sqlite"|path: "/etc/headscale/acl.hujson"|' /opt/headscale/config/config.yaml
docker compose restart headscale
docker logs headscale
docker compose down
docker compose up -d
docker logs headscale
docker exec headscale headscale users create admin
sed -i 's/auto_update_enabled: true/auto_update_enabled: false/' /opt/headscale/config/config.yaml
sed -i 's|- https://controlplane.tailscale.com/derpmap/default|#- https://controlplane.tailscale.com/derpmap/default|' /opt/headscale/config/config.yaml
docker compose restart headscale
docker logs headscale
docker exec headscale headscale users create admin
docker compose down
docker compose up -d
docker logs headscale
cat << 'EOF' > /opt/headscale/config/derp.yaml
regions:
  900:
    regionid: 900
    regioncode: local
    regionname: Local Fake DERP
    nodes:
      - name: 900a
        regionid: 900
        hostname: 127.0.0.1
        ipv4: 127.0.0.1
        stunport: 3478
        stunonly: false
        derpport: 3478
EOF

docker compose down
docker compose up -d
docker logs headscale
docker exec headscale headscale users create admin
docker compose up -d
ping 8.8.8.8
ip route
ip addr
ip addr
root
ping -c 4 192.168.10.1
ping .c 4 8.8.8.8
ping -c 4 8.8.8.8
apt update && install openssh-server -y
apt update && apt install openssh-server -y
echo "nameserver 8.8.8.8" > /etc/resolv.conf
ping -c 3 google.com
apt update && apt install openssh-server -y
nano /etc/ssh/sshd_config
poweroff
ip a
rm -rf ~/.vscode-server ~/.vscode-server-oss
pkill -f codium-server
rm -rf ~/.vscodium-server
exit
pkill -9 -f codium
pkill -9 -f vscode
rm -rf ~/.vscodium-server ~/.vscode-server ~/.vscode-server-oss
ps aux | grep -i codium
exit
cd headscale/
docker compose down
docker compose up -d
docker exec -it headscale headscale auth register --auth-id <REDACTED_TAILSCALE_AUTH_KEY> --user admin
docker exec -it headscale headscale auth register --auth-id <REDACTED_TAILSCALE_AUTH_KEY> --user admin
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://<REDACTED_NGROK_ID>.ngrok-free.dev --advertise-routes=172.16.10.0/24,192.168.10.0/24
systemctl start tailscaled
systemctl enable tailscaled
tailscale up --login-server=https://<REDACTED_NGROK_ID>.ngrok-free.dev --advertise-routes=172.16.10.0/24,192.168.10.0/24
codium --remote ssh-remote+debproxy-managerv2 /root
tailscale up --login-server=https://<REDACTED_NGROK_ID>.ngrok-free.dev --advertise-routes=172.16.10.0/24,192.168.10.0/24
curl -i https://<REDACTED_NGROK_ID>.ngrok-free.dev
apt-get update && apt-get install -y ca-certificates
update-ca-certificates
curl -i https://<REDACTED_NGROK_ID>.ngrok-free.dev
apt-get install -y openssl
openssl s_client -showcerts -connect <REDACTED_NGROK_ID>.ngrok-free.dev:443 </dev/null | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > /usr/local/share/ca-certificates/ngrok-chain.crt
update-ca-certificates
curl -i https://<REDACTED_NGROK_ID>.ngrok-free.dev
tailscale up --login-server=https://<REDACTED_NGROK_ID>.ngrok-free.dev --advertise-routes=172.16.10.0/24,192.168.10.0/24 --reset
docker compose down
cd headscale/
docker compose down
tailscale up --advertise-routes=172.16.10.0/24,192.168.10.0/24 --reset
systemctl restart tailscaled
tailscale up --login-server=https://controlplane.tailscale.com --advertise-routes=172.16.10.0/24,192.168.10.0/24
curl -i https://controlplane.tailscale.com
ip a
nano /etc/network/interfaces
systemctl status sshd
nano /etc/ssh/sshd_config
ip a
ping -c 3 192.168.1.1
ping -c 3 192.168.79.166
ping -c 3 192.168.1.1
docker exec crowdsec cscli bouncers delete opnsense-firewall
docker exec crowdsec cscli bouncers add opnsense-firewall
docker exec crowdsec cscli bouncers list
curl -I http://192.168.1.6:8080/
cd grafana-loki/
docker compose down
docker compose up -d
curl -I http://192.168.1.6:8080/
docker ps | grep crowdsec
docker logs crowdsec | tail -n 20
ping -c 3 google.com
cat /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf
docker restart crowdsec
curl -I http://192.168.1.6:8080/
docker compose down
docker compose up -d
docker logs crowdsec | tail -n 20
curl -I http://192.168.1.6:8080/
docker logs crowdsec | tail -n 20
curl -I http://127.0.0.1:8080/
docker exec crowdsec cscli bouncers list
cd -
ls
cd goaccess-crowdsec/
cd /opt/headscale
docker compose down --volumes --remove-orphans
cd ..
rm -rf headscale
cd /opt/grafana-loki
rm -rf grafana-data loki-config promtail-config prometheus.yml
docker ps -a
docker network prune -f
docker volume prune -f
docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 15m --reason "Test integrazione OPNsense"
docker exec crowdsec cscli decisions delete --ip 1.2.3.4
docker exec crowdsec cscli decisions add --ip 192.168.1.7 --duration 5m --reason "Test blocco RDP perimetrale"
docker exec crowdsec cscli bouncers add opnsense-firewall
systemctl status ssh
exit
find / -name "acquis.yaml" 2>/dev/null
