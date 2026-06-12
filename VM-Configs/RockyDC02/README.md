🚀 Enterprise Linux Lab - Infrastructure as Code (IaC)

Questo repository contiene il codice infrastrutturale (IaC) utilizzato per automatizzare il deployment, la configurazione e il monitoraggio di un data center Linux di classe Enterprise.
L'intero ambiente è stato progettato con un approccio Zero-Trust, puntando su distribuzioni stabili (Long Term Support), isolamento dei carichi di lavoro tramite virtualizzazione leggera e aderenza rigorosa ai controlli di accesso obbligatorio (MAC).

🏗️ Architettura e Stack Tecnologico

L'infrastruttura è governata da un Master Node (Rocky Linux 9.7) che funge da Domain Controller e torre di controllo Ansible. I micro-servizi sono segregati all'interno di container LXC/LXD (Ubuntu), istruiti direttamente tramite socket senza l'uso di demoni SSH intermedi.

🛠️ Core Technologies

Identity & Access Management: FreeIPA (LDAP, KDC Kerberos, DNS BIND), Keycloak (IAM SSO federato).
Virtualization & Web: LXC/LXD, Apache HTTP Server (Reverse Proxy con SNI Offloading), Nginx.
Storage & File Sharing: Stratis (LVM/XFS), OpenZFS, Samba (SSO Domain Joined).
Security & Hardening: SELinux (Enforcing persistente), Kernel Live Patching (kpatch), Firewalld, PKI/ACME interna.
Observability & SIEM: Prometheus, Grafana, stack ELK (Elasticsearch, Kibana, Filebeat per la raccolta log).
Version Control (GitOps): Gitea (Self-hosted).

🌟 Funzionalità Principali

Identità Centralizzata (SSO): Autenticazione invisibile Kerberos per l'accesso client (Fedora/Rocky), alle share Samba e ai micro-servizi (Keycloak).
Gestione SSL/TLS Zero-Touch: La CA interna (FreeIPA) funge da provider ACME. I certificati per i container vengono richiesti, validati (HTTP-01 challenge) e rinnovati automaticamente tramite Certbot.
Isolamento SELinux & Hardening PAM: Protezione contro i movimenti laterali tramite etichette di sicurezza rigide (es. samba_share_t). Restrizioni PAM e bypass dinamico in fase di boot per prevenire race conditions.
Corporate Desktop Baseline: Automazione flotta client (GPO-like) per distribuire software (Brave Browser), forzare layout grafici (ArcMenu, Dash-to-panel) e mappare drive di rete in modo idempotente.
Disaster Recovery Automatizzato: Script Bash orchestrati da Systemd Timer per lo snapshot a caldo e l'export dei container LXC verso pool di storage Stratis, con Retention Policy dinamica.

🗺️ Topologia di Rete (Logica SNI)

Tutto il traffico HTTP/HTTPS in ingresso viene intercettato da Apache sul Master Node, che analizza l'header SNI (Server Name Indication) ed esegue il proxying preservando la catena crittografica verso i container LXD isolati in una subnet NAT privata.

📂 Struttura del Repository

inventory.example: File di inventario di base con gruppi logici e direttive LXD (da compilare con i propri IP).
deploy_*.yml: Playbook Ansible modulari per l'installazione dei singoli componenti (Web, IAM, Monitoring, Vaultwarden, Git).
corporate_baseline.yml: Playbook globale per la configurazione dei client Linux aziendali e hardening.
templates/: File di configurazione sorgente (VirtualHost Apache, smb.conf, drop-in Systemd, configurazioni Nginx).
scripts/: Script bash per attività di Disaster Recovery e Shutdown controllato (lab-down).

⚠️ Disclaimer

Questo repository rappresenta una versione pubblica e sanitizzata del codice originario. Tutti i dati sensibili, le chiavi asimmetriche SSH/TLS, i ticket Kerberos, le password in chiaro e gli indirizzi IP reali della topologia privata sono stati rimossi o sostituiti con placeholder (<TUO_IP>, <TUO_DOMINIO>) per ragioni di sicurezza.