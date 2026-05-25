#!/bin/bash

export TZ="Europe/Rome"
LOG_FILE="/home/hcdebian/scripts/hardware_telemetry.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# --- CONFIGURAZIONE PROMETHEUS ---
# Usiamo la tua query esatta (racchiusa tra apici singoli per non far confusione con le virgolette interne)
PROM_QUERY='windows_thermalzone_temperature_celsius{name=~".*CPUZ.*"}'
PROM_URL="http://localhost:9090/api/v1/query"

# Chiamata API a Prometheus
# Usiamo --data-urlencode perché la query contiene caratteri speciali come { } = ~ . *
# Versione che arrotonda a 1 decimale (es: 58.1)
TEMP=$(curl -s --data-urlencode "query=$PROM_QUERY" "$PROM_URL" | grep -oP '"value":\[\d+\.\d+,"\K[^"]+' | head -n 1 | xargs printf "%.1f")

# Se la temperatura è vuota, mettiamo N/A
if [ -z "$TEMP" ]; then TEMP="N/A"; fi

# Estrazione banda per entrambe le tue schede di rete
RX_ENS33=$(cat /sys/class/net/ens33/statistics/rx_bytes 2>/dev/null || echo "0")
RX_ENS37=$(cat /sys/class/net/ens37/statistics/rx_bytes 2>/dev/null || echo "0")

# Scrittura nel log
echo "[$DATE] Temp: ${TEMP}°C | ens33: $RX_ENS33 | ens37: $RX_ENS37" >> $LOG_FILE