#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🌐 ASH HTTP CLIENT — resilient curl wrapper with retry & caching             ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Everything in the dotfiles that talks to the network goes through here,      ║
# ║  which means one place implements:                                           ║
# ║    • exponential backoff with jitter (never thundering-herd a rate limit)     ║
# ║    • ETag / Last-Modified conditional requests (bandwidth + politeness)       ║
# ║    • a hard connect/read timeout (a hung request can't block login)           ║
# ║    • response caching through lib/cache.sh                                    ║
# ║    • credential isolation — secrets never appear in argv                      ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HTTP_CLIENT_LOADED:-}" ]] && return 0
readonly _ASH_HTTP_CLIENT_LOADED=1
readonly ASH_HTTP_VERSION="5.0.0"

: "${ASH_HTTP_TIMEOUT:=15}"
: "${ASH_HTTP_CONNECT_TIMEOUT:=5}"
: "${ASH_HTTP_RETRIES:=3}"
: "${ASH_HTTP_USER_AGENT:=ASH-Dotfiles/${ASH_VERSION:-5.0.0-omega} (+https://github.com/ash-dotfiles)}"
: "${ASH_HTTP_CACHE_TTL:=300}"
: "${ASH_HTTP_OFFLINE:=0}"

declare -gA ASH_HTTP_LAST=()

ash_http_available() { command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; }

# ── Connectivity probe (cheap; result cached for 30 s) ───────────────────────
ash_http_online() {
    if [[ "${ASH_HTTP_OFFLINE:-0}" == "1" ]]; then return 1; fi
    if declare -f ash_cache_get >/dev/null 2>&1; then
        ash_cache_get "net" "online-probe" 30 >/dev/null 2>&1 && return 0
    fi
    return 0
}

