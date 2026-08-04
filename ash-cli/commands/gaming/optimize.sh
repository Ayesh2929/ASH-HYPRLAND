#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  gaming optimize                                          ║
# ║  System-wide gaming optimizations: CPU governor • IRQ affinity • kernel params   ║
# ║  GPU power modes • compositor tweaks • network latency • swap reduction          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_GAMING_OPTIMIZE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_GAMING_OPTIMIZE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  OPTIMIZATION STATE SAVE/RESTORE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _OPT_SNAPSHOT="${_GM_STATE_DIR}/pre-gaming-snapshot.conf"

_opt_save_snapshot() {
    gm_step "Saving current system state..."
    {
        printf '# ASH Gaming Pre-snapshot — %s\n' "$(date -Iseconds)"
        printf 'cpu_governor=%s\n' \
            "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'unknown')"
        printf 'swappiness=%s\n' \
            "$(cat /proc/sys/vm/swappiness 2>/dev/null || echo '60')"
        printf 'transparent_hugepage=%s\n' \
            "$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | \
               grep -oP '\[\K[^\]]+')"
        printf 'irq_balance=%s\n' \
            "$(systemctl is-active irqbalance 2>/dev/null || echo 'unknown')"
        printf 'nmi_watchdog=%s\n' \
            "$(cat /proc/sys/kernel/nmi_watchdog 2>/dev/null || echo '1')"
        printf 'compaction_proactiveness=%s\n' \
            "$(cat /proc/sys/vm/compaction_proactiveness 2>/dev/null || echo '20')"
    } > "$_OPT_SNAPSHOT"
    gm_ok "Snapshot saved: ${_OPT_SNAPSHOT}"
}

