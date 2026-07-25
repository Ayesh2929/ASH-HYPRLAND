# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔥  ASH CLI — FISH COMPLETIONS v5.0 OMEGA                                 ║
# ║  Ultra Premium • Intelligent • Context-Aware • Dynamic                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Completion guard ───────────────────────────────────────────────────────────
function __ash_completion_guard
    not __fish_seen_subcommand_from $argv
end

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC DATA SOURCES
# ══════════════════════════════════════════════════════════════════════════════

# ── List installed themes ──────────────────────────────────────────────────────
function __ash_list_themes
    set -l theme_dirs \
        "$HOME/.config/ash/themes" \
        "$HOME/.local/share/ash/themes" \
        "/usr/share/ash/themes"
    for d in $theme_dirs
        if test -d "$d"
            for f in (find "$d" -name "*.conf" -o -name "*.json" 2>/dev/null)
                basename (dirname "$f")
            end
        end
    end
    # Hardcoded premium presets as fallback
    printf '%s\n' \
        catppuccin-mocha catppuccin-macchiato catppuccin-frappe \
        catppuccin-latte tokyo-night tokyo-night-storm tokyo-night-moon \
        gruvbox-dark gruvbox-dark-hard gruvbox-material gruvbox-light \
        nord dracula dracula-pro one-dark one-dark-pro one-light \
        everforest-dark everforest-light kanagawa-wave kanagawa-dragon \
        rose-pine rose-pine-moon rose-pine-dawn material-ocean \
        material-palenight ayu-dark ayu-mirage ayu-light \
        solarized-dark solarized-light nightfox carbonfox oxocarbon \
        melange vesper moonfly cyberpunk-2077 synthwave-84 matrix-green \
        tron-legacy neon-dreams outrun retrowave forest-deep ocean-dark \
        aurora-borealis sakura-spring nebula-blue galaxy-spiral \
        vaporwave 8bit-gameboy terminal-green pure-black zen \
        pride-rainbow accessibility-high-contrast | sort -u
end

