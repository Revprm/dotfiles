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
THROTTLE_TEMP=95           # °C
RESTORE_TEMP=90            # °C
TLP_PERF="performance"
TLP_BAL="balanced"
TLP_BAT="powersave"

log() {
    echo "[$(date '+%F %T')] $*" | sudo tee -a "$LOG_FILE" >/dev/null
}

# Initialize
log "Starting Smart Performance Manager..."
sudo chmod 666 "$LOG_FILE" 2>/dev/null

while true; do
    # ───────────────────────────────
    # 1️⃣ Read current CPU temperature
    # ───────────────────────────────
    TEMP=$(sensors | awk '/Package id 0:/ {print int($4)}')
    if [ -z "$TEMP" ]; then TEMP=0; fi

    # ───────────────────────────────
    # 2️⃣ Detect current usage mode
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
    # 3️⃣ Temperature-based fan + CPU logic
    # ───────────────────────────────
    if [ "$TEMP" -ge "$THROTTLE_TEMP" ]; then
        # 🔥 Critical zone
        echo 60 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Performance >/dev/null 2>&1
        log "🔥 Temp $TEMP°C → Throttling CPU to 60%, Fan: Performance"

    elif [ "$TEMP" -ge 85 ]; then
        # 🌡 High zone
        echo 80 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Balanced >/dev/null 2>&1
        log "🌡 Temp $TEMP°C → CPU 80%, Fan: Balanced"

    elif [ "$TEMP" -ge 70 ]; then
        # 😌 Warm zone
        echo 90 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Cool >/dev/null 2>&1
        log "😌 Temp $TEMP°C → CPU 90%, Fan: Cool"

    elif [ "$TEMP" -le "$RESTORE_TEMP" ]; then
        # ❄️ Normal / cool
        echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        sudo asusctl profile -P Balanced >/dev/null 2>&1
        log "❄️ Temp $TEMP°C → CPU 100%, Fan: Balanced"
    fi

    sleep "$CHECK_INTERVAL"
done
