🏢 Self-Hosted Hybrid IT Infrastructure Lab

Questo repository documenta la progettazione e il deployment di un laboratorio infrastrutturale IT aziendale self-hosted. Il progetto illustra la transizione strategica da una costosa soluzione tradizionale basata su Windows Server verso un'architettura moderna, ibrida e interamente open-source.
L'ambiente ottimizza le risorse hardware combinando servizi di rete nativi (bare-metal) per l'identità e applicazioni containerizzate per la produttività.

🛠️ Architettura e Stack Tecnologico

Il cuore dell'infrastruttura è ospitato su una singola macchina virtuale altamente ottimizzata, con un consumo a riposo (idle) di appena ~1.0 GiB di RAM.
Sistema Operativo: Debian 12 Bookworm (installazione minimale CLI-only) per ridurre la superficie d'attacco.
Identity & Access Management: Samba 4 configurato nativamente sull'host come Active Directory Domain Controller (AD DC).
Container Engine: Docker & Docker Compose con isolamento dei privilegi.
Cloud Privato & Sincronizzazione: Nextcloud Hub supportato da un database PostgreSQL 16 (immagine Alpine ultra-leggera).
Gestione Password: Vaultwarden (API Bitwarden in Rust) blindato con certificati SSL/TLS autogenerati (validità 10 anni).
Networking & VPN: Nginx Reverse Proxy e WireGuard VPN orchestrati con regole iptables di NAT e Masquerade.
Amministrazione di Sistema: Accesso SSH tramite chiavi asimmetriche (password disabilitate) e gestione visiva tramite Cockpit Web Console.

🗺️ Roadmap di Migrazione (Le 5 Fasi)

Il progetto è stato sviluppato seguendo 5 macro-fasi logiche, risolvendo criticità storiche delle infrastrutture SMB:
1. Fondamenta e Rete
Sostituzione del server Windows tradizionale con un server Linux minimale (Ubuntu/Debian) dotato di Docker. Assegnazione di IP statico e integrazione dell'ambiente di sviluppo tramite VSCodium Remote-SSH.
2. Identità Centralizzata (Single Sign-On Ibrido)
Superamento di Microsoft AD tramite l'inizializzazione di Samba 4 AD DC. È stato creato il dominio locale hcdebian02.local. L'infrastruttura gestisce un'unica identità centralizzata: Nextcloud interroga dinamicamente il database LDAP di Samba, permettendo agli utenti di accedere al PC e al cloud con le medesime credenziali.
3. Condivisione File Moderna e Bypass SMB
Evoluzione dei vecchi File Server: le condivisioni di rete SMB sono state abbandonate in favore della sincronizzazione tramite client Nextcloud. Questa scelta azzera i colli di bottiglia prestazionali di SMB in User Space su Linux e neutralizza i conflitti logici legati agli errori di "Accesso Negato" delle ACL incrociate tra Windows e Linux.
4. Backup e Protezione Anti-Ransomware
In alternativa a costosi NAS proprietari e Veeam, il Disaster Recovery si affida a due livelli di protezione: 
Livello Infrastruttura: Snapshot completi a livello di hypervisor (VMware).
Livello Dati: Funzionalità integrate di Versionamento Storico e Cestino di Nextcloud, che garantiscono il ripristino istantaneo dei documenti in caso di attacco distruttivo (es. cryptolocker).
5. Smart Working, VPN e GPO Tuning
Accesso Esterno: Configurazione di un tunnel WireGuard per simulare client remoti in Smart Working , con instradamento del traffico verso l'infrastruttura Docker tramite regole DNAT e Nginx Reverse Proxy.
Hardening Client Windows: Distribuzione di GPO personalizzate (Lab Performance Optimization) per la piallatura del bloatware, la disattivazione della telemetria, l'ottimizzazione degli effetti visivi e lo spegnimento dei servizi superflui.

🔒 Sicurezza e Isolamento di Rete

Per prevenire conflitti logici e garantire la stabilità:
Samba AD DC è stato vincolato in ascolto esclusivo sull'interfaccia LAN dell'host fisico (bind interfaces only = yes), evitando sovrapposizioni con il bridge di Docker (172.17.0.1).
Le regole di routing interne dei container comunicano con il DNS autoritativo Kerberos tramite il file resolv.conf reindirizzato localmente, pur mantenendo forwarder esterni sicuri.