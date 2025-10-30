#!/usr/bin/env bash
# tlp-auto-switch.sh — hybrid TLP mode switcher (gaming + temperature-based)
# Improved version with better error handling and stability

CONFIG="/etc/tlp.conf"
BACKUP="/etc/tlp.conf.bak"
LOCKFILE="/var/run/tlp-auto-switch.lock"

# Back up original config once
[[ -f "$BACKUP" ]] || sudo cp "$CONFIG" "$BACKUP"

# --- Configuration ---
CPU_LIMIT_HIGH=75      # °C — performance mode above this
CPU_LIMIT_LOW=60       # °C — back to balanced below this (wider hysteresis)
GPU_LIMIT_HIGH=75
GPU_LIMIT_LOW=60
CHECK_INTERVAL=20      # seconds between checks
GAMING_COOLDOWN=60     # seconds to stay in performance after gaming stops

# List of known gaming-related processes
GAMING_APPS=(
    "steam" "lutris" "heroic"
    "Celeste" "java" "osu-lazer"
    "osu!" "osu!.exe" "proton" 
    "gamescope" "dolphin-emu" "retroarch"
    "wine.*osu" "steam_app"
)

# --- Helper functions ---
get_cpu_temp() {
    local temp
    
    # Try multiple methods to get CPU temperature
    if command -v sensors >/dev/null 2>&1; then
        # Try different sensor patterns
        temp=$(sensors 2>/dev/null | grep -E 'Package id 0:|Tdie:|Tctl:|CPU:' | head -n1 | grep -oP '\+?\d+\.\d+°C' | head -n1 | grep -oP '\d+' | head -n1)
        [[ -n "$temp" ]] && echo "$temp" && return
    fi
    
    # Fallback: try all hwmon interfaces
    for hwmon in /sys/class/hwmon/hwmon*/temp*_input; do
        [[ -f "$hwmon" ]] || continue
        local label="${hwmon%_input}_label"
        if [[ -f "$label" ]]; then
            local label_text=$(cat "$label" 2>/dev/null)
            # Look for CPU-related labels
            if echo "$label_text" | grep -qiE 'package|tdie|tctl|tccd|core'; then
                temp=$(($(cat "$hwmon" 2>/dev/null || echo 0) / 1000))
                [[ $temp -gt 0 ]] && echo "$temp" && return
            fi
        fi
    done
    
    # Try any temp1_input as last resort
    for hwmon in /sys/class/hwmon/hwmon*/temp1_input; do
        [[ -f "$hwmon" ]] || continue
        temp=$(($(cat "$hwmon" 2>/dev/null || echo 0) / 1000))
        # Sanity check: CPU temp should be between 20-100°C
        if [[ $temp -ge 20 ]] && [[ $temp -le 100 ]]; then
            echo "$temp"
            return
        fi
    done
    
    # Last resort
    echo "0"
}

get_gpu_temp() {
    local temp
    
    # NVIDIA
    if command -v nvidia-smi >/dev/null 2>&1; then
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
        [[ -n "$temp" ]] && echo "$temp" && return
    fi
    
    # AMD
    if command -v amd-smi >/dev/null 2>&1; then
        temp=$(amd-smi --showtemp 2>/dev/null | grep -o '[0-9]\+' | head -n1)
        [[ -n "$temp" ]] && echo "$temp" && return
    fi
    
    # Fallback for AMD via hwmon
    for hwmon in /sys/class/hwmon/hwmon*/name; do
        if grep -q "amdgpu" "$hwmon" 2>/dev/null; then
            local temp_path="${hwmon%/name}/temp1_input"
            if [[ -f "$temp_path" ]]; then
                temp=$(($(cat "$temp_path" 2>/dev/null || echo 0) / 1000))
                echo "$temp"
                return
            fi
        fi
    done
    
    echo "0"
}

