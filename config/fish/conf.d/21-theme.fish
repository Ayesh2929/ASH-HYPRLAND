# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Theme Integration Ultra                            ║
# ║  Live theme sync, color exports, terminal palette & event system           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_theme_loaded && exit 0
set --global _ash_theme_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_theme_state       "$HOME/.local/share/ash/state/current-theme.json"
set --global _ash_theme_cache_dir   "$HOME/.local/share/ash/cache/theme"
set --global _ash_theme_colors_env  "$HOME/.local/share/ash/cache/theme/colors.fish"
set --global _ash_theme_watch_sock  "$XDG_RUNTIME_DIR/ash-theme-watcher.sock"
set --global _ash_theme_hooks_dir   "$HOME/.config/ash/scripts/hooks"
set --global _ash_themes_dir        "$HOME/.config/ash/themes/presets"
set --global _ash_theme_log         "$HOME/.local/share/ash/logs/theme.log"
set --global _ash_cli               "$HOME/.local/bin/ash"

mkdir -p $_ash_theme_cache_dir 2>/dev/null
mkdir -p (dirname $_ash_theme_log) 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 CATPPUCCIN MOCHA — Hardcoded fallback palette                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# 16-color terminal palette (used when no theme state exists)
set --global _ash_fallback_colors \
    base:1e1e2e \
    mantle:181825 \
    crust:11111b \
    surface0:313244 \
    surface1:45475a \
    surface2:585b70 \
    overlay0:6c7086 \
    overlay1:7f849c \
    overlay2:9399b2 \
    subtext0:a6adc8 \
    subtext1:bac2de \
    text:cdd6f4 \
    lavender:b4befe \
    blue:89b4fa \
    sapphire:74c7ec \
    sky:89dceb \
    teal:94e2d5 \
    green:a6e3a1 \
    yellow:f9e2af \
    peach:fab387 \
    maroon:eba0ac \
    red:f38ba8 \
    mauve:cba6f7 \
    pink:f5c2e7 \
    flamingo:f2cdcd \
    rosewater:f5e0dc

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 COLOR LOADER: Parse ASH theme state → Fish global variables             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_theme_load_colors --description "Load current theme colors into globals"
    # Fast path: use cached fish color vars if fresh (< 2s old)
    if test -f $_ash_theme_colors_env
        set -l age (math (date +%s) - (stat -c %Y $_ash_theme_colors_env 2>/dev/null; or echo 0))
        if test $age -lt 2
            source $_ash_theme_colors_env 2>/dev/null
            return 0
        end
    end

    # Parse from ASH theme state JSON
    if test -f $_ash_theme_state && command -q jq
        set -l parsed (
            jq -r '
                .name as $name |
                .variant as $variant |
                (.colors // {}) |
                to_entries[] |
                "set --global ASH_COLOR_\(.key | ascii_upcase) \(.value)"
            ' $_ash_theme_state 2>/dev/null
        )

        # Also extract theme metadata
        set -l meta (
            jq -r '
                "set --global ASH_THEME_NAME \(.name // "unknown")",
                "set --global ASH_THEME_VARIANT \(.variant // "dark")",
                "set --global ASH_THEME_AUTHOR \"\(.author // "")\"",
                "set --global ASH_THEME_VERSION \"\(.version // "1.0.0")\"",
                "set --global ASH_THEME_WALLPAPER \"\(.wallpaper // "")\"",
                "set --global ASH_THEME_ACCENT \"\(.accent // "#cba6f7")\"",
                "set --global ASH_THEME_STYLE \"\(.style // "default")\""
            ' $_ash_theme_state 2>/dev/null
        )

        # Write cache file
        begin
            echo "# ASH Theme Colors — auto-generated "(date)
            echo "# Theme: "(jq -r '.name // "unknown"' $_ash_theme_state 2>/dev/null)
            echo ""
            for line in $meta $parsed
                echo $line
            end
        end > $_ash_theme_colors_env 2>/dev/null

        # Source it
        source $_ash_theme_colors_env 2>/dev/null
        return 0
    end

    # Fallback: load hardcoded Catppuccin Mocha
    set --global ASH_THEME_NAME    "catppuccin-mocha"
    set --global ASH_THEME_VARIANT "dark"
    set --global ASH_THEME_ACCENT  "#cba6f7"

    for entry in $_ash_fallback_colors
        set -l key (string split ':' $entry)[1]
        set -l val (string split ':' $entry)[2]
        set --global "ASH_COLOR_"(string upper $key) "#$val"
    end

    return 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📺 TERMINAL PALETTE: Set 16-color palette via OSC escape sequences         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_theme_set_terminal_palette --description "Apply theme colors to terminal via OSC sequences"
    # Only apply in terminals that support it
    set -l supported_terms xterm-256color kitty alacritty wezterm foot tmux-256color
    if not contains $TERM $supported_terms
        # Try via TERM_PROGRAM
        set -l supported_programs kitty WezTerm foot alacritty
        contains $TERM_PROGRAM $supported_programs || return 0
    end

    # Build palette from loaded colors
    set -l base        (set -q ASH_COLOR_BASE;     and echo $ASH_COLOR_BASE;     or echo "#1e1e2e")
    set -l surface0    (set -q ASH_COLOR_SURFACE0;  and echo $ASH_COLOR_SURFACE0;  or echo "#313244")
    set -l surface1    (set -q ASH_COLOR_SURFACE1;  and echo $ASH_COLOR_SURFACE1;  or echo "#45475a")
    set -l overlay0    (set -q ASH_COLOR_OVERLAY0;  and echo $ASH_COLOR_OVERLAY0;  or echo "#6c7086")
    set -l text        (set -q ASH_COLOR_TEXT;      and echo $ASH_COLOR_TEXT;      or echo "#cdd6f4")
    set -l red         (set -q ASH_COLOR_RED;       and echo $ASH_COLOR_RED;       or echo "#f38ba8")
    set -l green       (set -q ASH_COLOR_GREEN;     and echo $ASH_COLOR_GREEN;     or echo "#a6e3a1")
    set -l yellow      (set -q ASH_COLOR_YELLOW;    and echo $ASH_COLOR_YELLOW;    or echo "#f9e2af")
    set -l blue        (set -q ASH_COLOR_BLUE;      and echo $ASH_COLOR_BLUE;      or echo "#89b4fa")
    set -l mauve       (set -q ASH_COLOR_MAUVE;     and echo $ASH_COLOR_MAUVE;     or echo "#cba6f7")
    set -l teal        (set -q ASH_COLOR_TEAL;      and echo $ASH_COLOR_TEAL;      or echo "#94e2d5")
    set -l peach       (set -q ASH_COLOR_PEACH;     and echo $ASH_COLOR_PEACH;     or echo "#fab387")
    set -l subtext0    (set -q ASH_COLOR_SUBTEXT0;  and echo $ASH_COLOR_SUBTEXT0;  or echo "#a6adc8")
    set -l maroon      (set -q ASH_COLOR_MAROON;    and echo $ASH_COLOR_MAROON;    or echo "#eba0ac")
    set -l sky         (set -q ASH_COLOR_SKY;       and echo $ASH_COLOR_SKY;       or echo "#89dceb")
    set -l lavender    (set -q ASH_COLOR_LAVENDER;  and echo $ASH_COLOR_LAVENDER;  or echo "#b4befe")

    # Map to ANSI 16 colors: OSC 4 ; N ; rgb:RR/GG/BB ST
    # 0=black 1=red 2=green 3=yellow 4=blue 5=magenta 6=cyan 7=white
    # 8-15=bright variants
    set -l palette \
        "0:$base" \
        "1:$red" \
        "2:$green" \
        "3:$yellow" \
        "4:$blue" \
        "5:$mauve" \
        "6:$teal" \
        "7:$subtext0" \
        "8:$surface1" \
        "9:$maroon" \
        "10:$green" \
        "11:$peach" \
        "12:$sky" \
        "13:$lavender" \
        "14:$sky" \
        "15:$text"

    for entry in $palette
        set -l idx   (string split ':' $entry)[1]
        set -l color (string split ':' $entry | tail -1)
        # Convert #RRGGBB → rr/gg/bb
        set -l r (string sub --start 2 --length 2 $color)
        set -l g (string sub --start 4 --length 2 $color)
        set -l b (string sub --start 6 --length 2 $color)
        printf '\033]4;%s;rgb:%s/%s/%s\007' $idx $r $g $b
    end

    # Set foreground, background, cursor
    set -l bg_r (string sub --start 2 --length 2 $base)
    set -l bg_g (string sub --start 4 --length 2 $base)
    set -l bg_b (string sub --start 6 --length 2 $base)
    set -l fg_r (string sub --start 2 --length 2 $text)
    set -l fg_g (string sub --start 4 --length 2 $text)
    set -l fg_b (string sub --start 6 --length 2 $text)
    set -l ac_r (string sub --start 2 --length 2 $mauve)
    set -l ac_g (string sub --start 4 --length 2 $mauve)
    set -l ac_b (string sub --start 6 --length 2 $mauve)

    printf '\033]10;rgb:%s/%s/%s\007' $fg_r $fg_g $fg_b   # foreground
    printf '\033]11;rgb:%s/%s/%s\007' $bg_r $bg_g $bg_b   # background
    printf '\033]12;rgb:%s/%s/%s\007' $ac_r $ac_g $ac_b   # cursor
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 FISH SYNTAX HIGHLIGHTING: Apply theme colors                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_theme_set_fish_colors --description "Apply theme colors to Fish syntax highlighting"
    # Resolve colors (with fallbacks)
    set -l c_keyword  (set -q ASH_COLOR_MAUVE;    and echo $ASH_COLOR_MAUVE;    or echo "#cba6f7")
    set -l c_command  (set -q ASH_COLOR_BLUE;     and echo $ASH_COLOR_BLUE;     or echo "#89b4fa")
    set -l c_param    (set -q ASH_COLOR_PEACH;    and echo $ASH_COLOR_PEACH;    or echo "#fab387")
    set -l c_string   (set -q ASH_COLOR_GREEN;    and echo $ASH_COLOR_GREEN;    or echo "#a6e3a1")
    set -l c_comment  (set -q ASH_COLOR_OVERLAY0; and echo $ASH_COLOR_OVERLAY0; or echo "#6c7086")
    set -l c_operator (set -q ASH_COLOR_SKY;      and echo $ASH_COLOR_SKY;      or echo "#89dceb")
    set -l c_error    (set -q ASH_COLOR_RED;      and echo $ASH_COLOR_RED;      or echo "#f38ba8")
    set -l c_escape   (set -q ASH_COLOR_PINK;     and echo $ASH_COLOR_PINK;     or echo "#f5c2e7")
    set -l c_autosugg (set -q ASH_COLOR_OVERLAY0; and echo $ASH_COLOR_OVERLAY0; or echo "#6c7086")
    set -l c_match    (set -q ASH_COLOR_PEACH;    and echo $ASH_COLOR_PEACH;    or echo "#fab387")
    set -l c_search   (set -q ASH_COLOR_YELLOW;   and echo $ASH_COLOR_YELLOW;   or echo "#f9e2af")
    set -l c_path     (set -q ASH_COLOR_YELLOW;   and echo $ASH_COLOR_YELLOW;   or echo "#f9e2af")
    set -l c_var      (set -q ASH_COLOR_FLAMINGO; and echo $ASH_COLOR_FLAMINGO; or echo "#f2cdcd")
    set -l c_quote    (set -q ASH_COLOR_GREEN;    and echo $ASH_COLOR_GREEN;    or echo "#a6e3a1")
    set -l c_valid_p  (set -q ASH_COLOR_TEAL;     and echo $ASH_COLOR_TEAL;     or echo "#94e2d5")
    set -l c_invalid  (set -q ASH_COLOR_RED;      and echo $ASH_COLOR_RED;      or echo "#f38ba8")

    # Variant check: adjust for light themes
    if test "$ASH_THEME_VARIANT" = light
        set c_comment  (set -q ASH_COLOR_SUBTEXT0; and echo $ASH_COLOR_SUBTEXT0; or echo "#6e6a86")
        set c_autosugg (set -q ASH_COLOR_SUBTEXT0; and echo $ASH_COLOR_SUBTEXT0; or echo "#6e6a86")
    end

    # ── Fish color variables ──────────────────────────────────────────────────
    set --global fish_color_normal          $c_command
    set --global fish_color_command         $c_command
    set --global fish_color_keyword         $c_keyword"  --bold"
    set --global fish_color_quote           $c_string
    set --global fish_color_redirection     $c_operator
    set --global fish_color_end             $c_operator
    set --global fish_color_error           $c_error"  --bold"
    set --global fish_color_param           $c_param
    set --global fish_color_comment         $c_comment"  --italics"
    set --global fish_color_selection       "--background=$c_keyword" normal
    set --global fish_color_operator        $c_operator
    set --global fish_color_escape          $c_escape
    set --global fish_color_autosuggestion  $c_autosugg"  --italics"
    set --global fish_color_cwd             $c_path"  --bold"
    set --global fish_color_cwd_root        $c_error"  --bold"
    set --global fish_color_user            $c_keyword
    set --global fish_color_host            $c_command
    set --global fish_color_host_remote     $c_string
    set --global fish_color_status          $c_error
    set --global fish_color_cancel          $c_error
    set --global fish_color_search_match    "--background=$c_search" $c_command
    set --global fish_color_history_current "--bold"
    set --global fish_color_valid_path      $c_valid_p"  --underline"

    # ── Pager colors ──────────────────────────────────────────────────────────
    set --global fish_pager_color_progress     $c_comment"  --background=normal"
    set --global fish_pager_color_background   normal
    set --global fish_pager_color_prefix       $c_command"  --bold"
    set --global fish_pager_color_completion   normal
    set --global fish_pager_color_description  $c_comment
    set --global fish_pager_color_selected_background "--background="(set -q ASH_COLOR_SURFACE0; and echo $ASH_COLOR_SURFACE0; or echo "#313244")
    set --global fish_pager_color_selected_prefix     $c_keyword"  --bold"
    set --global fish_pager_color_selected_completion normal
    set --global fish_pager_color_secondary_background normal
    set --global fish_pager_color_secondary_prefix    $c_comment
    set --global fish_pager_color_secondary_completion $c_comment
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📣 EVENT SYSTEM: Emit & handle ASH theme events                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_theme_emit --description "Emit ash_theme_changed event with metadata"
    set -l theme_name $argv[1]
    test -z "$theme_name" && set theme_name (set -q ASH_THEME_NAME; and echo $ASH_THEME_NAME; or echo unknown)

    # Emit to all registered listeners
    emit ash_theme_changed  $theme_name
    emit ash_colors_updated $theme_name

    # Notify external processes via a state file
    echo (date +%s) > "$_ash_theme_cache_dir/last-change-ts" 2>/dev/null
end

# ─── Watcher: detect external theme changes ────────────────────────────────

function __ash_theme_check_change --on-event fish_prompt \
    --description "Check for external ASH theme changes on each prompt"

    test -f $_ash_theme_state || return

    set -l state_mtime (stat -c %Y $_ash_theme_state 2>/dev/null; or echo 0)
    set -l cache_mtime (stat -c %Y $_ash_theme_colors_env 2>/dev/null; or echo 0)

    # If state is newer than cache → theme changed externally
    if test $state_mtime -gt $cache_mtime
        __ash_theme_apply_silent
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 APPLY ENGINE: Full theme application pipeline                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_theme_apply_silent --description "Apply theme silently (called from watcher)"
    # 1. Invalidate color cache
    rm -f $_ash_theme_colors_env 2>/dev/null

    # 2. Reload colors from state
    __ash_theme_load_colors

    # 3. Apply fish syntax highlighting
    __ash_theme_set_fish_colors

    # 4. Apply terminal palette
    __ash_theme_set_terminal_palette

    # 5. Emit events for other components (starship, fzf, etc.)
    __ash_theme_emit $ASH_THEME_NAME
end

function ash-theme-apply --description "Apply current ASH theme to Fish shell"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)

    echo ""
    echo $bold$cyan"  🎨 Applying ASH theme: $ASH_THEME_NAME"$reset
    echo ""

    __ash_theme_apply_silent

    echo "  "$green"✓ Colors loaded    "$reset $ASH_THEME_NAME "("$ASH_THEME_VARIANT")"
    echo "  "$green"✓ Fish highlighting"$reset" applied"
    echo "  "$green"✓ Terminal palette "$reset" applied"
    echo "  "$green"✓ Events emitted   "$reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC THEME FUNCTIONS                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── ash-theme-switch ─────────────────────────────────────────────────────────
