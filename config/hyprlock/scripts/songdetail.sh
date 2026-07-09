#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HYPRLOCK SCRIPT: SONGDETAIL                     ║
# ║  MPRIS2 media intelligence engine — art, lyrics, waveform, multi-player    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  DESCRIPTION                                                                 │
# │  Full-featured MPRIS2 now-playing data provider for hyprlock widgets.       │
# │  Reads from playerctl, processes album art, calculates progress,            │
# │  formats output for every music widget variant in the ASH widget system.   │
# │                                                                              │
# │  USAGE                                                                       │
# │    songdetail.sh                    Full one-line summary (default)         │
# │    songdetail.sh --title            Track title only                        │
# │    songdetail.sh --artist           Artist name only                        │
# │    songdetail.sh --album            Album name only                         │
# │    songdetail.sh --artist-album     "Artist  ·  Album" combined             │
# │    songdetail.sh --player           Player icon + name                      │
# │    songdetail.sh --progress         Unicode bar + timestamps                │
# │    songdetail.sh --pct              Integer percentage (0–100)              │
# │    songdetail.sh --time             "2:34 / 4:12" timestamp pair            │
# │    songdetail.sh --art              Resolve art → cache path + download     │
# │    songdetail.sh --art-path         Output cached art path (no download)   │
# │    songdetail.sh --status           "playing" / "paused" / "stopped"        │
# │    songdetail.sh --compact          Artist — Title + mini progress          │
# │    songdetail.sh --paused           Output only when paused                 │
# │    songdetail.sh --short            Truncated "Artist — Title" (28 chars)  │
# │    songdetail.sh --waveform         Animated unicode spectrum bars          │
# │    songdetail.sh --lyric            Current lyric line (requires LRC file)  │
# │                                                                              │
# │  DEPENDENCIES                                                                │
# │    Required: playerctl                                                       │
# │    Optional: curl (art download from URL) • ffmpeg (art extraction)         │
# │              python3 (color sampling) • convert (ImageMagick resize)        │
# │                                                                              │
# │  CACHE LOCATIONS                                                             │
# │    Art cache:    ~/.cache/hyprlock/album-art/current.png                   │
# │    Art index:    ~/.cache/hyprlock/album-art/index.json                    │
# │    Lyric cache:  ~/.cache/hyprlock/lyrics/<artist>-<title>.lrc             │
# │    State cache:  ~/.cache/hyprlock/player-state.json                       │
# └─────────────────────────────────────────────────────────────────────────────┘

set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 01 — CONFIGURATION & CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_NAME="songdetail"
readonly SCRIPT_VERSION="5.0.0"

# ── Cache directories ─────────────────────────────────────────────────────────
readonly CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock"
readonly ART_CACHE_DIR="${CACHE_ROOT}/album-art"
readonly ART_CACHE_FILE="${ART_CACHE_DIR}/current.png"
readonly ART_INDEX_FILE="${ART_CACHE_DIR}/index.json"
readonly LYRIC_CACHE_DIR="${CACHE_ROOT}/lyrics"
readonly STATE_CACHE_FILE="${CACHE_ROOT}/player-state.json"
readonly FALLBACK_ART="${XDG_CONFIG_HOME:-$HOME/.config}/ash/assets/music-fallback.png"

# ── Display configuration ─────────────────────────────────────────────────────
# Title truncation: chars before appending "…"
readonly TITLE_MAX_LEN=36
# Artist truncation
readonly ARTIST_MAX_LEN=24
# Album truncation
readonly ALBUM_MAX_LEN=22
# Short mode total length (--short / ticker use)
readonly SHORT_MAX_LEN=48
# Progress bar width in block characters
readonly PROGRESS_BAR_WIDTH=16
# Compact mode bar width
readonly COMPACT_BAR_WIDTH=10
# Waveform bar count
readonly WAVEFORM_BARS=14

# ── Player priority order ─────────────────────────────────────────────────────
# When multiple MPRIS players active, preference order for "active" selection.
# First match in list = selected player.
readonly -a PLAYER_PRIORITY=(
    "spotify"
    "strawberry"
    "clementine"
    "rhythmbox"
    "cantata"
    "mpd"
    "vlc"
    "firefox"
    "chromium"
    "brave"
    "chromium-browser"
)

