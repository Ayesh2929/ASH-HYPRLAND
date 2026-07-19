# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ASH CLI Completions Ultra                         ║
# ║  Dynamic, context-aware completions with live data & rich descriptions     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_completions_loaded && exit 0
set --global _ash_completions_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CACHE                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_comp_themes_dir  "$HOME/.config/ash/themes/presets"
set --global _ash_comp_plugins_dir "$HOME/.config/ash/plugins"
set --global _ash_comp_state_dir   "$HOME/.local/share/ash/state"
set --global _ash_comp_cache_dir   "$HOME/.local/share/ash/cache/completions"
set --global _ash_comp_cache_ttl   300   # 5 minutes

mkdir -p $_ash_comp_cache_dir 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 CACHE HELPERS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_comp_cached --description "Return cached value or run command and cache it"
    set -l key    $argv[1]
    set -l cmd    $argv[2..-1]
    set -l cache  "$_ash_comp_cache_dir/$key"

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        if test $age -lt $_ash_comp_cache_ttl
            cat $cache
            return 0
        end
    end

    set -l result (eval $cmd 2>/dev/null)
    echo $result > $cache 2>/dev/null
    echo $result
end

function __ash_comp_invalidate --description "Invalidate a completion cache entry"
    rm -f "$_ash_comp_cache_dir/$argv[1]" 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 DYNAMIC COMPLETION SOURCES                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Theme list ───────────────────────────────────────────────────────────────
function __ash_comp_themes --description "List available ASH themes"
    if test -d $_ash_comp_themes_dir
        find $_ash_comp_themes_dir -mindepth 2 -maxdepth 2 -type d 2>/dev/null |
        while read -l dir
            set -l category (basename (dirname $dir))
            set -l name     (basename $dir)
            echo "$name\t$category theme"
        end | sort -u
    else if command -q ash
        ash theme list --short 2>/dev/null
    end
end

# ─── Installed plugins ────────────────────────────────────────────────────────
function __ash_comp_plugins_installed --description "List installed ASH plugins"
    if test -d "$_ash_comp_plugins_dir/core"
        for d in "$_ash_comp_plugins_dir/core"/*/
            test -f "$d/plugin.json" || continue
            set -l name (basename $d)
            set -l desc (command -q jq && jq -r '.description // ""' "$d/plugin.json" 2>/dev/null; or echo "")
            echo "$name\t$desc"
        end
    end
end

# ─── All plugins (installed + available) ──────────────────────────────────────
function __ash_comp_plugins_all --description "List all known ASH plugins"
    __ash_comp_plugins_installed

    # Well-known plugins
    set -l known_plugins \
        "game-mode\tOptimize system for gaming" \
        "caffeine\tPrevent screen sleep" \
        "auto-wallpaper\tAutomatic wallpaper rotation" \
        "blur-toggle\tToggle window blur" \
        "focus-timer\tPomodoro focus timer" \
        "pip-mode\tPicture-in-picture windows" \
        "night-light\tBlue light filter" \
        "do-not-disturb\tDisable notifications" \
        "weather-display\tWeather in bar" \
        "media-controls\tGlobal media keys" \
        "color-picker\tSystem color picker" \
        "clipboard-manager\tClipboard history" \
        "screen-recorder\tRecord screen to video" \
        "discord-rpc\tDiscord rich presence" \
        "spotify-control\tSpotify integration" \
        "pomodoro-plus\tAdvanced Pomodoro timer" \
        "ai-assistant\tAI-powered assistant" \
        "analytics\tUsage analytics"

    for plugin in $known_plugins
        echo $plugin
    end
end

# ─── Snapshots ────────────────────────────────────────────────────────────────
function __ash_comp_snapshots --description "List ASH snapshots"
    set -l snap_dir "$HOME/.local/share/ash/snapshots"
    if test -d $snap_dir
        for snap in $snap_dir/*.json $snap_dir/*.tar.gz
            test -e $snap || continue
            set -l name (basename $snap | string replace -r '\.(json|tar\.gz)$' '')
            echo "$name\tSnapshot"
        end 2>/dev/null
    end
end

# ─── Modes ────────────────────────────────────────────────────────────────────
function __ash_comp_modes --description "List ASH modes"
    echo "game\t🎮 Optimize for gaming (disables blur, animations)"
    echo "work\t💼 Work mode (focus notifications, productivity layout)"
    echo "focus\t🎯 Focus mode (minimal distractions, DND)"
    echo "cinema\t🎬 Cinema mode (hide bar, fullscreen)"
    echo "present\t📊 Presentation mode (clean desktop, no notifications)"
    echo "battery\t🔋 Battery saver (reduce animations, power save)"
    echo "stream\t📡 Streaming mode (OBS-ready, record indicator)"
    echo "privacy\t🔒 Privacy mode (disable logging, secure)"
    echo "accessibility\t♿ Accessibility mode (high contrast, larger text)"
    echo "default\t↩ Reset to default mode"
end

# ─── Profiles ─────────────────────────────────────────────────────────────────
function __ash_comp_profiles --description "List ASH user profiles"
    set -l profiles_dir "$HOME/.config/ash/profiles"
    if test -d $profiles_dir
        for d in $profiles_dir/*/
            test -f "$d/profile.json" || continue
            set -l name (basename $d)
            set -l desc (command -q jq && jq -r '.description // ""' "$d/profile.json" 2>/dev/null; or echo "")
            echo "$name\t$desc"
        end
    else
        for p in default work gaming streaming minimal
            echo "$p\tProfile"
        end
    end
