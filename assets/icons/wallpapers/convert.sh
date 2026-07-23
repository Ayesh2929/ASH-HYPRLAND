#!/usr/bin/env bash
# ============================================================
# ASH DOTFILES v5.0 OMEGA
# Wallpaper SVG → JPG/WebP Converter
# Ultra-optimized, multi-format export pipeline
# ============================================================

set -euo pipefail

# ── Config ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}"
QUALITY_JPG=97
QUALITY_WEBP=95
RESOLUTION_4K="3840x2160"
RESOLUTION_2K="2560x1440"
RESOLUTION_FHD="1920x1080"
RESOLUTION_HD="1280x720"

# ── Colors ───────────────────────────────────────────────────
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_MAUVE='\033[38;2;203;164;247m'
C_SAPPH='\033[38;2;116;199;236m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_GREY='\033[38;2;127;132;156m'

# ── Logging ──────────────────────────────────────────────────
log_info()  { echo -e "${C_MAUVE}[INFO]${C_RESET}  $*"; }
log_ok()    { echo -e "${C_GREEN}[ OK ]${C_RESET}  $*"; }
log_err()   { echo -e "${C_RED}[ERR ]${C_RESET}  $*" >&2; }
log_step()  { echo -e "\n${C_BOLD}${C_SAPPH}──── $* ────${C_RESET}"; }

# ── Dependency check ─────────────────────────────────────────
check_deps() {
  local -a required=(rsvg-convert convert cwebp optipng)
  local missing=()
  for dep in "${required[@]}"; do
    command -v "$dep" &>/dev/null || missing+=("$dep")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    log_err "Missing dependencies: ${missing[*]}"
    log_err "Install: sudo pacman -S librsvg imagemagick libwebp optipng"
    exit 1
  fi
}

# ── Convert single SVG to multi-format ───────────────────────
convert_wallpaper() {
  local svg_file="$1"
  local base_name
  base_name="$(basename "$svg_file" .svg)"

  log_step "Processing: ${base_name}"

  # 4K JPG (primary)
  log_info "→ 4K JPG  (${RESOLUTION_4K})"
  rsvg-convert \
    --width=3840 \
    --height=2160 \
    --format=png \
    --keep-aspect-ratio \
    "$svg_file" \
  | convert \
    -quality "${QUALITY_JPG}" \
    -sampling-factor 4:2:0 \
    -strip \
    -interlace Plane \
    -colorspace sRGB \
    -filter Lanczos \
    png:- \
    "${OUT_DIR}/${base_name}.jpg"
  log_ok "${base_name}.jpg"

  # 4K WebP (modern)
  log_info "→ 4K WebP (${RESOLUTION_4K})"
  rsvg-convert \
    --width=3840 \
    --height=2160 \
    --format=png \
    --keep-aspect-ratio \
    "$svg_file" \
  | cwebp \
    -q "${QUALITY_WEBP}" \
    -m 6 \
    -pass 10 \
    -mt \
    -sharp_yuv \
    -stdin \
    -o "${OUT_DIR}/${base_name}.webp"
  log_ok "${base_name}.webp"

  # 2K JPG
  log_info "→ 2K JPG  (${RESOLUTION_2K})"
  rsvg-convert \
    --width=2560 \
    --height=1440 \
    --format=png \
    --keep-aspect-ratio \
    "$svg_file" \
  | convert \
    -quality "${QUALITY_JPG}" \
    -strip \
    -interlace Plane \
    -colorspace sRGB \
    png:- \
    "${OUT_DIR}/${base_name}-2k.jpg"
  log_ok "${base_name}-2k.jpg"

  # FHD JPG
  log_info "→ FHD JPG (${RESOLUTION_FHD})"
  rsvg-convert \
    --width=1920 \
    --height=1080 \
    --format=png \
    --keep-aspect-ratio \
    "$svg_file" \
  | convert \
    -quality "${QUALITY_JPG}" \
    -strip \
    -interlace Plane \
    -colorspace sRGB \
    png:- \
    "${OUT_DIR}/${base_name}-fhd.jpg"
  log_ok "${base_name}-fhd.jpg"

  # Thumbnail for picker (320x180)
  log_info "→ Thumbnail (320x180)"
  rsvg-convert \
    --width=320 \
    --height=180 \
    --format=png \
    --keep-aspect-ratio \
    "$svg_file" \
  | convert \
    -quality 88 \
    -strip \
    -colorspace sRGB \
    png:- \
    "${OUT_DIR}/${base_name}-thumb.jpg"
  log_ok "${base_name}-thumb.jpg"

  # Print file sizes
  log_info "Sizes:"
  for f in \
    "${OUT_DIR}/${base_name}.jpg" \
    "${OUT_DIR}/${base_name}.webp" \
    "${OUT_DIR}/${base_name}-2k.jpg" \
    "${OUT_DIR}/${base_name}-fhd.jpg" \
    "${OUT_DIR}/${base_name}-thumb.jpg"; do
    [[ -f "$f" ]] && \
      printf "  ${C_GREY}%-42s${C_RESET} %s\n" \
        "$(basename "$f")" \
        "$(du -sh "$f" | cut -f1)"
  done
}

# ── Generate metadata JSON ────────────────────────────────────
generate_metadata() {
  local base="$1"
  local name="$2"
  local theme="$3"
  local desc="$4"

  cat > "${OUT_DIR}/${base}.json" <<EOF
{
  "name": "${name}",
  "file": "${base}.jpg",
  "formats": {
    "4k_jpg":   "${base}.jpg",
    "4k_webp":  "${base}.webp",
    "2k_jpg":   "${base}-2k.jpg",
    "fhd_jpg":  "${base}-fhd.jpg",
    "thumb":    "${base}-thumb.jpg"
  },
  "resolution": {
    "width":  3840,
    "height": 2160,
    "aspect": "16:9"
  },
  "theme":       "${theme}",
  "description": "${desc}",
  "tags":        ["default", "ash", "${theme}", "catppuccin"],
  "version":     "5.0.0",
  "author":      "ash-dotfiles",
  "license":     "MIT",
  "generated":   "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  log_ok "Metadata: ${base}.json"
}

# ── Main ─────────────────────────────────────────────────────
main() {
  log_step "ASH Wallpaper Export Pipeline v5.0 OMEGA"
  check_deps

  local -a wallpapers=(
    "default-dark.svg"
    "default-light.svg"
    "default-minimal.svg"
  )

  for svg in "${wallpapers[@]}"; do
    local full_path="${SCRIPT_DIR}/${svg}"
    if [[ -f "$full_path" ]]; then
      convert_wallpaper "$full_path"
    else
      log_err "SVG not found: $full_path"
    fi
  done

  # Generate metadata
  log_step "Generating Metadata"
  generate_metadata \
    "default-dark" \
    "ASH Default Dark" \
    "catppuccin-mocha" \
    "Deep space nebula with concentric rings, star field and perspective grid. Catppuccin Mocha palette."

  generate_metadata \
    "default-light" \
    "ASH Default Light" \
    "catppuccin-latte" \
    "Clean paper aesthetic with watercolor washes, floating UI cards and warm sun glow. Catppuccin Latte palette."

  generate_metadata \
    "default-minimal" \
    "ASH Default Minimal" \
    "monochrome-mocha" \
    "Ultra-minimal near-pure dark with single mauve accent ring, micro grid and sparse composition. Zero clutter."

  log_step "Export Complete"
  log_ok "All wallpapers exported to: ${OUT_DIR}"

  # Summary table
  echo ""
  printf "${C_BOLD}${C_SAPPH}%-35s %-12s %-12s %-12s${C_RESET}\n" \
    "File" "4K JPG" "4K WebP" "Thumb"
  printf "${C_GREY}%s${C_RESET}\n" \
    "──────────────────────────────────────────────────────────────"
  for base in default-dark default-light default-minimal; do
    local j w t
    j="$(du -sh "${OUT_DIR}/${base}.jpg"      2>/dev/null | cut -f1 || echo '-')"
    w="$(du -sh "${OUT_DIR}/${base}.webp"     2>/dev/null | cut -f1 || echo '-')"
    t="$(du -sh "${OUT_DIR}/${base}-thumb.jpg" 2>/dev/null | cut -f1 || echo '-')"
    printf "%-35s %-12s %-12s %-12s\n" "${base}" "${j}" "${w}" "${t}"
  done
  echo ""
}

main "$@"