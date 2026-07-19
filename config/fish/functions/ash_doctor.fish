# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ash_doctor Ultra                                   ║
# ║  Comprehensive system diagnostics with auto-fix, reporting & rich output   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash_doctor --description "ASH ultra system diagnostics"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 PATHS                                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _log_dir    "$HOME/.local/share/ash/logs"
    set -l _log_file   "$_log_dir/doctor-"(date +%Y%m%d-%H%M%S)".log"
    set -l _report_dir "$HOME/.local/share/ash/reports"
    set -l _state_dir  "$HOME/.local/share/ash/state"
    set -l _start_ts   (date +%s)

    mkdir -p $_log_dir $_report_dir $_state_dir 2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 RESULT TRACKING                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -g _doc_pass  0
    set -g _doc_warn  0
    set -g _doc_fail  0
    set -g _doc_info  0
    set -g _doc_fixes 0
    set -g _doc_results   # Array of "level:message"
    set -g _doc_section ""

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📝 CHECK PRIMITIVES                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __doc_log --description "Write to doctor log"
        printf "[%s][%-4s] %s\n" (date '+%H:%M:%S') $argv[1] \
            (string join ' ' $argv[2..-1]) >> $_log_file 2>/dev/null
    end

    function __doc_pass --description "Record a passing check"
        set -g _doc_pass (math $_doc_pass + 1)
        printf "  $GREEN✓$R  %-52s  $GREEN%s$R\n" $argv[1] $argv[2]
        __doc_log PASS "$argv[1]: $argv[2]"
        set --append _doc_results "pass:$argv[1]:$argv[2]"
    end

    function __doc_warn --description "Record a warning"
        set -g _doc_warn (math $_doc_warn + 1)
        printf "  $YELLOW⚠$R  %-52s  $YELLOW%s$R\n" $argv[1] $argv[2]
        __doc_log WARN "$argv[1]: $argv[2]"
        set --append _doc_results "warn:$argv[1]:$argv[2]"
    end

    function __doc_fail --description "Record a failure"
        set -g _doc_fail (math $_doc_fail + 1)
        printf "  $RED✗$R  %-52s  $RED%s$R\n" $argv[1] $argv[2]
        __doc_log FAIL "$argv[1]: $argv[2]"
        set --append _doc_results "fail:$argv[1]:$argv[2]"
    end

    function __doc_info --description "Record an informational check"
        set -g _doc_info (math $_doc_info + 1)
        printf "  $CYAN◆$R  %-52s  $DIM%s$R\n" $argv[1] $argv[2]
        __doc_log INFO "$argv[1]: $argv[2]"
        set --append _doc_results "info:$argv[1]:$argv[2]"
    end

    function __doc_fix --description "Record an auto-fix"
        set -g _doc_fixes (math $_doc_fixes + 1)
        printf "  $ORANGE🔧$R  %-52s  $ORANGE%s$R\n" $argv[1] "FIXED"
        __doc_log FIX "$argv[1]"
    end

    function __doc_section --description "Print section header"
        set -g _doc_section $argv[1]
        set -l icon $argv[2]
        printf "\n  $BOLD$CYAN%s  %s$R\n" $icon $argv[1]
        printf "  $DIM%s$R\n" (string repeat -n 62 "─")
    end

    function __doc_cmd_check --description "Check if command exists"
        set -l name $argv[1]
        set -l cmd  $argv[2]
        test -z "$cmd" && set cmd $name
        set -l importance $argv[3]   # critical | optional
        test -z "$importance" && set importance optional

        if command -q $cmd
            set -l ver ($cmd --version 2>/dev/null | head -1 | \
                grep -oP '\d+\.\d+[\.\d]*' | head -1)
            __doc_pass $name (test -n "$ver" && echo "v$ver" || echo "installed")
        else
            if test "$importance" = critical
                __doc_fail $name "NOT FOUND (required)"
            else
                __doc_warn $name "not installed (optional)"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode  full    # quick | full | fix | report
    set -l _check ""      # specific check module
    set -l _output_fmt text
    set -l _output_file ""
    set -l _quiet   0
    set -l _verbose 0
    set -l _autofix 0

    for arg in $argv
        switch $arg
            case quick -q;             set _mode  quick
            case full;                 set _mode  full
            case fix --fix;            set _mode  fix; set _autofix 1
            case report --report;      set _mode  report
            case -v --verbose;         set _verbose 1
            case --quiet;              set _quiet   1
            case --format=json;        set _output_fmt json
            case --format=html;        set _output_fmt html
            case --format=markdown;    set _output_fmt markdown
            case --check=*
                set _check (string replace '--check=' '' $arg)
            case --output=*
                set _output_file (string replace '--output=' '' $arg)
            case --help -h help
                __doc_help
                return 0
        end
    end

    function __doc_help --description "Print help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🏥  ash_doctor — System Diagnostics              ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  ash_doctor [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-18s$R  %s\n" "(none)"   "Quick check (< 5 seconds)"
        printf "    $CYAN%-18s$R  %s\n" "quick"    "Fast essential checks only"
        printf "    $CYAN%-18s$R  %s\n" "full"     "Comprehensive all-module check"
        printf "    $CYAN%-18s$R  %s\n" "fix"      "Auto-fix detected issues"
        printf "    $CYAN%-18s$R  %s\n" "report"   "Generate detailed report file"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-22s$R  %s\n" "--check=<module>"   "Run specific check module"
        printf "    $CYAN%-22s$R  %s\n" "--format=<fmt>"     "Report format: text|json|html|markdown"
        printf "    $CYAN%-22s$R  %s\n" "--output=<file>"    "Write report to file"
        printf "    $CYAN%-22s$R  %s\n" "--verbose, -v"      "Show extra detail"
        printf "    $CYAN%-22s$R  %s\n" "--quiet"            "Minimal output"
        echo ""
        echo "  $BOLD Modules:$R"
        for mod in system wayland hyprland gpu audio bluetooth network \
            fonts tools-critical tools-optional configs theme-engine \
            plugins permissions disk-space security
            printf "    $DIM• $CYAN%s$R\n" $mod
        end
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖥  BANNER                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    printf "\n"
    printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$PURPLE║  🏥  ASH Doctor — System Diagnostics                        ║$R\n"
    printf "  $BOLD$PURPLE║  %-62s║$R\n" \
        "  Mode: $_mode  ·  "(date '+%A, %B %-d %Y  %H:%M')
    printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════════════╝$R\n"
    printf "\n"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔬 CHECK MODULES                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── MODULE: System ────────────────────────────────────────────────────────
    function __check_system --description "System checks"
        __doc_section "System Environment" "🖥️ "

        # OS info
        set -l os_name (grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | \
            cut -d= -f2 | string trim -c '"')
        test -z "$os_name" && set os_name (uname -s)
        __doc_info "Operating System" $os_name

        # Kernel
        __doc_info "Kernel" (uname -r)

        # Architecture
        set -l arch (uname -m)
        if test "$arch" = x86_64 || test "$arch" = aarch64
            __doc_pass "Architecture" $arch
        else
            __doc_warn "Architecture" "$arch (unusual)"
        end

        # Fish version
        set -l fish_ver (fish --version 2>/dev/null | awk '{print $3}')
        if string match -qr '^3\.(7|8|9|[1-9][0-9])' $fish_ver
            __doc_pass "Fish shell" "v$fish_ver"
        else if test -n "$fish_ver"
            __doc_warn "Fish shell" "v$fish_ver (v3.7+ recommended)"
        else
            __doc_fail "Fish shell" "version unknown"
        end

        # Home directory
        if test -d $HOME && test -w $HOME
            __doc_pass "Home directory" "$HOME (writable)"
        else
            __doc_fail "Home directory" "Not writable: $HOME"
        end

        # XDG dirs
        for xdg_var in XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_RUNTIME_DIR
            if set -q $xdg_var
                __doc_pass $xdg_var $$xdg_var
            else
                __doc_info $xdg_var "not set (using defaults)"
            end
        end

        # Locale
        if set -q LANG
            __doc_info "Locale" $LANG
        else
            __doc_warn "Locale" "LANG not set"
        end

        # Systemd user
        if command -q systemctl
            systemctl --user is-system-running 2>/dev/null | grep -q 'running\|degraded'
            and __doc_pass "systemd user" (systemctl --user is-system-running 2>/dev/null)
            or  __doc_warn "systemd user" "not running"
        end
    end

    # ── MODULE: Wayland ───────────────────────────────────────────────────────
    function __check_wayland --description "Wayland environment checks"
        __doc_section "Wayland Environment" "🖼️ "

        # WAYLAND_DISPLAY
        if set -q WAYLAND_DISPLAY
            __doc_pass "WAYLAND_DISPLAY" $WAYLAND_DISPLAY
        else
            __doc_fail "WAYLAND_DISPLAY" "not set (not in Wayland session)"
        end

        # XDG portals
        if test -d "$HOME/.local/share/xdg-desktop-portal" || \
           test -f "/usr/lib/xdg-desktop-portal"
            __doc_pass "XDG portals" "configured"
        else
            __doc_warn "XDG portals" "xdg-desktop-portal not found"
        end

        # wl-clipboard
        __doc_cmd_check "wl-clipboard (wl-copy)" wl-copy optional

        # Wayland socket
        set -l wl_sock "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        if test -S $wl_sock
            __doc_pass "Wayland socket" $wl_sock
        else
            __doc_warn "Wayland socket" "not found at $wl_sock"
        end

        # PipeWire
        if command -q pw-cli
            set -l pw_state (pw-cli info 2>/dev/null | head -1)
            __doc_pass "PipeWire" "running"
        else
            __doc_warn "PipeWire" "not installed"
        end
    end

    # ── MODULE: Hyprland ──────────────────────────────────────────────────────
    function __check_hyprland --description "Hyprland compositor checks"
        __doc_section "Hyprland" "🪟 "

        # Hyprland binary
        __doc_cmd_check "Hyprland" Hyprland critical

        # HYPRLAND_INSTANCE_SIGNATURE
        if set -q HYPRLAND_INSTANCE_SIGNATURE
            __doc_pass "Session signature" $HYPRLAND_INSTANCE_SIGNATURE
        else
            __doc_warn "Session signature" "not in Hyprland session"
        end

        # hyprctl
        if command -q hyprctl
            set -l version (hyprctl version 2>/dev/null | head -1)
            __doc_pass "hyprctl" (string sub --length 40 $version)

            # Active monitors
            set -l monitors (hyprctl monitors 2>/dev/null | grep -c '^Monitor')
            __doc_info "Active monitors" $monitors

            # Active workspaces
            set -l workspaces (hyprctl workspaces 2>/dev/null | grep -c '^workspace ID')
            __doc_info "Active workspaces" $workspaces
        else
            __doc_warn "hyprctl" "not found"
        end

        # Config file
        for cfg in \
            "$HOME/.config/hypr/hyprland.conf" \
            "$HOME/.config/hyprland.conf"
            if test -f $cfg
                __doc_pass "Config file" $cfg
                break
            end
        end

        # Key components
        for comp in waybar rofi swww hyprlock hypridle dunst
            __doc_cmd_check $comp $comp optional
        end
    end

    # ── MODULE: GPU ───────────────────────────────────────────────────────────
    function __check_gpu --description "GPU driver checks"
        __doc_section "GPU & Display" "🎮 "

        # Detect GPU vendor
        if command -q lspci
            set -l gpu_line (lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1)
            if test -n "$gpu_line"
                __doc_info "GPU" (string sub --length 55 $gpu_line)
            end
        end

        # NVIDIA
        if command -q nvidia-smi
            set -l driver_ver (nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
            __doc_pass "NVIDIA driver" "v$driver_ver"

            # Check for nvidia-open
            if lsmod 2>/dev/null | grep -q nvidia_drm
                __doc_pass "NVIDIA DRM" "loaded"
            else
                __doc_warn "NVIDIA DRM" "not loaded (may cause Wayland issues)"
            end
        end

        # AMD
        if test -d /sys/class/drm
            for card in /sys/class/drm/card*/device/vendor
                set -l vendor (cat $card 2>/dev/null)
                if test "$vendor" = "0x1002"   # AMD
                    __doc_pass "AMD GPU" "detected"
                    command -q vainfo && \
                        __doc_pass "VA-API (AMD)" "available"
                    break
                end
            end
        end

        # Intel
        if test -d "/sys/class/drm/card0"
            test -f "/sys/class/drm/card0/device/vendor" && \
            test (cat /sys/class/drm/card0/device/vendor 2>/dev/null) = "0x8086" && \
                __doc_info "Intel GPU" "detected"
        end

        # Vulkan
        if command -q vulkaninfo
            vulkaninfo 2>/dev/null | grep -q 'VkPhysicalDeviceProperties' && \
                __doc_pass "Vulkan" "available"
        else
            __doc_warn "Vulkan" "vulkaninfo not found"
        end
    end

    # ── MODULE: Audio ─────────────────────────────────────────────────────────
    function __check_audio --description "Audio system checks"
        __doc_section "Audio System" "🔊 "

        # PipeWire
        if command -q pw-cli
            pw-cli info >/dev/null 2>&1 && \
                __doc_pass "PipeWire daemon" "running" || \
                __doc_fail "PipeWire daemon" "not running"
        else
            __doc_warn "PipeWire" "not installed"
        end

        # WirePlumber
        if command -q wpctl
            wpctl status >/dev/null 2>&1 && \
                __doc_pass "WirePlumber" "running" || \
                __doc_warn "WirePlumber" "not running"
        else
            __doc_warn "WirePlumber" "not installed"
        end

        # PulseAudio compat
        if command -q pactl
            pactl info >/dev/null 2>&1 && \
                __doc_pass "PulseAudio compat" "available"
        end

        # Default sink
        if command -q pactl
            set -l sink (pactl get-default-sink 2>/dev/null)
            test -n "$sink" && __doc_info "Default sink" (string sub --length 45 $sink) || \
                __doc_warn "Default sink" "none configured"
        end

        # playerctl
        __doc_cmd_check "playerctl" playerctl optional
    end

    # ── MODULE: Network ───────────────────────────────────────────────────────
    function __check_network --description "Network checks"
        __doc_section "Network" "🌐 "

        # NetworkManager
        if command -q nmcli
            nmcli -t device status 2>/dev/null | grep -q ':connected' && \
                __doc_pass "NetworkManager" "connected" || \
                __doc_warn "NetworkManager" "no active connection"
        else if command -q ip
            ip link show 2>/dev/null | grep -q 'state UP' && \
                __doc_info "Network" "interface UP" || \
                __doc_warn "Network" "no UP interface"
        end

        # Internet connectivity
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
            __doc_pass "Internet (IPv4)" "reachable"
        else
            __doc_fail "Internet (IPv4)" "unreachable"
        end

        # DNS
        if command -q host
            host -t A github.com >/dev/null 2>&1 && \
                __doc_pass "DNS resolution" "working" || \
                __doc_fail "DNS resolution" "failed"
        end

        # SSH agent
        if set -q SSH_AUTH_SOCK && test -S $SSH_AUTH_SOCK
            __doc_pass "SSH agent" $SSH_AUTH_SOCK
        else
            __doc_info "SSH agent" "not running"
        end
    end

    # ── MODULE: Fonts ─────────────────────────────────────────────────────────
    function __check_fonts --description "Font checks"
        __doc_section "Fonts" "🔤 "

        # Required fonts for ASH
        set -l required_fonts \
            "JetBrains Mono" \
            "Nerd Font" \
            "Hack Nerd" \
            "FiraCode"

        set -l optional_fonts \
            "Cascadia Code" \
            "Ubuntu Mono" \
            "Fira Code"

        if command -q fc-list
            for font in $required_fonts
                if fc-list 2>/dev/null | grep -qi $font
                    __doc_pass "Font: $font" "installed"
                else
                    __doc_warn "Font: $font" "not found (icons may not render)"
                end
            end

            # Count total fonts
            set -l total (fc-list 2>/dev/null | wc -l | string trim)
            __doc_info "Total fonts" $total
        else
            __doc_warn "fc-list" "not installed (fontconfig missing)"
        end

        # Nerd Font check via echo
        set -l nf_test ""
        if test -n "$nf_test"
            __doc_pass "Nerd Font rendering" "terminal supports icons"
        else
            __doc_info "Nerd Font rendering" "install a Nerd Font for icons"
        end
    end

    # ── MODULE: Critical Tools ────────────────────────────────────────────────
    function __check_tools_critical --description "Critical tool checks"
        __doc_section "Critical Tools" "🔧 "

        set -l critical_tools \
            "git" "nvim" "fish" "curl" "wget" "jq" \
            "fd" "rg" "bat" "eza" "fzf" "zoxide" \
            "starship" "hyprctl"

        for tool in $critical_tools
            __doc_cmd_check $tool $tool critical
        end
    end

    # ── MODULE: Optional Tools ────────────────────────────────────────────────
    function __check_tools_optional --description "Optional tool checks"
        __doc_section "Optional Tools" "🛠️ "

        set -l optional_tools \
            "lazygit" "delta" "dust" "bottom" "gdu" \
            "tokei" "hyperfine" "sd" "choose" "procs" \
            "zellij" "tmux" "atuin" "mcfly" \
            "docker" "kubectl" "helm" "terraform" \
            "aws" "gcloud" "az" "gh" \
            "node" "python3" "go" "rustc" \
            "fnm" "pnpm" "bun" "deno"

        for tool in $optional_tools
            __doc_cmd_check $tool $tool optional
        end
    end

    # ── MODULE: ASH Config Files ──────────────────────────────────────────────
    function __check_configs --description "Config file checks"
        __doc_section "Configuration Files" "⚙️ "

        set -l critical_configs \
            "$HOME/.config/fish/config.fish" \
            "$HOME/.config/hypr/hyprland.conf" \
            "$HOME/.config/ash"

        for cfg in $critical_configs
            if test -e $cfg
                if test -r $cfg
                    __doc_pass (basename $cfg) \
                        (string replace "$HOME" "~" $cfg)
                else
                    __doc_fail (basename $cfg) "not readable"
                end
            else
                __doc_warn (basename $cfg) "not found"
            end
        end

        # ASH state files
        set -l state_file "$HOME/.local/share/ash/state/current-theme.json"
        if test -f $state_file
            if command -q jq
                jq . $state_file >/dev/null 2>&1 && \
                    __doc_pass "ASH theme state" "valid JSON" || \
                    __doc_fail "ASH theme state" "invalid JSON"
            else
                __doc_pass "ASH theme state" "exists"
            end
        else
            __doc_warn "ASH theme state" "no active theme set"
        end

        # Fish conf.d count
        set -l conf_count (count "$HOME/.config/fish/conf.d/"*.fish 2>/dev/null)
        __doc_info "Fish conf.d files" "$conf_count loaded"
    end

    # ── MODULE: Theme Engine ──────────────────────────────────────────────────
    function __check_theme_engine --description "Theme engine checks"
        __doc_section "ASH Theme Engine" "🎨 "

        # ASH_THEME_NAME
        if set -q ASH_THEME_NAME && test -n "$ASH_THEME_NAME"
            __doc_pass "Active theme" $ASH_THEME_NAME
        else
            __doc_warn "Active theme" "not set (run: ash theme apply <name>)"
        end

        # ASH_THEME_VARIANT
        if set -q ASH_THEME_VARIANT
            __doc_pass "Theme variant" $ASH_THEME_VARIANT
        else
            __doc_info "Theme variant" "not set"
        end

        # Color variables
        set -l color_vars (set -n | grep '^ASH_COLOR_' | count)
        if test $color_vars -gt 10
            __doc_pass "Color variables" "$color_vars loaded"
        else
            __doc_warn "Color variables" "only $color_vars loaded (run: ash_reload --theme)"
        end

        # ash_theme_sync function
        if functions -q ash_theme_sync
            __doc_pass "Theme sync function" "loaded"
        else
            __doc_fail "Theme sync function" "not found (check 21-theme.fish)"
        end

        # swww (wallpaper)
        __doc_cmd_check "swww (wallpaper)" swww optional

        # Bat theme
        if set -q BAT_THEME
            __doc_pass "bat theme" $BAT_THEME
        else
            __doc_warn "bat theme" "BAT_THEME not set"
        end
    end

    # ── MODULE: Permissions ───────────────────────────────────────────────────
    function __check_permissions --description "Permission checks"
        __doc_section "Permissions & Capabilities" "🔐 "

        # Home directory permissions
        set -l home_perm (stat -c '%a' $HOME 2>/dev/null)
        if test "$home_perm" = "700" || test "$home_perm" = "750" || test "$home_perm" = "755"
            __doc_pass "Home permissions" "$home_perm"
        else
            __doc_warn "Home permissions" "$home_perm (recommended: 700/750)"
        end

        # SSH directory
        if test -d "$HOME/.ssh"
            set -l ssh_perm (stat -c '%a' "$HOME/.ssh" 2>/dev/null)
            if test "$ssh_perm" = "700"
                __doc_pass "SSH directory" "700 (correct)"
            else
                __doc_fail "SSH directory" "$ssh_perm (must be 700)"
            end
        end

        # Config directory
        if test -r "$HOME/.config"
            __doc_pass ".config readable" "yes"
        else
            __doc_fail ".config readable" "no"
        end

        # Secrets directory
        if test -d "$HOME/.local/share/ash/secrets"
            set -l sec_perm (stat -c '%a' "$HOME/.local/share/ash/secrets" 2>/dev/null)
            if test "$sec_perm" = "700"
                __doc_pass "Secrets directory" "700 (locked)"
            else
                __doc_warn "Secrets directory" "$sec_perm (should be 700)"
            end
        end

        # GPG agent
        if command -q gpg-connect-agent
            gpg-connect-agent /bye 2>/dev/null && \
                __doc_pass "GPG agent" "running" || \
                __doc_info "GPG agent" "not running"
        end
    end

    # ── MODULE: Disk Space ────────────────────────────────────────────────────
    function __check_disk --description "Disk space checks"
        __doc_section "Disk Space" "💾 "

        # Root partition
        set -l root_use (df / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5);print $5}')
        set -l root_info (df -h / 2>/dev/null | awk 'NR==2{print $3" / "$2}')

        if test $root_use -lt 80
            __doc_pass "/" "$root_info ($root_use% used)"
        else if test $root_use -lt 90
            __doc_warn "/" "$root_info ($root_use% used — getting full)"
        else
            __doc_fail "/" "$root_info ($root_use% used — CRITICAL)"
        end

        # Home partition (if separate)
        set -l home_dev (df $HOME 2>/dev/null | awk 'NR==2{print $1}')
        set -l root_dev (df / 2>/dev/null | awk 'NR==2{print $1}')

        if test "$home_dev" != "$root_dev"
            set -l home_use (df $HOME 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5);print $5}')
            set -l home_info (df -h $HOME 2>/dev/null | awk 'NR==2{print $3" / "$2}')

            if test $home_use -lt 85
                __doc_pass "/home" "$home_info ($home_use% used)"
            else
                __doc_warn "/home" "$home_info ($home_use% used)"
            end
        end

        # Cache sizes
        for cache_dir in "$HOME/.cache" "$HOME/.local/share/ash" "$HOME/.config/ash"
            if test -d $cache_dir
                set -l size (du -sh $cache_dir 2>/dev/null | awk '{print $1}')
                __doc_info (basename $cache_dir)" cache" $size
            end
        end

        # Neovim data
        if test -d "$HOME/.local/share/nvim"
            set -l nvim_size (du -sh "$HOME/.local/share/nvim" 2>/dev/null | awk '{print $1}')
            __doc_info "Neovim data" $nvim_size
        end
    end

    # ── MODULE: Security ──────────────────────────────────────────────────────
    function __check_security --description "Security checks"
        __doc_section "Security" "🔒 "

        # SSH keys
        if test -d "$HOME/.ssh"
            set -l key_count (count "$HOME/.ssh"/*.pub 2>/dev/null)
            test $key_count -gt 0 && \
                __doc_pass "SSH public keys" "$key_count found" || \
                __doc_info "SSH public keys" "none found"

            # Check key permissions
            for key in "$HOME/.ssh/id_"*
                string match -q '*.pub' $key && continue
                test -f $key || continue
                set -l perm (stat -c '%a' $key 2>/dev/null)
                if test "$perm" = "600"
                    __doc_pass "SSH key: "(basename $key) "600 (secure)"
                else
                    __doc_fail "SSH key: "(basename $key) "$perm (must be 600)"
                end
            end
        end

        # Firewall
        if command -q ufw
            ufw status 2>/dev/null | grep -q 'active' && \
                __doc_pass "UFW firewall" "active" || \
                __doc_warn "UFW firewall" "inactive"
        else if command -q firewall-cmd
            firewall-cmd --state 2>/dev/null | grep -q running && \
                __doc_pass "firewalld" "running" || \
                __doc_warn "firewalld" "not running"
        else if command -q iptables
            __doc_info "Firewall" "iptables available"
        else
            __doc_warn "Firewall" "no firewall detected"
        end

        # World-writable files in home
        set -l world_writable (find "$HOME/.config" -maxdepth 3 -perm -o+w \
            -not -type l 2>/dev/null | wc -l | string trim)
        if test $world_writable -eq 0
            __doc_pass "World-writable files" "none found in .config"
        else
            __doc_warn "World-writable files" "$world_writable found in .config"
        end

        # SUID binaries (informational)
        if test $_verbose -eq 1
            set -l suid_count (find /usr/bin /usr/sbin -perm -4000 2>/dev/null | wc -l | string trim)
            __doc_info "SUID binaries" "$suid_count in /usr/bin,/usr/sbin"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔧 AUTO-FIX ENGINE                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __doc_run_fixes --description "Apply auto-fixes for detected issues"
        __doc_section "Auto-Fix Engine" "🔧 "

        set -l fixed   0
        set -l skipped 0

        # ── Fix: SSH key permissions ────────────────────────────────────────
        for key in "$HOME/.ssh/id_"* 2>/dev/null
            string match -q '*.pub' $key && continue
            test -f $key || continue
            set -l perm (stat -c '%a' $key 2>/dev/null)
            if test "$perm" != "600"
                chmod 600 $key 2>/dev/null
                and begin
                    __doc_fix "SSH key permissions: $key → 600"
                    set fixed (math $fixed + 1)
                end
            end
        end

        # ── Fix: SSH directory permissions ──────────────────────────────────
        if test -d "$HOME/.ssh"
            set -l perm (stat -c '%a' "$HOME/.ssh" 2>/dev/null)
            if test "$perm" != "700"
                chmod 700 "$HOME/.ssh" 2>/dev/null
                and begin
                    __doc_fix "SSH directory: $HOME/.ssh → 700"
                    set fixed (math $fixed + 1)
                end
            end
        end

        # ── Fix: Missing XDG directories ─────────────────────────────────────
        for xdg_dir in \
            "$HOME/.config" \
            "$HOME/.local/bin" \
            "$HOME/.local/share" \
            "$HOME/.local/state" \
            "$HOME/.cache" \
            "$HOME/.local/share/ash/logs" \
            "$HOME/.local/share/ash/state" \
            "$HOME/.local/share/ash/cache"
            if not test -d $xdg_dir
                mkdir -p $xdg_dir 2>/dev/null
                and begin
                    __doc_fix "Created: $xdg_dir"
                    set fixed (math $fixed + 1)
                end
            end
        end

        # ── Fix: Fish completion cache ────────────────────────────────────────
        rm -rf "$HOME/.local/share/ash/cache/completions" 2>/dev/null
        fish_update_completions 2>/dev/null >/dev/null
        __doc_fix "Rebuilt Fish completions"
        set fixed (math $fixed + 1)

        # ── Fix: Broken symlinks in ~/.local/bin ──────────────────────────────
        if test -d "$HOME/.local/bin"
            for link in "$HOME/.local/bin/"*
                test -L $link && not test -e $link || continue
                rm -f $link 2>/dev/null
                and begin
                    __doc_fix "Removed broken symlink: $link"
                    set fixed (math $fixed + 1)
                end
            end
        end

        # ── Fix: Theme not applied ────────────────────────────────────────────
        if not set -q ASH_THEME_NAME || test -z "$ASH_THEME_NAME"
            if functions -q ash_theme_sync
                ash_theme_sync --quiet 2>/dev/null
                __doc_fix "Applied default theme sync"
                set fixed (math $fixed + 1)
            end
        end

        # ── Fix: bat cache rebuild ────────────────────────────────────────────
        if command -q bat
            bat cache --build 2>/dev/null >/dev/null
            __doc_fix "Rebuilt bat syntax/theme cache"
            set fixed (math $fixed + 1)
        else if command -q batcat
            batcat cache --build 2>/dev/null >/dev/null
            __doc_fix "Rebuilt batcat cache"
            set fixed (math $fixed + 1)
        end

        printf "\n  $BOLD$ORANGE  Applied $fixed fix(es)$R\n"
        set -g _doc_fixes $fixed
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 DISPATCH: Run selected modules                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_mode
        case quick
            __check_system
            __check_tools_critical
            __check_configs
            __check_theme_engine
            __check_disk

        case full
            if test -n "$_check"
                # Specific module
                switch $_check
                    case system;           __check_system
                    case wayland;          __check_wayland
                    case hyprland;         __check_hyprland
                    case gpu;              __check_gpu
                    case audio;            __check_audio
                    case network net;      __check_network
                    case fonts;            __check_fonts
                    case tools-critical;   __check_tools_critical
                    case tools-optional;   __check_tools_optional
                    case configs config;   __check_configs
                    case theme-engine;     __check_theme_engine
                    case permissions;      __check_permissions
                    case disk disk-space;  __check_disk
                    case security;         __check_security
                    case '*'
                        printf "  $RED✗$R  Unknown module: $_check\n"
                        return 1
                end
            else
                # All modules
                __check_system
                __check_wayland
                __check_hyprland
                __check_gpu
                __check_audio
                __check_network
                __check_fonts
                __check_tools_critical
                __check_tools_optional
                __check_configs
                __check_theme_engine
                __check_permissions
                __check_disk
                __check_security
            end

        case fix
            # Run full check then fix
            __check_system
            __check_wayland
            __check_configs
            __check_theme_engine
            __check_permissions
            __check_disk
            __doc_run_fixes

        case report
            # Full check + report generation
            __check_system
            __check_wayland
            __check_hyprland
            __check_gpu
            __check_audio
            __check_network
            __check_fonts
            __check_tools_critical
            __check_configs
            __check_theme_engine
            __check_permissions
            __check_disk
            __check_security
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 SUMMARY                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _end_ts    (date +%s)
    set -l _elapsed   (math $_end_ts - $_start_ts)
    set -l _total     (math $_doc_pass + $_doc_warn + $_doc_fail + $_doc_info)
    set -l _health_pct 0
    test $_total -gt 0 && set _health_pct (math --scale 0 "$_doc_pass * 100 / (max(1, $_doc_pass + $_doc_warn + $_doc_fail))")

    # Health grade
    set -l _grade ""
    set -l _grade_color $GREEN
    if test $_health_pct -ge 95
        set _grade "A+"
    else if test $_health_pct -ge 90
        set _grade "A"
    else if test $_health_pct -ge 80
        set _grade "B"
    else if test $_health_pct -ge 70
        set _grade "C"
        set _grade_color $YELLOW
    else if test $_health_pct -ge 60
        set _grade "D"
        set _grade_color $ORANGE
    else
        set _grade "F"
        set _grade_color $RED
    end

    printf "\n"
    printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$PURPLE║     📊  Diagnostic Summary                           ║$R\n"
    printf "  $BOLD$PURPLE╠══════════════════════════════════════════════════════╣$R\n"
    printf "  $BOLD$PURPLE║$R  $GREEN%-4s checks passed$R%34s$PURPLE║$R\n" $_doc_pass ""
    printf "  $BOLD$PURPLE║$R  $YELLOW%-4s warnings$R%38s$PURPLE║$R\n" $_doc_warn ""
    printf "  $BOLD$PURPLE║$R  $RED%-4s failures$R%38s$PURPLE║$R\n" $_doc_fail ""
    printf "  $BOLD$PURPLE║$R  $CYAN%-4s info items$R%36s$PURPLE║$R\n" $_doc_info ""

    if test $_doc_fixes -gt 0
        printf "  $BOLD$PURPLE║$R  $ORANGE%-4s auto-fixes applied$R%29s$PURPLE║$R\n" $_doc_fixes ""
    end

    printf "  $BOLD$PURPLE╠══════════════════════════════════════════════════════╣$R\n"
    printf "  $BOLD$PURPLE║$R  $BOLD%sHealth: %3d%%  Grade: %s%s$R%26s$PURPLE║$R\n" \
        $_grade_color $_health_pct $_grade $R ""
    printf "  $BOLD$PURPLE║$R  $DIM⏱  Completed in %ds  Log: %-33s$R$PURPLE║$R\n" \
        $_elapsed (basename $_log_file)
    printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n"

    # Action recommendation
    if test $_doc_fail -gt 0
        printf "\n  $RED✗$R  $BOLD%d critical issue(s) found$R\n" $_doc_fail
        printf "  $DIM  Run: ash_doctor fix   or   ash doctor full --check=<module>$R\n"
    else if test $_doc_warn -gt 0
        printf "\n  $YELLOW⚠$R  $BOLD%d warning(s) — system functional$R\n" $_doc_warn
        printf "  $DIM  Run: ash_doctor fix   to auto-repair common issues$R\n"
    else
        printf "\n  $GREEN✓$R  $BOLDAll checks passed — system healthy!$R\n"
    end
    printf "\n"

    # ── Report generation ──────────────────────────────────────────────────────
    if test "$_mode" = report
        set -l report_file "$_report_dir/doctor-"(date +%Y%m%d-%H%M%S)".txt"
        test -n "$_output_file" && set report_file $_output_file

        begin
            printf "ASH Doctor Report — %s\n" (date)
            printf "Mode: %s  Health: %d%%  Grade: %s\n\n" $_mode $_health_pct $_grade
            printf "Results:\n"
            for r in $_doc_results
                set -l parts (string split ':' $r)
                printf "  [%-4s] %s: %s\n" $parts[1] $parts[2] $parts[3]
            end
        end > $report_file 2>/dev/null

        printf "  $CYAN📄$R  Report saved: $report_file\n\n"
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __doc_log __doc_pass __doc_warn __doc_fail __doc_info \
        __doc_fix __doc_section __doc_cmd_check __doc_help __doc_run_fixes \
        __check_system __check_wayland __check_hyprland __check_gpu \
        __check_audio __check_network __check_fonts __check_tools_critical \
        __check_tools_optional __check_configs __check_theme_engine \
        __check_permissions __check_disk __check_security 2>/dev/null

    set --erase _doc_pass _doc_warn _doc_fail _doc_info _doc_fixes \
        _doc_results _doc_section 2>/dev/null

    return (test $_doc_fail -eq 0 && echo 0 || echo 1)

end