end

# ─── Config keys ──────────────────────────────────────────────────────────────
function __ash_comp_config_keys --description "List known ASH config keys"
    echo "theme.default\tDefault theme name"
    echo "theme.variant\tTheme variant (dark/light)"
    echo "theme.auto_switch\tAuto-switch on wallpaper change"
    echo "theme.schedule.enabled\tEnable scheduled theme switching"
    echo "theme.schedule.day\tDay theme name"
    echo "theme.schedule.night\tNight theme name"
    echo "wallpaper.directory\tWallpaper directory path"
    echo "wallpaper.slideshow.interval\tSlideshow interval (seconds)"
    echo "wallpaper.slideshow.random\tRandom slideshow order"
    echo "wallpaper.transition\tWallpaper transition style"
    echo "mode.default\tDefault mode on login"
    echo "mode.game.mangohud\tEnable MangoHUD in game mode"
    echo "mode.game.gamemode\tEnable gamemode daemon"
    echo "mode.battery.threshold\tBattery level for auto battery-mode"
    echo "bar.layout\tDefault bar layout"
    echo "bar.position\tBar position (top/bottom)"
    echo "notifications.sound\tEnable notification sounds"
    echo "notifications.dnd_on_focus\tAuto-DND in focus mode"
    echo "snapshot.auto.enabled\tEnable auto snapshots"
    echo "snapshot.auto.interval\tAuto snapshot interval"
    echo "snapshot.max_count\tMaximum snapshot count"
    echo "plugins.auto_update\tAuto-update plugins"
    echo "ai.enabled\tEnable AI features"
    echo "ai.backend\tAI backend (ollama/openai)"
    echo "ai.model\tAI model name"
    echo "analytics.enabled\tEnable usage analytics"
    echo "analytics.privacy\tPrivacy level (none/basic/full)"
    echo "cloud.enabled\tEnable cloud sync"
    echo "cloud.provider\tCloud provider (github/s3/gdrive)"
    echo "security.encrypt_secrets\tEncrypt sensitive config"
    echo "sounds.enabled\tEnable system sounds"
    echo "animations.enabled\tEnable UI animations"
    echo "animations.style\tAnimation style preset"
    echo "display.gamma\tDisplay gamma correction"
    echo "display.night_light\tEnable night light"
    echo "display.night_light.temp\tNight light color temperature"
end

# ─── Wallpaper sources ────────────────────────────────────────────────────────
function __ash_comp_wallpaper_sources --description "List wallpaper download sources"
    echo "unsplash\tUnsplash.com — free high-quality photos"
    echo "wallhaven\tWallhaven.cc — community wallpapers"
    echo "reddit\tReddit wallpaper subreddits"
    echo "pixabay\tPixabay — free stock images"
    echo "local\tLocal wallpaper directory"
end

