#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — migrate from-ml4w                                  ║
# ║  Sourced by ash migrate dispatcher; defines migrate::from_ml4w.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MIGRATE_FROM_ML4W_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MIGRATE_FROM_ML4W_LOADED=1

migrate::from_ml4w::help() {
    cat <<'EOF'
ash migrate from-ml4w — from ml4w migrate

Usage:
  ash migrate from-ml4w [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

migrate::from_ml4w() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) migrate::from_ml4w::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash migrate from-ml4w: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "from-ml4w" in
        list|browse|search|trending)
            local reg_dir=""
            case "migrate" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"migrate","sub":"from-ml4w","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available migrate (from-ml4w):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "migrate from-ml4w: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash migrate from-ml4w: requires an ID — usage: ash migrate from-ml4w <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash migrate from-ml4w: placeholder — would install/create migrate item (not yet wired to store)" 
            ash_log_info "ash migrate from-ml4w: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash migrate from-ml4w: placeholder — would remove migrate item" 
            ;;
        *)
            echo "ash migrate from-ml4w: placeholder executed with args: $*" 
            ash_log_info "ash migrate from-ml4w $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    migrate::from_ml4w "$@"
fi
