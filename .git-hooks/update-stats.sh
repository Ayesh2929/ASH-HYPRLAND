#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 ASH DOTFILES v5.0 OMEGA — ULTRA STATS ENGINE                           ║
# ║  Collects · Analyzes · Visualizes repository statistics in real-time        ║
# ║  Runs post-commit to keep stats fresh and dashboards alive                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI MASTER PALETTE ───────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m";   readonly B="${ESC}[1m";   readonly D="${ESC}[2m"
readonly RED="${ESC}[31m";           readonly GREEN="${ESC}[32m"
readonly YELLOW="${ESC}[33m";        readonly CYAN="${ESC}[36m"
readonly WHITE="${ESC}[37m";         readonly ORANGE="${ESC}[38;5;208m"
readonly PURPLE="${ESC}[38;5;135m";  readonly LIME="${ESC}[38;5;154m"
readonly GOLD="${ESC}[38;5;220m";    readonly LAVENDER="${ESC}[38;5;183m"
readonly MINT="${ESC}[38;5;121m";    readonly PEACH="${ESC}[38;5;217m"
readonly ROSE="${ESC}[38;5;211m";    readonly TEAL="${ESC}[38;5;43m"
readonly CORAL="${ESC}[38;5;203m";   readonly CREAM="${ESC}[38;5;230m"
readonly SLATE="${ESC}[38;5;245m";   readonly AMBER="${ESC}[38;5;214m"
readonly EMERALD="${ESC}[38;5;120m"; readonly VIOLET="${ESC}[38;5;177m"
readonly CRIMSON="${ESC}[38;5;161m"; readonly INDIGO="${ESC}[38;5;105m"
readonly SKY="${ESC}[38;5;117m";     readonly OCEAN="${ESC}[38;5;38m"
readonly SAND="${ESC}[38;5;180m";    readonly CHERRY="${ESC}[38;5;197m"
readonly FOREST="${ESC}[38;5;28m";   readonly STEEL="${ESC}[38;5;67m"

readonly BG_MIDNIGHT="${ESC}[48;5;16m"
readonly BG_DARK="${ESC}[48;5;235m"
readonly BG_NAVY="${ESC}[48;5;17m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="update-stats"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"
readonly SCRIPT_START_MS="$(date +%s%3N)"
readonly TIMESTAMP_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly TIMESTAMP_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"

# Output paths
readonly STATS_FILE="${REPO_ROOT}/data/state/repo-stats.json"
readonly STATS_MD="${REPO_ROOT}/.github/stats/current.md"
readonly STATS_BADGE_DIR="${REPO_ROOT}/assets/badges"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-stats"
readonly LOG_FILE="${LOG_DIR}/stats-$(date +%s).log"
readonly CACHE_FILE="${LOG_DIR}/stats.cache"

# Cache TTL (seconds)
readonly CACHE_TTL=300

# ── STATE ─────────────────────────────────────────────────────────────────────
declare -A STATS=()
declare -A LANG_LINES=()
declare -A LANG_FILES=()
STATS_UPDATED=0
STATS_CACHED=0
STATS_FAILED=0

# ── INIT ──────────────────────────────────────────────────────────────────────
init() {
    mkdir -p "$LOG_DIR" \
             "$(dirname "$STATS_FILE")" \
             "$(dirname "$STATS_MD")" \
             "$STATS_BADGE_DIR"
    : > "$LOG_FILE"
}

now_ms()     { date +%s%3N; }
elapsed_ms() { echo $(( $(now_ms) - SCRIPT_START_MS )); }
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

stat_row() {
    local icon="$1" label="$2" value="$3" color="${4:-$GOLD}" extra="${5:-}"
    printf "  %s  %s%-30s%s %s%s%s %s%s%s\n" \
        "$icon" \
        "${D}${WHITE}" "$label" "$R" \
        "${color}${B}" "$value" "$R" \
        "${D}${SLATE}" "$extra" "$R" >&2
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  📊 ASH DOTFILES v5.0 OMEGA — STATS ENGINE${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  Real-time repository analytics & visualization${R}${BG_MIDNIGHT}${GOLD}"
    box_d
    box_l "$(printf "  %s%-16s%s %s%s%s" "${CYAN}${B}" "Timestamp:" \
        "$R$BG_MIDNIGHT$GOLD" "${PEACH}" "$TIMESTAMP_HUMAN" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-16s%s %s%s%s" "${CYAN}${B}" "Repo:" \
        "$R$BG_MIDNIGHT$GOLD" "${LAVENDER}" "$(basename "$REPO_ROOT")" "$R$BG_MIDNIGHT$GOLD")"
    box_b
    printf "\n" >&2
}

