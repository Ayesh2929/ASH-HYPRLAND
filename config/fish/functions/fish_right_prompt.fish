# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fish_right_prompt Ultra                            ║
# ║  Right-side context: time, battery, exit code, cloud & ASH state           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function fish_right_prompt --description "ASH ultra right-side prompt"

    # ── Capture status immediately ─────────────────────────────────────────────
    set -l last_status $status

    # ── Skip if disabled ──────────────────────────────────────────────────────
    set -q ASH_NO_RIGHT_PROMPT && test "$ASH_NO_RIGHT_PROMPT" = 1 && return 0

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLOR RESOLUTION                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_c --description "Resolve color from ASH theme"
        set -l key "ASH_COLOR_"(string upper $argv[1])
        set -l fallback $argv[2]
        if set -q $key
            set_color (string replace '#' '' $$key) 2>/dev/null && return
        end
        set_color $fallback 2>/dev/null
    end

    set -l R     (set_color normal)
    set -l BOLD  (set_color --bold)
    set -l DIM   (set_color brblack)

    set -l COL_OK      (__rp_c green   green)
    set -l COL_ERR     (__rp_c red     red)
    set -l COL_WARN    (__rp_c yellow  yellow)
    set -l COL_TIME    (__rp_c subtext0 a6adc8)
    set -l COL_BAT_HI  (__rp_c green   green)
    set -l COL_BAT_MED (__rp_c yellow  yellow)
    set -l COL_BAT_LOW (__rp_c peach   FF9F43)
    set -l COL_BAT_CRT (__rp_c red     red)
    set -l COL_CLOUD   (__rp_c sky     89dceb)
    set -l COL_KUBE    (__rp_c blue    blue)
    set -l COL_AWS     (__rp_c peach   FF9F43)
    set -l COL_GCP     (__rp_c blue    4285F4)
    set -l COL_AZ      (__rp_c blue    0078D4)
    set -l COL_THEME   (__rp_c lavender b4befe)
    set -l COL_VPN     (__rp_c green   green)
    set -l COL_PRIV    (__rp_c red     red)
    set -l COL_MEM     (__rp_c teal    94e2d5)
    set -l COL_JOBS    (__rp_c yellow  yellow)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📦 RIGHT SEGMENTS COLLECTION                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l rp_parts

    # ── Helper: add segment to right prompt ────────────────────────────────────
    function __rp_seg --description "Add right segment"
        set -g __rp_part "$argv"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ✅ SEGMENT: Exit status (errors only)                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $last_status -ne 0
        # Map common exit codes to meanings
        set -l code_msg ""
        switch $last_status
            case 1;   set code_msg "error"
            case 2;   set code_msg "misuse"
            case 126; set code_msg "no permission"
            case 127; set code_msg "not found"
            case 128; set code_msg "invalid exit"
            case 129; set code_msg "SIGHUP"
            case 130; set code_msg "SIGINT"
            case 131; set code_msg "SIGQUIT"
            case 137; set code_msg "SIGKILL"
            case 141; set code_msg "SIGPIPE"
            case 143; set code_msg "SIGTERM"
            case 255; set code_msg "exit overflow"
        end

        if test -n "$code_msg"
            set --append rp_parts $COL_ERR"✗ $last_status ($code_msg)"$R
        else
            set --append rp_parts $COL_ERR"✗ $last_status"$R
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  💾 SEGMENT: Memory pressure (only when high)                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_memory --description "Memory pressure indicator"
        test -f /proc/meminfo || return

        set -l total (awk '/^MemTotal/{print $2}'    /proc/meminfo)
        set -l avail (awk '/^MemAvailable/{print $2}' /proc/meminfo)
        set -l pct   (math --scale 0 "(($total - $avail) * 100) / $total")

        # Only show if > 80%
        test $pct -le 80 && return

        set -l used_gb (math --scale 1 "($total - $avail) / 1048576")

        set -l mem_color $COL_WARN
        test $pct -gt 90 && set mem_color $COL_ERR

        echo "$mem_color  $used_gb GiB ($pct%)$R"
    end

    set -l _mem_seg (__rp_memory)
    test -n "$_mem_seg" && set --append rp_parts $_mem_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔋 SEGMENT: Battery                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_battery --description "Battery status segment"
        # Linux: /sys/class/power_supply
        set -l bat_dir /sys/class/power_supply

        if test -d $bat_dir
            # Find first battery
            set -l bat_path ""
            for d in $bat_dir/BAT* $bat_dir/battery $bat_dir/AC*
                if test -f "$d/capacity"
                    set bat_path $d
                    break
                end
            end

            test -z "$bat_path" && return

            set -l capacity (cat "$bat_path/capacity" 2>/dev/null; or echo 0)
            set -l status   (cat "$bat_path/status"   2>/dev/null; or echo Unknown)

            # Only show when not charging at high levels
            if test "$status" = Charging && test $capacity -gt 80
                return
            end

            # Choose icon based on level + charging state
            set -l bat_icon
            set -l bat_color

            if test "$status" = Charging
                set bat_icon ""
                set bat_color $COL_BAT_HI
            else if test $capacity -gt 80
                set bat_icon ""
                set bat_color $COL_BAT_HI
            else if test $capacity -gt 50
                set bat_icon ""
                set bat_color $COL_BAT_HI
            else if test $capacity -gt 30
                set bat_icon ""
                set bat_color $COL_BAT_MED
            else if test $capacity -gt 15
                set bat_icon ""
                set bat_color $COL_BAT_LOW
            else if test $capacity -gt 5
                set bat_icon ""
                set bat_color $COL_BAT_CRT
            else
                set bat_icon ""
                set bat_color $COL_BAT_CRT
            end

            echo "$bat_color$bat_icon $capacity%$R"
            return
        end

        # macOS
        if command -q pmset
            set -l bat_info (pmset -g batt 2>/dev/null)
            set -l pct (echo $bat_info | grep -oP '\d+(?=%)' | head -1)
            set -l chg (echo $bat_info | grep -q "charging" && echo "⚡" || echo "")

            test -z "$pct" && return

            set -l bat_color $COL_BAT_HI
            test $pct -lt 30 && set bat_color $COL_BAT_MED
            test $pct -lt 15 && set bat_color $COL_BAT_LOW
            test $pct -lt 5  && set bat_color $COL_BAT_CRT

            echo "$bat_color  $pct%$chg$R"
        end
    end

    set -l _bat_seg (__rp_battery)
    test -n "$_bat_seg" && set --append rp_parts $_bat_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔒 SEGMENT: VPN / Privacy mode                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_vpn --description "VPN status segment"
        # Check for common VPN interfaces
        for iface in tun0 tun1 wg0 wg1 vpn0 proton nordlynx tailscale0
            if test -d "/sys/class/net/$iface"
                echo "$COL_VPN VPN$R"
                return
            end
        end

        # Check for ASH privacy mode
        set -l state "$HOME/.local/share/ash/state/current-mode.json"
        if test -f $state && command -q jq
            set -l mode (jq -r '.mode // empty' $state 2>/dev/null)
            test "$mode" = privacy && echo "$COL_PRIV  private$R"
        end
    end

    set -l _vpn_seg (__rp_vpn)
    test -n "$_vpn_seg" && set --append rp_parts $_vpn_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ☁️  SEGMENT: Cloud context                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_cloud --description "Active cloud provider context"
        set -l cloud_parts

        # AWS Profile
        if set -q AWS_PROFILE && test -n "$AWS_PROFILE"
            set --append cloud_parts $COL_AWS"  $AWS_PROFILE"$R
        end

        # GCP Project
        if set -q CLOUDSDK_CORE_PROJECT && test -n "$CLOUDSDK_CORE_PROJECT"
            set --append cloud_parts $COL_GCP"  $CLOUDSDK_CORE_PROJECT"$R
        else if set -q GOOGLE_CLOUD_PROJECT && test -n "$GOOGLE_CLOUD_PROJECT"
            set --append cloud_parts $COL_GCP"  $GOOGLE_CLOUD_PROJECT"$R
        end

        # Azure Subscription (abbreviated)
        if set -q AZURE_DEFAULTS_GROUP && test -n "$AZURE_DEFAULTS_GROUP"
            set --append cloud_parts $COL_AZ"  $AZURE_DEFAULTS_GROUP"$R
        end

        test (count $cloud_parts) -gt 0 && string join " " $cloud_parts
    end

    set -l _cloud_seg (__rp_cloud)
    test -n "$_cloud_seg" && set --append rp_parts $_cloud_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ☸️  SEGMENT: Kubernetes (right side, compact)                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_kube --description "Kubernetes context (right prompt)"
        set -q SHOW_KUBE || return
        command -q kubectl || return

        set -l ctx (kubectl config current-context 2>/dev/null)
        test -z "$ctx" && return

        # Truncate long context names
        set -l short_ctx (string sub --length 20 $ctx)
        test (string length $ctx) -gt 20 && set short_ctx "$short_ctx…"

        echo "$COL_KUBE  $short_ctx$R"
    end

    set -l _kube_seg (__rp_kube)
    test -n "$_kube_seg" && set --append rp_parts $_kube_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 SEGMENT: Current ASH theme (compact)                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_theme --description "ASH theme indicator"
        set -q ASH_SHOW_THEME || return
        set -q ASH_THEME_NAME || return

        set -l short_name (string replace -r '-.*' '' $ASH_THEME_NAME)
        echo "$COL_THEME  $short_name$R"
    end

    set -l _theme_seg (__rp_theme)
    test -n "$_theme_seg" && set --append rp_parts $_theme_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⚙️  SEGMENT: Background jobs (right side)                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _jobs (jobs | wc -l | string trim)
    if test "$_jobs" -gt 0
        set --append rp_parts $COL_JOBS"  $_jobs"$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🕐 SEGMENT: Time (always last)                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rp_time --description "Current time segment"
        set -l fmt ""
        switch (set -q ASH_TIME_FORMAT && echo $ASH_TIME_FORMAT || echo 24h)
            case 12h
                set fmt '%I:%M:%S %p'
            case full
                set fmt '%H:%M:%S'
            case date
                set fmt '%Y-%m-%d %H:%M'
            case '*'
                set fmt '%H:%M:%S'
        end
        date +"$fmt"
    end

    set --append rp_parts $DIM(__rp_time)$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  RENDER RIGHT PROMPT                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l separator $DIM" ❙ "$R
    set -q ASH_PROMPT_SEPARATOR && set separator $ASH_PROMPT_SEPARATOR

    test (count $rp_parts) -gt 0 && \
        printf "%s " (string join $separator $rp_parts)

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __rp_c __rp_seg __rp_memory __rp_battery \
        __rp_vpn __rp_cloud __rp_kube __rp_theme __rp_time 2>/dev/null

end
