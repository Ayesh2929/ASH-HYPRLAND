# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SYSINFO FUNCTION                             ║
# ║           Comprehensive system information display                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function sysinfo -d "Display comprehensive system information"
    # ── Colors ────────────────────────────────────────────────────────────────
    set -l c1  (set_color cba6f7)  # primary
    set -l c2  (set_color 89b4fa)  # secondary
    set -l c3  (set_color 94e2d5)  # tertiary
    set -l c4  (set_color a6e3a1)  # success
    set -l c5  (set_color f9e2af)  # warning
    set -l c6  (set_color fab387)  # orange
    set -l ct  (set_color cdd6f4)  # text
    set -l cm  (set_color 7f849c)  # muted
    set -l cr  (set_color normal)

    function _row -a label value color
        echo -s "  "$cm$label$cr"  "$color$value$cr
    end

    echo ""
    echo -s $c1"  ╔════════════════════════════════════════════════╗"$cr
    echo -s $c1"  ║"$cr"      "$c1"ASH"$cr" System Information — "(date "+%Y-%m-%d %H:%M")$c1"     ║"$cr
    echo -s $c1"  ╚════════════════════════════════════════════════╝"$cr
    echo ""

    # ── OS & Kernel ───────────────────────────────────────────────────────────
    echo -s "  "$c2"  System"$cr
    set -l os_name (cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d= -f2 | tr -d '"')
    set -l kernel  (uname -r)
    set -l arch    (uname -m)
    set -l host    (hostname)
    set -l uptime  (uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")

    _row "OS      " $os_name $ct
    _row "Kernel  " $kernel $c3
    _row "Arch    " $arch $cm
    _row "Host    " $host $c2
    _row "Uptime  " $uptime $c4
    echo ""

    # ── CPU ───────────────────────────────────────────────────────────────────
    echo -s "  "$c1"󰘚 CPU"$cr
    set -l cpu_model (grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | string trim)
    set -l cpu_cores (nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)
    set -l cpu_freq  (cat /proc/cpuinfo | grep "cpu MHz" | awk '{printf "%.0f", $4}' | sort -n | tail -1)
    set -l cpu_temp  ""
    if test -f /sys/class/thermal/thermal_zone0/temp
        set -l raw (cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        set cpu_temp (math $raw / 1000)"°C"
    end

    _row "Model   " $cpu_model $ct
    _row "Cores   " $cpu_cores $c3
    test -n "$cpu_freq" && _row "Speed   " $cpu_freq"MHz" $c2
    test -n "$cpu_temp" && _row "Temp    " $cpu_temp $c5
    echo ""

    # ── Memory ────────────────────────────────────────────────────────────────
    echo -s "  "$c3"󰍛 Memory"$cr
    set -l mem_info (cat /proc/meminfo 2>/dev/null)
    set -l mem_total (echo $mem_info | grep -oP "MemTotal:\s+\K\d+")
    set -l mem_avail (echo $mem_info | grep -oP "MemAvailable:\s+\K\d+")
    set -l mem_used  (math $mem_total - $mem_avail)
    set -l mem_pct   (math --scale=1 "$mem_used * 100 / $mem_total")

    set -l swap_total (echo $mem_info | grep -oP "SwapTotal:\s+\K\d+")
    set -l swap_free  (echo $mem_info | grep -oP "SwapFree:\s+\K\d+")

    set -l mem_used_gb  (math --scale=2 $mem_used / 1024 / 1024)
    set -l mem_total_gb (math --scale=2 $mem_total / 1024 / 1024)
    set -l swap_used_gb (math --scale=2 "(($swap_total - $swap_free)) / 1024 / 1024")
    set -l swap_total_gb (math --scale=2 $swap_total / 1024 / 1024)

    # Memory bar
    set -l bar_width 20
    set -l bar_filled (math --scale=0 "$bar_width * $mem_pct / 100")
    set -l bar_empty  (math $bar_width - $bar_filled)
    set -l bar ""
    for i in (seq 1 $bar_filled); set bar "$bar█"; end
    for i in (seq 1 $bar_empty);  set bar "$bar░"; end

    _row "RAM     " "$mem_used_gb"G" / $mem_total_gb"G" ($mem_pct%)" $ct
    echo -s "  "$cm"Bar     "$cr"  "$c2$bar$cr
    if test $swap_total -gt 0
        _row "Swap    " "$swap_used_gb"G" / $swap_total_gb"G $cr
    end
    echo ""

    # ── Storage ───────────────────────────────────────────────────────────────
    echo -s "  "$c4"󰋊 Storage"$cr
    df -h --output=target,size,used,avail,pcent 2>/dev/null \
        | grep -E "^(/|/home|/tmp|/boot)" \
        | while read -l mount size used avail pct
            echo -s "  "$cm(string pad -r -w 10 $mount)$cr"  "$ct$used"/"$size$cr"  "$cm"free: "$c4$avail$cr"  "$c5$pct$cr
        end
    echo ""

    # ── GPU ───────────────────────────────────────────────────────────────────
    echo -s "  "$c6"󰾲 Graphics"$cr
    set -l gpu (lspci 2>/dev/null | grep -iE "vga|3d|display" | head -2)
    if test -n "$gpu"
        echo $gpu | while read -l line
            echo -s "  "$ct"  "(string replace -r "^.*: " "" $line)$cr
        end
    else
        _row "GPU     " "Not detected" $cm
    end
    echo ""

    # ── Network ───────────────────────────────────────────────────────────────
    echo -s "  "$c2"󰖟 Network"$cr
    if command -q nmcli
        set -l ssid (nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes" | cut -d: -f2)
        set -l ip   (ip -4 addr show 2>/dev/null | grep -oP "(?<=inet )[\d.]+(?=.*/)" | grep -v "^127" | head -1)

        test -n "$ssid" && _row "WiFi    " $ssid $c4
        test -n "$ip"   && _row "Local IP" $ip $c3
    end

    # Public IP (cached or fresh)
    set -l pub_ip (curl -s --max-time 3 "https://ipinfo.io/ip" 2>/dev/null)
    test -n "$pub_ip" && _row "Pub IP  " $pub_ip $c2
    echo ""

    # ── Session ───────────────────────────────────────────────────────────────
    echo -s "  "$cm"󱄅 Session"$cr
    _row "Shell   " "Fish "(fish --version 2>&1 | awk '{print $3}') $c3
    _row "Login   " $USER"@"$host $c2

    if test -n "$WAYLAND_DISPLAY"
        _row "Display " "Wayland ($WAYLAND_DISPLAY)" $c1
    else if test -n "$DISPLAY"
        _row "Display " "X11 ($DISPLAY)" $cm
    end

    if test -n "$HYPRLAND_INSTANCE_SIGNATURE"
        _row "WM      " "Hyprland" $c1
        set -l ws (hyprctl monitors -j 2>/dev/null | jq -r '.[0].activeWorkspace.name // "?"')
        _row "WS      " $ws $c3
    end
    echo ""

    # ── Packages ──────────────────────────────────────────────────────────────
    echo -s "  "$c5"󰏗 Packages"$cr
    if command -q pacman
        set -l pkg_count (pacman -Q 2>/dev/null | wc -l)
        _row "Pacman  " $pkg_count" installed" $ct

        # AUR packages
        if command -q paru
            set -l aur_count (paru -Qm 2>/dev/null | wc -l)
            _row "AUR     " $aur_count" packages" $c6
        end
    end
    echo ""
end

# Alias
complete -c sysinfo -s h -l help -d "Show system info"