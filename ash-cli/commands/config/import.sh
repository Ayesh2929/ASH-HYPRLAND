#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG IMPORT                                          ║
# ║  Import config from JSON/TOML/ENV/conf with validation, merge & dry-run           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::import::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config import <file> [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${ASH_ACCENT}file${RST}   Path to config file to import (JSON, TOML, ENV, or conf)

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--format,   -F FORMAT${RST}   Force format: json|toml|env|conf (auto-detect default)
  ${ASH_MUTED}--merge,    -m${RST}           Merge into existing config (default: overwrite)
  ${ASH_MUTED}--section,  -s SECTION${RST}  Import only keys for this section
  ${ASH_MUTED}--dry-run,  -n${RST}           Preview changes without applying
  ${ASH_MUTED}--no-backup${RST}              Skip backup before import
  ${ASH_MUTED}--no-validate${RST}            Skip schema validation
  ${ASH_MUTED}--decrypt,  -d${RST}           Decrypt GPG-encrypted file before import
  ${ASH_MUTED}--force,    -f${RST}           Skip confirmation
  ${ASH_MUTED}--help,     -h${RST}           Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config import ~/ash-backup.json
  ash config import ~/ash-theme.json --section theme --merge
  ash config import config.env --dry-run
  ash config import encrypted.json.gpg --decrypt
EOF
}

# ── Detect format from extension ─────────────────────────────────────────────
_import::detect_format() {
    local path="$1"
    case "${path,,}" in
        *.json)         printf 'json' ;;
        *.toml)         printf 'toml' ;;
        *.env|*.sh)     printf 'env'  ;;
        *.conf|*.ini)   printf 'conf' ;;
        *)              printf 'conf' ;;  # default
    esac
}

# ── Parse JSON → flat key=value map ──────────────────────────────────────────
_import::parse_json() {
    local file="$1" section_filter="$2"
    python3 -c "
import json, sys

def flatten(obj, prefix=''):
    items = {}
    if isinstance(obj, dict):
        for k, v in obj.items():
            new_key = f'{prefix}.{k}' if prefix else k
            items.update(flatten(v, new_key))
    else:
        items[prefix] = str(obj).lower() if isinstance(obj, bool) else str(obj)
    return items

data = json.load(open('${file}'))
flat = flatten(data)
filter_sec = '${section_filter}'
for k, v in sorted(flat.items()):
    sec = k.split('.')[0]
    if filter_sec and sec != filter_sec:
        continue
    print(f'{k}={v}')
" 2>/dev/null
}

