#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗  █████╗  ██████╗██╗  ██╗██╗   ██╗██████╗                               ║
# ║  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗                              ║
# ║  ██████╔╝███████║██║     █████╔╝ ██║   ██║██████╔╝                              ║
# ║  ██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔═══╝                               ║
# ║  ██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║                                   ║
# ║  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝                                   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  BACKUP COMMAND DISPATCHER                               ║
# ║  Complete backup management hub: create • restore • schedule • encrypt • verify ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_BACKUP_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_BACKUP_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _BK_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _BK_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _BK_DEFAULT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash/backups"
declare -gr _BK_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/backup"
declare -gr _BK_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/backup"
declare -gr _BK_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash/backup"
declare -gr _BK_MANIFEST_DIR="${_BK_STATE_DIR}/manifests"
declare -gr _BK_LOG_FILE="${_BK_STATE_DIR}/backup.log"
declare -gr _BK_SCHEDULE_FILE="${_BK_CONFIG_DIR}/schedule.conf"
declare -gr _BK_GPGKEY_FILE="${_BK_CONFIG_DIR}/gpgkey"
declare -gr _BK_INDEX_FILE="${_BK_STATE_DIR}/index.json"

# Default backup targets (can be overridden in config)
declare -ga _BK_DEFAULT_TARGETS=(
    "${XDG_CONFIG_HOME:-$HOME/.config}"
    "${HOME}/.ssh"
    "${HOME}/.gnupg"
    "${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bk()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_bkr()     { _bk '\033[0m';                          }
_bkbold()  { _bk '\033[1m';                          }
_bkdim()   { _bk '\033[38;2;108;112;134m';           }
_bkmauve() { _bk '\033[1;38;2;203;166;247m';         }
_bkblue()  { _bk '\033[38;2;137;180;250m';           }
_bkgreen() { _bk '\033[38;2;166;227;161m';           }
_bkpeach() { _bk '\033[38;2;250;179;135m';           }
_bkyellow(){ _bk '\033[1;38;2;249;226;175m';         }
_bkred()   { _bk '\033[1;38;2;243;139;168m';         }
_bkteal()  { _bk '\033[38;2;148;226;213m';           }
_bksky()   { _bk '\033[38;2;137;220;235m';           }
_bklav()   { _bk '\033[38;2;180;190;254m';           }
_bkpink()  { _bk '\033[38;2;245;194;231m';           }
_bksapph() { _bk '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_section() {
    local icon="$1"  title="$2"  color="${3:-$(_bkmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_bkr)"
    printf '%s  %s%s\n' "$(_bkdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_bkr)"
}

bk_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_bkgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_bkdim)" "${key}:" "$(_bkr)" "$vc" "$val" "$(_bkr)"
}

bk_ok()    { printf '  %s✓%s  %s\n' "$(_bkgreen)"  "$(_bkr)" "$1"; }
bk_fail()  { printf '  %s✗%s  %s\n' "$(_bkred)"    "$(_bkr)" "$1"; }
bk_info()  { printf '  %sℹ%s  %s\n' "$(_bkdim)"    "$(_bkr)" "$1"; }
bk_warn()  { printf '  %s⚠%s  %s\n' "$(_bkyellow)" "$(_bkr)" "$1"; }
bk_step()  { printf '  %s→%s  %s\n' "$(_bkteal)"   "$(_bkr)" "$1"; }

bk_divider() {
    printf '%s  %s%s\n' "$(_bkdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_bkr)"
}

