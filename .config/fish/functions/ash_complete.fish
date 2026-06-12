# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ENHANCED FISH COMPLETIONS                    ║
# ║           Smart tab completion with descriptions for all ash commands      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Disable file completions for ash
complete -c ash -f

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 TOP-LEVEL COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# Core
complete -c ash -n "__fish_use_subcommand" -a theme      -d "🎨 Theme & wallpaper (pick|random|ai|undo|mode)"
complete -c ash -n "__fish_use_subcommand" -a shot       -d "📸 Screenshot (area|full|window|ocr|edit)"
complete -c ash -n "__fish_use_subcommand" -a vol        -d "🔊 Volume control (up|down|mute|set)"
complete -c ash -n "__fish_use_subcommand" -a bright     -d "☀️  Brightness (up|down|set|night)"
complete -c ash -n "__fish_use_subcommand" -a lock       -d "🔒 Lock screen (lock|suspend|hibernate)"
complete -c ash -n "__fish_use_subcommand" -a reload     -d "🔄 Hot-reload configs (all|hypr|waybar)"

# Maintenance
complete -c ash -n "__fish_use_subcommand" -a doctor     -d "🏥 60+ health checks"
complete -c ash -n "__fish_use_subcommand" -a update     -d "📦 Update dotfiles + packages"
complete -c ash -n "__fish_use_subcommand" -a backup     -d "💾 Backup configuration"
complete -c ash -n "__fish_use_subcommand" -a restore    -d "🔄 Restore from backup"
complete -c ash -n "__fish_use_subcommand" -a clean      -d "🧹 Clean caches (normal|deep)"
complete -c ash -n "__fish_use_subcommand" -a log        -d "📋 View logs"

# Unique Features
complete -c ash -n "__fish_use_subcommand" -a music      -d "🎵 Music reactive theme (enable|disable|once)"
complete -c ash -n "__fish_use_subcommand" -a score      -d "🏆 Desktop health score (show|fix)"
complete -c ash -n "__fish_use_subcommand" -a workspace  -d "📁 Workspace profiles (create|apply|list)"
complete -c ash -n "__fish_use_subcommand" -a smart      -d "🌤️  Smart wallpapers (enable|weather|schedule)"
complete -c ash -n "__fish_use_subcommand" -a analytics  -d "📊 Usage analytics (show|start|export)"
complete -c ash -n "__fish_use_subcommand" -a context    -d "🎭 Context theming (enable|disable|config)"

# Info
complete -c ash -n "__fish_use_subcommand" -a version    -d "ℹ️  Show version"
complete -c ash -n "__fish_use_subcommand" -a help       -d "❓ Show help"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 THEME SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from theme" -a pick    -d "Interactive wallpaper picker"
complete -c ash -n "__fish_seen_subcommand_from theme" -a random  -d "Random wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a next    -d "Next wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a prev    -d "Previous wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a apply   -d "Apply specific wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a reapply -d "Re-apply current colors"
complete -c ash -n "__fish_seen_subcommand_from theme" -a colors  -d "Show current palette"
complete -c ash -n "__fish_seen_subcommand_from theme" -a export  -d "Export palette JSON"
complete -c ash -n "__fish_seen_subcommand_from theme" -a list    -d "List all wallpapers"
complete -c ash -n "__fish_seen_subcommand_from theme" -a undo    -d "↩️  Undo last theme change"
complete -c ash -n "__fish_seen_subcommand_from theme" -a history -d "Browse theme history"
complete -c ash -n "__fish_seen_subcommand_from theme" -a ai      -d "🤖 AI generate theme"
complete -c ash -n "__fish_seen_subcommand_from theme" -a mode    -d "Light/dark mode toggle"
complete -c ash -n "__fish_seen_subcommand_from theme" -a current -d "Show current wallpaper path"

# Theme mode subcommands
complete -c ash -n "__fish_seen_subcommand_from mode" -a light    -d "Switch to light mode"
complete -c ash -n "__fish_seen_subcommand_from mode" -a dark     -d "Switch to dark mode"
complete -c ash -n "__fish_seen_subcommand_from mode" -a toggle   -d "Toggle light/dark"
complete -c ash -n "__fish_seen_subcommand_from mode" -a auto     -d "Auto based on time"
complete -c ash -n "__fish_seen_subcommand_from mode" -a schedule -d "Setup systemd timer"

# Wallpaper categories for random
complete -c ash -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from random" \
    -a "dark light cyberpunk anime abstract nature landscapes space minimal gradient" \
    -d "Wallpaper category"

# File completion for apply
complete -c ash -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from apply" -F

