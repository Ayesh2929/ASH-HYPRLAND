# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SYSINFO FISH FUNCTION (FULL)                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function sysinfo -d "Display system information"
    set -l c1  (set_color -o cba6f7)
    set -l c2  (set_color 89b4fa)
    set -l c3  (set_color 94e2d5)
    set -l c4  (set_color a6e3a1)
    set -l c5  (set_color f9e2af)
    set -l ct  (set_color cdd6f4)
    set -l cm  (set_color 7f849c)
    set -l cr  (set_color normal)

    set -l os      (cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d= -f2 | tr -d '"')
    set -l kernel  (uname -r)
    set -l uptime  (uptime -p 2>/dev/null | sed 's/up //' || echo "?")
    set -l shell   "Fish "(fish --version 2>&1 | awk '{print $3}')
    set -l cpu     (grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | string trim | cut -c1-40)
    set -l ram_total (awk '/MemTotal/{printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null)G
    set -l ram_used  (awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.0f", (t-a)/1024/1024}' /proc/meminfo 2>/dev/null)G
    set -l pkgs    (pacman -Q 2>/dev/null | wc -l || echo "?")
    set -l wm      (hyprctl version 2>/dev/null | head -1 | awk '{print $1, $2}' || echo "Hyprland")

    echo ""
    echo -s "  "$c1"╭──────────────────────────────────────╮"$cr
    echo -s "  "$c1"│"$cr"  "$c1(string upper $USER)$cr" @ "$c2(hostname)$cr
    echo -s "  "$c1"├──────────────────────────────────────┤"$cr
    echo -s "  "$c1"│"$cr"  "$cm"OS      "$cr"  "$ct$os$cr
    echo -s "  "$c1"│"$cr"  "$cm"Kernel  "$cr"  "$c3$kernel$cr
    echo -s "  "$c1"│"$cr"  "$cm"Uptime  "$cr"  "$c4$uptime$cr
    echo -s "  "$c1"│"$cr"  "$cm"Shell   "$cr"  "$c2$shell$cr
    echo -s "  "$c1"│"$cr"  "$cm"WM      "$cr"  "$c1$wm$cr
    echo -s "  "$c1"│"$cr"  "$cm"CPU     "$cr"  "$ct$cpu$cr
    echo -s "  "$c1"│"$cr"  "$cm"RAM     "$cr"  "$ct$ram_used"/"$ram_total$cr
    echo -s "  "$c1"│"$cr"  "$cm"Pkgs    "$cr"  "$c5$pkgs" installed"$cr
    echo -s "  "$c1"╰──────────────────────────────────────╯"$cr
    echo ""
end