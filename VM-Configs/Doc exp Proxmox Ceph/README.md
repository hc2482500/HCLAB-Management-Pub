# 🚀 Nested Hyperconverged Lab: Proxmox VE & Ceph

Questo progetto documenta la progettazione, il deployment e la validazione di un'infrastruttura iperconvergente (HCI) di livello Enterprise, realizzata da zero sfruttando la *Nested Virtualization* (virtualizzazione nidificata) su VMware Workstation[cite: 9]. 

L'architettura si basa su un cluster Proxmox VE a tre nodi, supportato da uno storage distribuito e replicato **Ceph** e configurato per l'Alta Affidabilità (HA)[cite: 9].

---

## 🏗️ Topologia dell'Infrastruttura

Per evitare colli di bottiglia e ottimizzare le risorse del computer host (180 GB disponibili), le risorse sono state allocate con precisione tramite Thin Provisioning[cite: 9]. La rete separa il traffico di gestione da quello storage[cite: 9].

| Parametro | Nodo 1 | Nodo 2 | Nodo 3 |
| :--- | :--- | :--- | :--- |
| **IP Management (NAT)** | `192.168.79.172` | `192.168.79.173` | Variabile DHCP |
| **IP Rete Ceph (Host-Only)** | `10.0.0.1/24` | `10.0.0.2/24` | `10.0.0.3/24` |
| **Storage (Thin Provisioning)** | 20 GB (OS) + 25 GB (OSD) | 20 GB (OS) + 25 GB (OSD) | 20 GB (OS) + 25 GB (OSD) |

---

## 🎯 Obiettivi Raggiunti e Validazioni

Il laboratorio è stato suddiviso in diverse fasi di implementazione e stress-test per convalidare le dinamiche di un vero datacenter.

### 1. Alta Affidabilità (HA), Quorum e Split-Brain
*   **Live Migration:** Migrazione a caldo della VM 100 ("Test-DebXfce") tra nodi senza alcuna perdita di pacchetti di rete[cite: 9].
*   **Failover HA:** In seguito allo spegnimento forzato di un nodo, il cluster ha isolato il guasto tramite fencing (60-90 secondi) e riavviato automaticamente la VM su un nodo sano[cite: 9].
*   **Quorum & Split-Brain:** È stata dimostrata la regola della maggioranza assoluta. La perdita simultanea di due nodi ha causato il blocco istantaneo (congelamento) del cluster superstite per proteggere l'integrità dei dati ed evitare scenari di split-brain[cite: 9].

### 2. Implementazione CephFS (MDS)
*   Oltre allo storage a blocchi (RBD), è stato configurato un file system condiviso (CephFS) per centralizzare immagini ISO, template LXC e file di backup VZDump[cite: 8, 9].
*   Per gestire l'albero delle directory senza Single Point of Failure (SPOF), è stato distribuito un **Metadata Server (MDS)** su ciascun nodo (1 nodo in stato `active`, 2 in stato `up:standby` pronti al failover)[cite: 8, 9].

### 3. Snapshot e Copy-on-Write (CoW)
*   Sfruttando l'architettura nativa di Ceph, è stato testato l'uso di snapshot istantanei a impatto zero sullo storage[cite: 8, 9].
*   **Simulazione:** Scattata un'istantanea a caldo della VM ("Prima_del_disastro"), eliminato un file critico per corrompere il sistema e azionato il *Rollback*[cite: 8, 9]. Il ripristino è avvenuto in meno di un secondo riallineando i puntatori dei blocchi[cite: 8, 9].

### 4. Manutenzione Sicura e Flag `noout`
*   In Ceph, un nodo offline per oltre 10 minuti innesca un rebalancing massivo dei dati che può saturare la rete[cite: 8, 9]. 
*   È stata validata la procedura per la manutenzione hardware attivando il flag globale **`noout`** (forzando il cluster in `HEALTH_WARN`), istruendo l'algoritmo a non ricalcolare la CRUSH map e congelando lo spostamento dei dati fino al rientro del nodo[cite: 8, 9].

### 5. Backup Iperconvergenti
*   Integrazione del motore nativo Proxmox (`vzdump`) con lo spazio distribuito CephFS[cite: 8, 9].
*   I dati sono protetti doppiamente: salvati come archivio contro corruzioni del sistema operativo guest, e replicati intrinsecamente dall'algoritmo di Ceph contro i guasti fisici dei nodi sottostanti[cite: 8].

---

## 🛠️ Enterprise Troubleshooting & Security Evasion

La messa in opera ha richiesto competenze di troubleshooting avanzato per aggirare ostacoli di virtualizzazione e policy EDR/VPN aziendali:

*   **Conflitto Hyper-V vs VMware:** Risolto l'errore `Module HV power on failed` disabilitando il Core Isolation di Windows (Memory Integrity) e bloccando l'hypervisor Microsoft tramite il comando `bcdedit /set hypervisorlaunchtype off`[cite: 9].
*   **Networking e DPI Bypass:** Per consentire l'accesso esterno alla WebGUI (8006), il semplice Port Forwarding su VMware NAT si è scontrato con difese perimetrali severe. È stata analizzata l'impossibilità di stabilire connessioni in ingresso a causa di:
    *   Sistemi **EDR** (Sophos Endpoint con Tamper Protection e HP Wolf Security)[cite: 9].
    *   **Client Isolation** e routing forzato causati dalla VPN aziendale (FortiClient VPN)[cite: 9].
    *   Policy di Deep Packet Inspection (DPI) e anti-Shadow IT che hanno bloccato i tentativi di tunneling inverso tramite **Ngrok**[cite: 9].
    *   *Risoluzione:* Analisi e riconoscimento dei vincoli architetturali non aggirabili per policy, optando per il remote control autorizzato via Microsoft Teams/Assistenza Rapida[cite: 9].