# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH GREETING                                ║
# ║           Dynamic greeting with system info on new shell                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fish_greeting
    # Skip greeting in non-interactive or script mode
    status is-interactive || return
    test -n "$FISH_NO_GREETING" && return

    # ── Colors ────────────────────────────────────────────────────────────────
    set -l c_primary  (set_color cba6f7)
    set -l c_secondary (set_color 89b4fa)
    set -l c_tertiary (set_color 94e2d5)
    set -l c_success  (set_color a6e3a1)
    set -l c_warning  (set_color f9e2af)
    set -l c_error    (set_color f38ba8)
    set -l c_text     (set_color cdd6f4)
    set -l c_muted    (set_color 7f849c)
    set -l c_bold     (set_color -o normal)
    set -l c_reset    (set_color normal)

    # ── Time-based greeting ────────────────────────────────────────────────────
    set -l hour (date +%H)
    set -l greeting_emoji ""
    set -l greeting_text ""

    if test $hour -lt 6
        set greeting_emoji "🌙"
        set greeting_text "Good night"
    else if test $hour -lt 12
        set greeting_emoji "☀️"
        set greeting_text "Good morning"
    else if test $hour -lt 17
        set greeting_emoji "🌤️"
        set greeting_text "Good afternoon"
    else if test $hour -lt 21
        set greeting_emoji "🌅"
        set greeting_text "Good evening"
    else
        set greeting_emoji "🌙"
        set greeting_text "Good night"
    end

    # ── System Info ───────────────────────────────────────────────────────────
    set -l os_name    (cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d= -f2 | tr -d '"')
    set -l kernel     (uname -r | cut -d- -f1)
    set -l uptime_str (uptime -p 2>/dev/null | sed 's/up //')
    set -l cpu_model  (grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs | sed 's/  */ /g')
    set -l mem_total  (awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null)
    set -l mem_avail  (awk '/MemAvailable/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null)
    set -l shell_ver  (fish --version 2>&1 | awk '{print $3}')
    set -l nvim_ver   (nvim --version 2>/dev/null | head -1 | awk '{print $2}')
    set -l date_str   (date "+%A, %B %d %Y")
    set -l time_str   (date "+%H:%M")

    # Package count
    set -l pkg_count "?"
    if command -q pacman
        set pkg_count (pacman -Q 2>/dev/null | wc -l)
    end

    # Active Hyprland workspace
    set -l workspace_str ""
    if test -n "$HYPRLAND_INSTANCE_SIGNATURE"
        set -l ws (hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.name // ""')
        test -n "$ws" && set workspace_str " · WS: $ws"
    end

    # ── ASCII Banner ──────────────────────────────────────────────────────────
    echo ""
    echo -s $c_primary"  ╔═══════════════════════════════════════════════════╗"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$greeting_emoji"  "$c_bold$c_text"$greeting_text, "(string upper $USER)"!"$c_reset"                           "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_muted"$date_str · $time_str$workspace_str"$c_reset"         "$c_primary"║"$c_reset
    echo -s $c_primary"  ╠═══════════════════════════════════════════════════╣"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_secondary"󰣇"$c_reset"  "$c_text"$os_name"$c_reset"                          "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_tertiary""$c_reset"  Kernel  "$c_text"$kernel"$c_reset"                         "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_warning"⏱"$c_reset"  Uptime  "$c_text"$uptime_str"$c_reset"                        "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_success"󰏗"$c_reset"  Pkgs    "$c_text"$pkg_count installed"$c_reset"                  "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_secondary"󰘚"$c_reset"  RAM     "$c_text"$(math --scale=1 $mem_avail / 1024)G free of ${mem_total}G"$c_reset"                "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_tertiary""$c_reset"  Shell   "$c_text"Fish $shell_ver"$c_reset"                          "$c_primary"║"$c_reset

    if test -n "$nvim_ver"
        echo -s $c_primary"  ║"$c_reset"  "$c_primary""$c_reset"  Neovim  "$c_text"$nvim_ver"$c_reset"                           "$c_primary"║"$c_reset
    end

    echo -s $c_primary"  ╠═══════════════════════════════════════════════════╣"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_muted"  ash theme   "$c_success"pick"$c_reset"   "$c_muted"ash doctor    "$c_success"check"$c_reset"     "$c_primary"║"$c_reset
    echo -s $c_primary"  ║"$c_reset"  "$c_muted"  ash wall    "$c_success"random"$c_reset" "$c_muted"ash update    "$c_success"upgrade"$c_reset"   "$c_primary"║"$c_reset
    echo -s $c_primary"  ╚═══════════════════════════════════════════════════╝"$c_reset
    echo ""
end