# ── CACHE CHECK ───────────────────────────────────────────────────────────────
check_cache() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi

    local cache_age
    cache_age="$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || \
                    stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0) ))"

    if [[ $cache_age -lt $CACHE_TTL ]]; then
        return 0
    fi

    return 1
}

# ── COLLECT FILE SYSTEM STATS ─────────────────────────────────────────────────
collect_file_stats() {
    section "📁" "File System Statistics" "$CYAN"

    local t_start; t_start="$(now_ms)"

    # Exclusion pattern for find
    local excl="-not -path '*/.git/*' -not -path '*/node_modules/*' \
                -not -path '*/data/cache/*' -not -path '*/backups/*' \
                -not -path '*/data/tmp/*' -not -path '*/.cache/*'"

    # Total files
    STATS[total_files]="$(eval "find '$REPO_ROOT' $excl -type f" | \
        wc -l | tr -d ' ')"
    stat_row "📄" "Total Files" "${STATS[total_files]}" "$GOLD"

    # Total directories
    STATS[total_dirs]="$(eval "find '$REPO_ROOT' $excl -type d" | \
        wc -l | tr -d ' ')"
    stat_row "📁" "Total Directories" "${STATS[total_dirs]}" "$CYAN"

    # Scripts
    STATS[total_scripts]="$(eval "find '$REPO_ROOT' $excl -name '*.sh'" | \
        wc -l | tr -d ' ')"
    stat_row "🐚" "Shell Scripts" "${STATS[total_scripts]}" "$LIME"

    # Lua files
    STATS[total_lua]="$(eval "find '$REPO_ROOT' $excl -name '*.lua'" | \
        wc -l | tr -d ' ')"
    stat_row "🌙" "Lua Files" "${STATS[total_lua]}" "$VIOLET"

    # Themes
    STATS[theme_count]="$(find "${REPO_ROOT}/themes/presets" \
        -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')"
    stat_row "🎨" "Theme Presets" "${STATS[theme_count]}" "$ROSE"

    # Plugins
    STATS[plugin_count]="$(find "${REPO_ROOT}/plugins/core" \
        "${REPO_ROOT}/plugins/integrations" \
        -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    stat_row "🔌" "Plugins" "${STATS[plugin_count]}" "$OCEAN"

    # Wallpapers
    STATS[wallpaper_count]="$(find "${REPO_ROOT}/wallpapers" \
        -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \
                   -o -name "*.gif" -o -name "*.avif" \) \
        2>/dev/null | wc -l | tr -d ' ')"
    stat_row "🖼️" "Wallpapers" "${STATS[wallpaper_count]}" "$SKY"

    # Doc pages
    STATS[doc_pages]="$(find "${REPO_ROOT}/docs" \
        -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    stat_row "📖" "Documentation Pages" "${STATS[doc_pages]}" "$LAVENDER"

    # CI workflows
    STATS[workflow_count]="$(find "${REPO_ROOT}/.github/workflows" \
        -name "*.yml" -type f 2>/dev/null | wc -l | tr -d ' ')"
    stat_row "🏗️" "CI/CD Workflows" "${STATS[workflow_count]}" "$AMBER"

    # Systemd services
    STATS[service_count]="$(find "${REPO_ROOT}/systemd" \
        -name "*.service" -type f 2>/dev/null | wc -l | tr -d ' ')"
    stat_row "⏱️" "Systemd Services" "${STATS[service_count]}" "$TEAL"

    # Repo size
    STATS[repo_size]="$(du -sh "$REPO_ROOT" 2>/dev/null | cut -f1)"
    stat_row "💾" "Repository Size" "${STATS[repo_size]}" "$PEACH"

    printf "  %s[collection: %s]%s\n" \
        "${D}${SLATE}" "$(format_dur "$(( $(now_ms) - t_start ))")" "$R" >&2
}

