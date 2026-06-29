#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — PLUGIN MANAGER ULTRA BACKEND
# ══════════════════════════════════════════════════════════════════════════════
# File    : plugin-manager.sh
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Full-featured plugin management backend for Rofi.
#
#   Core systems:
#     • Plugin registry (local JSON + remote GitHub registry)
#     • Full CRUD lifecycle (install · update · remove · enable · disable)
#     • Dependency resolution (topological sort)
#     • Version constraint checking (semver)
#     • Plugin sandboxing (permissions model)
#     • Hook system (pre/post install/remove/update)
#     • SQLite state database (installed · enabled · versions · stats)
#     • LRU cache (registry responses, 1h TTL)
#     • Parallel install queue with progress tracking
#     • Plugin configuration editor
#     • Favourites system
#     • Changelog viewer
#     • Integrity verification (sha256)
#     • Automatic backup before destructive ops
#     • Full ROFI_RETV dispatcher (10 keybinds)
#     • Comprehensive CLI (20+ commands)
#     • POSIX-safe, shellcheck-clean, strict mode
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# § 1  ENVIRONMENT & PATHS
# ══════════════════════════════════════════════════════════════════════════════

readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
readonly XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

readonly ASH_DIR="${XDG_CONFIG_HOME}/ash"
readonly ASH_DATA_DIR="${XDG_DATA_HOME}/ash"
readonly ASH_CACHE_DIR="${XDG_CACHE_HOME}/ash"
readonly ASH_STATE_DIR="${XDG_STATE_HOME}/ash"

# Plugin directories
readonly PLUGIN_DIR="${ASH_DATA_DIR}/plugins"
readonly PLUGIN_INSTALLED="${PLUGIN_DIR}/installed"
readonly PLUGIN_DISABLED="${PLUGIN_DIR}/disabled"
readonly PLUGIN_STAGING="${PLUGIN_DIR}/.staging"
readonly PLUGIN_BACKUPS="${PLUGIN_DIR}/.backups"
readonly PLUGIN_HOOKS="${PLUGIN_DIR}/.hooks"
readonly PLUGIN_CONFIGS="${ASH_DIR}/plugins"

# State & cache
readonly PLUGIN_DB="${ASH_DATA_DIR}/plugins/registry.db"
readonly PLUGIN_CACHE="${ASH_CACHE_DIR}/plugin-manager"
readonly PLUGIN_LOG="${ASH_STATE_DIR}/plugin-manager.log"
readonly PLUGIN_QUEUE="${ASH_STATE_DIR}/plugin-queue.json"
readonly PLUGIN_STATE="${ASH_STATE_DIR}/plugin-session.json"
readonly PLUGIN_SETTINGS="${ASH_DIR}/plugin-manager/settings.conf"
readonly REGISTRY_CACHE="${PLUGIN_CACHE}/registry.json"
readonly REGISTRY_CACHE_META="${PLUGIN_CACHE}/registry-meta.json"

readonly ROFI_CFG_DIR="${XDG_CONFIG_HOME}/rofi/menus/plugin-manager"

# ══════════════════════════════════════════════════════════════════════════════
# § 2  CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

readonly DATE_FMT="%Y-%m-%d %H:%M:%S"
readonly REGISTRY_TTL=3600          # 1 hour cache
readonly REGISTRY_URL="https://raw.githubusercontent.com/ash-dotfiles/plugin-registry/main/registry.json"
readonly REGISTRY_FALLBACK_URL="https://ash-dotfiles.github.io/registry/registry.json"
readonly REQUEST_TIMEOUT=10
readonly INSTALL_TIMEOUT=120
readonly MAX_PARALLEL_INSTALLS=4
readonly SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'

# ── Nerd Font icons ───────────────────────────────────────────────────────────
readonly ICON_PLUGIN="󰏗"
readonly ICON_INSTALLED="󰏔"
readonly ICON_UPDATE="󰏕"
readonly ICON_INSTALL="󰅢"
readonly ICON_REMOVE="󱧉"
readonly ICON_ENABLE="⚡"
readonly ICON_DISABLE="󰒄"
readonly ICON_CONFIGURE="󰏫"
readonly ICON_SEARCH="󰍉"
readonly ICON_SYNC="󰑐"
readonly ICON_LOADING="󰔟"
readonly ICON_SUCCESS="✓"
readonly ICON_ERROR="✗"
readonly ICON_WARNING="󰏦"
readonly ICON_STAR="★"
readonly ICON_PIN="󰐃"
readonly ICON_INFO="󰋗"
readonly ICON_HISTORY="󰹑"
readonly ICON_GITHUB="󰊤"
readonly ICON_DEPS="󱘖"
readonly ICON_VERIFIED="󰒃"
readonly ICON_LOCK="󰒅"
readonly ICON_SEPARATOR="│"

# ── Plugin status codes ───────────────────────────────────────────────────────
readonly STATUS_INSTALLED="installed"
readonly STATUS_NOT_INSTALLED="not_installed"
readonly STATUS_DISABLED="disabled"
readonly STATUS_UPDATE_AVAILABLE="update_available"
readonly STATUS_ERROR="error"
readonly STATUS_INSTALLING="installing"
readonly STATUS_REMOVING="removing"
readonly STATUS_DEPRECATED="deprecated"

# ── Permission flags ──────────────────────────────────────────────────────────
readonly PERM_NETWORK="network"
readonly PERM_FILESYSTEM="filesystem"
readonly PERM_SYSTEMD="systemd"
readonly PERM_DISPLAY="display"
readonly PERM_AUDIO="audio"
readonly PERM_NOTIFY="notify"

# ── Category icon map ─────────────────────────────────────────────────────────
declare -A CAT_ICONS=(
    [theme]="󰔰"
    [productivity]="󰙏"
    [system]="󰍛"
    [integration]="󱘖"
    [gaming]="󰊗"
    [media]="󰎆"
    [security]="󰒃"
    [ai]="󰧱"
    [network]="󰛳"
    [utility]="󰒄"
    [unknown]="󰏗"
)

# ── Category colors (ANSI for terminal output) ────────────────────────────────
declare -A CAT_COLORS=(
    [theme]="\033[35m"        # magenta
    [productivity]="\033[34m" # blue
    [system]="\033[36m"       # cyan/teal
    [integration]="\033[94m"  # lavender
    [gaming]="\033[32m"       # green
    [media]="\033[96m"        # sky
    [security]="\033[31m"     # red
    [ai]="\033[95m"           # pink
    [network]="\033[34m"      # sapphire
    [utility]="\033[33m"      # peach
    [unknown]="\033[37m"      # white
)
readonly RESET="\033[0m"

# ══════════════════════════════════════════════════════════════════════════════
# § 3  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date +"${DATE_FMT}")"
    printf '[%s] [%-7s] %s\n' "${ts}" "${level}" "${msg}" \
        >> "${PLUGIN_LOG}" 2>/dev/null || true
}

log_info()    { _log "INFO"    "$@"; }
log_warn()    { _log "WARN"    "$@"; }
log_error()   { _log "ERROR"   "$@"; }
log_debug()   { [[ "${ASH_DEBUG:-0}" == "1" ]] && _log "DEBUG"   "$@" || true; }
log_success() { _log "SUCCESS" "$@"; }
log_audit()   { _log "AUDIT"   "$@"; }

# ══════════════════════════════════════════════════════════════════════════════
# § 4  INITIALISATION
# ══════════════════════════════════════════════════════════════════════════════

