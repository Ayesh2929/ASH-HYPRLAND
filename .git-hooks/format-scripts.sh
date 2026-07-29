#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 ASH DOTFILES v5.0 OMEGA — ULTRA FORMAT ENGINE                          ║
# ║  Auto-formats staged files across all languages with zero compromise        ║
# ║  Shell · Lua · Python · TypeScript · Dart · Nix · JSON · YAML · TOML       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI MASTER PALETTE ───────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m";       readonly B="${ESC}[1m"
readonly D="${ESC}[2m";       readonly I="${ESC}[3m"
readonly U="${ESC}[4m"

readonly BLACK="${ESC}[30m";      readonly RED="${ESC}[31m"
readonly GREEN="${ESC}[32m";      readonly YELLOW="${ESC}[33m"
readonly BLUE="${ESC}[34m";       readonly MAGENTA="${ESC}[35m"
readonly CYAN="${ESC}[36m";       readonly WHITE="${ESC}[37m"
readonly ORANGE="${ESC}[38;5;208m";   readonly PURPLE="${ESC}[38;5;135m"
readonly PINK="${ESC}[38;5;213m";     readonly LIME="${ESC}[38;5;154m"
readonly GOLD="${ESC}[38;5;220m";     readonly SKY="${ESC}[38;5;117m"
readonly LAVENDER="${ESC}[38;5;183m"; readonly MINT="${ESC}[38;5;121m"
readonly PEACH="${ESC}[38;5;217m";    readonly ROSE="${ESC}[38;5;211m"
readonly TEAL="${ESC}[38;5;43m";      readonly CORAL="${ESC}[38;5;203m"
readonly CREAM="${ESC}[38;5;230m";    readonly SLATE="${ESC}[38;5;245m"
readonly AMBER="${ESC}[38;5;214m";    readonly EMERALD="${ESC}[38;5;120m"
readonly VIOLET="${ESC}[38;5;177m";   readonly CRIMSON="${ESC}[38;5;161m"
readonly INDIGO="${ESC}[38;5;105m";   readonly SAND="${ESC}[38;5;180m"
readonly OCEAN="${ESC}[38;5;38m";     readonly CHERRY="${ESC}[38;5;197m"

readonly BG_MIDNIGHT="${ESC}[48;5;16m"
readonly BG_DARK="${ESC}[48;5;235m"
readonly BG_DARKER="${ESC}[48;5;232m"
readonly BG_FOREST="${ESC}[48;5;22m"
readonly BG_NAVY="${ESC}[48;5;17m"
readonly BG_DEEP="${ESC}[48;5;54m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="format-scripts"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-format"
readonly LOG_FILE="${LOG_DIR}/format-${TIMESTAMP}.log"
readonly BACKUP_DIR="${LOG_DIR}/backups-${TIMESTAMP}"
readonly EDITORCONFIG="${REPO_ROOT}/.editorconfig"
readonly SCRIPT_START_MS="$(date +%s%3N)"

# ── FORMATTER CONFIGS ─────────────────────────────────────────────────────────
readonly SHFMT_OPTS="-i 4 -bn -ci -sr -kp"           # indent=4, binary-next-line, etc.
readonly STYLUA_OPTS="--indent-type Spaces --indent-width 4 --quote-style AutoPreferDouble"
readonly BLACK_OPTS="--line-length 100 --quiet"
readonly ISORT_OPTS="--profile black --line-length 100 --quiet"
readonly PRETTIER_OPTS="--tab-width 2 --single-quote --trailing-comma es5 --print-width 100"
readonly ALEJANDRA_OPTS="--quiet"

# ── STATE ─────────────────────────────────────────────────────────────────────
FILES_FORMATTED=0
FILES_SKIPPED=0
FILES_FAILED=0
FILES_UNCHANGED=0
TOTAL_FILES=0
declare -A FORMATTER_STATS=()
declare -A FORMATTED_FILES=()
ERRORS=()
WARNINGS=()
RESTORE_NEEDED=false

# ── TIMING ────────────────────────────────────────────────────────────────────
now_ms()     { date +%s%3N; }
elapsed_ms() { echo $(( $(now_ms) - SCRIPT_START_MS )); }
format_dur() {
    local ms="$1"
    if   [[ $ms -lt 1000 ]];  then printf "%dms"   "$ms"
    elif [[ $ms -lt 60000 ]]; then printf "%.1fs"  "$(echo "scale=1; $ms/1000"  | bc 2>/dev/null || echo "$((ms/1000))")"
    else                           printf "%.1fm"  "$(echo "scale=1; $ms/60000" | bc 2>/dev/null || echo "$((ms/60000))")"
    fi
}

# ── INIT ──────────────────────────────────────────────────────────────────────
init() {
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    log_engine "Format Engine initialized"
    log_engine "Repo: ${REPO_ROOT}"
    log_engine "Log:  ${LOG_FILE}"
}

# ── LOGGING ───────────────────────────────────────────────────────────────────
_log() {
    local level="$1" icon="$2" color="$3"
    local msg="${*:4}"
    local ts; ts="$(date '+%H:%M:%S.%3N')"

    printf "%s%s%s %s%s%s %s%s%s\n" \
        "${D}${SLATE}" "$ts" "$R" \
        "${color}${B}" "$icon" "$R" \
        "${color}" "$msg" "$R" >&2

    printf "[%s] [%-8s] %s %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$icon" "$msg" \
        >> "$LOG_FILE"
}

