#!/bin/bash

export TZ="Europe/Rome"

# --- CONFIGURAZIONE ---
EMAIL_DEST="<inserire-email-aziendale-oscurata>"
LOG_TELEMETRY="/home/hcdebian/scripts/hardware_telemetry.log"
DATE=$(date +'%d/%m/%Y %H:%M')

# --- 1. PRELIEVO DATI ---
# Prendiamo l'ultima riga del log di telemetria
LATEST_STATS=$(tail -n 1 "$LOG_TELEMETRY")
TEMP=$(echo "$LATEST_STATS" | grep -oP 'Temp: \K[0-9.]+')
RAM_FREE=$(free -h | awk '/^Mem:/{print $4}')
CPU_LOAD=$(uptime | awk -F'average:' '{ print $2 }' | cut -d, -f1 | xargs)

# --- 2. IL CERVELLO (Phi-3) ---
# Chiediamo a Phi-3 un'analisi professionale ma con un tocco di personalità
AI_COMMENT=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "phi3",
  "prompt": "Sei l'"'"'assistente AI di hcdebian. Analizza questi dati: Temp CPU '$TEMP'C, RAM Libera '$RAM_FREE', Carico CPU '$CPU_LOAD'. Fornisci una diagnosi di una riga sulla salute del server.",
  "stream": false
}' | jq -r '.response')

# --- 3. INVIO EMAIL ---
echo -e "<html><body style='font-family:sans-serif; background:#f0fdf4; padding:20px;'>
<div style='border-left:5px solid #16a34a; padding-left:20px;'>
<h2 style='color:#16a34a;'>Rapporto AI del Mattino 🧠</h2>
<p style='font-size:1.2em; color:#15803d;'><b>Analisi di Phi-3:</b> \"$AI_COMMENT\"</p>
<hr style='border:0; border-top:1px solid #bbf7d0;'>
<ul style='list-style:none; padding:0; color:#166534;'>
<li>🔥 Temperatura: <b>$TEMP°C</b></li>
<li>🧠 Memoria Libera: <b>$RAM_FREE</b></li>
<li>⚙️ Carico Sistema: <b>$CPU_LOAD</b></li>
</ul>
<p style='font-size:0.8em; color:#86efac;'>Generato alle $DATE</p>
</div></body></html>" | mutt -e "set content_type=text/html" -s "Analisi AI Server: $DATE" -- "$EMAIL_DEST"