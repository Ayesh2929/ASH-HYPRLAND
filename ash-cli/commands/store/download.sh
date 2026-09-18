#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — store download                                  ║
# ║  Sourced by ash store dispatcher; defines store::download.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_STORE_DOWNLOAD_LOADED:-}" ]] && return 0
readonly _ASH_CMD_STORE_DOWNLOAD_LOADED=1

store::download::help() {
    cat <<'EOF'
ash store download — download store

Usage:
  ash store download [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

store::download() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) store::download::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash store download: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "download" in
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
                    printf '{"group":"store","sub":"download","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available store (download):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "store download: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash store download: requires an ID — usage: ash store download <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash store download: placeholder — would install/create store item (not yet wired to store)" 
            ash_log_info "ash store download: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash store download: placeholder — would remove store item" 
            ;;
        *)
            echo "ash store download: placeholder executed with args: $*" 
            ash_log_info "ash store download $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    store::download "$@"
fi
