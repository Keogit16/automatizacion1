#!/bin/bash

# ============================================================
# Monitor de Disco y Rotación de Logs
# ============================================================

UMBRAL=90
LOG_DIR="/var/log/monitor_disco"
TMP_DIR="/tmp"
INTERVAL=5
LOG_BASE="$LOG_DIR/monitor_disco_*.log"
MAX_LOGS=7

# Crear directorio si no existe
mkdir -p "$LOG_DIR"

log() {
    local FECHA_HORA
    FECHA_HORA=$(date '+%Y-%m-%d %H:%M:%S')
    local LOG_HOY="${LOG_DIR}/monitor_disco_$(date '+%Y-%m-%d').log"
    echo "[$FECHA_HORA] $1" | tee -a "$LOG_HOY"
}

rotar_logs() {
    find "$LOG_DIR" -maxdepth 1 -type f -name "monitor_disco_*.log" | while read -r archivo; do
        rm -f "$archivo" && log "Eliminado: $archivo"
    done < <(find "$LOG_DIR" -maxdepth 1 -type f \
        -name "$(basename "$LOG_DIR"/monitor_disco_*.log)" | sort -t. -k2 -n -r | tail -n +$((MAX_LOGS + 1)))
    log "Rotación de logs: eliminados registros con más de $MAX_LOGS días."
}

limpiar_tmp() {
    local count=0
    while IFS= read -r archivo; do
        rm -f "$archivo" && ((count++))
    done < <(find "$TMP_DIR" -maxdepth 1 -type f)
    log "/tmp: $count archivo(s) eliminado(s)."
}

limpiar_logs() {
    find "$LOG_DIR" -maxdepth 1 -type f \
        | sed 's/\.[0-9]*$//' | sed 's/\.log\..*$//' | sort -u | \
        while read -r prefijo; do
            local archivos
            archivos=$(find "$LOG_DIR" -maxdepth 1 -type f \
                -name "$(basename "$prefijo")*" | sort -t. -k2 -n -r)
            local total
            total=$(echo "$archivos" | grep -c .)
            if [ "$total" -gt 1 ]; then
                continue
            fi
        done
    log "Limpieza completada. Uso después: $(df / | tail -1 | awk '{print $5}')"
}

log "============================================================"
log "Monitor iniciado | PID: $$ | Umbral: ${UMBRAL}%"
log "============================================================"

ULTIMO_DIA=$(date '+%Y-%m-%d')

while true; do
    DIA_ACTUAL=$(date '+%Y-%m-%d')
    if [ "$DIA_ACTUAL" != "$ULTIMO_DIA" ]; then
        log "Nuevo día detectado. Ejecutando rotación de logs..."
        rotar_logs
        ULTIMO_DIA="$DIA_ACTUAL"
    fi

    USO=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    log "Revisión de disco: uso actual ${USO}%"

    if [ "$USO" -gt "$UMBRAL" ]; then
        log "⚠ Alerta: uso supera el ${UMBRAL}%. Iniciando limpieza..."
        limpiar_tmp
        limpiar_logs

        USO_POST=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        log "✓ Limpieza completada. Uso después: ${USO_POST}%"
    else
        log "✓ Uso dentro del límite. Sin acción requerida."
    fi

    log "Próxima revisión en ${INTERVAL} segundos."
    log "============================================================"
    sleep "$INTERVAL"
done