# ── COLLECT GIT STATS ─────────────────────────────────────────────────────────
collect_git_stats() {
    section "🌿" "Git Statistics" "$EMERALD"

    local t_start; t_start="$(now_ms)"

    STATS[total_commits]="$(git -C "$REPO_ROOT" \
        rev-list --count HEAD 2>/dev/null || echo "0")"
    stat_row "💾" "Total Commits" "${STATS[total_commits]}" "$GOLD"

    STATS[total_contributors]="$(git -C "$REPO_ROOT" \
        shortlog -sn --all 2>/dev/null | wc -l | tr -d ' ' || echo "1")"
    stat_row "👤" "Contributors" "${STATS[total_contributors]}" "$MINT"

    STATS[total_branches]="$(git -C "$REPO_ROOT" \
        branch -a 2>/dev/null | grep -c . || echo "1")"
    stat_row "🌿" "Branches" "${STATS[total_branches]}" "$LIME"

    STATS[total_tags]="$(git -C "$REPO_ROOT" \
        tag 2>/dev/null | wc -l | tr -d ' ' || echo "0")"
    stat_row "🏷️" "Tags / Releases" "${STATS[total_tags]}" "$AMBER"

    STATS[latest_tag]="$(git -C "$REPO_ROOT" \
        describe --tags --abbrev=0 2>/dev/null || echo "v5.0.0")"
    stat_row "🚀" "Latest Release" "${STATS[latest_tag]}" "$ROSE"

    STATS[last_commit_hash]="$(git -C "$REPO_ROOT" \
        rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    STATS[last_commit_date]="$(git -C "$REPO_ROOT" \
        log -1 --format='%cd' --date='format:%Y-%m-%d' 2>/dev/null || \
        date '+%Y-%m-%d')"
    STATS[last_commit_msg]="$(git -C "$REPO_ROOT" \
        log -1 --format='%s' 2>/dev/null | head -c 60 || echo "N/A")"
    STATS[last_commit_author]="$(git -C "$REPO_ROOT" \
        log -1 --format='%an' 2>/dev/null || echo "unknown")"

    stat_row "🔖" "Last Commit" "${STATS[last_commit_hash]}" "$TEAL" \
        "${STATS[last_commit_date]} by ${STATS[last_commit_author]}"

    # Weekly commit activity (last 8 weeks)
    local weekly_counts=()
    for i in 7 6 5 4 3 2 1 0; do
        local count
        count="$(git -C "$REPO_ROOT" log \
            --after="$(( i+1 )) weeks ago" \
            --before="${i} weeks ago" \
            --oneline 2>/dev/null | wc -l | tr -d ' ')"
        weekly_counts+=("$count")
    done
    STATS[weekly_activity]="$(IFS=,; echo "${weekly_counts[*]}")"

    # Commit frequency (commits per week average)
    local total_weeks=52
    STATS[commits_per_week]="$(( ${STATS[total_commits]} / total_weeks ))"
    stat_row "📈" "Avg Commits/Week" "${STATS[commits_per_week]}" "$VIOLET"

    # File additions/deletions
    STATS[total_additions]="$(git -C "$REPO_ROOT" \
        log --pretty=tformat: --numstat 2>/dev/null | \
        awk '{s+=$1} END {print s}' || echo "0")"
    STATS[total_deletions]="$(git -C "$REPO_ROOT" \
        log --pretty=tformat: --numstat 2>/dev/null | \
        awk '{s+=$2} END {print s}' || echo "0")"
    stat_row "📊" "Lines Added/Deleted" \
        "+${STATS[total_additions]} / -${STATS[total_deletions]}" "$CORAL"

    printf "  %s[collection: %s]%s\n" \
        "${D}${SLATE}" "$(format_dur "$(( $(now_ms) - t_start ))")" "$R" >&2
}