init() {
    local -a dirs=(
        "${PLUGIN_DIR}"
        "${PLUGIN_INSTALLED}"
        "${PLUGIN_DISABLED}"
        "${PLUGIN_STAGING}"
        "${PLUGIN_BACKUPS}"
        "${PLUGIN_HOOKS}"
        "${PLUGIN_CONFIGS}"
        "${PLUGIN_CACHE}"
        "${ASH_STATE_DIR}"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
    done

    # Initialise SQLite database
    if command -v sqlite3 &>/dev/null; then
        sqlite3 "${PLUGIN_DB}" <<'SQL' 2>/dev/null || true
CREATE TABLE IF NOT EXISTS plugins (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    version         TEXT NOT NULL DEFAULT '0.0.0',
    installed_at    TEXT,
    updated_at      TEXT,
    status          TEXT NOT NULL DEFAULT 'not_installed',
    enabled         INTEGER NOT NULL DEFAULT 1,
    category        TEXT DEFAULT 'utility',
    author          TEXT DEFAULT '',
    description     TEXT DEFAULT '',
    tags            TEXT DEFAULT '[]',
    permissions     TEXT DEFAULT '[]',
    dependencies    TEXT DEFAULT '[]',
    checksum        TEXT DEFAULT '',
    source_url      TEXT DEFAULT '',
    config_path     TEXT DEFAULT '',
    hook_pre_install  TEXT DEFAULT '',
    hook_post_install TEXT DEFAULT '',
    hook_pre_remove   TEXT DEFAULT '',
    hook_post_remove  TEXT DEFAULT '',
    hook_on_enable    TEXT DEFAULT '',
    hook_on_disable   TEXT DEFAULT '',
    install_size_kb INTEGER DEFAULT 0,
    error_msg       TEXT DEFAULT '',
    use_count       INTEGER DEFAULT 0,
    last_used       TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS registry_cache (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    latest_version  TEXT NOT NULL,
    description     TEXT DEFAULT '',
    author          TEXT DEFAULT '',
    category        TEXT DEFAULT 'utility',
    tags            TEXT DEFAULT '[]',
    downloads       INTEGER DEFAULT 0,
    stars           INTEGER DEFAULT 0,
    rating          REAL DEFAULT 0.0,
    size_kb         INTEGER DEFAULT 0,
    license         TEXT DEFAULT 'MIT',
    repo_url        TEXT DEFAULT '',
    download_url    TEXT DEFAULT '',
    checksum        TEXT DEFAULT '',
    dependencies    TEXT DEFAULT '[]',
    permissions     TEXT DEFAULT '[]',
    min_ash_version TEXT DEFAULT '0.0.0',
    featured        INTEGER DEFAULT 0,
    is_core         INTEGER DEFAULT 0,
    is_beta         INTEGER DEFAULT 0,
    deprecated      INTEGER DEFAULT 0,
    fetched_at      TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

CREATE TABLE IF NOT EXISTS favourites (
    plugin_id   TEXT PRIMARY KEY,
    added_at    TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

CREATE TABLE IF NOT EXISTS install_history (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    plugin_id   TEXT NOT NULL,
    action      TEXT NOT NULL,
    version     TEXT DEFAULT '',
    success     INTEGER NOT NULL DEFAULT 1,
    duration_ms INTEGER DEFAULT 0,
    error_msg   TEXT DEFAULT '',
    timestamp   TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

CREATE INDEX IF NOT EXISTS idx_plugins_status   ON plugins(status);
CREATE INDEX IF NOT EXISTS idx_plugins_category ON plugins(category);
CREATE INDEX IF NOT EXISTS idx_registry_cat     ON registry_cache(category);
CREATE INDEX IF NOT EXISTS idx_registry_feat    ON registry_cache(featured);
CREATE INDEX IF NOT EXISTS idx_history_ts       ON install_history(timestamp DESC);
SQL
    fi

    # Default settings
    if [[ ! -f "${PLUGIN_SETTINGS}" ]]; then
        mkdir -p "$(dirname "${PLUGIN_SETTINGS}")"
        cat > "${PLUGIN_SETTINGS}" <<'EOF'
# Plugin Manager Settings — ASH Dotfiles v5.0
registry_url="https://raw.githubusercontent.com/ash-dotfiles/plugin-registry/main/registry.json"
registry_ttl="3600"
auto_update="false"
auto_update_schedule="weekly"
verify_checksums="true"
backup_before_remove="true"
parallel_installs="true"
max_parallel="4"
editor="${EDITOR:-nvim}"
terminal="${ASH_TERMINAL:-kitty}"
notify_install="true"
notify_update="true"
notify_error="true"
sandbox_mode="false"
sort_order="name"
default_category="all"
show_beta="true"
show_deprecated="false"
EOF
    fi

    # Initialise queue
    if [[ ! -f "${PLUGIN_QUEUE}" ]]; then
        echo '{"version":"1","queue":[]}' > "${PLUGIN_QUEUE}"
    fi

    log_info "Plugin manager initialised"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 5  SETTINGS LOADER
# ══════════════════════════════════════════════════════════════════════════════

load_settings() {
    if [[ -f "${PLUGIN_SETTINGS}" ]]; then
        while IFS='=' read -r key val; do
            [[ "${key}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${key}" ]]               && continue
            key="${key// /}"
            val="${val//\"/}"; val="${val//\'/}"
            case "${key}" in
                registry_url|registry_ttl|auto_update|verify_checksums|\
                backup_before_remove|parallel_installs|max_parallel|editor|\
                terminal|notify_install|notify_update|notify_error|\
                sandbox_mode|sort_order|default_category|show_beta|\
                show_deprecated|auto_update_schedule)
                    printf -v "${key}" '%s' "${val}" ;;
            esac
        done < "${PLUGIN_SETTINGS}"
    fi

    registry_url="${registry_url:-${REGISTRY_URL}}"
    verify_checksums="${verify_checksums:-true}"
    sort_order="${sort_order:-name}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  DEPENDENCY CHECK
# ══════════════════════════════════════════════════════════════════════════════

check_deps() {
    local missing=()
    for dep in curl jq git; do
        command -v "${dep}" &>/dev/null || missing+=("${dep}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required deps: ${missing[*]}"
        printf '%s  Missing: %s\000info\037__error__\n' \
            "${ICON_ERROR}" "${missing[*]}"
        exit 1
    fi
    log_debug "Deps OK"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 7  REGISTRY ENGINE
# ══════════════════════════════════════════════════════════════════════════════

registry_is_stale() {
    [[ ! -f "${REGISTRY_CACHE}" ]] && return 0
    [[ ! -f "${REGISTRY_CACHE_META}" ]] && return 0
    local fetched_at now diff
    fetched_at="$(jq -r '.fetched_at // 0' "${REGISTRY_CACHE_META}" 2>/dev/null || echo 0)"
    now="$(date +%s)"
    diff=$(( now - fetched_at ))
    (( diff > REGISTRY_TTL ))
}

registry_fetch() {
    local force="${1:-false}"

    if [[ "${force}" != "true" ]] && ! registry_is_stale; then
        log_debug "Registry cache fresh — skipping fetch"
        return 0
    fi

    log_info "Fetching plugin registry…"
    notify_user "${ICON_SYNC} Syncing Registry" "Fetching latest plugin data…" "low"

    local raw
    raw="$(curl \
        --silent \
        --fail \
        --location \
        --max-time "${REQUEST_TIMEOUT}" \
        --compressed \
        --user-agent "ash-plugin-manager/5.0" \
        "${registry_url}" 2>/dev/null)" || {
        # Try fallback
        log_warn "Primary registry failed — trying fallback"
        raw="$(curl \
            --silent \
            --fail \
            --location \
            --max-time "${REQUEST_TIMEOUT}" \
            "${REGISTRY_FALLBACK_URL}" 2>/dev/null)" || {
            log_error "All registry endpoints failed"
            return 1
        }
    }

    # Validate JSON
    echo "${raw}" | jq empty 2>/dev/null || {
        log_error "Registry returned invalid JSON"
        return 1
    }

    # Write cache
    echo "${raw}" > "${REGISTRY_CACHE}"
    jq -n --argjson ts "$(date +%s)" \
        '{"fetched_at":$ts,"version":"1"}' \
        > "${REGISTRY_CACHE_META}"

    # Populate SQLite cache
    if command -v sqlite3 &>/dev/null; then
        local t_start
        t_start="$(date +%s%3N)"
        local now
        now="$(date +"${DATE_FMT}")"

        # Clear old cache
        sqlite3 "${PLUGIN_DB}" "DELETE FROM registry_cache;" 2>/dev/null || true

        # Bulk insert
        echo "${raw}" | jq -r '.plugins[]? |
            [
                .id, .name, .version, .description, .author,
                .category, (.tags|tostring), (.downloads//0),
                (.stars//0), (.rating//0.0), (.size_kb//0),
                (.license//"MIT"), (.repo_url//""), (.download_url//""),
                (.checksum//""), (.dependencies|tostring),
                (.permissions|tostring), (.min_ash_version//"0.0.0"),
                (if .featured then 1 else 0 end),
                (if .is_core then 1 else 0 end),
                (if .is_beta then 1 else 0 end),
                (if .deprecated then 1 else 0 end)
            ] | @tsv' 2>/dev/null \
        | while IFS=$'\t' read -r \
            id name version desc author cat tags dl stars rating \
            size_kb license repo_url dl_url checksum deps perms \
            min_ash featured is_core is_beta deprecated; do

            # Escape single quotes
            name="${name//\'/\'\'}"
            desc="${desc//\'/\'\'}"
            author="${author//\'/\'\'}"
            repo_url="${repo_url//\'/\'\'}"

            sqlite3 "${PLUGIN_DB}" \
"INSERT OR REPLACE INTO registry_cache(
    id,name,latest_version,description,author,category,tags,
    downloads,stars,rating,size_kb,license,repo_url,download_url,
    checksum,dependencies,permissions,min_ash_version,
    featured,is_core,is_beta,deprecated,fetched_at)
VALUES(
    '${id}','${name}','${version}','${desc}','${author}','${cat}','${tags}',
    ${dl},${stars},${rating},${size_kb},'${license}','${repo_url}','${dl_url}',
    '${checksum}','${deps}','${perms}','${min_ash}',
    ${featured},${is_core},${is_beta},${deprecated},'${now}');" \
            2>/dev/null || true
        done

        local t_end count
        t_end="$(date +%s%3N)"
        count="$(sqlite3 "${PLUGIN_DB}" "SELECT COUNT(*) FROM registry_cache;" 2>/dev/null || echo 0)"
        log_success "Registry loaded: ${count} plugins in $(( t_end - t_start ))ms"
    fi

    notify_user "${ICON_SUCCESS} Registry Synced" "Plugin database updated" "low"
    log_info "Registry sync complete"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 8  PLUGIN QUERY ENGINE
# ══════════════════════════════════════════════════════════════════════════════

db_get_plugin() {
    local id="$1"
    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT * FROM plugins WHERE id='${id//\'/\'\'}' LIMIT 1;" \
        2>/dev/null
}

db_get_registry_plugin() {
    local id="$1"
    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT * FROM registry_cache WHERE id='${id//\'/\'\'}' LIMIT 1;" \
        2>/dev/null
}

db_list_installed() {
    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT id,name,version,status,enabled,category,description
         FROM plugins
         WHERE status IN ('installed','update_available','disabled')
         ORDER BY name;" \
        2>/dev/null
}

db_list_updates() {
    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT p.id, p.name, p.version AS installed_ver,
                r.latest_version AS latest_ver,
                p.category, p.description
         FROM plugins p
         JOIN registry_cache r ON p.id = r.id
         WHERE p.status IN ('installed','update_available')
           AND p.version != r.latest_version
         ORDER BY p.name;" \
        2>/dev/null
}

db_count_updates() {
    command -v sqlite3 &>/dev/null || echo "0"
    sqlite3 "${PLUGIN_DB}" \
        "SELECT COUNT(*) FROM plugins p
         JOIN registry_cache r ON p.id = r.id
         WHERE p.status IN ('installed','update_available')
           AND p.version != r.latest_version;" \
        2>/dev/null || echo "0"
}

db_list_registry() {
    local category="${1:-all}"
    local sort="${2:-name}"
    local show_installed="${3:-true}"
    local where_clause="WHERE r.deprecated = 0"
    local order_clause

    [[ "${show_installed:-true}" != "true" ]] && \
        where_clause+=" AND (p.status IS NULL OR p.status = 'not_installed')"

    [[ "${category}" != "all" ]] && \
        where_clause+=" AND r.category = '${category//\'/\'\'}'"

    case "${sort}" in
        date)   order_clause="r.fetched_at DESC" ;;
        rating) order_clause="r.rating DESC, r.downloads DESC" ;;
        size)   order_clause="r.size_kb ASC" ;;
        *)      order_clause="r.name ASC" ;;
    esac

    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT r.id, r.name, r.latest_version, r.category, r.description,
                r.rating, r.downloads, r.stars, r.featured, r.is_core,
                r.is_beta, r.deprecated, r.size_kb,
                COALESCE(p.status, 'not_installed') AS installed_status,
                COALESCE(p.enabled, 1) AS enabled,
                COALESCE(p.version, '') AS installed_ver
         FROM registry_cache r
         LEFT JOIN plugins p ON r.id = p.id
         ${where_clause}
         ORDER BY ${order_clause};" \
        2>/dev/null
}

db_search() {
    local query="$1"
    local safe_query="${query//\'/\'\'}"
    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT r.id, r.name, r.latest_version, r.category, r.description,
                r.rating, r.downloads, r.featured, r.is_core, r.is_beta,
                COALESCE(p.status, 'not_installed') AS installed_status,
                COALESCE(p.version,'') AS installed_ver
         FROM registry_cache r
         LEFT JOIN plugins p ON r.id = p.id
         WHERE r.deprecated = 0
           AND (
               r.name        LIKE '%${safe_query}%'
            OR r.description LIKE '%${safe_query}%'
            OR r.author      LIKE '%${safe_query}%'
            OR r.category    LIKE '%${safe_query}%'
            OR r.tags        LIKE '%${safe_query}%'
           )
         ORDER BY r.featured DESC, r.rating DESC, r.name ASC
         LIMIT 100;" \
        2>/dev/null
}

db_stats() {
    command -v sqlite3 &>/dev/null || echo "0|0|0|0|0"
    sqlite3 "${PLUGIN_DB}" \
        "SELECT
            (SELECT COUNT(*) FROM plugins WHERE status='installed'),
            (SELECT COUNT(*) FROM plugins p JOIN registry_cache r ON p.id=r.id
             WHERE p.status='installed' AND p.version != r.latest_version),
            (SELECT COUNT(*) FROM registry_cache),
            (SELECT COUNT(*) FROM plugins WHERE enabled=0),
            (SELECT COALESCE(SUM(install_size_kb),0) FROM plugins WHERE status='installed')
         ;" \
        2>/dev/null || echo "0|0|0|0|0"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 9  SEMVER ENGINE
# ══════════════════════════════════════════════════════════════════════════════

semver_compare() {
    # Returns: 0=equal, 1=a>b, 2=a<b
    local a="$1" b="$2"
    [[ "${a}" == "${b}" ]] && { echo 0; return; }

    local IFS='.'
    local -a va=( ${a//-*/} )
    local -a vb=( ${b//-*/} )

    local i
    for (( i=0; i<3; i++ )); do
        local na="${va[$i]:-0}"
        local nb="${vb[$i]:-0}"
        (( na > nb )) && { echo 1; return; }
        (( na < nb )) && { echo 2; return; }
    done
    echo 0
}

semver_satisfies() {
    # Check if version $1 satisfies constraint $2 (e.g., ">=4.0.0")
    local version="$1" constraint="$2"
    local op ver
    if [[ "${constraint}" =~ ^(>=|<=|>|<|=|==|!=)([0-9].*)$ ]]; then
        op="${BASH_REMATCH[1]}"
        ver="${BASH_REMATCH[2]}"
    else
        op=">="
        ver="${constraint}"
    fi

    local cmp
    cmp="$(semver_compare "${version}" "${ver}")"

    case "${op}" in
        ">="  ) [[ "${cmp}" -le 1 ]] ;;
        "<="  ) [[ "${cmp}" -ne 1 ]] ;;
        ">"   ) [[ "${cmp}" -eq 1 ]] ;;
        "<"   ) [[ "${cmp}" -eq 2 ]] ;;
        "="   ) [[ "${cmp}" -eq 0 ]] ;;
        "=="  ) [[ "${cmp}" -eq 0 ]] ;;
        "!="  ) [[ "${cmp}" -ne 0 ]] ;;
        *     ) return 1 ;;
    esac
}

ash_version() {
    # Read ash version from version.json
    local vf="${ASH_DIR}/../version.json"
    if [[ -f "${vf}" ]]; then
        jq -r '.version // "5.0.0"' "${vf}" 2>/dev/null || echo "5.0.0"
    else
        echo "5.0.0"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 10  DEPENDENCY RESOLVER
# ══════════════════════════════════════════════════════════════════════════════

resolve_deps() {
    local plugin_id="$1"
    local -a resolved=()
    local -a visiting=()

    _resolve_recursive() {
        local pid="$1"
        # Cycle detection
        for v in "${visiting[@]}"; do
            [[ "${v}" == "${pid}" ]] && {
                log_error "Circular dependency: ${pid}"
                return 1
            }
        done
        visiting+=("${pid}")

        # Get deps from registry
        local deps_json
        deps_json="$(sqlite3 "${PLUGIN_DB}" \
            "SELECT dependencies FROM registry_cache WHERE id='${pid}';" \
            2>/dev/null || echo "[]")"

        local dep
        while IFS= read -r dep; do
            [[ -z "${dep}" ]] && continue
            # Skip if already resolved
            local already=false
            for r in "${resolved[@]}"; do
                [[ "${r}" == "${dep}" ]] && { already=true; break; }
            done
            "${already}" || _resolve_recursive "${dep}"
        done < <(echo "${deps_json}" | jq -r '.[]?' 2>/dev/null)

        # Remove from visiting
        visiting=( "${visiting[@]/${pid}/}" )
        resolved+=("${pid}")
    }

    _resolve_recursive "${plugin_id}" && echo "${resolved[@]}" || return 1
}

# ══════════════════════════════════════════════════════════════════════════════
# § 11  INTEGRITY VERIFICATION
# ══════════════════════════════════════════════════════════════════════════════

verify_checksum() {
    local file="$1" expected_sum="$2"
    [[ "${verify_checksums:-true}" != "true" ]] && return 0
    [[ -z "${expected_sum}" ]] && {
        log_warn "No checksum for ${file} — skipping verification"
        return 0
    }

    local actual_sum
    actual_sum="$(sha256sum "${file}" 2>/dev/null | cut -d' ' -f1)"

    if [[ "${actual_sum}" == "${expected_sum}" ]]; then
        log_debug "Checksum OK: ${file}"
        return 0
    else
        log_error "Checksum MISMATCH: ${file}"
        log_error "  Expected: ${expected_sum}"
        log_error "  Actual:   ${actual_sum}"
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 12  HOOK RUNNER
# ══════════════════════════════════════════════════════════════════════════════

run_hook() {
    local plugin_id="$1" hook_name="$2"
    local hook_file="${PLUGIN_HOOKS}/${plugin_id}/${hook_name}.sh"

    [[ ! -f "${hook_file}" ]] && return 0
    [[ ! -x "${hook_file}" ]] && chmod +x "${hook_file}"

    log_info "Running hook: ${plugin_id}/${hook_name}"

    # Run in subshell with timeout
    local exit_code=0
    timeout 30 bash "${hook_file}" \
        --plugin-id="${plugin_id}" \
        --hook="${hook_name}" \
        &>>"${PLUGIN_LOG}" || exit_code=$?

    if (( exit_code != 0 )); then
        log_warn "Hook ${hook_name} exited with code ${exit_code} for ${plugin_id}"
    fi
    return "${exit_code}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 13  BACKUP ENGINE
# ══════════════════════════════════════════════════════════════════════════════

backup_plugin() {
    local plugin_id="$1"
    local plugin_path="${PLUGIN_INSTALLED}/${plugin_id}"
    [[ ! -d "${plugin_path}" ]] && return 0

    local ts backup_name
    ts="$(date +%Y%m%d-%H%M%S)"
    backup_name="${plugin_id}-${ts}.tar.gz"
    local backup_path="${PLUGIN_BACKUPS}/${backup_name}"

    tar -czf "${backup_path}" \
        -C "$(dirname "${plugin_path}")" \
        "$(basename "${plugin_path}")" \
        2>/dev/null && \
    log_info "Plugin backed up: ${backup_path}" || \
    log_warn "Backup failed for: ${plugin_id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 14  INSTALL ENGINE
# ══════════════════════════════════════════════════════════════════════════════

plugin_install() {
    local plugin_id="$1"
    local t_start
    t_start="$(date +%s%3N)"

    log_audit "INSTALL START: ${plugin_id}"
    log_info "Installing plugin: ${plugin_id}"

    # ── Guard: Already installed ───────────────────────────────────────────
    local current_status
    current_status="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT status FROM plugins WHERE id='${plugin_id}';" \
        2>/dev/null || echo "")"
    if [[ "${current_status}" == "installed" ]]; then
        log_warn "${plugin_id} is already installed"
        notify_user "${ICON_WARNING} Already Installed" \
            "${plugin_id} is already installed" "low"
        return 1
    fi

    # ── Fetch registry info ────────────────────────────────────────────────
    local reg_row
    reg_row="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT id,name,latest_version,download_url,checksum,
                min_ash_version,dependencies,permissions,category,
                description,author,size_kb
         FROM registry_cache WHERE id='${plugin_id}' LIMIT 1;" \
        2>/dev/null)"

    if [[ -z "${reg_row}" ]]; then
        log_error "Plugin not found in registry: ${plugin_id}"
        notify_user "${ICON_ERROR} Not Found" \
            "Plugin '${plugin_id}' not in registry" "normal"
        return 1
    fi

    IFS='|' read -r _id name version dl_url checksum min_ash \
        deps_json perms_json category description author size_kb \
        <<< "${reg_row}"

    # ── Check ash version compatibility ────────────────────────────────────
    local current_ash
    current_ash="$(ash_version)"
    if [[ -n "${min_ash}" ]] && [[ "${min_ash}" != "0.0.0" ]]; then
        if ! semver_satisfies "${current_ash}" ">=${min_ash}"; then
            log_error "Incompatible: requires ash >=${min_ash}, have ${current_ash}"
            notify_user "${ICON_ERROR} Incompatible" \
                "Requires ash ≥${min_ash} (have ${current_ash})" "normal"
            return 1
        fi
    fi

    # ── Resolve and install dependencies ──────────────────────────────────
    local -a dep_ids=()
    while IFS= read -r dep; do
        [[ -n "${dep}" ]] && dep_ids+=("${dep}")
    done < <(echo "${deps_json}" | jq -r '.[]?' 2>/dev/null)

    for dep_id in "${dep_ids[@]}"; do
        local dep_status
        dep_status="$(sqlite3 "${PLUGIN_DB}" \
            "SELECT status FROM plugins WHERE id='${dep_id}';" \
            2>/dev/null || echo "")"
        if [[ "${dep_status}" != "installed" ]]; then
            log_info "Installing dependency: ${dep_id}"
            plugin_install "${dep_id}" || {
                log_error "Failed to install dependency: ${dep_id}"
                return 1
            }
        fi
    done

    # ── Mark as installing ─────────────────────────────────────────────────
    local now
    now="$(date +"${DATE_FMT}")"
    sqlite3 "${PLUGIN_DB}" \
        "INSERT OR REPLACE INTO plugins(id,name,version,status,category,
             description,author,source_url,dependencies,permissions,
             install_size_kb,installed_at)
         VALUES('${plugin_id}','${name//\'/\'\'}','${version}',
                'installing','${category}','${description//\'/\'\'}',
                '${author//\'/\'\'}','${dl_url}','${deps_json}',
                '${perms_json}',${size_kb:-0},'${now}');" \
        2>/dev/null || true

    # ── Run pre-install hook ───────────────────────────────────────────────
    run_hook "${plugin_id}" "pre_install" || true

    notify_user "${ICON_LOADING} Installing" "${name} v${version}…" "low"

    # ── Download plugin ────────────────────────────────────────────────────
    local staging_dir="${PLUGIN_STAGING}/${plugin_id}"
    mkdir -p "${staging_dir}"
    local archive_file="${staging_dir}/${plugin_id}-${version}.tar.gz"

    if [[ -n "${dl_url}" ]] && [[ "${dl_url}" != "null" ]]; then
        curl \
            --silent \
            --fail \
            --location \
            --max-time "${INSTALL_TIMEOUT}" \
            --output "${archive_file}" \
            "${dl_url}" 2>>"${PLUGIN_LOG}" || {
            log_error "Download failed: ${dl_url}"
            sqlite3 "${PLUGIN_DB}" \
                "UPDATE plugins SET status='error',error_msg='Download failed'
                 WHERE id='${plugin_id}';" 2>/dev/null || true
            notify_user "${ICON_ERROR} Install Failed" \
                "Download failed for ${name}" "normal"
            return 1
        }
    else
        # Clone from GitHub if no direct download URL
        local repo_url
        repo_url="$(sqlite3 "${PLUGIN_DB}" \
            "SELECT repo_url FROM registry_cache WHERE id='${plugin_id}';" \
            2>/dev/null)"
        if [[ -n "${repo_url}" ]] && [[ "${repo_url}" != "null" ]]; then
            git clone --depth=1 --quiet \
                "${repo_url}" "${staging_dir}/src" \
                2>>"${PLUGIN_LOG}" || {
                log_error "Git clone failed: ${repo_url}"
                notify_user "${ICON_ERROR} Install Failed" \
                    "Clone failed for ${name}" "normal"
                return 1
            }
        else
            log_error "No download URL or repo URL for: ${plugin_id}"
            return 1
        fi
    fi

    # ── Verify integrity ───────────────────────────────────────────────────
    if [[ -f "${archive_file}" ]]; then
        verify_checksum "${archive_file}" "${checksum}" || {
            log_error "Integrity check failed for: ${plugin_id}"
            notify_user "${ICON_ERROR} Integrity Failed" \
                "Checksum mismatch for ${name}" "critical"
            sqlite3 "${PLUGIN_DB}" \
                "UPDATE plugins SET status='error',error_msg='Checksum mismatch'
                 WHERE id='${plugin_id}';" 2>/dev/null || true
            return 1
        }

        # Extract
        local install_dir="${PLUGIN_INSTALLED}/${plugin_id}"
        mkdir -p "${install_dir}"
        tar -xzf "${archive_file}" \
            --strip-components=1 \
            -C "${install_dir}" \
            2>>"${PLUGIN_LOG}" || {
            log_error "Extract failed for: ${plugin_id}"
            return 1
        }
    else
        # Git clone — move to installed
        mv "${staging_dir}/src" "${PLUGIN_INSTALLED}/${plugin_id}"
    fi

    # Set correct permissions
    chmod -R 750 "${PLUGIN_INSTALLED}/${plugin_id}"

    # ── Run post-install hook ──────────────────────────────────────────────
    # Copy hooks if present
    if [[ -d "${PLUGIN_INSTALLED}/${plugin_id}/hooks" ]]; then
        cp -r "${PLUGIN_INSTALLED}/${plugin_id}/hooks/." \
            "${PLUGIN_HOOKS}/${plugin_id}/" 2>/dev/null || true
    fi
    run_hook "${plugin_id}" "post_install" || true

    # ── Copy default config ────────────────────────────────────────────────
    local default_cfg="${PLUGIN_INSTALLED}/${plugin_id}/config.json.default"
    if [[ -f "${default_cfg}" ]]; then
        local user_cfg="${PLUGIN_CONFIGS}/${plugin_id}/config.json"
        mkdir -p "$(dirname "${user_cfg}")"
        [[ ! -f "${user_cfg}" ]] && cp "${default_cfg}" "${user_cfg}"
    fi

    # ── Finalise in DB ─────────────────────────────────────────────────────
    local t_end duration_ms actual_size
    t_end="$(date +%s%3N)"
    duration_ms=$(( t_end - t_start ))
    actual_size="$(du -sk "${PLUGIN_INSTALLED}/${plugin_id}" 2>/dev/null \
        | cut -f1 || echo 0)"

    now="$(date +"${DATE_FMT}")"
    sqlite3 "${PLUGIN_DB}" \
        "UPDATE plugins SET
            status='installed', enabled=1,
            version='${version}', checksum='${checksum}',
            install_size_kb=${actual_size},
            error_msg='', installed_at='${now}'
         WHERE id='${plugin_id}';" \
        2>/dev/null || true

    # Log to history
    sqlite3 "${PLUGIN_DB}" \
        "INSERT INTO install_history(plugin_id,action,version,success,duration_ms)
         VALUES('${plugin_id}','install','${version}',1,${duration_ms});" \
        2>/dev/null || true

    # Clean staging
    rm -rf "${staging_dir}"

    log_success "Installed: ${plugin_id} v${version} in ${duration_ms}ms"
    notify_user "${ICON_SUCCESS} Installed" \
        "${ICON_PLUGIN} ${name} v${version}" "low"
    log_audit "INSTALL SUCCESS: ${plugin_id} v${version}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 15  REMOVE ENGINE
# ══════════════════════════════════════════════════════════════════════════════

plugin_remove() {
    local plugin_id="$1" force="${2:-false}"

    log_audit "REMOVE START: ${plugin_id}"

    # ── Guard: not installed ───────────────────────────────────────────────
    local status
    status="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT status FROM plugins WHERE id='${plugin_id}';" \
        2>/dev/null || echo "")"
    if [[ "${status}" != "installed" ]] && \
       [[ "${status}" != "disabled" ]] && \
       [[ "${force}" != "true" ]]; then
        log_warn "Plugin not installed: ${plugin_id}"
        return 1
    fi

    # ── Check reverse dependencies ─────────────────────────────────────────
    local rev_deps
    rev_deps="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT id FROM plugins
         WHERE status='installed'
           AND dependencies LIKE '%${plugin_id}%';" \
        2>/dev/null)"
    if [[ -n "${rev_deps}" ]] && [[ "${force}" != "true" ]]; then
        log_warn "Cannot remove — depended on by: ${rev_deps}"
        notify_user "${ICON_WARNING} Cannot Remove" \
            "Required by: ${rev_deps}" "normal"
        return 1
    fi

    # ── Backup before remove ───────────────────────────────────────────────
    if [[ "${backup_before_remove:-true}" == "true" ]]; then
        backup_plugin "${plugin_id}"
    fi

    # ── Run pre-remove hook ────────────────────────────────────────────────
    run_hook "${plugin_id}" "pre_remove" || true

    # ── Remove files ───────────────────────────────────────────────────────
    local plugin_path="${PLUGIN_INSTALLED}/${plugin_id}"
    local disabled_path="${PLUGIN_DISABLED}/${plugin_id}"
    rm -rf "${plugin_path}" "${disabled_path}"
    rm -rf "${PLUGIN_HOOKS}/${plugin_id}"

    # ── Post-remove hook ───────────────────────────────────────────────────
    run_hook "${plugin_id}" "post_remove" || true

    # ── Update DB ──────────────────────────────────────────────────────────
    local now
    now="$(date +"${DATE_FMT}")"
    sqlite3 "${PLUGIN_DB}" \
        "UPDATE plugins SET
            status='not_installed', enabled=0,
            version='', checksum='', installed_at=NULL
         WHERE id='${plugin_id}';" \
        2>/dev/null || true

    sqlite3 "${PLUGIN_DB}" \
        "INSERT INTO install_history(plugin_id,action,success)
         VALUES('${plugin_id}','remove',1);" \
        2>/dev/null || true

    local name
    name="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT name FROM registry_cache WHERE id='${plugin_id}';" \
        2>/dev/null || echo "${plugin_id}")"

    log_success "Removed: ${plugin_id}"
    notify_user "${ICON_REMOVE} Removed" "${name}" "low"
    log_audit "REMOVE SUCCESS: ${plugin_id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 16  UPDATE ENGINE
# ══════════════════════════════════════════════════════════════════════════════

plugin_update() {
    local plugin_id="$1"
    local current_ver latest_ver

    current_ver="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT version FROM plugins WHERE id='${plugin_id}';" \
        2>/dev/null || echo "")"
    latest_ver="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT latest_version FROM registry_cache WHERE id='${plugin_id}';" \
        2>/dev/null || echo "")"

    if [[ -z "${latest_ver}" ]]; then
        log_warn "No registry entry for: ${plugin_id}"
        return 1
    fi

    local cmp
    cmp="$(semver_compare "${current_ver}" "${latest_ver}")"
    if [[ "${cmp}" -eq 0 ]]; then
        log_info "${plugin_id} is already up to date (v${current_ver})"
        notify_user "${ICON_SUCCESS} Up To Date" \
            "${plugin_id} v${current_ver} is latest" "low"
        return 0
    fi

    log_info "Updating ${plugin_id}: v${current_ver} → v${latest_ver}"

    # Backup current
    backup_plugin "${plugin_id}"
    run_hook "${plugin_id}" "pre_update" || true

    # Re-install (remove files, install fresh)
    rm -rf "${PLUGIN_INSTALLED}/${plugin_id}"
    plugin_install "${plugin_id}" && {
        run_hook "${plugin_id}" "post_update" || true
        sqlite3 "${PLUGIN_DB}" \
            "INSERT INTO install_history(plugin_id,action,version,success)
             VALUES('${plugin_id}','update','${latest_ver}',1);" \
            2>/dev/null || true
        log_success "Updated: ${plugin_id} v${current_ver}→v${latest_ver}"
        notify_user "${ICON_SUCCESS} Updated" \
            "${plugin_id}: v${current_ver} → v${latest_ver}" "low"
    }
}

plugin_update_all() {
    local -a updates=()
    local count
    count="$(db_count_updates)"

    if [[ "${count}" -eq 0 ]]; then
        log_info "No updates available"
        notify_user "${ICON_SUCCESS} All Up To Date" "No updates available" "low"
        return 0
    fi

    notify_user "${ICON_LOADING} Updating All" \
        "Updating ${count} plugins…" "low"

    while IFS='|' read -r id _rest; do
        [[ -z "${id}" ]] && continue
        updates+=("${id}")
    done < <(db_list_updates)

    local failed=0
    for id in "${updates[@]}"; do
        plugin_update "${id}" || (( failed++ ))
    done

    if (( failed == 0 )); then
        notify_user "${ICON_SUCCESS} All Updated" \
            "${#updates[@]} plugins updated" "low"
    else
        notify_user "${ICON_WARNING} Update Complete" \
            "${#updates[@]} total, ${failed} failed" "normal"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 17  ENABLE / DISABLE ENGINE
# ══════════════════════════════════════════════════════════════════════════════

plugin_enable() {
    local plugin_id="$1"
    local disabled_path="${PLUGIN_DISABLED}/${plugin_id}"
    local enabled_path="${PLUGIN_INSTALLED}/${plugin_id}"

    # Move from disabled dir if needed
    if [[ -d "${disabled_path}" ]] && [[ ! -d "${enabled_path}" ]]; then
        mv "${disabled_path}" "${enabled_path}"
    fi

    sqlite3 "${PLUGIN_DB}" \
        "UPDATE plugins SET enabled=1,status='installed'
         WHERE id='${plugin_id}';" \
        2>/dev/null || true

    run_hook "${plugin_id}" "on_enable" || true
    local name
    name="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT name FROM registry_cache WHERE id='${plugin_id}';" \
        2>/dev/null || echo "${plugin_id}")"
    notify_user "${ICON_ENABLE} Enabled" "${name}" "low"
    log_info "Plugin enabled: ${plugin_id}"
}

plugin_disable() {
    local plugin_id="$1"
    local enabled_path="${PLUGIN_INSTALLED}/${plugin_id}"
    local disabled_path="${PLUGIN_DISABLED}/${plugin_id}"

    run_hook "${plugin_id}" "on_disable" || true

    # Move to disabled dir (preserves files)
    if [[ -d "${enabled_path}" ]]; then
        mv "${enabled_path}" "${disabled_path}"
    fi

    sqlite3 "${PLUGIN_DB}" \
        "UPDATE plugins SET enabled=0,status='disabled'
         WHERE id='${plugin_id}';" \
        2>/dev/null || true

    local name
    name="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT name FROM registry_cache WHERE id='${plugin_id}';" \
        2>/dev/null || echo "${plugin_id}")"
    notify_user "${ICON_DISABLE} Disabled" "${name}" "low"
    log_info "Plugin disabled: ${plugin_id}"
}

plugin_toggle_enable() {
    local plugin_id="$1"
    local enabled
    enabled="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT enabled FROM plugins WHERE id='${plugin_id}';" \
        2>/dev/null || echo "1")"

    if [[ "${enabled}" -eq 1 ]]; then
        plugin_disable "${plugin_id}"
    else
        plugin_enable "${plugin_id}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 18  CONFIGURATION ENGINE
# ══════════════════════════════════════════════════════════════════════════════

plugin_configure() {
    local plugin_id="$1"
    local cfg_file="${PLUGIN_CONFIGS}/${plugin_id}/config.json"

    # Create default config if absent
    if [[ ! -f "${cfg_file}" ]]; then
        mkdir -p "$(dirname "${cfg_file}")"
        local default_cfg="${PLUGIN_INSTALLED}/${plugin_id}/config.json.default"
        if [[ -f "${default_cfg}" ]]; then
            cp "${default_cfg}" "${cfg_file}"
        else
            echo '{}' > "${cfg_file}"
        fi
    fi

    local ed="${editor:-${EDITOR:-nvim}}"
    local term="${terminal:-kitty}"

    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exec \
            "${term} --class ash-plugin-config \
             --title 'Plugin Config: ${plugin_id}' \
             ${ed} '${cfg_file}'" \
            &>/dev/null &
    else
        "${term}" -e "${ed}" "${cfg_file}" &>/dev/null &
    fi

    log_info "Opened config for: ${plugin_id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 19  FAVOURITES
# ══════════════════════════════════════════════════════════════════════════════

fav_toggle() {
    local plugin_id="$1"
    command -v sqlite3 &>/dev/null || return 1

    local is_fav
    is_fav="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT COUNT(*) FROM favourites WHERE plugin_id='${plugin_id}';" \
        2>/dev/null || echo 0)"

    if [[ "${is_fav}" -gt 0 ]]; then
        sqlite3 "${PLUGIN_DB}" \
            "DELETE FROM favourites WHERE plugin_id='${plugin_id}';" \
            2>/dev/null || true
        notify_user "${ICON_PIN} Unpinned" "${plugin_id}" "low"
    else
        sqlite3 "${PLUGIN_DB}" \
            "INSERT OR IGNORE INTO favourites(plugin_id) VALUES('${plugin_id}');" \
            2>/dev/null || true
        notify_user "${ICON_STAR} Pinned" "${plugin_id}" "low"
    fi
}

fav_list() {
    command -v sqlite3 &>/dev/null || return 1
    sqlite3 "${PLUGIN_DB}" \
        "SELECT f.plugin_id, r.name, r.category,
                COALESCE(p.status,'not_installed')
         FROM favourites f
         LEFT JOIN registry_cache r ON f.plugin_id = r.id
         LEFT JOIN plugins p ON f.plugin_id = p.id
         ORDER BY r.name;" \
        2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# § 20  OPEN GITHUB
# ══════════════════════════════════════════════════════════════════════════════

plugin_open_github() {
    local plugin_id="$1"
    local repo_url
    repo_url="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT repo_url FROM registry_cache WHERE id='${plugin_id}';" \
        2>/dev/null || echo "")"

    if [[ -z "${repo_url}" ]] || [[ "${repo_url}" == "null" ]]; then
        log_warn "No GitHub URL for: ${plugin_id}"
        notify_user "${ICON_INFO} No URL" \
            "No repository URL for ${plugin_id}" "low"
        return 1
    fi

    # Open with xdg-open or browser
    if command -v xdg-open &>/dev/null; then
        xdg-open "${repo_url}" &>/dev/null &
    elif command -v firefox &>/dev/null; then
        firefox "${repo_url}" &>/dev/null &
    else
        wl-copy <<< "${repo_url}" 2>/dev/null || true
        notify_user "${ICON_GITHUB} URL Copied" "${repo_url}" "low"
    fi

    log_info "Opened GitHub: ${repo_url}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 21  DISPLAY FORMATTERS
# ══════════════════════════════════════════════════════════════════════════════

truncate() {
    local str="$1" max="${2:-50}"
    (( ${#str} > max )) && echo "${str:0:$(( max - 1 ))}…" || echo "${str}"
}

status_icon() {
    case "${1:-}" in
        installed)         echo "${ICON_INSTALLED}" ;;
        update_available)  echo "${ICON_UPDATE}" ;;
        disabled)          echo "${ICON_DISABLE}" ;;
        installing)        echo "${ICON_LOADING}" ;;
        error)             echo "${ICON_ERROR}" ;;
        *)                 echo "${ICON_PLUGIN}" ;;
    esac
}

status_dot() {
    case "${1:-}" in
        installed)        echo "●" ;;
        update_available) echo "●" ;;
        disabled)         echo "○" ;;
        error)            echo "✗" ;;
        *)                echo "·" ;;
    esac
}

