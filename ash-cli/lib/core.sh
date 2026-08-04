#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 — CORE LIBRARY                                                ║
# ║  Foundation primitives used by all other modules                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CORE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CORE_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 SHELL COMPATIBILITY ASSERTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_core_assert_bash_version() {
    local required_major="${1:-4}"
    local required_minor="${2:-4}"

    local major="${BASH_VERSINFO[0]}"
    local minor="${BASH_VERSINFO[1]}"

    if (( major < required_major )) || \
       (( major == required_major && minor < required_minor )); then
        printf '\033[1;31m[ASH FATAL]\033[0m Bash %d.%d+ required (found %d.%d)\n' \
            "$required_major" "$required_minor" "$major" "$minor" >&2
        exit 1
    fi
}

ash_core_assert_bash_version 4 4

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 CORE ASSERTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Assert: command exists
ash_require_cmd() {
    local cmd="$1"
    local package="${2:-$1}"
    local critical="${3:-1}"

    if ! command -v "$cmd" &>/dev/null; then
        if [[ $critical -eq 1 ]]; then
            ash_log_fatal "Required command not found: '${cmd}'" \
                          "Install it with: paru -S ${package}"
        else
            ash_log_warn "Optional command not found: '${cmd}' (install: paru -S ${package})"
            return 1
        fi
    fi
    return 0
}

# Assert: file exists
ash_require_file() {
    local file="$1"
    local description="${2:-file}"

    if [[ ! -f "$file" ]]; then
        ash_log_error "Required ${description} not found: ${file}"
        return 1
    fi
    return 0
}

# Assert: directory exists (create if requested)
ash_require_dir() {
    local dir="$1"
    local create="${2:-0}"

    if [[ ! -d "$dir" ]]; then
        if [[ $create -eq 1 ]]; then
            mkdir -p "$dir" || {
                ash_log_error "Cannot create directory: ${dir}"
                return 1
            }
            ash_log_debug "Created directory: ${dir}"
        else
            ash_log_error "Required directory not found: ${dir}"
            return 1
        fi
    fi
    return 0
}

# Assert: running as non-root
ash_require_nonroot() {
    if [[ $EUID -eq 0 ]]; then
        ash_log_error "This command must NOT be run as root"
        ash_log_error "Run as your regular user account"
        return 1
    fi
}

# Assert: running on Wayland
ash_require_wayland() {
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        ash_log_error "Wayland session required"
        ash_log_error "Current session: ${XDG_SESSION_TYPE:-unknown}"
        return 1
    fi
}

# Assert: Hyprland is running
ash_require_hyprland() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        ash_log_error "Hyprland is not running"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 EXECUTION HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Run a command with dry-run awareness
ash_run() {
    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        ash_log_info "[DRY RUN] $ $*"
        return 0
    fi

    ash_log_debug "$ $*"

    if [[ "${ASH_FLAG_VERBOSE:-0}" -eq 1 ]]; then
        "$@"
    else
        "$@" 2>/dev/null
    fi
}

# Run silently (suppress all output)
ash_run_silent() {
    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        ash_log_info "[DRY RUN] $ $*"
        return 0
    fi

    ash_log_debug "[silent] $ $*"
    "$@" &>/dev/null
}

# Run with timeout
ash_run_timeout() {
    local timeout="$1"
    shift

    if command -v timeout &>/dev/null; then
        timeout "$timeout" "$@"
    else
        "$@"
    fi
}

# Run in background, track PID
declare -gA ASH_BACKGROUND_PIDS=()

ash_run_background() {
    local name="$1"
    shift

    ash_log_debug "[background:${name}] $ $*"
    "$@" &
    ASH_BACKGROUND_PIDS["$name"]=$!
    ash_log_debug "Background PID for '${name}': ${ASH_BACKGROUND_PIDS[$name]}"
}

