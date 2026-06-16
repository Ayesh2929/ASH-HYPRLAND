#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔑 ASH DOTFILES v5.0 OMEGA — SECRET DETECTION ENGINE                      ║
# ║  Multi-layer secret scanning: patterns · entropy · signatures · allowlist  ║
# ║  Protects against: API keys · tokens · private keys · passwords · seeds    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI PALETTE ──────────────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m"  readonly B="${ESC}[1m"  readonly D="${ESC}[2m"
readonly RED="${ESC}[31m"           readonly GREEN="${ESC}[32m"
readonly YELLOW="${ESC}[33m"        readonly CYAN="${ESC}[36m"
readonly WHITE="${ESC}[37m"         readonly ORANGE="${ESC}[38;5;208m"
readonly GOLD="${ESC}[38;5;220m"    readonly LAVENDER="${ESC}[38;5;183m"
readonly MINT="${ESC}[38;5;121m"    readonly PEACH="${ESC}[38;5;217m"
readonly LIME="${ESC}[38;5;154m"    readonly TEAL="${ESC}[38;5;43m"
readonly CORAL="${ESC}[38;5;203m"   readonly CREAM="${ESC}[38;5;230m"
readonly SLATE="${ESC}[38;5;245m"   readonly AMBER="${ESC}[38;5;214m"
readonly CRIMSON="${ESC}[38;5;161m" readonly VIOLET="${ESC}[38;5;177m"
readonly ROSE="${ESC}[38;5;211m"    readonly INDIGO="${ESC}[38;5;105m"
readonly BG_MIDNIGHT="${ESC}[48;5;16m"
readonly BG_RED="${ESC}[48;5;88m"
readonly BG_DARK="${ESC}[48;5;235m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="check-secrets"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-secrets"
readonly LOG_FILE="${LOG_DIR}/scan-$(date +%s).log"
readonly ALLOWLIST_FILE="${REPO_ROOT}/.ash-secrets-allowlist"
readonly ENTROPY_THRESHOLD=4.2      # Shannon entropy threshold
readonly MAX_SCAN_FILE_SIZE_MB=10   # Skip files larger than this
readonly PARALLEL_JOBS=4

# ── STATE ─────────────────────────────────────────────────────────────────────
declare -A FINDINGS=()       # path:line → finding detail
declare -A ALLOWED=()        # allowlisted finding hashes
TOTAL_FILES_SCANNED=0
TOTAL_LINES_SCANNED=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
SCAN_START_MS="$(date +%s%3N)"