function ash-theme-switch --description "Switch ASH theme by name"
    set -l name $argv[1]

    if test -z "$name"
        # Interactive fuzzy picker if fzf available
        if command -q fzf && test -d $_ash_themes_dir
            set name (
                find $_ash_themes_dir -name "theme.conf" -o -name "*.conf" 2>/dev/null |
                xargs -I{} dirname {} 2>/dev/null | xargs -I{} basename {} 2>/dev/null |
                sort -u |
                fzf --border-label '  ASH Themes ' \
                    --border rounded \
                    --prompt '  ' \
                    --pointer '▶' \
                    --preview "cat '$_ash_themes_dir/{}/colors.json' 2>/dev/null | python3 -m json.tool 2>/dev/null || echo 'No preview'" \
                    --preview-window 'right:40%:border-rounded' \
                    --header '  Enter:apply  Ctrl-P:preview  '
            )
            test -z "$name" && return 0
        else
            echo "  Usage: ash-theme-switch <theme-name>"
            return 1
        end
    end

    # Delegate to ASH CLI if available
    if command -q ash
        ash theme apply $name
    else if test -x $_ash_cli
        $_ash_cli theme apply $name
    else
        echo $_ssh_red"  ✗ ASH CLI not found"$reset >&2
        return 1
    end