# ═══════════════════════════════════════════════════════════════════════════════
# 🎵 MUSIC SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from music" -a enable  -d "Start music reactive daemon"
complete -c ash -n "__fish_seen_subcommand_from music" -a disable -d "Stop music reactive daemon"
complete -c ash -n "__fish_seen_subcommand_from music" -a toggle  -d "Toggle music reactive"
complete -c ash -n "__fish_seen_subcommand_from music" -a once    -d "Apply current song color"
complete -c ash -n "__fish_seen_subcommand_from music" -a status  -d "Show daemon status"
complete -c ash -n "__fish_seen_subcommand_from music" -a color   -d "Show current music color"
complete -c ash -n "__fish_seen_subcommand_from music" -a reset   -d "Reset to wallpaper theme"

# ═══════════════════════════════════════════════════════════════════════════════
# 🏆 SCORE SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from score" -a show    -d "Show health dashboard"
complete -c ash -n "__fish_seen_subcommand_from score" -a fix     -d "Auto-fix all issues"
complete -c ash -n "__fish_seen_subcommand_from score" -a history -d "Score history"
complete -c ash -n "__fish_seen_subcommand_from score" -a export  -d "Export score data"
complete -c ash -n "__fish_seen_subcommand_from score" -a quick   -d "One-line score"

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 WORKSPACE SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from workspace" -a create -d "Save current workspace"
complete -c ash -n "__fish_seen_subcommand_from workspace" -a apply  -d "Restore workspace profile"
complete -c ash -n "__fish_seen_subcommand_from workspace" -a list   -d "List all profiles"
complete -c ash -n "__fish_seen_subcommand_from workspace" -a delete -d "Delete a profile"
complete -c ash -n "__fish_seen_subcommand_from workspace" -a init   -d "Create built-in profiles"
complete -c ash -n "__fish_seen_subcommand_from workspace" -a profile -d "Profile management"

# Dynamic: complete with saved profile names
complete -c ash \
    -n "__fish_seen_subcommand_from workspace; and __fish_seen_subcommand_from apply" \
    -a "(ls ~/.local/share/ash-dots/workspace-profiles/*.json 2>/dev/null | xargs -I{} basename {} .json)" \
    -d "Profile name"

complete -c ash \
    -n "__fish_seen_subcommand_from workspace; and __fish_seen_subcommand_from delete" \
    -a "(ls ~/.local/share/ash-dots/workspace-profiles/*.json 2>/dev/null | xargs -I{} basename {} .json)" \
    -d "Profile to delete"

# ═══════════════════════════════════════════════════════════════════════════════
# 🌤️ SMART SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from smart" -a enable        -d "Start smart wallpaper daemon"
complete -c ash -n "__fish_seen_subcommand_from smart" -a disable        -d "Stop smart wallpaper daemon"
complete -c ash -n "__fish_seen_subcommand_from smart" -a toggle         -d "Toggle smart wallpapers"
complete -c ash -n "__fish_seen_subcommand_from smart" -a now            -d "Apply time-based wallpaper now"
complete -c ash -n "__fish_seen_subcommand_from smart" -a weather        -d "Apply weather-based wallpaper"
complete -c ash -n "__fish_seen_subcommand_from smart" -a schedule       -d "View schedule file"
complete -c ash -n "__fish_seen_subcommand_from smart" -a edit-schedule  -d "Edit schedule in nvim"
complete -c ash -n "__fish_seen_subcommand_from smart" -a status         -d "Show daemon status"

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 ANALYTICS SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from analytics" -a show    -d "Show usage dashboard"
complete -c ash -n "__fish_seen_subcommand_from analytics" -a start   -d "Start activity tracking"
complete -c ash -n "__fish_seen_subcommand_from analytics" -a stop    -d "Stop activity tracking"
complete -c ash -n "__fish_seen_subcommand_from analytics" -a export  -d "Export data"
complete -c ash -n "__fish_seen_subcommand_from analytics" -a reset   -d "Delete all analytics data"
complete -c ash -n "__fish_seen_subcommand_from analytics" -a status  -d "Show daemon status"

# Export format
complete -c ash \
    -n "__fish_seen_subcommand_from analytics; and __fish_seen_subcommand_from export" \
    -a "json csv" -d "Export format"

# ═══════════════════════════════════════════════════════════════════════════════
# 📸 SHOT SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from shot" -a full    -d "Full screen capture"
complete -c ash -n "__fish_seen_subcommand_from shot" -a area    -d "Interactive area selection"
complete -c ash -n "__fish_seen_subcommand_from shot" -a window  -d "Active window"
complete -c ash -n "__fish_seen_subcommand_from shot" -a monitor -d "Current monitor"
complete -c ash -n "__fish_seen_subcommand_from shot" -a edit    -d "Area → editor (swappy)"
complete -c ash -n "__fish_seen_subcommand_from shot" -a ocr     -d "Area → text extraction"
complete -c ash -n "__fish_seen_subcommand_from shot" -a color   -d "Pick color from screen"
complete -c ash -n "__fish_seen_subcommand_from shot" -a delay   -d "Delayed screenshot"
complete -c ash -n "__fish_seen_subcommand_from shot" -a open    -d "Open screenshots folder"