# ── COLLECT LOC STATS ─────────────────────────────────────────────────────────
collect_loc_stats() {
    section "📝" "Lines of Code Analysis" "$VIOLET"

    local t_start; t_start="$(now_ms)"

    # Language to extension mapping
    declare -A LANG_EXTS=(
        ["Shell"]="sh bash"
        ["Lua"]="lua"
        ["Python"]="py"
        ["TypeScript"]="ts tsx"
        ["JavaScript"]="js jsx mjs"
        ["Dart"]="dart"
        ["Rust"]="rs"
        ["Go"]="go"
        ["Nix"]="nix"
        ["JSON"]="json jsonc"
        ["YAML"]="yml yaml"
        ["TOML"]="toml"
        ["Markdown"]="md"
        ["Fish"]="fish"
        ["CSS/SCSS"]="css scss less"
        ["Rasi"]="rasi"
        ["KDL"]="kdl"
        ["Yuck"]="yuck"
        ["QML"]="qml"
    )

    declare -A LANG_COLORS=(
        ["Shell"]="${LIME}"      ["Lua"]="${VIOLET}"    ["Python"]="${AMBER}"
        ["TypeScript"]="${CYAN}" ["JavaScript"]="${GOLD}" ["Dart"]="${OCEAN}"
        ["Rust"]="${CORAL}"      ["Go"]="${SKY}"        ["Nix"]="${INDIGO}"
        ["JSON"]="${MINT}"       ["YAML"]="${PEACH}"    ["TOML"]="${SAND}"
        ["Markdown"]="${LAVENDER}" ["Fish"]="${EMERALD}" ["CSS/SCSS"]="${ROSE}"
        ["Rasi"]="${TEAL}"       ["KDL"]="${STEEL}"     ["Yuck"]="${FOREST}"
        ["QML"]="${CHERRY}"
    )

    declare -A LANG_ICONS=(
        ["Shell"]="🐚"  ["Lua"]="🌙"     ["Python"]="🐍"
        ["TypeScript"]="⚡" ["JavaScript"]="📜" ["Dart"]="🎯"
        ["Rust"]="🦀"   ["Go"]="🐹"      ["Nix"]="❄️"
        ["JSON"]="📋"   ["YAML"]="📝"    ["TOML"]="⚙️"
        ["Markdown"]="📖" ["Fish"]="🐟"  ["CSS/SCSS"]="🎨"
        ["Rasi"]="🚀"   ["KDL"]="🔷"    ["Yuck"]="🔺"
        ["QML"]="🔵"
    )

    local total_loc=0
    local total_files_counted=0
    declare -A lang_data=()

    for lang in "${!LANG_EXTS[@]}"; do
        local exts="${LANG_EXTS[$lang]}"
        local lang_lines=0
        local lang_file_count=0

        for ext in $exts; do
            while IFS= read -r -d '' file; do
                local line_count
                line_count="$(wc -l < "$file" 2>/dev/null | tr -d ' ' || echo 0)"
                lang_lines=$(( lang_lines + line_count ))
                ((lang_file_count++)) || true
                ((total_files_counted++)) || true
            done < <(find "$REPO_ROOT" \
                -not -path '*/.git/*' \
                -not -path '*/node_modules/*' \
                -not -path '*/data/cache/*' \
                -not -path '*/backups/*' \
                -name "*.${ext}" -type f \
                -print0 2>/dev/null || true)
        done

        if [[ $lang_lines -gt 0 ]]; then
            total_loc=$(( total_loc + lang_lines ))
            LANG_LINES["$lang"]="$lang_lines"
            LANG_FILES["$lang"]="$lang_file_count"
            lang_data["$lang"]="$lang_lines"
        fi
    done

    STATS[total_loc]="$total_loc"
    STATS[total_files_counted]="$total_files_counted"

    # Sort by LOC and display top languages
    local sorted_langs
    sorted_langs="$(for k in "${!lang_data[@]}"; do
        echo "${lang_data[$k]} $k"
    done | sort -rn | head -15)"

    printf "\n" >&2

    local max_lines=1
    while IFS=' ' read -r lines _; do
        [[ $lines -gt $max_lines ]] && max_lines=$lines
    done <<< "$sorted_langs"

    while IFS=' ' read -r lines lang; do
        [[ -z "$lang" ]] && continue

        local color="${LANG_COLORS[$lang]:-$WHITE}"
        local icon="${LANG_ICONS[$lang]:-📄}"
        local files="${LANG_FILES[$lang]:-0}"
        local bar_len=$(( lines * 30 / (max_lines + 1) + 1 ))
        local bar; bar="$(printf '%*s' "$bar_len" '' | tr ' ' '▮')"
        local pct=$(( lines * 100 / (total_loc + 1) ))

        printf "  %s  %s%-14s%s %s%-32s%s %s%8s%s %s%d%%%s  %s%d files%s\n" \
            "$icon" \
            "${color}${B}" "$lang" "$R" \
            "${color}${D}" "$bar" "$R" \
            "${GOLD}${B}" "$(printf '%d' "$lines")" "$R" \
            "${D}${SLATE}" "$pct" "$R" \
            "${D}" "$files" "$R" >&2

    done <<< "$sorted_langs"

    printf "\n" >&2
    printf "  %s%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" \
        "${D}${SLATE}" "" "$R" >&2
    printf "  %s📊%s %s%-30s%s %s%s LOC%s  %s%d files%s\n" \
        "" "$R" \
        "${GOLD}${B}" "TOTAL" "$R" \
        "${GOLD}${B}" "$(printf '%d' "$total_loc")" "$R" \
        "${D}${SLATE}" "$total_files_counted" "$R" >&2

    printf "  %s[collection: %s]%s\n" \
        "${D}${SLATE}" "$(format_dur "$(( $(now_ms) - t_start ))")" "$R" >&2
}