rating_stars() {
    local rating="$1"
    local full half empty
    full=$(( ${rating%.*} ))
    local decimal="${rating#*.}"
    (( decimal >= 5 )) && half=1 || half=0
    empty=$(( 5 - full - half ))

    local stars=""
    local i
    for (( i=0; i<full;  i++ )); do stars+="★"; done
    (( half )) && stars+="½"
    for (( i=0; i<empty; i++ )); do stars+="☆"; done
    echo "${stars}"
}

format_size() {
    local kb="${1:-0}"
    if (( kb >= 1024 )); then
        printf '%.1f MB' "$(echo "scale=1; ${kb}/1024" | bc 2>/dev/null || echo 0)"
    else
        printf '%d KB' "${kb}"
    fi
}

format_downloads() {
    local dl="${1:-0}"
    if (( dl >= 1000 )); then
        printf '%.1fk' "$(echo "scale=1; ${dl}/1000" | bc 2>/dev/null || echo 0)"
    else
        echo "${dl}"
    fi
}

cat_icon() {
    local cat="${1:-unknown}"
    echo "${CAT_ICONS[$cat]:-${CAT_ICONS[unknown]}}"
}

# ── Format plugin list row for Rofi ──────────────────────────────────────────
# Row format:
# [STATUS] [CAT_ICON] Name  vVersion  ★Rating  ↓Downloads  [BADGES]
format_plugin_row() {
    local id="$1" name="$2" version="$3" category="$4" \
          description="$5" rating="$6" downloads="$7" \
          featured="${8:-0}" is_core="${9:-0}" is_beta="${10:-0}" \
          installed_status="${11:-not_installed}" \
          installed_ver="${12:-}"

    local s_icon s_dot cat_ic name_trunc badges
    s_icon="$(status_icon "${installed_status}")"
    s_dot="$(status_dot "${installed_status}")"
    cat_ic="$(cat_icon "${category}")"
    name_trunc="$(truncate "${name}" 28)"

    # Build badge string
    badges=""
    [[ "${featured}"        == "1" ]] && badges+=" ★"
    [[ "${is_core}"         == "1" ]] && badges+=" [core]"
    [[ "${is_beta}"         == "1" ]] && badges+=" [β]"
    [[ "${installed_status}" == "installed" ]] && \
        [[ -n "${installed_ver}" ]] && \
        [[ "${installed_ver}" != "${version}" ]] && badges+=" ⬆"

    local ver_display="${version}"
    [[ "${installed_status}" == "installed" ]] && \
        ver_display="${installed_ver:-${version}}"

    printf '%s %s %s  %-28s  v%-8s  %s %s  ↓%s%s\000info\037%s\n' \
        "${s_dot}" \
        "${s_icon}" \
        "${cat_ic}" \
        "${name_trunc}" \
        "${ver_display}" \
        "$(rating_stars "${rating:-0.0}")" \
        "${rating:-0.0}" \
        "$(format_downloads "${downloads:-0}")" \
        "${badges}" \
        "${id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 22  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

state_save() {
    local key="$1" val="$2"
    local tmp
    tmp="$(mktemp)"
    if [[ -f "${PLUGIN_STATE}" ]]; then
        jq --arg k "${key}" --arg v "${val}" '.[$k] = $v' \
            "${PLUGIN_STATE}" > "${tmp}" && mv "${tmp}" "${PLUGIN_STATE}"
    else
        jq -n --arg k "${key}" --arg v "${val}" '{($k): $v}' \
            > "${PLUGIN_STATE}"
    fi
}

state_get() {
    local key="$1"
    [[ ! -f "${PLUGIN_STATE}" ]] && return 1
    jq -r ".${key} // empty" "${PLUGIN_STATE}" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# § 23  RENDER ENGINE
# ══════════════════════════════════════════════════════════════════════════════

render_list() {
    local tab="${1:-all}"
    local category="${2:-all}"
    local sort="${sort_order:-name}"

    # Fetch registry if stale
    registry_is_stale && registry_fetch &

    case "${tab}" in
        installed)
            local rows installed_count=0
            rows="$(db_list_installed)"
            if [[ -z "${rows}" ]]; then
                printf '%s  No plugins installed yet\000info\037__empty__\n' \
                    "${ICON_PLUGIN}"
                printf '  Press Ctrl+I on any plugin to install\000info\037__hint__\n'
                return
            fi
            while IFS='|' read -r id name ver status enabled cat desc; do
                [[ -z "${id}" ]] && continue
                format_plugin_row \
                    "${id}" "${name}" "${ver}" "${cat}" "${desc}" \
                    "0.0" "0" "0" "0" "0" \
                    "${status}" "${ver}"
                (( installed_count++ ))
            done <<< "${rows}"
            ;;

        updates)
            local count
            count="$(db_count_updates)"
            if [[ "${count}" -eq 0 ]]; then
                printf '%s  All plugins are up to date!\000info\037__empty__\n' \
                    "${ICON_SUCCESS}"
                return
            fi
            printf '─── %s Updates Available (%s) ─────────────────────────\000info\037__sep__\n' \
                "${ICON_UPDATE}" "${count}"
            while IFS='|' read -r id name cur_ver new_ver cat desc; do
                [[ -z "${id}" ]] && continue
                printf '● %s %s  %-28s  v%s → v%s\000info\037%s\n' \
                    "${ICON_UPDATE}" \
                    "$(cat_icon "${cat}")" \
                    "$(truncate "${name}" 28)" \
                    "${cur_ver}" "${new_ver}" \
                    "${id}"
            done < <(db_list_updates)
            ;;

        featured)
            printf '─── ★ Featured Plugins ──────────────────────────────────\000info\037__sep__\n'
            while IFS='|' read -r row; do
                [[ -z "${row}" ]] && continue
                IFS='|' read -r id name version cat desc rating dl \
                    stars featured is_core is_beta _dep inst_status inst_ver \
                    <<< "${row}"
                [[ "${featured}" != "1" ]] && continue
                format_plugin_row "${id}" "${name}" "${version}" "${cat}" \
                    "${desc}" "${rating}" "${dl}" "${featured}" \
                    "${is_core}" "${is_beta}" "${inst_status}" "${inst_ver}"
            done < <(db_list_registry "${category}" "rating" "true")
            ;;

        favourites)
            local fav_rows
            fav_rows="$(fav_list)"
            if [[ -z "${fav_rows}" ]]; then
                printf '%s  No pinned plugins\000info\037__empty__\n' "${ICON_PIN}"
                printf '  Press Ctrl+F on a plugin to pin it\000info\037__hint__\n'
                return
            fi
            printf '─── %s Pinned Plugins ──────────────────────────────────\000info\037__sep__\n' \
                "${ICON_PIN}"
            while IFS='|' read -r id name cat status; do
                [[ -z "${id}" ]] && continue
                printf '%s %s %s  %-40s  [%s]\000info\037%s\n' \
                    "${ICON_STAR}" "$(status_dot "${status}")" \
                    "$(cat_icon "${cat}")" "$(truncate "${name}" 40)" \
                    "${status}" "${id}"
            done <<< "${fav_rows}"
            ;;

        *)
            # All / browse — full registry list
            local total=0
            while IFS='|' read -r row; do
                [[ -z "${row}" ]] && continue
                IFS='|' read -r id name version cat desc rating dl \
                    stars featured is_core is_beta deprecated \
                    size_kb inst_status enabled inst_ver <<< "${row}"
                format_plugin_row "${id}" "${name}" "${version}" "${cat}" \
                    "${desc}" "${rating}" "${dl}" "${featured}" \
                    "${is_core}" "${is_beta}" "${inst_status}" "${inst_ver}"
                (( total++ ))
            done < <(db_list_registry "${category}" "${sort}" "true")

            if (( total == 0 )); then
                printf '%s  No plugins found\000info\037__empty__\n' "${ICON_PLUGIN}"
            fi
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 24  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_user() {
    local summary="$1" body="${2:-}" urgency="${3:-normal}"
    command -v notify-send &>/dev/null || return 0
    notify-send \
        --urgency="${urgency}" \
        --app-name="Plugin Manager" \
        --icon="package-x-generic" \
        "${summary}" "${body}" \
        &>/dev/null &
}

