#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗███╗   ██╗ ██████╗██████╗ ██╗   ██╗██████╗ ████████╗                   ║
# ║  ██╔════╝████╗  ██║██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝                   ║
# ║  █████╗  ██╔██╗ ██║██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║                      ║
# ║  ██╔══╝  ██║╚██╗██║██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║                      ║
# ║  ███████╗██║ ╚████║╚██████╗██║  ██║   ██║   ██║        ██║                      ║
# ║  ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝                      ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  backup encrypt                                           ║
# ║  GPG encrypt/decrypt archives • key management • symmetric/asymmetric           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BK_ENCRYPT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BK_ENCRYPT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  GPG KEY MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_enc_list_gpg_keys() {
    if ! command -v gpg &>/dev/null; then
        bk_fail "GPG not installed"
        bk_info "Install: paru -S gnupg"
        return 1
    fi

    local keys
    keys="$(gpg --list-secret-keys --keyid-format=long \
            --with-colons 2>/dev/null | \
            grep '^uid\|^sec' | head -20 || echo '')"

    if [[ -z "$keys" ]]; then
        bk_info "No GPG secret keys found"
        bk_info "Generate one: gpg --gen-key"
        return 0
    fi

    printf '\n  %sAvailable GPG keys:%s\n\n' "$(_bkdim)" "$(_bkr)"
    printf '  %s%-20s %-10s %s%s\n' "$(_bkdim)" "Key ID" "Created" "UID" "$(_bkr)"
    printf '  %s%s%s\n' "$(_bkdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_bkr)"

    gpg --list-secret-keys --keyid-format=long 2>/dev/null | \
    awk '
        /^sec/ {
            split($0, a, "/")
            split(a[2], b, " ")
            key_id = b[1]
            created = b[2]
        }
        /^uid/ {
            uid = $0
            sub(/.*\] /, "", uid)
            printf "  %-22s %-12s %s\n", key_id, created, uid
        }
    ' | head -10 | while IFS= read -r line; do
        printf '  %s%s%s\n' "$(_bksky)" "$line" "$(_bkr)"
    done
}

_enc_set_key() {
    local key_id="$1"
    mkdir -p "$(dirname "$_BK_GPGKEY_FILE")" 2>/dev/null || true
    printf '%s\n' "$key_id" > "$_BK_GPGKEY_FILE"
    bk_ok "Default GPG key set: ${key_id}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ENCRYPT EXISTING BACKUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_enc_encrypt_file() {
    local input="$1"  gpg_key="${2:-}"  symmetric="${3:-0}"

    local output="${input}.gpg"

    if [[ -f "$output" ]]; then
        bk_warn "Encrypted file already exists: ${output##*/}"
        printf '  %sOverwrite? [y/N] %s' "$(_bkyellow)" "$(_bkr)"
        local ans; read -r ans
        [[ "${ans,,}" != "y" ]] && return 0
    fi

    bk_spin_start "Encrypting: $(basename "$input")..."

    local gpg_exit=0

    if [[ $symmetric -eq 1 ]]; then
        gpg --batch --yes \
            --symmetric \
            --cipher-algo AES256 \
            --output "$output" \
            "$input" 2>/dev/null || gpg_exit=$?
    elif [[ -n "$gpg_key" ]]; then
        gpg --batch --yes \
            --recipient "$gpg_key" \
            --encrypt \
            --output "$output" \
            "$input" 2>/dev/null || gpg_exit=$?
    else
        # Auto-select key
        local auto_key
        auto_key="$(cat "$_BK_GPGKEY_FILE" 2>/dev/null || echo '')"
        if [[ -z "$auto_key" ]]; then
            bk_spin_stop 0 "No GPG key configured"
            bk_info "Set key: ash bk encrypt --set-key <key-id>"
            bk_info "Or use symmetric: ash bk encrypt --symmetric"
            return 1
        fi
        gpg --batch --yes \
            --recipient "$auto_key" \
            --encrypt \
            --output "$output" \
            "$input" 2>/dev/null || gpg_exit=$?
    fi

    if [[ $gpg_exit -eq 0 ]] && [[ -f "$output" ]]; then
        bk_spin_stop 1 "Encrypted: ${output##*/}"

        local orig_size enc_size
        orig_size="$(stat -c '%s' "$input" 2>/dev/null || echo 0)"
        enc_size="$(stat -c '%s' "$output" 2>/dev/null || echo 0)"

        bk_kv "Input"    "$(bk_human_size "$orig_size")"
        bk_kv "Output"   "$(bk_human_size "$enc_size")"

        # Optionally remove original
        printf '  %sRemove unencrypted original? [y/N] %s' \
            "$(_bkyellow)" "$(_bkr)"
        local rm_ans; read -r rm_ans
        if [[ "${rm_ans,,}" == "y" ]]; then
            shred -uz "$input" 2>/dev/null || rm -f "$input"
            bk_ok "Original securely deleted"
        fi

        return 0
    else
        bk_spin_stop 0 "Encryption failed (exit: ${gpg_exit})"
        rm -f "$output" 2>/dev/null || true
        return 1
    fi
}

