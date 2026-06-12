#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — AI THEME GENERATOR                            ║
# ║           Generate custom color palettes from text descriptions            ║
# ║           Uses Ollama (local AI) for privacy — no internet required        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: ai-theme.sh [generate|from-image|status] "description"
#
# EXAMPLES:
#   ai-theme.sh generate "dark cyberpunk neon purple rain"
#   ai-theme.sh generate "warm sunset orange golden hour"
#   ai-theme.sh generate "forest green nature calm minimal"
#   ai-theme.sh from-image ~/photos/vacation.jpg
#   ai-theme.sh list-styles

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/ai-theme.log"
readonly AI_PALETTES_DIR="${CACHE_DIR}/ai-palettes"
readonly OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }
err()  { echo -e "  \033[91m✗\033[0m $*" >&2; log "ERROR" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 AI BACKEND DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_ai_backend() {
    # 1. Try Ollama (local, preferred)
    if command -v ollama &>/dev/null; then
        if curl -s --max-time 2 "${OLLAMA_HOST}/api/tags" &>/dev/null; then
            echo "ollama"
            return 0
        fi
    fi

    # 2. Try Python with simple color generation
    if command -v python3 &>/dev/null; then
        echo "python"
        return 0
    fi

    echo "none"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR GENERATION WITH OLLAMA
# ═══════════════════════════════════════════════════════════════════════════════

generate_with_ollama() {
    local description="$1"
    local model="${OLLAMA_MODEL:-llama3.2}"

    info "Using Ollama (${model}) to generate colors..."

    local prompt
    prompt="You are a color theme designer. Generate a dark desktop color palette based on this description: '${description}'

Return ONLY a JSON object with exactly these hex color codes (without # prefix):
{
  \"base\": \"background darkest\",
  \"mantle\": \"background slightly lighter\",
  \"surface0\": \"raised element background\",
  \"primary\": \"main accent color (most vibrant)\",
  \"secondary\": \"secondary accent\",
  \"tertiary\": \"third accent\",
  \"text\": \"main text color (light)\",
  \"success\": \"green-ish\",
  \"warning\": \"yellow-ish\",
  \"error\": \"red-ish\"
}

Make colors harmonious and fitting the description. Dark background preferred.
Return ONLY the JSON, no explanation."

    local response
    response=$(curl -s --max-time 30 \
        "${OLLAMA_HOST}/api/generate" \
        -d "{
            \"model\": \"${model}\",
            \"prompt\": $(echo "${prompt}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
            \"stream\": false,
            \"options\": {\"temperature\": 0.7}
        }" 2>/dev/null)

    if [[ -z "${response}" ]]; then
        warn "Ollama returned empty response"
        return 1
    fi

    # Extract the JSON from the response
    local generated_json
    generated_json=$(echo "${response}" | \
        python3 -c "
import json, sys, re

try:
    data = json.load(sys.stdin)
    text = data.get('response', '')

    # Find JSON in the response
    match = re.search(r'\{[^{}]*\}', text, re.DOTALL)
    if match:
        palette = json.loads(match.group())
        # Validate and clean hex colors
        cleaned = {}
        for k, v in palette.items():
            hex_val = str(v).strip().lstrip('#')
            if len(hex_val) == 6 and all(c in '0123456789abcdefABCDEF' for c in hex_val):
                cleaned[k] = hex_val.lower()

        if len(cleaned) >= 6:
            print(json.dumps(cleaned))
        else:
            print('{}')
    else:
        print('{}')
except Exception as e:
    print('{}')
" 2>/dev/null)

    if [[ "${generated_json}" == "{}" ]] || [[ -z "${generated_json}" ]]; then
        warn "Could not extract valid colors from Ollama response"
        return 1
    fi

    echo "${generated_json}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🐍 COLOR GENERATION WITH PYTHON (no AI needed — algorithmic)
# ═══════════════════════════════════════════════════════════════════════════════

generate_with_python() {
    local description="$1"

    info "Generating colors algorithmically from description..."

    python3 - << PYEOF 2>/dev/null
import json, hashlib, colorsys

description = "${description}"

# Extract mood/color keywords from description
keywords = description.lower().split()

# Keyword → hue mapping
HUE_KEYWORDS = {
    'red': 0, 'fire': 0, 'blood': 0, 'ruby': 0,
    'orange': 30, 'sunset': 30, 'amber': 35, 'golden': 45,
    'yellow': 60, 'gold': 50, 'sunny': 60,
    'green': 120, 'forest': 120, 'nature': 110, 'emerald': 140,
    'cyan': 180, 'teal': 175, 'mint': 160, 'aqua': 185,
    'blue': 220, 'ocean': 210, 'sky': 200, 'sapphire': 230,
    'purple': 270, 'violet': 280, 'mauve': 265, 'lavender': 250,
    'pink': 320, 'rose': 340, 'magenta': 300,
    'white': 0, 'gray': 0, 'silver': 0,
}

# Find matching hue
base_hue = 270  # Default: purple
for word in keywords:
    for keyword, hue in HUE_KEYWORDS.items():
        if keyword in word:
            base_hue = hue
            break

# Saturation based on mood
sat = 0.7
if any(w in keywords for w in ['neon', 'vibrant', 'electric', 'cyber', 'punk']):
    sat = 0.9
elif any(w in keywords for w in ['minimal', 'calm', 'soft', 'muted', 'pastel']):
    sat = 0.4
elif any(w in keywords for w in ['dark', 'moody', 'night', 'shadow']):
    sat = 0.6

# Base lightness for dark theme
base_l = 0.15

def hsl_to_hex(h, s, l):
    h = h / 360.0
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return f"{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"

palette = {
    "base":      hsl_to_hex(base_hue, sat * 0.2, 0.10),
    "mantle":    hsl_to_hex(base_hue, sat * 0.2, 0.08),
    "surface0":  hsl_to_hex(base_hue, sat * 0.25, 0.18),
    "primary":   hsl_to_hex(base_hue, sat, 0.72),
    "secondary": hsl_to_hex((base_hue + 30) % 360, sat * 0.9, 0.65),
    "tertiary":  hsl_to_hex((base_hue + 60) % 360, sat * 0.8, 0.60),
    "text":      hsl_to_hex(base_hue, 0.3, 0.85),
    "success":   "a6e3a1",
    "warning":   "f9e2af",
    "error":     "f38ba8",
}

print(json.dumps(palette))
PYEOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ GENERATE FROM IMAGE MOOD
# ═══════════════════════════════════════════════════════════════════════════════

generate_from_image() {
    local image_path="$1"

    if [[ ! -f "${image_path}" ]]; then
        err "Image not found: ${image_path}"
        return 1
    fi

    if ! command -v convert &>/dev/null; then
        err "ImageMagick required: paru -S imagemagick"
        return 1
    fi

    info "Analyzing image mood: $(basename "${image_path}")"

    # Extract dominant colors using ImageMagick
    local colors
    colors=$(convert "${image_path}" \
        -filter Lanczos \
        -resize 200x200^ \
        -gravity center \
        -extent 200x200 \
        -quantize transparent \
        -colors 12 \
        -unique-colors \
        -format "%[hex:u]\n" \
        info: 2>/dev/null | head -12)

    if [[ -z "${colors}" ]]; then
        err "Could not extract colors from image"
        return 1
    fi

    # Build description from dominant colors
    # Then generate palette using existing logic
    local hex_list
    hex_list=$(echo "${colors}" | head -5 | tr '\n' ' ')
    info "Extracted colors: ${hex_list}"

    # Use theme-engine.sh which already does this well
    "${HOME}/.config/hypr/scripts/theme/theme-engine.sh" "${image_path}" apply
    ok "Theme applied from image analysis"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# ✅ APPLY GENERATED PALETTE
# ═══════════════════════════════════════════════════════════════════════════════

apply_generated_palette() {
    local palette_json="$1"
    local description="$2"
    local palette_name="${3:-ai-generated}"

    # Save palette
    mkdir -p "${AI_PALETTES_DIR}"
    local palette_file="${AI_PALETTES_DIR}/${palette_name}.json"
    echo "${palette_json}" > "${palette_file}"

    # Extract colors
    local base primary secondary tertiary text success warning error

    base=$(echo "${palette_json}"      | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('base','1e1e2e'))")
    primary=$(echo "${palette_json}"   | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('primary','cba6f7'))")
    secondary=$(echo "${palette_json}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('secondary','89b4fa'))")
    tertiary=$(echo "${palette_json}"  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tertiary','94e2d5'))")
    text=$(echo "${palette_json}"      | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('text','cdd6f4'))")
    success=$(echo "${palette_json}"   | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('success','a6e3a1'))")
    warning=$(echo "${palette_json}"   | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('warning','f9e2af'))")
    error=$(echo "${palette_json}"     | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error','f38ba8'))")

    # Show preview
    echo ""
    echo -e "  \033[1m🎨 Generated Palette Preview:\033[0m"
    echo ""

    local preview_colors=(
        "Base:${base}" "Primary:${primary}" "Secondary:${secondary}"
        "Tertiary:${tertiary}" "Text:${text}" "Success:${success}"
        "Warning:${warning}" "Error:${error}"
    )

    for entry in "${preview_colors[@]}"; do
        local name="${entry%%:*}"
        local hex="${entry##*:}"
        if [[ ${#hex} -eq 6 ]]; then
            local r g b
            r=$(( 16#${hex:0:2} ))
            g=$(( 16#${hex:2:2} ))
            b=$(( 16#${hex:4:2} ))
            printf "  \033[38;2;%d;%d;%dm██\033[0m  %-12s #%s\n" \
                "${r}" "${g}" "${b}" "${name}" "${hex}"
        fi
    done

    echo ""
    read -rp "  Apply this theme? [Y/n]: " confirm
    if [[ "${confirm,,}" == "n" ]]; then
        info "Theme not applied"
        return 0
    fi

    # Save theme undo point
    "${HOME}/.config/hypr/scripts/theme/theme-undo.sh" save "pre-ai-theme" \
        &>/dev/null || true

    # Build full color data and apply via light-theme logic
    local mantle="${base}"
    local surf0="${primary}"

    # Generate complete palette
    python3 - << PYEOF 2>/dev/null
import json
from datetime import datetime

# Build from generated colors
data = {
    "_meta": {"description": "${description}", "generated": datetime.now().isoformat(), "mode": "ai"},
    "backgrounds": {"base": "#${base}", "mantle": "#${base}", "crust": "#${base}"},
    "surfaces": {"surface0": "#${surf0[:2]}${surf0[2:4]}${surf0[4:]}", "surface1": "#${primary}", "surface2": "#${secondary}"},
    "overlays": {"overlay0": "#${tertiary}", "overlay1": "#${text}", "overlay2": "#${text}"},
    "accents": {"primary": "#${primary}", "secondary": "#${secondary}", "tertiary": "#${tertiary}"},
    "text": {"text": "#${text}", "subtext1": "#${text}", "subtext0": "#${tertiary}", "muted": "#${tertiary}"},
    "states": {"success": "#${success}", "warning": "#${warning}", "error": "#${error}", "info": "#${secondary}"}
}

with open("${CACHE_DIR}/colors/current.json", "w") as f:
    json.dump(data, f, indent=2)
print("Saved")
PYEOF

    # Apply Hyprland colors
    cat > "${HOME}/.config/hypr/themes/active.conf" << EOF
# ASH AI Theme: ${description}
# Generated: $(date)
general {
    col.active_border   = rgba(${primary}ff) rgba(${secondary}ff) rgba(${tertiary}ff) 60deg
    col.inactive_border = rgba(${base}aa)
}
decoration {
    shadow { color = rgba(${base}cc) }
}
group {
    col.border_active = rgba(${primary}ff)
    groupbar { col.active = rgba(${primary}ff) }
}
EOF

    # Apply Waybar
    cat > "${HOME}/.config/waybar/styles/colors.css" << EOF
/* ASH AI Theme: ${description} */
@define-color base       #${base};
@define-color primary    #${primary};
@define-color secondary  #${secondary};
@define-color tertiary   #${tertiary};
@define-color text       #${text};
@define-color success    #${success};
@define-color warning    #${warning};
@define-color error      #${error};
@define-color bg         @base;
@define-color fg         @text;
@define-color accent     @primary;
@define-color surface0   #${base};
@define-color surface1   #${primary};
@define-color overlay0   #${tertiary};
@define-color muted      #${tertiary};
@define-color info       #${secondary};
@define-color subtext0   #${tertiary};
@define-color subtext1   #${text};
@define-color mantle     #${base};
@define-color crust      #${base};
EOF

    # Reload
    hyprctl reload 2>/dev/null || true
    pkill -SIGUSR2 waybar 2>/dev/null || true

    notify-send "🤖 AI Theme Applied" \
        "${description}" \
        --app-name="ASH AI Theme" \
        --expire-time=4000 \
        2>/dev/null || true

    ok "AI theme applied: ${description}"
    ok "Saved as: ${palette_file}"
    log "INFO" "AI theme: ${description} → primary:#${primary}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LIST SAVED AI PALETTES
# ═══════════════════════════════════════════════════════════════════════════════

list_palettes() {
    if [[ ! -d "${AI_PALETTES_DIR}" ]] || \
       [[ -z "$(ls "${AI_PALETTES_DIR}"/*.json 2>/dev/null)" ]]; then
        echo "  No AI palettes saved yet"
        echo "  Generate one: ash theme ai 'cyberpunk purple neon'"
        return 0
    fi

    echo ""
    echo -e "  \033[1m\033[95m🤖 Saved AI Palettes:\033[0m"
    echo ""

    for f in "${AI_PALETTES_DIR}"/*.json; do
        local name primary
        name=$(basename "${f}" .json)
        primary=$(python3 -c "
import json
try:
    d=json.load(open('$f'))
    print(d.get('primary','?'))
except:
    print('?')
" 2>/dev/null || echo "?")

        if [[ ${#primary} -eq 6 ]]; then
            local r g b
            r=$(( 16#${primary:0:2} ))
            g=$(( 16#${primary:2:2} ))
            b=$(( 16#${primary:4:2} ))
            printf "  \033[38;2;%d;%d;%dm██\033[0m  %s\n" \
                "${r}" "${g}" "${b}" "${name}"
        else
            echo "  ■  ${name}"
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-help}"
    shift || true

    mkdir -p "${AI_PALETTES_DIR}" "${CACHE_DIR}/logs"

    case "${action}" in
        generate | gen | g)
            local description="${*:-dark cyberpunk purple}"

            if [[ -z "${description}" ]]; then
                read -rp "  Describe your theme: " description
            fi

            info "Generating theme: '${description}'"

            local backend
            backend=$(detect_ai_backend)
            info "Backend: ${backend}"

            local palette_json=""
            case "${backend}" in
                ollama)
                    palette_json=$(generate_with_ollama "${description}") || \
                    palette_json=$(generate_with_python "${description}")
                    ;;
                python)
                    palette_json=$(generate_with_python "${description}")
                    ;;
                none)
                    err "No AI backend found"
                    err "Install Ollama: curl https://ollama.ai/install.sh | sh"
                    err "Then: ollama pull llama3.2"
                    exit 1
                    ;;
            esac

            if [[ -n "${palette_json}" ]] && [[ "${palette_json}" != "{}" ]]; then
                local safe_name
                safe_name=$(echo "${description}" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | cut -c1-30)
                apply_generated_palette "${palette_json}" "${description}" "${safe_name}"
            else
                err "Failed to generate palette"
                exit 1
            fi
            ;;

        from-image | image | img)
            local image="${1:-}"
            [[ -z "${image}" ]] && { err "Usage: ai-theme.sh from-image PATH"; exit 1; }
            generate_from_image "${image}"
            ;;

        list | ls)
            list_palettes
            ;;

        apply | load)
            local name="${1:-}"
            local palette_file="${AI_PALETTES_DIR}/${name}.json"
            [[ ! -f "${palette_file}" ]] && { err "Palette not found: ${name}"; list_palettes; exit 1; }
            local palette_json
            palette_json=$(cat "${palette_file}")
            apply_generated_palette "${palette_json}" "${name}" "${name}"
            ;;

        status)
            local backend
            backend=$(detect_ai_backend)
            echo ""
            echo -e "  \033[1m🤖 AI Theme Generator Status:\033[0m"
            echo -e "  Backend: ${backend}"
            if [[ "${backend}" == "ollama" ]]; then
                echo -e "  Ollama: ✅ Running at ${OLLAMA_HOST}"
                local models
                models=$(curl -s "${OLLAMA_HOST}/api/tags" 2>/dev/null \
                    | python3 -c "import json,sys; d=json.load(sys.stdin); print(', '.join([m['name'] for m in d.get('models',[])]))" \
                    2>/dev/null || echo "unknown")
                echo -e "  Models: ${models}"
            elif [[ "${backend}" == "python" ]]; then
                echo -e "  Mode: Algorithmic (no Ollama — still works!)"
            fi
            echo ""
            ;;

        install-ollama)
            info "Installing Ollama..."
            curl -fsSL https://ollama.ai/install.sh | sh
            ollama pull llama3.2
            ok "Ollama installed with llama3.2"
            ;;

        help | *)
            cat << 'HELP'

  🤖 ASH AI Theme Generator

  USAGE:
    ash theme ai "dark cyberpunk purple neon"
    ash theme ai "warm sunset orange golden"
    ash theme ai "forest green nature calm"
    ash theme ai "ocean blue deep midnight"
    ash theme ai from-image ~/photo.jpg
    ash theme ai list
    ash theme ai status

  BACKENDS:
    1. Ollama (local AI — best results)
       Install: curl https://ollama.ai/install.sh | sh
       Then: ollama pull llama3.2

    2. Python algorithmic (no AI needed — always works)
       Uses color theory to generate harmonious palettes

  TIPS:
    → Use descriptive words: colors, moods, aesthetics
    → Keywords: cyberpunk, forest, ocean, sunset, minimal...
    → Works without internet (Ollama runs locally)

HELP
            ;;
    esac
}

main "$@"