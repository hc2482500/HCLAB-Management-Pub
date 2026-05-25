#!/bin/bash

export TZ="Europe/Rome"

# --- CONFIGURAZIONE ---
# Indirizzo email di destinazione secondario
EMAIL_DEST="<email-privata-oscurata>" 
DATE_STR=$(date +%Y%m%d_%H%M)
DATE_FORMATTED=$(date +'%d/%m/%Y %H:%M')

# --- DIRECTORY DI BACKUP ---
BACKUP_DIR="/home/hcdebian/backups"
mkdir -p "$BACKUP_DIR"

# --- NOMI DEI FILE DI BACKUP ---
# Unificato in un unico file "Full Backup"
BACKUP_ALL="$BACKUP_DIR/hcdebian_full_backup_ext_${DATE_STR}.bak"
TEMP_SQL="/tmp/odoo_dump.sql"

echo "Avvio creazione backup unificato per invio a $EMAIL_DEST..."

# --- 0. PRE-BACKUP (DUMP DATABASE ODOO) ---
# Estrazione pulita del database prima dello zip
docker exec odoo_db pg_dump -U odoo postgres > "$TEMP_SQL" 2>/dev/null
if [ $? -eq 0 ]; then DB_STATUS="OK"; else DB_STATUS="ERRORE"; fi

# --- 1. CREAZIONE BACKUP UNIFICATO ---
# 1.1 Inseriamo tutte le cartelle di configurazione e gli script
zip -rq "$BACKUP_ALL" \
    /home/hcdebian/scripts \
    /home/hcdebian/nginx/default.conf \
    /home/hcdebian/homer/assets/config.yml \
    /home/hcdebian/prometheus/prometheus.yml \
    /home/hcdebian/loki/loki-config.yaml \
    /home/hcdebian/promtail/promtail-config.yaml \
    /home/hcdebian/grafana \
    /home/hcdebian/mio-frontend \
    /home/hcdebian/homelab \

# 1.2 Aggiungiamo il dump SQL all'interno dello stesso archivio
zip -rqj "$BACKUP_ALL" "$TEMP_SQL"
rm -f "$TEMP_SQL"

# --- 2. RACCOLTA DATI APT (CRONOLOGICA) ---
# Estrae i pacchetti installati manualmente dal più vecchio al più nuovo (formato testo)
APT_LIST_TEXT=$(zgrep -h -E '^Commandline: (apt|apt-get) install' $(ls -tr /var/log/apt/history.log* 2>/dev/null) 2>/dev/null | \
                sed -E 's/^Commandline: (apt|apt-get) install //g' | \
                sed -E 's/ -[a-zA-Z0-9-]+//g' | \
                tr -s ' ' '\n' | \
                grep -v '^$' | \
                awk '!seen[$0]++' | \
                nl -s '. ') # Aggiunge la numerazione (1. 2. 3...)

# --- 3. INVIO EMAIL ---
echo "Generazione email e invio allegato..."

# Corpo dell'email in formato testo semplice
EMAIL_BODY="Report Backup Esterno - hcdebian
Data: $DATE_FORMATTED
Stato Database Odoo: $DB_STATUS

In allegato trovi l'archivio unico contenente:
- Configurazioni Docker (YAML)
- Script di sistema
- Configurazione Nginx e Dashboard
- Dump SQL Database Odoo

--------------------------------------------------
STORICO PACCHETTI APT (Dal più vecchio al più nuovo):
--------------------------------------------------
$APT_LIST_TEXT

🤖 Inviato in automatico da hcdebian"

# Invio tramite mutt (un solo allegato)
echo "$EMAIL_BODY" | mutt -s "Backup Homelab Esterno Unificato - $DATE_FORMATTED" \
     -a "$BACKUP_ALL" \
     -- "$EMAIL_DEST"

# --- 4. PULIZIA ---
# Mantiene solo i backup degli ultimi 7 giorni
find "$BACKUP_DIR" -name "*.bak" -type f -mtime +7 -exec rm {} \;

echo "✅ Backup unificato inviato con successo a $EMAIL_DEST!"