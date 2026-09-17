#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔌 ASH DOTFILES v5.0 OMEGA — PLUGIN VALIDATOR                             ║
# ║  Comprehensive plugin validation: schema · security · API · compatibility  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI PALETTE ──────────────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m";  readonly B="${ESC}[1m";  readonly D="${ESC}[2m"
readonly RED="${ESC}[31m";           readonly GREEN="${ESC}[32m"
readonly YELLOW="${ESC}[33m";        readonly BLUE="${ESC}[34m"
readonly CYAN="${ESC}[36m";          readonly WHITE="${ESC}[37m"
readonly ORANGE="${ESC}[38;5;208m";  readonly PURPLE="${ESC}[38;5;135m"
readonly GOLD="${ESC}[38;5;220m";    readonly LAVENDER="${ESC}[38;5;183m"
readonly MINT="${ESC}[38;5;121m";    readonly PEACH="${ESC}[38;5;217m"
readonly LIME="${ESC}[38;5;154m";    readonly TEAL="${ESC}[38;5;43m"
readonly CORAL="${ESC}[38;5;203m";   readonly CREAM="${ESC}[38;5;230m"
readonly SLATE="${ESC}[38;5;245m";   readonly AMBER="${ESC}[38;5;214m"
readonly EMERALD="${ESC}[38;5;120m"; readonly INDIGO="${ESC}[38;5;105m"
readonly CRIMSON="${ESC}[38;5;161m"; readonly VIOLET="${ESC}[38;5;177m"
readonly BG_MIDNIGHT="${ESC}[48;5;16m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly PLUGIN_SCHEMA="${REPO_ROOT}/plugins/schema/plugin-schema.json"
readonly TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-plugin-validate"
readonly LOG_FILE="${LOG_DIR}/validate-$(date +%s).log"

# Required plugin.json fields
readonly -a REQUIRED_PLUGIN_FIELDS=(
    "name"
    "version"
    "author"
    "description"
    "entry"
    "ash_version"
)

# Optional but validated fields
readonly -a OPTIONAL_PLUGIN_FIELDS=(
    "license"
    "homepage"
    "repository"
    "keywords"
    "permissions"
    "dependencies"
    "hooks"
    "config_schema"
    "icon"
    "screenshots"
)

# Valid permission declarations
readonly -a VALID_PERMISSIONS=(
    "filesystem.read"
    "filesystem.write"
    "filesystem.config"
    "network.http"
    "network.websocket"
    "system.exec"
    "system.notify"
    "system.audio"
    "system.display"
    "system.bluetooth"
    "system.power"
    "ash.theme"
    "ash.config"
    "ash.snapshot"
    "ash.wallpaper"
    "ash.mode"
    "hyprland.ipc"
    "hyprland.config"
    "wayland.clipboard"
    "dbus.session"
    "dbus.system"
)

# Dangerous patterns in plugin scripts
readonly -a DANGEROUS_PATTERNS=(
    'rm -rf /'
    'rm -rf ~'
    'mkfs\.'
    'dd if='
    'chmod -R 777 /'
    ':(){:|:&};:'        # Fork bomb
    '> /dev/sda'
    'curl.*\| bash'
    'wget.*\| bash'
    'curl.*\| sh'
    'wget.*\| sh'
    'eval.*curl'
    'eval.*wget'
    '\$\(curl'
    '\$\(wget'
    'nc -l.*-e'
    'ncat.*--exec'
    '/etc/passwd'
    '/etc/shadow'
    'sudo chmod'
    'sudo chown'
    'systemctl.*disable'
    'systemctl.*mask'
)

# Valid hook names
readonly -a VALID_HOOKS=(
    "pre_enable"    "post_enable"
    "pre_disable"   "post_disable"
    "pre_update"    "post_update"
    "on_theme_change"  "on_mode_change"
    "on_wallpaper_change" "on_snapshot"
    "on_startup"    "on_shutdown"
    "on_lock"       "on_unlock"
    "on_idle"       "on_active"
    "on_battery"    "on_ac_power"
)

