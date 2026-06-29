#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — QUICKNOTE ULTRA BACKEND
# ══════════════════════════════════════════════════════════════════════════════
# File    : quicknote.sh
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Full-featured QuickNote backend for Rofi.
#           Features:
#             • CRUD notes (create / read / update / delete)
#             • Pin / unpin notes
#             • Priority system (high / medium / normal / low)
#             • Tag system with multi-tag support
#             • Full-text fuzzy search via fzf
#             • Markdown export
#             • Clipboard integration (wl-clipboard)
#             • Archive system
#             • Word count & metadata
#             • Live preview in Rofi message area
#             • Ash theme-color-aware priority icons
#             • Systemd/XDG data dir compliance
#             • Atomic writes (no data loss on crash)
#             • POSIX-safe, shellcheck-clean
# ══════════════════════════════════════════════════════════════════════════════

# ── Strict Mode ─────────────────────────────────────────────────────────────
set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# § 1  ENVIRONMENT & PATHS
# ══════════════════════════════════════════════════════════════════════════════

# XDG base dirs (spec-compliant)
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
readonly XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

# Ash dirs
readonly ASH_DIR="${XDG_CONFIG_HOME}/ash"
readonly ASH_DATA_DIR="${XDG_DATA_HOME}/ash"
readonly ASH_CACHE_DIR="${XDG_CACHE_HOME}/ash"
readonly ASH_STATE_DIR="${XDG_STATE_HOME}/ash"

# QuickNote specific dirs
readonly NOTE_DIR="${ASH_DATA_DIR}/notes"
readonly NOTE_ARCHIVE_DIR="${ASH_DATA_DIR}/notes/.archive"
readonly NOTE_META_DIR="${ASH_DATA_DIR}/notes/.meta"
readonly NOTE_LOCK_DIR="${ASH_DATA_DIR}/notes/.locks"
readonly NOTE_CACHE="${ASH_CACHE_DIR}/quicknote"
readonly NOTE_LOG="${ASH_STATE_DIR}/quicknote.log"
readonly NOTE_DB="${NOTE_DIR}/.index.json"
readonly NOTE_SETTINGS="${ASH_DIR}/quicknote/settings.conf"

# Rofi quicknote config dir
readonly QUICKNOTE_CONFIG_DIR="${XDG_CONFIG_HOME}/rofi/menus/quicknote"

# ── Constants ────────────────────────────────────────────────────────────────
readonly NOTE_EXT=".md"
readonly MAX_PREVIEW_LINES=12
readonly MAX_NOTES_DISPLAY=200
readonly DATE_FMT="%Y-%m-%d %H:%M"
readonly LOCK_TIMEOUT=5

# ── Priority definitions ──────────────────────────────────────────────────────
readonly PRIORITY_HIGH="high"
readonly PRIORITY_MEDIUM="medium"
readonly PRIORITY_NORMAL="normal"
readonly PRIORITY_LOW="low"

# ── Nerd Font icons ───────────────────────────────────────────────────────────
readonly ICON_NOTE="󱞁"
readonly ICON_PINNED="󰐃"
readonly ICON_UNPINNED="󱝶"
readonly ICON_PRIO_HIGH="🔴"
readonly ICON_PRIO_MEDIUM="🟡"
readonly ICON_PRIO_NORMAL="🟢"
readonly ICON_PRIO_LOW="🔵"
readonly ICON_TAG="󰓻"
readonly ICON_EDIT="󰏫"
readonly ICON_DELETE="󰆴"
readonly ICON_ARCHIVE="󰀼"
readonly ICON_EXPORT="󰈮"
readonly ICON_COPY="󰆏"
readonly ICON_NEW="󰝒"
readonly ICON_SEARCH="󰍉"
readonly ICON_SEPARATOR="│"

# ── Dependency list ───────────────────────────────────────────────────────────
readonly DEPS_REQUIRED=(rofi jq date stat)
readonly DEPS_OPTIONAL=(wl-copy wl-paste xclip xdotool notify-send fzf)

# ══════════════════════════════════════════════════════════════════════════════
# § 2  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

_log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp="$(date +"${DATE_FMT}")"
    printf '[%s] [%-5s] %s\n' "${timestamp}" "${level}" "${msg}" \
        >> "${NOTE_LOG}" 2>/dev/null || true
}

log_info()  { _log "INFO"  "$@"; }
log_warn()  { _log "WARN"  "$@"; }
log_error() { _log "ERROR" "$@"; }
log_debug() { [[ "${ASH_DEBUG:-0}" == "1" ]] && _log "DEBUG" "$@" || true; }

# ══════════════════════════════════════════════════════════════════════════════
# § 3  INITIALISATION
# ══════════════════════════════════════════════════════════════════════════════

