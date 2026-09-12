#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Core Utilities                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_UTILS_LOADED:-}" ]] && return 0
readonly _ASH_UTILS_LOADED=1

source "${BASH_SOURCE[0]%/*}/colors.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"

# ── Paths ──────────────────────────────────────────────────────────────────────
ASH_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
ASH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
ASH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
ASH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
ASH_SNAPSHOT_DIR="${ASH_DATA_DIR}/snapshots"
ASH_SNAPSHOT_INDEX="${ASH_SNAPSHOT_DIR}/.index.json"
ASH_SNAPSHOT_LOCK="${ASH_STATE_DIR}/.snapshot.lock"

# ── Directory Bootstrap ────────────────────────────────────────────────────────
utils::bootstrap_dirs() {
    local dirs=(
        "${ASH_DATA_DIR}"
        "${ASH_STATE_DIR}"
        "${ASH_CACHE_DIR}"
        "${ASH_CONFIG_DIR}"
        "${ASH_SNAPSHOT_DIR}"
    )
    for d in "${dirs[@]}"; do
        mkdir -p "${d}" 2>/dev/null || {
            log::error "Cannot create directory: ${d}"
            return 1
        }
    done
}

# ── JSON Helpers ───────────────────────────────────────────────────────────────
json::get() {
    # json::get <file> <key>  — portable jq wrapper with python fallback
    local file="$1" key="$2"
    if command -v jq &>/dev/null; then
        jq -r "${key} // empty" "${file}" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json,sys
data=json.load(open('${file}'))
keys='${key}'.lstrip('.').split('.')
val=data
for k in keys:
    if k: val=val.get(k,{}) if isinstance(val,dict) else ''
print(val if not isinstance(val,dict) else json.dumps(val))
" 2>/dev/null
    else
        log::error "jq or python3 required for JSON parsing"
        return 1
    fi
}

json::set() {
    local file="$1" key="$2" value="$3"
    if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq "${key} = ${value}" "${file}" > "${tmp}" && mv "${tmp}" "${file}"
    else
        log::error "jq required for JSON modification"
        return 1
    fi
}

json::append_array() {
    # Append object to a JSON array at key
    local file="$1" array_key="$2" object="$3"
    if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq "${array_key} += [${object}]" "${file}" > "${tmp}" && mv "${tmp}" "${file}"
    fi
}

# ── Index Management ───────────────────────────────────────────────────────────
index::init() {
    if [[ ! -f "${ASH_SNAPSHOT_INDEX}" ]]; then
        cat > "${ASH_SNAPSHOT_INDEX}" <<'EOF'
{
  "version": 1,
  "snapshots": []
}
EOF
    fi
}

index::get_all() {
    index::init
    jq -r '.snapshots' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo '[]'
}

index::find_by_id() {
    local id="$1"
    index::init
    jq -r --arg id "${id}" \
        '.snapshots[] | select(.id == $id or (.id | startswith($id)))' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null
}

index::find_by_name() {
    local name="$1"
    index::init
    jq -r --arg name "${name}" \
        '.snapshots[] | select(.name == $name)' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null
}

index::add() {
    local entry="$1"
    index::init
    local tmp
    tmp=$(mktemp)
    jq --argjson entry "${entry}" '.snapshots += [$entry]' \
        "${ASH_SNAPSHOT_INDEX}" > "${tmp}" && mv "${tmp}" "${ASH_SNAPSHOT_INDEX}"
}

index::remove() {
    local id="$1"
    index::init
    local tmp
    tmp=$(mktemp)
    jq --arg id "${id}" \
        '.snapshots = [.snapshots[] | select(.id != $id)]' \
        "${ASH_SNAPSHOT_INDEX}" > "${tmp}" && mv "${tmp}" "${ASH_SNAPSHOT_INDEX}"
}

index::update_field() {
    local id="$1" field="$2" value="$3"
    index::init
    local tmp
    tmp=$(mktemp)
    jq --arg id "${id}" \
       --arg field "${field}" \
       --argjson value "${value}" \
       '(.snapshots[] | select(.id == $id) | .[$field]) = $value' \
        "${ASH_SNAPSHOT_INDEX}" > "${tmp}" && mv "${tmp}" "${ASH_SNAPSHOT_INDEX}"
}

# ── Lock File ──────────────────────────────────────────────────────────────────
lock::acquire() {
    local timeout="${1:-30}"
    local waited=0

    while [[ -f "${ASH_SNAPSHOT_LOCK}" ]]; do
        local lock_pid
        lock_pid=$(cat "${ASH_SNAPSHOT_LOCK}" 2>/dev/null || echo 0)

        if ! kill -0 "${lock_pid}" 2>/dev/null; then
            log::warn "Removing stale lock (PID ${lock_pid} is dead)"
            rm -f "${ASH_SNAPSHOT_LOCK}"
            break
        fi

        (( waited >= timeout )) && {
            log::error "Could not acquire lock within ${timeout}s (held by PID ${lock_pid})"
            return 1
        }

        log::debug "Waiting for lock… (${waited}s)"
        sleep 1
        (( waited += 1 ))
    done

    printf '%d' "$$" > "${ASH_SNAPSHOT_LOCK}"
    trap 'rm -f "${ASH_SNAPSHOT_LOCK}"' EXIT INT TERM
}

