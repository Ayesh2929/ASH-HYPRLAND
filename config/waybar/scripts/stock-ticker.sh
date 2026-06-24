#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Stock Ticker                      ║
# ║                                                                              ║
# ║  Real-time stock/crypto prices via Yahoo Finance API.                      ║
# ║  Customize TICKERS array with your symbols.                                 ║
# ║  Cache: 5 minutes (respects API rate limits).                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
readonly TICKERS=(
    "AAPL"      # Apple
    "GOOGL"     # Google/Alphabet
    "BTC-USD"   # Bitcoin
    # "ETH-USD" # Ethereum
    # "MSFT"    # Microsoft
    # "NVDA"    # NVIDIA
    # "SPY"     # S&P 500 ETF
)
readonly MAX_DISPLAY=3              # Symbols to show in bar (rest in tooltip)
readonly CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/ash-dotfiles/stocks.json"
readonly CACHE_AGE=300              # 5 minutes
readonly TIMEOUT=8

# ── Cache check ────────────────────────────────────────────────────────────────
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [[ $age -lt $CACHE_AGE ]]
}

# ── Connectivity check ─────────────────────────────────────────────────────────
if ! ping -c1 -W2 finance.yahoo.com &>/dev/null 2>&1; then
    echo '{"text":"󱎫 offline","tooltip":"Stock data: no internet","class":"offline"}'
    exit 0
fi

mkdir -p "$(dirname "$CACHE_FILE")"

# ── Fetch prices ───────────────────────────────────────────────────────────────
fetch_price() {
    local ticker="$1"
    local DATA
    DATA=$(curl -sf --max-time "$TIMEOUT" \
        "https://query1.finance.yahoo.com/v8/finance/chart/${ticker}?interval=1d&range=1d" \
        2>/dev/null) || return 1

    local PRICE PCT
    PRICE=$(echo "$DATA" | jq -r '.chart.result[0].meta.regularMarketPrice'         2>/dev/null || echo "?")
    PCT=$(  echo "$DATA" | jq -r '.chart.result[0].meta.regularMarketChangePercent' 2>/dev/null || echo "0")

    echo "${PRICE}|${PCT}"
}

# ── Build output ───────────────────────────────────────────────────────────────
TEXT=""
TOOLTIP="Stock Prices ($(date '+%H:%M'))\n\n"
ALL_DATA=()

for TICKER in "${TICKERS[@]}"; do
    RESULT=$(fetch_price "$TICKER" 2>/dev/null || echo "?|0")
    IFS='|' read -r PRICE PCT <<< "$RESULT"

    # Format values
    PRICE_FMT=$(printf "%.2f" "${PRICE:-0}" 2>/dev/null || echo "?")
    PCT_FMT=$( printf "%.2f" "${PCT:-0}"   2>/dev/null || echo "0")

    # Color + arrow
    if (( $(echo "${PCT_FMT} >= 0" | bc -l 2>/dev/null || echo 0) )); then
        COLOR="#a6e3a1"
        ARROW="▲"
        CSS_ARROW="up"
    else
        COLOR="#f38ba8"
        ARROW="▼"
        CSS_ARROW="down"
    fi

    ALL_DATA+=("${TICKER}|${PRICE_FMT}|${PCT_FMT}|${COLOR}|${ARROW}|${CSS_ARROW}")
    TOOLTIP+="${TICKER}: \$${PRICE_FMT} ${ARROW}${PCT_FMT}%\n"
done

# Build bar text (max MAX_DISPLAY tickers)
IDX=0
for ENTRY in "${ALL_DATA[@]}"; do
    [[ $IDX -ge $MAX_DISPLAY ]] && break
    IFS='|' read -r T PR PC COLOR ARROW CSS_A <<< "$ENTRY"
    TEXT+="<span color='${COLOR}'>${T} ${ARROW}${PC}%</span>  "
    (( IDX++ )) || true
done
TEXT="${TEXT%  }"  # Strip trailing spaces

TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')
TEXT=$(echo "$TEXT" | sed 's/"/\\"/g')

printf '{"text":"%s","tooltip":"%s","class":"stocks"}\n' "$TEXT" "$TOOLTIP"