# ── COLLECT HEALTH STATS ──────────────────────────────────────────────────────
collect_health_stats() {
    section "🏥" "Repository Health" "$EMERALD"

    # Stale branches check
    local stale_branches=0
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        local last_commit_date
        last_commit_date="$(git log -1 --format='%ct' "$branch" 2>/dev/null || echo 0)"
        local days_old=$(( ($(date +%s) - last_commit_date) / 86400 ))
        [[ $days_old -gt 90 ]] && ((stale_branches++)) || true
    done < <(git branch -r 2>/dev/null | grep -v HEAD | head -20 || true)

    STATS[stale_branches]="$stale_branches"

    local health_score=100

    # Check for large files
    local large_files
    large_files="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -size +5M \
        -type f 2>/dev/null | wc -l | tr -d ' ')"
    STATS[large_files]="$large_files"
    [[ $large_files -gt 0 ]] && health_score=$(( health_score - large_files * 5 ))

    # Check test coverage ratio
    local test_files
    test_files="$(find "${REPO_ROOT}/tests" \
        -name "test-*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')"
    local src_files
    src_files="$(find "${REPO_ROOT}/ash-cli" \
        -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')"
    STATS[test_files]="$test_files"
    STATS[src_files]="$src_files"

    local coverage_ratio=0
    [[ $src_files -gt 0 ]] && coverage_ratio=$(( test_files * 100 / src_files ))
    STATS[test_coverage_ratio]="$coverage_ratio"

    # Check docs completeness
    local has_readme=0 has_changelog=0 has_contrib=0 has_license=0 has_security=0
    [[ -f "${REPO_ROOT}/README.md" ]]      && has_readme=1
    [[ -f "${REPO_ROOT}/CHANGELOG.md" ]]   && has_changelog=1
    [[ -f "${REPO_ROOT}/CONTRIBUTING.md" ]] && has_contrib=1
    [[ -f "${REPO_ROOT}/LICENSE" ]]         && has_license=1
    [[ -f "${REPO_ROOT}/SECURITY.md" ]]    && has_security=1

    local docs_score=$(( has_readme + has_changelog + has_contrib + \
                         has_license + has_security ))
    STATS[docs_completeness]="$(( docs_score * 20 ))"
    [[ $docs_score -lt 5 ]] && health_score=$(( health_score - (5-docs_score)*10 ))

    [[ $health_score -lt 0 ]] && health_score=0
    STATS[health_score]="$health_score"

    # Render health indicators
    local health_color
    if   [[ $health_score -ge 90 ]]; then health_color="${GREEN}${B}"
    elif [[ $health_score -ge 70 ]]; then health_color="${AMBER}${B}"
    elif [[ $health_score -ge 50 ]]; then health_color="${ORANGE}${B}"
    else                                   health_color="${RED}${B}"
    fi

    # Health bar
    local bar_filled=$(( health_score * 40 / 100 ))
    local bar_empty=$(( 40 - bar_filled ))
    local health_bar
    health_bar="${health_color}$(printf '%*s' "$bar_filled" '' | tr ' ' '█')${D}${SLATE}$(printf '%*s' "$bar_empty" '' | tr ' ' '░')${R}"

    printf "\n  %s %sHealth Score: %s%d/100%s\n\n" \
        "🏥" "${D}" "${health_color}" "$health_score" "$R" >&2
    printf "  %s\n\n" "$health_bar" >&2

    stat_row "🧪" "Test Files" "${STATS[test_files]}" "$MINT" \
        "vs ${STATS[src_files]} source files (${coverage_ratio}% coverage)"
    stat_row "📚" "Docs Completeness" "${STATS[docs_completeness]}%" "$LAVENDER" \
        "${docs_score}/5 key files present"
    stat_row "📦" "Large Files (>5MB)" "${STATS[large_files]}" \
        "$([[ $large_files -gt 0 ]] && echo "${AMBER}${B}" || echo "${GREEN}${B}")"
    stat_row "🌿" "Stale Branches (>90d)" "${STATS[stale_branches]}" \
        "$([[ $stale_branches -gt 5 ]] && echo "${AMBER}" || echo "${GREEN}")"
}

# ── SPARKLINE GENERATOR ───────────────────────────────────────────────────────
generate_sparkline() {
    local data="$1"  # comma-separated values
    local blocks=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

    IFS=',' read -ra values <<< "$data"

    local max=0
    for v in "${values[@]}"; do
        [[ $v -gt $max ]] && max=$v
    done
    [[ $max -eq 0 ]] && max=1

    local sparkline=""
    for v in "${values[@]}"; do
        local idx=$(( v * 7 / (max + 1) ))
        sparkline+="${blocks[$idx]}"
    done
    echo "$sparkline"
}

