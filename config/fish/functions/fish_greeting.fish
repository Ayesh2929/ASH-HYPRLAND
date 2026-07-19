# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fish_greeting Ultra                                ║
# ║  Dynamic system dashboard with live stats, art & ASH theme integration     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function fish_greeting --description "ASH ultra system greeting dashboard"

    # ── Skip in non-interactive / tool contexts ───────────────────────────────
    status is-interactive || return 0
    set -q TERM_PROGRAM; and test "$TERM_PROGRAM" = vscode && return 0
    set -q INSIDE_EMACS && return 0
    set -q EMACS         && return 0
    set -q VIM           && return 0
    set -q NVIM          && return 0

    # ── Skip if greeting is suppressed ────────────────────────────────────────
    set -q ASH_NO_GREETING && test "$ASH_NO_GREETING" = 1 && return 0

    # ── Respect $fish_greeting = "" (user silenced it) ────────────────────────
    if set -q fish_greeting && test -z "$fish_greeting"
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLOR RESOLUTION — Dynamic ASH theme sync                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Pull from ASH color globals (set by 21-theme.fish) or fallback
    function __greet_color --description "Resolve color from ASH theme or fallback"
        set -l var_name "ASH_COLOR_"(string upper $argv[1])
        set -l fallback $argv[2]
        if set -q $var_name
            set_color (string replace '#' '' $$var_name) 2>/dev/null
            and return
        end
        set_color $fallback 2>/dev/null
    end

    set -l R    (set_color normal)
    set -l B    (set_color --bold)
    set -l DIM  (set_color brblack)

    set -l C1   (__greet_color mauve    magenta)   # primary accent
    set -l C2   (__greet_color blue     blue)      # secondary
    set -l C3   (__greet_color green    green)      # success / uptime
    set -l C4   (__greet_color yellow   yellow)    # warnings / cpu
    set -l C5   (__greet_color red      red)       # errors / critical
    set -l C6   (__greet_color sky      cyan)      # info / network
    set -l C7   (__greet_color peach    FF9F43)    # orange
    set -l C8   (__greet_color teal     94e2d5)    # teal
    set -l C9   (__greet_color lavender b4befe)    # soft purple
    set -l C10  (__greet_color rosewater f5e0dc)   # pink

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖼️  ASCII ART — theme-colored dynamic logo                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __greet_art --description "Render ASH ASCII art logo"
        set -l A  $C1   # left half
        set -l B2 $C2   # right half
        set -l D  $DIM

        printf "\n"
        printf "  $A    ___   ____  __  __     $R\n"
        printf "  $A   /   | / __/ / / / /     $R\n"
        printf "  $A  / /| |/ /_  / /_/ /      $R\n"
        printf "  $A / ___ /\\__/ /_/\\__,_/      $R\n"
        printf "  $A/_/  |_\\____/               $R$D v5.0 OMEGA$R\n"
        printf "\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 SYSTEM INFO COLLECTORS                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ─── OS & Kernel ──────────────────────────────────────────────────────────
    function __greet_os --description "Get OS name"
        if test -f /etc/os-release
            grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | \
                cut -d= -f2 | string trim -c '"'
            return
        end
        uname -s 2>/dev/null
    end

    function __greet_kernel --description "Get kernel version"
        uname -r 2>/dev/null | string split '-' | head -1
    end

    # ─── CPU ──────────────────────────────────────────────────────────────────
    function __greet_cpu --description "Get CPU model"
        if test -f /proc/cpuinfo
            grep '^model name' /proc/cpuinfo 2>/dev/null | head -1 | \
                cut -d: -f2 | string trim | \
                string replace -r '\s+' ' ' | \
                string replace -r '\(R\)|\(TM\)' ''
            return
        end
        sysctl -n machdep.cpu.brand_string 2>/dev/null
    end

    function __greet_cpu_cores --description "Get CPU core / thread count"
        set -l cores  (nproc 2>/dev/null; or sysctl -n hw.logicalcpu 2>/dev/null; or echo "?")
        set -l phys   (grep '^cpu cores' /proc/cpuinfo 2>/dev/null | head -1 | \
                          awk '{print $NF}')
        test -z "$phys" && echo "$cores threads" || echo "$phys cores / $cores threads"
    end

    # ─── CPU Usage ────────────────────────────────────────────────────────────
    function __greet_cpu_usage --description "Get CPU usage percentage"
        # Fast: read /proc/stat twice with 0.1s gap
        if test -f /proc/stat
            set -l s1 (awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat)
            sleep 0.1 2>/dev/null
            set -l s2 (awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat)

            set -l t1 (math (string join '+' (string split ' ' $s1)))
            set -l t2 (math (string join '+' (string split ' ' $s2)))
            set -l i1 (echo $s1 | awk '{print $4}')
            set -l i2 (echo $s2 | awk '{print $4}')

            set -l delta (math $t2 - $t1)
            set -l idle  (math $i2 - $i1)

            if test $delta -gt 0
                math --scale 1 "(($delta - $idle) * 100) / $delta"
                return
            end
        end
        echo "?"
    end

    function __greet_cpu_temp --description "Get CPU temperature"
        # Try multiple sources
        for temp_path in \
            /sys/class/thermal/thermal_zone0/temp \
            /sys/class/hwmon/hwmon0/temp1_input \
            /sys/class/hwmon/hwmon1/temp1_input
            if test -f $temp_path
                set -l raw (cat $temp_path 2>/dev/null)
                if test -n "$raw" && test $raw -gt 1000
                    math --scale 1 "$raw / 1000"
                    echo "°C"
                    return
                end
            end
        end

        command -q sensors && sensors 2>/dev/null | \
            awk '/^(Core 0|Tdie|temp1)/{gsub(/[+°C]/,"",$2); print $2"°C"; exit}'
    end

    # ─── Memory ───────────────────────────────────────────────────────────────
    function __greet_memory --description "Get memory usage"
        if test -f /proc/meminfo
            set -l total (awk '/^MemTotal/{print $2}' /proc/meminfo)
            set -l avail (awk '/^MemAvailable/{print $2}' /proc/meminfo)
            set -l used  (math $total - $avail)
            set -l pct   (math --scale 1 "$used * 100 / $total")

            set -l used_mb  (math --scale 0 "$used / 1024")
            set -l total_mb (math --scale 0 "$total / 1024")

            if test $total_mb -ge 1024
                set -l used_g  (math --scale 1 "$used_mb / 1024")
                set -l total_g (math --scale 1 "$total_mb / 1024")
                echo "$used_g GiB / $total_g GiB ($pct%)"
            else
                echo "$used_mb MiB / $total_mb MiB ($pct%)"
            end
            return
        end

        # macOS
        command -q vm_stat && begin
            set -l pages_free (vm_stat | awk '/Pages free/{gsub(/\./,"",$3);print $3}')
            set -l page_size  (sysctl -n hw.pagesize 2>/dev/null; or echo 4096)
            set -l total_mem  (sysctl -n hw.memsize 2>/dev/null)
            set -l used_mem   (math $total_mem - ($pages_free * $page_size))
            echo (math --scale 1 "$used_mem / 1073741824")" GiB / "(math --scale 1 "$total_mem / 1073741824")" GiB"
        end
    end

    function __greet_mem_pct --description "Memory usage percentage"
        if test -f /proc/meminfo
            set -l total (awk '/^MemTotal/{print $2}'    /proc/meminfo)
            set -l avail (awk '/^MemAvailable/{print $2}' /proc/meminfo)
            math --scale 0 "(($total - $avail) * 100) / $total"
        else
            echo 0
        end
    end

    # ─── Disk ─────────────────────────────────────────────────────────────────
    function __greet_disk --description "Get disk usage for /"
        df -h / 2>/dev/null | awk 'NR==2{print $3" / "$2" ("$5" used)"}'
    end

    function __greet_disk_pct --description "Get disk usage percentage"
        df / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}'
    end

    # ─── Network ──────────────────────────────────────────────────────────────
    function __greet_ip --description "Get primary local IP"
        # Prefer ip command
        if command -q ip
            ip route get 1.1.1.1 2>/dev/null | \
                awk '/src/{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}'
            return
        end
        # macOS
        ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v 127 | head -1
    end

    function __greet_iface --description "Get primary network interface"
        if command -q ip
            ip route 2>/dev/null | awk '/^default/{print $5; exit}'
            return
        end
        route -n get default 2>/dev/null | awk '/interface/{print $2}'
    end

    function __greet_ssid --description "Get current WiFi SSID"
        if command -q nmcli
            nmcli -t -f active,ssid dev wifi 2>/dev/null | \
                awk -F: '/^yes/{print $2; exit}'
            return
        end
        if command -q iwgetid
            iwgetid -r 2>/dev/null
            return
        end
        # macOS
        /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport \
            -I 2>/dev/null | awk '/ SSID/{print $2}'
    end

    # ─── GPU ──────────────────────────────────────────────────────────────────
    function __greet_gpu --description "Get GPU name"
        # NVIDIA
        if command -q nvidia-smi
            nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1
            return
        end
        # AMD
        if test -f /sys/class/drm/card0/device/product_name
            cat /sys/class/drm/card0/device/product_name 2>/dev/null
            return
        end
        # lspci fallback
        if command -q lspci
            lspci 2>/dev/null | grep -i 'vga\|3d\|display' | \
                sed 's/.*: //' | head -1
            return
        end
        echo "Unknown"
    end

    function __greet_gpu_usage --description "Get GPU usage (NVIDIA)"
        if command -q nvidia-smi
            nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits \
                2>/dev/null | head -1 | string trim
        end
    end

    # ─── Uptime ───────────────────────────────────────────────────────────────
    function __greet_uptime --description "Get formatted uptime"
        if test -f /proc/uptime
            set -l secs (awk '{print int($1)}' /proc/uptime)
            set -l days  (math --scale 0 "$secs / 86400")
            set -l hours (math --scale 0 "($secs % 86400) / 3600")
            set -l mins  (math --scale 0 "($secs % 3600) / 60")

            set -l parts
            test $days  -gt 0 && set --append parts "$days"d
            test $hours -gt 0 && set --append parts "$hours"h
            test $mins  -gt 0 && set --append parts "$mins"m
            test (count $parts) -eq 0 && set parts "< 1m"
            string join ' ' $parts
            return
        end
        uptime 2>/dev/null | sed 's/.*up //' | sed 's/,.*//'
    end

    # ─── Package managers ─────────────────────────────────────────────────────
    function __greet_pkgs --description "Get installed package counts"
        set -l parts

        command -q pacman   && set --append parts (pacman -Qq 2>/dev/null | wc -l | string trim)" pacman"
        command -q dpkg     && set --append parts (dpkg --get-selections 2>/dev/null | grep -c '\binstall\b')" dpkg"
        command -q rpm      && set --append parts (rpm -qa 2>/dev/null | wc -l | string trim)" rpm"
        command -q flatpak  && test (flatpak list 2>/dev/null | wc -l | string trim) -gt 0 && \
            set --append parts (flatpak list 2>/dev/null | wc -l | string trim)" flatpak"
        command -q snap     && test (snap list 2>/dev/null | tail -n +2 | wc -l | string trim) -gt 0 && \
            set --append parts (snap list 2>/dev/null | tail -n +2 | wc -l | string trim)" snap"
        command -q brew     && set --append parts (brew list 2>/dev/null | wc -l | string trim)" brew"
        command -q nix-env  && set --append parts (nix-env -q 2>/dev/null | wc -l | string trim)" nix"

        if test (count $parts) -gt 0
            string join ', ' $parts
        else
            echo "unknown"
        end
    end

    # ─── Shell & Terminal ─────────────────────────────────────────────────────
    function __greet_shell --description "Get fish version"
        echo "fish "(__fish_version 2>/dev/null; or echo "?")
    end

    function __greet_term --description "Get terminal emulator"
        if test -n "$TERM_PROGRAM"
            echo $TERM_PROGRAM
            return
        end
        if test -n "$TERM"
            echo $TERM
            return
        end
        # Try to detect via process tree
        set -l ppid (ps -o ppid= -p $fish_pid 2>/dev/null | string trim)
        set -l parent_name (ps -o comm= -p $ppid 2>/dev/null | string trim)
        echo $parent_name
    end

    # ─── ASH State ────────────────────────────────────────────────────────────
    function __greet_ash_theme --description "Get current ASH theme name"
        if set -q ASH_THEME_NAME
            echo $ASH_THEME_NAME
            return
        end
        set -l state "$HOME/.local/share/ash/state/current-theme.json"
        if test -f $state && command -q jq
            jq -r '.name // "unknown"' $state 2>/dev/null
            return
        end
        echo "catppuccin-mocha"
    end

    function __greet_ash_mode --description "Get current ASH mode"
        set -l state "$HOME/.local/share/ash/state/current-mode.json"
        if test -f $state && command -q jq
            jq -r '.mode // "default"' $state 2>/dev/null
            return
        end
        echo "default"
    end

    function __greet_ash_plugins --description "Count installed ASH plugins"
        set -l plugins_dir "$HOME/.config/ash/plugins"
        if test -d $plugins_dir
            count $plugins_dir/core/*/ $plugins_dir/integrations/*/ 2>/dev/null | \
                awk '{sum+=$1} END{print sum}'
            return
        end
        echo "0"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 PROGRESS BAR RENDERER                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __greet_bar --description "Render a themed progress bar"
        set -l pct   $argv[1]   # 0-100
        set -l width $argv[2]   # bar width in chars
        set -l label $argv[3]   # optional label

        test -z "$width" && set width 20
        test -z "$pct"   && set pct 0

        set -l filled (math --scale 0 "min($pct, 100) * $width / 100")
        set -l empty  (math $width - $filled)

        # Color by threshold
        set -l bar_color $C3   # green
        test $pct -gt 60 && set bar_color $C4  # yellow
        test $pct -gt 85 && set bar_color $C5  # red

        set -l bar_fill  (string repeat -n $filled "█")
        set -l bar_empty (string repeat -n $empty  "░")

        printf "%s%s%s%s  %s%3d%%%s" \
            $bar_color $bar_fill $DIM $bar_empty \
            $bar_color $pct $R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🕐 DATE/TIME HELPERS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __greet_datetime --description "Get formatted date and time"
        date '+%A, %B %-d %Y  %H:%M:%S' 2>/dev/null; \
            or date '+%A, %B %d %Y  %H:%M:%S'
    end

    function __greet_greeting_word --description "Time-appropriate greeting"
        set -l hour (date +%H)
        if test $hour -lt 5
            echo "🌙 Good night"
        else if test $hour -lt 12
            echo "🌅 Good morning"
        else if test $hour -lt 17
            echo "☀️  Good afternoon"
        else if test $hour -lt 21
            echo "🌇 Good evening"
        else
            echo "🌙 Good night"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎴 MOTD: Rotating motivational quotes                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __greet_quote --description "Return a rotating motivational quote"
        set -l quotes \
            "The best way to predict the future is to create it." \
            "Code is like humor. When you have to explain it, it's bad." \
            "First, solve the problem. Then, write the code." \
            "Simplicity is the soul of efficiency." \
            "Programs must be written for people to read." \
            "It works on my machine. — Every developer, ever." \
            "Talk is cheap. Show me the code.  — Linus Torvalds" \
            "Make it work, make it right, make it fast." \
            "The best code is no code at all." \
            "Any fool can write code that a computer can understand." \
            "Good code is its own best documentation." \
            "Premature optimization is the root of all evil." \
            "In order to understand recursion, see: recursion." \
            "A bug is just an undocumented feature." \
            "If debugging is the process of removing bugs, programming must be the act of putting them in." \
            "You don't have to be great to start, but you have to start to be great." \
            "The only way to do great work is to love what you do. — Steve Jobs" \
            "Keep it simple, stupid." \
            "Done is better than perfect." \
            "Write code for humans first, computers second."

        set -l idx (math (date +%j 2>/dev/null; or echo 1) % (count $quotes) + 1)
        echo $quotes[$idx]
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔔 GIT REPO STATUS                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __greet_git_status --description "Show git status if in a repo"
        command -q git || return
        git -C . rev-parse --is-inside-work-tree 2>/dev/null | grep -q true || return

        set -l branch (git branch --show-current 2>/dev/null)
        set -l status_short (git status --porcelain 2>/dev/null | head -5)
        set -l ahead  (git rev-list @{u}..HEAD 2>/dev/null | wc -l | string trim)
        set -l behind (git rev-list HEAD..@{u} 2>/dev/null | wc -l | string trim)

        set -l status_parts
        test -n "$branch" && set --append status_parts "$C2 $branch$R"
        test "$ahead"  -gt 0 2>/dev/null && set --append status_parts "$C3⬆ $ahead$R"
        test "$behind" -gt 0 2>/dev/null && set --append status_parts "$C5⬇ $behind$R"
        test -n "$status_short" && set --append status_parts "$C4✎ modified$R"

        test (count $status_parts) -gt 0 && \
            printf "  $DIM│$R  $DIM  $R%s\n" (string join "  " $status_parts)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 LAYOUT MODES                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Detect terminal width for responsive layout
    set -l term_width  (tput cols  2>/dev/null; or echo 80)
    set -l term_height (tput lines 2>/dev/null; or echo 24)

    # Choose layout: minimal / compact / full
    set -l layout full
    test $term_width -lt 80                                    && set layout minimal
    test $term_width -lt 100 && test "$layout" = full         && set layout compact
    set -q ASH_GREETING_LAYOUT && set layout $ASH_GREETING_LAYOUT

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎭 LAYOUT: MINIMAL (< 80 cols)                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$layout" = minimal
        printf "\n"
        printf "  $B$C1(__greet_greeting_word), $USER!$R\n"
        printf "  $DIM%s$R\n" (__greet_datetime)
        printf "\n"
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎭 LAYOUT: COMPACT (80-100 cols)                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$layout" = compact
        # Collect data
        set -l mem_info  (__greet_memory)
        set -l mem_pct   (__greet_mem_pct)
        set -l disk_info (__greet_disk)
        set -l disk_pct  (__greet_disk_pct)
        set -l uptime    (__greet_uptime)
        set -l ip        (__greet_ip)

        printf "\n"
        printf "  $B$C1  (__greet_greeting_word), $USER!$R  $DIM%s$R\n" (__greet_datetime)
        printf "\n"
        printf "  $DIM┌─────────────────────────────────────────┐$R\n"
        printf "  $DIM│$R  $C6 %-10s$R  $DIM│$R  $C3 %-18s$R  $DIM│$R\n" \
            "Uptime" $uptime
        printf "  $DIM│$R  $C4 %-10s$R  $DIM│$R  $DIM%-18s$R  $DIM│$R\n" \
            "Memory" $mem_info
        printf "  $DIM│$R  $C7 %-10s$R  $DIM│$R  $DIM%-18s$R  $DIM│$R\n" \
            "Disk" $disk_info
        test -n "$ip" && \
            printf "  $DIM│$R  $C8 %-10s$R  $DIM│$R  $DIM%-18s$R  $DIM│$R\n" \
                "IP" $ip
        printf "  $DIM└─────────────────────────────────────────┘$R\n"
        printf "\n"
        printf "  $DIM\"$R$C9%s$R$DIM\"$R\n" (__greet_quote)
        printf "\n"
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎭 LAYOUT: FULL (≥ 100 cols)  ← DEFAULT                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Collect all system data (parallel where possible) ─────────────────────
    set -l _os        (__greet_os)
    set -l _kernel    (__greet_kernel)
    set -l _cpu       (__greet_cpu)
    set -l _cpu_cores (__greet_cpu_cores)
    set -l _gpu       (__greet_gpu)
    set -l _mem_str   (__greet_memory)
    set -l _mem_pct   (__greet_mem_pct)
    set -l _disk_str  (__greet_disk)
    set -l _disk_pct  (__greet_disk_pct)
    set -l _uptime    (__greet_uptime)
    set -l _ip        (__greet_ip)
    set -l _iface     (__greet_iface)
    set -l _ssid      (__greet_ssid)
    set -l _shell     (__greet_shell)
    set -l _term      (__greet_term)
    set -l _pkgs      (__greet_pkgs)
    set -l _dt        (__greet_datetime)
    set -l _greeting  (__greet_greeting_word)
    set -l _quote     (__greet_quote)
    set -l _theme     (__greet_ash_theme)
    set -l _mode      (__greet_ash_mode)
    set -l _plugins   (__greet_ash_plugins)

    # ── Optional: GPU usage (only if NVIDIA present) ──────────────────────────
    set -l _gpu_usage ""
    command -q nvidia-smi && set _gpu_usage (__greet_gpu_usage)

    # ── Optional: CPU temperature ─────────────────────────────────────────────
    set -l _cpu_temp (__greet_cpu_temp)

    # ── Helper: row renderer ──────────────────────────────────────────────────
    function __row --description "Render a dashboard row"
        set -l icon  $argv[1]
        set -l label $argv[2]
        set -l value $argv[3]
        set -l extra $argv[4]   # optional bar or secondary info
        printf "  $DIM│$R  %s  $B$DIM%-14s$R  %-38s  %s$DIM│$R\n" \
            $icon $label $value $extra
    end

    function __divider --description "Render a horizontal divider row"
        printf "  $DIM├%s┤$R\n" (string repeat -n 60 "─")
    end

    function __section --description "Render a section header row"
        set -l label $argv[1]
        set -l pad   (math 58 - (string length $label))
        printf "  $DIM│$R  $B$C1%-59s$R  $DIM│$R\n" $label
    end

    function __empty_row --description "Render empty row"
        printf "  $DIM│%-62s│$R\n" " "
    end

    # ── Top border ────────────────────────────────────────────────────────────
    printf "\n"
    __greet_art

    # ── Greeting header ───────────────────────────────────────────────────────
    printf "  $DIM╔%s╗$R\n" (string repeat -n 60 "═")
    printf "  $DIM║$R  $B$C1%s, %s!$R%s  $DIM║$R\n" \
        $_greeting $USER \
        (string repeat -n (math 43 - (string length "$_greeting, $USER!")) " ")
    printf "  $DIM║$R  $DIM%-60s$DIM║$R\n" "  $_dt"
    printf "  $DIM╠%s╣$R\n" (string repeat -n 60 "═")

    # ── Section: SYSTEM ───────────────────────────────────────────────────────
    __empty_row
    __section "  💻  SYSTEM"
    __empty_row
    __row "  " "OS"       (string sub --length 38 $_os)
    __row "  " "Kernel"   "$_kernel" "  $DIM($(uname -m))$R"
    __row " " "Shell"    "$_shell"
    __row "  " "Terminal" "$_term"
    __row " " "Packages" (string sub --length 38 $_pkgs)

    # ── Section: HARDWARE ─────────────────────────────────────────────────────
    __divider
    __empty_row
    __section "  🖥️   HARDWARE"
    __empty_row

    # CPU row with bar
    set -l _cpu_usage_val (__greet_cpu_usage)
    set -l _cpu_bar ""
    if string match -qr '^\d+' $_cpu_usage_val
        set _cpu_bar (__greet_bar (math --scale 0 "$_cpu_usage_val") 12)
    end
    __row " " "CPU" (string sub --length 28 (string replace -r '\s+' ' ' $_cpu)) "$_cpu_bar"
    __row "  " "CPU Cores" "$_cpu_cores"
    test -n "$_cpu_temp" && __row " " "CPU Temp"   "$_cpu_temp°C"

    # GPU row
    if test -n "$_gpu" && test "$_gpu" != Unknown
        set -l _gpu_bar ""
        if test -n "$_gpu_usage" && string match -qr '^\d+' $_gpu_usage
            set _gpu_bar (__greet_bar $_gpu_usage 12)
        end
        __row " " "GPU"       (string sub --length 28 $_gpu) "$_gpu_bar"
    end

    # Memory row with bar
    set -l _mem_bar (__greet_bar $_mem_pct 12)
    __row "  " "Memory"   (string sub --length 28 $_mem_str) "$_mem_bar"

    # Disk row with bar
    set -l _disk_bar (__greet_bar $_disk_pct 12)
    __row " " "Disk (/)"  (string sub --length 28 $_disk_str) "$_disk_bar"

    # ── Section: NETWORK ──────────────────────────────────────────────────────
    __divider
    __empty_row
    __section "  🌐  NETWORK"
    __empty_row

    test -n "$_iface" && __row " " "Interface" "$_iface"
    test -n "$_ip"    && __row "  " "IP Address" "$_ip"
    test -n "$_ssid"  && __row " " "WiFi"      "$_ssid"

    # Public IP (only if we can get it quickly)
    set -l _pub_ip ""
    if command -q curl
        set _pub_ip (curl -s --max-time 1 --connect-timeout 1 \
            https://api.ipify.org 2>/dev/null; or echo "")
        test -n "$_pub_ip" && __row "  " "Public IP" "$_pub_ip"
    end

    # ── Section: ASH DOTFILES ─────────────────────────────────────────────────
    __divider
    __empty_row
    __section "  ⚡  ASH DOTFILES v5.0"
    __empty_row

    __row " " "Theme"   "$_theme"
    __row " " "Variant" (test -n "$ASH_THEME_VARIANT" && echo $ASH_THEME_VARIANT || echo dark)
    __row " " "Mode"    "$_mode"
    __row " " "Plugins" "$_plugins"
    __row "  " "Uptime"  "$_uptime"

    # ── Git status (if in repo) ────────────────────────────────────────────────
    set -l _in_git (git -C . rev-parse --is-inside-work-tree 2>/dev/null)
    if test "$_in_git" = true
        __divider
        __empty_row
        __section "   GIT REPOSITORY"
        __empty_row

        set -l _git_branch (git branch --show-current 2>/dev/null)
        set -l _git_remote (git remote get-url origin 2>/dev/null | \
            string replace 'https://github.com/' '' | \
            string replace 'git@github.com:' '')
        set -l _git_ahead  (git rev-list @{u}..HEAD 2>/dev/null | wc -l | string trim)
        set -l _git_behind (git rev-list HEAD..@{u} 2>/dev/null | wc -l | string trim)
        set -l _git_mods   (git status --porcelain 2>/dev/null | grep -c '^.M'; or echo 0)
        set -l _git_untrk  (git status --porcelain 2>/dev/null | grep -c '^??'; or echo 0)

        test -n "$_git_branch" && __row "  " "Branch"   "$_git_branch"
        test -n "$_git_remote" && __row " " "Remote"   "$_git_remote"
        test "$_git_ahead"  -gt 0 2>/dev/null && \
            __row " " "Ahead"    "$_git_ahead commits to push" "  $C3↑$R"
        test "$_git_behind" -gt 0 2>/dev/null && \
            __row " " "Behind"   "$_git_behind commits to pull" "  $C4↓$R"
        test "$_git_mods" -gt 0 2>/dev/null && \
            __row " " "Modified" "$_git_mods file(s)" "  $C4●$R"
        test "$_git_untrk" -gt 0 2>/dev/null && \
            __row "  " "Untracked" "$_git_untrk file(s)" "  $DIM?$R"
    end

    # ── Quote footer ──────────────────────────────────────────────────────────
    __divider
    __empty_row
    printf "  $DIM│$R  $DIM\"$R$C9%-59s$R$DIM│$R\n" \
        (string sub --length 59 $_quote)
    __empty_row

    # ── Bottom border ─────────────────────────────────────────────────────────
    printf "  $DIM╚%s╝$R\n" (string repeat -n 60 "═")
    printf "\n"

    # ── Quick help tip ────────────────────────────────────────────────────────
    printf "  $DIM  ash doctor  │  ash theme pick  │  ash --help$R\n"
    printf "\n"

    # ── Cleanup local functions ───────────────────────────────────────────────
    functions --erase __greet_color __greet_art __greet_os __greet_kernel \
        __greet_cpu __greet_cpu_cores __greet_cpu_usage __greet_cpu_temp \
        __greet_memory __greet_mem_pct __greet_disk __greet_disk_pct \
        __greet_ip __greet_iface __greet_ssid __greet_gpu __greet_gpu_usage \
        __greet_uptime __greet_pkgs __greet_shell __greet_term \
        __greet_ash_theme __greet_ash_mode __greet_ash_plugins \
        __greet_bar __greet_datetime __greet_greeting_word __greet_quote \
        __greet_git_status __row __divider __section __empty_row 2>/dev/null

end
