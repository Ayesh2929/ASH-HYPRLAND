#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: System Load Average               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Read load averages
read L1 L5 L15 PROCS_RUN PROCS_TOTAL _ < /proc/loadavg

CORES=$(nproc 2>/dev/null || echo 1)
NORM=$(awk "BEGIN {printf \"%.0f\", ($L1/$CORES)*100}")
NORM="${NORM:-0}"

# State class
CSS="good"
[[ "$NORM" -ge 70 ]] && CSS="warning"
[[ "$NORM" -ge 90 ]] && CSS="critical"
[[ "$NORM" -ge 100 ]] && CSS="overloaded"

# Running/waiting processes
RUNNING="${PROCS_RUN%%/*}"
TOTAL="${PROCS_TOTAL:-?}"

TOOLTIP="System Load\n\n"
TOOLTIP+="1 min:  ${L1} (${NORM}% of ${CORES} cores)\n"
TOOLTIP+="5 min:  ${L5}\n"
TOOLTIP+="15 min: ${L15}\n\n"
TOOLTIP+="Running: ${RUNNING} / ${TOTAL} processes\n"
TOOLTIP+="Cores:   ${CORES}"

TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
    "$L1" "$TOOLTIP" "$CSS" "$NORM"