end

# ─── ash-theme-list ───────────────────────────────────────────────────────────
function ash-theme-list --description "List available ASH themes with categories"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     🎨  ASH Theme Library                        ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════╝"$reset
    echo ""
    echo "  Current: "$bold$green$ASH_THEME_NAME$reset" ("$ASH_THEME_VARIANT")"
    echo ""

    if not test -d $_ash_themes_dir
        echo $dim"  Themes directory not found: $_ash_themes_dir"$reset
        return 1
    end

    for category_dir in $_ash_themes_dir/*/
        set -l category (basename $category_dir)
        echo $bold$yellow"  📁 $category"$reset

        for theme_dir in $category_dir*/
            test -d $theme_dir || continue
            set -l theme_name (basename $theme_dir)
            set -l active_marker ""
            test "$theme_name" = "$ASH_THEME_NAME" && set active_marker $green" ← active"$reset

            echo "     "$dim"•"$reset" $theme_name$active_marker"
        end
        echo ""
    end
end

# ─── ash-theme-random ─────────────────────────────────────────────────────────
function ash-theme-random --description "Apply a random ASH theme"
    set -l category $argv[1]

    if test -d $_ash_themes_dir
        if test -n "$category" && test -d "$_ash_themes_dir/$category"
            set -l themes (find "$_ash_themes_dir/$category" -mindepth 1 -maxdepth 1 -type d)
        else
            set -l themes (find $_ash_themes_dir -mindepth 2 -maxdepth 2 -type d)
        end

        set -l count (count $themes)
        if test $count -gt 0
            set -l idx (random 1 $count)
            set -l chosen (basename $themes[$idx])
            echo "  🎲 Random theme: $chosen"
            ash-theme-switch $chosen
            return
        end
    end

    # Fallback to ASH CLI
    command -q ash && ash theme random
