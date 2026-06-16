#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖼️  ASH DOTFILES v5.0 OMEGA — RASTER EXPORT PIPELINE                      ║
# ║  Converts SVG sources → optimized PNG at 256 · 512 · 1024 · 2048px         ║
# ║  Supports: Inkscape · CairoSVG · resvg · ImageMagick · Puppeteer           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI ──────────────────────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m"   readonly B="${ESC}[1m"   readonly D="${ESC}[2m"
readonly RED="${ESC}[31m"     readonly GREEN="${ESC}[32m"
readonly YELLOW="${ESC}[33m"  readonly CYAN="${ESC}[36m"
readonly GOLD="${ESC}[38;5;220m"   readonly MINT="${ESC}[38;5;121m"
readonly LAVENDER="${ESC}[38;5;183m" readonly SLATE="${ESC}[38;5;245m"
readonly BG_MIDNIGHT="${ESC}[48;5;16m"

# ── PATHS ─────────────────────────────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOGO_DIR="${SCRIPT_DIR}"
readonly OUT_DIR="${SCRIPT_DIR}"

# ── SVG SOURCES ───────────────────────────────────────────────────────────────
readonly SVG_256="${LOGO_DIR}/ash-logo-256.svg"
readonly SVG_512="${LOGO_DIR}/ash-logo-512.svg"
readonly SVG_1024="${LOGO_DIR}/ash-logo-1024.svg"

# ── OUTPUT PNG TARGETS ────────────────────────────────────────────────────────
readonly PNG_256="${OUT_DIR}/ash-logo-256.png"
readonly PNG_512="${OUT_DIR}/ash-logo-512.png"
readonly PNG_1024="${OUT_DIR}/ash-logo-1024.png"
readonly PNG_2048="${OUT_DIR}/ash-logo-2048.png"   # Upscaled from 1024 src
readonly ICO="${OUT_DIR}/ash-logo.ico"

# ── ADDITIONAL EXPORT SIZES ───────────────────────────────────────────────────
declare -a EXTRA_SIZES=(16 32 48 64 96 128 192 384)

# ── FLAGS ─────────────────────────────────────────────────────────────────────
DRY_RUN=false
OPTIMIZE=true
GENERATE_ICO=true
GENERATE_FAVICON=true
GENERATE_WEBP=true
GENERATE_AVIF=false
GENERATE_EXTRAS=false
VERBOSE=false
RENDERER=""

# ── STATE ─────────────────────────────────────────────────────────────────────
EXPORTS_DONE=0
EXPORTS_FAILED=0
SCRIPT_START_MS="$(date +%s%3N)"

# ── TIMING ────────────────────────────────────────────────────────────────────
now_ms()     { date +%s%3N; }
elapsed_ms() { echo $(( $(now_ms) - SCRIPT_START_MS )); }
format_dur() {
    local ms="$1"
    [[ $ms -lt 1000 ]] && printf "%dms" "$ms" || \
        printf "%.1fs" "$(echo "scale=1; $ms/1000" | bc 2>/dev/null || echo "$((ms/1000))")"
}

# ── LOGGING ───────────────────────────────────────────────────────────────────
log_section() { printf "\n  %s%s▶ %s%s\n" "$GOLD" "$B" "$*" "$R" >&2; }
log_step()    { printf "  %s  ◆%s %s%s%s\n" "$CYAN" "$R" "$D" "$*" "$R" >&2; }
log_pass()    { printf "  %s  ✓%s %s%s%s\n" "${GREEN}${B}" "$R" "$MINT" "$*" "$R" >&2; ((EXPORTS_DONE++)) || true; }
log_fail()    { printf "  %s  ✗%s %s%s%s\n" "${RED}${B}"   "$R" "$RED"  "$*" "$R" >&2; ((EXPORTS_FAILED++)) || true; }
log_warn()    { printf "  %s  ⚠%s %s%s%s\n" "${YELLOW}${B}" "$R" "$YELLOW" "$*" "$R" >&2; }
log_skip()    { printf "  %s  ↷%s %s%s%s\n" "${SLATE}${D}" "$R" "$D"  "$*" "$R" >&2; }
log_info()    { printf "  %s  ℹ%s %s%s%s\n" "${LAVENDER}" "$R" "$D" "$*" "$R" >&2; }

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n" >&2
    printf "%s%s" "$BG_MIDNIGHT" "$GOLD" >&2
    printf "  ╔══════════════════════════════════════════════════════════════════╗  \n" >&2
    printf "  ║  %s🖼️  ASH DOTFILES — RASTER EXPORT PIPELINE%s                       ║  \n" \
        "${B}" "${R}${BG_MIDNIGHT}${GOLD}" >&2
    printf "  ║  %sConverts SVG → PNG at 256 · 512 · 1024 · 2048px%s              ║  \n" \
        "${D}" "${R}${BG_MIDNIGHT}${GOLD}" >&2
    printf "  ╚══════════════════════════════════════════════════════════════════╝  \n" >&2
    printf "%s\n\n" "$R" >&2
}

