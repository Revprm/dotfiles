#!/usr/bin/env bash
# =========================================================================
# Smart Hybrid Performance + Thermal Manager v2.4 (Final)
# For modern Intel CPUs + ASUS laptops on Arch Linux
#
# v2.4: Fixed critical bug where logging within a function was captured
#       as a return value, causing the script to crash.
# =========================================================================

# --- BEGIN CONFIGURATION ---
LOG_FILE="/var/log/smart-performance.log"
LOCK_FILE="/tmp/smart-performance.lock"
INTERVAL_GAMING=3
INTERVAL_NORMAL=5
INTERVAL_AUDIO=15
THRESHOLDS_NORMAL=( [throttle]=95 [high]=85 [warm]=75 [cool]=60 )
THRESHOLDS_GAMING=( [throttle]=90 [high]=78 [warm]=68 [cool]=55 )
HYSTERESIS_NORMAL=3
HYSTERESIS_GAMING=2
CPU_PERF=( [emergency]=85 [high]=90 [balanced]=95 [full]=100 )
FAN_PROFILE=( [performance]="Performance" [balanced]="Balanced" [quiet]="Quiet" )
GAMING_PROCESSES="steam_app_|heroic|lutris|wine|proton|mangohud|gamescope|WutheringWaves"
# --- END CONFIGURATION ---

# Root check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." >&2
   exit 1
fi

# State variables
CURRENT_STATE=""
LAST_FAN_PROFILE=""
IS_GAMING=false

# --- Core Functions ---

log() {
    # Logs a message to the specified log file. Also echoes to stdout
    # if the script is run interactively.
    local message="[$(date '+%F %T')] $*"
    echo "$message" >> "$LOG_FILE"
    if [ -t 1 ]; then echo "$message"; fi
}

cleanup() {
    log "🛑 Script stopping. Cleaning up lockfile."
    rm -f "$LOCK_FILE"
    exit 0
}

check_dependencies() {
    for cmd in sensors asusctl tlp pactl pw-cli pgrep timeout; do
        if ! command -v "$cmd" &>/dev/null; then
            log "❌ ERROR: Command not found: $cmd. Please install it."
            exit 1
        fi
    done
}

get_cpu_temp() {
    # This function is now silent. It ONLY outputs the temperature value.
    # This is critical for command substitution `var=$(...)` to work correctly.
    local temp_json
    temp_json=$(timeout 2s sensors -j 2>/dev/null)

    if [[ -z "$temp_json" ]]; then
        echo "" # Return empty on failure
        return
    fi
    
    # This final echo IS the return value of the function.
    echo "$temp_json" | grep -A 2 '"Package id 0":' | grep 'temp1_input' | awk '{print $2}' | cut -d'.' -f1
}

is_audio_active() {
    { pactl list sink-inputs 2>/dev/null | grep -q "State: RUNNING"; } || \
    { pw-cli list-objects 2>/dev/null | grep -q 'state = "running"'; }
}

is_gaming_active() {
    pgrep -af "$GAMING_PROCESSES" >/dev/null
}

set_cpu_performance() {
    local target_perf=$1 reason=$2
    local pstate_path="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
    if [[ ! -w "$pstate_path" ]]; then return; fi
    local current_perf=$(cat "$pstate_path")
    if [[ "$current_perf" != "$target_perf" ]]; then
        echo "$target_perf" > "$pstate_path"
        log "🔧 CPU -> ${target_perf}% ($reason)"
    fi
}

set_fan_profile() {
    local profile=$1 reason=$2
    if [[ "$profile" != "$LAST_FAN_PROFILE" ]]; then
        if asusctl profile -P "$profile" >/dev/null 2>&1; then
            log "🌀 Profile (asusctl) -> $profile ($reason)"
            LAST_FAN_PROFILE="$profile"
        else
            log "⚠️ Warning: Failed to set asusctl profile to '$profile'."
        fi
    fi
}