end

# ─── ash-theme-info ───────────────────────────────────────────────────────────
function ash-theme-info --description "Show current theme information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     🎨  Current Theme Info                       ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════╝"$reset
    echo ""
    echo "  "$bold"Name:     "$reset $ASH_THEME_NAME
    echo "  "$bold"Variant:  "$reset $ASH_THEME_VARIANT
    echo "  "$bold"Accent:   "$reset $ASH_THEME_ACCENT
    echo "  "$bold"Author:   "$reset $ASH_THEME_AUTHOR
    echo "  "$bold"Version:  "$reset $ASH_THEME_VERSION
    echo "  "$bold"Style:    "$reset $ASH_THEME_STYLE
    echo ""

    if test -n "$ASH_THEME_WALLPAPER"
        echo "  "$bold"Wallpaper:"$reset $ASH_THEME_WALLPAPER
        echo ""
    end

    # Show color swatch
    echo "  "$bold"Color Palette:"$reset
    echo ""
    for entry in $_ash_fallback_colors
        set -l key (string split ':' $entry)[1]
        set -l var "ASH_COLOR_"(string upper $key)
        set -l val (set -q $var; and echo $$var; or echo "")
        if test -n "$val"
            set -l r (math --scale 0 "0x"(string sub --start 2 --length 2 $val))
            set -l g (math --scale 0 "0x"(string sub --start 4 --length 2 $val))
            set -l b (math --scale 0 "0x"(string sub --start 6 --length 2 $val))
            printf "  %s%-14s%s %s▬▬▬▬%s %s\n" \
                (set_color --bold) $key $reset \
                (set_color $r $g $b 2>/dev/null; or echo "") \
                $reset \
                $dim$val$reset
        end
    end
    echo ""
