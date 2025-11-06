#!/usr/bin/env bash
# ==========================================
# Smart Hybrid Performance + Thermal Manager
# For Intel i7-11370H + ASUS laptop on Arch
# ==========================================
# Features:
# - TLP mode auto-switch (game, battery, balanced)
# - Temperature-based fan and CPU control
# - Logging to /var/log/smart-performance.log
# ==========================================

LOG_FILE="/var/log/smart-performance.log"
CHECK_INTERVAL=5          # seconds
THROTTLE_TEMP=95          # °C  → Emergency throttle
HIGH_TEMP=85              # °C  → Aggressive cooling
WARM_TEMP=75              # °C  → Balanced cooling
COOL_TEMP=60              # °C  → Quiet operation
TLP_PERF="performance"
TLP_BAL="balanced"
TLP_BAT="powersave"

log() {
    echo "[$(date '+%F %T')] $*" | sudo tee -a "$LOG_FILE" >/dev/null
}

# Initialize
sudo chmod 666 "$LOG_FILE" 2>/dev/null
log "🚀 Starting Smart Performance Manager..."

while true; do
    # ───────────────────────────────
    # 1️⃣ Read current CPU temperature
    # ───────────────────────────────
    TEMP=$(sensors | awk '/Package id 0:/ {print int($4)}')
    [ -z "$TEMP" ] && TEMP=0

    # ───────────────────────────────
    # 2️⃣ Detect current usage mode (TLP)
    # ───────────────────────────────
    if pgrep -fa "steam|heroic|lutris|wine|proton|osu|gameoverlay" >/dev/null; then
        MODE="$TLP_PERF"
    elif [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" -eq 0 ]; then
        MODE="$TLP_BAT"
    else
        MODE="$TLP_BAL"
    fi
    sudo tlp setprofile "$MODE" >/dev/null 2>&1

    # ───────────────────────────────
    # 3️⃣ Temperature-based CPU & Fan Logic
    # ───────────────────────────────
    if [ "$TEMP" -ge "$THROTTLE_TEMP" ]; then
        echo 60 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Performance >/dev/null 2>&1
        log "🔥 Temp ${TEMP}°C → CPU 60%, Fan: Performance (Emergency Throttle)"

    elif [ "$TEMP" -ge "$HIGH_TEMP" ]; then
        echo 80 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Performance >/dev/null 2>&1
        log "🌡 Temp ${TEMP}°C → CPU 80%, Fan: Performance"

    elif [ "$TEMP" -ge "$WARM_TEMP" ]; then
        echo 90 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Balanced >/dev/null 2>&1
        log "😌 Temp ${TEMP}°C → CPU 90%, Fan: Balanced"

    elif [ "$TEMP" -le "$COOL_TEMP" ]; then
        echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Quiet >/dev/null 2>&1
        log "❄️ Temp ${TEMP}°C → CPU 100%, Fan: Quiet"
    fi

    sleep "$CHECK_INTERVAL"
done
