#!/usr/bin/env bash
# =========================================================================
# Smart Hybrid Performance + Thermal Manager v2.6
# For modern Intel CPUs + ASUS laptops on Arch Linux
#
# v2.6: (Gemini)
#     - 🐞 BUGFIX: Replaced fragile/hardcoded AC adapter check
#       (cat /sys/class/power_supply/AC/online) with a robust
#       function that iterates all power supplies.
# v2.5: (Gemini)
#     - 🐞 CRITICAL BUGFIX: Correctly apply NORMAL/GAMING thresholds.
#     - 🛡️ Robustness: Added 'set -Eeuo pipefail' for safer execution.
#     - 🛡️ Robustness: Replaced fragile 'grep/awk/cut' with 'jq' for
#       parsing 'sensors' JSON output.
#     - ⚙️ Config: Used 'declare -r' (readonly) for constants and
#       'declare -r -A' for associative arrays for script safety.
#     - 🧹 Cleanup: Added 'jq' to dependency check.
# =========================================================================

set -Eeuo pipefail

# --- BEGIN CONFIGURATION ---
declare -r LOG_FILE="/var/log/smart-performance.log"
declare -r LOCK_FILE="/tmp/smart-performance.lock"
declare -r INTERVAL_GAMING=3
declare -r INTERVAL_NORMAL=5
declare -r INTERVAL_AUDIO=15
declare -r -A THRESHOLDS_NORMAL=( [throttle]=95 [high]=85 [warm]=75 [cool]=60 )
declare -r -A THRESHOLDS_GAMING=( [throttle]=90 [high]=78 [warm]=68 [cool]=55 )
declare -r HYSTERESIS_NORMAL=3
declare -r HYSTERESIS_GAMING=2
declare -r -A CPU_PERF=( [emergency]=85 [high]=90 [balanced]=95 [full]=100 )
declare -r -A FAN_PROFILE=( [performance]="Performance" [balanced]="Balanced" [quiet]="Quiet" )
declare -r GAMING_PROCESSES="steam_app_|heroic|lutris|wine|proton|mangohud|gamescope|WutheringWaves"
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
    for cmd in sensors asusctl tlp pactl pw-cli pgrep timeout jq; do
        if ! command -v "$cmd" &>/dev/null; then
            log "❌ ERROR: Command not found: $cmd. Please install it."
            exit 1
        fi
    done
}

get_cpu_temp() {
    # This function is now silent. It ONLY outputs the temperature value.
    local temp_json
    
    # Attempt to get sensor data. Exit with empty string on timeout.
    temp_json=$(timeout 2s sensors -j 2>/dev/null) || { echo ""; return; }
    
    if [[ -z "$temp_json" ]]; then
        echo "" # Return empty on failure
        return
    fi
    
    # Use jq to robustly parse the JSON.
    echo "$temp_json" | jq '[.. | ."Package id 0"? | objects | .temp1_input // empty] | first | floor // empty' 2>/dev/null
}

is_audio_active() {
    { pactl list sink-inputs 2>/dev/null | grep -q "State: RUNNING"; } || \
    { pw-cli list-objects 2>/dev/null | grep -q 'state = "running"'; }
}

is_gaming_active() {
    pgrep -af "$GAMING_PROCESSES" >/dev/null
}

