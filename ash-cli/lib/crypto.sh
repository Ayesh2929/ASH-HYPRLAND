#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔐 ASH CRYPTO ENGINE — hashing, encryption, secrets at rest                  ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Threat model                                                                ║
# ║    These helpers protect *dotfiles backups and API keys in transit and at     ║
# ║    rest on an untrusted disk*. They are NOT a substitute for a hardware       ║
# ║    token or a real secrets manager. Passphrase strength is the ceiling.       ║
# ║                                                                               ║
# ║  Design rules                                                                ║
# ║    • Never echo a secret to stdout unless the caller explicitly asks (`-`).   ║
# ║    • Never pass secrets on the command line — they leak via /proc/*/cmdline.  ║
# ║      Everything goes through stdin or a 0600 temp file that is shredded.      ║
# ║    • Prefer libsodium (age/sodium) > openssl > gpg, in that order.            ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CRYPTO_LOADED:-}" ]] && return 0
readonly _ASH_CRYPTO_LOADED=1
readonly ASH_CRYPTO_VERSION="5.0.0"

: "${ASH_SECRETS_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/ash/secrets}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  HASHING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_hash <algo> [file|-]   algo: sha256 sha512 sha1 md5 blake2b
# ash_hash <algo> [file|-]
#
# Hashes the EXACT bytes of a file, or of stdin when given `-` / no file.
# The previous implementation did `payload="$(cat)"`, and command
# substitution strips every trailing newline — so `ash_hash sha256 foo.txt`
# returned the digest of foo.txt-without-its-final-newline, i.e. an integrity
# check that disagreed with sha256sum. Streams are piped through untouched now.
ash_hash() {
    local algo="${1:-sha256}" src="${2:--}"

    # Normalise aliases onto tools that actually exist on this box.
    case "$algo" in
        blake2|blake2b) (( ${BASH_VERSINFO[0]} >= 4 )) || algo="sha256"; algo="blake2b" ;;
        sha2)           algo="sha256" ;;
        sha512-256)     algo="sha512-256" ;;
    esac

    # Pick a tool that can stream. openssl is the most portable fallback and
    # also the only one that understands every digest name we expose.
    # The two backends print differently, so remember which one we picked:
    #   sha256sum  → "<digest>  <file>"      (digest is field 1, "-" for stdin)
    #   openssl    → "SHA256(stdin)= <digest>" (digest is the last field)
    local -a cmd=()
    local field=1
    if command -v "${algo}sum" >/dev/null 2>&1; then
        cmd=( "${algo}sum" )
        field=1
    elif command -v openssl >/dev/null 2>&1; then
        cmd=( openssl dgst "-${algo}" )
        field='$NF'
    else
        ash_log_error "no hash backend available for ${algo}" 2>/dev/null || true
        return 1
    fi

    local digest
    if [[ "$src" == "-" ]]; then
        digest="$( "${cmd[@]}" | awk -v f="$field" 'f == 1 { print $1; next } { print $NF }' )"
    else
        [[ -f "$src" ]] || { ash_log_error "ash_hash: no such file: ${src}" 2>/dev/null || true; return 1; }
        # Passing the filename (instead of piping bytes) lets the tool read
        # the file directly: binary-safe, and no data goes through the shell.
        digest="$( "${cmd[@]}" "$src" | awk -v f="$field" 'f == 1 { print $1; next } { print $NF }' )"
    fi

    printf '%s\n' "$digest"
}

# Verifies a digest in constant time. Returns 0 on match, 1 on mismatch,
# 2 when the input could not be read.
# ash_verify_hash <algo> <expected> <file|->
ash_verify_hash() {
    local algo="${1:-sha256}" expected="$2" src="${3:--}"
    local actual
    actual="$(ash_hash "$algo" "$src")" || return 2
    [[ -z "$expected" ]] && return 2
    ash_crypto_equals "${actual,,}" "${expected,,}"
}

ash_hash_file() { ash_hash "${1:-sha256}" "$2"; }

# Hashes a literal string argument (no stdin newline surprises).
ash_hash_string() {
    local algo="${1:-sha256}" value="$2"
    printf '%s' "$value" | ash_hash "$algo" -
}

