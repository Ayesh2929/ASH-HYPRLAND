#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — store upload                                  ║
# ║  Sourced by ash store dispatcher; defines store::upload.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_STORE_UPLOAD_LOADED:-}" ]] && return 0
readonly _ASH_CMD_STORE_UPLOAD_LOADED=1

store::upload::help() {
    cat <<'EOF'
ash store upload — upload store

Usage:
  ash store upload [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

store::upload() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) store::upload::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash store upload: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "upload" in
        list|browse|search|trending)
            local reg_dir=""
            case "store" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"store","sub":"upload","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available store (upload):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "store upload: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash store upload: requires an ID — usage: ash store upload <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash store upload: placeholder — would install/create store item (not yet wired to store)" 
            ash_log_info "ash store upload: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash store upload: placeholder — would remove store item" 
            ;;
        *)
            echo "ash store upload: placeholder executed with args: $*" 
            ash_log_info "ash store upload $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    store::upload "$@"
fi