lock::release() {
    rm -f "${ASH_SNAPSHOT_LOCK}"
}

# ── Checksum ───────────────────────────────────────────────────────────────────
utils::checksum_dir() {
    local dir="$1"
    if command -v sha256sum &>/dev/null; then
        find "${dir}" -type f | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}'
    elif command -v shasum &>/dev/null; then
        find "${dir}" -type f | sort | xargs shasum -a 256 2>/dev/null | shasum -a 256 | awk '{print $1}'
    else
        date +%s%N | sha1sum | awk '{print $1}'
    fi
}

# ── Human-Readable Size ────────────────────────────────────────────────────────
utils::human_size() {
    local bytes="$1"
    if (( bytes < 1024 )); then
        printf '%d B' "${bytes}"
    elif (( bytes < 1048576 )); then
        printf '%.1f KiB' "$(echo "scale=1; ${bytes}/1024" | bc 2>/dev/null || echo 0)"
    elif (( bytes < 1073741824 )); then
        printf '%.1f MiB' "$(echo "scale=1; ${bytes}/1048576" | bc 2>/dev/null || echo 0)"
    else
        printf '%.2f GiB' "$(echo "scale=2; ${bytes}/1073741824" | bc 2>/dev/null || echo 0)"
    fi
}

# ── Relative Time ──────────────────────────────────────────────────────────────
utils::relative_time() {
    local epoch="$1"
    local now
    now=$(date +%s)
    local diff=$(( now - epoch ))

    if   (( diff < 60 ));     then printf 'just now'
    elif (( diff < 3600 ));   then printf '%dm ago' $(( diff / 60 ))
    elif (( diff < 86400 ));  then printf '%dh ago' $(( diff / 3600 ))
    elif (( diff < 604800 )); then printf '%dd ago' $(( diff / 86400 ))
    elif (( diff < 2592000 )); then printf '%dw ago' $(( diff / 604800 ))
    else                           printf '%dmo ago' $(( diff / 2592000 ))
    fi
}

# ── Confirmation Prompt ────────────────────────────────────────────────────────
utils::confirm() {
    local msg="${1:-Are you sure?}" default="${2:-n}"
    local prompt choices

    if [[ "${default,,}" == "y" ]]; then
        choices="[Y/n]"
    else
        choices="[y/N]"
    fi

    printf '\n  %s%s%s  %s %s%s%s ' \
        "${ASH_WARNING}" "${ICO_WARN}" "${RST}" \
        "${msg}" \
        "${ASH_MUTED}" "${choices}" "${RST}"

    local answer
    read -r answer
    answer="${answer:-${default}}"

    [[ "${answer,,}" == "y" ]]
}

# ── Dependency Check ───────────────────────────────────────────────────────────
utils::require() {
    local missing=()
    for cmd in "$@"; do
        command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
    done

    if (( ${#missing[@]} > 0 )); then
        log::error "Missing required tools: ${missing[*]}"
        log::info  "Install with: paru -S ${missing[*]}"
        return 1
    fi
}

# ── Snapshot ID Generator ──────────────────────────────────────────────────────
utils::generate_id() {
    # Format: snap-YYYYMMDD-HHMMSS-XXXX (4 random hex chars)
    local ts rand
    ts=$(date '+%Y%m%d-%H%M%S')
    rand=$(head -c 2 /dev/urandom 2>/dev/null | od -A n -t x1 | tr -d ' \n' | head -c 4)
    printf 'snap-%s-%s' "${ts}" "${rand}"
}

# ── Config Targets ─────────────────────────────────────────────────────────────
# Files/dirs included in snapshots
SNAPSHOT_TARGETS=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    "${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
    "${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
    "${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
    "${XDG_CONFIG_HOME:-$HOME/.config}/dunst"
    "${XDG_CONFIG_HOME:-$HOME/.config}/swaync"
    "${XDG_CONFIG_HOME:-$HOME/.config}/hyprlock"
    "${XDG_CONFIG_HOME:-$HOME/.config}/hypridle"
    "${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    "${XDG_CONFIG_HOME:-$HOME/.config}/starship"
    "${XDG_CONFIG_HOME:-$HOME/.config}/btop"
    "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
    "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
    "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
    "${XDG_DATA_HOME:-$HOME/.local/share}/ash/themes"
    "${XDG_DATA_HOME:-$HOME/.local/share}/ash/plugins"
    "${ASH_CONFIG_DIR}/ash.conf"
)

utils::get_snapshot_dir() {
    local id="$1"
    printf '%s/%s' "${ASH_SNAPSHOT_DIR}" "${id}"
}