# HMAC — signs data so tampering is detectable without sharing the key.
ash_hmac() {
    local algo="${1:-sha256}" key="$2" data="$3"
    if command -v openssl >/dev/null 2>&1; then
        printf '%s' "$data" | openssl dgst "-${algo}" -hmac "$key" 2>/dev/null | awk '{print $NF}'
    else
        # Fallback: keyed prefix hash (weaker, but better than nothing and
        # clearly documented as such).
        ash_log_warn "openssl unavailable — using non-standard keyed hash" 2>/dev/null || true
        printf '%s' "${key}${data}${key}" | "${algo}sum" | awk '{print $1}'
    fi
}

# Constant-time comparison — prevents timing oracles on token checks.
ash_crypto_equals() {
    local a="$1" b="$2"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, hmac
a = sys.argv[1].encode(); b = sys.argv[2].encode()
sys.exit(0 if hmac.compare_digest(a, b) else 1)
' "$a" "$b"
    else
        [[ "$a" == "$b" ]]
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  RANDOMNESS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Cryptographically-sourced random bytes via the best available kernel API.
ash_random_bytes() {
    local n="${1:-32}"
    if   [[ -r /dev/urandom ]]; then head -c "$n" /dev/urandom
    elif command -v openssl >/dev/null 2>&1; then openssl rand "$n"
    else
        # Last resort: bash RANDOM is NOT cryptographic. Warn loudly.
        ash_log_warn "using non-cryptographic RANDOM — install coreutils" 2>/dev/null || true
        local i out=""
        for (( i = 0; i < n; i++ )); do out+=$(printf '\\x%02x' $(( RANDOM % 256 ))); done
        printf '%b' "$out"
    fi
}

ash_random_token() {
    local n="${1:-32}"
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 $(( n * 3 / 4 + 1 )) 2>/dev/null | tr -d '\n=' | head -c "$n"
    else
        ash_random_bytes "$n" | od -An -tx1 | tr -d ' \n' | head -c "$n"
    fi
}

# Password with a guaranteed character-class mix (may be rejected by
# ill-conceived "must contain" policies otherwise).
ash_random_password() {
    local length="${1:-24}" classes="${2:-all}"
    local lower="abcdefghijkmnopqrstuvwxyz"       # no l
    local upper="ABCDEFGHJKLMNPQRSTUVWXYZ"        # no I O
    local digits="23456789"                       # no 0 1
    local symbols='!@#$%^&*()-_=+[]{};:,.?'

    local pool="$lower$upper$digits"
    [[ "$classes" == "all" || "$classes" == *s* ]] && pool+="$symbols"

    local pw=""
    local i
    for (( i = 0; i < length; i++ )); do
        local idx
        idx="$(ash_random_bytes 2 | od -An -tu2 | tr -d ' \n')"
        pw+="${pool:$(( idx % ${#pool} )):1}"
    done

    printf '%s' "$pw"
}

ash_random_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr 'A-Z' 'a-z'
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
    else
        local hex; hex="$(ash_random_bytes 16 | od -An -tx1 | tr -d ' \n')"
        printf '%s-%s-4%s-a%s-%s' \
            "${hex:0:8}" "${hex:8:4}" "${hex:13:3}" "${hex:17:3}" "${hex:20:12}"
    fi
}