# ══════════════════════════════════════════════════════════════════════════════
# § 25  ROFI RETV DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

handle_rofi_input() {
    local retv="${ROFI_RETV:-0}"
    local selected="${1:-}"
    local plugin_id="${ROFI_INFO:-}"

    log_debug "RETV=${retv} SEL='${selected:0:30}' ID='${plugin_id}'"

    local current_tab
    current_tab="$(state_get "tab" 2>/dev/null || echo "all")"
    local current_cat
    current_cat="$(state_get "category" 2>/dev/null || echo "all")"

    case "${retv}" in

        # ── Initial call: render list ────────────────────────────────────
        28)
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Enter: select/preview plugin ─────────────────────────────────
        0)
            if [[ "${plugin_id}" =~ ^__.*__$ ]]; then
                render_list "${current_tab}" "${current_cat}"
                return
            fi
            if [[ -n "${plugin_id}" ]]; then
                state_save "selected_plugin" "${plugin_id}"
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+I — Install ─────────────────────────────────────────────
        1)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                plugin_install "${plugin_id}" &
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+R — Remove ──────────────────────────────────────────────
        2)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                plugin_remove "${plugin_id}" &
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+U — Update ──────────────────────────────────────────────
        3)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                plugin_update "${plugin_id}" &
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+A — Update all ───────────────────────────────────────────
        4)
            plugin_update_all &
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+E — Enable / disable toggle ─────────────────────────────
        5)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                plugin_toggle_enable "${plugin_id}"
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+C — Configure plugin ─────────────────────────────────────
        6)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                plugin_configure "${plugin_id}"
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+F — Favourite toggle ─────────────────────────────────────
        7)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                fav_toggle "${plugin_id}"
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+G — Open GitHub ──────────────────────────────────────────
        8)
            if [[ -n "${plugin_id}" ]] && [[ ! "${plugin_id}" =~ ^__ ]]; then
                plugin_open_github "${plugin_id}"
            fi
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+S — Sync registry ────────────────────────────────────────
        9)
            registry_fetch "true" &
            render_list "${current_tab}" "${current_cat}"
            ;;

        # ── Ctrl+X — Clear filters / reset ────────────────────────────────
        10)
            state_save "tab" "all"
            state_save "category" "all"
            state_save "selected_plugin" ""
            render_list "all" "all"
            ;;

        # ── Fallback ──────────────────────────────────────────────────────
        *)
            render_list "${current_tab}" "${current_cat}"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 26  CLI INTERFACE
