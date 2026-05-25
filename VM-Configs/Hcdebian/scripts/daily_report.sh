#!/bin/bash

# --- CORREZIONE FUSO ORARIO ---
# Forza l'orario sull'area di Roma (gestisce automaticamente ora legale/solare)
export TZ="Europe/Rome"

# --- CONFIGURAZIONE ---
EMAIL_DEST="<inserire-email-aziendale-oscurata>"
REPORT_HTML="/tmp/report.html"
DATE=$(date +'%d/%m/%Y %H:%M')
DATE_STR=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/home/hcdebian/backups"

# --- NOME DEL FILE DI BACKUP (Formato .tar.gz) ---
BACKUP_ALL="$BACKUP_DIR/hcdebian_full_backup_${DATE_STR}.tar.gz"
TEMP_SQL="/tmp/odoo_dump.sql"
TEMP_VW="/tmp/vaultwarden_backup.tar.gz"

echo "Avvio generazione report e backup per hcdebian ($DATE)..."

# --- 0. PRE-BACKUP (DUMP DATABASE E VOLUMI) ---
mkdir -p "$BACKUP_DIR"

echo "Esecuzione dump database Odoo..."
docker exec odoo_db pg_dump -U odoo postgres > "$TEMP_SQL" 2>/dev/null
if [ $? -eq 0 ]; then 
    DB_STATUS="✅ SQL Dump Pronto"
    echo "✅ Dump database Odoo completato con successo."
else 
    DB_STATUS="❌ Errore Dump SQL"
    echo "❌ Errore durante il dump del database Odoo."
fi

echo "Esecuzione backup Vaultwarden..."
docker exec vaultwarden tar -cz -C /data . > "$TEMP_VW" 2>/dev/null
if [ $? -eq 0 ]; then 
    VW_STATUS="✅ Vaultwarden Pronto"
    echo "✅ Backup Vaultwarden completato con successo."
else 
    VW_STATUS="❌ Errore Vaultwarden"
    echo "❌ Errore durante il backup di Vaultwarden."
fi

# --- 1. CREAZIONE ARCHIVIO UNICO (.tar.gz) ---
echo "Creazione archivio unico di backup: $(basename "$BACKUP_ALL")..."

# Usiamo tar con opzione -czf (.tar.gz)
# Escludiamo file di log e cache per ridurre le dimensioni
tar -czf "$BACKUP_ALL" \
    --exclude="*.log" \
    --exclude="__pycache__" \
    --exclude="*.tmp" \
    /home/hcdebian/scripts \
    /home/hcdebian/nginx/default.conf \
    /home/hcdebian/homer/assets/config.yml \
    /home/hcdebian/prometheus/prometheus.yml \
    /home/hcdebian/loki/loki-config.yaml \
    /home/hcdebian/promtail/promtail-config.yaml \
    /home/hcdebian/grafana \
    /home/hcdebian/mio-frontend \
    /home/hcdebian/homelab \
    -C /tmp odoo_dump.sql vaultwarden_backup.tar.gz

# Pulizia file temporanei dopo l'archiviazione
rm -f "$TEMP_SQL" "$TEMP_VW"

# --- 2. RACCOLTA DATI PER IL REPORT ---
# Stato Nginx
NGINX_CHECK=$(docker exec nginx-proxy nginx -t 2>&1 | grep "test is successful" > /dev/null && echo "OPERATIVO" || echo "ERRORE")
NGINX_COLOR="#bbf7d0"; if [ "$NGINX_CHECK" != "OPERATIVO" ]; then NGINX_COLOR="#fca5a5"; fi

# Disco
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
DISK_COLOR="#ffffff"; if [ "$DISK_USAGE" -gt 85 ]; then DISK_COLOR="#fca5a5"; fi 

# Container Status
DOCKER_ROWS=$(docker ps --format "<tr><td style='border-bottom: 1px solid rgba(255,255,255,0.1); padding: 8px 5px;'>{{.Names}}</td><td style='border-bottom: 1px solid rgba(255,255,255,0.1); padding: 8px 5px; color: #bbf7d0;'>{{.Status}}</td></tr>")