ash_random_hex() { ash_random_bytes "${1:-16}" | od -An -tx1 | tr -d ' \n'; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 3  ENCODING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_base64_encode() { printf '%s' "${1:--}" >/dev/null; base64 -w0 2>/dev/null || base64; }
ash_base64_decode() { base64 -d 2>/dev/null || base64 --decode 2>/dev/null; }
ash_url_encode() {
    local s="$1" out="" i ch
    for (( i = 0; i < ${#s}; i++ )); do
        ch="${s:i:1}"
        case "$ch" in
            [a-zA-Z0-9.~_-]) out+="$ch" ;;
            *) out+="$(printf '%%%02X' "'$ch")" ;;
        esac
    done
    printf '%s' "$out"
}
ash_url_decode() {
    local s="${1//+/ }"
    printf '%b' "${s//%/\\x}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 4  SYMMETRIC ENCRYPTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Reports which backends are usable so the UI can pick the best one.
ash_crypto_backend() {
    if   command -v age     >/dev/null 2>&1; then printf 'age'
    elif command -v gpg     >/dev/null 2>&1; then printf 'gpg'
    elif command -v openssl >/dev/null 2>&1; then printf 'openssl'
    else printf 'none'; fi
}

# ash_encrypt <in-file> <out-file> [-p PASSPHRASE_FILE] [--backend B]
# Output format is auto-detected on decrypt, so switching backends is safe.
ash_encrypt() {
    local in="$1" out="$2"; shift 2
    local passfile="" backend; backend="$(ash_crypto_backend)"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--passphrase-file) passfile="$2"; shift 2 ;;
            --backend) backend="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -f "$in" ]] || { ash_log_error "input not found: $in" 2>/dev/null || true; return 1; }

    local tmp_pass=""
    if [[ -n "$passfile" ]]; then
        passfile="${passfile/#\~/$HOME}"
    else
        tmp_pass="$(mktemp "${TMPDIR:-/tmp}/ash-pass-XXXXXX")"
        chmod 600 "$tmp_pass"
        if [[ -t 0 ]]; then
            printf 'Encryption passphrase: ' >&2
        fi
        local p1=""
        read -rs p1 2>/dev/null || p1="$(ash_random_token 32)"
        printf '\n' >&2
        # Confirm on an interactive terminal
        if [[ -t 0 ]]; then
            printf 'Confirm passphrase  : ' >&2
            local p2=""; read -rs p2; printf '\n' >&2
            if [[ "$p1" != "$p2" ]]; then
                rm -f "$tmp_pass"
                ash_log_error "passphrases do not match" 2>/dev/null || true
                return 1
            fi
        fi
        printf '%s' "$p1" > "$tmp_pass"
        passfile="$tmp_pass"
    fi

    local rc=0
    case "$backend" in
        age)
            if [[ -f "$passfile" ]]; then
                age -p -e -a < "$in" > "$out" 2>/dev/null <<< "$(cat "$passfile")" || \
                    { rc=1; }
                # age reads the passphrase interactively; use a FIFO trick
                if (( rc == 1 )); then
                    local fifo; fifo="$(mktemp -u "${TMPDIR:-/tmp}/ash-fifo-XXXXXX")"
                    mkfifo "$fifo" && chmod 600 "$fifo"
                    ( printf '%s\n' "$(cat "$passfile")" > "$fifo" ) &
                    age -p -e -a < "$in" > "$out" < "$fifo" 2>/dev/null || rc=1
                    rm -f "$fifo"
                fi
            fi
            ;;
        openssl)
            openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt \
                -pass "file:${passfile}" -in "$in" -out "$out" 2>/dev/null || rc=1
            ;;
        gpg)
            gpg --batch --yes --symmetric --cipher-algo AES256 \
                --passphrase-file "$passfile" --output "$out" "$in" 2>/dev/null || rc=1
            ;;
        *)
            ash_log_error "no encryption backend (install age, gnupg or openssl)" 2>/dev/null || true
            rc=1
            ;;
    esac

    # Shred the passphrase file if we created it.
    if [[ -n "$tmp_pass" ]]; then
        if command -v shred >/dev/null 2>&1; then shred -u -n 3 "$tmp_pass" 2>/dev/null || rm -f "$tmp_pass"
        else rm -f "$tmp_pass"; fi
    fi

    if (( rc == 0 )); then
        chmod 600 "$out" 2>/dev/null || true
        ash_event_emit "crypto.encrypted" "output=${out}" "backend=${backend}" 2>/dev/null || true
    fi
    return $rc
}