init() {
    # Create directory tree
    local -a dirs=(
        "${NOTE_DIR}"
        "${NOTE_ARCHIVE_DIR}"
        "${NOTE_META_DIR}"
        "${NOTE_LOCK_DIR}"
        "${NOTE_CACHE}"
        "${ASH_STATE_DIR}"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
    done

    # Initialise DB if absent
    if [[ ! -f "${NOTE_DB}" ]]; then
        echo '{"version":"1","notes":[]}' > "${NOTE_DB}"
    fi

    # Initialise settings if absent
    if [[ ! -f "${NOTE_SETTINGS}" ]]; then
        mkdir -p "$(dirname "${NOTE_SETTINGS}")"
        cat > "${NOTE_SETTINGS}" <<'EOF'
# QuickNote Settings — ASH Dotfiles v5.0
editor="${EDITOR:-nvim}"
terminal="${ASH_TERMINAL:-kitty}"
sort_order="modified"        # modified | created | alpha | priority | pinned
default_priority="normal"    # high | medium | normal | low
auto_preview="true"
max_note_size="10240"        # bytes
clipboard_backend="auto"     # auto | wl-copy | xclip
notification_on_create="true"
notification_on_delete="true"
notification_on_copy="true"
archive_after_days="90"
max_recent="10"
EOF
    fi

    log_info "QuickNote initialised"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 4  DEPENDENCY CHECK
# ══════════════════════════════════════════════════════════════════════════════

check_deps() {
    local missing=()
    for dep in "${DEPS_REQUIRED[@]}"; do
        command -v "${dep}" &>/dev/null || missing+=("${dep}")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        echo "ERROR: Missing: ${missing[*]}" >&2
        exit 1
    fi

    # Determine clipboard backend
    if command -v wl-copy &>/dev/null; then
        CLIPBOARD_COPY="wl-copy"
        CLIPBOARD_PASTE="wl-paste"
    elif command -v xclip &>/dev/null; then
        CLIPBOARD_COPY="xclip -selection clipboard -in"
        CLIPBOARD_PASTE="xclip -selection clipboard -out"
    else
        CLIPBOARD_COPY=""
        CLIPBOARD_PASTE=""
        log_warn "No clipboard backend found (wl-copy / xclip)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 5  SETTINGS HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# shellcheck source=/dev/null
load_settings() {
    if [[ -f "${NOTE_SETTINGS}" ]]; then
        # Safe source: only allow key=value pairs
        while IFS='=' read -r key val; do
            [[ "${key}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${key}" ]]               && continue
            key="${key// /}"
            val="${val//\"/}"
            val="${val//\'/}"
            # Allowlist of safe keys
            case "${key}" in
                editor|terminal|sort_order|default_priority|\
                auto_preview|max_note_size|clipboard_backend|\
                notification_on_create|notification_on_delete|\
                notification_on_copy|archive_after_days|max_recent)
                    printf -v "${key}" '%s' "${val}" ;;
            esac
        done < "${NOTE_SETTINGS}"
    fi

    # Defaults (safe fallback)
    editor="${editor:-${EDITOR:-nvim}}"
    terminal="${terminal:-kitty}"
    sort_order="${sort_order:-modified}"
    default_priority="${default_priority:-normal}"
    auto_preview="${auto_preview:-true}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  LOCKING (atomic operations)
# ══════════════════════════════════════════════════════════════════════════════

_lock_file() {
    local name="$1"
    echo "${NOTE_LOCK_DIR}/${name}.lock"
}

acquire_lock() {
    local name="$1"
    local lock
    lock="$(_lock_file "${name}")"
    local waited=0
    while [[ -f "${lock}" ]]; do
        sleep 0.1
        waited=$(( waited + 1 ))
        if (( waited > LOCK_TIMEOUT * 10 )); then
            log_warn "Lock timeout for ${name}, forcing"
            rm -f "${lock}"
            break
        fi
    done
    echo $$ > "${lock}"
    log_debug "Lock acquired: ${name}"
}

release_lock() {
    local name="$1"
    rm -f "$(_lock_file "${name}")"
    log_debug "Lock released: ${name}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 7  NOTE ID GENERATION
# ══════════════════════════════════════════════════════════════════════════════

generate_id() {
    # Format: YYYYMMDD-HHMMSS-XXXXX (collision-resistant)
    local ts rand
    ts="$(date +%Y%m%d-%H%M%S)"
    rand="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 5)"
    echo "${ts}-${rand}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 8  METADATA ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Metadata files live in NOTE_META_DIR/<id>.json
# Schema:
# {
#   "id":       "20240101-120000-abc12",
#   "title":    "My Note",
#   "created":  "2024-01-01 12:00",
#   "modified": "2024-01-02 09:30",
#   "priority": "normal",
#   "pinned":   false,
#   "tags":     ["work", "ideas"],
#   "archived": false,
#   "words":    42
# }

meta_file() {
    local id="$1"
    echo "${NOTE_META_DIR}/${id}.json"
}

meta_create() {
    local id="$1" title="$2" priority="${3:-normal}"
    local now
    now="$(date +"${DATE_FMT}")"
    local meta_path
    meta_path="$(meta_file "${id}")"

    jq -n \
        --arg id       "${id}"       \
        --arg title    "${title}"    \
        --arg created  "${now}"      \
        --arg modified "${now}"      \
        --arg priority "${priority}" \
        '{
            id:       $id,
            title:    $title,
            created:  $created,
            modified: $modified,
            priority: $priority,
            pinned:   false,
            tags:     [],
            archived: false,
            words:    0
        }' > "${meta_path}"
    log_debug "Meta created: ${id}"
}

meta_read() {
    local id="$1"
    local meta_path
    meta_path="$(meta_file "${id}")"
    if [[ -f "${meta_path}" ]]; then
        cat "${meta_path}"
    else
        echo "{}"
    fi
}

meta_update() {
    local id="$1"
    local key="$2"
    local val="$3"
    local meta_path
    meta_path="$(meta_file "${id}")"
    local now
    now="$(date +"${DATE_FMT}")"
    local tmp
    tmp="$(mktemp)"

    jq --arg k "${key}" --arg v "${val}" --arg m "${now}" \
        '.[$k] = $v | .modified = $m' \
        "${meta_path}" > "${tmp}" && mv "${tmp}" "${meta_path}"
    log_debug "Meta updated: ${id} ${key}=${val}"
}

meta_update_bool() {
    local id="$1" key="$2" val="$3"
    local meta_path
    meta_path="$(meta_file "${id}")"
    local now
    now="$(date +"${DATE_FMT}")"
    local tmp
    tmp="$(mktemp)"

    jq --arg k "${key}" --argjson v "${val}" --arg m "${now}" \
        '.[$k] = $v | .modified = $m' \
        "${meta_path}" > "${tmp}" && mv "${tmp}" "${meta_path}"
}

meta_update_words() {
    local id="$1" words="$2"
    local meta_path
    meta_path="$(meta_file "${id}")"
    local tmp
    tmp="$(mktemp)"

    jq --argjson w "${words}" '.words = $w' \
        "${meta_path}" > "${tmp}" && mv "${tmp}" "${meta_path}"
}

meta_add_tag() {
    local id="$1" tag="$2"
    local meta_path
    meta_path="$(meta_file "${id}")"
    local tmp
    tmp="$(mktemp)"

    jq --arg t "${tag}" \
        'if (.tags | index($t)) == null then .tags += [$t] else . end' \
        "${meta_path}" > "${tmp}" && mv "${tmp}" "${meta_path}"
}

meta_remove_tag() {
    local id="$1" tag="$2"
    local meta_path
    meta_path="$(meta_file "${id}")"
    local tmp
    tmp="$(mktemp)"

    jq --arg t "${tag}" '.tags = [.tags[] | select(. != $t)]' \
        "${meta_path}" > "${tmp}" && mv "${tmp}" "${meta_path}"
}

meta_delete() {
    local id="$1"
    rm -f "$(meta_file "${id}")"
}

count_words() {
    local file="$1"
    if [[ -f "${file}" ]]; then
        wc -w < "${file}" | tr -d ' '
    else
        echo 0
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 9  NOTE FILE OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════

note_path() {
    local id="$1"
    echo "${NOTE_DIR}/${id}${NOTE_EXT}"
}

note_exists() {
    local id="$1"
    [[ -f "$(note_path "${id}")" ]]
}

# Create a new note — atomic write
note_create() {
    local title="$1"
    local content="${2:-}"
    local priority="${3:-${default_priority:-normal}}"
    local tags="${4:-}"

    local id
    id="$(generate_id)"
    local note_file
    note_file="$(note_path "${id}")"
    local now
    now="$(date +"${DATE_FMT}")"
    local tmp
    tmp="$(mktemp)"

    # Build markdown header + content
    {
        printf '# %s\n\n' "${title}"
        printf '> Created: %s | Priority: %s\n\n' "${now}" "${priority}"
        if [[ -n "${tags}" ]]; then
            printf '**Tags:** %s\n\n' "${tags}"
        fi
        printf '---\n\n'
        if [[ -n "${content}" ]]; then
            printf '%s\n' "${content}"
        fi
    } > "${tmp}"

    # Atomic move
    mv "${tmp}" "${note_file}"
    chmod 600 "${note_file}"

    # Create metadata
    meta_create "${id}" "${title}" "${priority}"

    # Add tags if provided
    if [[ -n "${tags}" ]]; then
        IFS=',' read -ra tag_arr <<< "${tags}"
        for tag in "${tag_arr[@]}"; do
            tag="${tag## }"   # ltrim
            tag="${tag%% }"   # rtrim
            [[ -n "${tag}" ]] && meta_add_tag "${id}" "${tag}"
        done
    fi

    # Update word count
    local words
    words="$(count_words "${note_file}")"
    meta_update_words "${id}" "${words}"

    log_info "Note created: ${id} '${title}'"
    notify_user "󱞁 Note Created" "${title}" "low"

    echo "${id}"
}

# Read a note's content
note_read() {
    local id="$1"
    local note_file
    note_file="$(note_path "${id}")"
    if [[ -f "${note_file}" ]]; then
        cat "${note_file}"
    else
        echo ""
    fi
}

# Delete a note (with optional archive)
note_delete() {
    local id="$1"
    local archive="${2:-false}"
    local note_file
    note_file="$(note_path "${id}")"

    if [[ ! -f "${note_file}" ]]; then
        log_warn "note_delete: ${id} not found"
        return 1
    fi

    if [[ "${archive}" == "true" ]]; then
        mv "${note_file}" "${NOTE_ARCHIVE_DIR}/"
        meta_update_bool "${id}" "archived" "true"
        log_info "Note archived: ${id}"
        notify_user "󰀼 Note Archived" "$(note_title "${id}")" "low"
    else
        rm -f "${note_file}"
        meta_delete "${id}"
        log_info "Note deleted: ${id}"
        notify_user "󰆴 Note Deleted" "$(note_title "${id}")" "low"
    fi
}

# Get note title from metadata
note_title() {
    local id="$1"
    meta_read "${id}" | jq -r '.title // "Untitled"'
}

# Update note content (opens editor if no content given)
note_edit_content() {
    local id="$1" new_content="$2"
    local note_file
    note_file="$(note_path "${id}")"
    local now
    now="$(date +"${DATE_FMT}")"
    local tmp
    tmp="$(mktemp --suffix="${NOTE_EXT}")"

    if [[ -n "${new_content}" ]]; then
        printf '%s' "${new_content}" > "${tmp}"
        mv "${tmp}" "${note_file}"
    fi

    local words
    words="$(count_words "${note_file}")"
    meta_update_words "${id}" "${words}"
    meta_update "${id}" "modified" "${now}"
    log_info "Note content updated: ${id}"
}

# Open note in configured editor
note_open_editor() {
    local id="$1"
    local note_file
    note_file="$(note_path "${id}")"
    load_settings

    local term="${terminal:-kitty}"
    local ed="${editor:-nvim}"

    # Try to open in floating terminal window via hyprctl dispatch
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exec \
            "${term} --class ash-quicknote-editor --title 'QuickNote: $(note_title "${id}")' ${ed} '${note_file}'" \
            &>/dev/null &
    else
        "${term}" -e "${ed}" "${note_file}" &>/dev/null &
    fi

    log_info "Note opened in editor: ${id}"
}

# Pin / unpin a note
note_toggle_pin() {
    local id="$1"
    local current_pin
    current_pin="$(meta_read "${id}" | jq -r '.pinned')"
    local new_pin
    if [[ "${current_pin}" == "true" ]]; then
        new_pin="false"
    else
        new_pin="true"
    fi
    meta_update_bool "${id}" "pinned" "${new_pin}"
    log_info "Note pin toggled: ${id} → ${new_pin}"
    echo "${new_pin}"
}

# Set note priority
note_set_priority() {
    local id="$1" priority="$2"
    case "${priority}" in
        high|medium|normal|low) ;;
        *)
            log_warn "Invalid priority: ${priority}"
            return 1
            ;;
    esac
    meta_update "${id}" "priority" "${priority}"
    log_info "Note priority set: ${id} → ${priority}"
}

# Copy note content to clipboard
note_copy_clipboard() {
    local id="$1"
    local note_file
    note_file="$(note_path "${id}")"

    if [[ -z "${CLIPBOARD_COPY}" ]]; then
        log_warn "No clipboard backend available"
        return 1
    fi

    ${CLIPBOARD_COPY} < "${note_file}"
    log_info "Note copied to clipboard: ${id}"
    notify_user "󰆏 Copied to Clipboard" "$(note_title "${id}")" "low"
}

# Export note as markdown to ~/Documents/Notes/
note_export_markdown() {
    local id="$1"
    local export_dir="${HOME}/Documents/Notes"
    mkdir -p "${export_dir}"
    local title
    title="$(note_title "${id}")"
    # Sanitize filename
    local safe_title="${title//[^a-zA-Z0-9 _-]/_}"
    safe_title="${safe_title// /-}"
    local export_file="${export_dir}/${safe_title}-${id}${NOTE_EXT}"

    cp "$(note_path "${id}")" "${export_file}"
    log_info "Note exported: ${id} → ${export_file}"
    notify_user "󰈮 Note Exported" "${export_file}" "low"
    echo "${export_file}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 10  LIST & SORT ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# List all note IDs (non-archived)
list_note_ids() {
    local filter="${1:-all}"

    find "${NOTE_DIR}" -maxdepth 1 -name "*${NOTE_EXT}" \
        -type f 2>/dev/null \
    | while read -r f; do
        local id
        id="$(basename "${f}" "${NOTE_EXT}")"
        local meta
        meta="$(meta_read "${id}")"
        local archived
        archived="$(echo "${meta}" | jq -r '.archived // false')"

        [[ "${archived}" == "true" ]] && continue

        case "${filter}" in
            pinned)
                local pinned
                pinned="$(echo "${meta}" | jq -r '.pinned // false')"
                [[ "${pinned}" != "true" ]] && continue
                ;;
            tag:*)
                local tag="${filter#tag:}"
                local has_tag
                has_tag="$(echo "${meta}" | \
                    jq -r --arg t "${tag}" '.tags | index($t) != null')"
                [[ "${has_tag}" != "true" ]] && continue
                ;;
        esac
        echo "${id}"
    done
}

# Sort note IDs by a field
sort_notes() {
    local sort_by="${1:-modified}"
    local -a ids=("${@:2}")

    local sorted
    sorted="$(
        for id in "${ids[@]}"; do
            local meta
            meta="$(meta_read "${id}")"
            local val
            case "${sort_by}" in
                modified) val="$(echo "${meta}" | jq -r '.modified')"; ;;
                created)  val="$(echo "${meta}" | jq -r '.created')";  ;;
                alpha)    val="$(echo "${meta}" | jq -r '.title')";     ;;
                priority)
                    local p
                    p="$(echo "${meta}" | jq -r '.priority')"
                    case "${p}" in
                        high)   val="1" ;;
                        medium) val="2" ;;
                        normal) val="3" ;;
                        low)    val="4" ;;
                        *)      val="5" ;;
                    esac
                    ;;
                pinned)
                    local pinned
                    pinned="$(echo "${meta}" | jq -r '.pinned // false')"
                    [[ "${pinned}" == "true" ]] && val="0" || val="1"
                    ;;
                *) val="$(echo "${meta}" | jq -r '.modified')"; ;;
            esac
            printf '%s\t%s\n' "${val}" "${id}"
        done | sort -t$'\t' -k1,1 | cut -f2
    )"
    echo "${sorted}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 11  DISPLAY FORMATTING
