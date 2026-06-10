# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH COMPLETIONS FOR ASH CLI                 ║
# ║           Tab completion for all ash commands and subcommands              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Disable file completions for ash
complete -c ash -f

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 TOP-LEVEL COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_use_subcommand" -a theme      -d "Theme & wallpaper management"
complete -c ash -n "__fish_use_subcommand" -a shot       -d "Screenshot tools"
complete -c ash -n "__fish_use_subcommand" -a vol        -d "Volume control"
complete -c ash -n "__fish_use_subcommand" -a bright     -d "Brightness control"
complete -c ash -n "__fish_use_subcommand" -a lock       -d "Lock screen"
complete -c ash -n "__fish_use_subcommand" -a reload     -d "Hot-reload configurations"
complete -c ash -n "__fish_use_subcommand" -a doctor     -d "Health check (60+ tests)"
complete -c ash -n "__fish_use_subcommand" -a update     -d "Update dotfiles & packages"
complete -c ash -n "__fish_use_subcommand" -a backup     -d "Backup configuration"
complete -c ash -n "__fish_use_subcommand" -a restore    -d "Restore from backup"
complete -c ash -n "__fish_use_subcommand" -a clean      -d "Clean caches"
complete -c ash -n "__fish_use_subcommand" -a log        -d "View logs"
complete -c ash -n "__fish_use_subcommand" -a version    -d "Show version"
complete -c ash -n "__fish_use_subcommand" -a help       -d "Show help"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 THEME SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from theme" -a pick       -d "Interactive wallpaper picker"
complete -c ash -n "__fish_seen_subcommand_from theme" -a random     -d "Random wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a next       -d "Next wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a prev       -d "Previous wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a apply      -d "Apply specific wallpaper"
complete -c ash -n "__fish_seen_subcommand_from theme" -a reapply    -d "Re-apply current colors"
complete -c ash -n "__fish_seen_subcommand_from theme" -a colors     -d "Show current palette"
complete -c ash -n "__fish_seen_subcommand_from theme" -a export     -d "Export palette to JSON"
complete -c ash -n "__fish_seen_subcommand_from theme" -a list       -d "List all wallpapers"
complete -c ash -n "__fish_seen_subcommand_from theme" -a current    -d "Show current wallpaper"

# Wallpaper categories for 'ash theme random'
complete -c ash -n "__fish_seen_subcommand_from theme" \
    -n "__fish_seen_subcommand_from random" \
    -a "dark light cyberpunk anime abstract nature landscapes space minimal gradient" \
    -d "Wallpaper category"

# File completion for 'ash theme apply'
complete -c ash -n "__fish_seen_subcommand_from theme" \
    -n "__fish_seen_subcommand_from apply" \
    -F

# ═══════════════════════════════════════════════════════════════════════════════
# 📸 SHOT SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from shot" -a full        -d "Full screen capture"
complete -c ash -n "__fish_seen_subcommand_from shot" -a area        -d "Area selection"
complete -c ash -n "__fish_seen_subcommand_from shot" -a window      -d "Active window"
complete -c ash -n "__fish_seen_subcommand_from shot" -a monitor     -d "Current monitor"
complete -c ash -n "__fish_seen_subcommand_from shot" -a edit        -d "Area → editor"
complete -c ash -n "__fish_seen_subcommand_from shot" -a ocr         -d "Area → text (OCR)"
complete -c ash -n "__fish_seen_subcommand_from shot" -a color       -d "Pick color from screen"
complete -c ash -n "__fish_seen_subcommand_from shot" -a delay       -d "Delayed screenshot"
complete -c ash -n "__fish_seen_subcommand_from shot" -a open        -d "Open screenshots folder"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔊 VOL SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from vol" -a up           -d "Increase volume"
complete -c ash -n "__fish_seen_subcommand_from vol" -a down         -d "Decrease volume"
complete -c ash -n "__fish_seen_subcommand_from vol" -a mute         -d "Toggle mute"
complete -c ash -n "__fish_seen_subcommand_from vol" -a set          -d "Set volume to N%"
complete -c ash -n "__fish_seen_subcommand_from vol" -a get          -d "Get current volume"
complete -c ash -n "__fish_seen_subcommand_from vol" -a status       -d "Volume status JSON"

# Volume amount completion
complete -c ash -n "__fish_seen_subcommand_from vol" \
    -n "__fish_seen_subcommand_from up down set" \
    -a "5 10 15 20 25 50 75 100" \
    -d "Percentage"

# ═══════════════════════════════════════════════════════════════════════════════
# ☀️ BRIGHT SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from bright" -a up        -d "Increase brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a down      -d "Decrease brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a set       -d "Set brightness to N%"
complete -c ash -n "__fish_seen_subcommand_from bright" -a get       -d "Get current brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a max       -d "Maximum brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a min       -d "Minimum brightness"
complete -c ash -n "__fish_seen_subcommand_from bright" -a night     -d "Toggle night mode"
complete -c ash -n "__fish_seen_subcommand_from bright" -a status    -d "Brightness status JSON"

# Brightness amount completion
complete -c ash -n "__fish_seen_subcommand_from bright" \
    -n "__fish_seen_subcommand_from up down set" \
    -a "10 20 30 40 50 60 70 80 90 100" \
    -d "Percentage"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 LOCK SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from lock" -a lock        -d "Lock screen"
complete -c ash -n "__fish_seen_subcommand_from lock" -a suspend     -d "Lock and suspend"
complete -c ash -n "__fish_seen_subcommand_from lock" -a hibernate   -d "Lock and hibernate"
complete -c ash -n "__fish_seen_subcommand_from lock" -a immediate   -d "Immediate lock (no hooks)"
complete -c ash -n "__fish_seen_subcommand_from lock" -a status      -d "Lock status"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RELOAD SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from reload" -a all       -d "Reload everything"
complete -c ash -n "__fish_seen_subcommand_from reload" -a hypr      -d "Reload Hyprland"
complete -c ash -n "__fish_seen_subcommand_from reload" -a waybar    -d "Reload Waybar"
complete -c ash -n "__fish_seen_subcommand_from reload" -a dunst     -d "Reload Dunst"
complete -c ash -n "__fish_seen_subcommand_from reload" -a theme     -d "Reapply theme"

# ═══════════════════════════════════════════════════════════════════════════════
# 🧹 CLEAN SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from clean" -a normal     -d "Normal cache clean"
complete -c ash -n "__fish_seen_subcommand_from clean" -a deep       -d "Deep clean (all caches)"

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LOG SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# Log type completion
complete -c ash -n "__fish_seen_subcommand_from log" \
    -a "cli theme-engine install update backup waybar screenshot volume brightness" \
    -d "Log type"

# Line count completion
complete -c ash -n "__fish_seen_subcommand_from log" \
    -a "25 50 100 200 500" \
    -d "Number of lines"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RESTORE SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

complete -c ash -n "__fish_seen_subcommand_from restore" -a list     -d "List available backups"
complete -c ash -n "__fish_seen_subcommand_from restore" -a latest   -d "Restore latest backup"
complete -c ash -n "__fish_seen_subcommand_from restore" -a theme    -d "Restore theme only"
complete -c ash -n "__fish_seen_subcommand_from restore" -a interactive -d "Interactive picker"

# Dynamic backup name completion from backup directory
complete -c ash -n "__fish_seen_subcommand_from restore" \
    -a "(ls ~/.local/share/ash-dots/backups/ 2>/dev/null | grep 'backup-' | sed 's/.tar.gz//')" \
    -d "Backup name"