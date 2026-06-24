#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Theme Picker Script                               ║
# ║                                                                              ║
# ║  Complete theme management via Rofi custom mode. Browse, preview, apply,   ║
# ║  favorite, export themes and generate new ones via AI.                      ║
# ║                                                                              ║
# ║  Theme directory structure:                                                  ║
# ║  ~/.local/share/ash-dotfiles/themes/                                        ║
# ║  ├── dark/catppuccin-mocha/theme.conf                                       ║
# ║  ├── dark/catppuccin-mocha/colors.json                                      ║
# ║  ├── dark/catppuccin-mocha/metadata.json                                    ║
# ║  └── dark/catppuccin-mocha/preview.webp                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly THEMES_DIR="${HOME}/.local/share/ash-dotfiles/themes"
readonly BUILTIN_DIR="${HOME}/.config/ash-dotfiles/themes/presets"
readonly CURRENT_THEME_FILE="${HOME}/.local/state/ash-dotfiles/current-theme"
readonly FAVORITES_FILE="${HOME}/.local/share/ash-dotfiles/theme-favorites.txt"
readonly HISTORY_FILE="${HOME}/.local/share/ash-dotfiles/theme-history.txt"
readonly PREVIEW_TIMEOUT=5          # Seconds for live preview
readonly MAX_THEMES=300

# ══════════════════════════════════════════════════════════════════════════════
# §02  THEME DISCOVERY & METADATA
# ══════════════════════════════════════════════════════════════════════════════

# Theme category → emoji icon
category_icon() {
    case "${1,,}" in
        dark)       echo "🌑" ;;
        light)      echo "☀" ;;
        pastel)     echo "🌸" ;;
        neon)       echo "⚡" ;;
        nature)     echo "🌿" ;;
        space)      echo "🚀" ;;
        anime)      echo "🎌" ;;
        retro)      echo "📼" ;;
        gaming)     echo "🎮" ;;
        minimal)    echo "◻" ;;
        gradient)   echo "🎨" ;;
        seasonal)   echo "🍂" ;;
        mood)       echo "🌊" ;;
        special)    echo "✨" ;;
        generated)  echo "🤖" ;;
        *)          echo "🎨" ;;
    esac
}

# Accent color → colored dot
accent_dot() {
    local accent="${1,,}"
    case "$accent" in
        mauve|purple)   echo "🟣" ;;
        blue)           echo "🔵" ;;
        green)          echo "🟢" ;;
        red)            echo "🔴" ;;
        yellow|orange)  echo "🟡" ;;
        pink)           echo "🩷" ;;
        teal|cyan)      echo "🩵" ;;
        white)          echo "⚪" ;;
        black)          echo "⚫" ;;
        *)              echo "🔮" ;;
    esac
}

get_current_theme() {
    cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "catppuccin-mocha"
}

get_all_themes() {
    local -a themes=()

    # Scan builtin preset directories
    for category_dir in "${BUILTIN_DIR}"/*/*/; do
        local theme_dir="${category_dir%/}"
        local theme_name
        theme_name=$(basename "$theme_dir")

        # Read metadata if available
        local meta_file="${theme_dir}/metadata.json"
        if [[ -f "$meta_file" ]]; then
            local family variant mode accent
            family=$(jq -r '.family // "Unknown"'  "$meta_file" 2>/dev/null || echo "Unknown")
            variant=$(jq -r '.variant // ""'         "$meta_file" 2>/dev/null || echo "")
            mode=$(   jq -r '.mode // "dark"'        "$meta_file" 2>/dev/null || echo "dark")
            accent=$( jq -r '.accent // ""'          "$meta_file" 2>/dev/null || echo "")

            themes+=("${theme_name}|${family}|${mode}|${accent}|${theme_dir}")
        else
            # Guess from path
            local category
            category=$(basename "$(dirname "$theme_dir")")
            themes+=("${theme_name}|${theme_name}|${category}||${theme_dir}")
        fi
    done

    # Scan user themes
    for theme_dir in "${THEMES_DIR}"/*/*/; do
        [[ -d "$theme_dir" ]] || continue
        local theme_name
        theme_name=$(basename "${theme_dir%/}")
        local meta_file="${theme_dir}/metadata.json"

        if [[ -f "$meta_file" ]]; then
            local family mode accent
            family=$(jq -r '.family // "Custom"' "$meta_file" 2>/dev/null || echo "Custom")
            mode=$(   jq -r '.mode // "dark"'    "$meta_file" 2>/dev/null || echo "dark")
            accent=$( jq -r '.accent // ""'      "$meta_file" 2>/dev/null || echo "")
            themes+=("${theme_name}|${family}|${mode}|${accent}|${theme_dir}")
        else
            themes+=("${theme_name}|Custom|dark||${theme_dir}")
        fi
    done

    printf '%s\n' "${themes[@]}"
}