apply_thermal_policy() {
    local temp=$1 is_audio=$2 is_gaming=$3
    local new_state=""
    local -n thresholds="THRESHOLDS_${is_gaming:+"GAMING"}"
    local hysteresis="${is_gaming:+$HYSTERESIS_GAMING}"
    [[ -z "$is_gaming" ]] && thresholds="THRESHOLDS_NORMAL" && hysteresis="$HYSTERESIS_NORMAL"
    if   (( temp >= thresholds[throttle] )); then new_state="EMERGENCY"
    elif (( temp >= thresholds[high] ));     then new_state="HIGH"
    elif (( temp >= thresholds[warm] ));     then new_state="WARM"
    elif (( temp <= thresholds[cool] ));     then new_state="COOL"
    else new_state="$CURRENT_STATE"; fi
    if [[ "$new_state" != "$CURRENT_STATE" && -n "$CURRENT_STATE" ]]; then
        case "$CURRENT_STATE" in
            EMERGENCY) (( temp < (thresholds[throttle] - hysteresis) )) || new_state="EMERGENCY" ;;
            HIGH)      (( temp < (thresholds[high] - hysteresis) ))     || new_state="HIGH" ;;
            WARM)      (( temp < (thresholds[warm] - hysteresis) ))     || new_state="WARM" ;;
        esac
    fi
    if [[ "$new_state" != "$CURRENT_STATE" ]]; then
        local mode_icon="${is_gaming:+"🎮 "}"; log "🔄 State change: $CURRENT_STATE -> $new_state. Temp: ${temp}°C"
        case "$new_state" in
            EMERGENCY) if [[ "$is_audio" == true && "$is_gaming" == false ]]; then set_cpu_performance "${CPU_PERF[balanced]}" "${mode_icon}🔥 ${temp}°C + Audio Safety"; log "🔊 Audio protection active."; else set_cpu_performance "${CPU_PERF[emergency]}" "${mode_icon}🔥 ${temp}°C Emergency"; fi; set_fan_profile "${FAN_PROFILE[performance]}" "${mode_icon}Emergency cooling";;
            HIGH) set_cpu_performance "${CPU_PERF[high]}" "${mode_icon}🌡️ ${temp}°C High"; set_fan_profile "${FAN_PROFILE[performance]}" "${mode_icon}Aggressive cooling";;
            WARM) set_cpu_performance "${CPU_PERF[balanced]}" "${mode_icon}😌 ${temp}°C Warm"; if [[ "$is_gaming" == true ]]; then set_fan_profile "${FAN_PROFILE[performance]}" "${mode_icon}Sustained cooling"; else set_fan_profile "${FAN_PROFILE[balanced]}" "${mode_icon}Balanced cooling"; fi;;
            COOL) set_cpu_performance "${CPU_PERF[full]}" "${mode_icon}❄️ ${temp}°C Cool"; if [[ "$is_gaming" == true ]]; then set_fan_profile "${FAN_PROFILE[balanced]}" "${mode_icon}Quiet gaming"; elif [[ $(cat /sys/class/power_supply/AC/online) -eq 0 ]]; then set_fan_profile "${FAN_PROFILE[quiet]}" "On battery"; else set_fan_profile "${FAN_PROFILE[quiet]}" "Quiet operation"; fi;;
        esac
        CURRENT_STATE="$new_state"
    fi
}

main() {
    check_dependencies
    touch "$LOG_FILE" && chmod 664 "$LOG_FILE"
    if ! ( set -o noclobber; echo "$$" > "$LOCK_FILE") 2>/dev/null; then
        log "❌ ERROR: Script is already running. Lockfile exists."
        exit 1
    fi
    trap cleanup SIGINT SIGTERM EXIT
    log "🚀 Starting Smart Performance Manager v2.4..."
    log "🔎 Configured Gaming Processes: $GAMING_PROCESSES"
    while true; do
        local temp
        temp=$(get_cpu_temp)
        if [[ -z "$temp" ]]; then
            log "⚠️ Warning: Could not read CPU temperature. Skipping cycle."
        else
            local is_audio=false; is_audio_active && is_audio=true
            local was_gaming=$IS_GAMING; IS_GAMING=false; is_gaming_active && IS_GAMING=true
            if [[ "$IS_GAMING" != "$was_gaming" ]]; then
                if [[ "$IS_GAMING" == true ]]; then log "🎮 GAMING MODE ACTIVATED."; set_fan_profile "${FAN_PROFILE[performance]}" "Gaming detected";
                else log "🎮 GAMING MODE DEACTIVATED."; CURRENT_STATE=""; LAST_FAN_PROFILE=""; fi
            fi
            apply_thermal_policy "$temp" "$is_audio" "$IS_GAMING"
        fi
        local interval="$INTERVAL_NORMAL"
        [[ "$IS_GAMING" == true ]] && interval="$INTERVAL_GAMING"
        [[ "$is_audio" == true && "$IS_GAMING" == false ]] && interval="$INTERVAL_AUDIO"
        sleep "$interval"
    done
}

main "$@"