# ── ARGUMENT PARSING ──────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)       DRY_RUN=true;        shift ;;
            -v|--verbose)       VERBOSE=true;         shift ;;
            --no-optimize)      OPTIMIZE=false;       shift ;;
            --no-ico)           GENERATE_ICO=false;   shift ;;
            --no-favicon)       GENERATE_FAVICON=false; shift ;;
            --no-webp)          GENERATE_WEBP=false;  shift ;;
            --avif)             GENERATE_AVIF=true;   shift ;;
            --extras)           GENERATE_EXTRAS=true; shift ;;
            --renderer)         RENDERER="${2:?'--renderer requires a value'}"; shift 2 ;;
            -h|--help)          print_help; exit 0 ;;
            *) echo "Unknown option: $1" >&2; exit 1 ;;
        esac
    done
}

print_help() {
    cat <<EOF
${GOLD}${B}Usage:${R} export-raster.sh [OPTIONS]

${B}Options:${R}
  ${GREEN}--dry-run${R}       Preview without exporting
  ${GREEN}--no-optimize${R}   Skip PNG optimization
  ${GREEN}--no-ico${R}        Skip .ico generation
  ${GREEN}--no-favicon${R}    Skip favicon set generation
  ${GREEN}--no-webp${R}       Skip WebP generation
  ${GREEN}--avif${R}          Generate AVIF (requires libavif)
  ${GREEN}--extras${R}        Generate extra sizes (16-384px)
  ${GREEN}--renderer${R} <r>  Force renderer: inkscape|cairosvg|resvg|magick|puppeteer
  ${GREEN}--verbose${R}       Verbose output

EOF
}

# ── RENDERER DETECTION ────────────────────────────────────────────────────────
detect_renderer() {
    log_section "Detecting SVG Renderer"

    if [[ -n "$RENDERER" ]]; then
        log_info "Forced renderer: $RENDERER"
        return 0
    fi

    # Priority order: resvg > Inkscape > CairoSVG > ImageMagick > Puppeteer
    if command -v resvg &>/dev/null; then
        RENDERER="resvg"
        local ver; ver="$(resvg --version 2>/dev/null | head -1 || echo "?")"
        log_pass "resvg detected — ${ver} (best quality)"

    elif command -v inkscape &>/dev/null; then
        RENDERER="inkscape"
        local ver; ver="$(inkscape --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1 || echo "?")"
        log_pass "Inkscape detected — v${ver}"

    elif command -v cairosvg &>/dev/null || python3 -c "import cairosvg" &>/dev/null 2>&1; then
        RENDERER="cairosvg"
        log_pass "CairoSVG detected"

    elif command -v convert &>/dev/null; then
        RENDERER="magick"
        local ver; ver="$(convert --version 2>/dev/null | head -1 || echo "?")"
        log_warn "ImageMagick fallback — SVG rendering quality may vary"
        log_info "$ver"

    elif command -v node &>/dev/null && node -e "require('puppeteer')" &>/dev/null 2>&1; then
        RENDERER="puppeteer"
        log_pass "Puppeteer (headless Chrome) detected"

    else
        log_fail "No SVG renderer found!"
        printf "\n  %sInstall one of the following:%s\n" "$YELLOW" "$R" >&2
        printf "    %s# Recommended (fastest, most accurate)%s\n" "$D" "$R" >&2
        printf "    %scargo install resvg%s\n" "$CYAN" "$R" >&2
        printf "\n    %s# Alternative options%s\n" "$D" "$R" >&2
        printf "    %spip install cairosvg%s\n" "$CYAN" "$R" >&2
        printf "    %ssudo pacman -S inkscape%s\n" "$CYAN" "$R" >&2
        printf "    %snpm install -g puppeteer%s\n" "$CYAN" "$R" >&2
        exit 1
    fi
}