log_engine()  { _log "ENGINE"  "⚙️"  "${GOLD}"      "$*"; }
log_format()  { _log "FORMAT"  "🎨"  "${CYAN}"      "$*"; }
log_pass()    { _log "PASS"    "✓"   "${GREEN}"     "$*"; }
log_fail()    { _log "FAIL"    "✗"   "${RED}"       "$*"; }
log_skip()    { _log "SKIP"    "↷"   "${SLATE}${D}" "$*"; }
log_warn()    { _log "WARN"    "⚠"   "${YELLOW}"    "$*"; }
log_info()    { _log "INFO"    "ℹ"   "${LAVENDER}"  "$*"; }
log_backup()  { _log "BACKUP"  "💾"  "${PEACH}"     "$*"; }
log_restore() { _log "RESTORE" "♻️"   "${CORAL}"     "$*"; }
log_section() { _log "SECTION" "▶"   "${GOLD}${B}"  "$*"; }
log_stat()    { _log "STAT"    "📊"  "${VIOLET}"    "$*"; }

# ── RENDERING ENGINE ──────────────────────────────────────────────────────────
hr() {
    local char="${1:-─}" width="${2:-$TERM_WIDTH}" color="${3:-${D}${SLATE}}"
    printf "%s%s%s\n" "$color" \
        "$(printf '%*s' "$width" '' | tr ' ' "$char")" "$R" >&2
}

