# 🌐 Advanced Enterprise & ISP Network Simulation Lab

Benvenuti nella repository del mio laboratorio di simulazione di rete avanzata. Questo progetto dimostra la progettazione, l'implementazione e il troubleshooting di un'infrastruttura di rete completa, partendo dalle fondamenta di Switching (Layer 2) fino ad arrivare al core routing MPLS tipico dei Service Provider (Layer 3/4), integrando sicurezza perimetrale e Quality of Service.

Il laboratorio è stato interamente virtualizzato sfruttando la nested virtualization su Proxmox VE, ottimizzando al massimo il consumo di risorse tramite l'uso intensivo di container LXC leggeri e macchine virtuali mirate[cite: 2, 3].

---

## 🏗️ Topologia e Nodi dell'Infrastruttura

La rete è segmentata in diverse VLAN e VRF per garantire l'isolamento dei domini di broadcast e delle tabelle di routing dei clienti[cite: 1, 2].

| Hostname | Sistema Operativo | Ruolo Principale | Risorse (RAM) | Tecnologie Chiave |
| :--- | :--- | :--- | :--- | :--- |
| **pve** | Proxmox VE (Debian) | Hypervisor / L2 Switch | 8 GB | Nested Virt, Linux Bridge, VLAN-aware[cite: 2] |
| **router-core** | Alpine Linux (LXC) | Core Router & DDI | 512 MB | FRRouting, OSPF, LDP, MP-BGP, DHCP/DNS[cite: 1, 2] |
| **router-site2** | Alpine Linux (LXC) | Branch Router | 256 MB | FRRouting, OSPF[cite: 1, 2] |
| **vyos-pe1** | VyOS (VM) | Provider Edge Router | 512 MB | MPLS, L3VPN (VRF), MP-BGP, Traffic Shaping[cite: 1, 2] |
| **opnsense-fw**| OPNsense (FreeBSD) | Next-Gen Firewall | 1.5 GB | Inline IPS (Netmap), OpenVPN, NAT[cite: 2, 3] |
| **client1/2** | Alpine Linux (LXC) | End-Device di test | 128 MB | SSH, ICMP, iperf3[cite: 2] |

---

## 🚀 Fasi del Progetto e Tecnologie Implementate

### Fase 1: Switching e Segmentazione (Layer 2)
* Creazione di uno switch virtuale isolato (`vmbr1`) con supporto ai tag 802.1Q (VLAN aware)[cite: 2, 3].
* Segmentazione del traffico in VLAN dedicate (VLAN 10, 20, 30 per reti interne, VLAN 100/110/200 per reti di transito)[cite: 2].

### Fase 2: Routing Dinamico e Servizi DDI (Layer 3)
* Configurazione del routing inter-VLAN tramite abilitazione dell'IP Forwarding a livello kernel Linux[cite: 2, 3].
* Erogazione di servizi DHCP e DNS locale tramite `dnsmasq`[cite: 2].
* Scambio dinamico delle rotte interne tramite il protocollo **OSPF** (Area 0) utilizzando la suite **FRRouting**[cite: 2].

### Fase 3: Sicurezza Perimetrale e Accesso Remoto
* Implementazione di regole di firewalling e Hybrid Outbound NAT per l'accesso controllato a Internet[cite: 2, 3].
* Creazione di una Public Key Infrastructure (PKI) per l'accesso remoto sicuro tramite **OpenVPN**[cite: 2].
* Analisi profonda dei pacchetti: attivazione del motore **Suricata IPS** in modalità *Inline* (Netmap live mode) con oltre 2.400 firme attive per il blocco (Drop) automatico delle minacce[cite: 2, 3].

### Fase 4: Simulazione WAN, Core MPLS e Quality of Service (QoS)
* **Underlay Network:** Sincronizzazione delle interfacce Loopback e distribuzione delle etichette tramite protocollo **LDP**[cite: 2].
* **Overlay Network & L3VPN:** Instaurazione di una sessione iBGP (AS 65000) per il trasporto della famiglia VPNv4/IPv4-vpn[cite: 2]. Isolamento logico del traffico cliente tramite **VRF (Virtual Routing and Forwarding)**[cite: 2, 3].
* **Traffic Shaping (CoS/QoS):** Limitazione della banda globale a 10 Mbps. Creazione di code di priorità rigorose per garantire latenze minime (bufferbloat assente) al traffico ICMP/Voice (2 Mbps dedicati, classe 10), penalizzando il traffico Best Effort in caso di congestione (cappato a 8 Mbps)[cite: 2, 3].

### Fase 5: Monitoraggio e Visibilità
* Deep Packet Inspection su incapsulamento MPLS e flag PHP (Bottom of Stack) tramite `tcpdump`[cite: 2, 3].
* Centralizzazione dell'auditing tramite inoltro remoto di **Syslog** (Porta 514)[cite: 2].
* Abilitazione della telemetria **SNMPv2c** sui nodi core[cite: 2, 3].

---

## 🔧 Esempi di Configurazione (Repository Content)

In questa repository pubblica sono resi disponibili degli *snippet* di configurazione sanitizzati (`.example`) e documenti architetturali. I file mostrano le implementazioni reali utilizzate nel laboratorio:

1. **`pve_network.example`**: Configurazione del bridge VLAN-aware su host Proxmox.
2. **`sysctl_mpls.example.conf`**: Tuning del kernel Linux per il supporto al data plane MPLS.
3. **`frr_core_bgp_mpls.example.conf`**: Sintassi FRRouting per l'integrazione tra OSPF, LDP e BGP Route Leaking tra VRF.
4. **`vyos_qos_shaper.example.txt`**: Configurazione ad albero del Traffic Shaper su VyOS.
5. **Documentazione PDF**: Roadmap completa del progetto e Registro Logico delle attività e del troubleshooting.

---

## 🛠️ Highlights di Troubleshooting Avanzato

Durante l'implementazione sono state risolte sfide tecniche complesse, documentate nel registro attività, tra cui:
* **Route Leaking BGP su VRF:** Risoluzione di conflitti anti-loop calibrando in modo asimmetrico i *Route Distinguisher* e sincronizzando i *Route Target* incrociati tra nodi VyOS e Alpine[cite: 2].
* **Iniezione Moduli Kernel:** Attivazione a caldo dei moduli `mpls_router` e `mpls_iptunnel` e configurazione delle direttive di *input* per l'elaborazione hardware delle etichette MPLS in ambiente containerizzato[cite: 2].
* **Bypass Offloading Hardware:** Risoluzione dell'evasione dei pacchetti da parte dell'IPS Suricata disattivando le funzioni di CRC/TSO/LRO sulla scheda di rete virtuale (vtnet) di FreeBSD[cite: 2].