check_gaming() {
    for app in "${GAMING_APPS[@]}"; do
        if pgrep -fa "$app" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

set_mode() {
    local mode="$1"
    
    # Prevent concurrent modifications with a lock
    exec 200>"$LOCKFILE"
    flock -n 200 || { echo "Another instance is modifying TLP config, skipping..."; return 1; }
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Switching TLP to $mode mode..."
    
    # Create temporary config
    local tmp_config="/tmp/tlp.conf.tmp.$$"
    sudo cp "$CONFIG" "$tmp_config"
    
    case "$mode" in
        performance)
            sudo sed -i \
                -e 's/^CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="performance"/' \
                -e 's/^CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT="performance"/' \
                -e 's/^CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' \
                -e 's/^CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=1/' \
                -e 's/^CPU_HWP_DYN_BOOST_ON_AC=.*/CPU_HWP_DYN_BOOST_ON_AC=1/' \
                -e 's/^CPU_HWP_DYN_BOOST_ON_BAT=.*/CPU_HWP_DYN_BOOST_ON_BAT=1/' \
                -e 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC="performance"/' \
                -e 's/^PLATFORM_PROFILE_ON_BAT=.*/PLATFORM_PROFILE_ON_BAT="performance"/' \
                "$tmp_config"
            ;;
        balanced)
            sudo sed -i \
                -e 's/^CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="powersave"/' \
                -e 's/^CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT="powersave"/' \
                -e 's/^CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=0/' \
                -e 's/^CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=0/' \
                -e 's/^CPU_HWP_DYN_BOOST_ON_AC=.*/CPU_HWP_DYN_BOOST_ON_AC=0/' \
                -e 's/^CPU_HWP_DYN_BOOST_ON_BAT=.*/CPU_HWP_DYN_BOOST_ON_BAT=0/' \
                -e 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC="balanced"/' \
                -e 's/^PLATFORM_PROFILE_ON_BAT=.*/PLATFORM_PROFILE_ON_BAT="low-power"/' \
                "$tmp_config"
            ;;
    esac
    
    # Atomically replace config
    sudo mv "$tmp_config" "$CONFIG"
    sudo tlp start >/dev/null 2>&1
    
    # Release lock
    flock -u 200
    
    # Optional desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        # Find the actual desktop user (not root)
        local desktop_user=$(who | grep -E ':\d+' | awk '{print $1}' | head -n1)
        if [[ -n "$desktop_user" ]]; then
            local user_id=$(id -u "$desktop_user" 2>/dev/null)
            if [[ -n "$user_id" ]]; then
                sudo -u "$desktop_user" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${user_id}/bus" \
                    notify-send -u normal "TLP Mode Switched" "Now in $mode mode." 2>/dev/null || true
            fi
        fi
    fi
}

# --- Cleanup on exit ---
cleanup() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Shutting down TLP auto-switcher..."
    rm -f "$LOCKFILE"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# --- Main loop ---
current_mode="balanced"
last_gaming_time=0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TLP auto-switcher started"
echo "CPU thresholds: ${CPU_LIMIT_LOW}°C - ${CPU_LIMIT_HIGH}°C"
echo "GPU thresholds: ${GPU_LIMIT_LOW}°C - ${GPU_LIMIT_HIGH}°C"
echo "Gaming cooldown: ${GAMING_COOLDOWN}s"
echo "---"

while true; do
    cpu_temp=$(get_cpu_temp)
    gpu_temp=$(get_gpu_temp)
    
    # Check for gaming activity
    if check_gaming; then
        last_gaming_time=$SECONDS
        gaming_status="[GAMING]"
    else
        gaming_status=""
    fi
    
    # Check if still in cooldown period
    time_since_gaming=$((SECONDS - last_gaming_time))
    in_cooldown=$((time_since_gaming < GAMING_COOLDOWN))
    
    # Log current status
    echo "[$(date '+%H:%M:%S')] CPU: ${cpu_temp}°C | GPU: ${gpu_temp}°C | Mode: $current_mode $gaming_status"
    
    # Decision logic with cooldown
    if check_gaming || [[ $in_cooldown -eq 1 ]] || (( cpu_temp >= CPU_LIMIT_HIGH )) || (( gpu_temp >= GPU_LIMIT_HIGH )); then
        if [[ "$current_mode" != "performance" ]]; then
            reason="temp"
            check_gaming && reason="gaming"
            [[ $in_cooldown -eq 1 ]] && reason="cooldown"
            echo "→ Trigger: $reason"
            set_mode "performance"
            current_mode="performance"
        fi
    elif (( cpu_temp <= CPU_LIMIT_LOW )) && (( gpu_temp <= GPU_LIMIT_LOW )); then
        if [[ "$current_mode" != "balanced" ]]; then
            echo "→ Trigger: temps normalized"
            set_mode "balanced"
            current_mode="balanced"
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done
