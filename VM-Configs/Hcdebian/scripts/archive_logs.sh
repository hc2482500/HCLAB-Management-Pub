#!/bin/bash

# --- CONFIGURAZIONE ---
EMAIL_DEST="<inserire-email-aziendale-oscurata>"
REPORT_HTML="/tmp/archive_report.html"
ARCHIVE_DIR="/home/hcdebian/logs_archive"
DATE=$(date +%Y%m%d_%H%M)
DATE_FORMATTED=$(date +'%d/%m/%Y %H:%M')
ARCHIVE_FILE="$ARCHIVE_DIR/homelab_logs_$DATE.tar.gz"
TEMP_DIR="/tmp/logs_export_$DATE"
DAYS_TO_KEEP=30 # Quanti giorni di log vuoi conservare

# --- 0. PREPARAZIONE ---
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$TEMP_DIR/docker"
mkdir -p "$TEMP_DIR/system"

echo "Avvio archiviazione log per il $DATE..."

# --- 1. ESPORTAZIONE LOG DOCKER ---
echo "Estrazione log dai container Docker..."
for container in $(docker ps --format '{{.Names}}'); do
    docker logs --tail 5000 "$container" > "$TEMP_DIR/docker/${container}.log" 2>&1
done

# --- 2. ESPORTAZIONE LOG DI SISTEMA (DEBIAN) ---
echo "Estrazione log di sistema (journald)..."
journalctl --since "1 day ago" > "$TEMP_DIR/system/debian_journal.log"

# --- 3. COMPRESSIONE E ARCHIVIAZIONE ---
echo "Compressione dei log in $ARCHIVE_FILE..."
tar -czf "$ARCHIVE_FILE" -C /tmp "logs_export_$DATE"

# --- 4. PULIZIA E ROTAZIONE ---
rm -rf "$TEMP_DIR"

echo "Pulizia archivi più vecchi di $DAYS_TO_KEEP giorni..."
find "$ARCHIVE_DIR" -name "homelab_logs_*.tar.gz" -type f -mtime +$DAYS_TO_KEEP -exec rm {} \;

# --- 5. COSTRUZIONE HTML E INVIO EMAIL ---
echo "Generazione email HTML..."

cat <<EOF > $REPORT_HTML
<html>
<head>
    <meta charset="utf-8">
</head>
<body style="font-family: 'Inter', sans-serif, Arial; background-color: #16a34a; margin: 0; padding: 20px;">
    <div style="max-width: 600px; margin: auto; background-color: #16a34a;">
        
        <div style="margin-bottom: 30px;">
            <h1 style="margin: 0; font-size: 2.2rem; font-weight: 800; color: #ffffff; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">Homelab OS</h1>
            <p style="margin: 0; color: #f0fdf4; font-weight: 600; opacity: 0.9;">Archivio Log - $DATE_FORMATTED</p>
        </div>

        <div style="background: #15803d; padding: 20px; border-radius: 24px; box-shadow: 0 8px 32px rgba(0,0,0,0.15); border: 1px solid rgba(255, 255, 255, 0.1); margin-bottom: 20px;">
            <div style="margin-bottom: 12px;">
                <span style="color: #dcfce7; font-size: 0.8rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.8px;">📝 Archiviazione Completata</span>
            </div>
            <div style="color: #ffffff; font-size: 14px; font-weight: 600; margin-bottom: 12px;">Log estratti e compressi con successo.</div>
            <div style="color: #bbf7d0; font-size: 13px; line-height: 1.6; background: rgba(0,0,0,0.1); padding: 12px; border-radius: 12px;">
                <strong>File allegato:</strong> $(basename "$ARCHIVE_FILE")<br>
                <strong>Periodo di sistema:</strong> Ultime 24 ore<br>
                <strong>Linee per container:</strong> Ultime 5000
            </div>
        </div>

        <div style="margin-top: 30px; font-size: 0.9rem; color: #f0fdf4; background: rgba(255,255,255,0.1); padding: 12px; border-radius: 50px; border: 1px solid rgba(255,255,255,0.15); text-align: center; font-weight: 600;">
            🤖 Inviato da hcdebian
        </div>
        
    </div>
</body>
</html>
EOF

echo "Invio email con allegato a $EMAIL_DEST..."
mutt -e "set content_type=text/html" \
     -s "Archivio Log Homelab $DATE_FORMATTED" \
     -a "$ARCHIVE_FILE" \
     -- "$EMAIL_DEST" < "$REPORT_HTML"

# Pulizia silenziosa HTML
rm -f "$REPORT_HTML"

echo "✅ Archiviazione e invio email completati!"