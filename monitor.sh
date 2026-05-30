#!/bin/bash
# ----- Configuración -----
UMBRAL_DISCO=90
UMBRAL_RAM=85
UMBRAL_CPU=80

LOG_DIR="/var/log"
TMP_DIR="/tmp"
INTERVALO=5
LOG_BASE="${LOG_BASE:-/var/log/monitor_recursos}"
MAX_LOGS=7

# Forzamos locale C para que comandos como top/free usen punto decimal
export LC_ALL=C

# ----- Utilidades -----
log() {
    local FECHA_HORA
    FECHA_HORA=$(date '+%Y-%m-%d %H:%M:%S')
    local LOG_HOY="${LOG_BASE}_$(date '+%Y-%m-%d').log"
    echo "[${FECHA_HORA}] $1" | tee -a "$LOG_HOY"
}

rotar_logs() {
    find "$(dirname "$LOG_BASE")" -name "$(basename "$LOG_BASE")_*.log" \
        -mtime +${MAX_LOGS} -delete
    log "Rotación de logs: eliminados registros con más de ${MAX_LOGS} días."
}

# ----- Limpieza (acciones del monitor de disco) -----
limpiar_tmp() {
    local count=0
    while IFS= read -r archivo; do
        rm -f "$archivo" && ((count++)) || true
    done < <(find "$TMP_DIR" -maxdepth 1 -type f)
    log "  /tmp: ${count} archivo(s) eliminado(s)."
}

limpiar_logs() {
    find "$LOG_DIR" -maxdepth 1 -type f \
        | sed 's/\.[0-9]*$//' | sed 's/\.log.*$//' | sort -u \
        | while read -r prefijo; do
        local archivos total
        archivos=$(find "$LOG_DIR" -maxdepth 1 -type f \
                -name "$(basename "$prefijo")*" | sort -t. -k2 -n -r)
        total=$(echo "$archivos" | grep -c .)
        if [ "$total" -le 1 ]; then
            continue
        fi
        echo "$archivos" | tail -n +2 | while read -r archivo; do
            rm -f "$archivo"
            log "  Eliminado: $archivo"
        done
    done
}

# ----- Monitores -----
revisar_disco() {
    local USO USO_POST
    USO=$(df -h / | grep -v "^Filesystem" | awk '{print $5}' | sed 's/%//')
    log "🖴 Disco: uso ${USO}%"
    if [ "$USO" -gt "$UMBRAL_DISCO" ]; then
        log "⚠ Disco supera el ${UMBRAL_DISCO}%. Iniciando limpieza..."
        limpiar_tmp
        limpiar_logs
        USO_POST=$(df -h / | grep -v "^Filesystem" | awk '{print $5}' | sed 's/%//')
        log "✅ Limpieza completada. Uso de disco: ${USO_POST}%"
    fi
}

revisar_ram() {
    local USO
    # % de RAM usada = (used / total) * 100, redondeado a entero
    USO=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    log "🔵 RAM: uso ${USO}%"
    if [ "$USO" -gt "$UMBRAL_RAM" ]; then
        log "⚠ RAM supera el ${UMBRAL_RAM}%. Top 5 procesos por memoria:"
        ps -eo pid,comm,%mem --sort=-%mem | head -n 6 | tail -n 5 \
            | while read -r linea; do
            log "    $linea"
        done
    fi
}

revisar_cpu() {
    local USO
    # Tomamos el % idle reportado por top y restamos a 100
    USO=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}' | cut -d. -f1)
    log "⚙ CPU: uso ${USO}%"
    if [ "$USO" -gt "$UMBRAL_CPU" ]; then
        log "⚠ CPU supera el ${UMBRAL_CPU}%. Top 5 procesos por CPU:"
        ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6 | tail -n 5 \
            | while read -r linea; do
            log "    $linea"
        done
    fi
}

# ----- Manejo de señales -----
trap 'log "Monitor detenido (señal recibida). PID: $$"; exit 0' SIGINT SIGTERM

# ----- Loop principal -----
log "================================================="
log " Monitor iniciado | PID: $$"
log " Umbrales -> Disco:${UMBRAL_DISCO}% | RAM:${UMBRAL_RAM}% | CPU:${UMBRAL_CPU}%"
log " Intervalo: ${INTERVALO}s"
log "================================================="

ULTIMO_DIA=$(date '+%Y-%m-%d')

while true; do
    DIA_ACTUAL=$(date '+%Y-%m-%d')
    if [ "$DIA_ACTUAL" != "$ULTIMO_DIA" ]; then
        log "Nuevo día detectado. Ejecutando rotación de logs..."
        rotar_logs
        ULTIMO_DIA="$DIA_ACTUAL"
    fi

    revisar_disco
    revisar_ram
    revisar_cpu

    log "Próxima revisión en ${INTERVALO} segundos."
    log "-------------------------------------------------"
    sleep "$INTERVALO"
done