# Delay seconds
complete -c ash \
    -n "__fish_seen_subcommand_from shot; and __fish_seen_subcommand_from delay" \
    -a "3 5 10" -d "Seconds to wait"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔊 VOL SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from vol" -a up      -d "Increase volume"
complete -c ash -n "__fish_seen_subcommand_from vol" -a down    -d "Decrease volume"
complete -c ash -n "__fish_seen_subcommand_from vol" -a mute    -d "Toggle mute"
complete -c ash -n "__fish_seen_subcommand_from vol" -a set     -d "Set to exact %"
complete -c ash -n "__fish_seen_subcommand_from vol" -a get     -d "Print current volume"
complete -c ash -n "__fish_seen_subcommand_from vol" -a status  -d "Volume status JSON"
complete -c ash -n "__fish_seen_subcommand_from vol" -a backend -d "Show audio backend"

# Volume amounts
for cmd in up down set
    complete -c ash \
        -n "__fish_seen_subcommand_from vol; and __fish_seen_subcommand_from $cmd" \
        -a "5 10 15 20 25 50 75 100" -d "Percentage"
end

# ═══════════════════════════════════════════════════════════════════════════════
# ☀️ BRIGHT SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from bright" -a up     -d "Increase brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a down   -d "Decrease brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a set    -d "Set to exact %"
complete -c ash -n "__fish_seen_subcommand_from bright" -a get    -d "Print current brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a max    -d "Maximum brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a min    -d "Minimum brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a night  -d "Toggle night mode (30%)"
complete -c ash -n "__fish_seen_subcommand_from bright" -a status -d "Brightness status JSON"

for cmd in up down set
    complete -c ash \
        -n "__fish_seen_subcommand_from bright; and __fish_seen_subcommand_from $cmd" \
        -a "5 10 15 20 30 40 50 60 70 80 90 100" -d "Percentage"
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 LOCK SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from lock" -a lock      -d "Lock screen"
complete -c ash -n "__fish_seen_subcommand_from lock" -a suspend   -d "Lock and suspend"
complete -c ash -n "__fish_seen_subcommand_from lock" -a hibernate -d "Lock and hibernate"
complete -c ash -n "__fish_seen_subcommand_from lock" -a immediate -d "Immediate lock (no hooks)"
complete -c ash -n "__fish_seen_subcommand_from lock" -a status    -d "Show lock status"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RELOAD SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from reload" -a all    -d "Reload everything"
complete -c ash -n "__fish_seen_subcommand_from reload" -a hypr   -d "Reload Hyprland"
complete -c ash -n "__fish_seen_subcommand_from reload" -a waybar -d "Reload Waybar"
complete -c ash -n "__fish_seen_subcommand_from reload" -a dunst  -d "Reload Dunst"
complete -c ash -n "__fish_seen_subcommand_from reload" -a theme  -d "Reapply theme"

# ═══════════════════════════════════════════════════════════════════════════════
# 🧹 CLEAN SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from clean" -a normal -d "Normal cache clean"
complete -c ash -n "__fish_seen_subcommand_from clean" -a deep   -d "Deep clean (all caches)"

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LOG SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from log" \
    -a "cli theme-engine install update backup waybar screenshot volume brightness \
        network bluetooth player lock session layout magnifier analytics music" \
    -d "Log type"

complete -c ash -n "__fish_seen_subcommand_from log" \
    -a "25 50 100 200 500" -d "Lines to show"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RESTORE SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from restore" -a list      -d "List available backups"
complete -c ash -n "__fish_seen_subcommand_from restore" -a latest    -d "Restore latest backup"
complete -c ash -n "__fish_seen_subcommand_from restore" -a theme     -d "Restore theme only"
complete -c ash -n "__fish_seen_subcommand_from restore" -a interactive -d "Interactive picker"

# Dynamic backup name completion
complete -c ash \
    -n "__fish_seen_subcommand_from restore" \
    -a "(find ~/.local/share/ash-dots/backups -name 'backup-*.tar.gz' 2>/dev/null \
         | xargs -I{} basename {} .tar.gz 2>/dev/null)" \
    -d "Backup name"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎭 CONTEXT SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from context" -a enable  -d "Enable context theming"
complete -c ash -n "__fish_seen_subcommand_from context" -a disable -d "Disable context theming"
complete -c ash -n "__fish_seen_subcommand_from context" -a toggle  -d "Toggle context theming"
complete -c ash -n "__fish_seen_subcommand_from context" -a status  -d "Show current context"
complete -c ash -n "__fish_seen_subcommand_from context" -a config  -d "Edit configuration"