# ── List installed plugins ─────────────────────────────────────────────────────
function __ash_list_plugins
    set -l plugin_dir "$HOME/.local/share/ash/plugins"
    if test -d "$plugin_dir"
        for d in (find "$plugin_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
            basename "$d"
        end
    end
    printf '%s\n' \
        game-mode caffeine auto-wallpaper blur-toggle focus-timer \
        pip-mode night-light do-not-disturb workspace-rules screen-recorder \
        color-picker clipboard-manager weather-display media-controls \
        opacity-control border-effects screenshot-actions notification-history \
        battery-alerts network-monitor disk-monitor cpu-monitor temp-monitor \
        auto-mount auto-backup startup-apps workspace-names window-follow-mouse \
        smart-borders dynamic-gaps music-visualizer kaomoji-picker \
        quick-translate dict-lookup qr-generator password-gen timer-overlay \
        stopwatch alarm habit-tracker session-restore cloud-sync backup-auto \
        analytics macro-recorder ai-assistant remote-control profile-switcher \
        gesture-control auto-theme smart-gaps window-history workspace-auto \
        window-swallow scratchpad-plus tiling-master sticky-windows \
        window-preview smart-resize auto-rotate battery-saver \
        discord-rpc spotify-control github-status home-assistant \
        stream-deck obs-control | sort -u
end

# ── List snapshots ─────────────────────────────────────────────────────────────
function __ash_list_snapshots
    set -l snap_dir "$HOME/.local/share/ash/snapshots"
    if test -d "$snap_dir"
        for d in (find "$snap_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
            basename "$d"
        end
    else
        printf '%s\n' \
            "snap-$(date +%Y%m%d)-001" \
            "snap-$(date +%Y%m%d)-002" \
            "auto-daily" "auto-weekly" "pre-update" "manual"
    end
end

# ── List macros ────────────────────────────────────────────────────────────────
function __ash_list_macros
    ash macro list 2>/dev/null | tail -n +3 | awk '{print $1}'
end

# ── List profiles ──────────────────────────────────────────────────────────────
function __ash_list_profiles
    printf '%s\n' default work gaming streaming minimal custom
end

# ── List modes ─────────────────────────────────────────────────────────────────
function __ash_list_modes
    printf '%s\n' \
        default game work focus cinema present battery stream privacy accessibility
end

# ── List bar layouts ───────────────────────────────────────────────────────────
function __ash_list_bar_layouts
    printf '%s\n' \
        top-bar bottom-bar dual-bar-top dual-bar-bottom floating-bar \
        minimal-bar maximal-bar vertical-left vertical-right island-bar zen-bar gaming-bar
end

# ── List wallpaper categories ──────────────────────────────────────────────────
function __ash_list_wallpaper_categories
    printf '%s\n' \
        dark light minimal abstract nature space anime cyberpunk retro \
        architecture 4k ultrawide dual-monitor animated generated user
end

# ── List animation presets ─────────────────────────────────────────────────────
function __ash_list_animations
    printf '%s\n' default smooth bouncy snappy cinematic minimal none performance custom
end

# ── List ECC levels ───────────────────────────────────────────────────────────
function __ash_list_ecc
    printf '%s\t%s\n' \
        L "Low (7% recovery)" \
        M "Medium (15% recovery)" \
        Q "Quartile (25% recovery)" \
        H "High (30% recovery)"
end

# ── List GPU vendors ──────────────────────────────────────────────────────────
function __ash_list_gpu_vendors
    printf '%s\n' amd nvidia intel
end

# ── List cloud providers ──────────────────────────────────────────────────────
function __ash_list_cloud_providers
    printf '%s\n' github gitlab s3 gdrive onedrive dropbox custom
end

# ── List config keys ──────────────────────────────────────────────────────────
function __ash_list_config_keys
    printf '%s\t%s\n' \
        "theme.auto_change"           "Auto-change theme on schedule" \
        "theme.schedule"              "Cron schedule for theme changes" \
        "theme.transition_speed"      "Theme transition animation speed" \
        "theme.default"               "Default theme name" \
        "wallpaper.backend"           "Wallpaper setter: swww/swaybg/hyprpaper" \
        "wallpaper.slideshow_interval" "Slideshow interval in seconds" \
        "wallpaper.blur_radius"       "Blur radius for lock screen" \
        "bar.layout"                  "Default bar layout" \
        "bar.position"                "Bar position: top/bottom" \
        "bar.height"                  "Bar height in pixels" \
        "notifications.backend"       "Notification daemon: dunst/swaync" \
        "notifications.sounds"        "Enable notification sounds" \
        "plugins.auto_update"         "Auto-update plugins" \
        "plugins.directory"           "Plugin installation directory" \
        "snapshots.auto_create"       "Auto-create snapshots" \
        "snapshots.max_keep"          "Max snapshots to keep" \
        "snapshots.interval"          "Auto-snapshot interval" \
        "ai.provider"                 "AI provider: ollama/openai/local" \
        "ai.model"                    "AI model name" \
        "ai.theme_generation"         "Enable AI theme generation" \
        "cloud.provider"              "Cloud sync provider" \
        "cloud.auto_sync"             "Enable automatic cloud sync" \
        "analytics.enabled"           "Enable usage analytics" \
        "analytics.interval"          "Analytics collection interval" \
        "gaming.mangohud"             "Enable MangoHUD in game mode" \
        "gaming.gamemode"             "Enable Gamemode in game mode" \
        "focus.app_blocklist"         "Apps to block in focus mode" \
        "backup.auto"                 "Enable automatic backups" \
        "backup.interval"             "Backup interval" \
        "backup.destination"          "Backup destination path"
end

# ── List AI providers ─────────────────────────────────────────────────────────
function __ash_list_ai_providers
    printf '%s\t%s\n' \
        ollama    "Local Ollama instance" \
        openai    "OpenAI API (GPT-4)" \
        anthropic "Anthropic API (Claude)" \
        local     "Local model (no API)"
end

# ── List store categories ─────────────────────────────────────────────────────
function __ash_list_store_categories
    printf '%s\n' \
        themes plugins wallpapers cursors icons fonts all trending featured
end

# ── List migrate sources ──────────────────────────────────────────────────────
function __ash_list_migrate_sources
    printf '%s\t%s\n' \
        hyde      "HyDE dotfiles" \
        hyprdots  "HyprDots dotfiles" \
        ml4w      "ML4W dotfiles" \
        end-4     "end-4 dotfiles" \
        manual    "Manual migration wizard"
end

# ── Check if current token is an ash subcommand ───────────────────────────────
function __ash_needs_subcommand
    set -l tokens (commandline -poc)
    set -l count (count $tokens)
    test $count -le 1
end

function __ash_subcommand_is --argument-names sub
    set -l tokens (commandline -poc)
    contains -- "$sub" $tokens
end

function __ash_no_subcommand
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            theme mode plugin snapshot config doctor hw net update \
            shot wallpaper bar power monitor audio bluetooth window \
            workspace gaming backup analytics profile cloud store \
            session ai macro remote benchmark migrate completion \
            reload doctor update help version
            return 1
        end
    end
    return 0
end

# ══════════════════════════════════════════════════════════════════════════════
#  TOP-LEVEL COMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l ash_commands \
    "theme\t🎨 Theme management & generation" \
    "mode\t🎭 Desktop mode switching" \
    "plugin\t🔌 Plugin manager" \
    "snapshot\t📸 Config snapshots" \
    "config\t⚙️  Configuration editor" \
    "doctor\t🏥 System health check" \
    "hw\t🖥️  Hardware info & benchmark" \
    "net\t🌐 Network utilities" \
    "update\t🔄 Update system & components" \
    "shot\t📷 Screenshot & screen record" \
    "wallpaper\t🖼️  Wallpaper management" \
    "bar\t📊 Status bar control" \
    "power\t⚡ Power management" \
    "monitor\t🖥️  Monitor management" \
    "audio\t🔊 Audio control" \
    "bluetooth\t🔵 Bluetooth manager" \
    "window\t🪟  Window management" \
    "workspace\t🗂️  Workspace control" \
    "gaming\t🎮 Gaming utilities" \
    "backup\t💾 Backup & restore" \
    "analytics\t📊 Usage analytics" \
    "profile\t👤 Profile switcher" \
    "cloud\t☁️  Cloud sync" \
    "store\t🛒 ASH theme/plugin store" \
    "session\t💼 Session management" \
    "ai\t🤖 AI assistant" \
    "macro\t⌨️  Macro recorder" \
    "remote\t📡 Remote control" \
    "benchmark\t⏱️  Performance benchmark" \
    "migrate\t🚚 Migrate from other dotfiles" \
    "completion\t🐟 Shell completions" \
    "reload\t🔄 Reload all configs" \
    "help\t❓ Show help" \
    "version\t📌 Show version"

# Register top-level completions
complete -c ash -f -n __ash_no_subcommand -a "$ash_commands"

# ── Global flags (always available) ───────────────────────────────────────────
complete -c ash -l help    -s h -d "Show help"               -f
complete -c ash -l version -s v -d "Show version info"       -f
complete -c ash -l verbose -s V -d "Verbose output"          -f
complete -c ash -l quiet   -s q -d "Quiet / no decoration"   -f
complete -c ash -l yes     -s y -d "Auto-confirm prompts"    -f
complete -c ash -l dry-run -s n -d "Simulate, don't apply"  -f
complete -c ash -l json    -s j -d "Output as JSON"          -f
complete -c ash -l no-color     -d "Disable colored output"  -f
complete -c ash -l log-level -s l -d "Log level: debug info warn error" -f \
    -a "debug\tDebug level info\tInfo level warn\tWarn level error\tError level"

# ══════════════════════════════════════════════════════════════════════════════
#  THEME SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l theme_sub \
    "apply\t✅ Apply a theme" \
    "pick\t🎯 Interactive theme picker" \
    "random\t🎲 Apply random theme" \
    "create\t✏️  Create new theme" \
    "edit\t🖊️  Edit existing theme" \
    "clone\t📋 Clone a theme" \
    "export\t📤 Export theme to file" \
    "import\t📥 Import theme from file" \
    "preview\t👁️  Preview theme without applying" \
    "list\t📋 List all themes" \
    "search\t🔍 Search themes" \
    "delete\t🗑️  Delete a theme" \
    "reset\t↩️  Reset to default theme" \
    "schedule\t⏰ Schedule theme changes" \
    "ai-generate\t🤖 Generate theme with AI" \
    "ai-mood\t😊 Generate theme from mood" \
    "ai-weather\t🌤️  Generate theme from weather" \
    "ai-time\t🕐 Generate theme for time of day" \
    "wallpaper\t🖼️  Set theme wallpaper" \
    "colors\t🎨 Show theme color palette" \
    "store-browse\t🛒 Browse theme store" \
    "store-download\t⬇️  Download theme from store" \
    "store-upload\t⬆️  Upload theme to store" \
    "validate\t✔️  Validate theme config" \
    "benchmark\t⏱️  Benchmark theme apply speed" \
    "history\t📜 Theme change history" \
    "favorite\t⭐ Manage favorite themes" \
    "sync\t🔄 Sync themes across devices"

complete -c ash -n "__ash_subcommand_is theme; and __ash_completion_guard \
    apply pick random create edit clone export import preview list search \
    delete reset schedule ai-generate ai-mood ai-weather ai-time wallpaper \
    colors store-browse store-download store-upload validate benchmark \
    history favorite sync" \
    -f -a "$theme_sub"

# theme apply <name>
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply preview edit clone delete validate benchmark favorite" \
    -f -a "(__ash_list_themes)" -d "Theme name"

# theme import <file>
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from import export" \
    -F

# theme schedule flags
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from schedule" \
    -l time   -d "Schedule time (cron expression)" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from schedule" \
    -l theme  -d "Theme to apply" -f -a "(__ash_list_themes)"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from schedule" \
    -l list   -d "List scheduled changes" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from schedule" \
    -l remove -d "Remove schedule" -f

# theme ai-generate flags
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from ai-generate ai-mood" \
    -l prompt   -d "Text prompt for AI" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from ai-generate ai-mood" \
    -l provider -d "AI provider" -f -a "(__ash_list_ai_providers)"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from ai-generate ai-mood" \
    -l apply    -d "Apply generated theme" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from ai-generate" \
    -l save     -d "Save generated theme with name" -f

# theme create/edit flags
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from create" \
    -l name        -d "Theme name" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from create" \
    -l base        -d "Base theme to copy from" -f -a "(__ash_list_themes)"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from create edit" \
    -l accent      -d "Accent color (hex)" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from create edit" \
    -l background  -d "Background color (hex)" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from create edit" \
    -l foreground  -d "Foreground color (hex)" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from create edit" \
    -l wallpaper   -d "Wallpaper path" -F

# theme apply flags
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l no-wallpaper   -d "Skip wallpaper change" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l no-gtk         -d "Skip GTK theme" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l no-cursor      -d "Skip cursor theme" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l no-icons       -d "Skip icon theme" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l animation      -d "Transition animation" -f -a "(__ash_list_animations)"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l silent         -d "No notification" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from apply" \
    -l reload         -d "Force reload all apps" -f

# theme list flags
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from list" \
    -l category -d "Filter by category" -f -a "dark light neon nature space pastel anime retro gradient seasonal mood gaming minimal special"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from list" \
    -l installed -d "Show only installed" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from list" \
    -l favorites -d "Show only favorites" -f
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from list" \
    -l sort      -d "Sort by" -f -a "name\tAlphabetical date\tDate added usage\tMost used rating\tHighest rated"

# theme colors flags
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from colors" \
    -l theme  -d "Theme to show colors for" -f -a "(__ash_list_themes)"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from colors" \
    -l format -d "Output format" -f -a "hex\tHex codes rgb\tRGB values hsl\tHSL values ansi\tANSI preview"
complete -c ash -n "__ash_subcommand_is theme; and __fish_seen_subcommand_from colors" \
    -l all    -d "Show all color roles" -f

# ══════════════════════════════════════════════════════════════════════════════
#  MODE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l mode_sub \
    "game\t🎮 Gaming mode (max performance)" \
    "work\t💼 Work mode (balanced)" \
    "focus\t🎯 Focus mode (no distractions)" \
    "cinema\t🎬 Cinema mode (immersive)" \
    "present\t📊 Presentation mode" \
    "battery\t🔋 Battery saver mode" \
    "stream\t📡 Streaming mode" \
    "privacy\t🔒 Privacy mode" \
    "accessibility\t♿ Accessibility mode" \
    "default\t🏠 Default mode" \
    "create\t✏️  Create custom mode" \
    "list\t📋 List all modes" \
    "status\t📊 Show current mode"

complete -c ash -n "__ash_subcommand_is mode; and __ash_completion_guard \
    game work focus cinema present battery stream privacy accessibility \
    default create list status" \
    -f -a "$mode_sub"

# mode flags (all modes)
for m in game work focus cinema present battery stream privacy accessibility default
    complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from $m" \
        -l theme      -d "Apply specific theme" -f -a "(__ash_list_themes)"
    complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from $m" \
        -l no-theme   -d "Don't change theme" -f
    complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from $m" \
        -l notify     -d "Show desktop notification" -f
    complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from $m" \
        -l silent     -d "No notification" -f
end

# game mode specific
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from game" \
    -l mangohud   -d "Enable MangoHUD overlay" -f
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from game" \
    -l gamemode   -d "Enable Gamemode daemon" -f
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from game" \
    -l cpu-gov    -d "CPU governor" -f -a "performance\tMax performance powersave\tPower saving schedutil\tAdaptive"

# battery mode specific
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from battery" \
    -l aggressive -d "Aggressive power saving" -f
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from battery" \
    -l threshold  -d "Battery % to activate" -f

# focus mode specific
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from focus" \
    -l duration   -d "Focus duration in minutes" -f
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from focus" \
    -l block-apps -d "Apps to block (comma-separated)" -f
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from focus" \
    -l pomodoro   -d "Enable Pomodoro timer" -f

# mode create
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from create" \
    -l name   -d "Mode name" -f
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from create" \
    -l base   -d "Base mode to copy from" -f -a "(__ash_list_modes)"
complete -c ash -n "__ash_subcommand_is mode; and __fish_seen_subcommand_from create" \
    -l editor -d "Open config in editor" -f

# ══════════════════════════════════════════════════════════════════════════════
#  PLUGIN SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l plugin_sub \
    "install\t⬇️  Install a plugin" \
    "remove\t🗑️  Remove a plugin" \
    "update\t🔄 Update a plugin" \
    "update-all\t🔄 Update all plugins" \
    "list\t📋 List plugins" \
    "browse\t🌐 Browse plugin store" \
    "search\t🔍 Search plugins" \
    "create\t✏️  Create new plugin" \
    "enable\t✅ Enable a plugin" \
    "disable\t⛔ Disable a plugin" \
    "info\t📖 Plugin information" \
    "validate\t✔️  Validate plugin" \
    "publish\t📤 Publish to store" \
    "backup\t💾 Backup plugin configs"

complete -c ash -n "__ash_subcommand_is plugin; and __ash_completion_guard \
    install remove update update-all list browse search create \
    enable disable info validate publish backup" \
    -f -a "$plugin_sub"

# plugin <name> completions
for cmd in remove update enable disable info validate publish
    complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from $cmd" \
        -f -a "(__ash_list_plugins)" -d "Plugin name"
end

# plugin install flags
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from install" \
    -l git      -d "Install from git URL" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from install" \
    -l local    -d "Install from local path" -F
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from install" \
    -l version  -d "Specific version to install" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from install" \
    -l no-deps  -d "Skip dependency check" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from install" \
    -l enable   -d "Enable after install" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from install" \
    -l force    -d "Force reinstall" -f

# plugin list flags
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from list" \
    -l enabled  -d "Show enabled only" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from list" \
    -l disabled -d "Show disabled only" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from list" \
    -l outdated -d "Show outdated only" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from list" \
    -l category -d "Filter by category" -f -a "core integrations community"
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from list" \
    -l verbose  -d "Show detailed info" -f

# plugin create flags
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from create" \
    -l name     -d "Plugin name" -f
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from create" \
    -l template -d "Plugin template" -f -a "basic\tBasic shell hook\tHook integration\tIntegration widget\tWidget"
complete -c ash -n "__ash_subcommand_is plugin; and __fish_seen_subcommand_from create" \
    -l editor   -d "Open in editor after creation" -f

# ══════════════════════════════════════════════════════════════════════════════
#  SNAPSHOT SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l snap_sub \
    "create\t📸 Create a snapshot" \
    "restore\t↩️  Restore a snapshot" \
    "list\t📋 List snapshots" \
    "delete\t🗑️  Delete a snapshot" \
    "diff\t🔍 Diff two snapshots" \
    "export\t📤 Export snapshot" \
    "import\t📥 Import snapshot" \
    "auto\t⏰ Configure auto-snapshots" \
    "clean\t🧹 Clean old snapshots" \
    "pin\t📌 Pin a snapshot" \
    "tag\t🏷️  Tag a snapshot" \
    "history\t📜 View snapshot history" \
    "verify\t✔️  Verify snapshot integrity"

complete -c ash -n "__ash_subcommand_is snapshot; and __ash_completion_guard \
    create restore list delete diff export import auto clean pin tag history verify" \
    -f -a "$snap_sub"

# snapshot <name> completions
for cmd in restore delete pin tag verify export diff
    complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from $cmd" \
        -f -a "(__ash_list_snapshots)" -d "Snapshot name"
end

# snapshot create flags
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from create" \
    -l name        -d "Snapshot name" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from create" \
    -l description -d "Snapshot description" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from create" \
    -l tag         -d "Tag for the snapshot" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from create" \
    -l full        -d "Include all configs (full snapshot)" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from create" \
    -l compress    -d "Compress snapshot" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from create" \
    -l encrypt     -d "Encrypt snapshot" -f

# snapshot restore flags
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from restore" \
    -l no-backup   -d "Skip pre-restore backup" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from restore" \
    -l components  -d "Restore specific components" -f \
    -a "theme wallpaper plugins config all"
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from restore" \
    -l preview     -d "Preview what will change" -f

# snapshot auto flags
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from auto" \
    -l enable      -d "Enable auto-snapshots" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from auto" \
    -l disable     -d "Disable auto-snapshots" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from auto" \
    -l interval    -d "Interval: hourly daily weekly" -f \
    -a "hourly\tEvery hour daily\tOnce a day weekly\tOnce a week"
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from auto" \
    -l keep        -d "Number of auto-snapshots to keep" -f

# snapshot clean flags
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from clean" \
    -l keep   -d "Keep N most recent snapshots" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from clean" \
    -l older  -d "Delete snapshots older than N days" -f
complete -c ash -n "__ash_subcommand_is snapshot; and __fish_seen_subcommand_from clean" \
    -l dry-run -d "Show what would be deleted" -f

# ══════════════════════════════════════════════════════════════════════════════
#  CONFIG SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l config_sub \
    "get\t🔍 Get a config value" \
    "set\t✏️  Set a config value" \
    "unset\t🗑️  Remove a config key" \
    "list\t📋 List all config keys" \
    "reset\t↩️  Reset to defaults" \
    "export\t📤 Export config to file" \
    "import\t📥 Import config from file" \
    "edit\t🖊️  Open config in editor" \
    "validate\t✔️  Validate config file" \
    "migrate\t🚚 Migrate config format"

complete -c ash -n "__ash_subcommand_is config; and __ash_completion_guard \
    get set unset list reset export import edit validate migrate" \
    -f -a "$config_sub"

# config get/set/unset: complete key names
for cmd in get set unset
    complete -c ash -n "__ash_subcommand_is config; and __fish_seen_subcommand_from $cmd" \
        -f -a "(__ash_list_config_keys)" -d "Config key"
end

# config set: value completions for known boolean keys
complete -c ash -n "__ash_subcommand_is config; and __fish_seen_subcommand_from set" \
    -f -a "true\tEnable false\tDisable"

# config export flags
complete -c ash -n "__ash_subcommand_is config; and __fish_seen_subcommand_from export import" \
    -l output -d "Output file path" -F
complete -c ash -n "__ash_subcommand_is config; and __fish_seen_subcommand_from export" \
    -l format -d "Format: json toml yaml" -f -a "json toml yaml"

# ══════════════════════════════════════════════════════════════════════════════
#  DOCTOR SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l doctor_sub \
    "quick\t⚡ Quick essential checks" \
    "full\t🔬 Full system check (all checks)" \
    "fix\t🔧 Auto-fix detected issues" \
    "report\t📄 Generate diagnostic report"

complete -c ash -n "__ash_subcommand_is doctor; and __ash_completion_guard quick full fix report" \
    -f -a "$doctor_sub"

# doctor flags
complete -c ash -n "__ash_subcommand_is doctor" \
    -l checks -d "Run specific checks" -f \
    -a "system\tOS/kernel wayland\tWayland session hyprland\tHyprland compositor \
        gpu\tGPU drivers audio\tAudio system bluetooth\tBluetooth network\tNetwork \
        fonts\tFont installation tools\tRequired tools configs\tConfig files \
        plugins\tInstalled plugins security\tSecurity scan performance\tPerf metrics"
complete -c ash -n "__ash_subcommand_is doctor" \
    -l output   -d "Report output file" -F
complete -c ash -n "__ash_subcommand_is doctor" \
    -l format   -d "Report format" -f -a "text\tPlain text json\tJSON markdown\tMarkdown html\tHTML"
complete -c ash -n "__ash_subcommand_is doctor" \
    -l no-color -d "Disable colored output" -f

# ══════════════════════════════════════════════════════════════════════════════
#  HW (HARDWARE) SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l hw_sub \
    "full-report\t📊 Complete hardware report" \
    "cpu\t🧠 CPU information" \
    "gpu\t🎮 GPU information" \
    "memory\t💾 Memory/RAM details" \
    "disk\t💿 Disk & storage info" \
    "monitor\t🖥️  Display information" \
    "battery\t🔋 Battery status" \
    "usb\t🔌 USB devices" \
    "bluetooth\t🔵 Bluetooth devices" \
    "audio\t🔊 Audio hardware" \
    "network\t🌐 Network interfaces" \
    "pci\t🔌 PCI devices" \
    "sensors\t🌡️  Temperature sensors" \
    "benchmark\t⏱️  Hardware benchmark"

complete -c ash -n "__ash_subcommand_is hw; and __ash_completion_guard \
    full-report cpu gpu memory disk monitor battery usb bluetooth \
    audio network pci sensors benchmark" \
    -f -a "$hw_sub"

# hw flags
complete -c ash -n "__ash_subcommand_is hw" \
    -l format -d "Output format" -f -a "table\tTable view json\tJSON text\tPlain text"
complete -c ash -n "__ash_subcommand_is hw; and __fish_seen_subcommand_from gpu" \
    -l vendor -d "GPU vendor filter" -f -a "(__ash_list_gpu_vendors)"
complete -c ash -n "__ash_subcommand_is hw; and __fish_seen_subcommand_from benchmark" \
    -l type   -d "Benchmark type" -f \
    -a "cpu\tCPU benchmark gpu\tGPU benchmark memory\tMemory bandwidth disk\tDisk I/O all\tAll benchmarks"

# ══════════════════════════════════════════════════════════════════════════════
#  NET (NETWORK) SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l net_sub \
    "status\t📊 Network status overview" \
    "speed\t⚡ Internet speed test" \
    "wifi\t📶 WiFi info" \
    "wifi-scan\t🔍 Scan nearby WiFi networks" \
    "wifi-connect\t🔗 Connect to WiFi" \
    "wifi-hotspot\t📡 Create WiFi hotspot" \
    "vpn\t🔒 VPN management" \
    "dns\t🌐 DNS utilities" \
    "firewall\t🛡️  Firewall management" \
    "ports\t🔌 Open ports scanner" \
    "monitor\t📊 Network traffic monitor" \
    "proxy\t🔄 Proxy settings" \
    "tor\t🧅 Tor network"

complete -c ash -n "__ash_subcommand_is net; and __ash_completion_guard \
    status speed wifi wifi-scan wifi-connect wifi-hotspot vpn dns \
    firewall ports monitor proxy tor" \
    -f -a "$net_sub"

# net flags
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from speed" \
    -l server -d "Speed test server" -f
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from speed" \
    -l json   -d "Output as JSON" -f
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from wifi-connect" \
    -l ssid   -d "Network SSID" -f
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from wifi-connect" \
    -l pass   -d "Network password" -f
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from vpn" \
    -l action -d "VPN action" -f -a "connect\tConnect disconnect\tDisconnect status\tStatus list\tList profiles"
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from dns" \
    -l lookup  -d "DNS lookup for domain" -f
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from dns" \
    -l flush   -d "Flush DNS cache" -f
complete -c ash -n "__ash_subcommand_is net; and __fish_seen_subcommand_from dns" \
    -l set     -d "Set DNS server" -f \
    -a "cloudflare\t1.1.1.1 google\t8.8.8.8 quad9\t9.9.9.9 custom\tCustom DNS"

# ══════════════════════════════════════════════════════════════════════════════
#  UPDATE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l update_sub \
    "system\t📦 Update system packages" \
    "dotfiles\t🔥 Update ASH dotfiles" \
    "plugins\t🔌 Update all plugins" \
    "themes\t🎨 Update theme library" \
    "nvim\t📝 Update Neovim plugins" \
    "fish\t🐟 Update Fish plugins" \
    "flatpak\t📦 Update Flatpak apps" \
    "all\t🔄 Update everything" \
    "check\t🔍 Check for updates" \
    "rollback\t↩️  Rollback last update"

complete -c ash -n "__ash_subcommand_is update; and __ash_completion_guard \
    system dotfiles plugins themes nvim fish flatpak all check rollback" \
    -f -a "$update_sub"

# update flags
complete -c ash -n "__ash_subcommand_is update" \
    -l no-backup   -d "Skip pre-update snapshot" -f
complete -c ash -n "__ash_subcommand_is update" \
    -l branch      -d "Git branch to update from" -f
complete -c ash -n "__ash_subcommand_is update" \
    -l force       -d "Force update even if up-to-date" -f
complete -c ash -n "__ash_subcommand_is update; and __fish_seen_subcommand_from check" \
    -l notify      -d "Show desktop notification if updates available" -f

# ══════════════════════════════════════════════════════════════════════════════
#  SHOT (SCREENSHOT) SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l shot_sub \
    "full\t🖥️  Full screen screenshot" \
    "area\t✂️  Select area screenshot" \
    "window\t🪟  Active window screenshot" \
    "monitor\t🖥️  Specific monitor" \
    "ocr\t🔤 Screenshot + OCR text" \
    "color\t🎨 Pick color from screen" \
    "record\t🎬 Screen recording" \
    "gif\t🎞️  Animated GIF recording" \
    "annotate\t✏️  Annotate screenshot" \
    "timer\t⏱️  Screenshot with timer" \
    "upload\t📤 Upload screenshot" \
    "history\t📜 Screenshot history"

complete -c ash -n "__ash_subcommand_is shot; and __ash_completion_guard \
    full area window monitor ocr color record gif annotate timer upload history" \
    -f -a "$shot_sub"

# shot flags
complete -c ash -n "__ash_subcommand_is shot" \
    -l output   -d "Save to file" -F
complete -c ash -n "__ash_subcommand_is shot" \
    -l clipboard -d "Copy to clipboard" -f
complete -c ash -n "__ash_subcommand_is shot" \
    -l notify    -d "Show notification" -f
complete -c ash -n "__ash_subcommand_is shot" \
    -l format    -d "Image format" -f -a "png\tPNG jpg\tJPEG webp\tWebP"
complete -c ash -n "__ash_subcommand_is shot; and __fish_seen_subcommand_from timer" \
    -l delay     -d "Delay in seconds" -f
complete -c ash -n "__ash_subcommand_is shot; and __fish_seen_subcommand_from record" \
    -l audio     -d "Record with audio" -f
complete -c ash -n "__ash_subcommand_is shot; and __fish_seen_subcommand_from record gif" \
    -l fps       -d "Frames per second" -f -a "15 24 30 60"
complete -c ash -n "__ash_subcommand_is shot; and __fish_seen_subcommand_from upload" \
    -l service   -d "Upload service" -f \
    -a "imgur\tImgur catbox\tCatbox 0x0\t0x0.st custom\tCustom server"
complete -c ash -n "__ash_subcommand_is shot; and __fish_seen_subcommand_from monitor" \
    -l id        -d "Monitor ID (0, 1, 2...)" -f

# ══════════════════════════════════════════════════════════════════════════════
#  WALLPAPER SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l wall_sub \
    "set\t🖼️  Set a wallpaper" \
    "random\t🎲 Random wallpaper" \
    "pick\t🎯 Interactive picker" \
    "download\t⬇️  Download from source" \
    "generate\t🎨 Generate procedural wallpaper" \
    "generate-ai\t🤖 Generate with AI (Stable Diffusion)" \
    "slideshow\t▶️  Start wallpaper slideshow" \
    "blur\t🌫️  Set blurred wallpaper" \
    "info\t📖 Current wallpaper info" \
    "history\t📜 Wallpaper history"

complete -c ash -n "__ash_subcommand_is wallpaper; and __ash_completion_guard \
    set random pick download generate generate-ai slideshow blur info history" \
    -f -a "$wall_sub"

# wallpaper set <file>
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from set blur" \
    -F

# wallpaper flags
complete -c ash -n "__ash_subcommand_is wallpaper" \
    -l transition -d "Transition type" -f \
    -a "fade\tFade wipe\tWipe grow\tGrow wave\tWave random\tRandom none\tInstant"
complete -c ash -n "__ash_subcommand_is wallpaper" \
    -l duration   -d "Transition duration (seconds)" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from random" \
    -l category   -d "Wallpaper category" -f -a "(__ash_list_wallpaper_categories)"
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from download" \
    -l source     -d "Download source" -f \
    -a "unsplash\tUnsplash wallhaven\tWallhaven reddit\tReddit pixabay\tPixabay url\tDirect URL"
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from download" \
    -l query      -d "Search query" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from generate-ai" \
    -l prompt     -d "Image generation prompt" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from generate-ai" \
    -l model      -d "Stable Diffusion model" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from slideshow" \
    -l interval   -d "Seconds between changes" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from slideshow" \
    -l category   -d "Wallpaper category" -f -a "(__ash_list_wallpaper_categories)"
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from slideshow" \
    -l shuffle    -d "Shuffle order" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from blur" \
    -l radius     -d "Blur radius (1-100)" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from set" \
    -l extract-colors -d "Extract colors for theme" -f
complete -c ash -n "__ash_subcommand_is wallpaper; and __fish_seen_subcommand_from set" \
    -l apply-theme    -d "Auto-apply extracted theme" -f

# ══════════════════════════════════════════════════════════════════════════════
#  BAR SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l bar_sub \
    "layout\t🗂️  Set bar layout" \
    "toggle\t👁️  Toggle bar visibility" \
    "reload\t🔄 Reload bar config" \
    "switch\t🔄 Switch bar backend"

complete -c ash -n "__ash_subcommand_is bar; and __ash_completion_guard layout toggle reload switch" \
    -f -a "$bar_sub"

complete -c ash -n "__ash_subcommand_is bar; and __fish_seen_subcommand_from layout" \
    -f -a "(__ash_list_bar_layouts)" -d "Layout name"
complete -c ash -n "__ash_subcommand_is bar; and __fish_seen_subcommand_from switch" \
    -f -a "waybar\tWaybar ags\tAGS eww\tElkowar's Widgets" -d "Bar backend"

# ══════════════════════════════════════════════════════════════════════════════
#  POWER SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l power_sub \
    "menu\t⚡ Interactive power menu" \
    "lock\t🔒 Lock screen" \
    "suspend\t💤 Suspend to RAM" \
    "hibernate\t🐻 Hibernate to disk" \
    "shutdown\t⏻  Shutdown system" \
    "reboot\t🔄 Reboot system" \
    "logout\t🚪 Logout session"

complete -c ash -n "__ash_subcommand_is power; and __ash_completion_guard \
    menu lock suspend hibernate shutdown reboot logout" \
    -f -a "$power_sub"

complete -c ash -n "__ash_subcommand_is power; and __fish_seen_subcommand_from shutdown reboot" \
    -l delay  -d "Delay in seconds" -f
complete -c ash -n "__ash_subcommand_is power; and __fish_seen_subcommand_from shutdown reboot" \
    -l cancel -d "Cancel pending shutdown/reboot" -f

# ══════════════════════════════════════════════════════════════════════════════
#  MONITOR SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l monitor_sub \
    "list\t📋 List monitors" \
    "layout\t🗂️  Set monitor layout" \
    "mirror\t🪞 Mirror displays" \
    "extend\t⬜ Extend displays" \
    "resolution\t📐 Set resolution" \
    "refresh-rate\t⏱️  Set refresh rate"

complete -c ash -n "__ash_subcommand_is monitor; and __ash_completion_guard \
    list layout mirror extend resolution refresh-rate" \
    -f -a "$monitor_sub"

complete -c ash -n "__ash_subcommand_is monitor; and __fish_seen_subcommand_from resolution" \
    -f -a "1920x1080\tFHD 2560x1440\tQHD 3840x2160\t4K 1280x720\tHD"
complete -c ash -n "__ash_subcommand_is monitor; and __fish_seen_subcommand_from refresh-rate" \
    -f -a "60\t60Hz 75\t75Hz 144\t144Hz 165\t165Hz 240\t240Hz 360\t360Hz"

# ══════════════════════════════════════════════════════════════════════════════
#  AUDIO SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l audio_sub \
    "volume\t🔊 Control volume" \
    "mute\t🔇 Toggle mute" \
    "device\t🎧 Switch audio device" \
    "eq\t🎚️  Equalizer settings" \
    "visualizer\t🎵 Audio visualizer"

complete -c ash -n "__ash_subcommand_is audio; and __ash_completion_guard volume mute device eq visualizer" \
    -f -a "$audio_sub"

complete -c ash -n "__ash_subcommand_is audio; and __fish_seen_subcommand_from volume" \
    -f -a "up\tIncrease volume down\tDecrease volume set\tSet exact level"
complete -c ash -n "__ash_subcommand_is audio; and __fish_seen_subcommand_from volume" \
    -l amount -d "Amount to change (0-100)" -f
complete -c ash -n "__ash_subcommand_is audio; and __fish_seen_subcommand_from mute" \
    -f -a "on\tMute off\tUnmute toggle\tToggle"
complete -c ash -n "__ash_subcommand_is audio; and __fish_seen_subcommand_from eq" \
    -l preset -d "EQ preset" -f \
    -a "flat\tFlat bass-boost\tBass Boost gaming\tGaming voice\tVoice clarity treble\tTreble"

# ══════════════════════════════════════════════════════════════════════════════
#  BLUETOOTH SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l bt_sub \
    "scan\t🔍 Scan for devices" \
    "connect\t🔗 Connect to device" \
    "disconnect\t🔌 Disconnect device" \
    "pair\t🤝 Pair new device" \
    "list\t📋 List paired devices"

complete -c ash -n "__ash_subcommand_is bluetooth; and __ash_completion_guard scan connect disconnect pair list" \
    -f -a "$bt_sub"

complete -c ash -n "__ash_subcommand_is bluetooth; and __fish_seen_subcommand_from scan" \
    -l timeout -d "Scan duration in seconds" -f

# ══════════════════════════════════════════════════════════════════════════════
#  WINDOW SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l win_sub \
    "list\t📋 List open windows" \
    "focus\t🎯 Focus a window" \
    "move\t➡️  Move window" \
    "resize\t↔️  Resize window" \
    "close\t✖️  Close a window" \
    "pin\t📌 Pin window on top" \
    "float\t🪂 Toggle floating" \
    "fullscreen\t⬛ Toggle fullscreen"

complete -c ash -n "__ash_subcommand_is window; and __ash_completion_guard \
    list focus move resize close pin float fullscreen" \
    -f -a "$win_sub"

# ══════════════════════════════════════════════════════════════════════════════
#  WORKSPACE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l ws_sub \
    "list\t📋 List workspaces" \
    "switch\t🔄 Switch to workspace" \
    "move-window\t🪟  Move window to workspace" \
    "overview\t🗂️  Workspace overview"

complete -c ash -n "__ash_subcommand_is workspace; and __ash_completion_guard list switch move-window overview" \
    -f -a "$ws_sub"

complete -c ash -n "__ash_subcommand_is workspace; and __fish_seen_subcommand_from switch move-window" \
    -f -a "1 2 3 4 5 6 7 8 9 10 special" -d "Workspace number"

# ══════════════════════════════════════════════════════════════════════════════
#  GAMING SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l game_sub \
    "optimize\t⚡ Apply gaming optimizations" \
    "mangohud\t📊 MangoHUD overlay control" \
    "proton\t🍷 Proton/Steam Compatibility" \
    "gamemode\t🚀 Gamemode daemon control"

complete -c ash -n "__ash_subcommand_is gaming; and __ash_completion_guard optimize mangohud proton gamemode" \
    -f -a "$game_sub"

complete -c ash -n "__ash_subcommand_is gaming; and __fish_seen_subcommand_from mangohud" \
    -f -a "enable\tEnable overlay disable\tDisable overlay config\tEdit config"
complete -c ash -n "__ash_subcommand_is gaming; and __fish_seen_subcommand_from proton" \
    -l version -d "Proton version" -f
complete -c ash -n "__ash_subcommand_is gaming; and __fish_seen_subcommand_from optimize" \
    -l cpu-gov  -d "CPU governor" -f -a "performance powersave schedutil"

# ══════════════════════════════════════════════════════════════════════════════
#  BACKUP SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l backup_sub \
    "create\t💾 Create backup" \
    "restore\t↩️  Restore from backup" \
    "list\t📋 List backups" \
    "schedule\t⏰ Configure auto-backup" \
    "verify\t✔️  Verify backup integrity" \
    "encrypt\t🔒 Encrypt backup"

complete -c ash -n "__ash_subcommand_is backup; and __ash_completion_guard create restore list schedule verify encrypt" \
    -f -a "$backup_sub"

complete -c ash -n "__ash_subcommand_is backup; and __fish_seen_subcommand_from create" \
    -l destination -d "Backup destination" -F
complete -c ash -n "__ash_subcommand_is backup; and __fish_seen_subcommand_from create" \
    -l compress    -d "Compress backup" -f
complete -c ash -n "__ash_subcommand_is backup; and __fish_seen_subcommand_from create" \
    -l encrypt     -d "Encrypt backup" -f
complete -c ash -n "__ash_subcommand_is backup; and __fish_seen_subcommand_from restore" \
    -l source      -d "Backup source path" -F

# ══════════════════════════════════════════════════════════════════════════════
#  ANALYTICS SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l analytics_sub \
    "dashboard\t📊 Show analytics dashboard" \
    "theme-stats\t🎨 Theme usage stats" \
    "command-stats\t⌨️  Command usage stats" \
    "performance-stats\t⏱️  Performance metrics" \
    "export-report\t📤 Export analytics report"

complete -c ash -n "__ash_subcommand_is analytics; and __ash_completion_guard \
    dashboard theme-stats command-stats performance-stats export-report" \
    -f -a "$analytics_sub"

complete -c ash -n "__ash_subcommand_is analytics; and __fish_seen_subcommand_from export-report" \
    -l format -d "Report format" -f -a "json html csv pdf"
complete -c ash -n "__ash_subcommand_is analytics" \
    -l period -d "Time period" -f \
    -a "day\tLast 24h week\tLast 7 days month\tLast 30 days year\tLast year all\tAll time"

# ══════════════════════════════════════════════════════════════════════════════
#  PROFILE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l profile_sub \
    "create\t✏️  Create new profile" \
    "switch\t🔄 Switch active profile" \
    "delete\t🗑️  Delete profile" \
    "export\t📤 Export profile" \
    "import\t📥 Import profile" \
    "list\t📋 List profiles"

complete -c ash -n "__ash_subcommand_is profile; and __ash_completion_guard create switch delete export import list" \
    -f -a "$profile_sub"

for cmd in switch delete export
    complete -c ash -n "__ash_subcommand_is profile; and __fish_seen_subcommand_from $cmd" \
        -f -a "(__ash_list_profiles)" -d "Profile name"
end

complete -c ash -n "__ash_subcommand_is profile; and __fish_seen_subcommand_from import" \
    -F
complete -c ash -n "__ash_subcommand_is profile; and __fish_seen_subcommand_from create" \
    -l name  -d "Profile name" -f
complete -c ash -n "__ash_subcommand_is profile; and __fish_seen_subcommand_from create" \
    -l base  -d "Base profile" -f -a "(__ash_list_profiles)"

# ══════════════════════════════════════════════════════════════════════════════
#  CLOUD SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l cloud_sub \
    "sync-up\t☁️  Push config to cloud" \
    "sync-down\t⬇️  Pull config from cloud" \
    "status\t📊 Cloud sync status" \
    "configure\t⚙️  Configure cloud provider"

complete -c ash -n "__ash_subcommand_is cloud; and __ash_completion_guard sync-up sync-down status configure" \
    -f -a "$cloud_sub"

complete -c ash -n "__ash_subcommand_is cloud; and __fish_seen_subcommand_from configure" \
    -l provider -d "Cloud provider" -f -a "(__ash_list_cloud_providers)"
complete -c ash -n "__ash_subcommand_is cloud" \
    -l force    -d "Force sync (overwrite conflicts)" -f
complete -c ash -n "__ash_subcommand_is cloud" \
    -l dry-run  -d "Preview sync without applying" -f

# ══════════════════════════════════════════════════════════════════════════════
#  STORE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l store_sub \
    "browse\t🌐 Browse the store" \
    "search\t🔍 Search store" \
    "download\t⬇️  Download item" \
    "upload\t⬆️  Upload to store" \
    "rate\t⭐ Rate an item" \
    "trending\t🔥 Trending items"

complete -c ash -n "__ash_subcommand_is store; and __ash_completion_guard browse search download upload rate trending" \
    -f -a "$store_sub"

complete -c ash -n "__ash_subcommand_is store; and __fish_seen_subcommand_from browse search download trending" \
    -l category -d "Item category" -f -a "(__ash_list_store_categories)"
complete -c ash -n "__ash_subcommand_is store; and __fish_seen_subcommand_from search" \
    -l query    -d "Search query" -f
complete -c ash -n "__ash_subcommand_is store; and __fish_seen_subcommand_from rate" \
    -l score    -d "Rating 1-5" -f -a "1 2 3 4 5"

# ══════════════════════════════════════════════════════════════════════════════
#  SESSION SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l session_sub \
    "save\t💾 Save current session" \
    "restore\t↩️  Restore a session" \
    "list\t📋 List saved sessions" \
    "delete\t🗑️  Delete a session"

complete -c ash -n "__ash_subcommand_is session; and __ash_completion_guard save restore list delete" \
    -f -a "$session_sub"

complete -c ash -n "__ash_subcommand_is session; and __fish_seen_subcommand_from save" \
    -l name -d "Session name" -f

# ══════════════════════════════════════════════════════════════════════════════
#  AI SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l ai_sub \
    "chat\t💬 Interactive AI chat" \
    "suggest-theme\t🎨 AI theme suggestions" \
    "optimize-config\t⚙️  AI config optimization" \
    "fix-issue\t🔧 AI issue fixer" \
    "explain\t📖 Explain config/error"

complete -c ash -n "__ash_subcommand_is ai; and __ash_completion_guard chat suggest-theme optimize-config fix-issue explain" \
    -f -a "$ai_sub"

complete -c ash -n "__ash_subcommand_is ai" \
    -l provider -d "AI provider" -f -a "(__ash_list_ai_providers)"
complete -c ash -n "__ash_subcommand_is ai" \
    -l model    -d "AI model name" -f
complete -c ash -n "__ash_subcommand_is ai; and __fish_seen_subcommand_from suggest-theme" \
    -l mood     -d "Current mood/vibe" -f \
    -a "cozy\tCozy & warm energetic\tEnergetic & bright calm\tCalm & minimal dark\tDark & moody"
complete -c ash -n "__ash_subcommand_is ai; and __fish_seen_subcommand_from explain" \
    -l file     -d "File to explain" -F

# ══════════════════════════════════════════════════════════════════════════════
#  MACRO SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l macro_sub \
    "record\t⏺️  Record a macro" \
    "play\t▶️  Play a macro" \
    "edit\t✏️  Edit macro" \
    "list\t📋 List macros" \
    "delete\t🗑️  Delete macro"

complete -c ash -n "__ash_subcommand_is macro; and __ash_completion_guard record play edit list delete" \
    -f -a "$macro_sub"

complete -c ash -n "__ash_subcommand_is macro; and __fish_seen_subcommand_from play edit delete" \
    -f -a "(__ash_list_macros)" -d "Macro name"
complete -c ash -n "__ash_subcommand_is macro; and __fish_seen_subcommand_from record" \
    -l name   -d "Macro name" -f
complete -c ash -n "__ash_subcommand_is macro; and __fish_seen_subcommand_from play" \
    -l repeat -d "Repeat count" -f
complete -c ash -n "__ash_subcommand_is macro; and __fish_seen_subcommand_from play" \
    -l delay  -d "Delay between actions (ms)" -f

# ══════════════════════════════════════════════════════════════════════════════
#  REMOTE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l remote_sub \
    "connect\t🔗 Connect to remote ASH instance" \
    "sync-config\t🔄 Sync config with remote" \
    "apply-theme\t🎨 Apply theme on remote"

complete -c ash -n "__ash_subcommand_is remote; and __ash_completion_guard connect sync-config apply-theme" \
    -f -a "$remote_sub"

complete -c ash -n "__ash_subcommand_is remote; and __fish_seen_subcommand_from connect" \
    -l host -d "Remote host (user@host)" -f
complete -c ash -n "__ash_subcommand_is remote; and __fish_seen_subcommand_from apply-theme" \
    -l theme -d "Theme to apply" -f -a "(__ash_list_themes)"

# ══════════════════════════════════════════════════════════════════════════════
#  BENCHMARK SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l bench_sub \
    "startup\t⏱️  Measure startup time" \
    "theme-apply\t🎨 Benchmark theme apply" \
    "memory\t💾 Memory usage benchmark" \
    "report\t📊 Full benchmark report"

complete -c ash -n "__ash_subcommand_is benchmark; and __ash_completion_guard startup theme-apply memory report" \
    -f -a "$bench_sub"

complete -c ash -n "__ash_subcommand_is benchmark" \
    -l runs   -d "Number of benchmark runs" -f
complete -c ash -n "__ash_subcommand_is benchmark" \
    -l output -d "Save results to file" -F

# ══════════════════════════════════════════════════════════════════════════════
#  MIGRATE SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l migrate_sub \
    "from-hyde\t🚚 Migrate from HyDE" \
    "from-hyprdots\t🚚 Migrate from HyprDots" \
    "from-ml4w\t🚚 Migrate from ML4W"

complete -c ash -n "__ash_subcommand_is migrate; and __ash_completion_guard from-hyde from-hyprdots from-ml4w" \
    -f -a "$migrate_sub"

complete -c ash -n "__ash_subcommand_is migrate" \
    -l source  -d "Source dotfiles path" -F
complete -c ash -n "__ash_subcommand_is migrate" \
    -l dry-run -d "Preview migration" -f
complete -c ash -n "__ash_subcommand_is migrate" \
    -l backup  -d "Backup before migrating" -f

# ══════════════════════════════════════════════════════════════════════════════
#  COMPLETION SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l comp_sub \
    "fish\t🐟 Generate Fish completions" \
    "bash\t📟 Generate Bash completions" \
    "zsh\t⚡ Generate Zsh completions"

complete -c ash -n "__ash_subcommand_is completion; and __ash_completion_guard fish bash zsh" \
    -f -a "$comp_sub"