ash_wait_background() {
    local name="${1:-}"

    if [[ -n "$name" ]]; then
        local pid="${ASH_BACKGROUND_PIDS[$name]:-}"
        if [[ -n "$pid" ]]; then
            wait "$pid" 2>/dev/null || true
            unset 'ASH_BACKGROUND_PIDS[$name]'
        fi
    else
        # Wait for all background jobs
        for job_name in "${!ASH_BACKGROUND_PIDS[@]}"; do
            wait "${ASH_BACKGROUND_PIDS[$job_name]}" 2>/dev/null || true
        done
        ASH_BACKGROUND_PIDS=()
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 HYPRLAND CTL WRAPPER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hyprctl() {
    if ! command -v hyprctl &>/dev/null; then
        ash_log_error "hyprctl not found"
        return 1
    fi

    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        ash_log_error "Hyprland is not running"
        return 1
    fi

    ash_log_debug "hyprctl $*"
    hyprctl "$@"
}

ash_hyprctl_dispatch() {
    ash_hyprctl dispatch "$@"
}

ash_hyprctl_keyword() {
    ash_hyprctl keyword "$@"
}

ash_hyprctl_reload() {
    ash_hyprctl reload
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 VERSION UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_core_get_version() {
    printf '%s' "${ASH_VERSION:-0.0.0}"
}

ash_core_get_hyprland_version() {
    hyprctl version 2>/dev/null | grep -oP 'v[\d.]+' | head -1 || echo "unknown"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 PLATFORM DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  ASH_DISTRO_ID=""
declare -g  ASH_DISTRO_NAME=""
declare -g  ASH_DISTRO_VERSION=""
declare -g  ASH_PKG_MANAGER=""
declare -g  ASH_INIT_SYSTEM=""
declare -g  ASH_GPU_VENDOR=""
declare -g  ASH_IS_LAPTOP=0
declare -g  ASH_HAS_NVIDIA=0
declare -g  ASH_HAS_AMD=0
declare -g  ASH_HAS_INTEL_GPU=0

ash_core_detect_platform() {
    # Distro detection
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        ASH_DISTRO_ID="${ID:-unknown}"
        ASH_DISTRO_NAME="${NAME:-Unknown}"
        ASH_DISTRO_VERSION="${VERSION_ID:-unknown}"
    fi

    # Package manager detection
    if command -v paru &>/dev/null; then
        ASH_PKG_MANAGER="paru"
    elif command -v yay &>/dev/null; then
        ASH_PKG_MANAGER="yay"
    elif command -v pacman &>/dev/null; then
        ASH_PKG_MANAGER="pacman"
    elif command -v dnf &>/dev/null; then
        ASH_PKG_MANAGER="dnf"
    elif command -v zypper &>/dev/null; then
        ASH_PKG_MANAGER="zypper"
    elif command -v nix-env &>/dev/null; then
        ASH_PKG_MANAGER="nix"
    elif command -v xbps-install &>/dev/null; then
        ASH_PKG_MANAGER="xbps"
    elif command -v apt &>/dev/null; then
        ASH_PKG_MANAGER="apt"
    else
        ASH_PKG_MANAGER="unknown"
    fi

    # Init system detection
    if [[ -d /run/systemd/system ]]; then
        ASH_INIT_SYSTEM="systemd"
    elif [[ -f /run/runit.stopit ]]; then
        ASH_INIT_SYSTEM="runit"
    elif [[ -f /run/openrc ]]; then
        ASH_INIT_SYSTEM="openrc"
    else
        ASH_INIT_SYSTEM="unknown"
    fi

    # GPU detection
    if lspci 2>/dev/null | grep -qi 'nvidia'; then
        ASH_HAS_NVIDIA=1
        ASH_GPU_VENDOR="nvidia"
    fi
    if lspci 2>/dev/null | grep -qi 'amd\|radeon'; then
        ASH_HAS_AMD=1
        [[ -z "$ASH_GPU_VENDOR" ]] && ASH_GPU_VENDOR="amd"
    fi
    if lspci 2>/dev/null | grep -qi 'intel.*graphics\|iris'; then
        ASH_HAS_INTEL_GPU=1
        [[ -z "$ASH_GPU_VENDOR" ]] && ASH_GPU_VENDOR="intel"
    fi

    # Laptop detection
    if [[ -d /sys/class/power_supply/BAT0 ]] || \
       [[ -d /sys/class/power_supply/BAT1 ]]; then
        ASH_IS_LAPTOP=1
    fi

    ash_log_debug "Platform: ${ASH_DISTRO_NAME} | PKG: ${ASH_PKG_MANAGER} | GPU: ${ASH_GPU_VENDOR} | Laptop: ${ASH_IS_LAPTOP}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 INTERACTIVE PROMPTS (fallback if prompt.sh not loaded)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_confirm() {
    local message="${1:-Continue?}"
    local default="${2:-n}"

    # Auto-yes mode
    if [[ "${ASH_FLAG_YES:-0}" -eq 1 ]] || [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
        ash_log_debug "Auto-confirmed: ${message}"
        return 0
    fi

    local prompt_suffix="[y/N]"
    [[ "${default,,}" == "y" ]] && prompt_suffix="[Y/n]"

    local response
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\033[1;33m?\033[0m %s %s ' "$message" "$prompt_suffix"
    else
        printf '? %s %s ' "$message" "$prompt_suffix"
    fi

    read -r response

    response="${response:-$default}"
    [[ "${response,,}" == "y" ]] || [[ "${response,,}" == "yes" ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 FINALIZE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Initialize platform detection at load time
ash_core_detect_platform
