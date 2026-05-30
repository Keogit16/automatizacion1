#!/bin/bash

# ============================================================
# Simulador de Disco Lleno para Testing
# ============================================================

DEST_DIR="/tmp/disk_test"
TOTAL_FILES=30
LOG_FILE="/tmp/sim_disk.log"

mkdir -p "$DEST_DIR"

echo "============================================================" | tee -a "$LOG_FILE"
echo " Inicio de simulación: $(date)" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

SIZES=(50 100 200 150 75 300 120 80 250 400 500 600 1024)

for i in $(seq 1 $TOTAL_FILES); do
    SIZE=${SIZES[$(($i-1))]}
    FILE="$DEST_DIR/testfile_${i}_${SIZE}mb.bin"
    echo "[$(date +%T)] Creando $FILE (${SIZE} MB)..." | tee -a "$LOG_FILE"
    fallocate -l "${SIZE}M" "$FILE" 2>/dev/null || dd if=/dev/zero of="$FILE" bs=1M count="$SIZE" status=none
    USED=$(df -h "$DEST_DIR" | awk 'NR==2 {print $5}')
    TOTAL=$(df -h "$DEST_DIR" | awk 'NR==2 {print $2}')
    echo "[$(date +%T)] Uso actual: $USED / $TOTAL" | tee -a "$LOG_FILE"
    sleep 2
done

echo "" | tee -a "$LOG_FILE"
echo "Simulación completada. Archivos en: $DEST_DIR" | tee -a "$LOG_FILE"
echo "Uso final del disco:" | tee -a "$LOG_FILE"
df -h "$DEST_DIR" | tee -a "$LOG_FILE"
