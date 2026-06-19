#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — ULTRA PREMIUM SCREENSHOT GENERATION PIPELINE     ║
# ║  Generates all desktop screenshot assets with pixel-perfect precision        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ASSETS_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly OUTPUT_DIR="${SCRIPT_DIR}"
readonly SVG_DIR="${ASSETS_ROOT}/brand/svg-masters"
readonly TEMP_DIR="/tmp/ash-screenshots-$$"

# ── Color Palette Registry ─────────────────────────────────────────────────────
declare -A THEME_COLORS=(
  # Dark Themes
  ["dark-everforest.bg"]="#2D3B2D"
  ["dark-everforest.bg_dim"]="#232A23"
  ["dark-everforest.bg1"]="#3A4A3A"
  ["dark-everforest.bg2"]="#414B41"
  ["dark-everforest.bg3"]="#445544"
  ["dark-everforest.bg4"]="#4C5C4C"
  ["dark-everforest.fg"]="#D3C6AA"
  ["dark-everforest.fg_dim"]="#9DA994"
  ["dark-everforest.red"]="#E67E80"
  ["dark-everforest.orange"]="#E69875"
  ["dark-everforest.yellow"]="#DBBC7F"
  ["dark-everforest.green"]="#A7C080"
  ["dark-everforest.aqua"]="#83C092"
  ["dark-everforest.blue"]="#7FBBB3"
  ["dark-everforest.purple"]="#D699B6"
  ["dark-everforest.accent"]="#A7C080"
  ["dark-everforest.shadow"]="rgba(0,0,0,0.45)"
  ["dark-everforest.glass"]="rgba(45,59,45,0.72)"
  ["dark-everforest.border"]="rgba(167,192,128,0.35)"
  ["dark-everforest.glow"]="rgba(167,192,128,0.18)"

  ["dark-kanagawa.bg"]="#1F1F28"
  ["dark-kanagawa.bg_dim"]="#16161D"
  ["dark-kanagawa.bg1"]="#2A2A37"
  ["dark-kanagawa.bg2"]="#223249"
  ["dark-kanagawa.bg3"]="#363646"
  ["dark-kanagawa.bg4"]="#54546D"
  ["dark-kanagawa.fg"]="#DCD7BA"
  ["dark-kanagawa.fg_dim"]="#727169"
  ["dark-kanagawa.red"]="#C34043"
  ["dark-kanagawa.orange"]="#FFA066"
  ["dark-kanagawa.yellow"]="#C0A36E"
  ["dark-kanagawa.green"]="#76946A"
  ["dark-kanagawa.aqua"]="#6A9589"
  ["dark-kanagawa.blue"]="#7E9CD8"
  ["dark-kanagawa.purple"]="#957FB8"
  ["dark-kanagawa.accent"]="#7E9CD8"
  ["dark-kanagawa.shadow"]="rgba(0,0,0,0.55)"
  ["dark-kanagawa.glass"]="rgba(31,31,40,0.78)"
  ["dark-kanagawa.border"]="rgba(126,156,216,0.28)"
  ["dark-kanagawa.glow"]="rgba(126,156,216,0.15)"
)

# ── Resolution Targets ─────────────────────────────────────────────────────────
declare -A RESOLUTIONS=(
  ["1080p"]="1920x1080"
  ["1440p"]="2560x1440"
  ["4k"]="3840x2160"
  ["ultrawide"]="3440x1440"
  ["thumbnail"]="640x360"
  ["og_image"]="1200x630"
)

# ── Progress Bar ───────────────────────────────────────────────────────────────
_progress() {
  local current=$1 total=$2 label=$3
  local width=50
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar=""
  bar+="$(printf '█%.0s' $(seq 1 $filled))"
  bar+="$(printf '░%.0s' $(seq 1 $empty))"
  printf "\r  \033[38;2;167;192;128m[%s]\033[0m %3d%% %s" "$bar" "$(( current * 100 / total ))" "$label"
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
  mkdir -p "$TEMP_DIR" "$OUTPUT_DIR"
  trap 'rm -rf "$TEMP_DIR"' EXIT

  local themes=(
    "dark-everforest"
    "dark-kanagawa"
    "dark-catppuccin"
    "dark-tokyonight"
    "dark-gruvbox"
    "dark-nord"
    "dark-dracula"
    "dark-onedark"
    "dark-rosepine"
    "light-catppuccin"
    "neon-cyberpunk"
    "neon-synthwave"
    "nature-forest"
    "nature-ocean"
    "space-nebula"
    "retro-vaporwave"
    "anime-evangelion"
  )

  local total=${#themes[@]}
  local current=0

  echo ""
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║   ASH Screenshot Generation Pipeline v5.0        ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo ""

  for theme in "${themes[@]}"; do
    (( current++ ))
    _progress "$current" "$total" "Generating: ${theme}"
    generate_desktop_screenshot "$theme"
    generate_thumbnail "$theme"
  done

  echo ""
  echo ""
  echo "  ✅ Generated ${total} desktop screenshots"
  echo "  📁 Output: ${OUTPUT_DIR}"
}

generate_desktop_screenshot() {
  local theme=$1
  local svg_file="${TEMP_DIR}/${theme}.svg"
  local output="${OUTPUT_DIR}/${theme}.webp"

  # Generate SVG master → convert to WebP
  render_desktop_svg "$theme" > "$svg_file"

  if command -v resvg &>/dev/null; then
    resvg --width 2560 --height 1440 "$svg_file" "${TEMP_DIR}/${theme}.png"
  elif command -v inkscape &>/dev/null; then
    inkscape --export-type=png \
             --export-width=2560 \
             --export-height=1440 \
             --export-filename="${TEMP_DIR}/${theme}.png" \
             "$svg_file" 2>/dev/null
  fi

  if command -v cwebp &>/dev/null && [[ -f "${TEMP_DIR}/${theme}.png" ]]; then
    cwebp -q 90 -m 6 -sharp_yuv \
          "${TEMP_DIR}/${theme}.png" \
          -o "$output" 2>/dev/null
  else
    # Fallback: copy SVG as placeholder
    cp "$svg_file" "${OUTPUT_DIR}/${theme}.svg"
  fi
}

generate_thumbnail() {
  local theme=$1
  local thumb_dir="${OUTPUT_DIR}/thumbnails"
  mkdir -p "$thumb_dir"

  if [[ -f "${TEMP_DIR}/${theme}.png" ]] && command -v convert &>/dev/null; then
    convert "${TEMP_DIR}/${theme}.png" \
            -resize "640x360^" \
            -gravity center \
            -extent 640x360 \
            -quality 85 \
            "${thumb_dir}/${theme}-thumb.webp" 2>/dev/null
  fi
}

main "$@"