# ─── Bar layouts ──────────────────────────────────────────────────────────────
function __ash_comp_bar_layouts --description "List available bar layouts"
    echo "top-bar\tSingle bar at the top"
    echo "bottom-bar\tSingle bar at the bottom"
    echo "dual-bar-top\tDual bars, both at top"
    echo "dual-bar-bottom\tDual bars, both at bottom"
    echo "floating-bar\tFloating pill-style bar"
    echo "minimal-bar\tMinimal bar with few modules"
    echo "maximal-bar\tFull-featured bar with all modules"
    echo "vertical-left\tVertical bar on the left"
    echo "vertical-right\tVertical bar on the right"
    echo "island-bar\tMacOS-style island bar"
    echo "zen-bar\tClean zen-focused bar"
    echo "gaming-bar\tGaming-optimized bar"
end

# ─── Animation styles ─────────────────────────────────────────────────────────
function __ash_comp_animation_styles --description "List animation style presets"
    echo "default\tBalanced animations"
    echo "smooth\tSmooth, fluid animations"
    echo "bouncy\tBouncy spring animations"
    echo "snappy\tFast, snappy animations"
    echo "cinematic\tSlow, cinematic animations"
    echo "minimal\tSubtle, minimal animations"
    echo "none\tDisable all animations"
    echo "performance\tPerformance-optimized (reduced)"
    echo "elastic\tElastic spring animations"
end

# ─── Rofi launcher types ──────────────────────────────────────────────────────
function __ash_comp_rofi_types --description "List rofi launcher layout types"
    echo "type-1-grid\tGrid layout launcher"
    echo "type-2-sidebar\tSidebar layout launcher"
    echo "type-3-fullscreen\tFullscreen launcher"
    echo "type-4-center\tCentered launcher"
    echo "type-5-spotlight\tSpotlight-style launcher"
    echo "type-6-dmenu\tDmenu-style launcher"
    echo "type-7-runner\tRunner-style launcher"
end