# ── STATE ─────────────────────────────────────────────────────────────────────
ERRORS=()
WARNINGS=()
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0
CHECKS_SKIPPED=0
VALIDATION_SCORE=0
MAX_SCORE=0
PLUGIN_NAME=""
PLUGIN_VERSION=""
PLUGIN_PERMISSIONS=()
SECURITY_ISSUES=()

# ── INIT & RENDER ──────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

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
    printf "\n" >&2; hr "${D}${SLATE}"; \
    printf "  %s %s%s%s\n" "$1" "${2:-$CYAN}${B}" "$2" "$R" >&2
    # shellcheck disable=SC2086
    printf "  %s %s%s%s\n" "$1" "${3:-$CYAN}${B}" "$2" "$R" >&2
    hr "${D}${SLATE}"; }

section() {
    printf "\n" >&2
    hr "${D}${SLATE}"
    printf "  %s %s%s%s\n" "$1" "${3:-$CYAN}${B}" "$2" "$R" >&2
    hr "${D}${SLATE}"
}

check() {
    local name="$1" result="$2" detail="${3:-}" points="${4:-1}"
    local icon="$5"
    ((MAX_SCORE += points)) || true; ((CHECKS_TOTAL++)) || true

    local color label
    case "$result" in
        pass) ((CHECKS_PASSED++)) || true; ((VALIDATION_SCORE += points)) || true
              color="${GREEN}${B}"; label="✓ PASS" ;;
        fail) ((CHECKS_FAILED++)) || true
              color="${RED}${B}";   label="✗ FAIL"; ERRORS+=("${name}: ${detail}") ;;
        warn) ((CHECKS_WARNED++)) || true; ((VALIDATION_SCORE += points/2)) || true
              color="${YELLOW}${B}"; label="⚠ WARN"; WARNINGS+=("${name}: ${detail}") ;;
        skip) ((CHECKS_SKIPPED++)) || true
              color="${SLATE}${D}"; label="↷ SKIP" ;;
    esac

    local nm_w=50 det_max=$(( TERM_WIDTH - 70 ))
    [[ $det_max -lt 0 ]] && det_max=20
    local det_short="${detail:0:$det_max}"
    [[ ${#detail} -gt $det_max ]] && det_short="${det_short}…"

    printf "  %s  %s%-*s%s %s%-8s%s %s%s%s\n" \
        "${icon:-◆}" \
        "${B}${WHITE}" "$nm_w" "$name" "$R" \
        "${color}" "$label" "$R" \
        "${D}${SLATE}" "$det_short" "$R" >&2
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n" >&2; box_t
    box_l "${B}${INDIGO}  🔌 ASH PLUGIN VALIDATOR v${SCRIPT_VERSION}${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  Schema · Security · API Compatibility · Permission Audit${R}${BG_MIDNIGHT}${GOLD}"
    box_d
    box_l "$(printf "  %s%-16s%s %s%s%s" "${CYAN}${B}" "Plugin:" \
        "$R$BG_MIDNIGHT$GOLD" "${LAVENDER}" "${1:-unknown}" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-16s%s %s%s%s" "${CYAN}${B}" "Validator:" \
        "$R$BG_MIDNIGHT$GOLD" "${MINT}" "ASH Plugin Engine v${SCRIPT_VERSION}" "$R$BG_MIDNIGHT$GOLD")"
    box_b; printf "\n" >&2
}

# ── FILE STRUCTURE ─────────────────────────────────────────────────────────────
validate_structure() {
    section "📁" "Plugin Structure" "$CYAN"
    local plugin_dir="$1"

    [[ -d "$plugin_dir" ]] || { check "dir_exists" "fail" "not a directory" 5 "📁"; return 1; }
    check "dir_exists" "Plugin directory exists" "pass" "$plugin_dir" 5 "📁"

    # Required files
    local -a required=("plugin.json" "init.sh")
    for f in "${required[@]}"; do
        if [[ -f "${plugin_dir}/${f}" ]]; then
            check "file_${f}" "Required: $f" "pass" "present" 3 "📄"
        else
            check "file_${f}" "Required: $f" "fail" "missing (required)" 3 "📄"
        fi
    done

    # Optional files
    local -a optional=("README.md" "config.json" "enable.sh" "disable.sh" "status.sh" "update.sh")
    for f in "${optional[@]}"; do
        if [[ -f "${plugin_dir}/${f}" ]]; then
            check "file_opt_${f}" "Optional: $f" "pass" "present" 1 "📎"
        fi
    done

    # README.md strongly recommended
    if [[ ! -f "${plugin_dir}/README.md" ]]; then
        check "file_readme" "README.md" "warn" "missing (strongly recommended)" 2 "📖"
    fi

    # Check directory size
    local size_kb; size_kb="$(du -sk "$plugin_dir" 2>/dev/null | cut -f1 || echo 0)"
    if [[ $size_kb -gt 10240 ]]; then
        check "dir_size" "Plugin directory size" "warn" \
            "${size_kb}KB > 10MB (large plugin)" 2 "💾"
    else
        check "dir_size" "Plugin directory size" "pass" "${size_kb}KB" 2 "💾"
    fi
}

# ── PLUGIN.JSON ────────────────────────────────────────────────────────────────
validate_plugin_json() {
    section "📋" "plugin.json Validation" "$INDIGO"
    local plugin_json="$1"

    [[ -f "$plugin_json" ]] || { check "json_exists" "plugin.json exists" "fail" "not found" 5 "📋"; return 1; }

    # JSON syntax
    if command -v jq &>/dev/null; then
        if ! jq empty < "$plugin_json" &>/dev/null; then
            check "json_syntax" "JSON syntax" "fail" "invalid JSON" 10 "📋"
            return 1
        fi
        check "json_syntax" "JSON syntax" "pass" "valid" 10 "📋"
    fi

    # Required fields
    for field in "${REQUIRED_PLUGIN_FIELDS[@]}"; do
        local val
        val="$(jq -r --arg f "$field" '.[$f] // empty' "$plugin_json" 2>/dev/null || true)"
        if [[ -n "$val" ]] && [[ "$val" != "null" ]]; then
            check "field_${field}" "Field: $field" "pass" "\"${val:0:40}\"" 3 "✅"
            case "$field" in
                name)        PLUGIN_NAME="$val" ;;
                version)     PLUGIN_VERSION="$val" ;;
            esac
        else
            check "field_${field}" "Field: $field" "fail" "missing required field" 3 "❌"
        fi
    done

    # Version format
    if [[ -n "$PLUGIN_VERSION" ]]; then
        if echo "$PLUGIN_VERSION" | grep -qP '^\d+\.\d+\.\d+'; then
            check "version_fmt" "Version format (semver)" "pass" "$PLUGIN_VERSION" 2 "🏷️"
        else
            check "version_fmt" "Version format (semver)" "warn" \
                "'$PLUGIN_VERSION' not semver" 1 "🏷️"
        fi
    fi

    # ash_version compatibility
    local ash_ver
    ash_ver="$(jq -r '.ash_version // empty' "$plugin_json" 2>/dev/null || true)"
    if [[ -n "$ash_ver" ]]; then
        if echo "$ash_ver" | grep -qP '^(\^|~|>=|<=)?\d+\.\d+'; then
            check "ash_compat" "ASH version compatibility" "pass" \
                "requires: $ash_ver" 3 "⚙️"
        else
            check "ash_compat" "ASH version compatibility" "warn" \
                "unusual format: $ash_ver" 1 "⚙️"
        fi
    fi

    # Permissions audit
    validate_permissions "$plugin_json"

    # Hooks validation
    validate_hooks "$plugin_json"

    # Entry point validation
    local entry
    entry="$(jq -r '.entry // empty' "$plugin_json" 2>/dev/null || true)"
    if [[ -n "$entry" ]]; then
        local plugin_dir; plugin_dir="$(dirname "$plugin_json")"
        if [[ -f "${plugin_dir}/${entry}" ]]; then
            check "entry_exists" "Entry point exists" "pass" "$entry" 3 "🚪"
        else
            check "entry_exists" "Entry point exists" "fail" \
                "entry '$entry' not found in plugin directory" 3 "🚪"
        fi
    fi

    # License check
    local license
    license="$(jq -r '.license // empty' "$plugin_json" 2>/dev/null || true)"
    if [[ -n "$license" ]] && [[ "$license" != "null" ]]; then
        check "license" "License declared" "pass" "$license" 1 "⚖️"
    else
        check "license" "License declared" "warn" "no license (recommend MIT)" 1 "⚖️"
    fi
}