end

# ─── ash-theme-swatch ─────────────────────────────────────────────────────────
function ash-theme-swatch --description "Show visual color swatch in terminal"
    set -l reset (set_color normal)
    set -l bold  (set_color --bold)

    echo ""
    echo $bold"  🎨 "$ASH_THEME_NAME" Color Swatch"$reset
    echo ""

    # Print a visual block for each color
    set -l color_names \
        rosewater flamingo pink mauve red maroon \
        peach yellow green teal sky sapphire blue lavender

    # Row 1: color blocks
    printf "  "
    for name in $color_names
        set -l var "ASH_COLOR_"(string upper $name)
        if set -q $var
            set -l val $$var
            set -l r (math --scale 0 "0x"(string sub --start 2 --length 2 $val) 2>/dev/null; or echo 128)
            set -l g (math --scale 0 "0x"(string sub --start 4 --length 2 $val) 2>/dev/null; or echo 128)
            set -l b (math --scale 0 "0x"(string sub --start 6 --length 2 $val) 2>/dev/null; or echo 128)
            printf '%s████%s' (set_color $r $g $b 2>/dev/null; or echo "") $reset
        end
    end
    echo ""

    # Row 2: names
    printf "  "
    for name in $color_names
        printf "%-4s" (string sub --length 4 $name)
    end
    echo ""
    echo ""

    # Surface colors
    printf "  "
    for name in base mantle crust surface0 surface1 surface2 overlay0 overlay1 overlay2 subtext0 subtext1 text
        set -l var "ASH_COLOR_"(string upper $name)
        if set -q $var
            set -l val $$var
            set -l r (math --scale 0 "0x"(string sub --start 2 --length 2 $val) 2>/dev/null; or echo 30)
            set -l g (math --scale 0 "0x"(string sub --start 4 --length 2 $val) 2>/dev/null; or echo 30)
            set -l b (math --scale 0 "0x"(string sub --start 6 --length 2 $val) 2>/dev/null; or echo 46)
            printf '%s████%s' (set_color $r $g $b 2>/dev/null; or echo "") $reset
        end
    end
    echo ""
    echo ""