get_fallback_themes() {
    # Hardcoded comprehensive theme list when no theme files exist
    cat << 'THEMES'
catppuccin-mocha|Catppuccin|dark|mauve
catppuccin-macchiato|Catppuccin|dark|mauve
catppuccin-frappe|Catppuccin|dark|mauve
catppuccin-latte|Catppuccin|light|blue
tokyo-night|Independent|dark|blue
tokyo-night-storm|Independent|dark|blue
tokyo-night-moon|Independent|dark|blue
gruvbox-dark|Gruvbox|dark|orange
gruvbox-dark-hard|Gruvbox|dark|orange
gruvbox-material|Gruvbox|dark|orange
gruvbox-light|Gruvbox|light|orange
nord|Nordic|dark|blue
dracula|Dracula|dark|purple
dracula-pro|Dracula|dark|purple
one-dark|One|dark|blue
one-dark-pro|One|dark|blue
one-light|One|light|blue
everforest-dark|Everforest|dark|green
everforest-light|Everforest|light|green
kanagawa-wave|Kanagawa|dark|teal
kanagawa-dragon|Kanagawa|dark|teal
rose-pine|Rosé Pine|dark|pink
rose-pine-moon|Rosé Pine|dark|pink
rose-pine-dawn|Rosé Pine|light|pink
material-ocean|Material|dark|teal
material-palenight|Material|dark|purple
ayu-dark|Ayu|dark|orange
ayu-mirage|Ayu|dark|orange
ayu-light|Ayu|light|orange
solarized-dark|Solarized|dark|cyan
solarized-light|Solarized|light|cyan
nightfox|Nightfox|dark|blue
carbonfox|Nightfox|dark|blue
oxocarbon|IBM|dark|teal
cyberpunk-2077|Neon|neon|yellow
synthwave-84|Neon|neon|purple
matrix-green|Neon|neon|green
tron-legacy|Neon|neon|cyan
outrun|Neon|neon|purple
forest-deep|Nature|dark|green
ocean-dark|Nature|dark|blue
aurora-borealis|Nature|dark|teal
sakura-spring|Anime|pastel|pink
ghibli-spirited|Anime|pastel|teal
evangelion-unit-01|Anime|dark|purple
lofi-girl|Mood|pastel|blue
vaporwave|Retro|neon|purple
8bit-gameboy|Retro|dark|green
monochrome|Minimal|dark|white
pure-black|Minimal|dark|black
zen|Minimal|dark|white
THEMES
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  FAVORITES MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

ensure_favorites() {
    mkdir -p "$(dirname "$FAVORITES_FILE")"
    touch "$FAVORITES_FILE" 2>/dev/null || true
}

is_favorite() {
    local theme="$1"
    ensure_favorites
    grep -qxF "$theme" "$FAVORITES_FILE" 2>/dev/null
}

toggle_favorite() {
    local theme="$1"
    ensure_favorites

    if is_favorite "$theme"; then
        local tmp
        tmp=$(mktemp)
        grep -vxF "$theme" "$FAVORITES_FILE" > "$tmp" 2>/dev/null || true
        mv "$tmp" "$FAVORITES_FILE"
        notify_tp "★ Unfavorited" "$theme" "low"
    else
        echo "$theme" >> "$FAVORITES_FILE"
        notify_tp "★ Favorited" "$theme" "low"
    fi
}

get_favorites() {
    ensure_favorites
    cat "$FAVORITES_FILE" 2>/dev/null | head -50 || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  THEME APPLICATION
# ══════════════════════════════════════════════════════════════════════════════

apply_theme() {
    local theme_name="$1"
    local silent="${2:-false}"

    notify_tp "󰌁 Applying theme" "$theme_name" "low"

    # Use ASH CLI if available
    if command -v ash &>/dev/null; then
        ash theme apply "$theme_name" --silent &>/dev/null && {
            echo "$theme_name" > "$CURRENT_THEME_FILE"
            add_to_history "$theme_name"
            $silent || notify_tp "󰌁 Theme applied" "$theme_name"
            return 0
        }
    fi

    # Direct application fallback
    echo "$theme_name" > "$CURRENT_THEME_FILE"
    add_to_history "$theme_name"

    # Reload waybar colors
    pkill -SIGUSR2 waybar 2>/dev/null || true

    # Reload hyprland colors
    hyprctl reload 2>/dev/null || true

    $silent || notify_tp "󰌁 Theme applied" "$theme_name (fallback mode)"
}

preview_theme() {
    local theme_name="$1"
    notify_tp "󱇲 Preview: $theme_name" "Previewing for ${PREVIEW_TIMEOUT}s…" "low"

    # Apply temporarily
    if command -v ash &>/dev/null; then
        ash theme apply "$theme_name" --preview --timeout "$PREVIEW_TIMEOUT" &>/dev/null || true
    else
        notify_tp "Preview unavailable" "ASH CLI required for preview" "normal"
    fi
}

add_to_history() {
    local theme="$1"
    mkdir -p "$(dirname "$HISTORY_FILE")"

    local tmp
    tmp=$(mktemp)
    echo "${theme}|$(date +%s)" | cat - "$HISTORY_FILE" \
        2>/dev/null > "$tmp" || true
    head -50 "$tmp" > "$HISTORY_FILE" 2>/dev/null || true
    rm -f "$tmp"
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  AI THEME GENERATION
# ══════════════════════════════════════════════════════════════════════════════

generate_ai_theme() {
    local prompt="${1:-dark minimal catppuccin-inspired}"

    notify_tp "󰚩 AI Generating" "Creating theme: $prompt" "low"

    if command -v ash &>/dev/null; then
        local new_theme
        new_theme=$(ash theme ai-generate --prompt "$prompt" --silent 2>/dev/null | \
            grep "^theme-name:" | cut -d: -f2 | xargs || echo "")

        if [[ -n "$new_theme" ]]; then
            notify_tp "󰚩 AI Theme Ready" "$new_theme" "normal"
            apply_theme "$new_theme"
        else
            notify_tp "AI Generation failed" "Try a different prompt" "critical"
        fi
    else
        notify_tp "AI unavailable" "ASH CLI required" "normal"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  THEME EXPORT
# ══════════════════════════════════════════════════════════════════════════════

export_theme() {
    local theme="$1"
    local export_dir="${HOME}/Downloads/ash-themes"
    mkdir -p "$export_dir"

    if command -v ash &>/dev/null; then
        ash theme export "$theme" --output "$export_dir" &>/dev/null && \
            notify_tp "󰈦 Exported" "Theme: $theme\nPath: $export_dir" "low"
    else
        notify_tp "Export unavailable" "ASH CLI required" "normal"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_tp() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Theme Picker" \
        --icon=preferences-desktop-theme \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:theme-picker \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_theme_entries() {
    local filter_cat="${1:-all}"

    local current_theme
    current_theme=$(get_current_theme)

    local -a themes=()

    # Try to get themes from filesystem; fall back to hardcoded list
    local theme_data
    theme_data=$(get_all_themes 2>/dev/null || get_fallback_themes)

    if [[ -z "$theme_data" ]]; then
        theme_data=$(get_fallback_themes)
    fi

    local current_section=""

    while IFS='|' read -r name family mode accent rest; do
        [[ -z "$name" ]] && continue

        # Apply category filter
        if [[ "$filter_cat" != "all" ]]; then
            case "$filter_cat" in
                dark|light|neon|pastel)
                    [[ "${mode,,}" != "${filter_cat,,}" ]] && continue
                    ;;
                favorites)
                    is_favorite "$name" || continue
                    ;;
                *)
                    [[ "${family,,}" != *"${filter_cat,,}"* ]] && continue
                    ;;
            esac
        fi

        # Section grouping by family
        if [[ "$family" != "$current_section" ]] && [[ "$filter_cat" == "all" ]]; then
            current_section="$family"
            printf '─── %s ─────────────\0nonselectable\x1ftrue\n' \
                "$(echo "$family" | tr '[:lower:]' '[:upper:]')"
        fi

        # Build display
        local is_current=false
        local is_fav=false
        [[ "$name" == "$current_theme" ]] && is_current=true
        is_favorite "$name" && is_fav=true

        local current_mark="" fav_mark=""
        $is_current && current_mark="● "
        $is_fav     && fav_mark="★ "

        local mode_icon
        case "${mode,,}" in
            dark)   mode_icon="🌑" ;;
            light)  mode_icon="☀" ;;
            neon)   mode_icon="⚡" ;;
            pastel) mode_icon="🌸" ;;
            *)      mode_icon="🎨" ;;
        esac

        local accent_display=""
        [[ -n "$accent" ]] && accent_display=$(accent_dot "$accent")

        local display
        display=$(printf '%s%s%-30s  %-14s  %s  %s%s' \
            "$fav_mark" \
            "$current_mark" \
            "${name:0:28}" \
            "${family:0:12}" \
            "$mode_icon" \
            "$accent_display" \
            "$($is_current && echo "  ● Active" || true)")

        # Mark active themes for CSS class
        local rofi_class=""
        $is_current && rofi_class="active"
        $is_fav && rofi_class="${rofi_class:+$rofi_class }urgent"

        printf '%s\0info\x1fapply\x1fmeta\x1f%s\n' "$display" "$name"

    done <<< "$theme_data"

    if [[ "$filter_cat" == "all" || "$filter_cat" == "generated" ]]; then
        printf '─── AI GENERATED ─────────────────\0nonselectable\x1ftrue\n'
        printf '󰚩  Generate new theme with AI…\0info\x1fai-generate\n'
    fi
}