# ── Parse ENV → flat key=value map ───────────────────────────────────────────
_import::parse_env() {
    local file="$1" section_filter="$2"
    while IFS='=' read -r env_key val; do
        [[ "${env_key}" =~ ^ASH_ ]] || continue
        [[ "${env_key}" =~ ^# ]] && continue
        # Remove ASH_ prefix, convert _ to . and lowercase
        local cfg_key
        cfg_key=$(printf '%s' "${env_key#ASH_}" | tr '_' '.' | tr '[:upper:]' '[:lower:]')
        local section; section=$(printf '%s' "${cfg_key}" | cut -d. -f1)
        [[ -n "${section_filter}" ]] && [[ "${section}" != "${section_filter}" ]] && continue
        printf '%s=%s\n' "${cfg_key}" "${val//\"/}"
    done < "${file}"
}

# ── Parse CONF → flat key=value map ──────────────────────────────────────────
_import::parse_conf() {
    local file="$1" section_filter="$2"
    while IFS= read -r line; do
        # Skip comments & empty
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        [[ "${line}" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.*) ]] || continue
        local key="${BASH_REMATCH[1]// /}"
        local val="${BASH_REMATCH[2]}"
        # Strip inline comments
        val="${val%%#*}" val="${val%"${val##*[![:space:]]}"}"
        local section; section=$(printf '%s' "${key}" | cut -d. -f1)
        [[ -n "${section_filter}" ]] && [[ "${section}" != "${section_filter}" ]] && continue
        printf '%s=%s\n' "${key}" "${val}"
    done < "${file}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::import() {
    local src_file="" format="" section_filter="" merge=false
    local dry_run=false no_backup=false no_validate=false
    local decrypt=false force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)      config::import::help; return 0 ;;
            --format|-F)    format="${2:?'--format requires FORMAT'}"; shift 2 ;;
            --merge|-m)     merge=true; shift ;;
            --section|-s)   section_filter="${2:?'--section requires SECTION'}"; shift 2 ;;
            --dry-run|-n)   dry_run=true; shift ;;
            --no-backup)    no_backup=true; shift ;;
            --no-validate)  no_validate=true; shift ;;
            --decrypt|-d)   decrypt=true; shift ;;
            --force|-f)     force=true; shift ;;
            -*)             log::error "Unknown option: $1"; return 1 ;;
            *)              src_file="$1"; shift ;;
        esac
    done

    [[ -z "${src_file}" ]] && {
        log::error "Source file required"
        config::import::help; return 1
    }
    [[ ! -f "${src_file}" ]] && {
        log::error "File not found: ${src_file}"
        return 1
    }

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Decrypt ───────────────────────────────────────────────────────────────
    local work_file="${src_file}"
    if [[ "${decrypt}" == "true" ]] || [[ "${src_file}" == *.gpg ]]; then
        utils::require "gpg"
        local decrypted; decrypted=$(mktemp)
        # shellcheck disable=SC2064
        trap "rm -f '${decrypted}'" EXIT
        ash_spinner_start "Decrypting…"
        gpg --batch --yes --output "${decrypted}" --decrypt "${src_file}" 2>/dev/null || {
            ash_spinner_stop 1 "Decryption failed"
            log::error "Failed to decrypt: ${src_file}"
            return 1
        }
        ash_spinner_stop 0 "Decrypted"
        work_file="${decrypted}"
    fi

    # ── Detect format ─────────────────────────────────────────────────────────
    [[ -z "${format}" ]] && format=$(_import::detect_format "${src_file}")

    # ── Parse ─────────────────────────────────────────────────────────────────
    ash_spinner_start "Parsing ${format} config…"
    local parsed_kv=()
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        parsed_kv+=("${line}")
    done < <(
        case "${format,,}" in
            json) _import::parse_json "${work_file}" "${section_filter}" ;;
            env)  _import::parse_env  "${work_file}" "${section_filter}" ;;
            conf) _import::parse_conf "${work_file}" "${section_filter}" ;;
            *)
                ash_spinner_stop 1 "Unknown format"
                log::error "Unsupported format: ${format}"
                return 1
                ;;
        esac
    )
    ash_spinner_stop 0 "Parsed ${#parsed_kv[@]} key(s)"

    (( ${#parsed_kv[@]} == 0 )) && {
        log::warn "No keys found in import file"
        return 0
    }

    # ── Validate & preview ────────────────────────────────────────────────────
    log::blank
    printf '  %s⚙  Import Preview%s\n\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
    printf '  %s%-45s  %-20s  %-20s%s\n' \
        "${BOLD}${ASH_MUTED}" "Key" "Current" "New Value" "${RST}"
    ash_hr "─" 90 "${ASH_MUTED}"

    local valid_pairs=() invalid_count=0

    for kv in "${parsed_kv[@]}"; do
        local key="${kv%%=*}" value="${kv#*=}"

        # Validate
        if [[ "${no_validate}" == "false" ]]; then
            if ! cfg::_key_exists_in_schema "${key}"; then
                printf '  %s%-45s%s  %sSKIPPED (unknown key)%s\n' \
                    "${ASH_MUTED}" "${key}" "${RST}" "${ASH_MUTED}" "${RST}"
                (( invalid_count++ ))
                continue
            fi
            if ! cfg::_validate_value "${key}" "${value}" 2>/dev/null; then
                printf '  %s%-45s%s  %sINVALID%s\n' \
                    "${ASH_ERROR}" "${key}" "${RST}" "${ASH_ERROR}" "${RST}"
                (( invalid_count++ ))
                continue
            fi
        fi

        local current; current=$(cfg::_read_raw "${key}" "${file}")
        local type; type=$(cfg::_schema_type "${key}" 2>/dev/null || printf "string")
        local val_color; val_color=$(_get::value_color "${type}" "${value}" 2>/dev/null || printf '%s' "${ASH_INFO}")

        local change_marker=""
        if [[ "${current}" != "${value}" ]]; then
            change_marker=" ${ASH_WARNING}●${RST}"
        fi

        printf '  %s%-45s%s  %s%-20s%s  %s%-20s%s%s\n' \
            "${ASH_MUTED}" "${key}" "${RST}" \
            "${ASH_MUTED}" "$(ash_truncate "${current:-<unset>}" 20)" "${RST}" \
            "${val_color}${BOLD}" "$(ash_truncate "${value}" 20)" "${RST}" \
            "${change_marker}"

        valid_pairs+=("${key}=${value}")
    done

    log::blank
    printf '  %s%d valid, %d skipped%s\n' \
        "${ASH_MUTED}" "${#valid_pairs[@]}" "${invalid_count}" "${RST}"

    [[ "${dry_run}" == "true" ]] && {
        log::blank
        printf '  %sDRY RUN — no changes applied%s\n' "${ASH_WARNING}" "${RST}"
        log::blank
        return 0
    }

    # ── Confirm ───────────────────────────────────────────────────────────────
    [[ "${force}" != "true" ]] && {
        utils::confirm "Apply ${#valid_pairs[@]} config value(s)?" "n" || {
            log::info "Import cancelled."; return 0
        }
    }

    # ── Backup ────────────────────────────────────────────────────────────────
    if [[ "${no_backup}" == "false" ]]; then
        local backup="${CFG_BACKUP_DIR}/ash.conf.$(date '+%Y%m%d-%H%M%S').bak"
        mkdir -p "${CFG_BACKUP_DIR}"
        cp "${file}" "${backup}"
        log::info "Backup saved: ${backup}"
    fi

    # ── Apply ─────────────────────────────────────────────────────────────────
    cfg::lock || return 1
    local applied=0
    for kv in "${valid_pairs[@]}"; do
        local key="${kv%%=*}" value="${kv#*=}"
        cfg::_write_raw "${key}" "${value}" "${file}"
        cfg::_record "import" "${key}" "" "${value}"
        (( applied++ ))
    done
    cfg::unlock

    log::blank
    log::success "Imported ${applied} config value(s)"
    log::blank
}