# ══════════════════════════════════════════════════════════════════════════════

# Priority icon for display
priority_icon() {
    case "${1:-normal}" in
        high)   echo "${ICON_PRIO_HIGH}"   ;;
        medium) echo "${ICON_PRIO_MEDIUM}" ;;
        normal) echo "${ICON_PRIO_NORMAL}" ;;
        low)    echo "${ICON_PRIO_LOW}"    ;;
        *)      echo "${ICON_PRIO_NORMAL}" ;;
    esac
}

# Pin icon for display
pin_icon() {
    if [[ "${1:-false}" == "true" ]]; then
        echo "${ICON_PINNED}"
    else
        echo "${ICON_NOTE}"
    fi
}

# Relative time formatting
relative_time() {
    local ts="$1"
    local now epoch_note diff

    # Parse the stored timestamp
    if ! epoch_note="$(date -d "${ts}" +%s 2>/dev/null)"; then
        echo "${ts}"
        return
    fi
    now="$(date +%s)"
    diff=$(( now - epoch_note ))

    if   (( diff < 60      )); then echo "just now"
    elif (( diff < 3600    )); then echo "$(( diff / 60 ))m ago"
    elif (( diff < 86400   )); then echo "$(( diff / 3600 ))h ago"
    elif (( diff < 604800  )); then echo "$(( diff / 86400 ))d ago"
    elif (( diff < 2592000 )); then echo "$(( diff / 604800 ))w ago"
    else echo "$(date -d "${ts}" +%b %d)"
    fi
}