_enc_decrypt_file() {
    local input="$1"

    # Remove .gpg extension for output
    local output="${input%.gpg}"
    [[ "$output" == "$input" ]] && output="${input}.dec"

    if [[ -f "$output" ]]; then
        bk_warn "Output file already exists: ${output##*/}"
        printf '  %sOverwrite? [y/N] %s' "$(_bkyellow)" "$(_bkr)"
        local ans; read -r ans
        [[ "${ans,,}" != "y" ]] && return 0
    fi

    bk_spin_start "Decrypting: $(basename "$input")..."

    local gpg_exit=0
    gpg --batch --yes \
        --output "$output" \
        --decrypt "$input" 2>/dev/null || gpg_exit=$?

    if [[ $gpg_exit -eq 0 ]] && [[ -f "$output" ]]; then
        bk_spin_stop 1 "Decrypted: ${output##*/}"
        bk_kv "Output" "${output/#$HOME/~}"
    else
        bk_spin_stop 0 "Decryption failed"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_backup_encrypt() {
    local action="status"
    local target_file=""
    local gpg_key=""
    local symmetric=0
    local set_key_id=""

    for arg in "${@:-}"; do
        case "$arg" in
            status|info|keys)    action="status"   ;;
            encrypt|enc|-e)      action="encrypt"  ;;
            decrypt|dec|-d)      action="decrypt"  ;;
            --symmetric|-s)      symmetric=1       ;;
            --key=*|-k=*)        gpg_key="${arg#*=}" ;;
            --set-key=*)         set_key_id="${arg#*=}"; action="set-key" ;;
            *.gpg)               target_file="$arg"; action="decrypt" ;;
            *.tar*|*.zst|*.gz)   target_file="$arg"; action="encrypt" ;;
            ash-*)
                # Backup ID — find the file
                local found_path
                found_path="$(bk_index_get "$arg" path)"
                [[ -n "$found_path" ]] && target_file="$found_path"
                ;;
            *)
                [[ -f "$arg" ]] && target_file="$arg"
                ;;
        esac
    done

    bk_section "🔐" "Backup Encryption" "$(_bkpink)"

    if ! command -v gpg &>/dev/null; then
        bk_fail "GPG not installed"
        bk_info "Install: paru -S gnupg"
        printf '\n'; return 1
    fi

    local gpg_ver
    gpg_ver="$(gpg --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1 || echo '?')"
    bk_kv "GPG version" "v${gpg_ver}"

    # Show current key
    if [[ -f "$_BK_GPGKEY_FILE" ]]; then
        bk_kv "Default key" "$(cat "$_BK_GPGKEY_FILE" 2>/dev/null)"
    else
        bk_kv "Default key" "$(bk_badge " NOT SET " "$(_bkyellow)")"
    fi

    case "$action" in
        status)
            _enc_list_gpg_keys
            ;;

        set-key)
            [[ -z "$set_key_id" ]] && {
                _enc_list_gpg_keys
                printf '\n  %sEnter key ID to use: %s' "$(_bkyellow)" "$(_bkr)"
                read -r set_key_id
            }
            [[ -z "$set_key_id" ]] && { bk_info "No key specified"; return 0; }
            _enc_set_key "$set_key_id"
            ;;

        encrypt)
            [[ -z "$target_file" ]] && {
                bk_fail "No file specified"
                bk_info "Usage: ash bk encrypt <file>"
                printf '\n'; return 1
            }
            [[ ! -f "$target_file" ]] && {
                bk_fail "File not found: ${target_file}"
                return 1
            }
            bk_kv "Input" "${target_file/#$HOME/~}"
            bk_kv "Mode"  "$([[ $symmetric -eq 1 ]] && echo 'symmetric (AES256)' || echo 'asymmetric (GPG)')"

            _enc_encrypt_file "$target_file" "$gpg_key" "$symmetric"

            bk_notify "🔐 Encrypted" "$(basename "$target_file")"
            ;;

        decrypt)
            [[ -z "$target_file" ]] && {
                bk_fail "No file specified"
                bk_info "Usage: ash bk encrypt decrypt <file.gpg>"
                printf '\n'; return 1
            }
            [[ ! -f "$target_file" ]] && {
                bk_fail "File not found: ${target_file}"
                return 1
            }
            bk_kv "Input" "${target_file/#$HOME/~}"
            _enc_decrypt_file "$target_file"
            bk_notify "🔓 Decrypted" "$(basename "$target_file")"
            ;;
    esac

    printf '\n'
}