# ── PERMISSIONS AUDIT ──────────────────────────────────────────────────────────
validate_permissions() {
    section "🔐" "Permission Audit" "$CRIMSON"
    local plugin_json="$1"

    if ! command -v jq &>/dev/null; then
        check "permissions" "Permission audit" "skip" "jq required" 0 "🔐"
        return 0
    fi

    local perms
    perms="$(jq -r '.permissions // [] | .[]' "$plugin_json" 2>/dev/null || true)"

    if [[ -z "$perms" ]]; then
        check "perm_declared" "Permissions declared" "warn" \
            "no permissions declared (assume minimal)" 2 "🔐"
        return 0
    fi

    local perm_count=0
    local invalid_perms=()
    local dangerous_perms=()
    local high_risk_perms=()

    while IFS= read -r perm; do
        [[ -z "$perm" ]] && continue
        ((perm_count++)) || true
        PLUGIN_PERMISSIONS+=("$perm")

        # Validate permission is known
        local is_known=false
        for valid_perm in "${VALID_PERMISSIONS[@]}"; do
            [[ "$perm" == "$valid_perm" ]] && { is_known=true; break; }
        done

        if [[ "$is_known" != "true" ]]; then
            invalid_perms+=("$perm")
        fi

        # Flag high-risk permissions
        case "$perm" in
            system.exec|dbus.system|filesystem.write)
                high_risk_perms+=("$perm") ;;
        esac

        # Dangerous wildcard permissions
        if echo "$perm" | grep -q '\*'; then
            dangerous_perms+=("$perm")
        fi

        # Per-permission icon display
        local perm_icon perm_color
        case "$perm" in
            filesystem.*)  perm_icon="📁" perm_color="${AMBER}" ;;
            network.*)     perm_icon="🌐" perm_color="${CORAL}" ;;
            system.exec)   perm_icon="⚡" perm_color="${RED}${B}" ;;
            system.*)      perm_icon="⚙️"  perm_color="${ORANGE}" ;;
            ash.*)         perm_icon="🌊" perm_color="${CYAN}" ;;
            hyprland.*)    perm_icon="🖥️"  perm_color="${TEAL}" ;;
            dbus.system)   perm_icon="⚠️"  perm_color="${RED}${B}" ;;
            dbus.*)        perm_icon="🔌" perm_color="${YELLOW}" ;;
            *)             perm_icon="❓" perm_color="${SLATE}" ;;
        esac

        printf "  %s  %-56s%s%s%s\n" \
            "$perm_icon" "${perm_color}${perm}${R}" \
            "$([[ "${VALID_PERMISSIONS[*]}" == *"$perm"* ]] && \
               echo "${D}${GREEN}✓${R}" || echo "${D}${RED}✗ unknown${R}")" \
            "" "" >&2
    done <<< "$perms"

    check "perm_count"   "Permission count"        "pass" \
        "${perm_count} declared" 2 "🔐"

    if [[ ${#invalid_perms[@]} -gt 0 ]]; then
        check "perm_valid" "All permissions recognized" "warn" \
            "unknown: ${invalid_perms[*]}" 3 "🔐"
    else
        check "perm_valid" "All permissions recognized" "pass" \
            "all ${perm_count} permissions valid" 3 "🔐"
    fi

    if [[ ${#dangerous_perms[@]} -gt 0 ]]; then
        check "perm_wildcard" "No wildcard permissions" "fail" \
            "wildcard perms: ${dangerous_perms[*]}" 5 "🚨"
        SECURITY_ISSUES+=("Wildcard permissions: ${dangerous_perms[*]}")
    else
        check "perm_wildcard" "No wildcard permissions" "pass" \
            "no wildcards" 5 "✅"
    fi

    if [[ ${#high_risk_perms[@]} -gt 0 ]]; then
        check "perm_high_risk" "High-risk permissions" "warn" \
            "requires security review: ${high_risk_perms[*]}" 3 "⚠️"
        SECURITY_ISSUES+=("High-risk permissions: ${high_risk_perms[*]}")
    else
        check "perm_high_risk" "High-risk permissions" "pass" \
            "none declared" 3 "✅"
    fi
}

# ── HOOKS VALIDATION ───────────────────────────────────────────────────────────
validate_hooks() {
    section "🪝" "Hook Declarations" "$GOLD"
    local plugin_json="$1"

    if ! command -v jq &>/dev/null; then
        check "hooks" "Hook declarations" "skip" "jq required" 0 "🪝"
        return 0
    fi

    local hooks
    hooks="$(jq -r '.hooks // {} | keys | .[]' "$plugin_json" 2>/dev/null || true)"

    if [[ -z "$hooks" ]]; then
        check "hooks_declared" "Hooks declared" "skip" "no hooks (optional)" 0 "🪝"
        return 0
    fi

    local hook_count=0
    local invalid_hooks=()

    while IFS= read -r hook; do
        [[ -z "$hook" ]] && continue
        ((hook_count++)) || true

        local is_valid=false
        for valid_hook in "${VALID_HOOKS[@]}"; do
            [[ "$hook" == "$valid_hook" ]] && { is_valid=true; break; }
        done

        if [[ "$is_valid" == "true" ]]; then
            local hook_script
            hook_script="$(jq -r --arg h "$hook" '.hooks[$h] // empty' \
                "$plugin_json" 2>/dev/null || true)"
            printf "  %s  %s%-48s%s%s%s%s\n" \
                "🪝" "${GOLD}" "$hook" "$R" \
                "${D}${SLATE}" "→ ${hook_script}" "$R" >&2
        else
            invalid_hooks+=("$hook")
        fi
    done <<< "$hooks"

    if [[ ${#invalid_hooks[@]} -gt 0 ]]; then
        check "hooks_valid" "All hooks recognized" "warn" \
            "unknown hooks: ${invalid_hooks[*]}" 2 "🪝"
    else
        check "hooks_valid" "All hooks recognized" "pass" \
            "${hook_count} hook(s) valid" 2 "🪝"
    fi
}

# ── SECURITY SCAN ─────────────────────────────────────────────────────────────
validate_security() {
    section "🔒" "Security Scan" "$RED"
    local plugin_dir="$1"

    local scan_files=()
    while IFS= read -r -d '' f; do
        scan_files+=("$f")
    done < <(find "$plugin_dir" \
        -type f \( -name "*.sh" -o -name "*.py" -o -name "*.lua" \
                   -o -name "*.js" -o -name "*.ts" \) \
        -print0 2>/dev/null || true)

    if [[ ${#scan_files[@]} -eq 0 ]]; then
        check "security_scan" "Security scan" "skip" "no script files" 0 "🔒"
        return 0
    fi

    local total_issues=0
    local found_issues=()

    for file in "${scan_files[@]}"; do
        for pattern in "${DANGEROUS_PATTERNS[@]}"; do
            local match
            match="$(grep -nP "$pattern" "$file" 2>/dev/null | head -1 || true)"
            if [[ -n "$match" ]]; then
                local line_num; line_num="$(echo "$match" | cut -d: -f1)"
                found_issues+=("${file##"$plugin_dir"/}:${line_num} — ${pattern}")
                ((total_issues++)) || true
                SECURITY_ISSUES+=("Dangerous pattern in ${file##"$plugin_dir"/}:${line_num}")
            fi
        done
    done

    if [[ $total_issues -gt 0 ]]; then
        check "security_dangerous" "No dangerous patterns" "fail" \
            "${total_issues} dangerous pattern(s) found" 10 "🚨"
        for issue in "${found_issues[@]:0:5}"; do
            printf "     %s⚠%s %s%s%s\n" "${RED}" "$R" "${D}" "$issue" "$R" >&2
        done
        return 1
    fi
    check "security_dangerous" "No dangerous patterns" "pass" \
        "${#scan_files[@]} files scanned" 10 "✅"

    # Check for hardcoded credentials
    local cred_found=()
    for file in "${scan_files[@]}"; do
        local cred
        cred="$(grep -nP \
            '(password|passwd|secret|token|api.key)\s*=\s*["\047][^"\047]{8,}' \
            "$file" 2>/dev/null | head -1 || true)"
        [[ -n "$cred" ]] && cred_found+=("${file##"$plugin_dir"/}")
    done

    if [[ ${#cred_found[@]} -gt 0 ]]; then
        check "security_creds" "No hardcoded credentials" "fail" \
            "found in: ${cred_found[*]}" 8 "🔑"
        SECURITY_ISSUES+=("Hardcoded credentials in: ${cred_found[*]}")
    else
        check "security_creds" "No hardcoded credentials" "pass" \
            "clean" 8 "✅"
    fi

    # Check eval usage
    local eval_found=()
    for file in "${scan_files[@]}"; do
        if grep -qP '\beval\b' "$file" 2>/dev/null; then
            eval_found+=("${file##"$plugin_dir"/}")
        fi
    done

    if [[ ${#eval_found[@]} -gt 0 ]]; then
        check "security_eval" "No eval() usage" "warn" \
            "eval in: ${eval_found[*]}" 3 "⚠️"
    else
        check "security_eval" "No eval() usage" "pass" \
            "no eval found" 3 "✅"
    fi

    # ShellCheck on bash files
    if command -v shellcheck &>/dev/null; then
        local sh_failed=()
        for file in "${scan_files[@]}"; do
            [[ "$file" == *.sh ]] || continue
            if ! shellcheck --severity=error "$file" &>/dev/null; then
                sh_failed+=("${file##"$plugin_dir"/}")
            fi
        done

        if [[ ${#sh_failed[@]} -gt 0 ]]; then
            check "security_shellcheck" "ShellCheck (scripts)" "fail" \
                "errors in: ${sh_failed[*]}" 5 "🐚"
        else
            local sh_count; sh_count="$(ls "$plugin_dir"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
            check "security_shellcheck" "ShellCheck (scripts)" "pass" \
                "${sh_count:-0} scripts clean" 5 "✅"
        fi
    else
        check "security_shellcheck" "ShellCheck" "skip" "shellcheck not installed" 5 "🐚"
    fi
}

# ── README QUALITY ─────────────────────────────────────────────────────────────
validate_readme() {
    section "📖" "README Quality" "$LAVENDER"
    local plugin_dir="$1"
    local readme="${plugin_dir}/README.md"

    if [[ ! -f "$readme" ]]; then
        check "readme_exists" "README.md exists" "warn" "missing" 3 "📖"
        return 0
    fi

    check "readme_exists" "README.md exists" "pass" "present" 3 "📖"

    local word_count
    word_count="$(wc -w < "$readme" | tr -d ' ')"

    if [[ $word_count -lt 50 ]]; then
        check "readme_length" "README content" "warn" \
            "${word_count} words — too brief (min 50)" 2 "📖"
    else
        check "readme_length" "README content" "pass" "${word_count} words" 2 "📖"
    fi

    # Check for key sections
    local -a key_sections=("Installation" "Usage" "Configuration" "Requirements")
    local missing_sections=()
    for sec in "${key_sections[@]}"; do
        if ! grep -qi "## *$sec" "$readme" 2>/dev/null; then
            missing_sections+=("$sec")
        fi
    done

    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        check "readme_sections" "README sections" "warn" \
            "missing: ${missing_sections[*]}" 2 "📖"
    else
        check "readme_sections" "README sections" "pass" \
            "all key sections present" 2 "📖"
    fi
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    printf "\n" >&2; box_t
    box_l "${B}${INDIGO}  🔌 PLUGIN VALIDATION REPORT${R}${BG_MIDNIGHT}${GOLD}"
    box_td
    box_l "$(printf "  %s%-18s%s %s%s%s" "${CYAN}${B}" "Plugin:" "$R$BG_MIDNIGHT$GOLD" \
        "${LAVENDER}${B}" "${PLUGIN_NAME:-unknown}" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s%s" "${CYAN}${B}" "Version:" "$R$BG_MIDNIGHT$GOLD" \
        "${MINT}" "${PLUGIN_VERSION:-unknown}" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s%s" "${CYAN}${B}" "Permissions:" "$R$BG_MIDNIGHT$GOLD" \
        "${PEACH}" "${#PLUGIN_PERMISSIONS[@]} declared" "$R$BG_MIDNIGHT$GOLD")"
    box_td
    box_l "$(printf "  %s✓ %-4s%s passed  %s✗ %-4s%s failed  %s⚠ %-4s%s warned" \
        "${GREEN}${B}" "$CHECKS_PASSED" "$R$BG_MIDNIGHT$GOLD" \
        "${RED}${B}"   "$CHECKS_FAILED" "$R$BG_MIDNIGHT$GOLD" \
        "${YELLOW}${B}" "$CHECKS_WARNED" "$R$BG_MIDNIGHT$GOLD")"

    if [[ ${#SECURITY_ISSUES[@]} -gt 0 ]]; then
        box_td
        box_l "${RED}${B}  🚨 SECURITY ISSUES:${R}${BG_MIDNIGHT}${GOLD}"
        for si in "${SECURITY_ISSUES[@]}"; do
            box_l "  ${RED}  ✗ ${si}${R}${BG_MIDNIGHT}${GOLD}"
        done
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        box_td
        box_l "${RED}${B}  ERRORS:${R}${BG_MIDNIGHT}${GOLD}"
        for e in "${ERRORS[@]}"; do
            box_l "  ${RED}  ✗ ${e:0:$(( TERM_WIDTH-12 ))}${R}${BG_MIDNIGHT}${GOLD}"
        done
    fi

    box_td
    if [[ $CHECKS_FAILED -gt 0 ]] || [[ ${#SECURITY_ISSUES[@]} -gt 0 ]]; then
        box_l "  ${RED}${B}VALIDATION FAILED ✗${R}${BG_MIDNIGHT}${GOLD}"
    else
        box_l "  ${GREEN}${B}VALIDATION PASSED ✓${R}${BG_MIDNIGHT}${GOLD}"
    fi
    box_b; printf "\n" >&2
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    local plugin_input="${1:?'Usage: validate-plugin.sh <plugin-dir|plugin.json>'}"

    local plugin_dir plugin_json
    if [[ -d "$plugin_input" ]]; then
        plugin_dir="$plugin_input"
        plugin_json="${plugin_dir}/plugin.json"
    elif [[ -f "$plugin_input" ]]; then
        plugin_json="$plugin_input"
        plugin_dir="$(dirname "$plugin_input")"
    else
        echo "${RED}Error: '$plugin_input' not found${R}" >&2
        exit 1
    fi

    print_banner "$(basename "$plugin_dir")"
    validate_structure  "$plugin_dir"
    validate_plugin_json "$plugin_json"
    validate_security   "$plugin_dir"
    validate_readme     "$plugin_dir"
    print_summary

    [[ $CHECKS_FAILED -gt 0 ]] || [[ ${#SECURITY_ISSUES[@]} -gt 0 ]] && exit 1
    [[ $CHECKS_WARNED -gt 0 ]] && exit 2
    exit 0
}

main "$@"