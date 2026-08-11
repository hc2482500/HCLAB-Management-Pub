# 🧠 Enterprise Local AI & Private Cloud (RAG & DLP)

Benvenuti nel mio progetto di integrazione tra archiviazione cloud privata e Intelligenza Artificiale generativa locale. 

Questo repository documenta l'architettura, il deployment e la messa in sicurezza di uno stack applicativo avanzato basato su **Nextcloud Hub**, **Ollama**, **Open WebUI** e un microservizio custom Python/FastAPI per la **Data Loss Prevention (DLP)**[cite: 6, 7]. L'intero stack esegue inferenza IA interamente in locale (CPU-only, senza dipendenze da API cloud esterne), garantendo la massima riservatezza dei dati aziendali[cite: 6].

> **Nota sull'Infrastruttura:** L'underlay infrastrutturale (il cluster iperconvergente Proxmox VE a 3 nodi con storage distribuito Ceph e rete isolata) è stato progettato e implementato dal team infrastrutturale. Il mio lavoro si concentra interamente sul livello Layer 7 (Applicativo, IA, Integrazione RAG e Sicurezza Web)[cite: 6].

---

## 🏗️ Topologia Applicativa

Il progetto si articola su due Macchine Virtuali principali, basate su Debian GNU/Linux 13 ed eseguite in containerizzazione Docker[cite: 6, 7].

| Hostname | IP | Ruolo Principale | Stack Tecnologico | Risorse |
| :--- | :--- | :--- | :--- | :--- |
| **P0-LAB-AI-SRV01** | `10.250.250.104` | AI Inference, RAG & DLP Proxy | Docker, Ollama, Open WebUI, Python/FastAPI | 16 vCPU, 64 GB RAM |
| **P0-LAB-LIN-NC01** | `10.250.250.108` | Private Cloud & Assistant | Docker, Nextcloud, Postgres, Nginx | 8 vCPU, 16 GB RAM |

---

## 🚀 Componenti Architetturali e Soluzioni Tecniche

### 1. Motore IA Locale e Modelli (VM 107)
Il motore di inferenza è gestito tramite **Ollama**, sfruttando l'accelerazione CPU (AVX2, FMA, BMI2) per garantire performance di `21.72 t/s` in valutazione prompt e `1.70 t/s` in generazione (benchmark su `llama3.1:8b`)[cite: 6].
*   **Modelli implementati:** `qwen2.5-coder:7b` per sviluppo/refactoring, `gemma2:9b` per analisi logica complessa, `llama3.1:8b` per task rapidi e `nomic-embed-text` per l'embedding vettoriale[cite: 6, 7].
*   **Networking:** Ottimizzazione dei download concorrenti dei pesi tramite customizzazione di `/etc/docker/daemon.json`[cite: 7] e protezione del traffico tramite `nftables` in modalità default DROP[cite: 7].

### 2. Privacy Sanitizer Proxy - DLP (VM 107)
Per prevenire l'esposizione di PII (Personally Identifiable Information) o segreti industriali, ho sviluppato un microservizio middleware in **Python (FastAPI/Uvicorn)**[cite: 6].
*   **Funzionamento:** Intercetta le richieste e analizza i documenti. Tramite un mix di Espressioni Regolari (per IP, Email, PIN) e inferenza NLP tramite il modello `qwen2.5:7b` (per nomi di progetti e aziende in *CamelCase*), bonifica il testo prima dell'elaborazione[cite: 6].
*   **Parsing nativo:** Supporto nativo per file binari sfruttando le librerie `python-multipart`, `python-docx` e `odfpy`. Il proxy ricostruisce i file `.docx` e `.odt` preservando la struttura in paragrafi originale prima di fornirli all'utente tramite una dashboard HTML drag&drop[cite: 6].

### 3. Integrazione RAG su Nextcloud Hub (VM 108)
L'archivio aziendale risiede su uno stack Nextcloud. L'integrazione RAG (Retrieval-Augmented Generation) è stata affrontata su due fronti:
*   **Livello Filesystem:** Montaggio bidirezionale tramite `davfs2` della cartella WebDAV di Nextcloud direttamente su `/mnt/nextcloud_rag` della VM IA, esponendo la Knowledge Base a Open WebUI[cite: 6, 7].
*   **Livello Applicativo:** Configurazione dell'app *Nextcloud Assistant*. Per aggirare i vincoli di sicurezza sui redirect interni (SSRF protection), ho forzato le policy tramite comandi `occ`:
    ```bash
    # Abilitazione delle query HTTP locali verso le API di Ollama
    occ config:system:set allow_local_remote_servers --type=bool --value=true
    ```
*   **Elaborazione Asincrona:** Per prevenire i timeout HTTP dovuti ai tempi di inferenza su CPU, l'esecuzione dei task di Nextcloud è stata demandata a un `cronjob` di sistema anziché al demone web[cite: 6, 9].

### 4. Hardening Web e Reverse Proxy (VM 108)
Il traffico verso Nextcloud è gestito da un reverse proxy **Nginx** (containerizzato). L'infrastruttura implementa best practice rigorose per la sicurezza Layer 7[cite: 8, 9]:
*   Gestione profonda dell'header tramite direttive esplicite:
    *   `Strict-Transport-Security "max-age=15552000; includeSubDomains"`
    *   `X-Frame-Options "SAMEORIGIN"`
    *   `X-XSS-Protection "1; mode=block"`
    *   `X-Robots-Tag "none"`
*   Fix del mapping degli IP e risoluzione di *trusted proxies* per il corretto funzionamento dietro firewall aziendali[cite: 8, 9].

---

## 📂 Struttura della Repository

In questa repository pubblica sono disponibili snippet di codice e configurazioni sanitizzate (`.example`), utili a comprendere le logiche di implementazione:

*   `/sanitizer-proxy/`: Il codice sorgente Python/FastAPI del microservizio DLP, completo di Dockerfile e parser per documenti.
*   `/docker/`:
    *   `docker-compose-ai.example.yml`: Stack di orchestrazione Ollama/Open WebUI.
    *   `docker-compose-nextcloud.example.yml`: Stack di orchestrazione Cloud privato.
*   `/security/`:
    *   `nginx-secure.example.conf`: Configurazione di hardening del reverse proxy.
    *   `nftables.example.conf`: Regole di chiusura porte e masquerade per i container.
*   `/scripts/`: Script bash per l'auditing e la telemetria di sistema.