is_on_ac() {
    # Loop through all power supplies
    for supply in /sys/class/power_supply/*; do
        # Check if it's an AC adapter ("Mains")
        if [[ -f "$supply/type" ]] && grep -q "Mains" "$supply/type" 2>/dev/null; then
            # If it is, check if it's online. If yes, we are on AC.
            if [[ -f "$supply/online" ]] && [[ $(cat "$supply/online") -eq 1 ]]; then
                return 0 # Bash success (true)
            fi
        fi
    done
    return 1 # Bash failure (false)
}

set_cpu_performance() {
    local target_perf=$1 reason=$2
    local pstate_path="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
    
    if [[ ! -w "$pstate_path" ]]; then return; fi
    
    local current_perf
    current_perf=$(cat "$pstate_path")
    
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
    
    local -n thresholds
    local hysteresis
    if [[ "$is_gaming" == true ]]; then
        thresholds="THRESHOLDS_GAMING"
        hysteresis="$HYSTERESIS_GAMING"
    else
        thresholds="THRESHOLDS_NORMAL"
        hysteresis="$HYSTERESIS_NORMAL"
    fi

    # 1. Determine new state based on temperature
    if   (( temp >= thresholds[throttle] )); then new_state="EMERGENCY"
    elif (( temp >= thresholds[high] ));     then new_state="HIGH"
    elif (( temp >= thresholds[warm] ));     then new_state="WARM"
    elif (( temp <= thresholds[cool] ));     then new_state="COOL"
    else new_state="$CURRENT_STATE"; fi # Maintain state in "dead zone"

    # 2. Apply hysteresis (when cooling down)
    if [[ "$new_state" != "$CURRENT_STATE" && -n "$CURRENT_STATE" ]]; then
        case "$CURRENT_STATE" in
            EMERGENCY) (( temp < (thresholds[throttle] - hysteresis) )) || new_state="EMERGENCY" ;;
            HIGH)      (( temp < (thresholds[high] - hysteresis) ))    || new_state="HIGH" ;;
            WARM)      (( temp < (thresholds[warm] - hysteresis) ))    || new_state="WARM" ;;
        esac
    fi

    # 3. Apply the new state if it has changed
    if [[ "$new_state" != "$CURRENT_STATE" ]]; then
        local mode_icon="${is_gaming:+"🎮 "}"
        log "🔄 State change: ${CURRENT_STATE:-"NONE"} -> $new_state. Temp: ${temp}°C"
        
        case "$new_state" in
            EMERGENCY) 
                if [[ "$is_audio" == true && "$is_gaming" == false ]]; then
                    set_cpu_performance "${CPU_PERF[balanced]}" "${mode_icon}🔥 ${temp}°C + Audio Safety"
                    log "🔊 Audio protection active."
                else
                    set_cpu_performance "${CPU_PERF[emergency]}" "${mode_icon}🔥 ${temp}°C Emergency"
                fi
                set_fan_profile "${FAN_PROFILE[performance]}" "${mode_icon}Emergency cooling"
                ;;
            HIGH)
                set_cpu_performance "${CPU_PERF[high]}" "${mode_icon}🌡️ ${temp}°C High"
                set_fan_profile "${FAN_PROFILE[performance]}" "${mode_icon}Aggressive cooling"
                ;;
            WARM)
                set_cpu_performance "${CPU_PERF[balanced]}" "${mode_icon}😌 ${temp}°C Warm"
                if [[ "$is_gaming" == true ]]; then
                    set_fan_profile "${FAN_PROFILE[performance]}" "${mode_icon}Sustained cooling"
                else
                    set_fan_profile "${FAN_PROFILE[balanced]}" "${mode_icon}Balanced cooling"
                fi
                ;;
            COOL)
                set_cpu_performance "${CPU_PERF[full]}" "${mode_icon}❄️ ${temp}°C Cool"
                if [[ "$is_gaming" == true ]]; then
                    set_fan_profile "${FAN_PROFILE[balanced]}" "${mode_icon}Quiet gaming"
                elif ! is_on_ac; then # Check if NOT on AC
                    set_fan_profile "${FAN_PROFILE[quiet]}" "On battery"
                else
                    set_fan_profile "${FAN_PROFILE[quiet]}" "Quiet operation"
                fi
                ;;
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
    
    log "🚀 Starting Smart Performance Manager v2.6..."
    log "🔎 Configured Gaming Processes: $GAMING_PROCESSES"
    
    while true; do
        local temp
        temp=$(get_cpu_temp)
        
        if [[ -z "$temp" ]]; then
            log "⚠️ Warning: Could not read CPU temperature. Skipping cycle."
        else
            local is_audio=false
            is_audio_active && is_audio=true
            
            local was_gaming=$IS_GAMING
            IS_GAMING=false
            is_gaming_active && IS_GAMING=true
            
            if [[ "$IS_GAMING" != "$was_gaming" ]]; then
                if [[ "$IS_GAMING" == true ]]; then
                    log "🎮 GAMING MODE ACTIVATED."
                    set_fan_profile "${FAN_PROFILE[performance]}" "Gaming detected"
                else
                    log "🎮 GAMING MODE DEACTIVATED."
                    # Reset states to force re-evaluation for normal mode
                    CURRENT_STATE=""
                    LAST_FAN_PROFILE=""
                fi
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
