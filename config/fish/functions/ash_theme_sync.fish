# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ash_theme_sync Ultra                               ║
# ║  Real-time theme synchronization engine across all shell components        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash_theme_sync --description "Sync ASH theme across all shell components"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 PATHS                                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l state_file    "$HOME/.local/share/ash/state/current-theme.json"
    set -l cache_dir     "$HOME/.local/share/ash/cache/theme"
    set -l log_file      "$HOME/.local/share/ash/logs/theme-sync.log"
    set -l colors_cache  "$cache_dir/colors.fish"

    mkdir -p $cache_dir          2>/dev/null
    mkdir -p (dirname $log_file) 2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS & UI                                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l PURPLE (set_color magenta)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 LOGGING                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_log --description "Write to sync log"
        set -l ts  (date '+%H:%M:%S')
        set -l msg (string join ' ' $argv[2..-1])
        echo "[$ts][$argv[1]] $msg" >> $log_file 2>/dev/null
    end

    function __sync_ok  --description "Log + print success"
        __sync_log OK  $argv
        set -q _sync_verbose && echo "  $GREEN✓$R  $argv"
    end

    function __sync_skip --description "Log + print skip"
        __sync_log SKIP $argv
        set -q _sync_verbose && echo "  $DIM○  $argv$R"
    end

    function __sync_warn --description "Log + print warning"
        __sync_log WARN $argv
        echo "  $YELLOW⚠$R  $argv" >&2
    end

    function __sync_err --description "Log + print error"
        __sync_log ERR  $argv
        echo "  $RED✗$R  $argv" >&2
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _verbose    0
    set -l _quiet      0
    set -l _force      0
    set -l _component  ""
    set -l _theme_name ""
    set -l _show_help  0

    for arg in $argv
        switch $arg
            case -v --verbose;   set _verbose  1; set -g _sync_verbose 1
            case -q --quiet;     set _quiet    1
            case -f --force;     set _force    1
            case -h --help;      set _show_help 1
            case --fish;         set _component fish
            case --terminal;     set _component terminal
            case --fzf;          set _component fzf
            case --bat;          set _component bat
            case --starship;     set _component starship
            case --eza;          set _component eza
            case --nvim;         set _component nvim
            case --all;          set _component all
            case '*'
                # Treat as theme name
                test -z "$_theme_name" && set _theme_name $arg
        end
    end

    # ── Show help ─────────────────────────────────────────────────────────────
    if test $_show_help -eq 1
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🎨  ash_theme_sync — Theme Sync Engine           ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  ash_theme_sync [theme-name] [options]"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-20s$R  %s\n" "-v, --verbose"   "Show all sync steps"
        printf "    $CYAN%-20s$R  %s\n" "-q, --quiet"     "Suppress all output"
        printf "    $CYAN%-20s$R  %s\n" "-f, --force"     "Force sync (ignore cache)"
        printf "    $CYAN%-20s$R  %s\n" "--fish"          "Sync Fish colors only"
        printf "    $CYAN%-20s$R  %s\n" "--terminal"      "Sync terminal palette only"
        printf "    $CYAN%-20s$R  %s\n" "--fzf"           "Sync fzf colors only"
        printf "    $CYAN%-20s$R  %s\n" "--bat"           "Sync bat theme only"
        printf "    $CYAN%-20s$R  %s\n" "--starship"      "Sync starship theme only"
        printf "    $CYAN%-20s$R  %s\n" "--eza"           "Sync eza colors only"
        printf "    $CYAN%-20s$R  %s\n" "--nvim"          "Notify Neovim instances"
        printf "    $CYAN%-20s$R  %s\n" "--all"           "Sync all components"
        printf "    $CYAN%-20s$R  %s\n" "-h, --help"      "Show this help"
        echo ""
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📖 THEME STATE LOADING                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Load theme from state file ─────────────────────────────────────────────
    function __sync_load_state --description "Load theme colors from state file"
        if not test -f $state_file
            __sync_warn "State file not found: $state_file"
            return 1
        end

        command -q jq || begin
            __sync_warn "jq not found — using fallback Catppuccin Mocha"
            return 1
        end

        # Parse all color keys from JSON
        set -l parsed (
            jq -r '
                .name    as $n |
                .variant as $v |
                (.colors // {}) |
                to_entries[] |
                "ASH_COLOR_\(.key | ascii_upcase)=\(.value)"
            ' $state_file 2>/dev/null
        )

        # Export each color
        for pair in $parsed
            set -l key (string split '=' $pair)[1]
            set -l val (string split '=' $pair | tail -1)
            set --global --export $key $val
        end

        # Theme metadata
        set --global --export ASH_THEME_NAME    (jq -r '.name    // "catppuccin-mocha"' $state_file 2>/dev/null)
        set --global --export ASH_THEME_VARIANT (jq -r '.variant // "dark"'             $state_file 2>/dev/null)
        set --global --export ASH_THEME_ACCENT  (jq -r '.accent  // "#cba6f7"'          $state_file 2>/dev/null)
        set --global --export ASH_THEME_AUTHOR  (jq -r '.author  // ""'                 $state_file 2>/dev/null)
        set --global --export ASH_THEME_STYLE   (jq -r '.style   // "default"'          $state_file 2>/dev/null)

        return 0
    end

    # Load state (or keep existing globals)
    if test $_force -eq 1 || not set -q ASH_THEME_NAME
        __sync_load_state
    end

    # ── Helper: get color from globals ────────────────────────────────────────
    function __c --description "Get color value from ASH globals"
        set -l key "ASH_COLOR_"(string upper $argv[1])
        set -l fallback $argv[2]
        if set -q $key
            echo $$key
        else
            echo $fallback
        end
    end

    test $_quiet -eq 0 && test $_verbose -eq 1 && begin
        echo ""
        echo $BOLD$PURPLE"  🎨 ASH Theme Sync: $ASH_THEME_NAME ($ASH_THEME_VARIANT)"$R
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🐟 COMPONENT: Fish syntax highlighting                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_fish_colors --description "Sync Fish syntax highlighting colors"
        set -l c_keyword  (__c mauve    "#cba6f7")
        set -l c_command  (__c blue     "#89b4fa")
        set -l c_param    (__c peach    "#fab387")
        set -l c_string   (__c green    "#a6e3a1")
        set -l c_comment  (__c overlay0 "#6c7086")
        set -l c_operator (__c sky      "#89dceb")
        set -l c_error    (__c red      "#f38ba8")
        set -l c_escape   (__c pink     "#f5c2e7")
        set -l c_autosugg (__c overlay0 "#6c7086")
        set -l c_valid_p  (__c teal     "#94e2d5")
        set -l c_cwd      (__c blue     "#89b4fa")
        set -l c_user     (__c mauve    "#cba6f7")
        set -l c_host     (__c blue     "#89b4fa")

        # Convert hex to fish set_color format (strip #)
        function __fc --description "Convert hex to set_color arg"
            string replace '#' '' $argv[1]
        end

        set --global fish_color_normal          (__fc $c_command)
        set --global fish_color_command         (__fc $c_command)
        set --global fish_color_keyword         (__fc $c_keyword)"  --bold"
        set --global fish_color_quote           (__fc $c_string)
        set --global fish_color_redirection     (__fc $c_operator)
        set --global fish_color_end             (__fc $c_operator)
        set --global fish_color_error           (__fc $c_error)"   --bold"
        set --global fish_color_param           (__fc $c_param)
        set --global fish_color_comment         (__fc $c_comment)"  --italics"
        set --global fish_color_operator        (__fc $c_operator)
        set --global fish_color_escape          (__fc $c_escape)
        set --global fish_color_autosuggestion  (__fc $c_autosugg)"  --italics"
        set --global fish_color_cwd             (__fc $c_cwd)"  --bold"
        set --global fish_color_cwd_root        (__fc (__c red "#f38ba8"))"  --bold"
        set --global fish_color_user            (__fc $c_user)
        set --global fish_color_host            (__fc $c_host)
        set --global fish_color_host_remote     (__fc $c_string)
        set --global fish_color_status          (__fc $c_error)
        set --global fish_color_cancel          (__fc $c_error)
        set --global fish_color_valid_path      (__fc $c_valid_p)"  --underline"
        set --global fish_color_selection       "--background="(__fc (__c surface0 "#313244"))" normal"
        set --global fish_color_search_match    "--background="(__fc (__c yellow "#f9e2af"))" "(__fc $c_command)
        set --global fish_color_history_current "--bold"

        # Pager colors
        set --global fish_pager_color_progress      (__fc $c_comment)
        set --global fish_pager_color_background    normal
        set --global fish_pager_color_prefix        (__fc $c_command)"  --bold"
        set --global fish_pager_color_completion    normal
        set --global fish_pager_color_description   (__fc $c_comment)"  --italics"
        set --global fish_pager_color_selected_background \
            "--background="(__fc (__c surface0 "#313244"))
        set --global fish_pager_color_selected_prefix \
            (__fc $c_keyword)"  --bold"
        set --global fish_pager_color_selected_completion normal

        functions --erase __fc 2>/dev/null
        __sync_ok "fish syntax highlighting"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📺 COMPONENT: Terminal 16-color palette (OSC sequences)                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_terminal_palette --description "Apply theme to terminal via OSC sequences"
        # Only for capable terminals
        set -l supported_terms xterm-256color kitty alacritty wezterm foot tmux-256color
        set -l supported_progs kitty WezTerm foot Alacritty
        if not contains $TERM $supported_terms && not contains $TERM_PROGRAM $supported_progs
            __sync_skip "terminal palette (unsupported: $TERM)"
            return
        end

        # ANSI 16 → Catppuccin Mocha mapping
        set -l palette \
            "0:"  (__c base     "#1e1e2e")  \
            "1:"  (__c red      "#f38ba8")  \
            "2:"  (__c green    "#a6e3a1")  \
            "3:"  (__c yellow   "#f9e2af")  \
            "4:"  (__c blue     "#89b4fa")  \
            "5:"  (__c mauve    "#cba6f7")  \
            "6:"  (__c teal     "#94e2d5")  \
            "7:"  (__c subtext0 "#a6adc8")  \
            "8:"  (__c surface1 "#45475a")  \
            "9:"  (__c maroon   "#eba0ac")  \
            "10:" (__c green    "#a6e3a1")  \
            "11:" (__c peach    "#fab387")  \
            "12:" (__c sky      "#89dceb")  \
            "13:" (__c lavender "#b4befe")  \
            "14:" (__c sky      "#89dceb")  \
            "15:" (__c text     "#cdd6f4")

        # Emit OSC 4 sequences
        set -l i 0
        while test $i -lt (count $palette)
            set -l idx   (string replace ':' '' $palette[$i])
            set -l color $palette[(math $i + 1)]
            set -l r (string sub --start 2 --length 2 $color)
            set -l g (string sub --start 4 --length 2 $color)
            set -l b (string sub --start 6 --length 2 $color)
            printf '\033]4;%s;rgb:%s/%s/%s\007' $idx $r $g $b
            set i (math $i + 2)
        end

        # Foreground, background, cursor
        set -l fg   (__c text "#cdd6f4")
        set -l bg   (__c base "#1e1e2e")
        set -l cur  (__c mauve "#cba6f7")

        function __hex_to_rgb --description "Convert hex to r/g/b"
            echo \
                (string sub --start 2 --length 2 $argv[1]) \
                (string sub --start 4 --length 2 $argv[1]) \
                (string sub --start 6 --length 2 $argv[1])
        end

        set -l fg_rgb  (__hex_to_rgb $fg)
        set -l bg_rgb  (__hex_to_rgb $bg)
        set -l cur_rgb (__hex_to_rgb $cur)

        printf '\033]10;rgb:%s/%s/%s\007' $fg_rgb[1]  $fg_rgb[2]  $fg_rgb[3]
        printf '\033]11;rgb:%s/%s/%s\007' $bg_rgb[1]  $bg_rgb[2]  $bg_rgb[3]
        printf '\033]12;rgb:%s/%s/%s\007' $cur_rgb[1] $cur_rgb[2] $cur_rgb[3]

        functions --erase __hex_to_rgb 2>/dev/null
        __sync_ok "terminal palette (OSC sequences)"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 COMPONENT: fzf colors                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_fzf --description "Sync fzf color scheme"
        command -q fzf || begin; __sync_skip "fzf (not installed)"; return; end

        set -l bg      (__c base     "#1e1e2e")
        set -l bg_alt  (__c surface0 "#313244")
        set -l fg      (__c text     "#cdd6f4")
        set -l accent  (__c mauve    "#cba6f7")
        set -l green   (__c green    "#a6e3a1")
        set -l yellow  (__c yellow   "#f9e2af")
        set -l blue    (__c blue     "#89b4fa")
        set -l cyan    (__c sky      "#89dceb")
        set -l fg_alt  (__c subtext1 "#bac2de")

        set --global --export FZF_DEFAULT_OPTS (
            string replace --regex -- '--color [^ ]+' \
                "--color bg:$bg,bg+:$bg_alt,fg:$fg,fg+:$fg,hl:$accent,hl+:$accent,info:$yellow,prompt:$blue,pointer:$accent,marker:$green,spinner:$cyan,header:$fg_alt,border:$bg_alt,label:$fg_alt,query:$fg,gutter:$bg" \
                "$FZF_DEFAULT_OPTS" 2>/dev/null
        )

        # If no existing opts, set minimal
        if not string match -q '*--color*' "$FZF_DEFAULT_OPTS"
            set --global --export FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --color bg:$bg,bg+:$bg_alt,fg:$fg,fg+:$fg,hl:$accent,hl+:$accent,info:$yellow,prompt:$blue,pointer:$accent,marker:$green,spinner:$cyan,header:$fg_alt"
        end

        # Invalidate fzf color cache
        rm -f "$HOME/.local/share/ash/cache/fzf/fzf-colors.conf" 2>/dev/null

        __sync_ok "fzf color scheme"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🦇 COMPONENT: bat theme                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_bat --description "Sync bat syntax theme"
        command -q bat || command -q batcat || begin
            __sync_skip "bat (not installed)"
            return
        end

        set -l bat_exe (command -q bat && echo bat || echo batcat)
        set -l new_theme ""

        # Map ASH theme name → bat theme
        switch $ASH_THEME_NAME
            case '*catppuccin*mocha*'   '*catppuccin-mocha*'
                set new_theme "Catppuccin Mocha"
            case '*catppuccin*latte*'   '*catppuccin-latte*'
                set new_theme "Catppuccin Latte"
            case '*catppuccin*frappe*'  '*catppuccin-frappe*'
                set new_theme "Catppuccin Frappe"
            case '*catppuccin*macchiato*' '*catppuccin-macchiato*'
                set new_theme "Catppuccin Macchiato"
            case '*tokyonight*'
                set new_theme "tokyonight_night"
            case '*gruvbox*dark*'
                set new_theme "gruvbox-dark"
            case '*gruvbox*light*'
                set new_theme "gruvbox-light"
            case '*nord*'
                set new_theme "Nord"
            case '*dracula*'
                set new_theme "Dracula"
            case '*solarized*dark*'
                set new_theme "Solarized (dark)"
            case '*solarized*light*'
                set new_theme "Solarized (light)"
            case '*onelight*' '*one-light*'
                set new_theme "OneHalfLight"
            case '*'
                switch $ASH_THEME_VARIANT
                    case light; set new_theme "Catppuccin Latte"
                    case '*';   set new_theme "Catppuccin Mocha"
                end
        end

        # Validate theme exists
        if $bat_exe --list-themes 2>/dev/null | grep -qF "$new_theme"
            set --global --export BAT_THEME $new_theme

            # Update config file
            set -l bat_config "$HOME/.config/bat/config"
            if test -f $bat_config
                sed -i "s|^--theme=.*|--theme=\"$new_theme\"|" $bat_config 2>/dev/null
            end

            __sync_ok "bat theme: $new_theme"
        else
            __sync_warn "bat theme not found: $new_theme (keeping $BAT_THEME)"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 COMPONENT: Starship prompt                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_starship --description "Sync Starship prompt theme"
        command -q starship || begin; __sync_skip "starship (not installed)"; return; end

        set -l dynamic_config "$HOME/.local/share/ash/cache/starship-dynamic.toml"

        # Regenerate if ash_starship_generate_theme function exists
        if functions -q __ash_starship_generate_theme
            __ash_starship_generate_theme 2>/dev/null
            set --global --export STARSHIP_CONFIG $dynamic_config
            __sync_ok "starship config regenerated"
        else
            # Minimal: just update STARSHIP_CONFIG
            test -f $dynamic_config && set --global --export STARSHIP_CONFIG $dynamic_config
            __sync_ok "starship (using existing config)"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 COMPONENT: eza colors                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_eza --description "Sync eza color theme"
        command -q eza || begin; __sync_skip "eza (not installed)"; return; end

        # Rebuild EZA_COLORS from current theme
        if functions -q __ash_eza_build_colors
            rm -f "$HOME/.local/share/ash/cache/eza/colors" 2>/dev/null
            set --global --export EZA_COLORS (__ash_eza_build_colors)
            __sync_ok "eza colors"
        else
            __sync_skip "eza (color builder not loaded)"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📝 COMPONENT: Neovim live sync                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_nvim --description "Notify Neovim instances of theme change"
        command -q nvim || begin; __sync_skip "nvim (not installed)"; return; end

        # Write signal file
        echo $ASH_THEME_NAME > "$HOME/.local/share/ash/state/nvim-theme-signal" 2>/dev/null

        # Find all running nvim sockets and notify them
        set -l notified 0

        for sock in \
            "$XDG_RUNTIME_DIR/nvim."*".sock" \
            "$HOME/.local/share/nvim/server-"*".sock" \
            /tmp/nvim*
            test -S $sock || continue
            nvim --server $sock \
                --remote-send \
                "<cmd>lua if pcall(require,'ash') then require('ash').sync_theme() end<cr>" \
                2>/dev/null
            set notified (math $notified + 1)
        end

        if test $notified -gt 0
            __sync_ok "nvim: notified $notified instance(s)"
        else
            __sync_skip "nvim: no running instances found"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔔 COMPONENT: Event emission                                            ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_emit_events --description "Emit Fish events for theme change"
        # Core theme events
        emit ash_theme_changed   $ASH_THEME_NAME
        emit ash_colors_updated  $ASH_THEME_NAME

        # Write timestamp
        echo (date +%s) > "$HOME/.local/share/ash/cache/theme/last-change-ts" 2>/dev/null

        __sync_ok "events emitted (ash_theme_changed, ash_colors_updated)"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔔 COMPONENT: Desktop notification                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_notify --description "Send desktop notification"
        set -q ASH_THEME_NOTIFICATIONS || return
        test "$ASH_THEME_NOTIFICATIONS" = 1 || return

        if command -q notify-send
            notify-send \
                --app-name="ASH Dotfiles" \
                --icon="preferences-desktop-wallpaper" \
                --expire-time=2000 \
                "Theme Changed" \
                "🎨 $ASH_THEME_NAME ($ASH_THEME_VARIANT)" \
                2>/dev/null
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  💾 CACHE: Write current colors to fish cache file                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sync_write_cache --description "Write color cache for fast re-loading"
        set -l cache_file "$cache_dir/colors.fish"

        begin
            echo "# ASH Theme Color Cache — auto-generated"
            echo "# Theme: $ASH_THEME_NAME | Variant: $ASH_THEME_VARIANT"
            echo "# Generated: "(date)
            echo ""
            echo "set --global --export ASH_THEME_NAME    '$ASH_THEME_NAME'"
            echo "set --global --export ASH_THEME_VARIANT '$ASH_THEME_VARIANT'"
            echo "set --global --export ASH_THEME_ACCENT  '$ASH_THEME_ACCENT'"
            echo ""
            # Export all ASH_COLOR_ variables
            for var in (set -n | grep '^ASH_COLOR_')
                echo "set --global --export $var '$$var'"
            end
        end > $cache_file 2>/dev/null

        __sync_ok "color cache written"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MAIN DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l ts_start (date +%s%N 2>/dev/null; or date +%s)

    # ── Sync requested component(s) ───────────────────────────────────────────
    switch $_component
        case fish
            __sync_fish_colors
        case terminal
            __sync_terminal_palette
        case fzf
            __sync_fzf
        case bat
            __sync_bat
        case starship
            __sync_starship
        case eza
            __sync_eza
        case nvim
            __sync_nvim
        case '' all '*'
            # Full sync — all components in order
            __sync_fish_colors
            __sync_terminal_palette
            __sync_fzf
            __sync_bat
            __sync_starship
            __sync_eza
            __sync_nvim
            __sync_write_cache
            __sync_emit_events
            __sync_notify
    end

    # ── Timing ────────────────────────────────────────────────────────────────
    set -l ts_end (date +%s%N 2>/dev/null; or date +%s)
    set -l elapsed_ms (math --scale 1 "($ts_end - $ts_start) / 1000000" 2>/dev/null; or echo "?")

    test $_quiet -eq 0 && test $_verbose -eq 1 && begin
        echo ""
        echo "  $DIM⏱ Sync completed in $elapsed_ms ms$R"
        echo ""
    end

    test $_quiet -eq 0 && test $_verbose -eq 0 && \
        echo "  $GREEN✓$R Theme synced: $CYAN$ASH_THEME_NAME$R ($DIM${elapsed_ms}ms$R)"

    # ── Cleanup ───────────────────────────────────────────────────────────────
    set --erase _sync_verbose
    functions --erase __sync_log __sync_ok __sync_skip __sync_warn __sync_err \
        __sync_load_state __c __sync_fish_colors __sync_terminal_palette \
        __sync_fzf __sync_bat __sync_starship __sync_eza __sync_nvim \
        __sync_emit_events __sync_notify __sync_write_cache 2>/dev/null

end
