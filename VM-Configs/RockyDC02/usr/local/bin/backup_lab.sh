#!/bin/bash

BACKUP_DIR="/mnt/stratis/samba_share/backups"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINERS=("monitor-container" "web-container" "log-container")

echo "=== Inizio Disaster Recovery (Piano Ottimizzato) ==="

# 1. Ciclo di Snapshot ed Esportazione dei Container LXC
for CONTAINER in "${CONTAINERS[@]}"; do
    if /snap/bin/lxc info "$CONTAINER" >/dev/null 2>&1; then
        echo "Generazione snapshot per $CONTAINER..."
        /snap/bin/lxc snapshot "$CONTAINER" "backup_snap_$DATE"

        echo "Esportazione in corso verso Stratis Storage..."
        /snap/bin/lxc export "$CONTAINER" "$BACKUP_DIR/${CONTAINER}_$DATE.tar.gz"

        echo "Rimozione snapshot temporaneo..."
        /snap/bin/lxc delete "$CONTAINER/backup_snap_$DATE"
    fi
done

# 2. Backup a caldo del database FreeIPA
echo "Esecuzione ipa-backup aziendale..."
ipa-backup --backend --data --file=$BACKUP_DIR/freeipa_identity_$DATE.tar

# 3. Retention Policy Bisettimanale Rigida
echo "Pulizia file obsoleti (Mantenimento ultime 2 settimane)..."
find $BACKUP_DIR -type f -mtime +13 -name "*.tar.gz" -exec rm -f {} \;
find $BACKUP_DIR -type f -mtime +13 -name "*.tar" -exec rm -f {} \;

echo "=== Disaster Recovery completato con successo ==="