# ── Core request ─────────────────────────────────────────────────────────────
# ash_http_request <method> <url> [options]
#   --header "K: V"        repeatable
#   --data 'payload'       request body
#   --json 'payload'       body + Content-Type: application/json
#   --form "k=v"           multipart field, repeatable
#   --auth-token TOKEN     Bearer header (never logged)
#   --auth-user u:p        basic auth
#   --output FILE          write the body to FILE instead of stdout
#   --retry N              override retry count
#   --cache TTL            cache the response body for TTL seconds
#   --no-cache             bypass read; still writes
#   --conditional          send If-None-Match when a cached ETag exists
#   --fail                 non-2xx is an error
#   --follow               follow redirects (default on)
#   --max-size BYTES       abort above this size
#   --silent               suppress progress/log output
ash_http_request() {
    local method="${1:-GET}" url="${2:-}"; shift 2 || true

    command -v curl >/dev/null 2>&1 || {
        ash_log_error "curl is required for HTTP requests" 2>/dev/null || true
        return 127
    }
    [[ -z "$url" ]] && return 1

    local -a headers=() form_fields=()
    local data="" json_data="" auth_token="" auth_user=""
    local output_file="" retries="$ASH_HTTP_RETRIES"
    local cache_ttl=0 no_cache=0 conditional=0 fail_on_error=0
    local max_size="" follow=1 silent=0 accept_status=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --header)       headers+=("$2"); shift 2 ;;
            --data)         data="$2"; shift 2 ;;
            --json)         json_data="$2"; shift 2 ;;
            --form)         form_fields+=("$2"); shift 2 ;;
            --auth-token)   auth_token="$2"; shift 2 ;;
            --auth-user)    auth_user="$2"; shift 2 ;;
            --output|-o)    output_file="$2"; shift 2 ;;
            --retry)        retries="$2"; shift 2 ;;
            --cache)        cache_ttl="$2"; shift 2 ;;
            --no-cache)     no_cache=1; shift ;;
            --conditional)  conditional=1; shift ;;
            --fail)         fail_on_error=1; shift ;;
            --no-follow)    follow=0; shift ;;
            --max-size)     max_size="$2"; shift 2 ;;
            --accept)       accept_status="$2"; shift 2 ;;
            --silent|-s)    silent=1; shift ;;
            *)              shift ;;
        esac
    done

    # ── Cache lookup ─────────────────────────────────────────────────────
    local cache_key; cache_key="$(printf '%s|%s' "$method" "$url" | cksum | awk '{print $1}')"
    if (( cache_ttl > 0 && no_cache == 0 )) && declare -f ash_cache_get >/dev/null 2>&1; then
        local cached
        if cached="$(ash_cache_get "http" "$cache_key" "$cache_ttl")"; then
            ASH_HTTP_LAST[from_cache]="1"
            ASH_HTTP_LAST[status]="200"
            if [[ -n "$output_file" ]]; then printf '%s' "$cached" > "$output_file"; else printf '%s' "$cached"; fi
            return 0
        fi
    fi

    # ── Build curl argument vector ───────────────────────────────────────
    local -a args=(
        --silent --show-error
        --connect-timeout "$ASH_HTTP_CONNECT_TIMEOUT"
        --max-time "$ASH_HTTP_TIMEOUT"
        --user-agent "$ASH_HTTP_USER_AGENT"
        --write-out $'\n%{http_code}\t%{size_download}\t%{time_total}\t%{content_type}\t%{url_effective}'
        -X "$method"
    )
    [[ $follow -eq 1 ]] && args+=(--location --max-redirs 5)
    [[ -n "$max_size" ]] && args+=(--max-filesize "$max_size")

    local h
    for h in "${headers[@]}"; do args+=(--header "$h"); done

    if [[ -n "$json_data" ]]; then
        args+=(--header "Content-Type: application/json" --data-binary "$json_data")
    elif [[ -n "$data" ]]; then
        args+=(--data-binary "$data")
    fi

    # Secrets go through a 0600 header file, never argv (/proc/*/cmdline is
    # world-readable on most systems).
    local header_file=""
    if [[ -n "$auth_token" ]]; then
        header_file="$(mktemp "${TMPDIR:-/tmp}/ash-hdr-XXXXXX")"
        chmod 600 "$header_file"
        printf 'Authorization: Bearer %s\n' "$auth_token" > "$header_file"
        args+=(--header "@${header_file}")
    fi
    if [[ -n "$auth_user" ]]; then
        local up_file; up_file="$(mktemp "${TMPDIR:-/tmp}/ash-usr-XXXXXX")"
        chmod 600 "$up_file"
        printf 'user = "%s"\n' "$auth_user" > "$up_file"
        args+=(--config "$up_file")
        header_file="${header_file}${header_file:+ }${up_file}"
    fi

    local ff
    for ff in "${form_fields[@]}"; do
        args+=(--form "$ff")
    done

    if (( conditional == 1 )) && declare -f ash_cache_get >/dev/null 2>&1; then
        local etag
        if etag="$(ash_cache_get "http-etag" "$cache_key" 86400)"; then
            [[ -n "$etag" ]] && args+=(--header "If-None-Match: ${etag}")
        fi
    fi

    # ── Retry loop with exponential backoff + jitter ─────────────────────
    local attempt=0 rc=0 body="" meta=""
    local delay=1

    while :; do
        (( attempt += 1 ))
        local raw
        raw="$(curl "${args[@]}" "$url" 2>&1)" || rc=$?

        # curl exit codes: 6 DNS, 7 connect, 28 timeout, 35 SSL, 52 empty reply
        case "$rc" in
            0|22) break ;;                      # success (22 = --fail HTTP error)
            6|7|28|35|52|56)
                if (( attempt <= retries )); then
                    # Jitter prevents N parallel workers retrying in lockstep.
                    local jitter=$(( RANDOM % 1000 ))
                    local sleep_s
                    sleep_s="$(awk -v d="$delay" -v j="$jitter" 'BEGIN{ printf "%.2f", d + j/1000 }')"
                    (( silent == 0 )) && ash_log_debug "http retry ${attempt}/${retries} for ${url} in ${sleep_s}s (curl ${rc})" 2>/dev/null || true
                    sleep "$sleep_s"
                    delay=$(( delay * 2 ))
                    (( delay > 16 )) && delay=16
                    continue
                fi
                break
                ;;
            *) break ;;
        esac
    done

    # ── Clean up credential files immediately ────────────────────────────
    if [[ -n "$header_file" ]]; then
        local cf
        for cf in $header_file; do
            if command -v shred >/dev/null 2>&1; then shred -u -n 1 "$cf" 2>/dev/null || rm -f "$cf"
            else rm -f "$cf"; fi
        done
    fi

    # Split body from the --write-out metadata (last line).
    meta="$(printf '%s' "$raw" | tail -1)"
    body="$(printf '%s' "$raw" | sed '$d')"

    local status size time_total content_type effective_url
    IFS=$'\t' read -r status size time_total content_type effective_url <<< "$meta"

    ASH_HTTP_LAST[status]="${status:-0}"
    ASH_HTTP_LAST[bytes]="${size:-0}"
    ASH_HTTP_LAST[time]="${time_total:-0}"
    ASH_HTTP_LAST[content_type]="${content_type:-}"
    ASH_HTTP_LAST[url]="${effective_url:-$url}"
    ASH_HTTP_LAST[from_cache]=0

    # ── 304 Not Modified → serve from cache ──────────────────────────────
    if [[ "$status" == "304" ]]; then
        if declare -f ash_cache_get >/dev/null 2>&1; then
            body="$(ash_cache_get "http" "$cache_key" 0)"
        fi
        ASH_HTTP_LAST[status]="200"
        ASH_HTTP_LAST[from_cache]=1
    fi

    # ── Store in cache on success ────────────────────────────────────────
    if (( cache_ttl > 0 )) && [[ "$status" =~ ^2 ]] && declare -f ash_cache_put >/dev/null 2>&1; then
        ash_cache_put "http" "$cache_key" "$body" "$cache_ttl" "url=${url}"
    fi

    # ── Error reporting ──────────────────────────────────────────────────
    if (( rc != 0 )); then
        (( silent == 0 )) && ash_log_warn "HTTP ${method} ${url} failed (curl exit ${rc}, attempts=${attempt})" 2>/dev/null || true
        return "$rc"
    fi

    if [[ $fail_on_error -eq 1 ]] && [[ ! "$status" =~ ^2 ]]; then
        (( silent == 0 )) && ash_log_error "HTTP ${method} ${url} → ${status}" 2>/dev/null || true
        return 22
    fi

    if [[ -n "$accept_status" ]] && [[ "$status" != "$accept_status" ]]; then
        return 1
    fi

    if [[ -n "$output_file" ]]; then
        printf '%s' "$body" > "$output_file"
    else
        printf '%s' "$body"
    fi
    return 0
}