# ── SINGLE EXPORT FUNCTION ────────────────────────────────────────────────────
export_png() {
    local src_svg="$1"
    local dst_png="$2"
    local size="$3"
    local label="${4:-${size}×${size}}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_skip "[DRY] Would export: $(basename "$dst_png") (${size}px)"
        return 0
    fi

    if [[ ! -f "$src_svg" ]]; then
        log_fail "Source SVG not found: $src_svg"
        return 1
    fi

    local t_start; t_start="$(now_ms)"

    local exit_code=0
    case "$RENDERER" in

        resvg)
            resvg \
                --width  "$size" \
                --height "$size" \
                --background transparent \
                --dpi 96 \
                "$src_svg" "$dst_png" 2>/dev/null || exit_code=$?
            ;;

        inkscape)
            inkscape \
                --export-type=png \
                --export-filename="$dst_png" \
                --export-width="$size" \
                --export-height="$size" \
                --export-background-opacity=0 \
                "$src_svg" \
                2>/dev/null || exit_code=$?
            ;;

        cairosvg)
            cairosvg \
                "$src_svg" \
                -o "$dst_png" \
                -W "$size" \
                -H "$size" \
                --background-color transparent \
                2>/dev/null || \
            python3 -c "
import cairosvg
cairosvg.svg2png(
    url='${src_svg}',
    write_to='${dst_png}',
    output_width=${size},
    output_height=${size},
    background_color=None
)" 2>/dev/null || exit_code=$?
            ;;

        magick)
            convert \
                -background none \
                -density 288 \
                "$src_svg" \
                -resize "${size}x${size}" \
                -filter Lanczos \
                -quality 100 \
                "$dst_png" 2>/dev/null || exit_code=$?
            ;;

        puppeteer)
            node - "$src_svg" "$dst_png" "$size" <<'JSEOF' 2>/dev/null || exit_code=$?
const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
    const [,, svgPath, pngPath, size] = process.argv;
    const sz = parseInt(size, 10);

    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();

    await page.setViewport({ width: sz, height: sz, deviceScaleFactor: 1 });

    const svgContent = fs.readFileSync(svgPath, 'utf8');
    const dataUrl = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svgContent);

    await page.goto(dataUrl, { waitUntil: 'networkidle0' });
    await new Promise(r => setTimeout(r, 800)); // Let animations settle

    await page.screenshot({
        path: pngPath,
        type: 'png',
        omitBackground: true,
        clip: { x: 0, y: 0, width: sz, height: sz }
    });

    await browser.close();
})();
JSEOF
            ;;

        *)
            log_fail "Unknown renderer: $RENDERER"
            return 1
            ;;
    esac

    local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

    if [[ $exit_code -eq 0 ]] && [[ -f "$dst_png" ]]; then
        local file_size; file_size="$(du -h "$dst_png" | cut -f1)"
        log_pass "Exported: ${label} → $(basename "$dst_png") (${file_size}) [${dur}]"
        return 0
    else
        log_fail "Export failed: ${label} (exit: ${exit_code})"
        return 1
    fi
}