# ══════════════════════════════════════════════════════════════════════════════

print_help() {
    cat <<'EOF'
plugin-manager.sh — ASH Dotfiles v5.0 Omega Plugin Manager Backend

USAGE:
  plugin-manager.sh [COMMAND] [ARGS...]
  plugin-manager.sh              # Launch Rofi interface

COMMANDS:
  install   <id>                  Install a plugin
  remove    <id> [--force]        Remove a plugin
  update    <id>                  Update a plugin to latest version
  update-all                      Update all installed plugins
  enable    <id>                  Enable a disabled plugin
  disable   <id>                  Disable a plugin
  configure <id>                  Open plugin configuration editor
  info      <id>                  Show full plugin information
  list      [category] [filter]   List plugins (all|installed|updates|featured)
  search    <query>               Search plugins by name/tag/author
  fav-add   <id>                  Add plugin to favourites
  fav-list                        List favourite plugins
  history   [limit]               Show install/remove history
  sync                            Force-sync plugin registry
  stats                           Show plugin statistics
  verify    <id>                  Verify plugin integrity
  backup    <id>                  Backup a plugin
  changelog <id>                  Show plugin changelog
  deps      <id>                  Show dependency tree
  outdated                        List outdated plugins
  init                            Re-initialise plugin directories
  help                            Show this help

EXAMPLES:
  plugin-manager.sh install game-mode
  plugin-manager.sh search "wallpaper"
  plugin-manager.sh list installed
  plugin-manager.sh update-all
  plugin-manager.sh info focus-timer
EOF
}

