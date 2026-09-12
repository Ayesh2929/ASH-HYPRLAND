#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║ █████╗ ███████╗██╗  ██╗     ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗        ║
# ║ ██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝        ║
# ║ ███████║███████╗███████║    ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗       ║
# ║ ██╔══██║╚════██║██╔══██║    ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║       ║
# ║ ██║  ██║███████║██║  ██║    ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝       ║
# ║ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝       ║
# ║                                                                                      ║
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG COMMAND DISPATCHER                               ║
# ║  Unified configuration management — get, set, validate, migrate & more            ║
# ║                                                                                      ║
# ║  Author  : Ash Dotfiles Team                                                        ║
# ║  License : MIT                                                                      ║
# ║  Version : 5.0.0-OMEGA                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
# shellcheck disable=SC2154,SC1090,SC1091
set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § BOOTSTRAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_CFG_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_CFG_CMD_DIR}/../../lib"

source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § CONFIG PATH CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
readonly CFG_XDG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/ash"
readonly CFG_MAIN_FILE="${CFG_XDG_DIR}/ash.conf"
readonly CFG_SCHEMA_FILE="${_CFG_CMD_DIR}/../../data/config-schema.json"
readonly CFG_DEFAULTS_FILE="${_CFG_CMD_DIR}/../../data/defaults.conf"
readonly CFG_LOCK_FILE="${ASH_STATE_DIR:-${HOME}/.local/state/ash}/.config.lock"
readonly CFG_BACKUP_DIR="${ASH_STATE_DIR:-${HOME}/.local/state/ash}/config-backups"
readonly CFG_HISTORY_FILE="${ASH_STATE_DIR:-${HOME}/.local/state/ash}/config-history.jsonl"
readonly CFG_MIGRATION_DIR="${_CFG_CMD_DIR}/migrations"
readonly CFG_VERSION_KEY="ash.config.version"
readonly CFG_CURRENT_VERSION="5"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § SCHEMA — Embedded config schema (TOML-style sections with types & defaults)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Format: KEY|TYPE|DEFAULT|DESCRIPTION|ALLOWED_VALUES(optional,|-separated)
readonly -a CFG_SCHEMA=(
    # ── Core ──────────────────────────────────────────────────────────────────
    "ash.config.version|integer|5|Internal config schema version|"
    "ash.debug|boolean|false|Enable debug output globally|true|false"
    "ash.telemetry|boolean|false|Anonymous usage analytics|true|false"
    "ash.auto_update|boolean|true|Check for updates automatically|true|false"
    "ash.update_interval_days|integer|7|Days between update checks|"
    "ash.notifications|boolean|true|Enable desktop notifications|true|false"
    "ash.sound|boolean|true|Enable sound effects|true|false"
    "ash.animation|boolean|true|Enable UI animations|true|false"
    "ash.log_level|string|INFO|Log verbosity level|DEBUG|INFO|WARN|ERROR|SILENT"
    "ash.editor|string||Preferred editor (empty = \$EDITOR)|"
    "ash.shell|string|fish|Preferred shell|fish|bash|zsh"
    "ash.color_depth|string|truecolor|Terminal color support|truecolor|256|8|none"

    # ── Theme ─────────────────────────────────────────────────────────────────
    "theme.default|string|catppuccin-mocha|Default theme name|"
    "theme.auto_dark_light|boolean|false|Auto-switch dark/light by time|true|false"
    "theme.dark_start|string|20:00|Hour to switch to dark theme (HH:MM)|"
    "theme.light_start|string|07:00|Hour to switch to light theme (HH:MM)|"
    "theme.transition_duration|integer|300|Theme transition duration in ms|"
    "theme.transition_type|string|fade|Wallpaper transition type|fade|wipe|grow|wave|outer|random"
    "theme.apply_gtk|boolean|true|Apply theme to GTK apps|true|false"
    "theme.apply_qt|boolean|true|Apply theme to Qt/Kvantum|true|false"
    "theme.apply_cursor|boolean|true|Apply cursor theme|true|false"
    "theme.apply_icons|boolean|true|Apply icon theme|true|false"
    "theme.apply_spicetify|boolean|false|Apply theme to Spotify|true|false"
    "theme.apply_discord|boolean|false|Apply theme to Discord|true|false"
    "theme.apply_vscode|boolean|false|Apply theme to VSCode|true|false"
    "theme.color_scheme|string|auto|Color scheme preference|auto|dark|light"
    "theme.wallpaper_mode|string|fill|Wallpaper scaling mode|fill|fit|stretch|center|tile"

    # ── Wallpaper ─────────────────────────────────────────────────────────────
    "wallpaper.backend|string|swww|Wallpaper daemon backend|swww|swaybg|hyprpaper|mpvpaper"
    "wallpaper.slideshow|boolean|false|Enable wallpaper slideshow|true|false"
    "wallpaper.slideshow_interval|integer|300|Slideshow interval in seconds|"
    "wallpaper.slideshow_shuffle|boolean|true|Shuffle slideshow order|true|false"
    "wallpaper.blur_lockscreen|boolean|true|Blur wallpaper on lockscreen|true|false"
    "wallpaper.blur_strength|integer|5|Blur strength 1-20|"

    # ── Hyprland ──────────────────────────────────────────────────────────────
    "hyprland.animation_preset|string|default|Animation preset|default|smooth|bouncy|snappy|cinematic|minimal|none"
    "hyprland.border_size|integer|2|Window border size in pixels|"
    "hyprland.gaps_in|integer|5|Inner window gaps|"
    "hyprland.gaps_out|integer|10|Outer window gaps|"
    "hyprland.rounding|integer|10|Window corner rounding radius|"
    "hyprland.blur_enabled|boolean|true|Enable blur effect|true|false"
    "hyprland.blur_size|integer|8|Blur size|"
    "hyprland.blur_passes|integer|3|Blur render passes|"
    "hyprland.shadow_enabled|boolean|true|Enable window shadows|true|false"
    "hyprland.inactive_opacity|float|0.9|Inactive window opacity 0.1-1.0|"
    "hyprland.active_opacity|float|1.0|Active window opacity 0.1-1.0|"
    "hyprland.fullscreen_opacity|float|1.0|Fullscreen window opacity|"
    "hyprland.smart_gaps|boolean|false|Enable smart gaps (no gaps solo)|true|false"
    "hyprland.smart_borders|boolean|false|Enable smart borders|true|false"

    # ── Bar ───────────────────────────────────────────────────────────────────
    "bar.backend|string|waybar|Bar backend|waybar|ags|eww"
    "bar.layout|string|top-bar|Bar layout preset|top-bar|bottom-bar|floating-bar|minimal-bar|dual-bar-top|island-bar"
    "bar.height|integer|36|Bar height in pixels|"
    "bar.position|string|top|Bar position|top|bottom"
    "bar.transparency|float|0.85|Bar background transparency|"
    "bar.blur|boolean|true|Enable bar blur|true|false"

    # ── Waybar ────────────────────────────────────────────────────────────────
    "waybar.clock_format|string|%H:%M|Clock format string|"
    "waybar.show_weather|boolean|true|Show weather module|true|false"
    "waybar.show_media|boolean|true|Show media player module|true|false"
    "waybar.show_updates|boolean|true|Show package updates count|true|false"
    "waybar.show_github|boolean|false|Show GitHub notifications|true|false"
    "waybar.show_gpu|boolean|false|Show GPU usage|true|false"
    "waybar.show_cpu|boolean|true|Show CPU usage|true|false"
    "waybar.show_memory|boolean|true|Show memory usage|true|false"
    "waybar.show_disk|boolean|false|Show disk usage|true|false"
    "waybar.show_temp|boolean|true|Show CPU temperature|true|false"
    "waybar.weather_location|string||Weather location (empty = auto-detect)|"
    "waybar.weather_units|string|celsius|Temperature units|celsius|fahrenheit"

    # ── Notifications ─────────────────────────────────────────────────────────
    "notifications.backend|string|dunst|Notification daemon|dunst|swaync"
    "notifications.timeout_low|integer|3000|Low urgency timeout ms|"
    "notifications.timeout_normal|integer|5000|Normal urgency timeout ms|"
    "notifications.timeout_critical|integer|0|Critical timeout ms (0=never)|"
    "notifications.max_history|integer|100|Max notifications in history|"
    "notifications.dnd_on_fullscreen|boolean|true|Auto DND in fullscreen|true|false"

    # ── Lockscreen ────────────────────────────────────────────────────────────
    "lockscreen.backend|string|hyprlock|Lockscreen backend|hyprlock|swaylock"
    "lockscreen.timeout_idle|integer|300|Idle timeout before lock in seconds|"
    "lockscreen.timeout_suspend|integer|600|Idle timeout before suspend|"
    "lockscreen.show_clock|boolean|true|Show clock on lockscreen|true|false"
    "lockscreen.show_date|boolean|true|Show date on lockscreen|true|false"
    "lockscreen.show_weather|boolean|false|Show weather on lockscreen|true|false"

    # ── Snapshot ──────────────────────────────────────────────────────────────
    "snapshot.auto_enabled|boolean|false|Enable automatic snapshots|true|false"
    "snapshot.auto_interval_hours|integer|24|Hours between auto-snapshots|"
    "snapshot.auto_max_keep|integer|10|Max auto-snapshots to retain|"
    "snapshot.auto_on_theme|boolean|true|Snapshot before theme changes|true|false"
    "snapshot.auto_on_update|boolean|true|Snapshot before updates|true|false"
    "snapshot.compress|boolean|true|Compress snapshot archives|true|false"
    "snapshot.dir|string||Override snapshot storage dir (empty = default)|"

    # ── AI ────────────────────────────────────────────────────────────────────
    "ai.enabled|boolean|false|Enable AI features|true|false"
    "ai.backend|string|ollama|AI backend|ollama|openai|anthropic"
    "ai.model|string|llama3|AI model name|"
    "ai.ollama_host|string|http://localhost:11434|Ollama host URL|"
    "ai.theme_suggestions|boolean|true|AI theme suggestions|true|false"
    "ai.auto_theme_mood|boolean|false|Auto theme based on mood|true|false"
    "ai.auto_theme_weather|boolean|false|Auto theme based on weather|true|false"
    "ai.auto_theme_time|boolean|true|Auto theme based on time|true|false"

    # ── Privacy ───────────────────────────────────────────────────────────────
    "privacy.clear_clipboard_timeout|integer|0|Clear clipboard after N seconds (0=never)|"
    "privacy.history_enabled|boolean|true|Enable command/action history|true|false"
    "privacy.analytics_opt_out|boolean|true|Opt out of analytics|true|false"

    # ── Performance ───────────────────────────────────────────────────────────
    "performance.profile|string|balanced|Performance profile|performance|balanced|power-save|gaming"
    "performance.cpu_governor|string|schedutil|CPU frequency governor|performance|schedutil|powersave|ondemand"
    "performance.gpu_performance_level|string|auto|GPU performance level|auto|high|medium|low"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § INTERNAL HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cfg::bootstrap() {
    mkdir -p "${CFG_XDG_DIR}" "${CFG_BACKUP_DIR}" \
        "${ASH_STATE_DIR:-${HOME}/.local/state/ash}" 2>/dev/null || true
    [[ ! -f "${CFG_MAIN_FILE}" ]] && cfg::_write_defaults
}

cfg::_write_defaults() {
    cat > "${CFG_MAIN_FILE}" <<EOF
# ╔══════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Configuration File           ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                              ║
# ║  Edit with: ash config edit                             ║
# ╚══════════════════════════════════════════════════════════╝
# Format: key = value
# Comments begin with #
# Keys are dot-separated sections (e.g. theme.default)

EOF
    for schema_line in "${CFG_SCHEMA[@]}"; do
        IFS='|' read -r key type default desc _ <<< "${schema_line}"
        if [[ -n "${default}" ]]; then
            printf '%-45s = %s\n' "${key}" "${default}" >> "${CFG_MAIN_FILE}"
        else
            printf '# %-44s =\n' "${key}" >> "${CFG_MAIN_FILE}"
        fi
    done
    printf '\n# End of configuration\n' >> "${CFG_MAIN_FILE}"
}

# ── Lock ──────────────────────────────────────────────────────────────────────
cfg::lock()    { lock::acquire 10; }
cfg::unlock()  { lock::release; }

# ── History ───────────────────────────────────────────────────────────────────
cfg::_record() {
    local action="$1" key="${2:-}" old_val="${3:-}" new_val="${4:-}"
    local entry
    entry=$(jq -cn \
        --arg action  "${action}" \
        --arg key     "${key}" \
        --arg old     "${old_val}" \
        --arg new     "${new_val}" \
        --arg user    "${USER:-unknown}" \
        --argjson ts  "$(date +%s)" \
        '{action:$action,key:$key,old_value:$old,new_value:$new,user:$user,timestamp:$ts}')
    printf '%s\n' "${entry}" >> "${CFG_HISTORY_FILE}"
    # Rotate: keep last 1000 lines
    local lc; lc=$(wc -l < "${CFG_HISTORY_FILE}" 2>/dev/null || echo 0)
    if (( lc > 1000 )); then
        local tmp; tmp=$(mktemp)
        tail -1000 "${CFG_HISTORY_FILE}" > "${tmp}" && mv "${tmp}" "${CFG_HISTORY_FILE}"
    fi
}

# ── Raw file read/write ───────────────────────────────────────────────────────
cfg::_read_raw() {
    # Returns the raw string value for a key, empty string if not set
    local key="$1" file="${2:-${CFG_MAIN_FILE}}"
    [[ ! -f "${file}" ]] && return 0
    grep -E "^[[:space:]]*$(printf '%s' "${key}" | sed 's/\./\\./g')[[:space:]]*=" \
        "${file}" 2>/dev/null \
        | tail -1 \
        | sed -E 's/^[^=]+=\s*//' \
        | sed -E 's/^["\x27]//; s/["\x27]$//' \
        | sed -E 's/#.*$//' \
        | sed -E 's/[[:space:]]*$//'
}

cfg::_write_raw() {
    # Write or update key=value in the config file
    local key="$1" value="$2" file="${3:-${CFG_MAIN_FILE}}"
    local escaped_key
    escaped_key=$(printf '%s' "${key}" | sed 's/\./\\./g')

    if grep -qE "^[[:space:]]*${escaped_key}[[:space:]]*=" "${file}" 2>/dev/null; then
        # Update existing
        sed -i -E "s|^([[:space:]]*)${escaped_key}([[:space:]]*)=.*|\1${key}\2= ${value}|" \
            "${file}"
    else
        # Append — find or create section header
        local section; section=$(printf '%s' "${key}" | cut -d. -f1)
        if grep -q "^\[${section}\]" "${file}" 2>/dev/null; then
            sed -i "/^\[${section}\]/a ${key} = ${value}" "${file}"
        else
            printf '\n%-45s = %s\n' "${key}" "${value}" >> "${file}"
        fi
    fi
}

cfg::_delete_raw() {
    local key="$1" file="${2:-${CFG_MAIN_FILE}}"
    local escaped_key
    escaped_key=$(printf '%s' "${key}" | sed 's/\./\\./g')
    sed -i -E "/^[[:space:]]*${escaped_key}[[:space:]]*=/d" "${file}"
}

# ── Schema lookup ─────────────────────────────────────────────────────────────
cfg::_schema_entry() {
    local key="$1"
    for line in "${CFG_SCHEMA[@]}"; do
        local k; IFS='|' read -r k _ <<< "${line}"
        [[ "${k}" == "${key}" ]] && { printf '%s' "${line}"; return 0; }
    done
    return 1
}

cfg::_schema_type()    { local e; e=$(cfg::_schema_entry "$1") && IFS='|' read -r _ t _ <<< "${e}" && printf '%s' "${t}"; }
cfg::_schema_default() { local e; e=$(cfg::_schema_entry "$1") && IFS='|' read -r _ _ d _ <<< "${e}" && printf '%s' "${d}"; }
cfg::_schema_desc()    { local e; e=$(cfg::_schema_entry "$1") && IFS='|' read -r _ _ _ d _ <<< "${e}" && printf '%s' "${d}"; }

cfg::_schema_allowed() {
    local key="$1"
    local e; e=$(cfg::_schema_entry "${key}") || return 1
    # Allowed values are fields 5+ (index 4+)
    IFS='|' read -ra parts <<< "${e}"
    local allowed=()
    for (( i=4; i<${#parts[@]}; i++ )); do
        [[ -n "${parts[$i]}" ]] && allowed+=("${parts[$i]}")
    done
    (( ${#allowed[@]} > 0 )) && printf '%s\n' "${allowed[@]}"
}

cfg::_key_exists_in_schema() {
    cfg::_schema_entry "$1" &>/dev/null
}

# ── Value type coercion & validation ─────────────────────────────────────────
cfg::_validate_value() {
    local key="$1" value="$2"
    local type; type=$(cfg::_schema_type "${key}" 2>/dev/null) || return 0
    local allowed_vals
    mapfile -t allowed_vals < <(cfg::_schema_allowed "${key}" 2>/dev/null || true)

    # Type check
    case "${type}" in
        boolean)
            [[ "${value}" =~ ^(true|false|1|0|yes|no|on|off)$ ]] || {
                log::error "Invalid boolean: '${value}' — must be true or false"
                return 1
            }
            ;;
        integer)
            [[ "${value}" =~ ^-?[0-9]+$ ]] || {
                log::error "Invalid integer: '${value}'"
                return 1
            }
            ;;
        float)
            [[ "${value}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || {
                log::error "Invalid float: '${value}'"
                return 1
            }
            ;;
        string)
            : ;;  # any string is valid
    esac

    # Allowed values check
    if (( ${#allowed_vals[@]} > 0 )); then
        local match=false
        for av in "${allowed_vals[@]}"; do
            [[ "${value}" == "${av}" ]] && { match=true; break; }
        done
        if [[ "${match}" == "false" ]]; then
            log::error "Invalid value '${value}' for '${key}'"
            log::info  "Allowed: $(IFS=', '; printf '%s' "${allowed_vals[*]}")"
            return 1
        fi
    fi
    return 0
}

# ── Normalise boolean values ──────────────────────────────────────────────────
cfg::_normalise_bool() {
    case "${1,,}" in
        1|yes|on|true)  printf 'true'  ;;
        0|no|off|false) printf 'false' ;;
        *)              printf '%s' "$1" ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "⚙  ASH CONFIG SYSTEM" \
        "Unified configuration management • get set unset validate migrate" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config <subcommand> [args] [options]

${BOLD}${ASH_PRIMARY}SUBCOMMANDS${RST}
  ${ASH_ACCENT}get${RST}        <key>              Read a config value
  ${ASH_ACCENT}set${RST}        <key> <value>       Write a config value
  ${ASH_ACCENT}unset${RST}      <key>              Remove a key (restore default)
  ${ASH_ACCENT}list${RST}       [section] [opts]   Browse all config keys & values
  ${ASH_ACCENT}reset${RST}      [section] [opts]   Reset keys to defaults
  ${ASH_ACCENT}export${RST}     [opts]             Export config as JSON/TOML/env
  ${ASH_ACCENT}import${RST}     <file> [opts]      Import config from file
  ${ASH_ACCENT}edit${RST}       [opts]             Open config in \$EDITOR
  ${ASH_ACCENT}validate${RST}   [opts]             Validate config against schema
  ${ASH_ACCENT}migrate${RST}    [opts]             Migrate config to latest version

${BOLD}${ASH_PRIMARY}GLOBAL OPTIONS${RST}
  ${ASH_MUTED}--file,  -f FILE${RST}   Use alternate config file
  ${ASH_MUTED}--debug${RST}            Enable debug output
  ${ASH_MUTED}--no-color${RST}         Disable colored output
  ${ASH_MUTED}--help,  -h${RST}         Show this help

${BOLD}${ASH_PRIMARY}QUICK REFERENCE${RST}
  ${FG_BBLACK}# Read theme setting${RST}
  ${ASH_ACCENT}ash config get${RST} theme.default

  ${FG_BBLACK}# Change default theme${RST}
  ${ASH_ACCENT}ash config set${RST} theme.default catppuccin-mocha

  ${FG_BBLACK}# List all theme settings${RST}
  ${ASH_ACCENT}ash config list${RST} theme

  ${FG_BBLACK}# Validate current config${RST}
  ${ASH_ACCENT}ash config validate${RST}

  ${FG_BBLACK}# Export for backup${RST}
  ${ASH_ACCENT}ash config export${RST} --format json --output ~/ash-config-backup.json

${BOLD}${ASH_PRIMARY}CONFIG FILE${RST}
  ${ASH_MUTED}Location: ${ASH_INFO}${CFG_MAIN_FILE}${RST}
  ${ASH_MUTED}Version:  ${ASH_INFO}v${CFG_CURRENT_VERSION}${RST}

${BOLD}${ASH_PRIMARY}SECTIONS${RST}
  ${ASH_MUTED}ash         Core CLI settings
  theme       Theme engine settings
  wallpaper   Wallpaper daemon settings
  hyprland    Hyprland compositor settings
  bar         Status bar settings
  waybar      Waybar-specific settings
  notifications  Notification daemon settings
  lockscreen  Lock screen settings
  snapshot    Snapshot system settings
  ai          AI/ML feature settings
  privacy     Privacy & telemetry settings
  performance Performance profile settings${RST}

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::main() {
    cfg::bootstrap

    # ── Global flags ──────────────────────────────────────────────────────────
    local _config_file="${CFG_MAIN_FILE}"
    while [[ "${1:-}" == --* ]]; do
        case "$1" in
            --file|-f)   _config_file="${2:?'--file requires PATH'}"; shift 2 ;;
            --debug)     ASH_LOG_LEVEL="DEBUG"; shift ;;
            --no-color)  ASH_COLOR_SUPPORT=false; shift ;;
            --help|-h)   config::help; return 0 ;;
            *)           break ;;
        esac
    done

    # Export so subcommands can access
    export CFG_ACTIVE_FILE="${_config_file}"

    local subcmd="${1:-help}"
    shift || true

    case "${subcmd}" in
        get)       source "${_CFG_CMD_DIR}/get.sh";      config::get      "$@" ;;
        set)       source "${_CFG_CMD_DIR}/set.sh";      config::set      "$@" ;;
        unset)     source "${_CFG_CMD_DIR}/unset.sh";    config::unset    "$@" ;;
        list|ls)   source "${_CFG_CMD_DIR}/list.sh";     config::list     "$@" ;;
        reset)     source "${_CFG_CMD_DIR}/reset.sh";    config::reset    "$@" ;;
        export)    source "${_CFG_CMD_DIR}/export.sh";   config::export   "$@" ;;
        import)    source "${_CFG_CMD_DIR}/import.sh";   config::import   "$@" ;;
        edit)      source "${_CFG_CMD_DIR}/edit.sh";     config::edit     "$@" ;;
        validate)  source "${_CFG_CMD_DIR}/validate.sh"; config::validate "$@" ;;
        migrate)   source "${_CFG_CMD_DIR}/migrate.sh";  config::migrate  "$@" ;;
        help|--help|-h) config::help ;;
        *)
            log::error "Unknown subcommand: '${subcmd}'"
            log::info  "Run ${BOLD}ash config --help${RST} for usage"
            return 1
            ;;
    esac
}

# Executing this file directly still works; sourcing it — which is how the
# dispatcher loads it — must only define the entry point. The unconditional
# `config::main "$@"` that used to sit here ran the entire command at source time.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    config::main "$@"
fi

# ── Dispatcher entry point ────────────────────────────────────────────────────
# The ash dispatcher sources this file and calls ash_cmd_<category>. Without
# this function the command reported "Command function not found" after already
# having run itself once at source time.
ash_cmd_config() {
    config::main "$@"
}
