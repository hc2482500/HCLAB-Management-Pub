# Documentazione Tecnica: Laboratorio Active Directory hclab02

Questa documentazione traccia l'architettura, i servizi e le procedure di ripristino per l'infrastruttura Microsoft del laboratorio, gestita con metodologia Infrastructure as Code (IaC) e salvata su GitHub. L'infrastruttura si basa su Windows Server Core e un client Windows 10 Pro.

## 1. Architettura dell'Infrastruttura Base

*   **Ruolo Principale:** Domain Controller, DNS, File Server
*   **Sistema Operativo:** Windows Server 2019 Core (Senza GUI per minor superficie di attacco)
*   **Nome Server:** HC02
*   **Dominio:** `hclab02.local` (Livello Funzionale 2019/2022)
*   **Indirizzo IP DC:** 192.168.79.21 (Scheda di rete dedicata)
*   **Client di Test:** WinClient (Windows 10 Pro ENG) - IP 192.168.79.15
*   **Metodo di Gestione:** Remota tramite RSAT (Remote Server Administration Tools) da client Windows 10 Pro, WinRM, PowerShell e WAC.

## 2. Gestione dell'Infrastruttura: Windows Admin Center (WAC)

**Cos'è e a cosa serve**
Windows Admin Center (WAC) è uno strumento di gestione basato su browser, distribuito localmente, che consente di amministrare server Windows, cluster, infrastrutture iperconvergenti e PC client. Fornisce un'interfaccia web moderna e centralizzata per la gestione remota dell'infrastruttura (monitoraggio risorse, certificati, ruoli, servizi), sostituendo le console MMC e riducendo la dipendenza dalla riga di comando.

**Raccomandazioni e Best Practice sull'Installazione**
*   **Fortemente Sconsigliato su Domain Controller:** L'installazione di WAC all'interno di un'istanza Windows Server Core è fortemente sconsigliata se il server sta per essere promosso (o è già) Domain Controller. La coesistenza causa inutili complicanze tecniche, conflitti di gestione e mal di testa a livello amministrativo.
*   **Server Core Pulito:** Si raccomanda categoricamente di installare WAC su un Windows Server Core "pulito" dedicato esclusivamente al ruolo di gateway/gestione WAC.
*   **Mai mescolare i ruoli:** Mai installare un DC dentro un Server Core con WAC già in esecuzione, e viceversa.

## 3. Fasi di Implementazione

### Fase 1: Preparazione e Manutenzione del Server
Prima di rendere operativo il Domain Controller, il sistema è stato messo in sicurezza:
*   **Installazione Aggiornamenti:** Applicazione di patch critiche (kernel, .NET Framework).
*   **Patching Hardware-Level:** Aggiornamento del microcodice Intel (KB4589208) per vulnerabilità CPU.
*   **Gestione Riavvi:** Allineamento dei servizi DNS e AD DS post-installazione.

### Fase 2: Configurazione Logica di Active Directory
L'organizzazione degli oggetti separa utenti amministrativi da standard:
*   **Creazione OU:** `OU_Admins`, `OU_Computer`, `OU_Utenti`.
*   **Creazione Utenti:** Provisioning di `mario.rossi`, `user.test01` e `HC Admin 02`.
*   **Gestione Oggetti:** Migrazione utenti dal container predefinito alla nuova OU tramite PowerShell:
    ```powershell
    Get-ADUser user.test01 | Move-ADObject -TargetPath "OU=OU_Utenti,DC=hclab02,DC=local"
    ```

### Fase 3: Strumenti di Amministrazione (RSAT)
Il client Windows 10 Pro è stato promosso a console di gestione remota:
*   **Installazione RSAT:** GPMC installata tramite modulo capability:
    ```powershell
    Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
    ```

### Fase 4: Implementazione Criteri di Gruppo (GPO)
Creazione e collegamento delle GPO alle unità organizzative:
*   **Sicurezza:** `BLINDATURA_AppLocker`, `Security_Block_Powershell`, `Audit_Files` e blocco del Pannello di Controllo.
*   **Automazione e RDP:** Configurazione RDP per servizi remoti, apertura porta 3389 sul firewall e iniezione dinamica utenti in 'Remote Desktop Users' via GPP.
*   **Utenti:** `MAP_Disco_Z` e `Folder_Redirection_Documenti`.

## 4. Infrastructure as Code (IaC) e Scripting

Tutta la configurazione logica del server è versionata su GitHub in `VM-Configs\Windows-Server-HC02\`.

**Struttura Repository:**
*   `Scripts/`: Moduli di automazione PowerShell.
    *   Gestione GPO: `Export-GPOs.ps1`, `Restore-GPOs.ps1`
    *   Automazione SSL: `fastssl-ssl-cert-auto.ps1`, `IIS-SSL-Hunter.ps1`
    *   File Server: `Deploy-FileShares.ps1`
    *   Manutenzione: `check_pcfantasmi_dominio.ps1`
*   `GPO_Backups/`: Backup grezzo delle policy estrapolato tramite RSAT.
*   `AD_Structure/`: Struttura delle OU esportata in CSV.
*   `DNS_Config/`: Record DNS esportati in CSV.

## 5. Procedura di Disaster Recovery

In caso di perdita totale del Domain Controller (HC02), il ripristino avviene tramite i seguenti passaggi automation-driven:
1.  Installare un nuovo Windows Server 2019 Core e assegnare un IP statico (es. `192.168.79.21`).
2.  Promuovere il server a Domain Controller creando il nuovo dominio `hclab02.local`.
3.  Clonare il repository GitHub sul client amministrativo Windows 10.
4.  Ripristinare la struttura logica (OU) basandosi sul file CSV in `AD_Structure`.
5.  Creare l'infrastruttura cartelle e condivisioni (es. Dati_Z, IT_Admin) eseguendo `Deploy-FileShares.ps1`.
6.  Ripristinare le Group Policy tramite PowerShell:
    ```powershell
    .\Restore-GPOs.ps1
    ```
7.  Collegare manualmente le GPO ripristinate alle rispettive OU tramite GPMC.
8.  Ripristinare i dati utente nelle share dal backup di rete (NAS/S3).