# ── WRITE JSON STATS ──────────────────────────────────────────────────────────
write_json_stats() {
    section "💾" "Writing Statistics Files" "$TEAL"

    if ! command -v jq &>/dev/null; then
        printf "  %s⚠%s jq not available — writing raw JSON manually\n" \
            "${YELLOW}" "$R" >&2
    fi

    local weekly_sparkline
    weekly_sparkline="$(generate_sparkline "${STATS[weekly_activity]:-0,0,0,0,0,0,0,0}")"

    # Build language stats JSON
    local lang_json="{}"
    for lang in "${!LANG_LINES[@]}"; do
        local escaped_lang; escaped_lang="${lang// /_}"
        if command -v jq &>/dev/null; then
            lang_json="$(echo "$lang_json" | jq \
                --arg lang "$lang" \
                --argjson lines "${LANG_LINES[$lang]:-0}" \
                --argjson files "${LANG_FILES[$lang]:-0}" \
                '.[$lang] = {lines: $lines, files: $files}')"
        fi
    done

    # Write main stats JSON
    cat > "$STATS_FILE" <<JSONEOF
{
  "_meta": {
    "version": "${SCRIPT_VERSION}",
    "generated": "${TIMESTAMP_ISO}",
    "generator": "ASH Stats Engine v${SCRIPT_VERSION}"
  },
  "repository": {
    "name": "$(basename "$REPO_ROOT")",
    "path": "${REPO_ROOT}"
  },
  "files": {
    "total": ${STATS[total_files]:-0},
    "directories": ${STATS[total_dirs]:-0},
    "scripts": ${STATS[total_scripts]:-0},
    "lua": ${STATS[total_lua]:-0},
    "doc_pages": ${STATS[doc_pages]:-0},
    "wallpapers": ${STATS[wallpaper_count]:-0},
    "workflows": ${STATS[workflow_count]:-0},
    "services": ${STATS[service_count]:-0},
    "size": "${STATS[repo_size]:-N/A}"
  },
  "content": {
    "themes": ${STATS[theme_count]:-0},
    "plugins": ${STATS[plugin_count]:-0}
  },
  "code": {
    "total_loc": ${STATS[total_loc]:-0},
    "languages": ${lang_json}
  },
  "git": {
    "commits": ${STATS[total_commits]:-0},
    "contributors": ${STATS[total_contributors]:-0},
    "branches": ${STATS[total_branches]:-0},
    "tags": ${STATS[total_tags]:-0},
    "latest_release": "${STATS[latest_tag]:-v5.0.0}",
    "commits_per_week": ${STATS[commits_per_week]:-0},
    "weekly_activity": "${STATS[weekly_activity]:-}",
    "weekly_sparkline": "${weekly_sparkline}",
    "last_commit": {
      "hash": "${STATS[last_commit_hash]:-unknown}",
      "date": "${STATS[last_commit_date]:-${TIMESTAMP_ISO}}",
      "message": "${STATS[last_commit_msg]:-}",
      "author": "${STATS[last_commit_author]:-}"
    }
  },
  "health": {
    "score": ${STATS[health_score]:-0},
    "docs_completeness": ${STATS[docs_completeness]:-0},
    "test_coverage_ratio": ${STATS[test_coverage_ratio]:-0},
    "test_files": ${STATS[test_files]:-0},
    "src_files": ${STATS[src_files]:-0},
    "large_files": ${STATS[large_files]:-0},
    "stale_branches": ${STATS[stale_branches]:-0}
  }
}
JSONEOF

    printf "  %s✓%s JSON stats written: %s%s%s\n" \
        "${GREEN}${B}" "$R" "${D}${SLATE}" "$STATS_FILE" "$R" >&2
    ((STATS_UPDATED++)) || true
}

