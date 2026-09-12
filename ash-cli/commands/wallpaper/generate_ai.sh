#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper generate-ai                                    ║
# ║  AI image generation via Ollama (llava) • Stable Diffusion • DALL-E API        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_GENERATE_AI_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_GENERATE_AI_LOADED=1

set -euo pipefail

_ai_spinner() {
    local msg="$1"
    local frames=( '🌑' '🌒' '🌓' '🌔' '🌕' '🌖' '🌗' '🌘' )
    local i=0
    while true; do
        printf '\r  %s  %s' "${frames[$i]}" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.15
    done
}

_ai_ollama() {
    local prompt="$1"  output="$2"  model="${3:-llava}"

    wp_step "Generating via Ollama  (model: ${model})..."

    if ! command -v ollama &>/dev/null; then
        wp_fail "Ollama not found"
        wp_info "Install: paru -S ollama"
        return 1
    fi

    if ! pgrep -x ollama &>/dev/null; then
        wp_step "Starting Ollama service..."
        systemctl --user start ollama 2>/dev/null || ollama serve &>/dev/null &
        sleep 2
    fi

    # Check if model available
    if ! ollama list 2>/dev/null | grep -q "$model"; then
        wp_warn "Model '${model}' not pulled — pulling now..."
        ollama pull "$model" 2>/dev/null || {
            wp_fail "Could not pull model: ${model}"
            return 1
        }
    fi

    # Generate via ollama API
    local response
    response="$(curl -fsSL --max-time 120 \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"${model}\", \"prompt\": \"Generate an abstract wallpaper: ${prompt}\", \"stream\": false}" \
        "http://localhost:11434/api/generate" 2>/dev/null || echo '{}')"

    wp_warn "Note: Ollama text models don't generate images directly"
    wp_info "Using prompt to generate gradient wallpaper instead..."

    # Extract key words for gradient generation
    local keywords
    keywords="$(printf '%s' "$prompt" | \
                sed 's/[^a-zA-Z ]//g' | \
                tr ' ' '\n' | grep -v '^$' | head -3 | tr '\n' ',')"

    _wp_load_sub "generate" 2>/dev/null || true
    ash_wp_generate \
        --type=gradient \
        --direction=diagonal \
        --colors="#cba6f7,#89b4fa" \
        --no-set

    return 0
}

_ai_stable_diffusion() {
    local prompt="$1"  output="$2"
    local sd_url="${SD_WEBUI_URL:-http://localhost:7860}"
    local negative="${3:-ugly,blurry,low quality}"
    local steps="${4:-30}"

    wp_step "Generating via Stable Diffusion  (${sd_url})..."

    # Check if A1111/Forge is running
    if ! curl -fsSL --max-time 5 "${sd_url}/sdapi/v1/progress" \
         &>/dev/null 2>&1; then
        wp_fail "Stable Diffusion WebUI not running at ${sd_url}"
        wp_info "Set SD_WEBUI_URL if using different port"
        return 1
    fi

    local payload
    payload="$(printf '{"prompt":"%s","negative_prompt":"%s","steps":%d,"width":1920,"height":1080,"cfg_scale":7}' \
        "$prompt" "$negative" "$steps")"

    _ai_spinner "Generating image (${steps} steps)..." &
    local spin_pid=$!
    trap 'kill "$spin_pid" 2>/dev/null' EXIT INT TERM

    local response
    response="$(curl -fsSL --max-time 180 \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "${sd_url}/sdapi/v1/txt2img" 2>/dev/null || echo '{}')"

    kill "$spin_pid" 2>/dev/null
    trap - EXIT INT TERM
    printf '\r  %-60s\n' ""

    # Decode base64 image
    local img_b64
    img_b64="$(printf '%s' "$response" | \
               python3 -c "import json,sys; d=json.load(sys.stdin); \
               print(d.get('images',[''])[0])" 2>/dev/null || echo '')"

    if [[ -z "$img_b64" ]]; then
        wp_fail "No image returned from Stable Diffusion"
        return 1
    fi

    printf '%s' "$img_b64" | base64 -d > "$output" 2>/dev/null
    wp_ok "Image generated"
}

