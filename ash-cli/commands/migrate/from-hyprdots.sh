#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — migrate from-hyprdots                                  ║
# ║  Sourced by ash migrate dispatcher; defines migrate::from_hyprdots.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MIGRATE_FROM_HYPRDOTS_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MIGRATE_FROM_HYPRDOTS_LOADED=1

migrate::from_hyprdots::help() {
    cat <<'EOF'
ash migrate from-hyprdots — from hyprdots migrate

Usage:
  ash migrate from-hyprdots [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

migrate::from_hyprdots() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) migrate::from_hyprdots::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash migrate from-hyprdots: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "from-hyprdots" in
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
                    printf '{"group":"migrate","sub":"from-hyprdots","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available migrate (from-hyprdots):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "migrate from-hyprdots: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash migrate from-hyprdots: requires an ID — usage: ash migrate from-hyprdots <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash migrate from-hyprdots: placeholder — would install/create migrate item (not yet wired to store)" 
            ash_log_info "ash migrate from-hyprdots: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash migrate from-hyprdots: placeholder — would remove migrate item" 
            ;;
        *)
            echo "ash migrate from-hyprdots: placeholder executed with args: $*" 
            ash_log_info "ash migrate from-hyprdots $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    migrate::from_hyprdots "$@"
fi
