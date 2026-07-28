🌐 Enterprise IPv6-Only Cloud Lab & NAT64 Transition
Questo repository documenta l'architettura, i manifesti e gli script di configurazione di un laboratorio di rete Cloud Native avanzato. L'obiettivo del progetto è la realizzazione di un'infrastruttura 100% IPv6-Only[cite: 7, 8], capace di esporre servizi applicativi orchestrati verso il mondo esterno (IPv4) tramite tecnologie di transizione all'avanguardia come NAT64 e DNS64.

🏗️ Architettura e Flusso del Traffico (Ingress L3/L7)
Il traffico di rete attraversa molteplici livelli di traduzione e proxying per garantire la compatibilità tra client legacy (IPv4) e workload Cloud Native (IPv6):

Client (IPv4): Invia una richiesta HTTP/HTTPS[cite: 7].

Gateway OpenWrt (NAT64): Intercetta la richiesta su un IP WAN alias IPv4 dedicato (es. .179)[cite: 8]. Il demone Jool traduce l'intestazione L3 da IPv4 a IPv6 (NAT64 Inbound) e la inoltra nella rete virtuale isolata[cite: 7, 8].

Reverse Proxy (NPM su LXC): Un container LXC Debian ospita Nginx Proxy Manager in modalità host networking[cite: 7]. Riceve il traffico IPv6 tradotto, risolve l'header SNI/L7 e instrada la connessione verso il nodo Kubernetes corretto[cite: 7, 8].

Kubernetes (K3s): Il traffico raggiunge il Control Plane o i Worker Node (IPv6 nativo), atterrando sui Pod applicativi (es. WordPress o Portainer)[cite: 7, 8].

🛠️ Stack Tecnologico
Hypervisor Layer: Proxmox VE nidificato su VMware Workstation (con ottimizzazione MAC Spoofing e Offloading disabilitato)[cite: 7, 8].

Core Networking & Traduzione: OpenWrt (x86-64)[cite: 7, 8].

NAT64: jool-netfilter (Tabelle BIB statiche)[cite: 7, 8].

DNS64: unbound-daemon (Sintesi DNS per permettere ai nodi IPv6 di scaricare pacchetti da internet IPv4)[cite: 7, 8].

Orchestrazione & Compute:

Kubernetes K3s (Cluster Multi-Nodo IPv6-Only con SDN Flannel)[cite: 7, 8].

Linux Containers (LXC) per carichi di rete critici e diretti[cite: 8].

Gestione Ingress & GUI: Nginx Proxy Manager (Reverse Proxy L7), Portainer CE (Helm Deployment)[cite: 7, 8].

💡 Key Engineering Challenges & Soluzioni
Questo laboratorio ha richiesto un troubleshooting sistemistico e di rete di altissimo livello, documentato nei file di configurazione presenti:

Bypass del Routing Asimmetrico (SSH ProxyJump): Per amministrare i nodi isolati IPv6 da un host Windows IPv4, è stato implementato un Bastion Host su OpenWrt sfruttando la direttiva ProxyJump di OpenSSH, garantendo un accesso Passwordless trasparente tramite chiavi Ed25519[cite: 7, 8].

Risoluzione "Port Collision" e Limiti CNI: I bug di networking IPv6 nativo (Netavark/Podman) e i conflitti sui namespace sono stati risolti migrando i servizi di rete critici su istanze LXC con network_mode: host e adottando Kubernetes per il workload applicativo[cite: 7, 8].

Automazione Jool e Race Conditions: Per garantire la resilienza del motore NAT64 al riavvio, è stato sviluppato uno script di startup su OpenWrt (rc.local) che attende dinamicamente l'assegnazione dell'IP WAN prima di iniettare la Binding Information Base (BIB)[cite: 7, 8].

WordPress IPv6 Ingress Routing: Le variabili d'ambiente di WordPress (WP_HOME, WP_SITEURL) sono state iniettate direttamente nei manifesti YAML per prevenire loop di redirect HTTP 302 dietro il reverse proxy[cite: 8].

⚠️ Note sulla Sicurezza e Sanitizzazione
Tutti i manifesti e gli script in questo repository sono stati sanitizzati. Indirizzi IP reali, subnet ULA di laboratorio, chiavi pubbliche/private, token di setup e credenziali dei database sono stati sostituiti con dei segnaposto (es. <REDACTED>)[cite: 7, 8].