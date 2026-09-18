#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar: Intel GPU usage                           ║
# ║  Reads the i915 rc6 residency (no root, no intel_gpu_top needed) and falls   ║
# ║  back to intel_gpu_top when the kernel exposes it.                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Output: {"text":"…","class":"gpu-intel","tooltip":"…"}  — return-type json
set -euo pipefail

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

usage=""
render="/sys/class/drm/renderD128"
if [[ -d "$render" ]]; then
    for dev in "$render"/device; do
        [[ -d "$dev" ]] || continue
        busy_file="$dev/gt_cur_freq_mhz"
        max_file="$dev/gt_max_freq_mhz"
        if [[ -r "$busy_file" && -r "$max_file" ]]; then
            cur="$(cat "$busy_file" 2>/dev/null || echo 0)"
            max="$(cat "$max_file" 2>/dev/null || echo 0)"
            if [[ "$max" =~ ^[0-9]+$ ]] && (( max > 0 )); then
                usage=$(( cur * 100 / max ))
            fi
        fi
        break
    done
fi

if [[ -z "$usage" ]] && command -v intel_gpu_top >/dev/null 2>&1; then
    usage="$(timeout 2 intel_gpu_top -J -s 1000 2>/dev/null \
        | awk -F'[:,]' '/"Render\\/3D"/{getline; gsub(/[^0-9.]/,"",$2); if ($2+0>0) {printf "%d", $2+0; exit}}' || true)"
fi

if [[ -n "${usage:-}" && "$usage" =~ ^[0-9]+$ ]]; then
    class="gpu-intel"
    (( usage >= 85 )) && class="gpu-intel critical"
    (( usage >= 50 && usage < 85 )) && class="gpu-intel warning"
    text="Intel ${usage}%"
    tip="Intel iGPU  •  render load ${usage}%"
else
    class="gpu-intel"
    text="Intel n/a"
    tip="Intel GPU telemetry unavailable (kernel i915 counters not exposed)"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$(json_escape "$text")" "$class" "$(json_escape "$tip")"
