#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  backup restore                                           ║
# ║  Restore from backup: interactive picker • partial restore • conflict handling   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BK_RESTORE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BK_RESTORE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_restore_animation() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local frames=( '⏪' '⏮' '⏪' '▶' '⏪' )
        for frame in "${frames[@]}"; do
            printf '\r  %s  %s%sRestoring...%s' \
                "$frame" "$(_bkblue)$(_bkbold)" "" "$(_bkr)"
            sleep 0.12
        done
        printf '\r  %-50s\n' ""
    fi
}

_restore_pick_backup() {
    [[ -f "$_BK_INDEX_FILE" ]] || return 1

    local fzf_input
    fzf_input="$(python3 - << 'PYEOF'
import json, os, sys

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R     = '' if no_color else '\033[0m'
SKY   = '' if no_color else '\033[38;2;137;220;235m'
GRN   = '' if no_color else '\033[38;2;166;227;161m'
TEAL  = '' if no_color else '\033[38;2;148;226;213m'
PEACH = '' if no_color else '\033[38;2;250;179;135m'
DIM   = '' if no_color else '\033[38;2;108;112;134m'

try:
    data = json.load(open(os.environ.get('_BK_INDEX_FILE','')))
except:
    sys.exit(1)

for bk_id, entry in sorted(data.items(),
                             key=lambda x: x[1].get('created_at',''),
                             reverse=True):
    path      = entry.get('path','?')
    bk_type   = entry.get('type','?')
    size      = entry.get('size_bytes', 0)
    created   = entry.get('created_at','?')[:19]
    encrypted = '🔐' if entry.get('encrypted') else '  '
    status    = entry.get('status','?')

    if size >= 1073741824:
        size_s = f'{size/1073741824:.1f}GB'
    elif size >= 1048576:
        size_s = f'{size/1048576:.1f}MB'
    elif size >= 1024:
        size_s = f'{size/1024:.1f}KB'
    else:
        size_s = f'{size}B'

    type_col = TEAL if bk_type=='full' else (PEACH if bk_type=='incremental' else GRN)

    print(f'{bk_id}\t{encrypted}{SKY}{created}{R}  '
          f'{type_col}{bk_type:<14}{R}'
          f'{DIM}{size_s:<10}{R}  '
          f'{DIM}{os.path.basename(path)}{R}')
PYEOF
)"

    if [[ -z "$fzf_input" ]]; then
        bk_info "No backups found in index"
        return 1
    fi

    if command -v fzf &>/dev/null; then
        printf '%s\n' "$fzf_input" | \
            fzf --prompt "  ⏪  Select backup to restore: " \
                --height=20 \
                --border=rounded \
                --ansi \
                --delimiter='\t' \
                --with-nth=2 \
                --color="hl:$(printf '%s' "$(_bkmauve)" | sed 's/\033\[//;s/m//')" \
                --header="↵=restore  ESC=cancel" \
                2>/dev/null | awk -F'\t' '{print $1}'
    else
        printf '\n  %sAvailable backups:%s\n\n' "$(_bkdim)" "$(_bkr)"
        local i=0
        local -a ids=()

        while IFS=$'\t' read -r id display; do
            (( i++ )) || true
            ids+=("$id")
            printf '  %s%3d%s  %s\n' "$(_bkpeach)" "$i" "$(_bkr)" "$display"
        done <<< "$fzf_input"

        printf '\n  %sEnter number [1-%d]: %s' "$(_bkyellow)" "$i" "$(_bkr)"
        local choice; read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           (( choice >= 1 )) && (( choice <= ${#ids[@]} )); then
            printf '%s' "${ids[$((choice-1))]}"
        fi
    fi
}

ash_backup_restore() {
    local bk_id=""  restore_dest="/"  partial=""  dry_run=0

    for arg in "${@:-}"; do
        case "$arg" in
            --dest=*|-d=*)    restore_dest="${arg#*=}"  ;;
            --partial=*)      partial="${arg#*=}"       ;;
            --dry-run|-n)     dry_run=1                 ;;
            ash-*)            bk_id="$arg"             ;;
        esac
    done

    bk_section "⏪" "Restore Backup" "$(_bkpeach)"

    # Interactive picker
    if [[ -z "$bk_id" ]]; then
        bk_id="$(_restore_pick_backup)"
    fi

    [[ -z "$bk_id" ]] && { bk_info "No backup selected"; printf '\n'; return 0; }

    # Look up backup path
    local bk_path
    bk_path="$(bk_index_get "$bk_id" path)"

    if [[ -z "$bk_path" ]] || [[ ! -f "$bk_path" ]]; then
        # Try direct file path
        bk_path="$(find "$_BK_DEFAULT_DIR" -name "${bk_id}*" 2>/dev/null | head -1 || echo '')"
        [[ -z "$bk_path" ]] && {
            bk_fail "Backup not found: ${bk_id}"
            return 1
        }
    fi

    local bk_size
    bk_size="$(stat -c '%s' "$bk_path" 2>/dev/null | \
               awk '{if($1>=1073741824)printf "%.1fGB",$1/1073741824; \
                    else if($1>=1048576)printf "%.1fMB",$1/1048576; \
                    else printf "%.1fKB",$1/1024}')"

    bk_kv "Backup ID"  "$bk_id"
    bk_kv "File"       "${bk_path/#$HOME/~}"
    bk_kv "Size"       "$bk_size"
    bk_kv "Restore to" "$restore_dest"
    [[ -n "$partial" ]] && bk_kv "Filter" "$partial"

    # Check encryption
    local is_encrypted=0
    [[ "$bk_path" =~ \.gpg$ ]] && is_encrypted=1

    if [[ $is_encrypted -eq 1 ]]; then
        bk_kv "Encrypted" "$(bk_badge " 🔐 GPG " "$(_bkteal)")"
    fi

    # Warning
    bk_warn "This will overwrite files in: ${restore_dest}"

    if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
        printf '  %sContinue with restore? [y/N] %s' "$(_bkyellow)" "$(_bkr)"
        local ans; read -r ans
        [[ "${ans,,}" != "y" ]] && { bk_info "Restore cancelled"; printf '\n'; return 0; }
    fi

    if [[ $dry_run -eq 1 ]]; then
        bk_info "[DRY RUN] Would restore: ${bk_id} → ${restore_dest}"
        printf '\n'; return 0
    fi

    local start_time
    start_time="$(date +%s)"
    local work_file="$bk_path"

    # Decrypt if needed
    if [[ $is_encrypted -eq 1 ]]; then
        bk_step "Decrypting archive..."
        local tmp_dec
        tmp_dec="$(mktemp --suffix=.tar.zst)"
        trap 'rm -f "$tmp_dec"' EXIT INT TERM

        if gpg --batch --yes \
               --decrypt \
               --output "$tmp_dec" \
               "$bk_path" 2>/dev/null; then
            work_file="$tmp_dec"
            bk_ok "Decrypted successfully"
        else
            bk_fail "Decryption failed — wrong passphrase or key?"
            rm -f "$tmp_dec" 2>/dev/null || true
            return 1
        fi
    fi

    _restore_animation

    bk_spin_start "Extracting files..."

    mkdir -p "$restore_dest" 2>/dev/null || true

    local tar_args=( "tar" "--extract" "--preserve-permissions"
                     "--numeric-owner" "--file=$work_file"
                     "--directory=$restore_dest" )

    [[ -n "$partial" ]] && tar_args+=( "--wildcards" "$partial" )

    local tar_exit=0
    "${tar_args[@]}" 2>/dev/null || tar_exit=$?

    [[ -n "${tmp_dec:-}" ]] && rm -f "${tmp_dec}" 2>/dev/null || true
    trap - EXIT INT TERM

    local elapsed=$(( $(date +%s) - start_time ))

    if [[ $tar_exit -eq 0 ]]; then
        bk_spin_stop 1 "Extraction complete"
        bk_ok "Restore completed in ${elapsed}s"
        bk_log_ok "restore: ${bk_id} → ${restore_dest}  time=${elapsed}s"
        bk_notify "⏪ Restored" "${bk_id}  •  ${elapsed}s" "normal"
    else
        bk_spin_stop 0 "Extraction failed (exit: ${tar_exit})"
        return 1
    fi

    printf '\n'
}