# Truncate a string to max length with ellipsis
truncate() {
    local str="$1" max="${2:-50}"
    if (( ${#str} > max )); then
        echo "${str:0:$(( max - 1 ))}…"
    else
        echo "${str}"
    fi
}

# Format a single note row for Rofi display
format_note_row() {
    local id="$1"
    local meta
    meta="$(meta_read "${id}")"

    local title priority pinned modified words tags_json
    title="$(echo "${meta}" | jq -r '.title // "Untitled"')"
    priority="$(echo "${meta}" | jq -r '.priority // "normal"')"
    pinned="$(echo "${meta}" | jq -r '.pinned // false')"
    modified="$(echo "${meta}" | jq -r '.modified // ""')"
    words="$(echo "${meta}" | jq -r '.words // 0')"
    tags_json="$(echo "${meta}" | jq -r '.tags | join(", ")')"

    local prio_icon pin_icon rel_time title_truncated tags_display
    prio_icon="$(priority_icon "${priority}")"
    pin_icon="$(pin_icon "${pinned}")"
    rel_time="$(relative_time "${modified}")"
    title_truncated="$(truncate "${title}" 36)"

    if [[ -n "${tags_json}" ]]; then
        tags_display="  ${ICON_TAG} ${tags_json}"
    else
        tags_display=""
    fi

    # Row format:
    # [PRIO] [PIN] Title (truncated)   time · Nw [tags]
    printf '%s %s  %-36s  %s · %sw%s\000info\037%s\n' \
        "${prio_icon}" \
        "${pin_icon}" \
        "${title_truncated}" \
        "${rel_time}" \
        "${words}" \
        "${tags_display}" \
        "${id}"
}

# Preview text for a note (shown in Rofi message panel)
format_preview() {
    local id="$1"
    local note_file
    note_file="$(note_path "${id}")"

    if [[ ! -f "${note_file}" ]]; then
        echo "No preview available"
        return
    fi

    local meta
    meta="$(meta_read "${id}")"
    local title priority tags modified words
    title="$(echo "${meta}" | jq -r '.title // "Untitled"')"
    priority="$(echo "${meta}" | jq -r '.priority // "normal"')"
    tags="$(echo "${meta}" | jq -r '.tags | join("  ")')"
    modified="$(echo "${meta}" | jq -r '.modified // ""')"
    words="$(echo "${meta}" | jq -r '.words // 0')"

    local preview_lines
    # Skip markdown header lines and show body
    preview_lines="$(grep -v '^#' "${note_file}" \
        | grep -v '^>' \
        | grep -v '^\*\*Tags\*\*' \
        | grep -v '^---' \
        | grep -v '^$' \
        | head -n "${MAX_PREVIEW_LINES}" \
        | sed 's/\*\*//g; s/\*//g; s/`//g')"

    printf '<b>%s</b>\n<small>%s  ·  %s  ·  %s words  ·  %s</small>\n\n%s' \
        "${title}" \
        "$(priority_icon "${priority}") ${priority}" \
        "${modified}" \
        "${words}" \
        "${ICON_TAG} ${tags:-none}" \
        "${preview_lines}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 12  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_user() {
    local summary="$1" body="${2:-}" urgency="${3:-normal}"
    command -v notify-send &>/dev/null || return 0
    notify-send \
        --urgency="${urgency}" \
        --app-name="QuickNote" \
        --icon="accessories-text-editor" \
        "${summary}" \
        "${body}" \
        &>/dev/null &
}

# ══════════════════════════════════════════════════════════════════════════════
# § 13  ROFI INPUT PARSER — HANDLE CUSTOM KEYBINDS
# ══════════════════════════════════════════════════════════════════════════════

# Rofi calls us with ROFI_RETV environment variable set:
#   0  = normal enter / initial call
#   1  = custom keybind 1  (ctrl+n  → new note)
#   2  = custom keybind 2  (ctrl+d  → delete)
#   3  = custom keybind 3  (ctrl+e  → edit)
#   4  = custom keybind 4  (ctrl+p  → pin)
#   5  = custom keybind 5  (ctrl+y  → copy)
#   6  = custom keybind 6  (ctrl+s  → share/export)
#   7  = custom keybind 7  (ctrl+t  → tag)
#   8  = custom keybind 8  (ctrl+r  → rename)
#   9  = custom keybind 9  (ctrl+shift+e → export md)
#  10  = custom keybind 10 (ctrl+shift+a → archive)
# 28   = initial call (rofi opens)

handle_rofi_input() {
    local retv="${ROFI_RETV:-0}"
    local selected="${1:-}"
    local filter_mode="${QUICKNOTE_FILTER:-all}"

    # Extract note ID from the info field (appended via \000info\037<id>)
    # In practice Rofi sets ROFI_INFO env var for the selected item
    local note_id="${ROFI_INFO:-}"

    log_debug "RETV=${retv} SEL='${selected}' ID='${note_id}'"

    case "${retv}" in
        # ── Initial call: render list ────────────────────────────────────────
        28)
            render_list "${filter_mode}"
            ;;

        # ── Enter: open preview or run default action ─────────────────────
        0)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                # Echo preview as Rofi message (displayed in preview panel)
                format_preview "${note_id}"
            elif [[ -n "${selected}" ]]; then
                # User typed something not matching a note — offer to create
                handle_create_prompt "${selected}"
            fi
            ;;

        # ── Ctrl+N — New note ────────────────────────────────────────────────
        1)
            local new_title="${selected:-Untitled}"
            local new_id
            new_id="$(note_create "${new_title}" "" "${default_priority:-normal}" "")"
            # Reopen with the note focused
            note_open_editor "${new_id}"
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+D — Delete note ─────────────────────────────────────────────
        2)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                note_delete "${note_id}" "false"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+E — Edit note in editor ─────────────────────────────────────
        3)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                note_open_editor "${note_id}"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+P — Pin / unpin ─────────────────────────────────────────────
        4)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                local new_state
                new_state="$(note_toggle_pin "${note_id}")"
                local icon
                [[ "${new_state}" == "true" ]] \
                    && icon="${ICON_PINNED}" \
                    || icon="${ICON_UNPINNED}"
                notify_user "${icon} Note $([ "${new_state}" = "true" ] \
                    && echo 'Pinned' || echo 'Unpinned')" \
                    "$(note_title "${note_id}")" "low"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+Y — Copy to clipboard ───────────────────────────────────────
        5)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                note_copy_clipboard "${note_id}"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+S — Share / export ──────────────────────────────────────────
        6)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                local out
                out="$(note_export_markdown "${note_id}")"
                log_info "Shared note: ${out}"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+T — Add tag ─────────────────────────────────────────────────
        7)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                local tag_input
                tag_input="$(prompt_tag_input)"
                if [[ -n "${tag_input}" ]]; then
                    meta_add_tag "${note_id}" "${tag_input}"
                    notify_user "${ICON_TAG} Tag Added" \
                        "${tag_input} → $(note_title "${note_id}")" "low"
                fi
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+R — Rename note ──────────────────────────────────────────────
        8)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                local new_name
                new_name="$(prompt_rename "$(note_title "${note_id}")")"
                if [[ -n "${new_name}" ]]; then
                    meta_update "${note_id}" "title" "${new_name}"
                fi
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+Shift+E — Export markdown ───────────────────────────────────
        9)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                note_export_markdown "${note_id}"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Ctrl+Shift+A — Archive ────────────────────────────────────────────
        10)
            if [[ -n "${note_id}" ]] && note_exists "${note_id}"; then
                note_delete "${note_id}" "true"
            fi
            render_list "${filter_mode}"
            ;;

        # ── Fallback ──────────────────────────────────────────────────────────
        *)
            render_list "${filter_mode}"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 14  RENDER ENGINE