box_t()   { printf "%s%s  ╔%s╗  %s\n" "$BG_MIDNIGHT" "$GOLD" \
                "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_d()   { printf "%s%s  ╠%s╣  %s\n" "$BG_MIDNIGHT" "$GOLD" \
                "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_td()  { printf "%s%s  ╟%s╢  %s\n" "$BG_MIDNIGHT" "$GOLD" \
                "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '─')" "$R" >&2; }
box_b()   { printf "%s%s  ╚%s╝  %s\n" "$BG_MIDNIGHT" "$GOLD" \
                "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_l()   {
    local content="$1"
    local clean; clean="$(printf '%s' "$content" | sed 's/\x1b\[[0-9;]*m//g')"
    local pad=$(( TERM_WIDTH - 4 - ${#clean} ))
    [[ $pad -lt 0 ]] && pad=0
    printf "%s  ║ %s%*s║  %s\n" \
        "$BG_MIDNIGHT$GOLD" "$content" "$pad" "" "$R" >&2
}

section() {
    local icon="$1" title="$2" color="${3:-$CYAN}"
    printf "\n" >&2
    hr "─" "$TERM_WIDTH" "${D}${SLATE}"
    printf "  %s %s%s%s\n" "$icon" "${color}${B}" "$title" "$R" >&2
    hr "─" "$TERM_WIDTH" "${D}${SLATE}"
}

# ── ANIMATED PROGRESS BAR ─────────────────────────────────────────────────────
progress_bar() {
    local current="$1" total="$2" label="${3:-}" width=40
    [[ $total -eq 0 ]] && total=1
    local pct=$(( current * 100 / total ))
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))

    local color
    if   [[ $pct -lt 33 ]]; then color="${CORAL}"
    elif [[ $pct -lt 66 ]]; then color="${AMBER}"
    elif [[ $pct -lt 90 ]]; then color="${LIME}"
    else                          color="${EMERALD}"
    fi

    local bar_filled bar_empty
    bar_filled="$(printf '%*s' "$filled" '' | tr ' ' '█')"
    bar_empty="$(printf '%*s'  "$empty"  '' | tr ' ' '░')"

    printf "\r  %s%s%s%s%s %s%3d%%%s  %s%-30.30s%s" \
        "${color}${B}" "$bar_filled" \
        "${D}${SLATE}" "$bar_empty" "$R" \
        "${color}${B}" "$pct" "$R" \
        "${D}${WHITE}" "$label" "$R" >&2
}

# ── FILE BACKUP ────────────────────────────────────────────────────────────────
backup_file() {
    local file="$1"
    local backup_path="${BACKUP_DIR}/${file//\//_}"
    cp "$file" "$backup_path" 2>/dev/null || true
    log_backup "Backed up: $file → $backup_path"
}

restore_file() {
    local file="$1"
    local backup_path="${BACKUP_DIR}/${file//\//_}"
    if [[ -f "$backup_path" ]]; then
        cp "$backup_path" "$file"
        log_restore "Restored: $file"
    fi
}

# ── CHECKSUM ───────────────────────────────────────────────────────────────────
file_checksum() {
    md5sum "$1" 2>/dev/null | cut -d' ' -f1 || \
    shasum "$1" 2>/dev/null | cut -d' ' -f1 || \
    echo "nochecksum"
}

# ── FORMATTER AVAILABILITY CHECK ──────────────────────────────────────────────
check_formatters() {
    section "🔍" "Formatter Availability Check" "$CYAN"

    declare -gA AVAILABLE_FORMATTERS=()

    local -A FORMATTERS=(
        ["shfmt"]="Shell scripts"
        ["stylua"]="Lua files"
        ["black"]="Python files"
        ["isort"]="Python imports"
        ["ruff"]="Python (fast lint+format)"
        ["prettier"]="JS/TS/JSON/YAML/MD"
        ["alejandra"]="Nix files"
        ["nixfmt"]="Nix files (alt)"
        ["dart"]="Dart/Flutter files"
        ["rustfmt"]="Rust files"
        ["gofmt"]="Go files"
        ["markdownlint"]="Markdown files"
        ["yamllint"]="YAML validation"
        ["jq"]="JSON validation"
        ["fish"]="Fish syntax check"
        ["shellcheck"]="Shell lint"
        ["luacheck"]="Lua lint"
        ["taplo"]="TOML files"
        ["xmllint"]="XML files"
    )

    local -A FORMATTER_COLORS=(
        ["shfmt"]="${LIME}"      ["stylua"]="${VIOLET}"   ["black"]="${AMBER}"
        ["isort"]="${TEAL}"      ["ruff"]="${ORANGE}"     ["prettier"]="${CYAN}"
        ["alejandra"]="${INDIGO}" ["nixfmt"]="${INDIGO}"  ["dart"]="${OCEAN}"
        ["rustfmt"]="${CORAL}"   ["gofmt"]="${SKY}"       ["markdownlint"]="${LAVENDER}"
        ["yamllint"]="${PEACH}"  ["jq"]="${MINT}"         ["fish"]="${EMERALD}"
        ["shellcheck"]="${ROSE}" ["luacheck"]="${GOLD}"   ["taplo"]="${SAND}"
        ["xmllint"]="${CHERRY}"
    )

    local found_count=0 missing_count=0

    printf "\n" >&2
    for formatter in "${!FORMATTERS[@]}"; do
        local desc="${FORMATTERS[$formatter]}"
        local color="${FORMATTER_COLORS[$formatter]:-$WHITE}"

        if command -v "$formatter" &>/dev/null; then
            local version
            version="$(${formatter} --version 2>/dev/null | head -1 | \
                grep -oP '[\d]+\.[\d]+\.?[\d]*' | head -1 || echo "?")"

            AVAILABLE_FORMATTERS["$formatter"]=1
            ((found_count++)) || true

            printf "  %s✓%s  %s%-16s%s %s%-30s%s %sv%s%s\n" \
                "${GREEN}${B}" "$R" \
                "${color}${B}" "$formatter" "$R" \
                "${D}${WHITE}" "$desc" "$R" \
                "${D}${SLATE}" "${version}" "$R" >&2
        else
            ((missing_count++)) || true
            printf "  %s✗%s  %s%-16s%s %s%-30s%s %snot installed%s\n" \
                "${SLATE}${D}" "$R" \
                "${SLATE}${D}" "$formatter" "$R" \
                "${SLATE}${D}" "$desc" "$R" \
                "${SLATE}${D}" "$R" >&2
        fi
    done

    printf "\n" >&2
    log_stat "Formatters available: ${found_count}/${#FORMATTERS[@]}"

    if [[ $found_count -eq 0 ]]; then
        log_warn "No formatters found — install shfmt, stylua, black, prettier"
        return 2
    fi
}

# ── STAGED FILE COLLECTION ────────────────────────────────────────────────────
collect_staged_files() {
    section "📂" "Collecting Staged Files" "$GOLD"

    # Get staged files by type
    declare -gA STAGED_BY_TYPE=()

    local all_staged
    all_staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"

    if [[ -z "$all_staged" ]]; then
        log_info "No staged files found"
        return 3
    fi

    TOTAL_FILES="$(echo "$all_staged" | grep -c . || echo 0)"

    # Categorize by extension
    while IFS= read -r file; do
        [[ -f "$file" ]] || continue
        local ext="${file##*.}"

        case "$ext" in
            sh|bash)           STAGED_BY_TYPE["shell"]+="${file}"$'\n' ;;
            lua)               STAGED_BY_TYPE["lua"]+="${file}"$'\n' ;;
            py)                STAGED_BY_TYPE["python"]+="${file}"$'\n' ;;
            ts|tsx)            STAGED_BY_TYPE["typescript"]+="${file}"$'\n' ;;
            js|jsx|mjs)        STAGED_BY_TYPE["javascript"]+="${file}"$'\n' ;;
            dart)              STAGED_BY_TYPE["dart"]+="${file}"$'\n' ;;
            rs)                STAGED_BY_TYPE["rust"]+="${file}"$'\n' ;;
            go)                STAGED_BY_TYPE["go"]+="${file}"$'\n' ;;
            nix)               STAGED_BY_TYPE["nix"]+="${file}"$'\n' ;;
            json|jsonc)        STAGED_BY_TYPE["json"]+="${file}"$'\n' ;;
            yaml|yml)          STAGED_BY_TYPE["yaml"]+="${file}"$'\n' ;;
            toml)              STAGED_BY_TYPE["toml"]+="${file}"$'\n' ;;
            md|markdown)       STAGED_BY_TYPE["markdown"]+="${file}"$'\n' ;;
            fish)              STAGED_BY_TYPE["fish"]+="${file}"$'\n' ;;
            css|scss|less)     STAGED_BY_TYPE["css"]+="${file}"$'\n' ;;
            xml)               STAGED_BY_TYPE["xml"]+="${file}"$'\n' ;;
            html)              STAGED_BY_TYPE["html"]+="${file}"$'\n' ;;
        esac
    done <<< "$all_staged"

    # Display breakdown
    printf "\n" >&2
    local -A TYPE_ICONS=(
        ["shell"]="🐚"  ["lua"]="🌙"    ["python"]="🐍"
        ["typescript"]="⚡" ["javascript"]="📜" ["dart"]="🎯"
        ["rust"]="🦀"   ["go"]="🐹"     ["nix"]="❄️"
        ["json"]="📋"   ["yaml"]="📝"   ["toml"]="⚙️"
        ["markdown"]="📖" ["fish"]="🐟" ["css"]="🎨"
        ["xml"]="🔖"    ["html"]="🌐"
    )

    local -A TYPE_COLORS=(
        ["shell"]="${LIME}"     ["lua"]="${VIOLET}"   ["python"]="${AMBER}"
        ["typescript"]="${CYAN}" ["javascript"]="${GOLD}" ["dart"]="${OCEAN}"
        ["rust"]="${CORAL}"     ["go"]="${SKY}"       ["nix"]="${INDIGO}"
        ["json"]="${MINT}"      ["yaml"]="${PEACH}"   ["toml"]="${SAND}"
        ["markdown"]="${LAVENDER}" ["fish"]="${EMERALD}" ["css"]="${ROSE}"
        ["xml"]="${CHERRY}"     ["html"]="${ORANGE}"
    )

    for type in "${!STAGED_BY_TYPE[@]}"; do
        local files="${STAGED_BY_TYPE[$type]}"
        local count; count="$(echo "$files" | grep -c . || echo 0)"
        local icon="${TYPE_ICONS[$type]:-📄}"
        local color="${TYPE_COLORS[$type]:-$WHITE}"

        printf "  %s  %s%-14s%s %s%3d file(s)%s\n" \
            "$icon" \
            "${color}${B}" "$type" "$R" \
            "${GOLD}" "$count" "$R" >&2
    done

    printf "\n  %s%d total staged files across %d type(s)%s\n\n" \
        "${D}${SLATE}" "$TOTAL_FILES" "${#STAGED_BY_TYPE[@]}" "$R" >&2

    log_engine "Collected ${TOTAL_FILES} staged files"
}

