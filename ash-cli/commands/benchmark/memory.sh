#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — benchmark memory                                  ║
# ║  Sourced by ash benchmark dispatcher; defines benchmark::memory.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_BENCHMARK_MEMORY_LOADED:-}" ]] && return 0
readonly _ASH_CMD_BENCHMARK_MEMORY_LOADED=1

benchmark::memory::help() {
    cat <<'EOF'
ash benchmark memory — memory benchmark

Usage:
  ash benchmark memory [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

benchmark::memory() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) benchmark::memory::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash benchmark memory: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "memory" in
        list|browse|search|trending)
            local reg_dir=""
            case "benchmark" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"benchmark","sub":"memory","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available benchmark (memory):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "benchmark memory: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash benchmark memory: requires an ID — usage: ash benchmark memory <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash benchmark memory: placeholder — would install/create benchmark item (not yet wired to store)" 
            ash_log_info "ash benchmark memory: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash benchmark memory: placeholder — would remove benchmark item" 
            ;;
        *)
            echo "ash benchmark memory: placeholder executed with args: $*" 
            ash_log_info "ash benchmark memory $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    benchmark::memory "$@"
fi