# ── WRITE MARKDOWN STATS ──────────────────────────────────────────────────────
write_markdown_stats() {
    local weekly_sparkline
    weekly_sparkline="$(generate_sparkline "${STATS[weekly_activity]:-0,0,0,0,0,0,0,0}")"

    mkdir -p "$(dirname "$STATS_MD")"

    cat > "$STATS_MD" <<MDEOF
<!-- ASH Stats Engine v${SCRIPT_VERSION} — auto-generated ${TIMESTAMP_HUMAN} -->
<!-- DO NOT EDIT MANUALLY -->

## 📊 Repository Statistics

> **Last updated:** ${TIMESTAMP_HUMAN} UTC
> **Generated by:** ASH Stats Engine v${SCRIPT_VERSION}

### 🗂️ Repository Scale

| Metric | Value |
|--------|-------|
| 📄 Total Files | **${STATS[total_files]:-0}** |
| 📁 Directories | **${STATS[total_dirs]:-0}** |
| 📝 Lines of Code | **${STATS[total_loc]:-0}+** |
| 🎨 Themes | **${STATS[theme_count]:-0}+** |
| 🔌 Plugins | **${STATS[plugin_count]:-0}+** |
| 🖼️ Wallpapers | **${STATS[wallpaper_count]:-0}** |
| 📖 Doc Pages | **${STATS[doc_pages]:-0}** |
| ⏱️ Services | **${STATS[service_count]:-0}** |
| 🏗️ Workflows | **${STATS[workflow_count]:-0}** |
| 💾 Size | **${STATS[repo_size]:-N/A}** |

### 🌿 Git Activity

| Metric | Value |
|--------|-------|
| 💾 Commits | **${STATS[total_commits]:-0}** |
| 👤 Contributors | **${STATS[total_contributors]:-0}** |
| 🌿 Branches | **${STATS[total_branches]:-0}** |
| 🏷️ Latest Release | **${STATS[latest_tag]:-v5.0.0}** |
| 📈 Avg Commits/Week | **${STATS[commits_per_week]:-0}** |
| 📉 Weekly Activity | \`${weekly_sparkline}\` |
| 🔖 Last Commit | \`${STATS[last_commit_hash]:-?}\` ${STATS[last_commit_date]:-} |

### 🏥 Health Score

\`\`\`
Score: ${STATS[health_score]:-0}/100
Docs:  ${STATS[docs_completeness]:-0}% complete
Tests: ${STATS[test_coverage_ratio]:-0}% coverage ratio
\`\`\`

### 📝 Language Breakdown

| Language | LOC | Files |
|----------|-----|-------|
MDEOF

    # Add language rows sorted by LOC
    for lang in "${!LANG_LINES[@]}"; do
        printf "| %s | %s | %s |\n" \
            "$lang" "${LANG_LINES[$lang]}" "${LANG_FILES[$lang]:-0}"
    done | sort -t'|' -k3 -rn >> "$STATS_MD"

    echo "" >> "$STATS_MD"
    echo "---" >> "$STATS_MD"
    printf "*Auto-generated by [ASH Stats Engine](https://github.com) v%s*\n" \
        "$SCRIPT_VERSION" >> "$STATS_MD"

    printf "  %s✓%s Markdown stats written: %s%s%s\n" \
        "${GREEN}${B}" "$R" "${D}${SLATE}" "$STATS_MD" "$R" >&2
}

# ── UPDATE CACHE ──────────────────────────────────────────────────────────────
update_cache() {
    local cache_data=""
    for key in "${!STATS[@]}"; do
        cache_data+="${key}=${STATS[$key]}"$'\n'
    done
    echo "$cache_data" > "$CACHE_FILE"
    printf "  %s✓%s Cache updated (%s%s%s)\n" \
        "${GREEN}${B}" "$R" "${D}${SLATE}" "$CACHE_FILE" "$R" >&2
}

# ── LIVE DASHBOARD ────────────────────────────────────────────────────────────
print_dashboard() {
    section "📊" "Live Statistics Dashboard" "$GOLD"

    local weekly_sparkline
    weekly_sparkline="$(generate_sparkline "${STATS[weekly_activity]:-0,0,0,0,0,0,0,0}")"

    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  📊 ASH DOTFILES — LIVE STATS DASHBOARD${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  ${TIMESTAMP_HUMAN} UTC${R}${BG_MIDNIGHT}${GOLD}"
    box_d

    box_l "$(printf "  %s%-20s%s%s%-12s%s  %s%-20s%s%s%-12s%s" \
        "${D}${WHITE}" "🎨 Themes:"     "$R$BG_MIDNIGHT$GOLD" "${ROSE}${B}"    "${STATS[theme_count]:-0}+"  "$R$BG_MIDNIGHT$GOLD" \
        "${D}${WHITE}" "🔌 Plugins:"    "$R$BG_MIDNIGHT$GOLD" "${OCEAN}${B}"   "${STATS[plugin_count]:-0}+" "$R$BG_MIDNIGHT$GOLD")"

    box_l "$(printf "  %s%-20s%s%s%-12s%s  %s%-20s%s%s%-12s%s" \
        "${D}${WHITE}" "📄 Files:"      "$R$BG_MIDNIGHT$GOLD" "${GOLD}${B}"    "${STATS[total_files]:-0}"   "$R$BG_MIDNIGHT$GOLD" \
        "${D}${WHITE}" "📝 LOC:"        "$R$BG_MIDNIGHT$GOLD" "${VIOLET}${B}"  "${STATS[total_loc]:-0}+"    "$R$BG_MIDNIGHT$GOLD")"

    box_l "$(printf "  %s%-20s%s%s%-12s%s  %s%-20s%s%s%-12s%s" \
        "${D}${WHITE}" "💾 Commits:"    "$R$BG_MIDNIGHT$GOLD" "${EMERALD}${B}" "${STATS[total_commits]:-0}" "$R$BG_MIDNIGHT$GOLD" \
        "${D}${WHITE}" "👤 Authors:"    "$R$BG_MIDNIGHT$GOLD" "${MINT}${B}"    "${STATS[total_contributors]:-0}" "$R$BG_MIDNIGHT$GOLD")"

    box_l "$(printf "  %s%-20s%s%s%-12s%s  %s%-20s%s%s%-12s%s" \
        "${D}${WHITE}" "🏷️ Release:"    "$R$BG_MIDNIGHT$GOLD" "${AMBER}${B}"   "${STATS[latest_tag]:-?}"   "$R$BG_MIDNIGHT$GOLD" \
        "${D}${WHITE}" "🏥 Health:"     "$R$BG_MIDNIGHT$GOLD" \
        "$([[ ${STATS[health_score]:-0} -ge 80 ]] && echo "${GREEN}${B}" || echo "${AMBER}${B}")" \
        "${STATS[health_score]:-0}/100" "$R$BG_MIDNIGHT$GOLD")"

    box_td
    box_l "$(printf "  %s%-22s%s %s%s%s" \
        "${D}${WHITE}" "📈 Weekly commits:" "$R$BG_MIDNIGHT$GOLD" \
        "${CYAN}${B}" "$weekly_sparkline  (8 weeks)" "$R$BG_MIDNIGHT$GOLD")"

    box_td
    box_l "$(printf "  %s🔖 Last:%s %s%s%s • %s%s%s" \
        "${D}${WHITE}" "$R$BG_MIDNIGHT$GOLD" \
        "${PEACH}${B}" "${STATS[last_commit_hash]:-?}" "$R$BG_MIDNIGHT$GOLD" \
        "${D}" "${STATS[last_commit_msg]:0:40}..." "$R$BG_MIDNIGHT$GOLD")"

    box_b
    printf "\n" >&2
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local dur; dur="$(format_dur "$(elapsed_ms)")"

    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  📊 STATS UPDATE COMPLETE${R}${BG_MIDNIGHT}${GOLD}"
    box_td
    box_l "$(printf "  %s✓ %-4s%s written   %s↷ %-4s%s cached   %s✗ %-4s%s errors   %s⏱ %s%s" \
        "${GREEN}${B}"  "$STATS_UPDATED"  "$R$BG_MIDNIGHT$GOLD" \
        "${SLATE}${D}"  "$STATS_CACHED"   "$R$BG_MIDNIGHT$GOLD" \
        "${RED}${B}"    "$STATS_FAILED"   "$R$BG_MIDNIGHT$GOLD" \
        "${CYAN}${D}"   "$dur"            "$R$BG_MIDNIGHT$GOLD")"
    box_td
    box_l "  ${D}${SLATE}JSON:     ${STATS_FILE}${R}${BG_MIDNIGHT}${GOLD}"
    box_l "  ${D}${SLATE}Markdown: ${STATS_MD}${R}${BG_MIDNIGHT}${GOLD}"
    box_b
    printf "\n" >&2
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    [[ "${ASH_SKIP_HOOKS:-}" == "true" ]] && exit 0

    # Parse arguments
    local force=false quick=false dashboard_only=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)      force=true ;;
            --quick)      quick=true ;;
            --dashboard)  dashboard_only=true ;;
            *) echo "Unknown option: $1" >&2 ;;
        esac
        shift
    done

    init
    print_banner

    # Check cache (skip heavy collection if recent)
    if [[ "$force" != "true" ]] && check_cache; then
        printf "  %s⚡%s Using cached stats (< %ds old)\n" \
            "${CYAN}${B}" "$R" "$CACHE_TTL" >&2
        ((STATS_CACHED++)) || true
        if [[ -f "$STATS_FILE" ]] && command -v jq &>/dev/null; then
            # Load from cache
            while IFS='=' read -r key value; do
                [[ -z "$key" ]] && continue
                STATS["$key"]="$value"
            done < "$CACHE_FILE" 2>/dev/null || true
        fi
        print_dashboard
        print_summary
        exit 0
    fi

    if [[ "$dashboard_only" == "true" ]]; then
        collect_file_stats
        collect_git_stats
        print_dashboard
        exit 0
    fi

    # Full collection
    collect_file_stats
    collect_git_stats
    [[ "$quick" != "true" ]] && collect_loc_stats
    collect_health_stats

    # Write outputs
    write_json_stats
    write_markdown_stats
    update_cache

    print_dashboard
    print_summary
}

main "$@"