# ══════════════════════════════════════════════════════════════════════════════
#  LANGUAGE FORMATTERS
# ══════════════════════════════════════════════════════════════════════════════

# ── GENERIC FORMAT WRAPPER ────────────────────────────────────────────────────
format_file() {
    local file="$1"
    local formatter="$2"
    local formatter_cmd="$3"
    local icon="${4:-🎨}"
    local color="${5:-$CYAN}"

    [[ -f "$file" ]] || return 0

    # Backup original
    backup_file "$file"
    local before_sum; before_sum="$(file_checksum "$file")"
    local t_start; t_start="$(now_ms)"

    # Run formatter
    local output exit_code=0
    output="$(eval "$formatter_cmd" 2>&1)" || exit_code=$?

    local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

    if [[ $exit_code -ne 0 ]]; then
        restore_file "$file"
        ((FILES_FAILED++)) || true
        ERRORS+=("${formatter}: ${file} — ${output}")
        printf "  %s✗%s %s%s%-52s%s %s✗ FAIL%s %s[%s]%s\n" \
            "${RED}${B}" "$R" "$icon" "${color}${B}" \
            "$file" "$R" \
            "${RED}${B}" "$R" "${D}${SLATE}" "$dur" "$R" >&2
        return 1
    fi

    local after_sum; after_sum="$(file_checksum "$file")"

    if [[ "$before_sum" == "$after_sum" ]]; then
        ((FILES_UNCHANGED++)) || true
        printf "  %s≡%s %s%s%-52s%s %s≡ SAME%s %s[%s]%s\n" \
            "${SLATE}${D}" "$R" "$icon" "${D}${SLATE}" \
            "$file" "$R" \
            "${SLATE}${D}" "$R" "${D}${SLATE}" "$dur" "$R" >&2
    else
        ((FILES_FORMATTED++)) || true
        FORMATTED_FILES["$file"]="$formatter"

        # Re-stage the formatted file
        git add "$file" 2>/dev/null || true

        printf "  %s✓%s %s%s%-52s%s %s✓ DONE%s %s[%s]%s\n" \
            "${GREEN}${B}" "$R" "$icon" "${color}${B}" \
            "$file" "$R" \
            "${GREEN}${B}" "$R" "${D}${SLATE}" "$dur" "$R" >&2
    fi

    # Update formatter stats
    FORMATTER_STATS["$formatter"]=$(( ${FORMATTER_STATS["$formatter"]:-0} + 1 ))

    return 0
}

# ── SHELL FORMATTER ───────────────────────────────────────────────────────────
format_shell() {
    section "🐚" "Shell Scripts (shfmt + shellcheck)" "$LIME"

    local files="${STAGED_BY_TYPE[shell]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No shell files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[shfmt]:-}" ]]; then
        log_warn "shfmt not available — install: go install mvdan.cc/sh/v3/cmd/shfmt@latest"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        # Determine shell dialect
        local shell_flag="bash"
        local first_line; first_line="$(head -1 "$file" 2>/dev/null || true)"
        if echo "$first_line" | grep -q "#!/bin/sh"; then
            shell_flag="posix"
        elif echo "$first_line" | grep -q "mksh"; then
            shell_flag="mksh"
        fi

        format_file "$file" "shfmt" \
            "shfmt ${SHFMT_OPTS} -ln ${shell_flag} -w '${file}'" \
            "🐚" "${LIME}"

    done <<< "$files"
    printf "\n" >&2

    # Run shellcheck lint after formatting
    if [[ -n "${AVAILABLE_FORMATTERS[shellcheck]:-}" ]]; then
        printf "\n  %s%sShellCheck Lint:%s\n" "$B" "$ROSE" "$R" >&2
        local lint_errors=0
        while IFS= read -r file; do
            [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
            local output
            if ! output="$(shellcheck \
                --severity=warning \
                --format=gcc \
                --shell=bash \
                "$file" 2>&1)"; then
                ((lint_errors++)) || true
                echo "$output" | head -5 | while IFS= read -r line; do
                    printf "     %s│%s %s%s%s\n" \
                        "${ROSE}${D}" "$R" "${D}" "$line" "$R" >&2
                done
            fi
        done <<< "$files"

        if [[ $lint_errors -eq 0 ]]; then
            log_pass "ShellCheck: all files clean"
        else
            log_warn "ShellCheck: ${lint_errors} file(s) have warnings"
        fi
    fi
}

