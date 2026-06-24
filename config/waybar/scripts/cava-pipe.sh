#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: CAVA Audio Visualizer Pipe       ║
# ║                                                                              ║
# ║  Runs CAVA in raw ASCII mode and translates output to block characters     ║
# ║  for Waybar display. Only active during media playback.                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
readonly BARS=8
readonly CAVA_CFG_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-cava-waybar.cfg"
readonly BAR_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
readonly IDLE_CHAR="─"

# ── Check cava is available ────────────────────────────────────────────────────
if ! command -v cava &>/dev/null; then
    echo '{"text":"","class":"unavailable"}'
    exit 0
fi

# ── Generate CAVA config ───────────────────────────────────────────────────────
cat > "$CAVA_CFG_FILE" << CAVACFG
[general]
bars = ${BARS}
bar_height = 7
sleep_timer = 1

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
CAVACFG

# ── Cleanup ────────────────────────────────────────────────────────────────────
cleanup() {
    rm -f "$CAVA_CFG_FILE"
    pkill -f "cava -p $CAVA_CFG_FILE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ── Run CAVA and stream Waybar JSON ───────────────────────────────────────────
cava -p "$CAVA_CFG_FILE" 2>/dev/null | while IFS=';' read -ra VALUES; do
    # Check if music is playing
    if ! playerctl status 2>/dev/null | grep -q "Playing"; then
        printf '{"text":"%s","class":"idle"}\n' "${IDLE_CHAR:0:1} ${IDLE_CHAR:0:1} ${IDLE_CHAR:0:1} ${IDLE_CHAR:0:1}"
        sleep 2
        continue
    fi

    DISPLAY=""
    for VAL in "${VALUES[@]}"; do
        [[ -z "$VAL" ]] && continue
        VAL="${VAL// /}"
        [[ ! "$VAL" =~ ^[0-9]+$ ]] && continue
        IDX=$(( VAL > 7 ? 7 : VAL < 0 ? 0 : VAL ))
        DISPLAY+="${BAR_CHARS[$IDX]}"
    done

    [[ -n "$DISPLAY" ]] && \
        printf '{"text":"%s","class":"playing","tooltip":"Audio Visualizer"}\n' "$DISPLAY"
done