end

# ─── ash-theme-reload ─────────────────────────────────────────────────────────
function ash-theme-reload --description "Reload current theme (reparse state)"
    echo ""
    echo (set_color cyan)"  🔄 Reloading theme: $ASH_THEME_NAME"(set_color normal)
    __ash_theme_apply_silent
    echo (set_color green)"  ✓ Theme reloaded"(set_color normal)
    echo ""
end

# ─── ash-theme-export-env ─────────────────────────────────────────────────────
function ash-theme-export-env --description "Export theme colors as shell environment"
    set -l format $argv[1]
    test -z "$format" && set format fish

    switch $format
        case fish
            for var in (set -n | grep '^ASH_')
                echo "set --export $var '$$var'"
            end
        case bash sh
            for var in (set -n | grep '^ASH_')
                echo "export $var='$$var'"
            end
        case json
            echo "{"
            set -l vars (set -n | grep '^ASH_COLOR_')
            set -l last $vars[-1]
            for var in $vars
                set -l key (string replace 'ASH_COLOR_' '' $var | string lower)
                set -l val $$var
                set -l comma ","
                test "$var" = "$last" && set comma ""
                echo "  \"$key\": \"$val\"$comma"
            end
            echo "}"
        case css
            echo ":root {"
            for var in (set -n | grep '^ASH_COLOR_')
                set -l key (string replace 'ASH_COLOR_' '' $var | string lower | string replace _ -)
                set -l val $$var
                echo "  --ash-$key: $val;"
            end
            echo "}"
        case '*'
            echo "  Usage: ash-theme-export-env [fish|bash|json|css]"
            return 1
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZATION                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Load colors from state
__ash_theme_load_colors

# Apply Fish syntax highlighting
__ash_theme_set_fish_colors

# Apply terminal palette (non-blocking)
__ash_theme_set_terminal_palette

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ath    'ash-theme-switch'
abbr --add athl   'ash-theme-list'
abbr --add athr   'ash-theme-random'
abbr --add athi   'ash-theme-info'
abbr --add aths   'ash-theme-swatch'
abbr --add athrl  'ash-theme-reload'
abbr --add athe   'ash-theme-export-env'
abbr --add athenv 'ash-theme-export-env fish'
abbr --add athjson 'ash-theme-export-env json'
abbr --add athcss 'ash-theme-export-env css'