# ── Player icon map ───────────────────────────────────────────────────────────
# Nerd Font glyphs for each player. Fallback: 󰎈 (generic music note)
declare -A PLAYER_ICONS=(
    [spotify]="󰓇"
    [strawberry]="󰓀"
    [clementine]="󰋊"
    [rhythmbox]="󰑈"
    [cantata]="󰌳"
    [mpd]="󰍚"
    [ncmpcpp]="󰍚"
    [vlc]="󰕼"
    [firefox]="󰖟"
    [chromium]="󰊯"
    [brave]="󰖟"
    [youtube-music]="󰨾"
    [tidal]="󱍸"
    [deezer]="󰎈"
    [apple-music]="󰎈"
)

# ── Unicode progress fill characters ─────────────────────────────────────────
readonly BLOCK_FULL="█"
readonly BLOCK_EMPTY="░"

# ── Waveform character set ────────────────────────────────────────────────────
readonly WAVE_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 02 — UTILITY FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Ensure cache directories exist ────────────────────────────────────────────
_ensure_cache_dirs() {
    mkdir -p "${ART_CACHE_DIR}" "${LYRIC_CACHE_DIR}"
}

# ── Truncate string with ellipsis ─────────────────────────────────────────────
# Usage: _truncate "string" max_length
# Returns: truncated string with "…" appended if over limit
_truncate() {
    local str="$1"
    local max="${2:-36}"
    # Strip leading/trailing whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    str="${str%"${str##*[![:space:]]}"}"
    if [[ ${#str} -gt $max ]]; then
        echo "${str:0:$((max-1))}…"
    else
        echo "$str"
    fi
}

# ── Format seconds to MM:SS or H:MM:SS ───────────────────────────────────────
# Usage: _format_time <seconds_float>
# Returns: "2:34" or "1:02:34" for times ≥1 hour
_format_time() {
    local secs_float="${1:-0}"
    # Convert float to integer seconds
    local secs
    secs=$(printf "%.0f" "${secs_float}" 2>/dev/null || echo "0")
    local h=$(( secs / 3600 ))
    local m=$(( (secs % 3600) / 60 ))
    local s=$(( secs % 60 ))
    if [[ $h -gt 0 ]]; then
        printf "%d:%02d:%02d" "$h" "$m" "$s"
    else
        printf "%d:%02d" "$m" "$s"
    fi
}

# ── Build unicode progress bar ────────────────────────────────────────────────
# Usage: _make_bar <percentage_int> <width>
# Returns: "[████████░░░░░░░░]"
_make_bar() {
    local pct="${1:-0}"
    local width="${2:-$PROGRESS_BAR_WIDTH}"
    # Clamp percentage to 0–100
    [[ $pct -lt 0 ]] && pct=0
    [[ $pct -gt 100 ]] && pct=100
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    # Build filled portion
    [[ $filled -gt 0 ]] && bar=$(printf "%${filled}s" | tr ' ' "$BLOCK_FULL")
    # Build empty portion
    local empty_str=""
    [[ $empty -gt 0 ]] && empty_str=$(printf "%${empty}s" | tr ' ' "$BLOCK_EMPTY")
    echo "${bar}${empty_str}"
}

# ── Get player icon from player name ─────────────────────────────────────────
# Usage: _get_player_icon "spotify"
# Returns: Nerd Font glyph or 󰎈 fallback
_get_player_icon() {
    local player_raw="${1:-}"
    local player_key
    # Normalize: lowercase, strip .instance suffix, strip version numbers
    player_key=$(echo "$player_raw" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/\..*$//' \
        | sed 's/[0-9]//g')
    echo "${PLAYER_ICONS[$player_key]:-󰎈}"
}

# ── Sanitize filename component ───────────────────────────────────────────────
# Usage: _sanitize_filename "Artist - Title"
# Returns: "Artist_-_Title" (safe for filesystem)
_sanitize_filename() {
    echo "$1" \
        | tr -d '/<>:"|?*\\' \
        | tr ' ' '_' \
        | sed 's/__*/_/g' \
        | cut -c1-128
}

# ── Check if dependency is available ─────────────────────────────────────────
_has_cmd() {
    command -v "$1" &>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 03 — PLAYERCTL DATA ACQUISITION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Select the best active player ────────────────────────────────────────────
# Priority: configured order in PLAYER_PRIORITY array.
# Fallback: first player returned by playerctl -l with non-Stopped status.
# Returns: player instance name or empty string if none active
_select_player() {
    local available_players
    available_players=$(playerctl -l 2>/dev/null) || return 0

    if [[ -z "$available_players" ]]; then
        return 0
    fi

    # Try priority list first
    local p
    for p in "${PLAYER_PRIORITY[@]}"; do
        while IFS= read -r player; do
            local player_key
            player_key=$(echo "$player" | tr '[:upper:]' '[:lower:]' | sed 's/\..*$//')
            if [[ "$player_key" == "$p" ]]; then
                local status
                status=$(playerctl -p "$player" status 2>/dev/null | tr -d '[:space:]') || continue
                if [[ "$status" != "Stopped" && -n "$status" ]]; then
                    echo "$player"
                    return 0
                fi
            fi
        done <<< "$available_players"
    done

    # Fallback: first non-stopped player from full list
    while IFS= read -r player; do
        local status
        status=$(playerctl -p "$player" status 2>/dev/null | tr -d '[:space:]') || continue
        if [[ "$status" != "Stopped" && -n "$status" ]]; then
            echo "$player"
            return 0
        fi
    done <<< "$available_players"

    echo ""
}

# ── Fetch all metadata from selected player ───────────────────────────────────
# Populates global variables: PLAYER, STATUS, TITLE, ARTIST, ALBUM,
#   ART_URL, POSITION_SECS, DURATION_SECS, PROGRESS_PCT
# Returns 1 (exits silently) if no active player
_fetch_metadata() {
    # Guard: playerctl must be available
    if ! _has_cmd playerctl; then
        return 1
    fi

    PLAYER=$(_select_player)
    if [[ -z "$PLAYER" ]]; then
        return 1
    fi

    # ── Status ────────────────────────────────────────────────────────────────
    STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    [[ -z "$STATUS" || "$STATUS" == "stopped" ]] && return 1

    # ── Core metadata ─────────────────────────────────────────────────────────
    TITLE=$(playerctl  -p "$PLAYER" metadata title   2>/dev/null || echo "")
    ARTIST=$(playerctl -p "$PLAYER" metadata artist  2>/dev/null || echo "")
    ALBUM=$(playerctl  -p "$PLAYER" metadata album   2>/dev/null || echo "")
    ART_URL=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null || echo "")

    # ── Position and duration ─────────────────────────────────────────────────
    # playerctl position returns seconds as float: "153.425000"
    # mpris:length returns microseconds as integer: "253000000"
    local pos_raw dur_raw
    pos_raw=$(playerctl -p "$PLAYER" position 2>/dev/null || echo "0")
    dur_raw=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null || echo "0")

    # Convert position to integer seconds
    POSITION_SECS=$(printf "%.0f" "${pos_raw:-0}" 2>/dev/null || echo "0")

    # Convert duration from microseconds to integer seconds
    if [[ "${dur_raw:-0}" -gt 0 ]]; then
        DURATION_SECS=$(( dur_raw / 1000000 ))
    else
        DURATION_SECS=0
    fi

    # ── Progress percentage ───────────────────────────────────────────────────
    if [[ $DURATION_SECS -gt 0 ]]; then
        PROGRESS_PCT=$(( POSITION_SECS * 100 / DURATION_SECS ))
        # Clamp to 0–100
        [[ $PROGRESS_PCT -gt 100 ]] && PROGRESS_PCT=100
        [[ $PROGRESS_PCT -lt 0 ]] && PROGRESS_PCT=0
    else
        PROGRESS_PCT=0
    fi

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 04 — ALBUM ART ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Generate stable art cache key from track identity ─────────────────────────
# Avoids re-downloading art for the same track on each poll cycle.
# Key: MD5 of "artist|album" — stable across restarts.
_art_cache_key() {
    local artist="${1:-}"
    local album="${2:-}"
    echo -n "${artist}|${album}" | md5sum | cut -d' ' -f1
}

# ── Download or copy album art to cache ───────────────────────────────────────
# Handles three art URL types:
#   file:///path/to/art.jpg  → local file, copy/convert to cache
#   http(s)://...            → remote URL, download with curl
#   (empty)                  → use fallback art PNG
# Output: path to cached art file, or empty string on failure
_resolve_art() {
    local art_url="${1:-}"
    local artist="${2:-}"
    local album="${3:-}"

    _ensure_cache_dirs

    local cache_key
    cache_key=$(_art_cache_key "$artist" "$album")
    local cache_path="${ART_CACHE_DIR}/${cache_key}.png"

    # ── Return cached file if already exists ──────────────────────────────────
    if [[ -f "$cache_path" ]]; then
        # Update symlink to current.png
        ln -sf "$cache_path" "$ART_CACHE_FILE"
        echo "$ART_CACHE_FILE"
        return 0
    fi

    # ── Handle file:// URLs ───────────────────────────────────────────────────
    if [[ "$art_url" == file://* ]]; then
        local local_path="${art_url#file://}"
        # URL-decode common encodings (%20 → space)
        local_path=$(python3 -c "import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))" \
            "$local_path" 2>/dev/null || echo "$local_path")

        if [[ -f "$local_path" ]]; then
            # Resize to 256×256 for consistent display
            if _has_cmd convert; then
                convert "$local_path" \
                    -resize 256x256^ \
                    -gravity center \
                    -extent 256x256 \
                    -strip \
                    "$cache_path" 2>/dev/null \
                    && ln -sf "$cache_path" "$ART_CACHE_FILE" \
                    && echo "$ART_CACHE_FILE" \
                    && return 0
            fi
            # Fallback: direct copy without resize
            cp "$local_path" "$cache_path" 2>/dev/null \
                && ln -sf "$cache_path" "$ART_CACHE_FILE" \
                && echo "$ART_CACHE_FILE" \
                && return 0
        fi
    fi

    # ── Handle https:// / http:// URLs ────────────────────────────────────────
    if [[ "$art_url" == http://* || "$art_url" == https://* ]]; then
        if _has_cmd curl; then
            local tmp_download="${ART_CACHE_DIR}/.tmp_download_$$"
            if curl --silent \
                    --max-time 8 \
                    --retry 1 \
                    --retry-delay 1 \
                    --output "$tmp_download" \
                    --user-agent "ASH-Dotfiles-Hyprlock/${SCRIPT_VERSION}" \
                    "$art_url" 2>/dev/null; then

                # Validate downloaded file is an image
                if file "$tmp_download" 2>/dev/null | grep -qiE "image|jpeg|png|gif|webp"; then
                    if _has_cmd convert; then
                        convert "$tmp_download" \
                            -resize 256x256^ \
                            -gravity center \
                            -extent 256x256 \
                            -strip \
                            "$cache_path" 2>/dev/null \
                            && rm -f "$tmp_download" \
                            && ln -sf "$cache_path" "$ART_CACHE_FILE" \
                            && echo "$ART_CACHE_FILE" \
                            && return 0
                    fi
                    # No ImageMagick: use downloaded file directly
                    mv "$tmp_download" "$cache_path" \
                        && ln -sf "$cache_path" "$ART_CACHE_FILE" \
                        && echo "$ART_CACHE_FILE" \
                        && return 0
                fi
            fi
            rm -f "$tmp_download" 2>/dev/null || true
        fi
    fi

    # ── Fallback: use bundled fallback art ────────────────────────────────────
    if [[ -f "$FALLBACK_ART" ]]; then
        ln -sf "$FALLBACK_ART" "$ART_CACHE_FILE" 2>/dev/null || true
        echo "$ART_CACHE_FILE"
        return 0
    fi

    # No art available at all — return empty (image widget hides itself)
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 05 — LYRIC ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Find cached LRC file for current track ────────────────────────────────────
# Checks both exact match and normalized filename.
_find_lrc() {
    local artist="${1:-}"
    local title="${2:-}"

    _ensure_cache_dirs

    # Normalize for filename safety
    local safe_key
    safe_key=$(_sanitize_filename "${artist}-${title}")
    local lrc_path="${LYRIC_CACHE_DIR}/${safe_key}.lrc"

    [[ -f "$lrc_path" ]] && echo "$lrc_path" || echo ""
}

# ── Parse LRC file and extract current line ───────────────────────────────────
# LRC format: [MM:SS.xx]Lyric line text
# Finds the last line with timestamp ≤ current playback position.
_get_current_lyric() {
    local lrc_path="${1:-}"
    local position_secs="${2:-0}"

    [[ -z "$lrc_path" || ! -f "$lrc_path" ]] && echo "" && return 0

    local best_line=""
    local best_ts=0

    while IFS= read -r line; do
        # Match LRC timestamp format: [MM:SS.xx] or [MM:SS]
        if [[ "$line" =~ ^\[([0-9]+):([0-9]+)(\.([0-9]+))?\](.*)$ ]]; then
            local mins="${BASH_REMATCH[1]}"
            local secs="${BASH_REMATCH[2]}"
            local lyric="${BASH_REMATCH[5]}"
            local ts=$(( mins * 60 + secs ))

            # Skip metadata tags: [ar:], [ti:], [al:], [by:]
            [[ "$lyric" =~ ^[a-z]{2}: ]] && continue

            if [[ $ts -le $position_secs && $ts -ge $best_ts ]]; then
                best_ts=$ts
                best_line="${lyric## }"  # Strip leading space
            fi
        fi
    done < "$lrc_path"

    echo "$best_line"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 06 — WAVEFORM GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Generate pseudo-random waveform bars ─────────────────────────────────────
# Uses LCG (Linear Congruential Generator) seeded by nanosecond timestamp.
# Different seed multipliers per bar position create independent "oscillation"
# for each bar — simulates distinct frequency bands.
# When paused: bars collapse to flat line (▂ uniform height).
# When stopped: returns empty string (widget hides).
_generate_waveform() {
    local status="${1:-playing}"
    local progress_pct="${2:-0}"

    # Stopped: empty (widget hides)
    if [[ "$status" == "stopped" ]]; then
        echo ""
        return 0
    fi

    # Paused: flat minimal bars (▂ ▂ ▂)
    if [[ "$status" == "paused" ]]; then
        local flat=""
        for (( i=0; i<WAVEFORM_BARS; i++ )); do
            flat+="▂ "
        done
        echo "  ${flat% }"
        return 0
    fi

    # Playing: animated bars
    # Seed from nanosecond component of current time
    local ns_raw
    ns_raw=$(date +%N 2>/dev/null | sed 's/^0*//' || echo "1")
    local seed="${ns_raw:-1}"

    local wave="  "
    local bar_chars=("${WAVE_CHARS[@]}")
    local num_chars=${#bar_chars[@]}

    for (( i=0; i<WAVEFORM_BARS; i++ )); do
        # LCG: Xn+1 = (a*Xn + c) mod m
        # Different multiplier per bar for independent oscillation
        local a=$(( 6364136223846793005 + i * 1337 ))
        local c=1442695040888963407
        local m=8
        # Shell integer overflow is expected and desired here (modular)
        local idx=$(( (seed * a + c) % m ))
        idx=${idx#-}      # Absolute value (remove negative sign)
        idx=$(( idx % num_chars ))
        wave+="${bar_chars[$idx]} "
        # Advance seed for next bar
        seed=$(( (seed * a + c) ))
        seed=${seed#-}
    done

    echo "${wave% }"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 07 — OUTPUT FORMAT FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── DEFAULT: Full summary line ────────────────────────────────────────────────
# Format: "󰎆  Artist — Track Title"
# Paused: "⏸  Artist — Track Title" (different icon signals state)
# Empty string on stopped/no player.
output_default() {
    local title artist player_icon state_icon

    title=$(_truncate "$TITLE" "$TITLE_MAX_LEN")
    artist=$(_truncate "$ARTIST" "$ARTIST_MAX_LEN")
    player_icon=$(_get_player_icon "$PLAYER")

    # State icon differs playing vs paused
    if [[ "$STATUS" == "paused" ]]; then
        state_icon="⏸"
    else
        state_icon="$player_icon"
    fi

    if [[ -n "$artist" && -n "$title" ]]; then
        echo "${state_icon}  ${artist}  —  ${title}"
    elif [[ -n "$title" ]]; then
        echo "${state_icon}  ${title}"
    else
        echo "${state_icon}  Unknown Track"
    fi
}

# ── --title: Track title only ────────────────────────────────────────────────
output_title() {
    _truncate "$TITLE" "$TITLE_MAX_LEN"
}

# ── --artist: Artist name only ────────────────────────────────────────────────
output_artist() {
    _truncate "$ARTIST" "$ARTIST_MAX_LEN"
}

# ── --album: Album name only ──────────────────────────────────────────────────
output_album() {
    _truncate "$ALBUM" "$ALBUM_MAX_LEN"
}

# ── --artist-album: "Artist  ·  Album" combined ──────────────────────────────
# Used in music widget variant 1 secondary metadata row.
output_artist_album() {
    local artist album
    artist=$(_truncate "$ARTIST" "$ARTIST_MAX_LEN")
    album=$(_truncate  "$ALBUM"  "$ALBUM_MAX_LEN")

    if [[ -n "$artist" && -n "$album" ]]; then
        echo "${artist}  ·  ${album}"
    elif [[ -n "$artist" ]]; then
        echo "$artist"
    elif [[ -n "$album" ]]; then
        echo "$album"
    else
        echo ""
    fi
}

# ── --player: Player icon + display name ──────────────────────────────────────
# Format: "󰓇  via Spotify"
# Player name capitalized for display.
output_player() {
    local icon display_name
    icon=$(_get_player_icon "$PLAYER")
    # Strip .instance suffix, capitalize first letter
    display_name=$(echo "$PLAYER" \
        | sed 's/\..*$//' \
        | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    echo "${icon}  via ${display_name}"
}

# ── --progress: Unicode bar + timestamps ──────────────────────────────────────
# Format: "████████░░░░░░░░  2:34 / 4:12"
# Paused:  "████████░░░░░░░░  ⏸  2:34 / 4:12"
output_progress() {
    local bar pos_fmt dur_fmt pause_indicator=""

    bar=$(_make_bar "$PROGRESS_PCT" "$PROGRESS_BAR_WIDTH")
    pos_fmt=$(_format_time "$POSITION_SECS")
    dur_fmt=$(_format_time "$DURATION_SECS")

    [[ "$STATUS" == "paused" ]] && pause_indicator=" ⏸ " || pause_indicator="  "

    echo "${bar}${pause_indicator}${pos_fmt} / ${dur_fmt}"
}

# ── --pct: Integer percentage only ───────────────────────────────────────────
output_pct() {
    echo "$PROGRESS_PCT"
}

# ── --time: "MM:SS / MM:SS" timestamps only ──────────────────────────────────
output_time() {
    local pos_fmt dur_fmt
    pos_fmt=$(_format_time "$POSITION_SECS")
    dur_fmt=$(_format_time "$DURATION_SECS")
    echo "${pos_fmt} / ${dur_fmt}"
}

# ── --art: Resolve and cache album art, output path ──────────────────────────
# Side effect: downloads/copies art to cache directory.
# Outputs: path to cache file, or empty string if art unavailable.
output_art() {
    _resolve_art "$ART_URL" "$ARTIST" "$ALBUM"
}

# ── --art-path: Output current art path without re-resolving ─────────────────
# Safe to call every 1s — reads symlink target, no download overhead.
output_art_path() {
    if [[ -f "$ART_CACHE_FILE" ]]; then
        echo "$ART_CACHE_FILE"
    elif [[ -f "$FALLBACK_ART" ]]; then
        echo "$FALLBACK_ART"
    else
        echo ""
    fi
}

# ── --status: Playback state string ──────────────────────────────────────────
# Returns: "playing" / "paused" / "stopped"
output_status() {
    echo "$STATUS"
}

# ── --compact: One-line "Artist — Title  bar  time" ──────────────────────────
# Designed for ticker/minimal contexts where space is at premium.
# Format: "󰎆  Artist — Title  ████░░  2:34"
output_compact() {
    local title artist bar pos_fmt icon

    title=$(_truncate "$TITLE"  28)
    artist=$(_truncate "$ARTIST" 18)
    bar=$(_make_bar "$PROGRESS_PCT" "$COMPACT_BAR_WIDTH")
    pos_fmt=$(_format_time "$POSITION_SECS")
    icon=$(_get_player_icon "$PLAYER")

    if [[ -n "$artist" ]]; then
        echo "${icon}  ${artist} — ${title}  ${bar}  ${pos_fmt}"
    else
        echo "${icon}  ${title}  ${bar}  ${pos_fmt}"
    fi
}

# ── --paused: Output only when paused ────────────────────────────────────────
# Returns: "⏸  Paused" when paused, empty string otherwise.
# Used by music widget paused-state indicator label.
output_paused() {
    if [[ "$STATUS" == "paused" ]]; then
        echo "⏸  Paused"
    else
        echo ""
    fi
}

# ── --short: Short "Artist — Title" for ticker bars ──────────────────────────
# Combined artist+title truncated to SHORT_MAX_LEN total.
output_short() {
    local combined

    if [[ -n "$ARTIST" && -n "$TITLE" ]]; then
        combined="${ARTIST} — ${TITLE}"
    else
        combined="${TITLE:-${ARTIST:-Unknown}}"
    fi

    _truncate "$combined" "$SHORT_MAX_LEN"
}

# ── --waveform: Animated spectrum bars ───────────────────────────────────────
# Returns pseudo-random unicode waveform matching player state.
output_waveform() {
    _generate_waveform "$STATUS" "$PROGRESS_PCT"
}

# ── --lyric: Current synced lyric line ───────────────────────────────────────
# Reads from LRC file cache. Falls back to track info if no LRC.
# Format: "♪  Current lyric line text"
output_lyric() {
    local lrc_path
    lrc_path=$(_find_lrc "$ARTIST" "$TITLE")

    if [[ -n "$lrc_path" ]]; then
        local line
        line=$(_get_current_lyric "$lrc_path" "$POSITION_SECS")
        if [[ -n "$line" ]]; then
            echo "♪  $(_truncate "$line" 52)"
            return 0
        fi
    fi

    # Fallback: return standard track info
    output_default
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 08 — MAIN DISPATCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local mode="${1:-}"

    # ── Declare globals populated by _fetch_metadata ──────────────────────────
    PLAYER=""
    STATUS="stopped"
    TITLE=""
    ARTIST=""
    ALBUM=""
    ART_URL=""
    POSITION_SECS=0
    DURATION_SECS=0
    PROGRESS_PCT=0

    # ── Fetch all metadata (exits silently if no player active) ───────────────
    if ! _fetch_metadata; then
        # No active player — all modes return empty (widgets self-hide)
        echo ""
        exit 0
    fi

    # ── Route to appropriate output function ─────────────────────────────────
    case "$mode" in
        --title)        output_title        ;;
        --artist)       output_artist       ;;
        --album)        output_album        ;;
        --artist-album) output_artist_album ;;
        --player)       output_player       ;;
        --progress)     output_progress     ;;
        --pct)          output_pct          ;;
        --time)         output_time         ;;
        --art)          output_art          ;;
        --art-path)     output_art_path     ;;
        --status)       output_status       ;;
        --compact)      output_compact      ;;
        --paused)       output_paused       ;;
        --short)        output_short        ;;
        --waveform)     output_waveform     ;;
        --lyric)        output_lyric        ;;
        --version)      echo "${SCRIPT_NAME} v${SCRIPT_VERSION}" ;;
        --help|-h)
            sed -n '/^# USAGE/,/^# [A-Z]/p' "$0" | grep '│' | sed 's/.*│ //' | sed 's/ *│.*//'
            ;;
        "")             output_default      ;;
        *)
            # Unknown flag — output default and log warning
            echo "songdetail: unknown flag: $mode" >&2
            output_default
            ;;
    esac
}

main "$@"