bk_badge() {
    local text="$1"  color="${2:-$(_bkblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_bkbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROGRESS BAR WITH ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_progress() {
    local pct="$1"  label="${2:-Progress}"  width="${3:-40}"
    local filled=$(( pct * width / 100 ))
    (( filled > width )) && filled=$width
    local empty=$(( width - filled ))

    local bc
    if   (( pct >= 90 )); then bc="$(_bkgreen)"
    elif (( pct >= 60 )); then bc="$(_bkblue)"
    elif (( pct >= 30 )); then bc="$(_bkpeach)"
    else                       bc="$(_bkyellow)"
    fi

    printf '\r  %s%-22s%s [%s%s%s%s%s]  %s%3d%%%s' \
        "$(_bkdim)" "$label" "$(_bkr)" \
        "$bc" "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(_bkdim)" "$(printf '░%.0s' $(seq 1 $empty))" "$(_bkr)" \
        "$(_bkbold)$bc" "$pct" "$(_bkr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SPINNER ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _BK_SPIN_PID=""

bk_spin_start() {
    local msg="$1"
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0
    tput civis 2>/dev/null || true
    while true; do
        printf '\r  %s%s%s  %s' "$(_bkblue)" "${frames[$i]}" "$(_bkr)" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.08
    done &
    _BK_SPIN_PID=$!
}

bk_spin_stop() {
    local ok="${1:-1}"
    [[ -n "$_BK_SPIN_PID" ]] && kill "$_BK_SPIN_PID" 2>/dev/null || true
    _BK_SPIN_PID=""
    tput cnorm 2>/dev/null || true
    printf '\r  %-60s\n' ""
    [[ $ok -eq 1 ]] && bk_ok "${2:-Done}" || bk_fail "${2:-Failed}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HUMAN-READABLE SIZE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_human_size() {
    local bytes="${1:-0}"
    if   (( bytes >= 1099511627776 )); then printf '%.2f TB' "$(echo "scale=2;$bytes/1099511627776"|bc -l 2>/dev/null||echo 0)"
    elif (( bytes >= 1073741824    )); then printf '%.2f GB' "$(echo "scale=2;$bytes/1073741824"   |bc -l 2>/dev/null||echo 0)"
    elif (( bytes >= 1048576       )); then printf '%.2f MB' "$(echo "scale=2;$bytes/1048576"      |bc -l 2>/dev/null||echo 0)"
    elif (( bytes >= 1024          )); then printf '%.1f KB' "$(echo "scale=1;$bytes/1024"         |bc -l 2>/dev/null||echo 0)"
    else printf '%d B' "$bytes"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LOGGING ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_log() {
    local level="$1"  msg="$2"
    local ts
    ts="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    mkdir -p "$(dirname "$_BK_LOG_FILE")" 2>/dev/null || true
    printf '[%s] [%-7s] %s\n' "$ts" "$level" "$msg" >> "$_BK_LOG_FILE" 2>/dev/null || true
}

bk_log_info()  { bk_log "INFO"    "$@"; }
bk_log_warn()  { bk_log "WARN"    "$@"; }
bk_log_error() { bk_log "ERROR"   "$@"; }
bk_log_ok()    { bk_log "SUCCESS" "$@"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKUP INDEX (JSON registry of all backups)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_index_add() {
    local id="$1"  path="$2"  type="$3"  size="$4"
    local encrypted="${5:-false}"  tags="${6:-}"
    local ts
    ts="$(date -Iseconds)"

    mkdir -p "$(dirname "$_BK_INDEX_FILE")" 2>/dev/null || true

    local existing="{}"
    [[ -f "$_BK_INDEX_FILE" ]] && \
        existing="$(cat "$_BK_INDEX_FILE" 2>/dev/null || echo '{}')"

    python3 - "$id" "$path" "$type" "$size" "$encrypted" "$tags" "$ts" \
        "$existing" << 'PYEOF' > "${_BK_INDEX_FILE}.tmp" 2>/dev/null && \
        mv "${_BK_INDEX_FILE}.tmp" "$_BK_INDEX_FILE" 2>/dev/null || true
import json, sys

bk_id, path, bk_type, size, encrypted, tags, ts, existing_json = sys.argv[1:]

try:
    data = json.loads(existing_json)
except:
    data = {}

data[bk_id] = {
    "id":        bk_id,
    "path":      path,
    "type":      bk_type,
    "size":      int(size) if size.isdigit() else 0,
    "encrypted": encrypted == "true",
    "tags":      [t.strip() for t in tags.split(",") if t.strip()],
    "created_at": ts,
    "status":    "ok",
}

print(json.dumps(data, indent=2))
PYEOF
}

bk_index_remove() {
    local id="$1"
    [[ -f "$_BK_INDEX_FILE" ]] || return 0
    python3 -c "
import json, sys
data = json.load(open('${_BK_INDEX_FILE}'))
data.pop('${id}', None)
open('${_BK_INDEX_FILE}', 'w').write(json.dumps(data, indent=2))
" 2>/dev/null || true
}

bk_index_get() {
    local id="$1"  field="$2"
    [[ -f "$_BK_INDEX_FILE" ]] || return 0
    python3 -c "
import json
data = json.load(open('${_BK_INDEX_FILE}'))
entry = data.get('${id}', {})
print(entry.get('${field}', ''))
" 2>/dev/null || echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKUP STATUS OVERVIEW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_status_frame() {
    bk_section "💾" "Backup Status" "$(_bkblue)"

    bk_kv "Backup dir" "${_BK_DEFAULT_DIR/#$HOME/~}"

    # Count backups
    local bk_count=0  bk_size=0
    if [[ -f "$_BK_INDEX_FILE" ]]; then
        read -r bk_count bk_size < <(python3 -c "
import json
data = json.load(open('${_BK_INDEX_FILE}'))
total_size = sum(v.get('size',0) for v in data.values())
print(len(data), total_size)
" 2>/dev/null || echo "0 0")
    fi

    bk_kv "Total backups"  "$bk_count"
    [[ $bk_size -gt 0 ]] && bk_kv "Total size" "$(bk_human_size "$bk_size")"

    # Last backup info
    if [[ -f "$_BK_INDEX_FILE" ]]; then
        local last_id last_ts last_type
        read -r last_id last_ts last_type < <(python3 -c "
import json
data = json.load(open('${_BK_INDEX_FILE}'))
if data:
    last = max(data.values(), key=lambda x: x.get('created_at',''))
    print(last.get('id','?'), last.get('created_at','?'), last.get('type','?'))
else:
    print('none ? ?')
" 2>/dev/null || echo "none ? ?")

        if [[ "$last_id" != "none" ]]; then
            bk_kv "Last backup"  "$last_id"
            bk_kv "Last created" "$last_ts"
            bk_kv "Last type"    "$last_type"
        fi
    fi

    # Schedule status
    if [[ -f "$_BK_SCHEDULE_FILE" ]]; then
        bk_kv "Schedule"   "$(gm_badge " CONFIGURED " "$(_bkgreen)" 2>/dev/null || echo 'configured')"
    fi

    # Encryption key
    if [[ -f "$_BK_GPGKEY_FILE" ]] || gpg --list-secret-keys &>/dev/null 2>&1; then
        bk_kv "Encryption" "$(bk_badge " GPG READY " "$(_bkteal)")"
    fi

    # Storage free space
    local free_space
    free_space="$(df -h "$_BK_DEFAULT_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo '?')"
    bk_kv "Free space"    "$free_space"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_notify() {
    local title="$1"  body="$2"  urgency="${3:-normal}"
    [[ "${ASH_BK_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" \
        --urgency="$urgency" \
        --icon=document-save \
        --expire-time=5000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bk_ensure_dirs() {
    mkdir -p \
        "$_BK_DEFAULT_DIR" \
        "$_BK_STATE_DIR" \
        "$_BK_CACHE_DIR" \
        "$_BK_CONFIG_DIR" \
        "$_BK_MANIFEST_DIR" \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bk_load_sub() {
    local sub="$1"
    local sub_file="${_BK_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  backup sub-command not found: %s%s\n\n' \
            "$(_bkred)" "$sub" "$(_bkr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bk_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;180;250m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  💾  ASH  ─  backup  (Backup Manager)                    ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_bksky)"  cd="$(_bkdim)"  cs="$(_bkmauve)"  cr="$(_bkr)"

    printf '\n%sUSAGE%s\n' "$(_bkbold)" "$cr"
    printf '   ash backup [sub-command] [flags]\n'
    printf '   ash bk [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:💾:Show backup status and statistics"
        "create:✨:Create a new backup (full/incremental/differential)"
        "restore:⏪:Restore from a backup"
        "list:📋:List all backups with metadata"
        "schedule:⏰:Manage automated backup schedules"
        "verify:🔍:Verify backup integrity (checksums)"
        "encrypt:🔐:Encrypt/decrypt backup files"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-12s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--dest=PATH%s      Custom backup destination\n'   "$cc" "$cr"
    printf '   %s--compress=TYPE%s  Compression (zstd/gzip/xz/none)\n' "$cc" "$cr"
    printf '   %s--encrypt%s        Encrypt backup with GPG\n'     "$cc" "$cr"
    printf '   %s--tag=LABEL%s      Tag backup with label\n'       "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress notifications\n'      "$cc" "$cr"
    printf '   %s--json%s           JSON output\n'                 "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash bk status%s              Backup overview\n'          "$cc" "$cr"
    printf '   %sash bk create%s              Full backup\n'              "$cc" "$cr"
    printf '   %sash bk create --encrypt%s    Encrypted backup\n'        "$cc" "$cr"
    printf '   %sash bk list%s                Show all backups\n'         "$cc" "$cr"
    printf '   %sash bk restore%s             Interactive restore\n'      "$cc" "$cr"
    printf '   %sash bk verify BACKUP_ID%s    Verify backup integrity\n' "$cc" "$cr"
    printf '   %sash bk schedule daily 02:00%s  Daily at 2am\n'          "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_backup() {
    local sub="${1:-status}"
    shift || true

    local -a fwd_args=()
    for arg in "${@:-}"; do
        case "$arg" in
            --no-notify)       export ASH_BK_NO_NOTIFY=1       ;;
            --json)            export ASH_FLAG_JSON_OUTPUT=1   ;;
            --dest=*)          export ASH_BK_DEST="${arg#*=}"   ;;
            --compress=*)      export ASH_BK_COMPRESS="${arg#*=}" ;;
            --encrypt)         export ASH_BK_ENCRYPT=1         ;;
            --tag=*)           export ASH_BK_TAG="${arg#*=}"    ;;
            *)                 fwd_args+=("$arg")              ;;
        esac
    done

    bk_ensure_dirs

    case "$sub" in
        help|-h|--help) _bk_help ;;

        status|info)
            bk_status_frame
            printf '\n'
            ;;

        create|restore|list|schedule|verify|encrypt)
            _bk_load_sub "$sub" || return 1
            local fn="ash_backup_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                bk_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_bkred)" "$sub" "$(_bkr)" >&2
            printf '%sRun: ash backup help%s\n\n' "$(_bkdim)" "$(_bkr)" >&2
            return 1
            ;;
    esac
}

# Alias
ash_cmd_bk() { ash_cmd_backup "$@"; }