# ── LUA FORMATTER ─────────────────────────────────────────────────────────────
format_lua() {
    section "🌙" "Lua Files (StyLua + LuaCheck)" "$VIOLET"

    local files="${STAGED_BY_TYPE[lua]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Lua files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[stylua]:-}" ]]; then
        log_warn "stylua not available — install: cargo install stylua"
        return 0
    fi

    # Build stylua opts from .stylua.toml if present
    local stylua_cmd="stylua"
    if [[ -f "${REPO_ROOT}/config/nvim/stylua.toml" ]]; then
        stylua_cmd="stylua --config-path ${REPO_ROOT}/config/nvim/stylua.toml"
    else
        stylua_cmd="stylua ${STYLUA_OPTS}"
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "stylua" \
            "${stylua_cmd} '${file}'" \
            "🌙" "${VIOLET}"
    done <<< "$files"
    printf "\n" >&2

    # LuaCheck lint
    if [[ -n "${AVAILABLE_FORMATTERS[luacheck]:-}" ]]; then
        printf "\n  %s%sLuaCheck Lint:%s\n" "$B" "$GOLD" "$R" >&2
        local lua_files_arr=()
        while IFS= read -r f; do
            [[ -f "$f" ]] && lua_files_arr+=("$f")
        done <<< "$files"

        if [[ ${#lua_files_arr[@]} -gt 0 ]]; then
            local output
            if output="$(luacheck \
                --no-color \
                --codes \
                --ignore 212 213 \
                "${lua_files_arr[@]}" 2>&1)"; then
                log_pass "LuaCheck: all files clean"
            else
                local warn_count; warn_count="$(echo "$output" | \
                    grep -cP '(warning|error)' || echo 0)"
                log_warn "LuaCheck: ${warn_count} warning(s)"
                echo "$output" | head -8 | while IFS= read -r line; do
                    printf "     %s│%s %s%s%s\n" "${GOLD}${D}" "$R" "${D}" "$line" "$R" >&2
                done
            fi
        fi
    fi
}

# ── PYTHON FORMATTER ──────────────────────────────────────────────────────────
format_python() {
    section "🐍" "Python Files (Ruff + Black + isort)" "$AMBER"

    local files="${STAGED_BY_TYPE[python]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Python files staged"; return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        # Try ruff first (fastest, replaces isort+some black)
        if [[ -n "${AVAILABLE_FORMATTERS[ruff]:-}" ]]; then
            format_file "$file" "ruff" \
                "ruff format --quiet '${file}' && ruff check --fix --quiet '${file}'" \
                "🐍" "${AMBER}"

        else
            # Fallback: isort → black
            if [[ -n "${AVAILABLE_FORMATTERS[isort]:-}" ]]; then
                format_file "$file" "isort" \
                    "isort ${ISORT_OPTS} '${file}'" \
                    "🔤" "${TEAL}"
            fi

            if [[ -n "${AVAILABLE_FORMATTERS[black]:-}" ]]; then
                format_file "$file" "black" \
                    "black ${BLACK_OPTS} '${file}'" \
                    "🐍" "${AMBER}"
            fi
        fi

    done <<< "$files"
    printf "\n" >&2
}

# ── TYPESCRIPT / JAVASCRIPT FORMATTER ─────────────────────────────────────────
format_typescript() {
    section "⚡" "TypeScript & JavaScript (Prettier + ESLint)" "$CYAN"

    local ts_files="${STAGED_BY_TYPE[typescript]:-}"
    local js_files="${STAGED_BY_TYPE[javascript]:-}"
    local combined_files="${ts_files}${js_files}"

    if [[ -z "$combined_files" ]]; then
        log_skip "No TS/JS files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[prettier]:-}" ]]; then
        log_warn "prettier not available — install: npm i -g prettier"
        return 0
    fi

    # Detect prettier config
    local prettier_cfg=""
    for cfg in "${REPO_ROOT}/.prettierrc" \
               "${REPO_ROOT}/.prettierrc.json" \
               "${REPO_ROOT}/.prettierrc.yml" \
               "${REPO_ROOT}/web/.prettierrc"; do
        if [[ -f "$cfg" ]]; then
            prettier_cfg="--config ${cfg}"
            break
        fi
    done

    local count=0
    local total; total="$(echo "$combined_files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "prettier" \
            "prettier ${PRETTIER_OPTS} ${prettier_cfg} --write '${file}'" \
            "⚡" "${CYAN}"
    done <<< "$combined_files"
    printf "\n" >&2
}

# ── DART / FLUTTER FORMATTER ───────────────────────────────────────────────────
format_dart() {
    section "🎯" "Dart & Flutter (dart format)" "$OCEAN"

    local files="${STAGED_BY_TYPE[dart]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Dart files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[dart]:-}" ]]; then
        log_warn "dart not available — install Flutter SDK"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "dart format" \
            "dart format --line-length 100 '${file}'" \
            "🎯" "${OCEAN}"
    done <<< "$files"
    printf "\n" >&2
}

# ── RUST FORMATTER ─────────────────────────────────────────────────────────────
format_rust() {
    section "🦀" "Rust Files (rustfmt)" "$CORAL"

    local files="${STAGED_BY_TYPE[rust]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Rust files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[rustfmt]:-}" ]]; then
        log_warn "rustfmt not available — install: rustup component add rustfmt"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "rustfmt" \
            "rustfmt --edition 2021 '${file}'" \
            "🦀" "${CORAL}"
    done <<< "$files"
    printf "\n" >&2
}

