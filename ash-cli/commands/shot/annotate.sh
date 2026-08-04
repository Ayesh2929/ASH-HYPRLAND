#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot annotate                                            ║
# ║  Open screenshot in annotation tool: swappy / satty / gimp / krita              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_ANNOTATE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_ANNOTATE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_shot_annotate() {
    local input_file="${1:-}"
    local tool="auto"

    for arg in "${@:2}"; do
        case "$arg" in
            --tool=*) tool="${arg#*=}" ;;
            --swappy) tool="swappy"   ;;
            --satty)  tool="satty"    ;;
            --gimp)   tool="gimp"     ;;
        esac
    done

    shot_section "✏️ " "Screenshot Annotation" "$(_syellow)"

    # Pick file if not provided
    if [[ -z "$input_file" ]]; then
        if command -v fzf &>/dev/null; then
            input_file="$(find "$_SHOT_DIR" -name '*.png' -o -name '*.jpg' \
                         2>/dev/null | sort -r | head -50 | \
                fzf --prompt "  ✏️   Select screenshot: " \
                    --height=20 --border=rounded \
                    --preview="file {}" 2>/dev/null || echo '')"
        else
            input_file="$(find "$_SHOT_DIR" \( -name '*.png' -o -name '*.jpg' \) \
                         2>/dev/null | sort -r | head -1)"
        fi
    fi

    if [[ -z "$input_file" ]] || [[ ! -f "$input_file" ]]; then
        shot_fail "No valid file selected for annotation"
        shot_info "Usage: ash shot annotate [file]"
        return 1
    fi

    shot_kv "File" "$input_file"

    # Auto-detect best tool
    if [[ "$tool" == "auto" ]]; then
        if command -v satty  &>/dev/null; then tool="satty"
        elif command -v swappy &>/dev/null; then tool="swappy"
        elif command -v gimp   &>/dev/null; then tool="gimp"
        elif command -v krita  &>/dev/null; then tool="krita"
        else
            shot_fail "No annotation tool found"
            shot_info "Install: paru -S satty  (recommended)"
            shot_info "Alternative: paru -S swappy"
            return 1
        fi
    fi

    shot_kv "Tool" "$tool"
    shot_step "Opening in ${tool}..."

    case "$tool" in
        satty)
            satty --filename "$input_file" \
                  --output-filename "$(shot_filename "annotated" "png")" \
                  &>/dev/null &
            ;;
        swappy)
            swappy -f "$input_file" \
                   -o "$(shot_filename "annotated" "png")" \
                   &>/dev/null &
            ;;
        gimp)  gimp "$input_file" &>/dev/null & ;;
        krita) krita "$input_file" &>/dev/null & ;;
        *)
            shot_fail "Unknown tool: ${tool}"
            return 1
            ;;
    esac

    shot_ok "${tool} launched in background"

    printf '\n'
}