# ── PNG OPTIMIZATION ──────────────────────────────────────────────────────────
optimize_png() {
    local png_file="$1"

    if [[ "$OPTIMIZE" != "true" ]]; then
        log_skip "Optimization disabled"
        return 0
    fi

    local before_size; before_size="$(du -h "$png_file" | cut -f1)"
    local optimized=false

    # oxipng — best lossless optimizer
    if command -v oxipng &>/dev/null; then
        oxipng --opt 3 --strip safe "$png_file" 2>/dev/null && optimized=true

    # pngquant — lossy but much smaller (quality: 90-100%)
    elif command -v pngquant &>/dev/null; then
        pngquant --quality=90-100 --force --ext .png "$png_file" 2>/dev/null && optimized=true

    # optipng — standard lossless
    elif command -v optipng &>/dev/null; then
        optipng -o4 "$png_file" 2>/dev/null && optimized=true

    # pngcrush
    elif command -v pngcrush &>/dev/null; then
        local tmp="${png_file%.png}-crush.png"
        pngcrush -reduce -brute "$png_file" "$tmp" 2>/dev/null && \
            mv "$tmp" "$png_file" && optimized=true
    fi

    if [[ "$optimized" == "true" ]]; then
        local after_size; after_size="$(du -h "$png_file" | cut -f1)"
        log_pass "Optimized: $(basename "$png_file") ${before_size} → ${after_size}"
    else
        log_warn "No PNG optimizer found (oxipng/pngquant/optipng)"
        log_info  "Install: cargo install oxipng"
    fi
}

# ── WEBP CONVERSION ───────────────────────────────────────────────────────────
generate_webp() {
    local png_file="$1"
    local webp_file="${png_file%.png}.webp"

    if command -v cwebp &>/dev/null; then
        local t_start; t_start="$(now_ms)"
        cwebp -lossless -q 100 "$png_file" -o "$webp_file" 2>/dev/null
        local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"
        local size; size="$(du -h "$webp_file" | cut -f1)"
        log_pass "WebP: $(basename "$webp_file") (${size}) [${dur}]"

    elif command -v ffmpeg &>/dev/null; then
        ffmpeg -i "$png_file" -lossless 1 "$webp_file" -y 2>/dev/null && \
            log_pass "WebP (ffmpeg): $(basename "$webp_file")"
    else
        log_warn "cwebp not found — skipping WebP for $(basename "$png_file")"
    fi
}

# ── AVIF CONVERSION ───────────────────────────────────────────────────────────
generate_avif() {
    local png_file="$1"
    local avif_file="${png_file%.png}.avif"

    if command -v avifenc &>/dev/null; then
        avifenc --lossless "$png_file" "$avif_file" 2>/dev/null && \
            log_pass "AVIF: $(basename "$avif_file")"
    elif command -v ffmpeg &>/dev/null; then
        ffmpeg -i "$png_file" -c:v libaom-av1 -crf 0 \
            "$avif_file" -y 2>/dev/null && \
            log_pass "AVIF (ffmpeg): $(basename "$avif_file")"
    else
        log_warn "avifenc not found — skipping AVIF"
    fi
}

# ── ICO GENERATION ────────────────────────────────────────────────────────────
generate_ico() {
    log_section "Generating .ico (Windows/Browser)"

    if [[ "$GENERATE_ICO" != "true" ]]; then
        log_skip ".ico generation disabled"
        return 0
    fi

    # Generate required ICO sizes first
    local ico_sizes=(16 32 48 64 128 256)
    local ico_sources=()

    for size in "${ico_sizes[@]}"; do
        local tmp_png="${TMPDIR:-/tmp}/ash-ico-${size}.png"
        local src_svg

        if [[ $size -le 64 ]]; then
            src_svg="$SVG_256"
        elif [[ $size -le 128 ]]; then
            src_svg="$SVG_256"
        else
            src_svg="$SVG_256"
        fi

        if export_png "$src_svg" "$tmp_png" "$size" "ICO-${size}px"; then
            ico_sources+=("$tmp_png")
        fi
    done

    # Combine into .ico with ImageMagick or icotool
    if command -v convert &>/dev/null; then
        local convert_args=()
        for src in "${ico_sources[@]}"; do
            convert_args+=("$src")
        done
        convert "${convert_args[@]}" "$ICO" 2>/dev/null && \
            log_pass "Generated: ash-logo.ico (${#ico_sizes[@]} sizes embedded)"

    elif command -v icotool &>/dev/null; then
        icotool --create --output="$ICO" "${ico_sources[@]}" 2>/dev/null && \
            log_pass "Generated: ash-logo.ico (icotool)"
    else
        log_warn "No .ico generator found (ImageMagick convert or icotool)"
    fi

    # Cleanup temp files
    for f in "${ico_sources[@]}"; do
        rm -f "$f" 2>/dev/null || true
    done
}