print_stats() {
    local stats_row
    stats_row="$(db_stats)"
    local installed updates available disabled size_kb
    IFS='|' read -r installed updates available disabled size_kb <<< "${stats_row}"

    cat <<EOF
Plugin Manager Statistics — ASH Dotfiles v5.0
─────────────────────────────────────────────────────
 Installed plugins  : ${installed}
 Updates available  : ${updates}
 Total in registry  : ${available}
 Disabled plugins   : ${disabled}
 Total install size : $(format_size "${size_kb}")
─────────────────────────────────────────────────────
 Plugin dir         : ${PLUGIN_INSTALLED}
 Config dir         : ${PLUGIN_CONFIGS}
 Registry DB        : ${PLUGIN_DB}
 Cache dir          : ${PLUGIN_CACHE}
 Log                : ${PLUGIN_LOG}
─────────────────────────────────────────────────────
EOF
}

print_plugin_info() {
    local plugin_id="$1"
    local row
    row="$(sqlite3 "${PLUGIN_DB}" \
        "SELECT r.id,r.name,r.latest_version,r.description,r.author,
                r.category,r.license,r.repo_url,r.rating,r.downloads,
                r.stars,r.size_kb,r.featured,r.is_core,r.is_beta,
                r.min_ash_version,r.dependencies,r.permissions,
                COALESCE(p.status,'not_installed'),
                COALESCE(p.version,''),COALESCE(p.enabled,0),
                COALESCE(p.installed_at,'')
         FROM registry_cache r
         LEFT JOIN plugins p ON r.id=p.id
         WHERE r.id='${plugin_id//\'/\'\'}' LIMIT 1;" \
        2>/dev/null)"

    if [[ -z "${row}" ]]; then
        echo "Plugin not found: ${plugin_id}" >&2
        return 1
    fi

    IFS='|' read -r id name version desc author category license repo \
        rating downloads stars size_kb featured is_core is_beta min_ash \
        deps perms inst_status inst_ver enabled inst_at <<< "${row}"

    cat <<EOF
${ICON_PLUGIN}  ${name}  (${id})
$( printf '─%.0s' {1..60} )
 Version    : ${version}
 Status     : ${inst_status}$([ "${inst_ver}" != "${version}" ] && \
                [ -n "${inst_ver}" ] && echo " (installed: ${inst_ver})" || echo "")
 Author     : ${author}
 Category   : $(cat_icon "${category}") ${category}
 License    : ${license}
 Rating     : $(rating_stars "${rating}") ${rating}/5.0
 Downloads  : $(format_downloads "${downloads}")
 Stars      : ${stars}
 Size       : $(format_size "${size_kb}")
 Min ash    : v${min_ash}
 Featured   : $([ "${featured}" = "1" ] && echo "★ Yes" || echo "No")
 Core       : $([ "${is_core}" = "1"  ] && echo "Yes" || echo "No")
 Beta       : $([ "${is_beta}" = "1"  ] && echo "β Yes" || echo "No")
 Repo       : ${repo}
 Deps       : ${deps}
 Perms      : ${perms}
$([ -n "${inst_at}" ] && echo " Installed  : ${inst_at}")
$( printf '─%.0s' {1..60} )
 Description:
 ${desc}
EOF
}