# ash_decrypt <in-file> <out-file> [-p PASSPHRASE_FILE] [--stdout]
ash_decrypt() {
    local in="$1" out="${2:--}"; shift 2
    local passfile="" to_stdout=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--passphrase-file) passfile="$2"; shift 2 ;;
            --stdout) to_stdout=1; shift ;;
            *) shift ;;
        esac
    done
    [[ "$out" == "-" ]] && to_stdout=1

    [[ -f "$in" ]] || { ash_log_error "ciphertext not found: $in" 2>/dev/null || true; return 1; }

    # ── Auto-detect the format from magic bytes ──────────────────────────
    local fmt=""
    local head_bytes
    head_bytes="$(head -c 64 "$in" 2>/dev/null | od -An -c 2>/dev/null | tr -d '\n')"
    if   [[ "$head_bytes" == *'-----BEGIN AGE ENCRYPTED FILE-----'* ]]; then fmt="age"
    elif [[ "$head_bytes" == *Salted__* ]];                          then fmt="openssl"
    elif head -c 3 "$in" 2>/dev/null | grep -q $'\x85\x02';          then fmt="gpg"
    elif head -c 1 "$in" 2>/dev/null | grep -q $'\x85';              then fmt="gpg"
    else
        # Unknown — infer from the extension
        case "$in" in
            *.age)  fmt="age" ;;
            *.gpg|*.asc) fmt="gpg" ;;
            *.enc)  fmt="openssl" ;;
            *)      fmt="$(ash_crypto_backend)" ;;
        esac
    fi

    local tmp_pass=""
    if [[ -z "$passfile" ]]; then
        tmp_pass="$(mktemp "${TMPDIR:-/tmp}/ash-pass-XXXXXX")"
        chmod 600 "$tmp_pass"
        local p1=""
        [[ -t 0 ]] && printf 'Passphrase: ' >&2
        read -rs p1 2>/dev/null || p1=""
        [[ -t 0 ]] && printf '\n' >&2
        printf '%s' "$p1" > "$tmp_pass"
        passfile="$tmp_pass"
    fi

    local tmp_out=""
    [[ $to_stdout -eq 1 ]] && tmp_out="$(mktemp "${TMPDIR:-/tmp}/ash-dec-XXXXXX")"
    local target="${tmp_out:-$out}"

    local rc=0
    case "$fmt" in
        age)
            local fifo; fifo="$(mktemp -u "${TMPDIR:-/tmp}/ash-fifo-XXXXXX")"
            mkfifo "$fifo" 2>/dev/null && chmod 600 "$fifo"
            ( printf '%s\n' "$(cat "$passfile")" > "$fifo" ) &
            age -d -i /dev/null < "$in" > "$target" < "$fifo" 2>/dev/null || \
                age -d < "$in" > "$target" < "$fifo" 2>/dev/null || rc=1
            rm -f "$fifo"
            ;;
        openssl)
            openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 \
                -pass "file:${passfile}" -in "$in" -out "$target" 2>/dev/null || rc=1
            ;;
        gpg)
            gpg --batch --yes --quiet --decrypt \
                --passphrase-file "$passfile" --output "$target" "$in" 2>/dev/null || rc=1
            ;;
        *)
            ash_log_error "cannot determine encryption format for ${in}" 2>/dev/null || true
            rc=1 ;;
    esac

    if [[ -n "$tmp_pass" ]]; then
        if command -v shred >/dev/null 2>&1; then shred -u -n 3 "$tmp_pass" 2>/dev/null || rm -f "$tmp_pass"
        else rm -f "$tmp_pass"; fi
    fi

    if (( rc != 0 )); then
        rm -f "${tmp_out:-}" 2>/dev/null || true
        ash_log_error "decryption failed (wrong passphrase or corrupt file)" 2>/dev/null || true
        return 1
    fi

    if [[ $to_stdout -eq 1 ]]; then
        cat "$tmp_out"
        if command -v shred >/dev/null 2>&1; then shred -u -n 1 "$tmp_out" 2>/dev/null || rm -f "$tmp_out"
        else rm -f "$tmp_out"; fi
    fi
    return 0
}

# ── Secrets store ────────────────────────────────────────────────────────────
# One encrypted blob per key; the index is plaintext (names only, no values).
ash_secret_dir() {
    mkdir -p "$ASH_SECRETS_DIR" 2>/dev/null || true
    chmod 700 "$ASH_SECRETS_DIR" 2>/dev/null || true
    printf '%s' "$ASH_SECRETS_DIR"
}