# ── FAVICON SET ───────────────────────────────────────────────────────────────
generate_favicon_set() {
    log_section "Generating Favicon Set"

    if [[ "$GENERATE_FAVICON" != "true" ]]; then
        log_skip "Favicon set disabled"
        return 0
    fi

    local favicon_dir="${SCRIPT_DIR}/../../favicons"
    mkdir -p "$favicon_dir"

    local -a favicon_sizes=(16 32 48 64 96 128 192 256 512)
    for size in "${favicon_sizes[@]}"; do
        local src_svg="$SVG_256"
        [[ $size -gt 256 ]] && src_svg="$SVG_512"

        local dst="${favicon_dir}/favicon-${size}x${size}.png"
        export_png "$src_svg" "$dst" "$size" "favicon-${size}"
    done

    # Copy 32px as favicon.ico placeholder
    if [[ -f "${favicon_dir}/favicon-32x32.png" ]] && \
       command -v convert &>/dev/null; then
        convert \
            "${favicon_dir}/favicon-16x16.png" \
            "${favicon_dir}/favicon-32x32.png" \
            "${favicon_dir}/favicon-48x48.png" \
            "${favicon_dir}/favicon.ico" 2>/dev/null && \
            log_pass "Generated: favicon.ico"
    fi

    # Apple touch icon (180×180)
    local apple="${favicon_dir}/apple-touch-icon.png"
    export_png "$SVG_256" "$apple" "180" "apple-touch-icon"

    # Android chrome icons
    export_png "$SVG_512" "${favicon_dir}/android-chrome-192x192.png" "192" "android-192"
    export_png "$SVG_512" "${favicon_dir}/android-chrome-512x512.png" "512" "android-512"

    # Web manifest
    cat > "${favicon_dir}/site.webmanifest" <<JSON
{
  "name": "ASH Dotfiles",
  "short_name": "ASH",
  "description": "The most advanced Hyprland dotfiles",
  "icons": [
    { "src": "/favicons/favicon-16x16.png",          "sizes": "16x16",   "type": "image/png" },
    { "src": "/favicons/favicon-32x32.png",          "sizes": "32x32",   "type": "image/png" },
    { "src": "/favicons/favicon-96x96.png",          "sizes": "96x96",   "type": "image/png" },
    { "src": "/favicons/android-chrome-192x192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/favicons/android-chrome-512x512.png", "sizes": "512x512", "type": "image/png" }
  ],
  "theme_color": "#1E1E2E",
  "background_color": "#1E1E2E",
  "display": "standalone"
}
JSON
    log_pass "Generated: site.webmanifest"
}