build_favorites_entries() {
    local favs
    favs=$(get_favorites)

    if [[ -z "$favs" ]]; then
        printf '★  No favorites yet — press Ctrl+F to add\0nonselectable\x1ftrue\n'
        return
    fi

    printf '─── FAVORITES ────────────────────────\0nonselectable\x1ftrue\n'

    local current_theme
    current_theme=$(get_current_theme)

    while IFS= read -r theme; do
        [[ -z "$theme" ]] && continue

        local current_mark=""
        [[ "$theme" == "$current_theme" ]] && current_mark="● "

        local display
        display=$(printf '★ %s%-30s%s' "$current_mark" "${theme:0:28}" \
            "$([[ "$theme" == "$current_theme" ]] && echo "  (active)" || true)")

        printf '%s\0info\x1fapply\x1fmeta\x1f%s\n' "$display" "$theme"
    done <<< "$favs"

    printf '─────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰩹  Clear Favorites\0info\x1fclear-favorites\n'
}

build_recent_entries() {
    if [[ ! -f "$HISTORY_FILE" ]]; then
        printf '  No recently applied themes\0nonselectable\x1ftrue\n'
        return
    fi

    printf '─── RECENTLY APPLIED ─────────────────\0nonselectable\x1ftrue\n'

    local count=0
    while IFS='|' read -r theme ts; do
        [[ -z "$theme" ]] && continue

        local age
        if [[ -n "$ts" ]]; then
            local diff=$(( $(date +%s) - ts ))
            if   [[ $diff -lt 3600 ]]; then age="${diff}m ago"
            elif [[ $diff -lt 86400 ]]; then age="$((diff/3600))h ago"
            else age="$((diff/86400))d ago"
            fi
        else
            age="recent"
        fi

        printf '󰒓  %-32s  %s\0info\x1fapply\x1fmeta\x1f%s\n' \
            "${theme:0:30}" "$age" "$theme"

        (( count++ )) || true
        [[ $count -ge 10 ]] && break
    done < "$HISTORY_FILE"
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        apply)
            [[ -n "$meta" ]] && apply_theme "$meta"
            ;;
        preview)
            [[ -n "$meta" ]] && preview_theme "$meta"
            ;;
        toggle-fav)
            [[ -n "$meta" ]] && toggle_favorite "$meta"
            ;;
        random)
            local themes
            themes=$(get_fallback_themes | cut -d'|' -f1 | shuf | head -1)
            [[ -n "$themes" ]] && apply_theme "$themes"
            ;;
        ai-generate)
            local prompt
            prompt=$(rofi -dmenu \
                -p "AI Theme Prompt" \
                -filter "dark minimal catppuccin-inspired" \
                -theme-str "window { width: 500px; } listview { lines: 0; }" \
                2>/dev/null || echo "")
            [[ -n "$prompt" ]] && generate_ai_theme "$prompt"
            ;;
        toggle-dark-light)
            local current
            current=$(get_current_theme)
            # Find paired variant
            local paired=""
            if [[ "$current" =~ -dark$ ]]; then
                paired="${current%-dark}-light"
            elif [[ "$current" =~ -light$ ]]; then
                paired="${current%-light}-dark"
            elif [[ "$current" =~ -latte$ ]]; then
                paired="${current%-latte}-mocha"
            elif [[ "$current" =~ -mocha$ ]]; then
                paired="${current%-mocha}-latte"
            fi
            if [[ -n "$paired" ]]; then
                apply_theme "$paired"
            else
                notify_tp "No paired variant" "No dark/light pair found for $current" "normal"
            fi
            ;;
        export)
            [[ -n "$meta" ]] && export_theme "$meta"
            ;;
        clear-favorites)
            > "$FAVORITES_FILE" 2>/dev/null && \
                notify_tp "Favorites cleared" "" "low"
            ;;
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --apply)     [[ -n "${2:-}" ]] && apply_theme "$2" ;;
        --random)    dispatch_action "random" ;;
        --ai)        generate_ai_theme "${2:-dark abstract minimal}" ;;
        --list)      get_fallback_themes | cut -d'|' -f1 | sort ;;
        --current)   get_current_theme ;;
        --favorites) get_favorites ;;
        --fav-toggle)[[ -n "${2:-}" ]] && toggle_favorite "$2" ;;
        --help|-h)
            echo "ASH Theme Picker v5.0"
            echo ""
            echo "Usage: theme-picker.sh [OPTION] [THEME]"
            echo ""
            echo "Options:"
            echo "  --apply THEME    Apply theme"
            echo "  --random         Apply random theme"
            echo "  --ai [PROMPT]    Generate AI theme"
            echo "  --list           List all themes"
            echo "  --current        Show active theme"
            echo "  --favorites      Show favorites"
            echo "  --fav-toggle T   Toggle favorite"
            echo ""
            echo "No args: Launch Rofi theme picker"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show tp \
        -modi "tp:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/theme-picker/theme-picker.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_theme_entries "all"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# Ctrl+F: Toggle favorite
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && toggle_favorite "$meta_value"
    build_theme_entries "all"
    exit 0
fi

# Ctrl+R: Random theme
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    dispatch_action "random"
    build_theme_entries "all"
    exit 0
fi

# Ctrl+A: AI generate
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    dispatch_action "ai-generate"
    build_theme_entries "all"
    exit 0
fi

# Ctrl+P: Preview only
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && preview_theme "$meta_value"
    build_theme_entries "all"
    exit 0
fi

# Ctrl+D: Toggle dark/light
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    dispatch_action "toggle-dark-light"
    build_theme_entries "all"
    exit 0
fi

# Ctrl+E: Export
if [[ "${ROFI_RETV}" -eq 15 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && export_theme "$meta_value"
    exit 0
fi

# Alt+Enter: Preview without applying
if [[ "${ROFI_RETV}" -eq 17 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && preview_theme "$meta_value"
    build_theme_entries "all"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_theme_entries "all"
    exit 0
fi