_ai_openai_dalle() {
    local prompt="$1"  output="$2"
    local api_key="${OPENAI_API_KEY:-}"
    local model="${3:-dall-e-3}"
    local size="${4:-1792x1024}"

    [[ -z "$api_key" ]] && {
        wp_fail "OPENAI_API_KEY not set"
        wp_info "Set: export OPENAI_API_KEY=sk-..."
        return 1
    }

    wp_step "Generating via DALL-E  (model: ${model})..."

    local payload
    payload="$(printf '{"model":"%s","prompt":"%s","n":1,"size":"%s","quality":"hd"}' \
        "$model" "$prompt" "$size")"

    local response
    response="$(curl -fsSL --max-time 60 \
        -H "Authorization: Bearer ${api_key}" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.openai.com/v1/images/generations" 2>/dev/null || echo '{}')"

    local img_url
    img_url="$(printf '%s' "$response" | \
               python3 -c "import json,sys; d=json.load(sys.stdin); \
               print(d.get('data',[{}])[0].get('url',''))" 2>/dev/null || echo '')"

    [[ -z "$img_url" ]] && { wp_fail "DALL-E returned no image"; return 1; }

    wp_step "Downloading generated image..."
    curl -fsSL --max-time 60 -o "$output" "$img_url" 2>/dev/null && \
        wp_ok "DALL-E image downloaded"
}

ash_wp_generate_ai() {
    local provider="auto"
    local prompt="A beautiful abstract digital art wallpaper with vibrant colors and geometric shapes"
    local model=""
    local steps=30
    local set_after=1

    for arg in "${@:-}"; do
        case "$arg" in
            --provider=*)     provider="${arg#*=}"   ;;
            --prompt=*|-p=*)  prompt="${arg#*=}"     ;;
            --model=*)        model="${arg#*=}"      ;;
            --steps=*)        steps="${arg#*=}"      ;;
            --no-set)         set_after=0            ;;
            ollama|sd|dalle|openai) provider="$arg"  ;;
        esac
    done

    wp_section "🤖" "AI Wallpaper Generation" "$(_wpeach)"

    wp_kv "Provider" "$provider"
    wp_kv "Prompt"   "${prompt:0:60}..."

    local output_file
    output_file="${_WP_USER_DIR}/ai-$(date +%Y%m%d-%H%M%S).png"

    # Auto-detect provider
    if [[ "$provider" == "auto" ]]; then
        if [[ -n "${OPENAI_API_KEY:-}" ]]; then
            provider="dalle"
        elif curl -fsSL --max-time 3 \
            "http://localhost:7860/sdapi/v1/progress" &>/dev/null 2>&1; then
            provider="sd"
        elif command -v ollama &>/dev/null; then
            provider="ollama"
        else
            wp_fail "No AI provider found"
            wp_info "Options:"
            wp_info "  • Set OPENAI_API_KEY for DALL-E"
            wp_info "  • Run Stable Diffusion WebUI (port 7860)"
            wp_info "  • Install Ollama: paru -S ollama"
            return 1
        fi
        wp_kv "Auto-detected" "$provider"
    fi

    case "$provider" in
        ollama)
            _ai_ollama "$prompt" "$output_file" "${model:-llava}"
            ;;
        sd|stable-diffusion)
            _ai_stable_diffusion "$prompt" "$output_file" "" "$steps"
            ;;
        dalle|openai)
            _ai_openai_dalle "$prompt" "$output_file" \
                "${model:-dall-e-3}" "1792x1024"
            ;;
        *)
            wp_fail "Unknown provider: ${provider}"
            return 1
            ;;
    esac

    if [[ -f "$output_file" ]] && [[ -s "$output_file" ]]; then
        local size
        size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
        wp_ok "AI wallpaper generated"
        wp_kv "Output" "${output_file/#$HOME/~}"
        wp_kv "Size"   "$size"

        if [[ $set_after -eq 1 ]]; then
            wp_step "Applying AI wallpaper..."
            wp_set_backend "$output_file" && \
                wp_notify "🤖 AI Wallpaper" "${provider}: ${prompt:0:40}" "$output_file"
        fi
    else
        wp_fail "Generation produced no valid output"
        return 1
    fi

    printf '\n'
}
