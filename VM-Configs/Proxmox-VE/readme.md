🚀 Enterprise-Grade Home Lab & IaC Repository
Benvenuto nel mio repository di Infrastructure as Code (IaC) e configurazioni di sistema. Questo progetto documenta la costruzione, l'ottimizzazione e la messa in sicurezza di un Data Center on-premise simulato, basato su architettura Proxmox VE.
L'obiettivo di questo laboratorio è dimostrare competenze avanzate in ambito System Engineering, NetSecOps, Identity Management e Automazione, adottando rigorosamente best practice di livello enterprise.

🛠️ Stack Tecnologico
L'infrastruttura è stata ingegnerizzata privilegiando soluzioni open-source e architetture a microservizi (LXC/Docker), orchestrate dietro un firewall perimetrale rigido.
Hypervisor & Virtualization: Proxmox VE, Container LXC (Privileged/Unprivileged), QEMU/KVM.
Routing & Security (SecOps): OPNsense (Core Gateway), pfSense (Legacy), CrowdSec (IPS/Threat Intelligence).
Identity & Access Management (IAM): FreeIPA (Domain Controller), Kerberos, Samba (File Server SMB2/3).
Traffic Management & PKI: Nginx Proxy Manager (NPM), Autorità di Certificazione Locale (2-Tier PKI), Certificati SSL Wildcard.
Automazione (IaC): Ansible (Control Node), SSH Passwordless (Ed25519).
Observability & Monitoraggio: Uptime Kuma, GoAccess, Homepage (Dashboard centralizzata API-driven).
Backup & Disaster Recovery: Proxmox Backup Server (PBS) con deduplica a blocchi.

🏛️ Architettura e Sicurezza (Zero Trust)
La topologia di rete è stata disegnata per garantire il massimo isolamento ("Architettura a Isola"). I servizi non sono esposti direttamente alla rete fisica host, ma risiedono in una VLAN dedicata (192.168.1.x) protetta dal firewall OPNsense.

🛡️ SecOps Active Defense (CrowdSec)
L'ecosistema integra CrowdSec per un'analisi attiva dei log e la mitigazione delle minacce in tempo reale.
Layer 7 (Applicativo): Nginx Proxy Manager intercetta gli attacchi web restituendo codici 403 Forbidden.
Layer 3/4 (Network): L'agent LAPI centralizzato comunica con il bouncer di OPNsense, iniettando decisioni di blocco direttamente nel kernel pf per estromettere istantaneamente gli IP compromessi (inclusa l'interruzione di sessioni RDP attive).

🔑 Identity Provider & PKI a 2 Livelli
La gestione degli accessi è demandata a FreeIPA (hcro04.lan), che funge da Domain Controller.
Implementazione di una 2-Tier PKI (Root CA e Leaf Certificate) per prevenire gli allarmi dei browser e garantire transazioni HTTPS sicure su Vaultwarden (Web Crypto API).
Integrazione continua tra Domain Controller e File Server Samba tramite SSSD per il mapping istantaneo degli utenti e dei permessi POSIX.

🧩 Sfide Ingegneristiche e Problem Solving (Case Studies)
Durante il deployment, sono state affrontate e risolte diverse criticità sistemistiche avanzate:
Ottimizzazione Risorse (Da Stack Pesanti a Lightweight):
Risoluzione di un collo di bottiglia hardware (CPU/RAM al 100%) generato da uno stack Grafana/Loki/Promtail. L'architettura è stata ripensata effettuando un pivot verso GoAccess e Uptime Kuma, liberando oltre 1.5 GB di RAM senza perdere capacità di osservabilità.
Risoluzione Conflitti Layer 2 e Routing Asimmetrico:
Risoluzione dei drop di pacchetti intercettando il conflitto tra il firewall nativo dell'hypervisor Proxmox (vNIC) e le regole NAT di OPNsense. Stabilizzazione dei loop di routing asimmetrico abilitando l'override Disable Reply-To sulle regole WAN.
Kernel Limits e Super-UID nei Container LXC:
Bypassato il blocco del kernel Linux sui container Unprivileged (impossibilità di mappare gli UID giganti di FreeIPA, es. 1339400000). Tramite un backup/restore tattico su PBS, i nodi critici sono stati convertiti in Privileged, garantendo la continuità dell'infrastruttura d'identità in meno di 60 secondi.