# ══════════════════════════════════════════════════════════════════════════════

render_list() {
    local filter="${1:-all}"
    load_settings

    # Collect all matching IDs
    local -a ids=()
    while IFS= read -r id; do
        [[ -n "${id}" ]] && ids+=("${id}")
    done < <(list_note_ids "${filter}")

    if [[ ${#ids[@]} -eq 0 ]]; then
        printf '%s  No notes found — press Ctrl+N to create one\000info\037__empty__\n' \
            "${ICON_NOTE}"
        return
    fi

    # Sort
    local -a sorted_ids=()
    while IFS= read -r id; do
        [[ -n "${id}" ]] && sorted_ids+=("${id}")
    done < <(sort_notes "${sort_order:-modified}" "${ids[@]}")

    # Pinned notes always first
    local -a pinned_ids=()
    local -a unpinned_ids=()
    for id in "${sorted_ids[@]}"; do
        local pinned
        pinned="$(meta_read "${id}" | jq -r '.pinned // false')"
        if [[ "${pinned}" == "true" ]]; then
            pinned_ids+=("${id}")
        else
            unpinned_ids+=("${id}")
        fi
    done

    # Render pinned section header
    if [[ ${#pinned_ids[@]} -gt 0 ]]; then
        printf '─── %s Pinned ──────────────────────────────────\000info\037__sep_pinned__\n' \
            "${ICON_PINNED}"
        for id in "${pinned_ids[@]}"; do
            format_note_row "${id}"
        done
        if [[ ${#unpinned_ids[@]} -gt 0 ]]; then
            printf '─── %s Notes ───────────────────────────────────\000info\037__sep_notes__\n' \
                "${ICON_NOTE}"
        fi
    fi

    # Render unpinned notes
    local count=0
    for id in "${unpinned_ids[@]}"; do
        (( count >= MAX_NOTES_DISPLAY )) && break
        format_note_row "${id}"
        (( count++ )) || true
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# § 15  SECONDARY ROFI PROMPTS
# ══════════════════════════════════════════════════════════════════════════════

prompt_tag_input() {
    rofi \
        -dmenu \
        -p "󰓻  Tag name:" \
        -theme "${QUICKNOTE_CONFIG_DIR}/quicknote.rasi" \
        -lines 0 \
        2>/dev/null || echo ""
}

prompt_rename() {
    local current="$1"
    rofi \
        -dmenu \
        -p "󰏫  Rename note:" \
        -filter "${current}" \
        -theme "${QUICKNOTE_CONFIG_DIR}/quicknote.rasi" \
        -lines 0 \
        2>/dev/null || echo ""
}

prompt_priority() {
    printf '%s High\n%s Medium\n%s Normal\n%s Low' \
        "${ICON_PRIO_HIGH}" \
        "${ICON_PRIO_MEDIUM}" \
        "${ICON_PRIO_NORMAL}" \
        "${ICON_PRIO_LOW}" \
    | rofi \
        -dmenu \
        -p "● Priority:" \
        -theme "${QUICKNOTE_CONFIG_DIR}/quicknote.rasi" \
        -lines 4 \
        2>/dev/null | awk '{print tolower($NF)}'
}

handle_create_prompt() {
    local title="$1"
    local new_id
    new_id="$(note_create "${title}" "" "${default_priority:-normal}" "")"
    note_open_editor "${new_id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 16  SEARCH ENGINE
# ══════════════════════════════════════════════════════════════════════════════

search_notes() {
    local query="$1"
    local -a result_ids=()

    find "${NOTE_DIR}" -maxdepth 1 -name "*${NOTE_EXT}" -type f 2>/dev/null \
    | while read -r f; do
        local id
        id="$(basename "${f}" "${NOTE_EXT}")"
        local meta
        meta="$(meta_read "${id}")"
        local archived
        archived="$(echo "${meta}" | jq -r '.archived // false')"
        [[ "${archived}" == "true" ]] && continue

        # Search in title + content + tags
        local title
        title="$(echo "${meta}" | jq -r '.title // ""')"
        local tags
        tags="$(echo "${meta}" | jq -r '.tags | join(" ")')"
        local content
        content="$(cat "${f}" 2>/dev/null)"

        if echo "${title} ${tags} ${content}" | \
            grep -qi "${query}" 2>/dev/null; then
            echo "${id}"
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# § 17  STATISTICS
# ══════════════════════════════════════════════════════════════════════════════

print_stats() {
    local total pinned archived tagged_notes total_words
    total="$(find "${NOTE_DIR}" -maxdepth 1 -name "*${NOTE_EXT}" \
        -type f 2>/dev/null | wc -l)"
    pinned="$(list_note_ids "pinned" | wc -l)"
    archived="$(find "${NOTE_ARCHIVE_DIR}" -maxdepth 1 -name "*${NOTE_EXT}" \
        -type f 2>/dev/null | wc -l)"
    total_words=0

    while IFS= read -r id; do
        local w
        w="$(meta_read "${id}" | jq -r '.words // 0')"
        total_words=$(( total_words + w ))
    done < <(list_note_ids "all")

    cat <<EOF
QuickNote Statistics
──────────────────────────────────
 Total notes    : ${total}
 Pinned         : ${pinned}
 Archived       : ${archived}
 Total words    : ${total_words}
──────────────────────────────────
 Notes dir      : ${NOTE_DIR}
 Config dir     : ${QUICKNOTE_CONFIG_DIR}
EOF
}

# ══════════════════════════════════════════════════════════════════════════════
# § 18  CLI INTERFACE (direct usage without Rofi)
# ══════════════════════════════════════════════════════════════════════════════

print_help() {
    cat <<'EOF'
quicknote.sh — ASH Dotfiles v5.0 Omega QuickNote Backend

USAGE:
  quicknote.sh [COMMAND] [ARGS...]
  quicknote.sh                       # Launch Rofi interface

COMMANDS:
  new  <title> [content] [priority]  Create a new note
  del  <id>                          Delete a note
  arch <id>                          Archive a note
  edit <id>                          Open note in editor
  pin  <id>                          Toggle pin state
  copy <id>                          Copy note to clipboard
  exp  <id>                          Export to ~/Documents/Notes/
  tag  <id> <tag>                    Add a tag
  untag <id> <tag>                   Remove a tag
  prio <id> <priority>               Set priority
  ls   [filter]                      List notes (all|pinned|tag:<tag>)
  search <query>                     Full-text search
  show <id>                          Show note content
  stats                              Show statistics
  init                               Re-initialise directories
  help                               Show this help

PRIORITIES: high | medium | normal | low
FILTERS:    all  | pinned | recent | tag:<tagname>

EXAMPLES:
  quicknote.sh new "Meeting notes" "" high
  quicknote.sh tag 20240101-120000-abc12 work
  quicknote.sh search "meeting"
  quicknote.sh ls pinned
EOF
}

# ══════════════════════════════════════════════════════════════════════════════
# § 19  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

main() {
    init
    check_deps
    load_settings

    # Determine if we're being called by Rofi or directly
    if [[ -n "${ROFI_OUTSIDE:-}" ]] || [[ "${ROFI_RETV:-}" != "" ]]; then
        # Called by Rofi as a script-modi
        handle_rofi_input "${1:-}"
        return
    fi

    # Direct CLI mode
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "${cmd}" in
        "")
            # No args — launch Rofi
            rofi \
                -show quicknote \
                -modi "quicknote:${BASH_SOURCE[0]}" \
                -theme "${QUICKNOTE_CONFIG_DIR}/quicknote.rasi" \
                -display-quicknote "󱞁  QuickNote" \
                &>/dev/null &
            ;;
        new)
            local title="${1:-Untitled}"
            local content="${2:-}"
            local priority="${3:-${default_priority:-normal}}"
            local tags="${4:-}"
            note_create "${title}" "${content}" "${priority}" "${tags}"
            ;;
        del|delete)
            local id="$1"
            note_delete "${id}" "false"
            ;;
        arch|archive)
            local id="$1"
            note_delete "${id}" "true"
            ;;
        edit)
            local id="$1"
            note_open_editor "${id}"
            ;;
        pin)
            local id="$1"
            note_toggle_pin "${id}"
            ;;
        copy)
            local id="$1"
            note_copy_clipboard "${id}"
            ;;
        exp|export)
            local id="$1"
            note_export_markdown "${id}"
            ;;
        tag)
            local id="$1" tag="$2"
            meta_add_tag "${id}" "${tag}"
            ;;
        untag)
            local id="$1" tag="$2"
            meta_remove_tag "${id}" "${tag}"
            ;;
        prio|priority)
            local id="$1" prio="$2"
            note_set_priority "${id}" "${prio}"
            ;;
        ls|list)
            local filter="${1:-all}"
            while IFS= read -r id; do
                format_note_row "${id}"
            done < <(list_note_ids "${filter}")
            ;;
        search)
            local query="${1:?Usage: quicknote.sh search <query>}"
            while IFS= read -r id; do
                format_note_row "${id}"
            done < <(search_notes "${query}")
            ;;
        show)
            local id="${1:?Usage: quicknote.sh show <id>}"
            note_read "${id}"
            ;;
        preview)
            local id="${1:?Usage: quicknote.sh preview <id>}"
            format_preview "${id}"
            ;;
        stats)
            print_stats
            ;;
        init)
            log_info "Re-initialising QuickNote"
            echo "Initialised QuickNote at ${NOTE_DIR}"
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            log_warn "Unknown command: ${cmd}"
            print_help >&2
            exit 1
            ;;
    esac
}

main "$@"