# ── INIT ──────────────────────────────────────────────────────────────────────
init() {
    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    # Load allowlist
    if [[ -f "$ALLOWLIST_FILE" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            ALLOWED["$line"]=1
        done < "$ALLOWLIST_FILE"
    fi
}

now_ms()     { date +%s%3N; }
elapsed_ms() { echo $(( $(now_ms) - SCAN_START_MS )); }
format_dur() {
    local ms="$1"
    [[ $ms -lt 1000 ]] && printf "%dms" "$ms" || \
        printf "%.1fs" "$(echo "scale=1; $ms/1000" | bc 2>/dev/null || echo "$((ms/1000))")"
}

# ── RENDERING ─────────────────────────────────────────────────────────────────
hr() { printf "%s%s%s\n" "${1:-$D$SLATE}" \
    "$(printf '%*s' "${2:-$TERM_WIDTH}" '' | tr ' ' "${3:-─}")" "$R" >&2; }
box_t()  { printf "%s%s  ╔%s╗  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_d()  { printf "%s%s  ╠%s╣  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_td() { printf "%s%s  ╟%s╢  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '─')" "$R" >&2; }
box_b()  { printf "%s%s  ╚%s╝  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_l()  {
    local c="$1"; local cl; cl="$(echo "$c" | sed 's/\x1b\[[0-9;]*m//g')"
    local p=$(( TERM_WIDTH-4-${#cl} )); [[ $p -lt 0 ]] && p=0
    printf "%s  ║ %s%*s║  %s\n" "$BG_MIDNIGHT$GOLD" "$c" "$p" "" "$R" >&2; }

section() {
    printf "\n" >&2; hr "${D}${SLATE}"
    printf "  %s %s%s%s\n" "$1" "${3:-$CYAN}${B}" "$2" "$R" >&2
    hr "${D}${SLATE}"
}

finding() {
    local severity="$1"  # CRITICAL|HIGH|MEDIUM|LOW
    local rule="$2"
    local file="$3"
    local line_num="$4"
    local match="$5"
    local description="$6"

    # Compute finding hash for allowlist
    local hash; hash="$(echo "${file}:${line_num}:${rule}" | \
        md5sum 2>/dev/null | cut -d' ' -f1 || \
        echo "${file}_${line_num}_${rule}")"

    # Check allowlist
    if [[ -n "${ALLOWED[$hash]:-}" ]]; then
        printf "  %s↷%s %s%-56s%s %sALLOWLISTED%s\n" \
            "${SLATE}${D}" "$R" "${D}" \
            "${file}:${line_num}" \
            "$R" "${D}${SLATE}" "$R" >&2
        return 0
    fi

    # Redact the match for display
    local redacted="${match:0:8}$(printf '%*s' $(( ${#match} - 8 > 0 ? ${#match} - 8 : 0 )) '' | tr ' ' '*')"
    [[ ${#match} -le 8 ]] && redacted="$(printf '%*s' "${#match}" '' | tr ' ' '*')"

    local sev_color sev_icon
    case "$severity" in
        CRITICAL) sev_color="${CRIMSON}${B}"; sev_icon="🚨"; ((CRITICAL_COUNT++)) || true ;;
        HIGH)     sev_color="${RED}${B}";     sev_icon="🔴"; ((HIGH_COUNT++))     || true ;;
        MEDIUM)   sev_color="${ORANGE}${B}";  sev_icon="🟠"; ((MEDIUM_COUNT++))   || true ;;
        LOW)      sev_color="${YELLOW}${B}";  sev_icon="🟡"; ((LOW_COUNT++))      || true ;;
    esac

    # Store finding
    FINDINGS["${file}:${line_num}"]="${severity}|${rule}|${description}"

    # Display finding
    printf "\n" >&2
    printf "  %s┌─ %s %s%s%s ─────────────────────────────────%s\n" \
        "${sev_color}" "$sev_icon" "$severity" "$R${sev_color}" \
        "  ${rule}" "$R" >&2
    printf "  %s│%s  %s%s:%s%s%s %s%s%s\n" \
        "${sev_color}" "$R" \
        "${D}${SLATE}" "$file" "$R" "${D}${WHITE}" "line ${line_num}" \
        "" "" "$R" >&2
    printf "  %s│%s  %s%s%s\n" \
        "${sev_color}" "$R" "${D}${CREAM}" "$description" "$R" >&2
    printf "  %s│%s  %sMatch%s: %s%s%s\n" \
        "${sev_color}" "$R" "${D}" "$R" "${sev_color}" "$redacted" "$R" >&2
    printf "  %s│%s  %sHash%s:  %s%s%s\n" \
        "${sev_color}" "$R" "${D}" "$R" "${SLATE}${D}" "$hash" "$R" >&2
    printf "  %s└──────────────────────────────────────────────────────%s\n" \
        "${sev_color}" "$R" >&2

    # Log to file
    printf "[%s] [%s] %s:%s — %s — %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$severity" "$file" "$line_num" \
        "$rule" "$description" >> "$LOG_FILE"
}

# ── FILE FILTER ────────────────────────────────────────────────────────────────
should_scan_file() {
    local file="$1"

    # Skip binary files
    if file "$file" 2>/dev/null | grep -qiE "(binary|image|audio|video|archive|compressed)"; then
        return 1
    fi

    # Skip files that are too large
    local size_mb
    size_mb="$(du -m "$file" 2>/dev/null | cut -f1 || echo 0)"
    if [[ $size_mb -gt $MAX_SCAN_FILE_SIZE_MB ]]; then
        return 1
    fi

    # Skip encrypted files (they should have secrets, that's fine)
    case "$file" in
        *.enc|*.gpg|*.asc|*.pgp) return 1 ;;
    esac

    # Skip generated files
    case "$file" in
        */node_modules/*|*/.git/*|*/vendor/*|*/dist/*|\
        */__pycache__/*|*/.cache/*|*/backups/*) return 1 ;;
    esac

    return 0
}

# ── PATTERN SCANNING ENGINE ───────────────────────────────────────────────────
scan_patterns() {
    local file="$1"
    local content_changed="${2:-}"  # Optional: only scan diff content

    # ── CRITICAL: Private Keys ────────────────────────────────────────────────
    local -A CRITICAL_RULES=(
        ["rsa_private_key"]='-----BEGIN RSA PRIVATE KEY-----'
        ["ec_private_key"]='-----BEGIN EC PRIVATE KEY-----'
        ["dsa_private_key"]='-----BEGIN DSA PRIVATE KEY-----'
        ["openssh_private_key"]='-----BEGIN OPENSSH PRIVATE KEY-----'
        ["pgp_private_key"]='-----BEGIN PGP PRIVATE KEY BLOCK-----'
        ["private_key_generic"]='-----BEGIN PRIVATE KEY-----'
        ["pkcs8_private_key"]='-----BEGIN ENCRYPTED PRIVATE KEY-----'
    )

    for rule in "${!CRITICAL_RULES[@]}"; do
        local pattern="${CRITICAL_RULES[$rule]}"
        while IFS=: read -r line_num match; do
            [[ -z "$match" ]] && continue
            finding "CRITICAL" "$rule" "$file" "$line_num" "$match" \
                "Private key material detected"
        done < <(grep -n "$pattern" "$file" 2>/dev/null || true)
    done

    # ── HIGH: Cloud Provider Keys ──────────────────────────────────────────────
    declare -A HIGH_RULES
    HIGH_RULES["aws_access_key"]='AKIA[0-9A-Z]{16}'
    HIGH_RULES["aws_secret_key"]='[Aa]ws.{0,20}[Ss]ecret.{0,10}[0-9a-zA-Z/+=]{40}'
    HIGH_RULES["gcp_service_account"]='\"type\":\s*\"service_account\"'
    HIGH_RULES["gcp_api_key"]='AIza[0-9A-Za-z\-_]{35}'
    HIGH_RULES["azure_subscription"]='[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
    HIGH_RULES["github_pat"]='gh[pousr]_[A-Za-z0-9]{36,255}'
    HIGH_RULES["github_oauth"]='gho_[0-9a-zA-Z]{36}'
    HIGH_RULES["github_refresh"]='ghr_[0-9a-zA-Z]{76}'
    HIGH_RULES["github_app_token"]='(ghs|ghu)_[0-9a-zA-Z]{36}'
    HIGH_RULES["gitlab_pat"]='glpat-[0-9a-zA-Z\-]{20}'
    HIGH_RULES["gitlab_ci_token"]='GR1348941[0-9a-zA-Z\-]{20}'
    HIGH_RULES["stripe_secret"]='sk_(test|live)_[0-9a-zA-Z]{24,}'
    HIGH_RULES["stripe_restricted"]='rk_(test|live)_[0-9a-zA-Z]{24,}'
    HIGH_RULES["paypal_secret"]='access_token\$production\$[0-9a-z]{16}\$[0-9a-f]{32}'
    HIGH_RULES["openai_key"]='sk-[a-zA-Z0-9]{48}'
    HIGH_RULES["anthropic_key"]='sk-ant-[a-zA-Z0-9\-_]{95}'
    HIGH_RULES["huggingface_token"]='hf_[a-zA-Z]{34}'
    HIGH_RULES["discord_bot_token"]='[MN][a-zA-Z0-9]{23}\.[a-zA-Z0-9\-_]{6}\.[a-zA-Z0-9\-_]{27}'
    HIGH_RULES["discord_webhook"]='https://discord(app)?\.com/api/webhooks/[0-9]+/[a-zA-Z0-9\-_]+'
    HIGH_RULES["slack_token"]='xox[baprs]-([0-9a-zA-Z]{10,48})'
    HIGH_RULES["slack_webhook"]='https://hooks\.slack\.com/services/T[a-zA-Z0-9]+/B[a-zA-Z0-9]+/[a-zA-Z0-9]+'
    HIGH_RULES["telegram_bot_token"]='[0-9]{8,10}:[a-zA-Z0-9\-_]{35}'
    HIGH_RULES["twilio_account_sid"]='AC[a-zA-Z0-9]{32}'
    HIGH_RULES["twilio_auth_token"]='SK[a-zA-Z0-9]{32}'
    HIGH_RULES["sendgrid_api_key"]='SG\.[a-zA-Z0-9\-_]{22}\.[a-zA-Z0-9\-_]{43}'
    HIGH_RULES["mailgun_api_key"]='key-[0-9a-zA-Z]{32}'
    HIGH_RULES["mailchimp_api_key"]='[0-9a-f]{32}-us[0-9]{1,2}'
    HIGH_RULES["shopify_access_token"]='shpat_[a-fA-F0-9]{32}'
    HIGH_RULES["heroku_api_key"]='[hH]eroku.{0,25}[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'
    HIGH_RULES["npm_auth_token"]='npm_[A-Za-z0-9]{36}'
    HIGH_RULES["pypi_api_token"]='pypi-AgEIcHlwaS5vcmc[A-Za-z0-9\-_]{50,}'
    HIGH_RULES["docker_hub_pat"]='dckr_pat_[a-zA-Z0-9\-_]{27}'
    HIGH_RULES["cloudflare_api_key"]='[0-9a-f]{37}'
    HIGH_RULES["cloudflare_global_key"]='[A-Za-z0-9_-]{37}'
    HIGH_RULES["digitalocean_pat"]='dop_v1_[a-f0-9]{64}'
    HIGH_RULES["linode_api_key"]='[0-9a-f]{64}'
    HIGH_RULES["vultr_api_key"]='[A-Z0-9]{36}'

    for rule in "${!HIGH_RULES[@]}"; do
        local pattern="${HIGH_RULES[$rule]}"
        while IFS= read -r match_line; do
            [[ -z "$match_line" ]] && continue
            local line_num; line_num="$(echo "$match_line" | cut -d: -f1)"
            local match_val; match_val="$(echo "$match_line" | cut -d: -f2-)"

            # False positive filters
            if echo "$match_val" | grep -qiE \
                '(example|sample|placeholder|your[-_]|<[A-Z_]+>|REPLACE|xxx|test|dummy|fake|secret_here|\$\{|\{\{|0000000000)'; then
                continue
            fi

            finding "HIGH" "$rule" "$file" "$line_num" "$match_val" \
                "Credential pattern: ${rule//_/ }"
        done < <(grep -noP "$pattern" "$file" 2>/dev/null || true)
    done

    # ── MEDIUM: Generic Secrets ────────────────────────────────────────────────
    local -a medium_patterns=(
        # Generic password assignments
        "password\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        "passwd\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        "secret\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "api_key\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "apikey\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "auth_token\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "access_token\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "private_key\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "jwt_secret\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "encryption_key\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "signing_key\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "consumer_secret\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        "client_secret\s*[:=]\s*['\"][^'\"]{16,}['\"]"
        # Database connection strings with passwords
        "postgresql://[^:]+:[^@]{4,}@"
        "mysql://[^:]+:[^@]{4,}@"
        "mongodb(\+srv)?://[^:]+:[^@]{4,}@"
        "redis://:[^@]{4,}@"
        "amqp://[^:]+:[^@]{4,}@"
        # JWT tokens (3-part base64)
        "eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+"
        # SSH config with password
        "StrictHostKeyChecking no"
        # Crypto wallet seeds
        "[a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+"
    )

    local line_num=0
    while IFS= read -r line; do
        ((line_num++)) || true
        for pattern in "${medium_patterns[@]}"; do
            local match
            match="$(echo "$line" | grep -oP "$pattern" 2>/dev/null | head -1 || true)"
            if [[ -n "$match" ]]; then
                # False positive filter
                if echo "$line" | grep -qiE \
                    '(#.*example|TODO|FIXME|your[-_]|<[A-Z_]+>|PLACEHOLDER|\$\{|\{\{|template|sample)'; then
                    continue
                fi
                finding "MEDIUM" "generic_secret" "$file" "$line_num" \
                    "$match" "Potential secret assignment detected"
                break
            fi
        done
        ((TOTAL_LINES_SCANNED++)) || true
    done < "$file"
}

# ── ENTROPY ANALYSIS ──────────────────────────────────────────────────────────
scan_entropy() {
    local file="$1"

    if ! command -v python3 &>/dev/null; then
        return 0
    fi

    python3 - "$file" "$ENTROPY_THRESHOLD" <<'PYEOF' 2>/dev/null | \
    while IFS='|' read -r line_num token entropy; do
        finding "MEDIUM" "high_entropy_string" "$file" "$line_num" \
            "$token" "High entropy string (${entropy} bits) — possible secret"
    done
import sys, math, re

def shannon_entropy(data):
    if not data:
        return 0
    freq = {}
    for c in data:
        freq[c] = freq.get(c, 0) + 1
    return -sum(f/len(data) * math.log2(f/len(data)) for f in freq.values())

filepath = sys.argv[1]
threshold = float(sys.argv[2])

# Patterns that indicate high-entropy strings are likely secrets
secret_context = re.compile(
    r'(key|token|secret|password|passwd|api|auth|credential|private|signing|encrypt)',
    re.IGNORECASE
)

# Skip known-safe high-entropy content
safe_patterns = re.compile(
    r'(hash|checksum|uuid|example|test|placeholder|template|comment|#)',
    re.IGNORECASE
)

# Character sets for secrets
B64_CHARS = set('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=')
HEX_CHARS  = set('0123456789abcdefABCDEF')

try:
    with open(filepath, 'r', errors='replace') as f:
        for line_num, line in enumerate(f, 1):
            # Only check lines with secret context
            if not secret_context.search(line):
                continue
            if safe_patterns.search(line[:line.find('=') + 20 if '=' in line else 0]):
                continue

            # Find quoted strings of sufficient length
            tokens = re.findall(r'["\047]([A-Za-z0-9+/=_\-]{20,})["\047]', line)
            for token in tokens:
                if len(token) < 20 or len(token) > 256:
                    continue
                # Must be mostly base64 or hex chars
                b64_ratio = sum(1 for c in token if c in B64_CHARS) / len(token)
                if b64_ratio < 0.9:
                    continue
                ent = shannon_entropy(token)
                if ent >= threshold:
                    # Additional false-positive filter
                    if any(word in token.lower() for word in
                           ['example', 'placeholder', 'aaaa', 'bbbb', '1234', 'test']):
                        continue
                    print(f"{line_num}|{token[:8]}...|{ent:.2f}")
except Exception:
    pass
PYEOF
}

# ── SCAN FILES ────────────────────────────────────────────────────────────────
scan_file() {
    local file="$1"

    should_scan_file "$file" || return 0

    ((TOTAL_FILES_SCANNED++)) || true

    scan_patterns "$file"
    scan_entropy  "$file"
}

# ── STAGED FILES SCAN ─────────────────────────────────────────────────────────
scan_staged() {
    section "🔍" "Scanning Staged Files" "$CYAN"

    local staged_files
    staged_files="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"

    if [[ -z "$staged_files" ]]; then
        printf "  %s↷%s No staged files to scan\n" "${SLATE}${D}" "$R" >&2
        return 0
    fi

    local file_count=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ -f "$file" ]] || continue
        ((file_count++)) || true

        # Progress indicator
        printf "  %s◌%s Scanning: %s%-50.50s%s\r" \
            "${CYAN}${D}" "$R" "${D}" "$file" "$R" >&2

        scan_file "$file"
    done <<< "$staged_files"

    printf "  %s%-60s%s\n" "${D}" "" "$R" >&2  # Clear progress line
    printf "  %s✓%s Scanned %s%d%s staged files\n" \
        "${GREEN}${B}" "$R" "${GOLD}${B}" "$file_count" "$R" >&2
}

# ── GIT HISTORY SCAN (optional deep scan) ─────────────────────────────────────
scan_recent_commits() {
    local depth="${1:-5}"
    section "📜" "Scanning Recent Commit History (${depth} commits)" "$AMBER"

    local range
    if git rev-parse --verify "HEAD~${depth}" &>/dev/null; then
        range="HEAD~${depth}..HEAD"
    else
        range="HEAD"
    fi

    # Get diff of recent commits
    local diff_file
    diff_file="$(mktemp)"

    git diff "${range}" 2>/dev/null | \
        grep '^+' | \
        grep -v '^+++' > "$diff_file" || true

    if [[ ! -s "$diff_file" ]]; then
        printf "  %s↷%s No diff content to scan\n" "${SLATE}${D}" "$R" >&2
        rm -f "$diff_file"
        return 0
    fi

    scan_file "$diff_file"
    rm -f "$diff_file"
}

# ── KNOWN SAFE PATTERNS (false positive reduction) ────────────────────────────
is_false_positive() {
    local context="$1"
    local match="$2"

    # Template variables
    echo "$match" | grep -qP '(\$\{|{{|<[A-Z_]+>|YOUR_|REPLACE_|EXAMPLE_|PLACEHOLDER)' \
        && return 0

    # Test/example context in surrounding code
    echo "$context" | grep -qiE \
        '(test|spec|example|sample|mock|stub|fake|dummy|fixture|placeholder|todo|fixme|template)' \
        && return 0

    # All-zero or all-same character (placeholder pattern)
    echo "$match" | grep -qP '^([0-9a-f])\1{15,}$' && return 0

    # Sequential (1234567890abcdef...)
    echo "$match" | grep -qP '^0123456789' && return 0

    # Known test values
    echo "$match" | grep -qiE \
        '(supersecret|changeme|password123|admin123|testtoken|dummykey|fakekey)' \
        && return 0

    return 1
}

# ── GITLEAKS INTEGRATION ──────────────────────────────────────────────────────
run_gitleaks() {
    if ! command -v gitleaks &>/dev/null; then
        return 0
    fi

    section "🔬" "Gitleaks Deep Scan" "$VIOLET"

    local gitleaks_config="${REPO_ROOT}/.gitleaks.toml"
    local gl_opts=(
        "detect"
        "--source=${REPO_ROOT}"
        "--no-banner"
        "--quiet"
        "--redact"
    )

    [[ -f "$gitleaks_config" ]] && gl_opts+=("--config=${gitleaks_config}")
    gl_opts+=("--log-opts=HEAD~5..HEAD")

    local output exit_code=0
    output="$(gitleaks "${gl_opts[@]}" 2>&1)" || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        printf "  %s🚨%s Gitleaks found additional issues:\n" "${CRIMSON}${B}" "$R" >&2
        echo "$output" | head -20 | while IFS= read -r line; do
            printf "     %s%s%s\n" "${D}${ROSE}" "$line" "$R" >&2
        done
        ((HIGH_COUNT++)) || true
    else
        printf "  %s✓%s Gitleaks: %sno secrets found%s\n" \
            "${GREEN}${B}" "$R" "${MINT}" "$R" >&2
    fi
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n" >&2
    box_t
    box_l "${B}${CRIMSON}  🔑 ASH SECRET DETECTION ENGINE v${SCRIPT_VERSION}${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  Multi-layer scanning: Patterns · Entropy · Signatures · AI${R}${BG_MIDNIGHT}${GOLD}"
    box_d
    box_l "$(printf "  %s%-18s%s %s%s rules%s" \
        "${CYAN}${B}" "Pattern Rules:" "$R$BG_MIDNIGHT$GOLD" \
        "${GOLD}${B}" "100+" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%.1f bits%s" \
        "${CYAN}${B}" "Entropy Threshold:" "$R$BG_MIDNIGHT$GOLD" \
        "${PEACH}" "$ENTROPY_THRESHOLD" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s rules%s" \
        "${CYAN}${B}" "Allowlist:" "$R$BG_MIDNIGHT$GOLD" \
        "${MINT}" "${#ALLOWED[@]}" "$R$BG_MIDNIGHT$GOLD")"
    box_b
    printf "\n" >&2
}

# ── ALLOWLIST MANAGEMENT ───────────────────────────────────────────────────────
show_allowlist_help() {
    printf "\n  %s%s💡 To allowlist a false positive:%s\n" "$B" "$CYAN" "$R" >&2
    printf "     %secho '<hash>' >> %s%s\n" \
        "${D}" "$ALLOWLIST_FILE" "$R" >&2
    printf "     %sor add a comment: %s# ash-secret-ignore%s\n\n" \
        "${D}" "${D}${SLATE}" "$R" >&2
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local dur; dur="$(format_dur "$(elapsed_ms)")"
    local total_findings=$(( CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT ))

    printf "\n" >&2
    box_t
    box_l "${B}${CRIMSON}  🔑 SECRET SCAN REPORT${R}${BG_MIDNIGHT}${GOLD}"
    box_d

    box_l "$(printf "  %s%-20s%s %s%d%s" \
        "${CYAN}${B}" "Files Scanned:" "$R$BG_MIDNIGHT$GOLD" \
        "${GOLD}${B}" "$TOTAL_FILES_SCANNED" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-20s%s %s%d%s" \
        "${CYAN}${B}" "Lines Scanned:" "$R$BG_MIDNIGHT$GOLD" \
        "${PEACH}" "$TOTAL_LINES_SCANNED" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-20s%s %s%s%s" \
        "${CYAN}${B}" "Duration:" "$R$BG_MIDNIGHT$GOLD" \
        "${MINT}" "$dur" "$R$BG_MIDNIGHT$GOLD")"
    box_td

    if [[ $total_findings -gt 0 ]]; then
        box_l "$(printf "  %s%d FINDING(S) DETECTED%s" \
            "${CRIMSON}${B}" "$total_findings" "$R$BG_MIDNIGHT$GOLD")"
        box_td

        [[ $CRITICAL_COUNT -gt 0 ]] && \
            box_l "  ${CRIMSON}${B}🚨 CRITICAL: ${CRITICAL_COUNT}${R}${BG_MIDNIGHT}${GOLD}"
        [[ $HIGH_COUNT -gt 0 ]] && \
            box_l "  ${RED}${B}🔴 HIGH:     ${HIGH_COUNT}${R}${BG_MIDNIGHT}${GOLD}"
        [[ $MEDIUM_COUNT -gt 0 ]] && \
            box_l "  ${ORANGE}${B}🟠 MEDIUM:   ${MEDIUM_COUNT}${R}${BG_MIDNIGHT}${GOLD}"
        [[ $LOW_COUNT -gt 0 ]] && \
            box_l "  ${YELLOW}🟡 LOW:      ${LOW_COUNT}${R}${BG_MIDNIGHT}${GOLD}"

        box_td
        box_l "  ${RED}${B}⚠️  PUSH BLOCKED — Secrets detected in staged files${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}Remove secrets, then re-stage and commit${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}Log: ${LOG_FILE}${R}${BG_MIDNIGHT}${GOLD}"
    else
        box_l "  ${GREEN}${B}✓ NO SECRETS DETECTED — All clear!${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}${TOTAL_FILES_SCANNED} files, ${TOTAL_LINES_SCANNED} lines scanned${R}${BG_MIDNIGHT}${GOLD}"
    fi

    box_b
    printf "\n" >&2
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    init
    print_banner

    # Parse mode
    local mode="${1:-staged}"
    case "$mode" in
        staged)  scan_staged ;;
        history) scan_recent_commits "${2:-10}" ;;
        file)    scan_file "${2:?'file path required'}" ;;
        all)
            scan_staged
            scan_recent_commits 5
            ;;
        *)
            echo "${RED}Unknown mode: $mode${R}" >&2
            echo "Usage: $0 [staged|history|file|all]" >&2
            exit 1
            ;;
    esac

    run_gitleaks

    print_summary

    local total=$(( CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT ))
    if [[ $total -gt 0 ]]; then
        show_allowlist_help
        exit 1
    fi

    exit 0
}

main "$@"