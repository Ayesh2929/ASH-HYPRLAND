#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot ocr                                                 ║
# ║  Screenshot + OCR text extraction via tesseract with language selection         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_OCR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_OCR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_ocr_preprocess() {
    local input="$1"  output="$2"
    # Enhance for OCR: grayscale, sharpen, threshold
    if command -v magick &>/dev/null; then
        magick "$input" \
            -colorspace Gray \
            -sharpen 0x1 \
            -threshold 50% \
            "$output" 2>/dev/null
    elif command -v convert &>/dev/null; then
        convert "$input" \
            -colorspace Gray \
            -sharpen 0x1 \
            "$output" 2>/dev/null
    else
        cp "$input" "$output"
    fi
}

ash_shot_ocr() {
    local lang="eng"
    local mode="area"       # area | full | clipboard
    local output_mode="stdout"  # stdout | file | clipboard

    for arg in "${@:-}"; do
        case "$arg" in
            --lang=*)         lang="${arg#*=}"     ;;
            --full|-f)        mode="full"          ;;
            --clipboard)      output_mode="clipboard" ;;
            --file)           output_mode="file"   ;;
        esac
    done

    shot_section "🔤" "Screenshot OCR" "$(_steal)"

    shot_require tesseract tesseract || return 1

    # List available languages
    local available_langs
    available_langs="$(tesseract --list-langs 2>/dev/null | tail -n +2 | tr '\n' ' ')"
    shot_kv "Language"         "$lang"
    shot_kv "Available langs"  "${available_langs:-?}"
    shot_kv "Output"           "$output_mode"

    printf '\n'

    # Capture
    local tmp_img="${_SHOT_TMP}/ocr-raw-$$.png"
    local tmp_processed="${_SHOT_TMP}/ocr-proc-$$.png"

    case "$mode" in
        full)
            shot_step "Capturing full screen for OCR..."
            if command -v grim &>/dev/null; then
                grim "$tmp_img" 2>/dev/null || { shot_fail "Capture failed"; return 1; }
            fi
            ;;
        area|*)
            shot_info "Select area to extract text from..."
            if command -v slurp &>/dev/null && command -v grim &>/dev/null; then
                local geom
                geom="$(slurp \
                    -b "1e1e2eCC" -c "a6e3a1FF" -s "a6e3a140" -w 2 \
                    2>/dev/null)" || {
                    shot_info "Selection cancelled"
                    return 0
                }
                grim -g "$geom" "$tmp_img" 2>/dev/null || { shot_fail "Capture failed"; return 1; }
            else
                shot_fail "slurp + grim required for area OCR"
                return 1
            fi
            ;;
    esac

    # Preprocess for better OCR accuracy
    shot_step "Preprocessing image for OCR..."
    _ocr_preprocess "$tmp_img" "$tmp_processed"

    # Run tesseract
    shot_step "Extracting text..."
    local txt_output="${_SHOT_TMP}/ocr-result-$$"

    if ! tesseract "$tmp_processed" "$txt_output" -l "$lang" \
         --oem 1 --psm 3 quiet 2>/dev/null; then
        shot_fail "OCR extraction failed"
        rm -f "$tmp_img" "$tmp_processed" "${txt_output}.txt" 2>/dev/null
        return 1
    fi

    local extracted_text
    extracted_text="$(cat "${txt_output}.txt" 2>/dev/null | \
                      sed '/^[[:space:]]*$/d')"

    if [[ -z "$extracted_text" ]]; then
        shot_warn "No text detected in the selected region"
    else
        local line_count
        line_count="$(printf '%s' "$extracted_text" | wc -l)"
        local word_count
        word_count="$(printf '%s' "$extracted_text" | wc -w)"

        shot_ok "Text extracted"
        shot_kv "Lines" "$line_count"
        shot_kv "Words" "$word_count"

        # Display result
        shot_section "📄" "Extracted Text" "$(_sgreen)"
        printf '\n'
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
            printf '\033[38;2;205;214;244m'
        fi
        printf '%s' "$extracted_text" | sed 's/^/  /'
        printf '%s\n' "$(_sr)"

        # Output handling
        case "$output_mode" in
            clipboard)
                printf '%s' "$extracted_text" | wl-copy 2>/dev/null && \
                    shot_ok "Copied to clipboard" || \
                    shot_warn "wl-copy not available"
                ;;
            file)
                local out_file="${_SHOT_DIR}/ocr-$(date +%Y%m%d-%H%M%S).txt"
                printf '%s\n' "$extracted_text" > "$out_file"
                shot_ok "Saved to: ${out_file}"
                ;;
            stdout|*)
                # Already displayed above
                ;;
        esac
    fi

    # Cleanup
    rm -f "$tmp_img" "$tmp_processed" "${txt_output}.txt" 2>/dev/null

    shot_notify "🔤 OCR Complete" \
        "${word_count:-0} words extracted" ""

    printf '\n'
}