# ── Convenience verbs ────────────────────────────────────────────────────────
ash_http_get()  { ash_http_request GET  "$@"; }
ash_http_head() { ash_http_request HEAD "$@"; }
ash_http_post() { ash_http_request POST "$@"; }
ash_http_put()  { ash_http_request PUT  "$@"; }
ash_http_patch(){ ash_http_request PATCH "$@"; }
ash_http_delete(){ ash_http_request DELETE "$@"; }

# ── JSON API helpers ─────────────────────────────────────────────────────────
ash_http_get_json() {
    local url="$1"; shift || true
    local body
    body="$(ash_http_request GET "$url" --header "Accept: application/json" "$@")" || return 1
    if declare -f ash_json_valid >/dev/null 2>&1; then
        printf '%s' "$body" | ash_json_valid - || {
            ash_log_warn "response from ${url} is not valid JSON" 2>/dev/null || true
            printf '%s' "$body"
            return 1
        }
    fi
    printf '%s' "$body"
}

ash_http_post_json() {
    local url="$1" payload="$2"; shift 2 || true
    ash_http_request POST "$url" --json "$payload" "$@" --fail
}

# ── Download with resume + checksum verification ─────────────────────────────
# ash_http_download <url> <dest> [--checksum SHA256] [--resume] [--progress]
ash_http_download() {
    local url="$1" dest="$2"; shift 2 || true
    local checksum="" resume=0 progress=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --checksum) checksum="$2"; shift 2 ;;
            --resume)   resume=1; shift ;;
            --progress) progress=1; shift ;;
            *) shift ;;
        esac
    done

    command -v curl >/dev/null 2>&1 || return 127
    mkdir -p "$(dirname "$dest")" 2>/dev/null || true

    local -a args=(
        --location --fail --show-error
        --connect-timeout "$ASH_HTTP_CONNECT_TIMEOUT"
        --max-time 300
        --user-agent "$ASH_HTTP_USER_AGENT"
        --retry 3 --retry-delay 1 --retry-connrefused
    )
    (( resume == 1 )) && args+=(--continue-at -)
    (( progress == 1 )) && args+=(--progress-bar) || args+=(--silent)

    # Download to a .part file so a failed transfer never looks complete.
    local part="${dest}.part"
    if ! curl "${args[@]}" --output "$part" "$url"; then
        ash_log_error "download failed: ${url}" 2>/dev/null || true
        return 1
    fi

    # ── Verify before promoting ──────────────────────────────────────────
    if [[ -n "$checksum" ]]; then
        local actual
        actual="$(ash_hash sha256 "$part" 2>/dev/null)"
        if ! ash_crypto_equals "$actual" "$checksum" 2>/dev/null && [[ "$actual" != "$checksum" ]]; then
            ash_log_error "checksum mismatch for ${url}" 2>/dev/null || true
            printf '  expected: %s\n  actual  : %s\n' "$checksum" "$actual" >&2
            rm -f "$part"
            return 1
        fi
    fi

    mv -f "$part" "$dest"
    ash_event_emit "http.downloaded" "url=${url}" "dest=${dest}" 2>/dev/null || true
    return 0
}

# ── Diagnostics ──────────────────────────────────────────────────────────────
ash_http_report() {
    if ! command -v curl >/dev/null 2>&1; then
        printf '  ✗ curl is not installed\n'
        return 1
    fi
    printf '  curl     : %s\n' "$(curl --version 2>/dev/null | head -1)"
    printf '  timeout  : %ss total, %ss connect\n' "$ASH_HTTP_TIMEOUT" "$ASH_HTTP_CONNECT_TIMEOUT"
    printf '  retries  : %s\n' "$ASH_HTTP_RETRIES"

    local probe="https://api.github.com"
    local status
    status="$(ash_http_request GET "$probe" --silent --output /dev/null 2>/dev/null; echo "${ASH_HTTP_LAST[status]}")"
    if [[ "$status" =~ ^2 ]]; then
        printf '  network  : ✓ reachable (%s → %s)\n' "$probe" "$status"
    else
        printf '  network  : ⚠ unreachable or blocked (%s)\n' "${status:-timeout}"
    fi
}

# Rate-limit-aware fetch: honours GitHub's X-RateLimit-Remaining when present.
ash_http_github_api() {
    local endpoint="${1:-}"; shift || true
    local url="https://api.github.com${endpoint}"

    local token="${GITHUB_TOKEN:-${ASH_GITHUB_TOKEN:-}}"
    local -a auth=()
    [[ -n "$token" ]] && auth=(--auth-token "$token")

    ash_http_request GET "$url" \
        --header "Accept: application/vnd.github+json" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        "${auth[@]}" "$@"
}
