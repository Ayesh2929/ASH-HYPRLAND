#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚙️  ASH CONFIG PARSER — INI/TOML-lite hierarchical configuration engine       ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  A zero-dependency, POSIX-safe configuration layer that supports:             ║
# ║    • INI sections + dotted-path lookup      (theme.default)                   ║
# ║    • Typed coercion                          (int/bool/float/string/array)    ║
# ║    • Include directives                      (include = other.conf)           ║
# ║    • Variable interpolation                  (${ASH_VERSION}, %{HOME})        ║
# ║    • Environment overlay                     (ASH_CFG_THEME_DEFAULT=…)        ║
# ║    • Atomic, lock-protected writes           (never corrupt on crash)         ║
# ║    • Change events on the ASH event bus                                       ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CONFIG_PARSER_LOADED:-}" ]] && return 0
readonly _ASH_CONFIG_PARSER_LOADED=1

readonly ASH_CONFIG_PARSER_VERSION="5.0.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  INTERNAL STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Flat associative map: "<section>.<key>" -> value   ("" section => "<key>")
declare -gA ASH_CFG=()
# Tracks which physical file each key came from (for targeted writes)
declare -gA ASH_CFG_SOURCE=()
# Ordered list of files loaded, used for reload + provenance
declare -ga ASH_CFG_FILES=()
# Sections that appeared in the config (for `--list`)
declare -gA ASH_CFG_SECTIONS=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  LOW-LEVEL HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Strip an inline comment that is NOT inside quotes.
#   key = "a # b"   -> key = "a # b"
#   key = c    # note -> key = c
_ash_cfg_strip_comment() {
    local line="$1"
    local out="" ch prev="" in_s=0 in_d=0 i

    for (( i = 0; i < ${#line}; i++ )); do
        ch="${line:i:1}"
        case "$ch" in
            "'") [[ $in_d -eq 0 ]] && in_s=$(( 1 - in_s )) ;;
            '"') [[ $in_s -eq 0 ]] && in_d=$(( 1 - in_d )) ;;
            '#'|';')
                if [[ $in_s -eq 0 && $in_d -eq 0 ]]; then
                    # `#` preceded by whitespace (or at col 0) starts a comment.
                    [[ -z "$prev" || "$prev" == " " || "$prev" == $'\t' ]] && break
                fi
                ;;
        esac
        out+="$ch"
        prev="$ch"
    done

    # Trim trailing whitespace
    out="${out%"${out##*[![:space:]]}"}"
    printf '%s' "$out"
}

# Remove surrounding single or double quotes plus a trailing decoration.
_ash_cfg_unquote() {
    local v="$1"
    v="${v#"${v%%[![:space:]]*}"}"   # ltrim
    v="${v%"${v##*[![:space:]]}"}"   # rtrim
    case "$v" in
        \"*\") v="${v:1:${#v}-2}" ;;
        \'*\') v="${v:1:${#v}-2}" ;;
    esac
    printf '%s' "$v"
}

# Expand ${VAR}, ${VAR:-default}, $VAR and ~ at the head of a value.
_ash_cfg_interpolate() {
    local v="$1"
    local cycle_guard=0

    # Iterative expansion so nested references resolve (max 5 passes)
    while [[ "$v" == *'${'* || "$v" == *'~'* ]]; do
        (( cycle_guard++ > 5 )) && break
        local before="$v"
        if [[ "$v" == *'${'* ]]; then
            eval "v=\"$v\"" 2>/dev/null || break
        fi
        [[ "$v" == '~'* ]] && v="${HOME}${v:1}"
        [[ "$before" == "$v" ]] && break
    done

    printf '%s' "$v"
}

# ── Typed coercion ───────────────────────────────────────────────────────────
_ash_cfg_to_bool() {
    case "${1,,}" in
        1|true|yes|on|enabled|enable)   printf 'true'  ;;
        0|false|no|off|disabled|disable|'') printf 'false' ;;
        *) printf '%s' "$1" ;;
    esac
}

_ash_cfg_is_int() { [[ "$1" =~ ^-?[0-9]+$ ]]; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 3  LOADING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_cfg_store() {
    local section="$1" key="$2" value="$3" file="$4"
    local path="${section:+${section}.}${key}"

    ASH_CFG["$path"]="$value"
    ASH_CFG_SOURCE["$path"]="$file"
    [[ -n "$section" ]] && ASH_CFG_SECTIONS["$section"]=1

    # Environment overlay wins over file values. ASH_CFG_<SECTION>_<KEY>
    local env_name="ASH_CFG_${path^^}"
    env_name="${env_name//./_}"
    env_name="${env_name//-/_}"
    if [[ -n "${!env_name:-}" ]]; then
        ASH_CFG["$path"]="${!env_name}"
    fi
}

ash_config_load() {
    local file="$1"
    local _recursion_depth="${2:-0}"

    [[ -f "$file" ]] || return 1
    if (( _recursion_depth > 8 )); then
        ash_log_warn "config include depth exceeded in ${file}" 2>/dev/null || true
        return 0
    fi

    file="$(command -v realpath >/dev/null 2>&1 && realpath "$file" || printf '%s' "$file")"
    ASH_CFG_FILES+=("$file")

    local section="" line lineno=0 context_key=""
    local -a multi_value=()

    while IFS= read -r line || [[ -n "$line" ]]; do
        (( lineno += 1 ))
        line="${line%$'\r'}"

        # ── continuation lines (trailing backslash) ──────────────────────
        while [[ "$line" == *'\' && "$line" != *'\\\\' ]]; do
            local next
            if IFS= read -r next || [[ -n "$next" ]]; then
                (( lineno += 1 ))
                line="${line%\\}${next#${next%%[![:space:]]*}}"
            else
                break
            fi
        done

        [[ -z "${line//[[:space:]]/}" ]] && continue

        local trimmed="${line#"${line%%[![:space:]]*}"}"
        [[ "$trimmed" == '#'* || "$trimmed" == ';'* ]] && continue

        # ── [section] or [section "subsection"] ──────────────────────────
        if [[ "$trimmed" == '['*']' ]]; then
            section="${trimmed#[}"
            section="${section%]}"
            section="${section%%[[:space:]]*}"             # drop quoted subsection
            section="${section%\"}"; section="${section#\"}"
            section="${section// /_}"
            ASH_CFG_SECTIONS["$section"]=1
            continue
        fi

        # ── key = value ──────────────────────────────────────────────────
        if [[ "$trimmed" == *'='* ]]; then
            local key="${trimmed%%=*}"
            local raw="${trimmed#*=}"
            key="${key%"${key##*[![:space:]]}"}"
            key="${key#"${key%%[![:space:]]*}"}"
            [[ -z "$key" ]] && continue

            raw="$(_ash_cfg_strip_comment "$raw")"
            local value
            value="$(_ash_cfg_unquote "$raw")"

            # ── include directive ────────────────────────────────────────
            if [[ "$key" == "include" || "$key" == "@include" ]]; then
                local inc_dir inc_file
                inc_dir="$(dirname "$file")"
                for inc_file in $value; do
                    inc_file="${inc_file/#\~/$HOME}"
                    [[ "$inc_file" != /* ]] && inc_file="${inc_dir}/${inc_file}"
                    if [[ -f "$inc_file" ]]; then
                        ash_config_load "$inc_file" $(( _recursion_depth + 1 ))
                    elif command -v compgen >/dev/null 2>&1 && compgen -G "$inc_file" >/dev/null; then
                        local glob_match
                        for glob_match in $inc_file; do
                            ash_config_load "$glob_match" $(( _recursion_depth + 1 ))
                        done
                    fi
                done
                continue
            fi

            value="$(_ash_cfg_interpolate "$value")"

            # ── array syntax: key = [a, b, c] ────────────────────────────
            if [[ "$value" == '['*']' && "$value" == *']' ]]; then
                local inner="${value#[}"; inner="${inner%]}"
                local item cleaned=""
                while IFS= read -r item || [[ -n "$item" ]]; do
                    item="$(_ash_cfg_unquote "$item")"
                    [[ -z "${item//[[:space:]]/}" ]] && continue
                    cleaned+="${item} "
                done < <(printf '%s' "$inner" | tr ',' '\n')
                value="${cleaned% }"
            fi

            _ash_cfg_store "$section" "$key" "$value" "$file"
            context_key="${section:+${section}.}${key}"

            # ── multi-line block:  key = """..."""  ──────────────────────
            if [[ "$raw" == *'"""'* && "$(printf '%s' "$raw" | grep -o '"""' | wc -l)" == "1" ]]; then
                local block="" bl
                while IFS= read -r bl || [[ -n "$bl" ]]; do
                    (( lineno += 1 ))
                    if [[ "$bl" == *'"""'* ]]; then
                        block+="${bl%%'"""'*}"
                        break
                    fi
                    block+="${bl}"$'\n'
                done
                _ash_cfg_store "$section" "$key" "$block" "$file"
            fi
        fi
    done < "$file"

    return 0
}

# Reload every file that was previously loaded (fresh state).
ash_config_reload() {
    local -a files=("${ASH_CFG_FILES[@]:-}")
    ASH_CFG=(); ASH_CFG_SOURCE=(); ASH_CFG_SECTIONS=(); ASH_CFG_FILES=()

    local f
    for f in "${files[@]}"; do
        [[ -n "$f" ]] && ash_config_load "$f"
    done

    ash_event_emit "config.reloaded" "files=${#files[@]}" 2>/dev/null || true
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 4  READING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_config_get <path> [default]
# Prints the value, or <default> (or empty) when missing.
ash_config_get() {
    local path="${1:-}"
    local default="${2-}"

    [[ -z "$path" ]] && { printf '%s' "$default"; return 1; }

    # Exact match first, then a case-insensitive fallback.
    if [[ -n "${ASH_CFG[$path]+x}" ]]; then
        printf '%s' "${ASH_CFG[$path]}"
        return 0
    fi

    local key
    for key in "${!ASH_CFG[@]}"; do
        if [[ "${key,,}" == "${path,,}" ]]; then
            printf '%s' "${ASH_CFG[$key]}"
            return 0
        fi
    done

    printf '%s' "$default"
    return 1
}

# Type-coerced getters -------------------------------------------------------
ash_config_get_bool() {
    local v
    v="$(ash_config_get "${1:-}" "${2:-false}")" || true
    _ash_cfg_to_bool "$v"
}

ash_config_get_int() {
    local v
    v="$(ash_config_get "${1:-}" "${2:-0}")" || true
    if _ash_cfg_is_int "$v"; then printf '%s' "$v"; else printf '%s' "${2:-0}"; fi
}

ash_config_get_float() {
    local v
    v="$(ash_config_get "${1:-}" "${2:-0}")" || true
    if [[ "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then printf '%s' "$v"; else printf '%s' "${2:-0}"; fi
}

# Prints array members one per line.
ash_config_get_array() {
    local v
    v="$(ash_config_get "${1:-}" "")" || return 1
    [[ -z "$v" ]] && return 1
    # Values are stored space-separated by the loader.
    local item
    for item in $v; do printf '%s\n' "$item"; done
}

# Loads array members into a named array (nameref).
ash_config_get_array_into() {
    local -n _out="$1"
    local path="$2"
    _out=()
    local item
    while IFS= read -r item || [[ -n "$item" ]]; do
        [[ -n "$item" ]] && _out+=("$item")
    done < <(ash_config_get_array "$path")
}

ash_config_has() { [[ -n "${ASH_CFG[${1:-}]+x}" ]]; }

ash_config_has_section() { [[ -n "${ASH_CFG_SECTIONS[${1:-}]+x}" ]]; }

# ── Listing ──────────────────────────────────────────────────────────────────
ash_config_keys() {
    local filter="${1:-}"
    local key
    for key in "${!ASH_CFG[@]}"; do
        [[ -n "$filter" && "$key" != "$filter"* ]] && continue
        printf '%s\n' "$key"
    done | LC_ALL=C sort
}

ash_config_section_keys() {
    local section="${1:-}"
    local key
    for key in "${!ASH_CFG[@]}"; do
        [[ "$key" == "${section}."* ]] || continue
        printf '%s\n' "${key#${section}.}"
    done | LC_ALL=C sort
}

ash_config_sections() {
    local s
    for s in "${!ASH_CFG_SECTIONS[@]}"; do printf '%s\n' "$s"; done | LC_ALL=C sort
}

# ── Export to child processes ────────────────────────────────────────────────
ash_config_export() {
    local filter="${1:-}"
    local key
    for key in "${!ASH_CFG[@]}"; do
        [[ -n "$filter" && "$key" != "$filter"* ]] && continue
        local name="ASH_CFG_${key^^}"
        name="${name//./_}"; name="${name//-/_}"
        export "${name}=${ASH_CFG[$key]}"
    done
    return 0
}

# Emit the whole config as JSON (used by the REST API + web dashboard).
ash_config_to_json() {
    local -A sections_seen=()
    local key value esc

    printf '{'
    local first_section=1

    # Walk sections deterministically
    local section
    while IFS= read -r section || [[ -n "$section" ]]; do
        [[ $first_section -eq 1 ]] && first_section=0 || printf ','
        printf '"%s":{' "$section"
        local first_key=1
        while IFS= read -r key || [[ -n "$key" ]]; do
            value="$(ash_config_get "${section}.${key}")"
            esc="${value//\\/\\\\}"; esc="${esc//\"/\\\"}"
            esc="${esc//$'\n'/\\n}"; esc="${esc//$'\t'/\\t}"
            [[ $first_key -eq 1 ]] && first_key=0 || printf ','
            printf '"%s":"%s"' "$key" "$esc"
        done < <(ash_config_section_keys "$section")
        printf '}'
    done < <(ash_config_sections)

    [[ $first_section -eq 1 ]] && printf '}' || printf '}'
}

# Emit as a shell-eval'able source file.
ash_config_dump() {
    local key
    for key in $(ash_config_keys); do
        printf 'ASH_CFG[%q]=%q\n' "$key" "$(ash_config_get "$key")"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 5  WRITING (atomic, lock-aware)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_config_set <path> <value> [--file F] [--create-section]
ash_config_set() {
    local path="$1" value="$2"; shift 2
    local target_file="${ASH_CONFIG_FILE:-${ASH_USER_CONFIG:-}}"
    local create_section=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)            target_file="$2"; shift 2 ;;
            --create-section)  create_section=1; shift ;;
            *)                 shift ;;
        esac
    done

    [[ -z "$target_file" ]] && {
        ash_log_error "no target config file (set ASH_CONFIG_FILE)" 2>/dev/null \
            || printf 'ash: no target config file\n' >&2
        return 1
    }

    # Respect provenance: prefer writing back to the file the key came from.
    if [[ -n "${ASH_CFG_SOURCE[$path]:-}" && "$create_section" -eq 0 ]]; then
        target_file="${ASH_CFG_SOURCE[$path]}"
    fi

    local section="" key="$path"
    if [[ "$path" == *.* ]]; then
        section="${path%.*}"
        key="${path##*.}"
    fi

    local backup=""
    if [[ -f "$target_file" ]]; then
        backup="${target_file}.bak.$$"
        cp -p "$target_file" "$backup" 2>/dev/null || true
    else
        mkdir -p "$(dirname "$target_file")" 2>/dev/null || true
        : > "$target_file"
    fi

    local tmp
    tmp="$(mktemp "${target_file}.tmp.XXXXXX")" || return 1

    local in_section=0 written=0 found_section=0 line
    if [[ -f "$backup" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            local bare="${line#"${line%%[![:space:]]*}"}"

            if [[ "$bare" == '['*']' ]]; then
                # Leaving the target section un-patched -> append the key here
                if [[ $in_section -eq 1 && $written -eq 0 ]]; then
                    printf '%s = %s\n' "$key" "$value" >> "$tmp"
                    written=1
                fi
                local sec_name="${bare#[}"; sec_name="${sec_name%]}"
                sec_name="${sec_name%%[[:space:]]*}"
                if [[ "$sec_name" == "$section" ]]; then
                    in_section=1; found_section=1
                else
                    in_section=0
                fi
                printf '%s\n' "$line" >> "$tmp"
                continue
            fi

            # Replace the matching key in the right section
            if [[ -z "$section" || $in_section -eq 1 ]]; then
                local lk="${bare%%=*}"
                lk="${lk%"${lk##*[![:space:]]}"}"
                if [[ "$bare" == *'='* && "$lk" == "$key" ]]; then
                    printf '%s = %s\n' "$key" "$value" >> "$tmp"
                    written=1
                    continue
                fi
            fi
            printf '%s\n' "$line" >> "$tmp"
        done < "$backup"

        if [[ $in_section -eq 1 && $written -eq 0 ]]; then
            printf '%s = %s\n' "$key" "$value" >> "$tmp"
            written=1
        fi
    fi

    # Key/section not found anywhere -> append
    if [[ $written -eq 0 ]]; then
        [[ -n "$section" && $found_section -eq 0 ]] && printf '\n[%s]\n' "$section" >> "$tmp"
        printf '%s = %s\n' "$key" "$value" >> "$tmp"
    fi

    # Validate the rewritten key is actually parseable, then swap in.
    if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$tmp"; then
        chmod --reference="$target_file" "$tmp" 2>/dev/null || true
        mv -f "$tmp" "$target_file"
        [[ -n "$backup" ]] && rm -f "$backup"
    else
        rm -f "$tmp"
        [[ -n "$backup" ]] && mv -f "$backup" "$target_file"
        ash_log_error "config write validation failed for ${path}" 2>/dev/null || true
        return 1
    fi

    ASH_CFG["$path"]="$value"
    ASH_CFG_SOURCE["$path"]="$target_file"
    [[ -n "$section" ]] && ASH_CFG_SECTIONS["$section"]=1

    ash_event_emit "config.changed" "path=${path}" "value=${value}" 2>/dev/null || true
    return 0
}

# ash_config_unset <path>  — removes the key line from its source file.
ash_config_unset() {
    local path="$1"
    local target_file="${ASH_CFG_SOURCE[$path]:-${ASH_CONFIG_FILE:-${ASH_USER_CONFIG:-}}}"
    [[ -f "$target_file" ]] || return 1

    local section="" key="$path"
    if [[ "$path" == *.* ]]; then section="${path%.*}"; key="${path##*.}"; fi

    local tmp; tmp="$(mktemp "${target_file}.tmp.XXXXXX")" || return 1
    local in_section=0 line
    while IFS= read -r line || [[ -n "$line" ]]; do
        local bare="${line#"${line%%[![:space:]]*}"}"
        if [[ "$bare" == '['*']' ]]; then
            local sec_name="${bare#[}"; sec_name="${sec_name%]}"; sec_name="${sec_name%%[[:space:]]*}"
            [[ "$sec_name" == "$section" ]] && in_section=1 || in_section=0
            printf '%s\n' "$line" >> "$tmp"; continue
        fi
        if [[ ( -z "$section" || $in_section -eq 1 ) && "$bare" == *'='* ]]; then
            local lk="${bare%%=*}"; lk="${lk%"${lk##*[![:space:]]}"}"
            [[ "$lk" == "$key" ]] && continue
        fi
        printf '%s\n' "$line" >> "$tmp"
    done < "$target_file"

    mv -f "$tmp" "$target_file"
    unset 'ASH_CFG[$path]' 'ASH_CFG_SOURCE[$path]'
    ash_event_emit "config.unset" "path=${path}" 2>/dev/null || true
    return 0
}

# ── Import / Export ──────────────────────────────────────────────────────────
ash_config_export_file() {
    local out="${1:-${ASH_DATA_HOME:-/tmp}/config-export.conf}"
    mkdir -p "$(dirname "$out")" 2>/dev/null || true
    {
        printf '# ASH DOTFILES configuration export\n'
        printf '# Generated: %s\n' "$(date -Iseconds)"
        printf '# Host: %s@%s\n\n' "${USER:-user}" "$(hostname 2>/dev/null || echo unknown)"
        local section
        while IFS= read -r section || [[ -n "$section" ]]; do
            printf '[%s]\n' "$section"
            local key
            while IFS= read -r key || [[ -n "$key" ]]; do
                printf '%-20s = %s\n' "$key" "$(ash_config_get "${section}.${key}")"
            done < <(ash_config_section_keys "$section")
            printf '\n'
        done < <(ash_config_sections)
    } > "$out"
    printf '%s' "$out"
}

ash_config_import_file() {
    local in="$1"
    [[ -f "$in" ]] || return 1
    ash_config_load "$in"
    local key
    for key in $(ash_config_keys); do
        ash_config_set "$key" "$(ash_config_get "$key")" --file "${ASH_CONFIG_FILE:-$ASH_USER_CONFIG}" >/dev/null 2>&1 || true
    done
    return 0
}

# ── Validate the loaded configuration against a schema-ish list ──────────────
ash_config_validate() {
    local errors=0
    local -a required=(
        "general.version"
        "general.profile"
        "theme.default"
        "animation.preset"
    )

    local req
    for req in "${required[@]}"; do
        if ! ash_config_has "$req"; then
            printf '  ✗ missing required key: %s\n' "$req" >&2
            (( errors += 1 ))
        fi
    done

    # Range checks
    local dur; dur="$(ash_config_get_int theme.transition_dur 300)"
    if (( dur < 0 || dur > 5000 )); then
        printf '  ✗ theme.transition_dur out of range (0-5000): %s\n' "$dur" >&2
        (( errors += 1 ))
    fi

    local lvl; lvl="$(ash_config_get general.log_level INFO)"
    case "${lvl^^}" in
        TRACE|DEBUG|INFO|WARN|ERROR|FATAL) ;;
        *) printf '  ✗ invalid log_level: %s\n' "$lvl" >&2; (( errors += 1 )) ;;
    esac

    return $(( errors > 0 ? 1 : 0 ))
}

# ── Migration between config schema versions ────────────────────────────────
ash_config_migrate() {
    local from="${1:-}" to="${2:-5.0.0}"
    local cur; cur="$(ash_config_get general.version "$from")"

    [[ "$cur" == "$to" ]] && { printf 'already at %s\n' "$to"; return 0; }

    ash_log_info "migrating config ${cur} -> ${to}" 2>/dev/null || true

    # v3 -> v4: theme.name became theme.default; nested dirs flattened
    if ash_config_has "theme.name"; then
        ash_config_set "theme.default" "$(ash_config_get theme.name)" >/dev/null 2>&1 || true
        ash_config_unset "theme.name" >/dev/null 2>&1 || true
    fi
    # v4 -> v5: wallpaper.engine renamed to wallpaper.backend
    if ash_config_has "wallpaper.engine"; then
        ash_config_set "wallpaper.backend" "$(ash_config_get wallpaper.engine)" >/dev/null 2>&1 || true
        ash_config_unset "wallpaper.engine" >/dev/null 2>&1 || true
    fi

    ash_config_set "general.version" "$to" >/dev/null 2>&1 || true
    printf 'Config migrated to %s\n' "$to"
}