# ── GO FORMATTER ───────────────────────────────────────────────────────────────
format_go() {
    section "🐹" "Go Files (gofmt + goimports)" "$SKY"

    local files="${STAGED_BY_TYPE[go]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Go files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[gofmt]:-}" ]]; then
        log_warn "gofmt not available — install Go toolchain"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "gofmt" \
            "gofmt -w '${file}'" \
            "🐹" "${SKY}"
    done <<< "$files"
    printf "\n" >&2
}

# ── NIX FORMATTER ─────────────────────────────────────────────────────────────
format_nix() {
    section "❄️" "Nix Files (alejandra)" "$INDIGO"

    local files="${STAGED_BY_TYPE[nix]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Nix files staged"; return 0
    fi

    local nix_formatter=""
    if [[ -n "${AVAILABLE_FORMATTERS[alejandra]:-}" ]]; then
        nix_formatter="alejandra"
    elif [[ -n "${AVAILABLE_FORMATTERS[nixfmt]:-}" ]]; then
        nix_formatter="nixfmt"
    else
        log_warn "No Nix formatter — install: nix-env -i alejandra"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "$nix_formatter" \
            "${nix_formatter} ${ALEJANDRA_OPTS} '${file}'" \
            "❄️" "${INDIGO}"
    done <<< "$files"
    printf "\n" >&2
}

# ── JSON FORMATTER ────────────────────────────────────────────────────────────
format_json() {
    section "📋" "JSON & JSONC Files (jq + prettier)" "$MINT"

    local files="${STAGED_BY_TYPE[json]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No JSON files staged"; return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        # JSONC files — use prettier (jq can't handle comments)
        if [[ "$file" == *.jsonc ]]; then
            if [[ -n "${AVAILABLE_FORMATTERS[prettier]:-}" ]]; then
                format_file "$file" "prettier" \
                    "prettier --write --parser json5 '${file}'" \
                    "📋" "${MINT}"
            fi
            continue
        fi

        # Regular JSON — validate and format with jq
        if [[ -n "${AVAILABLE_FORMATTERS[jq]:-}" ]]; then
            format_file "$file" "jq" \
                "jq --sort-keys '.' '${file}' > '${file}.tmp' && mv '${file}.tmp' '${file}'" \
                "📋" "${MINT}"
        elif [[ -n "${AVAILABLE_FORMATTERS[prettier]:-}" ]]; then
            format_file "$file" "prettier" \
                "prettier --write --parser json '${file}'" \
                "📋" "${MINT}"
        else
            log_skip "$(basename "$file") — no JSON formatter"
        fi

    done <<< "$files"
    printf "\n" >&2
}

# ── YAML FORMATTER ─────────────────────────────────────────────────────────────
format_yaml() {
    section "📝" "YAML Files (prettier + yamllint)" "$PEACH"

    local files="${STAGED_BY_TYPE[yaml]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No YAML files staged"; return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        if [[ -n "${AVAILABLE_FORMATTERS[prettier]:-}" ]]; then
            format_file "$file" "prettier" \
                "prettier --write --parser yaml '${file}'" \
                "📝" "${PEACH}"
        fi

    done <<< "$files"
    printf "\n" >&2

    # yamllint validation
    if [[ -n "${AVAILABLE_FORMATTERS[yamllint]:-}" ]]; then
        printf "\n  %s%sYAML Validation:%s\n" "$B" "$PEACH" "$R" >&2
        local cfg="${REPO_ROOT}/.yamllint.yml"
        local lint_errors=0

        while IFS= read -r file; do
            [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
            local cmd="yamllint"
            [[ -f "$cfg" ]] && cmd="yamllint -c $cfg"

            local output
            if ! output="$(${cmd} "$file" 2>&1)"; then
                ((lint_errors++)) || true
                echo "$output" | head -3 | while IFS= read -r line; do
                    printf "     %s│%s %s%s%s\n" "${PEACH}${D}" "$R" "${D}" "$line" "$R" >&2
                done
            fi
        done <<< "$files"

        if [[ $lint_errors -eq 0 ]]; then
            log_pass "yamllint: all YAML valid"
        else
            log_warn "yamllint: ${lint_errors} file(s) with issues"
        fi
    fi
}

# ── TOML FORMATTER ─────────────────────────────────────────────────────────────
format_toml() {
    section "⚙️" "TOML Files (taplo)" "$SAND"

    local files="${STAGED_BY_TYPE[toml]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No TOML files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[taplo]:-}" ]]; then
        log_skip "taplo not available — install: cargo install taplo-cli"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        format_file "$file" "taplo" \
            "taplo format '${file}'" \
            "⚙️" "${SAND}"
    done <<< "$files"
    printf "\n" >&2
}

# ── MARKDOWN FORMATTER ─────────────────────────────────────────────────────────
format_markdown() {
    section "📖" "Markdown Files (prettier + markdownlint)" "$LAVENDER"

    local files="${STAGED_BY_TYPE[markdown]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Markdown files staged"; return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        if [[ -n "${AVAILABLE_FORMATTERS[prettier]:-}" ]]; then
            format_file "$file" "prettier" \
                "prettier --write --parser markdown --prose-wrap always '${file}'" \
                "📖" "${LAVENDER}"
        fi

    done <<< "$files"
    printf "\n" >&2
}

