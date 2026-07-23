# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ash_help Ultra                                     ║
# ║  Complete interactive help system with search, examples & rich display     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash_help --description "ASH Dotfiles interactive help system"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLOR RESOLUTION                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l ITAL   (set_color --italics 2>/dev/null; or echo "")

    function __h_c --description "Resolve ASH theme color"
        set -l key "ASH_COLOR_"(string upper $argv[1])
        set -l fb  $argv[2]
        if set -q $key
            set_color (string replace '#' '' $$key) 2>/dev/null && return
        end
        set_color $fb 2>/dev/null
    end

    set -l C1  (__h_c mauve    magenta)   # Primary accent (purple)
    set -l C2  (__h_c blue     blue)      # Commands
    set -l C3  (__h_c green    green)     # Success / OK
    set -l C4  (__h_c yellow   yellow)    # Flags / options
    set -l C5  (__h_c red      red)       # Warnings
    set -l C6  (__h_c sky      cyan)      # Info / examples
    set -l C7  (__h_c peach    FF9F43)    # Categories
    set -l C8  (__h_c teal     94e2d5)    # Subcommands
    set -l C9  (__h_c lavender b4befe)    # Notes
    set -l C10 (__h_c text     cdd6f4)    # Normal text

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📚 HELP DATA: Command definitions                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Help categories ────────────────────────────────────────────────────────
    set -l categories \
        "theme:🎨 Theme Management" \
        "mode:🎭 Desktop Modes" \
        "plugin:🔌 Plugin System" \
        "snapshot:📸 Snapshots" \
        "config:⚙️  Configuration" \
        "doctor:🏥 Diagnostics" \
        "update:🔄 Updates" \
        "shot:📷 Screenshots" \
        "wallpaper:🖼️  Wallpaper" \
        "bar:📊 Status Bar" \
        "power:⚡ Power" \
        "monitor:🖥️  Monitors" \
        "audio:🔊 Audio" \
        "bluetooth:📶 Bluetooth" \
        "window:🪟 Windows" \
        "workspace:🗂️  Workspaces" \
        "gaming:🎮 Gaming" \
        "backup:💾 Backup" \
        "analytics:📈 Analytics" \
        "ai:🤖 AI Assistant" \
        "macro:📼 Macros" \
        "cloud:☁️  Cloud Sync" \
        "store:🏪 Theme Store" \
        "profile:👤 Profiles" \
        "remote:🌍 Remote" \
        "hw:💻 Hardware Info" \
        "net:🌐 Network" \
        "benchmark:📊 Benchmarks" \
        "migrate:🔀 Migration"

    # ── Command reference database ─────────────────────────────────────────────
    # Format: category|command|description|example
    set -l commands_db \
        "theme|ash theme apply <name>|Apply a theme by name|ash theme apply catppuccin-mocha" \
        "theme|ash theme pick|Interactively pick a theme with preview|ash theme pick" \
        "theme|ash theme random [category]|Apply a random theme|ash theme random dark" \
        "theme|ash theme list [--category <cat>]|List all available themes|ash theme list --category neon" \
        "theme|ash theme create <name>|Create a new theme|ash theme create my-theme" \
        "theme|ash theme edit <name>|Edit an existing theme|ash theme edit catppuccin-mocha" \
        "theme|ash theme clone <src> <new>|Clone a theme as a new one|ash theme clone nord my-nord" \
        "theme|ash theme export <name>|Export theme to file|ash theme export tokyonight > theme.json" \
        "theme|ash theme import <file>|Import theme from file|ash theme import ./my-theme.json" \
        "theme|ash theme preview <name>|Preview theme without applying|ash theme preview gruvbox-dark" \
        "theme|ash theme delete <name>|Delete a custom theme|ash theme delete my-old-theme" \
        "theme|ash theme schedule|Schedule automatic theme switching|ash theme schedule --day nord --night catppuccin-mocha" \
        "theme|ash theme ai-generate|Generate theme using AI (Ollama)|ash theme ai-generate --prompt 'forest at night'" \
        "theme|ash theme ai-mood|Generate theme from mood description|ash theme ai-mood --mood focused" \
        "theme|ash theme store-browse|Browse the community theme store|ash theme store-browse" \
        "theme|ash theme wallpaper|Manage theme wallpaper|ash theme wallpaper set ~/pics/bg.jpg" \
        "theme|ash theme validate <name>|Validate theme configuration|ash theme validate my-theme" \
        "theme|ash theme history|Show theme switch history|ash theme history" \
        "theme|ash theme favorite [name]|Mark/list favorite themes|ash theme favorite catppuccin-mocha" \
        "theme|ash theme sync|Sync themes with cloud|ash theme sync" \
        "mode|ash mode game|Enable gaming optimizations|ash mode game --mangohud" \
        "mode|ash mode work|Enable work/productivity mode|ash mode work" \
        "mode|ash mode focus [--timer <min>]|Focus mode with optional Pomodoro|ash mode focus --timer 25" \
        "mode|ash mode cinema|Cinema/presentation mode|ash mode cinema" \
        "mode|ash mode stream|Streaming/OBS-ready mode|ash mode stream" \
        "mode|ash mode battery|Battery saver mode|ash mode battery" \
        "mode|ash mode privacy|Privacy mode (disable logging)|ash mode privacy" \
        "mode|ash mode present|Clean presentation mode|ash mode present" \
        "mode|ash mode default|Reset to default mode|ash mode default" \
        "mode|ash mode list|List available modes|ash mode list" \
        "mode|ash mode status|Show current mode|ash mode status" \
        "plugin|ash plugin install <name>|Install a plugin|ash plugin install game-mode" \
        "plugin|ash plugin remove <name>|Remove a plugin|ash plugin remove caffeine" \
        "plugin|ash plugin list [--enabled]|List installed plugins|ash plugin list --enabled" \
        "plugin|ash plugin browse|Browse available plugins|ash plugin browse" \
        "plugin|ash plugin update <name>|Update a plugin|ash plugin update game-mode" \
        "plugin|ash plugin update-all|Update all plugins|ash plugin update-all" \
        "plugin|ash plugin enable <name>|Enable a disabled plugin|ash plugin enable night-light" \
        "plugin|ash plugin disable <name>|Disable a plugin|ash plugin disable blur-toggle" \
        "plugin|ash plugin info <name>|Show plugin details|ash plugin info game-mode" \
        "plugin|ash plugin create <name>|Scaffold a new plugin|ash plugin create my-plugin" \
        "snapshot|ash snapshot create [--tag <tag>]|Create a config snapshot|ash snapshot create --tag 'pre-update'" \
        "snapshot|ash snapshot restore <id>|Restore a snapshot|ash snapshot restore abc123" \
        "snapshot|ash snapshot list|List all snapshots|ash snapshot list" \
        "snapshot|ash snapshot diff <id1> <id2>|Compare two snapshots|ash snapshot diff abc123 def456" \
        "snapshot|ash snapshot delete <id>|Delete a snapshot|ash snapshot delete abc123" \
        "snapshot|ash snapshot export <id>|Export snapshot to file|ash snapshot export abc123 > backup.tar.gz" \
        "snapshot|ash snapshot pin <id>|Pin snapshot (prevent auto-delete)|ash snapshot pin abc123" \
        "snapshot|ash snapshot clean [--keep <n>]|Remove old snapshots|ash snapshot clean --keep 10" \
        "config|ash config get <key>|Get a config value|ash config get theme.default" \
        "config|ash config set <key> <val>|Set a config value|ash config set theme.variant dark" \
        "config|ash config list [--section]|List all config values|ash config list --section theme" \
        "config|ash config edit|Open config in editor|ash config edit" \
        "config|ash config reset [--key <k>]|Reset config to defaults|ash config reset" \
        "config|ash config export|Export config to stdout|ash config export > my-config.json" \
        "config|ash config validate|Validate config file|ash config validate" \
        "doctor|ash doctor|Run quick health check|ash doctor" \
        "doctor|ash doctor quick|Fast health check (< 5s)|ash doctor quick" \
        "doctor|ash doctor full|Comprehensive check (all modules)|ash doctor full" \
        "doctor|ash doctor fix|Auto-fix detected issues|ash doctor fix" \
        "doctor|ash doctor report|Generate health report|ash doctor report --format html" \
        "update|ash update all|Update everything|ash update all" \
        "update|ash update system|Update system packages|ash update system" \
        "update|ash update dotfiles|Update ASH from git|ash update dotfiles" \
        "update|ash update plugins|Update all plugins|ash update plugins" \
        "update|ash update themes|Update all themes|ash update themes" \
        "update|ash update check|Check for updates|ash update check" \
        "update|ash update rollback|Rollback last update|ash update rollback" \
        "shot|ash shot full|Full screenshot|ash shot full" \
        "shot|ash shot area|Select region screenshot|ash shot area" \
        "shot|ash shot window|Active window screenshot|ash shot window" \
        "shot|ash shot ocr|Screenshot with OCR text extraction|ash shot ocr" \
        "shot|ash shot record|Record screen to video|ash shot record" \
        "shot|ash shot gif|Record to GIF|ash shot gif" \
        "shot|ash shot color|Pick color from screen|ash shot color" \
        "wallpaper|ash wallpaper set <file>|Set a wallpaper|ash wallpaper set ~/pics/bg.jpg" \
        "wallpaper|ash wallpaper random [cat]|Random wallpaper|ash wallpaper random nature" \
        "wallpaper|ash wallpaper pick|Interactive wallpaper picker|ash wallpaper pick" \
        "wallpaper|ash wallpaper slideshow|Start wallpaper slideshow|ash wallpaper slideshow --interval 300" \
        "wallpaper|ash wallpaper generate-ai|AI-generated wallpaper|ash wallpaper generate-ai --prompt 'cyberpunk city'" \
        "ai|ash ai chat|Chat with AI assistant|ash ai chat" \
        "ai|ash ai suggest-theme|Get AI theme suggestions|ash ai suggest-theme" \
        "ai|ash ai fix-issue|AI diagnose and fix issues|ash ai fix-issue" \
        "ai|ash ai explain <cmd>|Explain a command|ash ai explain 'find . -type f -mtime -7'" \
        "ai|ash ai optimize-config|AI optimize configuration|ash ai optimize-config" \
        "hw|ash hw full-report|Complete hardware report|ash hw full-report" \
        "hw|ash hw cpu|CPU information|ash hw cpu" \
        "hw|ash hw gpu|GPU information|ash hw gpu" \
        "hw|ash hw memory|Memory information|ash hw memory" \
        "hw|ash hw battery|Battery status|ash hw battery" \
        "hw|ash hw sensors|Temperature sensors|ash hw sensors" \
        "net|ash net status|Network status|ash net status" \
        "net|ash net speed|Speed test|ash net speed" \
        "net|ash net wifi|WiFi management|ash net wifi" \
        "net|ash net vpn|VPN management|ash net vpn" \
        "gaming|ash gaming optimize|Apply gaming optimizations|ash gaming optimize" \
        "gaming|ash gaming mangohud|Toggle MangoHUD overlay|ash gaming mangohud" \
        "gaming|ash gaming proton|Manage Proton versions|ash gaming proton" \
        "backup|ash backup create|Create config backup|ash backup create" \
        "backup|ash backup restore|Restore from backup|ash backup restore" \
        "backup|ash backup list|List backups|ash backup list" \
        "migrate|ash migrate from-hyde|Migrate from HyDE|ash migrate from-hyde --path ~/HyDE" \
        "migrate|ash migrate from-hyprdots|Migrate from hyprdots|ash migrate from-hyprdots" \
        "migrate|ash migrate from-ml4w|Migrate from ML4W|ash migrate from-ml4w"

    # ── Keyboard shortcuts reference ───────────────────────────────────────────
    set -l shortcuts_db \
        "Ctrl-R|History search (Atuin/McFly/fzf)" \
        "Ctrl-T|File picker (fzf)" \
        "Alt-C|Directory jump (fzf)" \
        "Ctrl-G|Git status browser (fzf)" \
        "Ctrl-K|Kill process picker (fzf)" \
        "Ctrl-N|Navigate with zoxide + fzf" \
        "Alt-E|Open file in editor (fzf)" \
        "Alt-S|SSH host picker (fzf)" \
        "Alt-T|ASH theme picker" \
        "Alt-Z|Interactive zoxide jump" \
        "Alt-M|Man page browser (fzf)" \
        "Ctrl-\\|Env variable browser (fzf)" \
        "F1|ASH help" \
        "F2|ASH mode selector" \
        "F3|Create ASH snapshot" \
        "F4|Open nvim in current directory" \
        "Ctrl-X Ctrl-E|Edit commandline in editor" \
        "Ctrl-B|Run with done notification" \
        "Alt-.|Insert last argument" \
        "Ctrl-Z|Smart bg/fg toggle" \
        "Alt-R|Reload Fish config" \
        "Ctrl-Y|Copy commandline to clipboard" \
        "Ctrl-V|Paste from clipboard" \
        "Ctrl-L|Clear screen" \
        "Escape|Vi normal mode (vi bindings)" \
        "jk (vi)|Return to normal mode" \
        "/ (vi-normal)|History search" \
        "Y (vi-normal)|Yank line to clipboard" \
        "; (vi-normal)|Leader key menu" \
        ",f (vi-normal)|fzf file picker" \
        ",g (vi-normal)|fzf git status"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _topic   ""
    set -l _search  ""
    set -l _command ""
    set -l _keys    0
    set -l _all     0
    set -l _version 0

    argparse \
        'h/help' \
        'k/keys' \
        'a/all' \
        'v/version' \
        's/search=' \
        'c/command=' \
        -- $argv 2>/dev/null

    set -q _flag_help    && set _topic help
    set -q _flag_keys    && set _keys  1
    set -q _flag_all     && set _all   1
    set -q _flag_version && set _version 1
    set -q _flag_search  && set _search $_flag_search
    set -q _flag_command && set _command $_flag_command

    # Positional: first arg is topic
    test (count $argv) -ge 1 && test -z "$_topic" && set _topic $argv[1]

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📐 UI PRIMITIVES                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __h_banner --description "Render ASH help banner"
        echo ""
        echo $BOLD$C1"  ╔══════════════════════════════════════════════════════════════╗"$R
        echo $BOLD$C1"  ║  ⚡ ASH DOTFILES v5.0 OMEGA — Interactive Help System       ║"$R
        echo $BOLD$C1"  ║     🏆 The Most Advanced Dotfiles in Human History           ║"$R
        echo $BOLD$C1"  ╚══════════════════════════════════════════════════════════════╝"$R
        echo ""
    end

    function __h_section --description "Print section header"
        set -l title $argv[1]
        set -l icon  $argv[2]
        echo ""
        echo $BOLD$C7"  ┌─ $icon $title "$DIM(string repeat -n (math 50 - (string length "$icon $title")) "─")$R
        echo ""
    end

    function __h_cmd_row --description "Print a command row"
        set -l cmd  $argv[1]
        set -l desc $argv[2]
        set -l ex   $argv[3]
        printf "  $C2  %-40s$R  $DIM%s$R\n" $cmd $desc
        test -n "$ex" && \
            printf "  $DIM  Example: $C6%s$R\n" $ex
    end

    function __h_key_row --description "Print a keybind row"
        set -l key  $argv[1]
        set -l desc $argv[2]
        printf "  $C4%-22s$R  $DIM%s$R\n" $key $desc
    end

    function __h_category_row --description "Print a category row"
        set -l icon  $argv[1]
        set -l name  $argv[2]
        set -l desc  $argv[3]
        printf "  $C7%-4s$R  $BOLD$C8%-18s$R  $DIM%s$R\n" $icon $name $desc
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 SEARCH FUNCTION                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __h_search --description "Search help database"
        set -l query  (string lower $argv[1])
        set -l found  0

        echo ""
        echo $BOLD$C6"  🔍 Search results for: '$argv[1]'"$R
        echo ""

        for entry in $commands_db
            set -l parts (string split '|' $entry)
            set -l cat   $parts[1]
            set -l cmd   $parts[2]
            set -l desc  $parts[3]
            set -l ex    $parts[4]

            if string match -qi "*$query*" $cmd || \
               string match -qi "*$query*" $desc || \
               string match -qi "*$query*" $cat
                printf "  $C7[%-12s]$R  $C2%-38s$R\n" $cat $cmd
                printf "  $DIM%14s%s$R\n" "" $desc
                test -n "$ex" && printf "  $DIM%14sExample: $C6%s$R\n" "" $ex
                echo ""
                set found (math $found + 1)
            end
        end

        if test $found -eq 0
            echo "  $C5No results found for '$argv[1]'$R"
            echo "  $DIM Try a broader search term$R"
        else
            echo "  $DIM Found $found result(s)$R"
        end
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 TOPIC RENDERERS                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Version info ──────────────────────────────────────────────────────────
    function __h_version --description "Show version information"
        echo ""
        echo $BOLD$C1"  ╔══════════════════════════════════════════════════╗"$R
        echo $BOLD$C1"  ║     ⚡  ASH DOTFILES v5.0 OMEGA                  ║"$R
        echo $BOLD$C1"  ╚══════════════════════════════════════════════════╝"$R
        echo ""

        set -l ver_file "$HOME/.local/share/ash/version.json"
        if test -f $ver_file && command -q jq
            echo "  "$BOLD"Version:     "$R $C6(jq -r '.version // "5.0.0"' $ver_file)$R
            echo "  "$BOLD"Build:       "$R $DIM(jq -r '.build   // "omega"'   $ver_file)$R
            echo "  "$BOLD"Released:    "$R $DIM(jq -r '.date    // "2024"'    $ver_file)$R
        else
            echo "  "$BOLD"Version:     "$R $C6"5.0.0 OMEGA"$R
        end

        echo "  "$BOLD"Fish:        "$R $DIM(fish --version 2>/dev/null)$R
        echo "  "$BOLD"Neovim:      "$R $DIM(nvim --version 2>/dev/null | head -1)$R
        echo ""

        # Stats
        echo "  "$BOLD"📊 Statistics:"$R
        set -l themes_count (find "$HOME/.config/ash/themes/presets" -type d -mindepth 2 -maxdepth 2 2>/dev/null | wc -l | string trim)
        set -l plugins_count (find "$HOME/.config/ash/plugins" -name "plugin.json" 2>/dev/null | wc -l | string trim)
        set -l snap_count (find "$HOME/.local/share/ash/snapshots" -name "*.json" 2>/dev/null | wc -l | string trim)

        printf "  $DIM  %-16s$R  $C3%s$R\n" "Themes:"   (test -n "$themes_count"  && echo $themes_count  || echo "0")
        printf "  $DIM  %-16s$R  $C3%s$R\n" "Plugins:"  (test -n "$plugins_count" && echo $plugins_count || echo "0")
        printf "  $DIM  %-16s$R  $C3%s$R\n" "Snapshots:" (test -n "$snap_count"   && echo $snap_count    || echo "0")
        echo ""
    end

    # ── Main overview ──────────────────────────────────────────────────────────
    function __h_overview --description "Show main help overview"
        __h_banner

        echo "  $C10Use $BOLD$C2ash <command> [subcommand] [options]$R"
        echo "  $DIM  For detailed help: $C2ash_help <topic>$R  or  $C2ash_help --search <query>$R"
        echo ""

        __h_section "Command Categories" "📚"

        for cat in $categories
            set -l parts (string split ':' $cat)
            set -l key   $parts[1]
            set -l label $parts[2]

            # Count commands in this category
            set -l count 0
            for entry in $commands_db
                string match -q "$key|*" $entry && set count (math $count + 1)
            end

            printf "  $C7%-30s$R  $DIM%3d commands$R  $DIM→ ash_help %s$R\n" \
                $label $count $key
        end

        echo ""
        echo "  $DIM┌───────────────────────────────────────────────────────────┐$R"
        echo "  $DIM│$R  $BOLD Quick References:$R"
        echo "  $DIM│$R"
        printf "  $DIM│$R  $C4%-20s$R  %s\n"    "ash_help keys"      "Keyboard shortcuts reference"
        printf "  $DIM│$R  $C4%-20s$R  %s\n"    "ash_help theme"     "Theme management commands"
        printf "  $DIM│$R  $C4%-20s$R  %s\n"    "ash_help mode"      "Desktop mode commands"
        printf "  $DIM│$R  $C4%-20s$R  %s\n"    "ash_help plugin"    "Plugin system commands"
        printf "  $DIM│$R  $C4%-20s$R  %s\n"    "ash --help"         "ASH CLI built-in help"
        printf "  $DIM│$R  $C4%-20s$R  %s\n"    "ash doctor"         "System health check"
        echo "  $DIM└───────────────────────────────────────────────────────────┘$R"
        echo ""

        # Quick tips
        echo "  $BOLD$C9💡 Quick Tips:$R"
        echo ""
        echo "  $DIM→$R  Tab completion works for all $C2ash$R subcommands and options"
        echo "  $DIM→$R  Most commands support $C4--dry-run$R for safe previewing"
        echo "  $DIM→$R  Use $C2ash snapshot create$R before major changes"
        echo "  $DIM→$R  Run $C2ash doctor$R if something isn't working"
        echo "  $DIM→$R  $C2ash theme ai-generate$R creates unique themes with AI"
        echo ""
    end

    # ── Keys reference ─────────────────────────────────────────────────────────
    function __h_keys --description "Show keyboard shortcuts reference"
        __h_banner
        __h_section "Keyboard Shortcuts" "⌨️"

        echo "  $DIM($R$C9fish + fzf + vi mode$R$DIM)$R"
        echo ""

        set -l groups \
            "History & Search" \
            "File Navigation" \
            "Git & Docker" \
            "ASH Commands" \
            "Editor Controls" \
            "Vi Mode (Normal)" \
            "Clipboard" \
            "Shell Control"

        set -l group_shortcuts \
            "Ctrl-R|History search (Atuin/McFly/fzf):Ctrl-N|Navigate dirs (zoxide+fzf):Alt-P|Previous history:Alt-N|Next history" \
            "Ctrl-T|File picker:Alt-C|Change directory (fzf):Alt-E|Edit file (fzf+nvim):Alt-W|Show directory tree" \
            "Ctrl-G|Git status browser:Alt-D|Docker container picker:Alt-S|SSH host picker" \
            "Alt-T|Theme picker:F1|ASH help:F2|Mode selector:F3|Create snapshot:F4|Open nvim here:Ctrl-B|Notify when done" \
            "Ctrl-X Ctrl-E|Edit cmdline in editor:Alt-.|Last argument:Ctrl-Z|Smart bg/fg:Alt-R|Reload config" \
            "/ |History search:Y|Yank line to clipboard:,f|fzf file picker:,g|fzf git status:,d|fzf dir picker:gf|Open file under cursor:gg|First history:G|Last history" \
            "Ctrl-Y|Copy cmdline to clipboard:Ctrl-V|Paste from clipboard" \
            "Ctrl-L|Clear screen:Ctrl-A|Line start:Ctrl-E|Line end:Ctrl-W|Delete word backward:Ctrl-U|Kill to line start:Escape|Vi normal mode"

        for i in (seq (count $groups))
            set -l group_name $groups[$i]
            set -l group_keys (string split ':' $group_shortcuts[$i])

            echo "  $BOLD$C8  $group_name$R"
            for ks in $group_keys
                set -l kparts (string split '|' $ks)
                __h_key_row $kparts[1] $kparts[2]
            end
            echo ""
        end
    end

    # ── Category-specific help ─────────────────────────────────────────────────
    function __h_category --description "Show commands for a specific category"
        set -l cat   $argv[1]
        set -l label $argv[2]

        __h_banner

        # Find category label from categories
        if test -z "$label"
            for c in $categories
                set -l parts (string split ':' $c)
                if test $parts[1] = $cat
                    set label $parts[2]
                    break
                end
            end
        end

        __h_section $label "📋"

        set -l found 0
        for entry in $commands_db
            set -l parts (string split '|' $entry)
            set -l ecategory $parts[1]
            set -l cmd       $parts[2]
            set -l desc      $parts[3]
            set -l example   $parts[4]

            test "$ecategory" = $cat || continue
            set found (math $found + 1)

            printf "  $C2  %-42s$R\n" $cmd
            printf "  $DIM   %s$R\n" $desc
            test -n "$example" && \
                printf "  $DIM   Example: $C6%s$R\n" $example
            echo ""
        end

        if test $found -eq 0
            echo "  $C5No commands found for category: $cat$R"
        end

        # Category-specific tips
        switch $cat
            case theme
                echo "  $BOLD$C9💡 Theme Tips:$R"
                echo "  $DIM→$R  $C2ash theme apply catppuccin-mocha$R  — apply popular theme"
                echo "  $DIM→$R  $C2ash theme random dark$R  — random dark theme"
                echo "  $DIM→$R  $C2ash theme ai-generate --prompt 'sunset ocean'$R  — AI theme"
                echo "  $DIM→$R  Set $C4ASH_THEME_NOTIFICATIONS=1$R to get system notifications"
            case mode
                echo "  $BOLD$C9💡 Mode Tips:$R"
                echo "  $DIM→$R  $C2ash mode game$R  — disables blur, animations, maximizes performance"
                echo "  $DIM→$R  $C2ash mode focus --timer 25$R  — 25-minute Pomodoro session"
                echo "  $DIM→$R  Modes are automatically restored after reboot"
            case plugin
                echo "  $BOLD$C9💡 Plugin Tips:$R"
                echo "  $DIM→$R  $C2ash plugin browse$R  — discover 150+ community plugins"
                echo "  $DIM→$R  $C2ash plugin create my-plugin$R  — scaffold a new plugin"
                echo "  $DIM→$R  Plugins persist across sessions automatically"
            case doctor
                echo "  $BOLD$C9💡 Doctor Tips:$R"
                echo "  $DIM→$R  Run $C2ash doctor fix$R  after $C2ash doctor full$R  to auto-repair"
                echo "  $DIM→$R  $C2ash doctor report --format html$R  for shareable reports"
        end

        echo ""
    end

    # ── Interactive fzf help browser ───────────────────────────────────────────
    function __h_interactive --description "Launch interactive help browser with fzf"
        command -q fzf || begin
            __h_overview
            return
        end

        set -l selected (
            begin
                for entry in $commands_db
                    set -l parts (string split '|' $entry)
                    printf "$C7[%-12s]$R  $C2%-38s$R  $DIM%s$R\n" \
                        $parts[1] $parts[2] $parts[3]
                end
            end |
            fzf --ansi \
                --no-sort \
                --border-label "  ⚡ ASH Help Browser " \
                --border rounded \
                --prompt "  🔍 Search: " \
                --pointer "▶" \
                --marker "✓" \
                --preview '
                    cmd=$(echo {} | awk -F"  " "{print \$2}" | string trim)
                    echo ""
                    echo "  Command: $cmd"
                    echo ""
                    # Show description
                    echo {} | awk -F"  " "{print \$3}"
                    echo ""
                    echo "  Run: ash_help --command \"$cmd\""
                ' \
                --preview-window 'right:40%:border-rounded:wrap' \
                --header '  Enter:view details  Ctrl-E:run command  Ctrl-C:exit  ' \
                --bind 'ctrl-e:execute(echo {} | awk -F"  " "{print \$2}" | string trim | xargs ash)+abort' \
                --height 80%
        )
    end

    # ── Command detail view ────────────────────────────────────────────────────
    function __h_command_detail --description "Show detailed info for a specific command"
        set -l query $argv[1]

        echo ""
        echo $BOLD$C1"  📖 Command Detail: $query"$R
        echo ""

        set -l found 0
        for entry in $commands_db
            set -l parts (string split '|' $entry)
            string match -qi "*$query*" $parts[2] || continue

            set found (math $found + 1)
            echo "  $BOLD$C2  $parts[2]$R"
            echo "  $DIM  $parts[3]$R"
            test -n "$parts[4]" && begin
                echo ""
                echo "  $BOLD Example:$R"
                echo "    $C6\$ $parts[4]$R"
            end
            echo ""
        end

        test $found -eq 0 && echo "  $C5Command not found: $query$R"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MAIN DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Version
    if test $_version -eq 1
        __h_version
        return 0
    end

    # Search
    if test -n "$_search"
        __h_search $_search
        return 0
    end

    # Specific command detail
    if test -n "$_command"
        __h_command_detail $_command
        return 0
    end

    # Keyboard shortcuts
    if test $_keys -eq 1
        __h_keys
        return 0
    end

    # Topic dispatch
    switch $_topic
        case '' index
            # No topic: interactive browser if fzf, else overview
            if command -q fzf && test $_all -eq 0
                __h_interactive
            else
                __h_overview
            end

        case help
            __h_overview

        case keys bindings shortcuts
            __h_keys

        case version
            __h_version

        case all
            # Show everything
            __h_overview
            __h_keys
            for cat in $categories
                set -l parts (string split ':' $cat)
                __h_category $parts[1] $parts[2]
            end

        case theme mode plugin snapshot config doctor update shot wallpaper \
             bar power monitor audio bluetooth window workspace gaming backup \
             analytics ai macro cloud store profile remote hw net benchmark migrate
            # Find category label
            set -l label ""
            for c in $categories
                set -l parts (string split ':' $c)
                if test $parts[1] = $_topic
                    set label $parts[2]
                    break
                end
            end
            __h_category $_topic $label

        case '*'
            # Unknown topic: search for it
            __h_search $_topic
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __h_c __h_banner __h_section __h_cmd_row __h_key_row \
        __h_category_row __h_search __h_version __h_overview __h_keys \
        __h_category __h_interactive __h_command_detail 2>/dev/null

end

# ── Alias: 'ashhelp' also works ───────────────────────────────────────────────
function ashhelp --wraps=ash_help --description "Alias for ash_help"
    ash_help $argv
end