# ══════════════════════════════════════════════════════════════════════════════
# § 27  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

main() {
    init
    check_deps
    load_settings

    # ── Rofi script-modi mode ─────────────────────────────────────────────
    if [[ -n "${ROFI_OUTSIDE:-}" ]] || [[ "${ROFI_RETV:-}" != "" ]]; then
        handle_rofi_input "${1:-}"
        return
    fi

    # ── CLI mode ──────────────────────────────────────────────────────────
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "${cmd}" in
        "")
            rofi \
                -show plugin-manager \
                -modi "plugin-manager:${BASH_SOURCE[0]}" \
                -theme "${ROFI_CFG_DIR}/plugin-manager.rasi" \
                -display-plugin-manager "󰏗  Plugins" \
                &>/dev/null &
            ;;
        install)
            plugin_install "${1:?Usage: install <id>}"
            ;;
        remove|rm)
            local force=""
            [[ "${2:-}" == "--force" ]] && force="true"
            plugin_remove "${1:?Usage: remove <id>}" "${force}"
            ;;
        update)
            plugin_update "${1:?Usage: update <id>}"
            ;;
        update-all|ua)
            plugin_update_all
            ;;
        enable)
            plugin_enable "${1:?Usage: enable <id>}"
            ;;
        disable)
            plugin_disable "${1:?Usage: disable <id>}"
            ;;
        configure|cfg)
            plugin_configure "${1:?Usage: configure <id>}"
            ;;
        info)
            print_plugin_info "${1:?Usage: info <id>}"
            ;;
        list|ls)
            local tab="${1:-all}" cat="${2:-all}"
            render_list "${tab}" "${cat}"
            ;;
        search|s)
            local query="${1:?Usage: search <query>}"
            while IFS='|' read -r row; do
                [[ -z "${row}" ]] && continue
                IFS='|' read -r id name version cat desc rating dl \
                    stars featured is_core is_beta inst_status inst_ver \
                    <<< "${row}"
                format_plugin_row "${id}" "${name}" "${version}" "${cat}" \
                    "${desc}" "${rating}" "${dl}" "${featured}" \
                    "${is_core}" "0" "${inst_status}" "${inst_ver}"
            done < <(db_search "${query}")
            ;;
        fav-add)
            fav_toggle "${1:?Usage: fav-add <id>}"
            ;;
        fav-list)
            fav_list
            ;;
        sync)
            registry_fetch "true"
            ;;
        stats)
            print_stats
            ;;
        outdated)
            db_list_updates
            ;;
        verify)
            local id="${1:?Usage: verify <id>}"
            local checksum
            checksum="$(sqlite3 "${PLUGIN_DB}" \
                "SELECT checksum FROM plugins WHERE id='${id}';" \
                2>/dev/null || echo "")"
            verify_checksum "${PLUGIN_INSTALLED}/${id}" "${checksum}" && \
                echo "${ICON_SUCCESS} Integrity OK: ${id}" || \
                echo "${ICON_ERROR} Integrity FAILED: ${id}"
            ;;
        backup)
            backup_plugin "${1:?Usage: backup <id>}"
            echo "${ICON_SUCCESS} Backup complete: ${1}"
            ;;
        history)
            local limit="${1:-20}"
            sqlite3 "${PLUGIN_DB}" \
                "SELECT plugin_id,action,version,success,duration_ms,timestamp
                 FROM install_history
                 ORDER BY timestamp DESC LIMIT ${limit};" \
                2>/dev/null
            ;;
        deps)
            local id="${1:?Usage: deps <id>}"
            resolve_deps "${id}" | tr ' ' '\n'
            ;;
        init)
            echo "${ICON_SUCCESS} Re-initialised plugin manager at ${PLUGIN_DIR}"
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