# ─── SSH hosts (for ash remote) ───────────────────────────────────────────────
function __ash_comp_ssh_hosts --description "List SSH hosts for remote commands"
    cat ~/.ssh/config ~/.ssh/config.d/*.conf 2>/dev/null |
    grep -i '^Host ' | awk '{print $2}' | grep -v '\*' | sort -u
end

# ─── AI backends ──────────────────────────────────────────────────────────────
function __ash_comp_ai_backends --description "List available AI backends"
    echo "ollama\tLocal Ollama LLM (privacy-first)"
    echo "openai\tOpenAI API (requires API key)"
    echo "anthropic\tAnthropic Claude (requires API key)"
    echo "stable-diffusion\tLocal image generation"
end

# ─── Current subcommand detection ─────────────────────────────────────────────
function __ash_comp_seen_subcommand --description "Check if a subcommand is already entered"
    set -l cmd $argv[1]
    set -l tokens (commandline -opc)
    for token in $tokens[2..-1]
        test "$token" = $cmd && return 0
    end
    return 1
end

function __ash_comp_no_subcommand --description "True if no main subcommand entered yet"
    set -l subcommands theme mode plugin snapshot config doctor hw net update \
        shot wallpaper bar power monitor audio bluetooth window workspace \
        gaming backup analytics profile cloud store session ai macro remote \
        benchmark migrate completion
    set -l tokens (commandline -opc)
    for token in $tokens[2..-1]
        contains $token $subcommands && return 1
    end
    return 0
end

function __ash_comp_using_subcommand --description "True if using specific subcommand"
    set -l sub $argv[1]
    set -l tokens (commandline -opc)
    contains $sub $tokens && return 0
    return 1
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✂️  CLEAR EXISTING COMPLETIONS                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

complete -c ash -e

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌐 GLOBAL FLAGS                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

complete -c ash -n __ash_comp_no_subcommand -l help       -s h -d "Show help"
complete -c ash -n __ash_comp_no_subcommand -l version    -s v -d "Show version"
complete -c ash -n __ash_comp_no_subcommand -l verbose    -s V -d "Verbose output"
complete -c ash -n __ash_comp_no_subcommand -l quiet      -s q -d "Quiet output"
complete -c ash -n __ash_comp_no_subcommand -l no-color       -d "Disable color output"
complete -c ash -n __ash_comp_no_subcommand -l json           -d "JSON output"
complete -c ash -n __ash_comp_no_subcommand -l dry-run        -d "Preview changes without applying"
complete -c ash -n __ash_comp_no_subcommand -l profile    -s p -r -d "Use specific profile"
complete -c ash -n __ash_comp_no_subcommand -l config     -s c -r -d "Custom config file"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 TOP-LEVEL SUBCOMMANDS                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -l __ash_top_cmds \
    "theme\t🎨 Theme management (apply/pick/create/AI)" \
    "mode\t🎭 Desktop mode switching (game/focus/work)" \
    "plugin\t🔌 Plugin management (install/remove/browse)" \
    "snapshot\t📸 Config snapshots (create/restore/diff)" \
    "config\t⚙️  Configuration management (get/set/edit)" \
    "doctor\t🏥 System diagnostics (check/fix/report)" \
    "hw\t💻 Hardware information & benchmarks" \
    "net\t🌐 Network management (wifi/vpn/dns)" \
    "update\t🔄 Update system/dotfiles/plugins/themes" \
    "shot\t📷 Screenshots (full/area/window/OCR/record)" \
    "wallpaper\t🖼️  Wallpaper management (set/random/AI)" \
    "bar\t📊 Status bar (layout/reload/toggle)" \
    "power\t⚡ Power management (lock/suspend/shutdown)" \
    "monitor\t🖥️  Monitor management (layout/resolution)" \
    "audio\t🔊 Audio management (volume/device/EQ)" \
    "bluetooth\t📶 Bluetooth (scan/connect/pair)" \
    "window\t🪟 Window management (focus/move/resize)" \
    "workspace\t🗂️  Workspace management (switch/move)" \
    "gaming\t🎮 Gaming utilities (optimize/mangohud)" \
    "backup\t💾 Backup management (create/restore)" \
    "analytics\t📈 Usage analytics & statistics" \
    "profile\t👤 User profiles (create/switch/export)" \
    "cloud\t☁️  Cloud sync (up/down/configure)" \
    "store\t🏪 Theme/plugin store (browse/download)" \
    "session\t💬 Session management (save/restore)" \
    "ai\t🤖 AI assistant (chat/suggest/fix)" \
    "macro\t📼 Macro recorder (record/play/edit)" \
    "remote\t🌍 Remote machine management" \
    "benchmark\t📊 Performance benchmarks" \
    "migrate\t🔀 Migrate from other dotfiles" \
    "completion\t✅ Shell completion scripts"

for cmd in $__ash_top_cmds
    complete -c ash -n __ash_comp_no_subcommand -f -a $cmd
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 THEME SUBCOMMAND COMPLETIONS                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -l __ash_theme_subs \
    "apply\tApply a theme by name" \
    "pick\tInteractively pick a theme" \
    "random\tApply a random theme" \
    "create\tCreate a new theme" \
    "edit\tEdit an existing theme" \
    "clone\tClone a theme as new" \
    "export\tExport theme to file" \
    "import\tImport theme from file" \
    "preview\tPreview theme without applying" \
    "list\tList all available themes" \
    "search\tSearch themes by name/tag" \
    "delete\tDelete a theme" \
    "reset\tReset to default theme" \
    "schedule\tSchedule theme switching" \
    "ai-generate\tGenerate theme using AI" \
    "ai-mood\tGenerate theme from mood description" \
    "ai-weather\tGenerate theme based on weather" \
    "ai-time\tGenerate theme based on time of day" \
    "wallpaper\tManage theme wallpaper" \
    "colors\tShow/edit theme color palette" \
    "store-browse\tBrowse theme store" \
    "store-download\tDownload theme from store" \
    "store-upload\tUpload theme to store" \
    "validate\tValidate theme configuration" \
    "benchmark\tBenchmark theme application speed" \
    "history\tShow theme switch history" \
    "favorite\tMark theme as favorite" \
    "sync\tSync themes with cloud"

for sub in $__ash_theme_subs
    complete -c ash -n '__ash_comp_using_subcommand theme && not __ash_comp_seen_subcommand (string split "\t" $sub)[1]' \
        -f -a $sub
end

# Theme name completions for apply/pick/preview/clone/delete/validate
for sub in apply preview clone delete validate favorite
    complete -c ash \
        -n "__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand $sub" \
        -f -a '(__ash_comp_themes)' \
        -d "Theme name"
end

# Theme flags
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand apply' \
    -l no-wallpaper -d "Apply theme without changing wallpaper"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand apply' \
    -l no-notify    -d "Apply without notification"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand apply' \
    -l instant      -d "Apply instantly (no transition)"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand apply' \
    -l dry-run      -d "Preview without applying"

complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand list' \
    -l category -s c -r -d "Filter by category"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand list' \
    -l variant  -s v -r -d "Filter by variant (dark/light)"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand list' \
    -l favorites    -d "Show favorites only"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand list' \
    -l json         -d "JSON output"

complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand random' \
    -l category -s c -r -a "dark light neon nature space anime retro gradient seasonal mood gaming minimal special" \
    -d "Random from category"

complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand schedule' \
    -l day   -r -d "Daytime theme"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand schedule' \
    -l night -r -d "Nighttime theme"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand schedule' \
    -l time  -r -d "Switch time (HH:MM)"

complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand ai-generate' \
    -l prompt   -r -d "AI prompt describing theme"
complete -c ash -n '__ash_comp_using_subcommand theme && __ash_comp_seen_subcommand ai-generate' \
    -l backend  -r -a '(__ash_comp_ai_backends)' -d "AI backend to use"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎭 MODE SUBCOMMAND COMPLETIONS                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in game work focus cinema present battery stream privacy accessibility default
    complete -c ash -n '__ash_comp_using_subcommand mode && not __ash_comp_seen_subcommand game work focus cinema present battery stream privacy accessibility default create list status' \
        -f -a "$sub\t"(string split '\t' (string match -r "$sub\t.*" (__ash_comp_modes) | head -1))[2]
end

for sub in create list status
    complete -c ash -n '__ash_comp_using_subcommand mode && not __ash_comp_seen_subcommand game work focus cinema present battery stream privacy accessibility default create list status' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand game' \
    -l no-blur       -d "Keep blur effects"
complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand game' \
    -l mangohud      -d "Enable MangoHUD overlay"
complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand game' \
    -l gamemode      -d "Enable gamemode daemon"
complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand game' \
    -l no-animations -d "Disable window animations"

complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand focus' \
    -l timer    -r -d "Focus session duration (minutes)"
complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand focus' \
    -l dnd          -d "Enable Do Not Disturb"
complete -c ash -n '__ash_comp_using_subcommand mode && __ash_comp_seen_subcommand focus' \
    -l block    -r -d "Block distracting apps"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔌 PLUGIN SUBCOMMAND COMPLETIONS                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -l __ash_plugin_subs \
    "install\tInstall a plugin" \
    "remove\tRemove a plugin" \
    "update\tUpdate a specific plugin" \
    "update-all\tUpdate all plugins" \
    "list\tList installed plugins" \
    "browse\tBrowse available plugins" \
    "search\tSearch plugins" \
    "create\tCreate a new plugin" \
    "enable\tEnable a disabled plugin" \
    "disable\tDisable a plugin" \
    "info\tShow plugin information" \
    "validate\tValidate plugin configuration" \
    "publish\tPublish plugin to store" \
    "backup\tBackup plugin configurations"

for sub in $__ash_plugin_subs
    complete -c ash \
        -n '__ash_comp_using_subcommand plugin && not __ash_comp_seen_subcommand install remove update update-all list browse search create enable disable info validate publish backup' \
        -f -a $sub
end

# Plugin name completions for specific subcommands
for sub in remove update enable disable info validate
    complete -c ash \
        -n "__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand $sub" \
        -f -a '(__ash_comp_plugins_installed)' \
        -d "Installed plugin"
end

complete -c ash \
    -n "__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand install" \
    -f -a '(__ash_comp_plugins_all)' \
    -d "Plugin to install"

complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand install' \
    -l url      -r -d "Install from URL"
complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand install' \
    -l git      -r -d "Install from git repository"
complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand install' \
    -l local    -r -d "Install from local directory"
complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand install' \
    -l no-enable    -d "Install without enabling"

complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand list' \
    -l enabled  -d "Show only enabled plugins"
complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand list' \
    -l disabled -d "Show only disabled plugins"
complete -c ash -n '__ash_comp_using_subcommand plugin && __ash_comp_seen_subcommand list' \
    -l json     -d "JSON output"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📸 SNAPSHOT SUBCOMMAND COMPLETIONS                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -l __ash_snap_subs \
    "create\tCreate a new snapshot" \
    "restore\tRestore a snapshot" \
    "list\tList all snapshots" \
    "delete\tDelete a snapshot" \
    "diff\tCompare two snapshots" \
    "export\tExport snapshot to file" \
    "import\tImport snapshot from file" \
    "auto\tConfigure auto-snapshots" \
    "clean\tRemove old/unused snapshots" \
    "pin\tPin a snapshot (prevent auto-delete)" \
    "tag\tTag a snapshot" \
    "history\tShow snapshot history" \
    "verify\tVerify snapshot integrity"

for sub in $__ash_snap_subs
    complete -c ash \
        -n '__ash_comp_using_subcommand snapshot && not __ash_comp_seen_subcommand create restore list delete diff export import auto clean pin tag history verify' \
        -f -a $sub
end

# Snapshot name completions
for sub in restore delete diff export pin tag verify
    complete -c ash \
        -n "__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand $sub" \
        -f -a '(__ash_comp_snapshots)' \
        -d "Snapshot name"
end

complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand create' \
    -l name     -s n -r -d "Snapshot name"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand create' \
    -l message  -s m -r -d "Snapshot description"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand create' \
    -l tag      -s t -r -d "Tag for snapshot"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand create' \
    -l full         -d "Full snapshot (include cache)"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand create' \
    -l encrypt      -d "Encrypt snapshot"

complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand restore' \
    -l no-confirm   -d "Skip confirmation prompt"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand restore' \
    -l preview      -d "Preview changes before restore"

complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand clean' \
    -l keep     -r -d "Number of snapshots to keep"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand clean' \
    -l older-than -r -d "Remove snapshots older than (days)"
complete -c ash -n '__ash_comp_using_subcommand snapshot && __ash_comp_seen_subcommand clean' \
    -l dry-run      -d "Preview cleanup without deleting"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  CONFIG SUBCOMMAND COMPLETIONS                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -l __ash_config_subs \
    "get\tGet a config value" \
    "set\tSet a config value" \
    "unset\tRemove a config key" \
    "list\tList all config values" \
    "reset\tReset config to defaults" \
    "export\tExport config to file" \
    "import\tImport config from file" \
    "edit\tOpen config in editor" \
    "validate\tValidate config file" \
    "migrate\tMigrate config from older version"

for sub in $__ash_config_subs
    complete -c ash \
        -n '__ash_comp_using_subcommand config && not __ash_comp_seen_subcommand get set unset list reset export import edit validate migrate' \
        -f -a $sub
end

for sub in get set unset
    complete -c ash \
        -n "__ash_comp_using_subcommand config && __ash_comp_seen_subcommand $sub" \
        -f -a '(__ash_comp_config_keys)' \
        -d "Config key"
end

complete -c ash -n '__ash_comp_using_subcommand config && __ash_comp_seen_subcommand list' \
    -l section  -r -d "Filter by section"
complete -c ash -n '__ash_comp_using_subcommand config && __ash_comp_seen_subcommand list' \
    -l json     -d "JSON output"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏥 DOCTOR SUBCOMMAND COMPLETIONS                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "quick\tQuick health check (< 5 seconds)" \
    "full\tFull comprehensive check (all modules)" \
    "fix\tAutomatically fix detected issues" \
    "report\tGenerate detailed health report"
    complete -c ash \
        -n '__ash_comp_using_subcommand doctor && not __ash_comp_seen_subcommand quick full fix report' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand doctor && __ash_comp_seen_subcommand full' \
    -l check -r \
    -a "system wayland hyprland gpu audio bluetooth network fonts tools configs theme-engine plugins permissions disk-space security performance xdg-portals services" \
    -d "Run specific check module"

complete -c ash -n '__ash_comp_using_subcommand doctor && __ash_comp_seen_subcommand report' \
    -l output -s o -r -d "Output file path"
complete -c ash -n '__ash_comp_using_subcommand doctor && __ash_comp_seen_subcommand report' \
    -l format -r -a "text json html markdown" -d "Report format"
complete -c ash -n '__ash_comp_using_subcommand doctor' \
    -l verbose   -d "Verbose check output"
complete -c ash -n '__ash_comp_using_subcommand doctor' \
    -l no-fix    -d "Check only, do not fix"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 UPDATE SUBCOMMAND COMPLETIONS                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "system\tUpdate system packages" \
    "dotfiles\tUpdate ASH dotfiles from git" \
    "plugins\tUpdate all plugins" \
    "themes\tUpdate all themes" \
    "nvim\tUpdate Neovim plugins" \
    "fish\tUpdate Fish plugins" \
    "flatpak\tUpdate Flatpak applications" \
    "all\tUpdate everything at once" \
    "check\tCheck for available updates" \
    "rollback\tRollback last update"
    complete -c ash \
        -n '__ash_comp_using_subcommand update && not __ash_comp_seen_subcommand system dotfiles plugins themes nvim fish flatpak all check rollback' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand update' \
    -l no-restart    -d "Do not restart services after update"
complete -c ash -n '__ash_comp_using_subcommand update' \
    -l no-snapshot   -d "Skip pre-update snapshot"
complete -c ash -n '__ash_comp_using_subcommand update' \
    -l dry-run       -d "Preview updates without applying"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📷 SHOT SUBCOMMAND COMPLETIONS                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "full\tCapture entire screen" \
    "area\tCapture selected region" \
    "window\tCapture active window" \
    "monitor\tCapture specific monitor" \
    "ocr\tCapture and extract text (OCR)" \
    "color\tPick color from screen" \
    "record\tRecord screen to video" \
    "gif\tRecord screen to GIF" \
    "annotate\tCapture and annotate" \
    "timer\tCapture after delay" \
    "upload\tUpload screenshot to URL" \
    "history\tBrowse screenshot history"
    complete -c ash \
        -n '__ash_comp_using_subcommand shot && not __ash_comp_seen_subcommand full area window monitor ocr color record gif annotate timer upload history' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand shot' \
    -l output   -s o -r -d "Output file path"
complete -c ash -n '__ash_comp_using_subcommand shot' \
    -l no-copy      -d "Do not copy to clipboard"
complete -c ash -n '__ash_comp_using_subcommand shot' \
    -l no-notify    -d "No notification after capture"
complete -c ash -n '__ash_comp_using_subcommand shot' \
    -l quality  -r  -d "JPEG quality (1-100)"
complete -c ash -n '__ash_comp_using_subcommand shot && __ash_comp_seen_subcommand timer' \
    -l delay    -r  -d "Delay in seconds"
complete -c ash -n '__ash_comp_using_subcommand shot && __ash_comp_seen_subcommand record' \
    -l audio        -d "Include audio"
complete -c ash -n '__ash_comp_using_subcommand shot && __ash_comp_seen_subcommand record' \
    -l fps      -r  -d "Frame rate (default: 30)"
complete -c ash -n '__ash_comp_using_subcommand shot && __ash_comp_seen_subcommand gif' \
    -l fps      -r  -d "GIF frame rate"
complete -c ash -n '__ash_comp_using_subcommand shot && __ash_comp_seen_subcommand gif' \
    -l optimize     -d "Optimize GIF size"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖼️  WALLPAPER SUBCOMMAND COMPLETIONS                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "set\tSet specific wallpaper" \
    "random\tSet random wallpaper" \
    "pick\tInteractively pick wallpaper" \
    "download\tDownload wallpaper from source" \
    "generate\tGenerate wallpaper" \
    "generate-ai\tGenerate wallpaper with AI" \
    "slideshow\tStart wallpaper slideshow" \
    "blur\tApply blur to current wallpaper" \
    "info\tShow current wallpaper info" \
    "history\tBrowse wallpaper history"
    complete -c ash \
        -n '__ash_comp_using_subcommand wallpaper && not __ash_comp_seen_subcommand set random pick download generate generate-ai slideshow blur info history' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand set' \
    -f -a '(find ~/Pictures ~/Wallpapers ~/.config/ash/wallpapers -name "*.jpg" -o -name "*.png" -o -name "*.webp" 2>/dev/null)' \
    -d "Wallpaper file"

complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand download' \
    -l source -r -a '(__ash_comp_wallpaper_sources)' -d "Download source"
complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand download' \
    -l query  -r -d "Search query"
complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand download' \
    -l count  -r -d "Number to download"

complete -c ash -n '__ash_comp_using_subcommand wallpaper' \
    -l transition -r \
    -a "fade wipe-left wipe-right wipe-up wipe-down grow-center outer wave-left wave-right random" \
    -d "Wallpaper transition style"

complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand slideshow' \
    -l interval -r -d "Interval in seconds"
complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand slideshow' \
    -l random       -d "Random order"

complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand generate-ai' \
    -l prompt   -r -d "AI prompt for wallpaper"
complete -c ash -n '__ash_comp_using_subcommand wallpaper && __ash_comp_seen_subcommand generate-ai' \
    -l model    -r -d "AI model to use"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 BAR SUBCOMMAND COMPLETIONS                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "layout\tSwitch bar layout" \
    "toggle\tToggle bar visibility" \
    "reload\tReload bar configuration" \
    "switch\tSwitch bar application (waybar/ags/eww)"
    complete -c ash \
        -n '__ash_comp_using_subcommand bar && not __ash_comp_seen_subcommand layout toggle reload switch' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand bar && __ash_comp_seen_subcommand layout' \
    -f -a '(__ash_comp_bar_layouts)' -d "Bar layout"

complete -c ash -n '__ash_comp_using_subcommand bar && __ash_comp_seen_subcommand switch' \
    -f -a "waybar\tWaybar status bar" \
    -f -a "ags\tAGS (Hyprland shell)" \
    -f -a "eww\tElkowar Wacky Widgets"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🤖 AI SUBCOMMAND COMPLETIONS                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "chat\tChat with AI assistant" \
    "suggest-theme\tGet AI theme recommendations" \
    "optimize-config\tAI-optimize configuration" \
    "fix-issue\tAI diagnose and fix issues" \
    "explain\tExplain configuration options"
    complete -c ash \
        -n '__ash_comp_using_subcommand ai && not __ash_comp_seen_subcommand chat suggest-theme optimize-config fix-issue explain' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand ai' \
    -l backend -r -a '(__ash_comp_ai_backends)' -d "AI backend"
complete -c ash -n '__ash_comp_using_subcommand ai' \
    -l model   -r -d "AI model name"
complete -c ash -n '__ash_comp_using_subcommand ai && __ash_comp_seen_subcommand chat' \
    -l no-history   -d "Start fresh conversation"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌍 REMOTE SUBCOMMAND COMPLETIONS                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "connect\tConnect to remote machine" \
    "sync-config\tSync configuration to remote" \
    "apply-theme\tApply theme on remote machine"
    complete -c ash \
        -n '__ash_comp_using_subcommand remote && not __ash_comp_seen_subcommand connect sync-config apply-theme' \
        -f -a $sub
end

for sub in connect sync-config apply-theme
    complete -c ash \
        -n "__ash_comp_using_subcommand remote && __ash_comp_seen_subcommand $sub" \
        -f -a '(__ash_comp_ssh_hosts)' -d "Remote host"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔀 MIGRATE SUBCOMMAND COMPLETIONS                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

for sub in "from-hyde\tMigrate from HyDE dotfiles" \
    "from-hyprdots\tMigrate from hyprdots" \
    "from-ml4w\tMigrate from ML4W dotfiles"
    complete -c ash \
        -n '__ash_comp_using_subcommand migrate && not __ash_comp_seen_subcommand from-hyde from-hyprdots from-ml4w' \
        -f -a $sub
end

complete -c ash -n '__ash_comp_using_subcommand migrate' \
    -l backup   -d "Backup existing config before migration"
complete -c ash -n '__ash_comp_using_subcommand migrate' \
    -l dry-run  -d "Preview migration without changes"
complete -c ash -n '__ash_comp_using_subcommand migrate' \
    -l path -r  -d "Path to existing dotfiles"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ COMPLETION OUTPUT SUBCOMMAND                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

complete -c ash -n '__ash_comp_using_subcommand completion && not __ash_comp_seen_subcommand fish bash zsh powershell' \
    -f -a "fish\tFish shell completions" \
    -f -a "bash\tBash completions" \
    -f -a "zsh\tZsh completions" \
    -f -a "powershell\tPowerShell completions"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 MAINTENANCE FUNCTION                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash-completion-cache-clear --description "Clear ASH completion caches"
    rm -rf $_ash_comp_cache_dir 2>/dev/null
    mkdir -p $_ash_comp_cache_dir 2>/dev/null
    echo (set_color green)"  ✓ Completion cache cleared"(set_color normal)
end

abbr --add ashcc 'ash-completion-cache-clear'