_opt_restore_snapshot() {
    if [[ ! -f "$_OPT_SNAPSHOT" ]]; then
        gm_warn "No snapshot found — using safe defaults"
        # Safe defaults
        printf 'schedutil\n' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor &>/dev/null || true
        echo 60 | sudo tee /proc/sys/vm/swappiness &>/dev/null || true
        return 0
    fi

    gm_step "Restoring pre-gaming system state..."

    local cpu_gov swappiness thp irq_bal nmi watchdog
    cpu_gov="$(  grep '^cpu_governor=' "$_OPT_SNAPSHOT" | cut -d= -f2)"
    swappiness="$(grep '^swappiness='  "$_OPT_SNAPSHOT" | cut -d= -f2)"
    thp="$(       grep '^transparent_hugepage=' "$_OPT_SNAPSHOT" | cut -d= -f2)"
    irq_bal="$(   grep '^irq_balance=' "$_OPT_SNAPSHOT" | cut -d= -f2)"
    nmi="$(        grep '^nmi_watchdog=' "$_OPT_SNAPSHOT" | cut -d= -f2)"

    [[ -n "$cpu_gov" ]] && \
        echo "$cpu_gov" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor \
        &>/dev/null && gm_ok "CPU governor → ${cpu_gov}"

    [[ -n "$swappiness" ]] && \
        echo "$swappiness" | sudo tee /proc/sys/vm/swappiness &>/dev/null && \
        gm_ok "Swappiness → ${swappiness}"

    [[ "$irq_bal" == "active" ]] && \
        sudo systemctl start irqbalance 2>/dev/null && gm_ok "irqbalance → started"

    [[ -n "$nmi" ]] && \
        echo "$nmi" | sudo tee /proc/sys/kernel/nmi_watchdog &>/dev/null || true

    rm -f "$_OPT_SNAPSHOT"
    gm_ok "System state restored"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  OPTIMIZATION STEPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_opt_cpu_performance() {
    gm_step "Setting CPU governor → performance..."
    local cpu_count
    cpu_count="$(nproc --all 2>/dev/null || echo 4)"

    if echo performance | sudo tee \
        /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor \
        &>/dev/null 2>&1; then
        gm_ok "CPU governor: performance  (${cpu_count} cores)"
    else
        # Try via powerprofilesctl
        if command -v powerprofilesctl &>/dev/null; then
            powerprofilesctl set performance 2>/dev/null && \
                gm_ok "Power profile: performance"
        else
            gm_warn "Cannot set CPU governor (no sudo / driver mismatch)"
        fi
    fi

    # Disable CPU frequency scaling limit (Intel only)
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo &>/dev/null && \
            gm_ok "Intel Turbo Boost: enabled"
    fi
}

_opt_memory_tuning() {
    gm_step "Optimizing memory parameters..."

    # Reduce swappiness for gaming (keep more in RAM)
    echo 10 | sudo tee /proc/sys/vm/swappiness &>/dev/null && \
        gm_ok "vm.swappiness → 10  (RAM preferred)"

    # Disable THP compaction (reduces latency spikes)
    if [[ -f /sys/kernel/mm/transparent_hugepage/defrag ]]; then
        echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag \
            &>/dev/null && gm_ok "THP defrag: disabled  (reduces stutter)"
    fi

    # Increase VFS cache pressure
    echo 50 | sudo tee /proc/sys/vm/vfs_cache_pressure &>/dev/null && \
        gm_ok "VFS cache pressure → 50"

    # Disable compaction proactiveness
    if [[ -f /proc/sys/vm/compaction_proactiveness ]]; then
        echo 0 | sudo tee /proc/sys/vm/compaction_proactiveness &>/dev/null && \
            gm_ok "Compaction proactiveness → 0"
    fi
}

_opt_network_latency() {
    gm_step "Reducing network latency..."

    # TCP low latency mode
    echo 1 | sudo tee /proc/sys/net/ipv4/tcp_low_latency &>/dev/null && \
        gm_ok "TCP low latency: enabled"

    # Increase socket buffer sizes
    echo 134217728 | sudo tee /proc/sys/net/core/rmem_max &>/dev/null || true
    echo 134217728 | sudo tee /proc/sys/net/core/wmem_max &>/dev/null && \
        gm_ok "Socket buffers: increased  (128MB)"

    # TCP ACK optimisation
    echo 1 | sudo tee /proc/sys/net/ipv4/tcp_fastopen &>/dev/null && \
        gm_ok "TCP Fast Open: enabled"
}

_opt_irq_affinity() {
    gm_step "Optimizing IRQ affinity..."

    # Stop irqbalance (let gaming apps control CPU affinity)
    if systemctl is-active irqbalance &>/dev/null 2>&1; then
        sudo systemctl stop irqbalance 2>/dev/null && \
            gm_ok "irqbalance: stopped  (manual IRQ control)"
    fi

    # Disable NMI watchdog (reduces latency interrupts)
    echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog &>/dev/null && \
        gm_ok "NMI watchdog: disabled"

    # Set watchdog to soft only
    echo 2 | sudo tee /proc/sys/kernel/watchdog &>/dev/null 2>&1 || true
}

_opt_gpu_performance() {
    gm_step "Setting GPU to max performance mode..."

    local gpu_found=0

    # NVIDIA
    if command -v nvidia-smi &>/dev/null && \
       nvidia-smi --query-gpu=name --format=csv,noheader &>/dev/null 2>&1; then
        nvidia-smi --persistence-mode=ENABLE &>/dev/null || true
        nvidia-smi --auto-boost-default=DISABLE &>/dev/null || true
        nvidia-smi --performance-levels=P0 &>/dev/null || true
        gm_ok "NVIDIA: persistence mode + P0 performance state"
        gpu_found=1
    fi

    # AMD
    for card_dir in /sys/class/drm/card*/device/; do
        local vendor
        vendor="$(cat "${card_dir}vendor" 2>/dev/null || echo '')"
        if [[ "$vendor" == "0x1002" ]]; then
            local dpm_file="${card_dir}power_dpm_force_performance_level"
            if [[ -w "$dpm_file" ]]; then
                echo high | sudo tee "$dpm_file" &>/dev/null && \
                    gm_ok "AMD GPU: DPM → high performance"
                gpu_found=1
            fi
        fi
    done

    # Intel
    if [[ -d /sys/class/drm/card0/gt_max_freq_mhz ]]; then
        gm_info "Intel iGPU: frequency managed by governor"
        gpu_found=1
    fi

    (( gpu_found == 0 )) && gm_warn "No supported GPU found for performance tuning"
}

_opt_compositor_hints() {
    gm_step "Applying Hyprland gaming hints..."

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && \
       command -v hyprctl &>/dev/null; then
        # VRR (FreeSync/G-Sync)
        hyprctl keyword misc:vrr 1 &>/dev/null && \
            gm_ok "VRR (FreeSync/G-Sync): enabled"

        # Disable animations for max performance
        hyprctl keyword animations:enabled 0 &>/dev/null && \
            gm_ok "Compositor animations: disabled"

        # Set maximum framerate policy
        hyprctl keyword misc:no_vfr false &>/dev/null || true

        gm_info "To restore: ash gaming optimize off"
    else
        gm_info "Hyprland not running — skipping compositor hints"
    fi
}

_opt_restore_compositor() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && \
       command -v hyprctl &>/dev/null; then
        hyprctl keyword animations:enabled 1 &>/dev/null && \
            gm_ok "Compositor animations: restored"
        hyprctl keyword misc:vrr 0 &>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROGRESS ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_opt_boot_animation() {
    local mode="$1"  # on | off
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        if [[ "$mode" == "on" ]]; then
            local -a frames=( '🎮' '🎮' '⚡' '⚡' '🚀' '🚀' '🎯' )
            local msg="Activating gaming mode"
        else
            local -a frames=( '🎯' '🚀' '⚡' '🎮' '💤' )
            local msg="Restoring normal mode"
        fi

        printf '\n'
        for frame in "${frames[@]}"; do
            printf '\r  %s  %s%s%s...' \
                "$frame" "$(_gpeach)$(_gbold)" "$msg" "$(_gr)"
            sleep 0.12
        done
        printf '\r  %-60s\n\n' ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_gaming_optimize() {
    local action="on"
    local skip_cpu=0  skip_mem=0  skip_net=0  skip_irq=0
    local skip_gpu=0  skip_compositor=0

    for arg in "${@:-}"; do
        case "$arg" in
            on|enable|start)    action="on"   ;;
            off|disable|stop)   action="off"  ;;
            --no-cpu)           skip_cpu=1    ;;
            --no-mem)           skip_mem=1    ;;
            --no-net)           skip_net=1    ;;
            --no-irq)           skip_irq=1    ;;
            --no-gpu)           skip_gpu=1    ;;
            --no-compositor)    skip_compositor=1 ;;
        esac
    done

    if [[ "$action" == "on" ]]; then
        gm_section "⚡" "Gaming Optimization — ON" "$(_gpeach)"

        # Check if already active
        if [[ -f "$_GM_ACTIVE_FILE" ]]; then
            local current_mode
            current_mode="$(cat "$_GM_ACTIVE_FILE" 2>/dev/null)"
            gm_warn "Gaming mode already active: ${current_mode}"
            gm_info "Run: ash gaming optimize off  to restore first"
        fi

        _opt_boot_animation "on"
        _opt_save_snapshot

        printf '\n'
        gm_section "🔧" "Applying Optimizations" "$(_gdim)"

        [[ $skip_cpu -eq 0 ]]        && _opt_cpu_performance
        [[ $skip_mem -eq 0 ]]        && _opt_memory_tuning
        [[ $skip_net -eq 0 ]]        && _opt_network_latency
        [[ $skip_irq -eq 0 ]]        && _opt_irq_affinity
        [[ $skip_gpu -eq 0 ]]        && _opt_gpu_performance
        [[ $skip_compositor -eq 0 ]] && _opt_compositor_hints

        # Mark active
        printf 'gaming\n' > "$_GM_ACTIVE_FILE"
        gm_log "optimize-on" "ok"

        printf '\n'
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
            printf '\033[1;38;2;250;179;135m'
            printf '  ╔══════════════════════════════════════════════════════════╗\n'
            printf '  ║  🎮  GAMING MODE ACTIVE  ─  System optimized for gaming  ║\n'
            printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
        else
            gm_ok "GAMING MODE ACTIVE"
        fi

        gm_notify "🎮 Gaming Mode" "System optimized for gaming performance" "critical"

    else
        gm_section "💤" "Gaming Optimization — OFF" "$(_gdim)"
        _opt_boot_animation "off"

        _opt_restore_snapshot
        _opt_restore_compositor

        rm -f "$_GM_ACTIVE_FILE"
        gm_log "optimize-off" "ok"

        gm_ok "Normal system mode restored"
        gm_notify "💤 Gaming Mode Off" "System restored to normal settings"
    fi

    printf '\n'
}