# ── FISH FORMATTER ─────────────────────────────────────────────────────────────
format_fish() {
    section "🐟" "Fish Shell Files (fish --no-execute)" "$EMERALD"

    local files="${STAGED_BY_TYPE[fish]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No Fish files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[fish]:-}" ]]; then
        log_warn "fish not available — install Fish shell"
        return 0
    fi

    local errors=0
    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue

        local output
        if ! output="$(fish --no-execute "$file" 2>&1)"; then
            ((errors++)) || true
            printf "  %s✗%s 🐟 %-52s%s✗ SYNTAX ERR%s\n" \
                "${RED}${B}" "$R" "$file" "${RED}${B}" "$R" >&2
            echo "$output" | while IFS= read -r line; do
                printf "       %s%s%s\n" "${D}${RED}" "$line" "$R" >&2
            done
        else
            printf "  %s✓%s 🐟 %-52s%s✓ VALID%s\n" \
                "${GREEN}${B}" "$R" "$file" "${GREEN}${B}" "$R" >&2
        fi
    done <<< "$files"

    [[ $errors -eq 0 ]] && log_pass "Fish: all files syntactically valid" || \
                           log_fail "Fish: ${errors} syntax error(s)"
}

# ── CSS / SCSS FORMATTER ───────────────────────────────────────────────────────
format_css() {
    section "🎨" "CSS & SCSS Files (prettier)" "$ROSE"

    local files="${STAGED_BY_TYPE[css]:-}"
    if [[ -z "$files" ]]; then
        log_skip "No CSS/SCSS files staged"; return 0
    fi

    if [[ -z "${AVAILABLE_FORMATTERS[prettier]:-}" ]]; then
        log_warn "prettier not available"
        return 0
    fi

    local count=0
    local total; total="$(echo "$files" | grep -c . || echo 0)"

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue
        ((count++)) || true
        progress_bar "$count" "$total" "$(basename "$file")"

        local parser="css"
        [[ "$file" == *.scss ]] && parser="scss"
        [[ "$file" == *.less ]] && parser="less"

        format_file "$file" "prettier" \
            "prettier --write --parser ${parser} '${file}'" \
            "🎨" "${ROSE}"
    done <<< "$files"
    printf "\n" >&2
}

# ── TRAILING WHITESPACE & LINE ENDINGS ────────────────────────────────────────
fix_whitespace() {
    section "🔧" "Whitespace & Line Ending Fixes" "$SLATE"

    local all_staged
    all_staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
    [[ -z "$all_staged" ]] && return 0

    local fixed_ws=0 fixed_eol=0

    while IFS= read -r file; do
        [[ -z "$file" ]] || [[ ! -f "$file" ]] && continue

        # Skip binary files
        if file "$file" 2>/dev/null | grep -qiE "(binary|image|audio|video)"; then
            continue
        fi

        # Skip explicitly excluded extensions
        case "$file" in
            *.png|*.jpg|*.webp|*.gif|*.ico|*.ttf|*.woff*|*.eot) continue ;;
        esac

        local modified=false

        # Fix trailing whitespace
        if grep -qP '\s+$' "$file" 2>/dev/null; then
            sed -i 's/[[:space:]]*$//' "$file"
            ((fixed_ws++)) || true
            modified=true
        fi

        # Fix CRLF → LF (except Windows-specific files)
        case "$file" in
            *.bat|*.cmd|*.ps1) ;;
            *)
                if file "$file" 2>/dev/null | grep -q CRLF; then
                    sed -i 's/\r//' "$file"
                    ((fixed_eol++)) || true
                    modified=true
                fi
                ;;
        esac

        # Ensure newline at end of file
        if [[ -s "$file" ]]; then
            local last_char; last_char="$(tail -c1 "$file" | wc -c)"
            if [[ "$last_char" -eq 0 ]]; then
                echo >> "$file"
                modified=true
            fi
        fi

        if [[ "$modified" == "true" ]]; then
            git add "$file" 2>/dev/null || true
        fi

    done <<< "$all_staged"

    [[ $fixed_ws -gt 0 ]] && log_pass "Fixed trailing whitespace: ${fixed_ws} files"
    [[ $fixed_eol -gt 0 ]] && log_pass "Fixed CRLF line endings: ${fixed_eol} files"
    [[ $((fixed_ws + fixed_eol)) -eq 0 ]] && log_info "Whitespace: all files clean"
}