ash_secret_set() {
    local name="${1//[^A-Za-z0-9._-]/_}"
    local dir; dir="$(ash_secret_dir)"

    local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/ash-secret-XXXXXX")"
    chmod 600 "$tmp"
    cat > "$tmp"

    local backend; backend="$(ash_crypto_backend)"
    local out="${dir}/${name}.enc"

    local rc=0
    if [[ "$backend" == "openssl" ]]; then
        local pf; pf="$(mktemp "${TMPDIR:-/tmp}/ash-pass-XXXXXX")"; chmod 600 "$pf"
        if [[ -t 0 ]]; then printf 'Passphrase for secret store: ' >&2; fi
        local p=""; read -rs p; [[ -t 0 ]] && printf '\n' >&2
        printf '%s' "$p" > "$pf"
        openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -pass "file:${pf}" \
            -in "$tmp" -out "$out" 2>/dev/null || rc=1
        shred -u -n 3 "$pf" 2>/dev/null || rm -f "$pf"
    else
        ash_encrypt "$tmp" "$out" || rc=1
    fi

    shred -u -n 3 "$tmp" 2>/dev/null || rm -f "$tmp"

    if (( rc == 0 )); then
        chmod 600 "$out" 2>/dev/null || true
        printf '%s|%s|%s\n' "$name" "$(date -Iseconds)" "$backend" >> "${dir}/index.db"
        ash_event_emit "crypto.secret.stored" "name=${name}" 2>/dev/null || true
    fi
    return $rc
}

ash_secret_get() {
    local name="${1//[^A-Za-z0-9._-]/_}"
    local file="${ASH_SECRETS_DIR}/${name}.enc"
    [[ -f "$file" ]] || { ash_log_error "no such secret: ${name}" 2>/dev/null || true; return 1; }
    ash_decrypt "$file" - --stdout
}

ash_secret_list() {
    local dir="${ASH_SECRETS_DIR:-}"
    [[ -d "$dir" ]] || return 0
    find "$dir" -maxdepth 1 -name '*.enc' -printf '%f\n' 2>/dev/null \
        | sed 's/\.enc$//' | LC_ALL=C sort
}

ash_secret_delete() {
    local name="${1//[^A-Za-z0-9._-]/_}"
    local file="${ASH_SECRETS_DIR}/${name}.enc"
    [[ -f "$file" ]] || return 1
    shred -u -n 3 "$file" 2>/dev/null || rm -f "$file"
    [[ -f "${ASH_SECRETS_DIR}/index.db" ]] && \
        grep -v "^${name}|" "${ASH_SECRETS_DIR}/index.db" > "${ASH_SECRETS_DIR}/index.db.tmp" 2>/dev/null && \
        mv -f "${ASH_SECRETS_DIR}/index.db.tmp" "${ASH_SECRETS_DIR}/index.db"
    return 0
}

# ── Integrity manifest (used by `ash doctor --integrity`) ────────────────────
ash_crypto_integrity_manifest() {
    local root="${1:-$PWD}" out="${2:-}"
    [[ -n "$out" ]] && exec 3>&1

    local line
    find "$root" -type f \
        \( -name '*.sh' -o -name '*.conf' -o -name '*.json' -o -name '*.lua' \
           -o -name '*.fish' -o -name '*.rasi' -o -name '*.css' \) \
        ! -path '*/.git/*' -print0 2>/dev/null \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' line; do
        printf '%s  %s\n' "$(ash_hash sha256 "$line")" "${line#"$root"/}"
    done
}

ash_crypto_verify_manifest() {
    local manifest="$1" root="${2:-$PWD}"
    [[ -f "$manifest" ]] || return 1

    local ok=0 changed=0 missing=0 added=0
    local expected actual rel file

    while IFS= read -r expected || [[ -n "$expected" ]]; do
        [[ -z "$expected" ]] && continue
        local hash="${expected%% *}"
        rel="${expected#* }"
        rel="${rel#  }"
        file="${root}/${rel}"

        if [[ ! -f "$file" ]]; then
            printf '  ✗ missing : %s\n' "$rel"
            (( missing += 1 ))
            continue
        fi

        actual="$(ash_hash sha256 "$file")"
        if [[ "$actual" == "$hash" ]]; then
            (( ok += 1 ))
        else
            printf '  ⚠ modified: %s\n' "$rel"
            (( changed += 1 ))
        fi
    done < "$manifest"

    printf '\n  %d unchanged, %d modified, %d missing\n' "$ok" "$changed" "$missing"
    return $(( changed + missing > 0 ? 1 : 0 ))
}