# Lista pacchetti installati
APT_PACKAGES_HTML=$(zgrep -h -E '^Commandline: (apt|apt-get) install' $(ls -tr /var/log/apt/history.log* 2>/dev/null) 2>/dev/null | \
                    sed -E 's/^Commandline: (apt|apt-get) install //g' | \
                    sed -E 's/ -[a-zA-Z0-9-]+//g' | \
                    tr -s ' ' '\n' | \
                    grep -v '^$' | \
                    awk '!seen[$0]++' | \
                    awk '{print "<li style=\"margin-bottom: 4px;\">" $1 "</li>"}')

if [ -z "$APT_PACKAGES_HTML" ]; then 
    APT_PACKAGES_HTML="<li>Nessun pacchetto rilevato nei log</li>"
fi

# --- 3. COSTRUZIONE HTML ---
cat <<EOF > $REPORT_HTML
<html>
<body style="font-family: 'Segoe UI', Tahoma, sans-serif; background-color: #16a34a; padding: 20px; color: white;">
    <div style="max-width: 700px; margin: auto;">
        <h2 style="margin-bottom: 5px;">Centrale hcdebian</h2>
        <p style="opacity: 0.8; margin-top: 0;">Report Completo - $DATE</p>

        <div style="background: #15803d; padding: 15px; border-radius: 15px; margin-bottom: 15px; font-weight: bold; font-size: 0.95rem;">
            <div style="margin-bottom: 8px;">Nginx Proxy: <span style="color: $NGINX_COLOR;">$NGINX_CHECK</span></div>
            <div style="margin-bottom: 8px;">Database Odoo: <span style="color: #bbf7d0;">$DB_STATUS</span></div>
            <div>Vaultwarden: <span style="color: #bbf7d0;">$VW_STATUS</span></div>
        </div>

        <div style="background: #15803d; padding: 20px; border-radius: 15px; margin-bottom: 15px;">
            <div style="font-size: 0.8rem; opacity: 0.8; text-transform: uppercase;">Storage di Sistema</div>
            <div style="font-size: 1.1rem; margin: 8px 0;">$(df -h / | tail -1 | awk '{print $4 " liberi su " $2}')</div>
            <div style="background: rgba(0,0,0,0.2); height: 8px; border-radius: 4px; overflow: hidden;">
                <div style="width: $DISK_USAGE%; background: $DISK_COLOR; height: 100%;"></div>
            </div>
        </div>

        <div style="background: #15803d; padding: 20px; border-radius: 15px; margin-bottom: 15px;">
            <div style="font-size: 0.8rem; opacity: 0.8; text-transform: uppercase; margin-bottom: 10px;">Stato Container</div>
            <table style="width: 100%; font-size: 12px; border-collapse: collapse;">
                $DOCKER_ROWS
            </table>
        </div>

        <div style="background: #15803d; padding: 20px; border-radius: 15px; margin-bottom: 15px;">
            <div style="font-size: 0.8rem; opacity: 0.8; text-transform: uppercase; margin-bottom: 15px;">🛠️ Storico Installazioni (Dal più vecchio al più nuovo)</div>
            <ol style="font-size: 11px; color: #dcfce7; column-count: 3; column-gap: 20px; margin: 0; padding-left: 20px; line-height: 1.4; list-style-position: inside;">
                $APT_PACKAGES_HTML
            </ol>
        </div>

        <div style="text-align: center; font-size: 11px; opacity: 0.7; margin-top: 20px;">
            💾 Backup Allegato: <strong>hcdebian_full_backup_${DATE_STR}.tar.gz</strong><br>
            (Configurazioni, Frontend, Grafana, Odoo SQL e Database Vaultwarden inclusi)
        </div>
    </div>
</body>
</html>
EOF

# --- 4. INVIO ---
echo "Invio email in corso a $EMAIL_DEST..."
mutt -e "set content_type=text/html" \
     -s "Report hcdebian $DATE" \
     -a "$BACKUP_ALL" \
     -- "$EMAIL_DEST" < "$REPORT_HTML"

if [ $? -eq 0 ]; then
    echo "✅ Report e backup inviati con successo!"
else
    echo "❌ Errore durante l'invio dell'email."
fi

# --- 5. PULIZIA ---
rm -f "$REPORT_HTML"
# Rimuove i backup più vecchi di 7 giorni
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +7 -exec rm {} \;

echo "Pulizia completata. Script terminato."