# ── FORMATTER STATS DISPLAY ────────────────────────────────────────────────────
print_formatter_stats() {
    if [[ ${#FORMATTER_STATS[@]} -eq 0 ]]; then
        return 0
    fi

    section "📊" "Formatter Activity" "$VIOLET"

    local -A STAT_COLORS=(
        ["shfmt"]="${LIME}"       ["stylua"]="${VIOLET}"
        ["black"]="${AMBER}"      ["ruff"]="${ORANGE}"
        ["prettier"]="${CYAN}"    ["alejandra"]="${INDIGO}"
        ["dart format"]="${OCEAN}" ["gofmt"]="${SKY}"
        ["rustfmt"]="${CORAL}"    ["jq"]="${MINT}"
        ["taplo"]="${SAND}"       ["isort"]="${TEAL}"
    )

    for formatter in "${!FORMATTER_STATS[@]}"; do
        local count="${FORMATTER_STATS[$formatter]}"
        local color="${STAT_COLORS[$formatter]:-$WHITE}"
        local bar_len=$(( count * 20 / (FILES_FORMATTED + 1) + 1 ))
        local bar; bar="$(printf '%*s' "$bar_len" '' | tr ' ' '▮')"

        printf "  %s%-16s%s %s%-20s%s %s%d file(s)%s\n" \
            "${color}${B}" "$formatter" "$R" \
            "${color}${D}" "$bar" "$R" \
            "${GOLD}" "$count" "$R" >&2
    done
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local dur; dur="$(format_dur "$(elapsed_ms)")"
    local total_processed=$(( FILES_FORMATTED + FILES_UNCHANGED + FILES_FAILED + FILES_SKIPPED ))

    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  🎨 FORMAT ENGINE REPORT — v${SCRIPT_VERSION}${R}${BG_MIDNIGHT}${GOLD}"
    box_d

    # Score bar
    local score_pct=100
    [[ $total_processed -gt 0 ]] && \
        score_pct=$(( (FILES_FORMATTED + FILES_UNCHANGED) * 100 / total_processed ))

    local score_bar score_color
    if   [[ $FILES_FAILED -eq 0 ]]; then score_color="${GREEN}${B}"
    elif [[ $FILES_FAILED -lt 3 ]]; then score_color="${YELLOW}${B}"
    else                                  score_color="${RED}${B}"
    fi

    local bar_filled=$(( score_pct * 36 / 100 ))
    local bar_empty=$(( 36 - bar_filled ))
    score_bar="${score_color}$(printf '%*s' "$bar_filled" '' | tr ' ' '█')${D}$(printf '%*s' "$bar_empty" '' | tr ' ' '░')${R}"

    box_l "$(printf "  %s%s%s  %s%d%%%s" \
        "" "$score_bar" "" \
        "${score_color}" "$score_pct" "$R$BG_MIDNIGHT$GOLD")"
    box_td

    box_l "$(printf "  %s✓  %-4s%s formatted   %s≡  %-4s%s unchanged   %s✗  %-4s%s failed   %s⏱ %s%s" \
        "${GREEN}${B}"  "$FILES_FORMATTED"  "$R$BG_MIDNIGHT$GOLD" \
        "${SLATE}${D}"  "$FILES_UNCHANGED"  "$R$BG_MIDNIGHT$GOLD" \
        "${RED}${B}"    "$FILES_FAILED"     "$R$BG_MIDNIGHT$GOLD" \
        "${CYAN}${D}"   "$dur"              "$R$BG_MIDNIGHT$GOLD")"

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        box_td
        box_l "${RED}${B}  FORMAT ERRORS:${R}${BG_MIDNIGHT}${GOLD}"
        for e in "${ERRORS[@]}"; do
            box_l "  ${RED}  ✗ ${e:0:$(( TERM_WIDTH-14 ))}${R}${BG_MIDNIGHT}${GOLD}"
        done
    fi

    if [[ ${#FORMATTED_FILES[@]} -gt 0 ]]; then
        box_td
        box_l "${LIME}${B}  AUTO-FORMATTED & RE-STAGED:${R}${BG_MIDNIGHT}${GOLD}"
        for file in "${!FORMATTED_FILES[@]}"; do
            local fmt="${FORMATTED_FILES[$file]}"
            box_l "  ${LIME}  ✓ ${file} ${D}(${fmt})${R}${BG_MIDNIGHT}${GOLD}"
        done
    fi

    box_td
    if [[ $FILES_FAILED -gt 0 ]]; then
        box_l "  ${YELLOW}${B}⚠️  Some files could not be formatted — check errors above${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}Backups saved to: ${BACKUP_DIR}${R}${BG_MIDNIGHT}${GOLD}"
    else
        box_l "  ${GREEN}${B}✓ All formatting complete — files re-staged automatically${R}${BG_MIDNIGHT}${GOLD}"
    fi
    box_b
    printf "\n" >&2
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  🎨 ASH DOTFILES v5.0 OMEGA — ULTRA FORMAT ENGINE${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  Auto-formatting 15+ languages with zero configuration${R}${BG_MIDNIGHT}${GOLD}"
    box_d
    box_l "$(printf "  %s%-18s%s %s%s%s" \
        "${CYAN}${B}" "Repository:" "$R$BG_MIDNIGHT$GOLD" \
        "${LAVENDER}" "$(basename "$REPO_ROOT")" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s%s" \
        "${CYAN}${B}" "Started:" "$R$BG_MIDNIGHT$GOLD" \
        "${PEACH}" "$(date '+%Y-%m-%d %H:%M:%S')" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s%s" \
        "${CYAN}${B}" "Backup Dir:" "$R$BG_MIDNIGHT$GOLD" \
        "${D}${SLATE}" "$BACKUP_DIR" "$R$BG_MIDNIGHT$GOLD")"
    box_b
    printf "\n" >&2
}

# ── CLEANUP ───────────────────────────────────────────────────────────────────
cleanup() {
    local exit_code=$?
    if [[ "$RESTORE_NEEDED" == "true" ]] && [[ $exit_code -ne 0 ]]; then
        log_restore "Restoring files due to error..."
        for file in "${!FORMATTED_FILES[@]}"; do
            restore_file "$file"
            git add "$file" 2>/dev/null || true
        done
    fi
}

trap cleanup EXIT

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    [[ "${ASH_SKIP_HOOKS:-}" == "true" ]] && exit 0
    [[ "${CI:-}" == "true" ]]             && exit 0

    init
    print_banner
    check_formatters || true
    collect_staged_files

    # Run all formatters
    format_shell
    format_lua
    format_python
    format_typescript
    format_dart
    format_rust
    format_go
    format_nix
    format_json
    format_yaml
    format_toml
    format_markdown
    format_fish
    format_css

    # Universal fixes
    fix_whitespace

    print_formatter_stats
    print_summary

    # Exit code: fail only if formatter errors (not for warnings)
    [[ $FILES_FAILED -gt 0 ]] && exit 1
    exit 0
}

main "$@"