# ── EXTRA SIZES ───────────────────────────────────────────────────────────────
generate_extra_sizes() {
    log_section "Generating Extra Sizes"

    local extra_dir="${SCRIPT_DIR}/extras"
    mkdir -p "$extra_dir"

    for size in "${EXTRA_SIZES[@]}"; do
        local src_svg
        if   [[ $size -le 64  ]]; then src_svg="$SVG_256"
        elif [[ $size -le 256 ]]; then src_svg="$SVG_256"
        elif [[ $size -le 512 ]]; then src_svg="$SVG_512"
        else                           src_svg="$SVG_1024"
        fi

        local dst="${extra_dir}/ash-logo-${size}.png"
        export_png "$src_svg" "$dst" "$size"

        [[ "$GENERATE_WEBP" == "true" ]] && [[ -f "$dst" ]] && \
            generate_webp "$dst"
    done
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local dur; dur="$(format_dur "$(elapsed_ms)")"

    printf "\n" >&2
    printf "%s%s" "$BG_MIDNIGHT" "$GOLD" >&2
    printf "  ╔══════════════════════════════════════════════════════════════════╗  \n" >&2
    printf "  ║  %s📊 EXPORT SUMMARY%s                                                ║  \n" \
        "${B}" "${R}${BG_MIDNIGHT}${GOLD}" >&2
    printf "  ╠══════════════════════════════════════════════════════════════════╣  \n" >&2
    printf "  ║  %s✓ %-4s%s exported   %s✗ %-4s%s failed   %s⏱ %s%s                         ║  \n" \
        "${GREEN}${B}" "$EXPORTS_DONE"   "${R}${BG_MIDNIGHT}${GOLD}" \
        "${RED}${B}"   "$EXPORTS_FAILED" "${R}${BG_MIDNIGHT}${GOLD}" \
        "${CYAN}${D}"  "$dur"            "${R}${BG_MIDNIGHT}${GOLD}" >&2
    printf "  ╠══════════════════════════════════════════════════════════════════╣  \n" >&2
    printf "  ║  %sRenderer: %-54s%s  ║  \n" \
        "${LAVENDER}" "$RENDERER" "${R}${BG_MIDNIGHT}${GOLD}" >&2
    printf "  ║  %sOutput:   %-54s%s  ║  \n" \
        "${D}" "$OUT_DIR" "${R}${BG_MIDNIGHT}${GOLD}" >&2
    printf "  ╚══════════════════════════════════════════════════════════════════╝  \n" >&2
    printf "%s\n\n" "$R" >&2
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    print_banner
    detect_renderer

    # ── CORE PNG EXPORTS ───────────────────────────────────────────────────
    log_section "Exporting Core PNG Files"

    export_png "$SVG_256"  "$PNG_256"  "256"  "256×256px  (app icon)"
    export_png "$SVG_512"  "$PNG_512"  "512"  "512×512px  (high-DPI)"
    export_png "$SVG_1024" "$PNG_1024" "1024" "1024×1024px (app store)"
    export_png "$SVG_1024" "$PNG_2048" "2048" "2048×2048px (retina max)"

    # ── OPTIMIZE ──────────────────────────────────────────────────────────
    log_section "Optimizing PNG Files"
    for png in "$PNG_256" "$PNG_512" "$PNG_1024" "$PNG_2048"; do
        [[ -f "$png" ]] && optimize_png "$png"
    done

    # ── WEBP ──────────────────────────────────────────────────────────────
    if [[ "$GENERATE_WEBP" == "true" ]]; then
        log_section "Generating WebP Variants"
        for png in "$PNG_256" "$PNG_512" "$PNG_1024"; do
            [[ -f "$png" ]] && generate_webp "$png"
        done
    fi

    # ── AVIF ──────────────────────────────────────────────────────────────
    if [[ "$GENERATE_AVIF" == "true" ]]; then
        log_section "Generating AVIF Variants"
        for png in "$PNG_256" "$PNG_512" "$PNG_1024"; do
            [[ -f "$png" ]] && generate_avif "$png"
        done
    fi

    # ── ICO ───────────────────────────────────────────────────────────────
    generate_ico

    # ── FAVICON SET ───────────────────────────────────────────────────────
    generate_favicon_set

    # ── EXTRA SIZES ───────────────────────────────────────────────────────
    [[ "$GENERATE_EXTRAS" == "true" ]] && generate_extra_sizes

    # ── MANIFEST ──────────────────────────────────────────────────────────
    log_section "Writing Asset Manifest"

    local manifest_file="${SCRIPT_DIR}/asset-manifest.json"
    if ! "$DRY_RUN"; then
        python3 - "$manifest_file" "$OUT_DIR" <<'PYEOF'
import json, os, hashlib, sys
from pathlib import Path

manifest_file = sys.argv[1]
out_dir = Path(sys.argv[2])

assets = []
for ext in ['png', 'webp', 'avif', 'ico', 'svg']:
    for f in sorted(out_dir.glob(f'*.{ext}')):
        try:
            stat = f.stat()
            sha256 = hashlib.sha256(f.read_bytes()).hexdigest()
            assets.append({
                "file": f.name,
                "size_bytes": stat.st_size,
                "size_human": f"{stat.st_size / 1024:.1f}KB",
                "sha256": sha256[:16] + "...",
                "format": ext.upper()
            })
        except Exception:
            pass

manifest = {
    "_generated": "ASH Export Pipeline v5.0.0-omega",
    "_timestamp": __import__('datetime').datetime.utcnow().isoformat() + "Z",
    "total_assets": len(assets),
    "assets": assets
}

with open(manifest_file, 'w') as f:
    json.dump(manifest, f, indent=2)

print(f"Manifest: {len(assets)} assets → {manifest_file}")
PYEOF
        log_pass "Asset manifest written: asset-manifest.json"
    fi

    print_summary

    [[ $EXPORTS_FAILED -gt 0 ]] && exit 1
    exit 0
}

main "$@"