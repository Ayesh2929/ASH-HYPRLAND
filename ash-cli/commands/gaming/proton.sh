#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  gaming proton                                            ║
# ║  Proton-GE management: list • install • set default • launch Windows games      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_GAMING_PROTON_LOADED:-}" == "1" ]] && return 0
readonly _ASH_GAMING_PROTON_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROTON PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_proton_find_dirs() {
    local -a dirs=()
    for d in \
        "${_GM_PROTON_DIR}" \
        "${_GM_STEAM_COMPAT_DIR}" \
        "${XDG_DATA_HOME:-$HOME/.local/share}/Steam/compatibilitytools.d" \
        "$HOME/.steam/root/compatibilitytools.d"; do
        [[ -d "$d" ]] && dirs+=("$d")
    done
    printf '%s\n' "${dirs[@]:-}"
}

_proton_list_installed() {
    local found=0

    while IFS= read -r proton_dir; do
        [[ -d "$proton_dir" ]] || continue

        while IFS= read -r entry; do
            [[ -d "$entry" ]] || continue
            local pname
            pname="$(basename "$entry")"
            [[ "$pname" =~ ^(GE-Proton|Proton|proton) ]] || continue

            local ver_file="${entry}/version"
            local ver="?"
            [[ -f "$ver_file" ]] && ver="$(cat "$ver_file" | head -1)"

            local size
            size="$(du -sh "$entry" 2>/dev/null | cut -f1)"

            # Determine type
            local type_badge
            if [[ "$pname" =~ GE ]]; then
                type_badge="$(gm_badge " GE " "$(_gpeach)")"
            elif [[ "$pname" =~ [Ww]ine ]]; then
                type_badge="$(gm_badge " WINE " "$(_gblue)")"
            else
                type_badge="$(gm_badge " STEAM " "$(_gteal)")"
            fi

            printf '  %s%s%s  %s%s%s  %s%s%s  %s%s%s\n' \
                "$(_gsky)$(_gbold)" "$pname" "$(_gr)" \
                "$(_gdim)" "v${ver}" "$(_gr)" \
                "" "$type_badge" "" \
                "$(_gdim)" "${size}" "$(_gr)"

            (( found++ )) || true
        done < <(find "$proton_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -rV)

    done < <(_proton_find_dirs)

    (( found == 0 )) && {
        gm_info "No Proton versions installed"
        gm_info "Install: ash gaming proton install  or  paru -S proton-ge-custom"
    }

    printf '\n  %s%d version(s) found%s\n' "$(_gdim)" "$found" "$(_gr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROTON-GE INSTALLER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_proton_install_ge() {
    local version="${1:-latest}"
    local install_dir="${_GM_STEAM_COMPAT_DIR}"
    mkdir -p "$install_dir" 2>/dev/null || true

    # Get latest release from GitHub API
    gm_step "Fetching Proton-GE releases..."

    local api_url="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
    local release_url

    if [[ "$version" == "latest" ]]; then
        release_url="${api_url}/latest"
    else
        release_url="${api_url}/tags/${version}"
    fi

    local release_json
    release_json="$(curl -fsSL --max-time 15 "$release_url" 2>/dev/null || echo '{}')"

    if [[ -z "$release_json" ]] || [[ "$release_json" == "{}" ]]; then
        gm_fail "Could not fetch release info from GitHub"
        gm_info "Try: paru -S proton-ge-custom"
        return 1
    fi

    local tar_url tag_name
    tar_url="$(printf '%s' "$release_json" | \
               python3 -c "
import json,sys
d=json.load(sys.stdin)
assets=d.get('assets',[])
for a in assets:
    if a.get('name','').endswith('.tar.gz'):
        print(a.get('browser_download_url',''))
        break
" 2>/dev/null || echo '')"

    tag_name="$(printf '%s' "$release_json" | \
                python3 -c "import json,sys; print(json.load(sys.stdin).get('tag_name','?'))" \
                2>/dev/null || echo '?')"

    if [[ -z "$tar_url" ]]; then
        gm_fail "Could not find tarball URL"
        return 1
    fi

    gm_kv "Version"  "$tag_name"
    gm_kv "URL"      "${tar_url##*/}"
    gm_kv "Dest"     "${install_dir/#$HOME/~}"

    local tmp_file="/tmp/proton-ge-$$.tar.gz"
    gm_step "Downloading Proton-GE ${tag_name}..."

    local spin_pid
    (
        local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
        local i=0
        while true; do
            printf '\r  %s%s%s  Downloading...' \
                "$(_gpeach)" "${frames[$i]}" "$(_gr)"
            i=$(( (i+1) % ${#frames[@]} ))
            sleep 0.1
        done
    ) &
    spin_pid=$!
    trap 'kill "$spin_pid" 2>/dev/null' EXIT INT TERM

    if curl -fsSL --progress-bar \
        "$tar_url" -o "$tmp_file" 2>/dev/null; then
        kill "$spin_pid" 2>/dev/null || true
        trap - EXIT INT TERM
        printf '\r  %-60s\n' ""
        gm_ok "Download complete"
    else
        kill "$spin_pid" 2>/dev/null || true
        trap - EXIT INT TERM
        printf '\r  %-60s\n' ""
        gm_fail "Download failed"
        rm -f "$tmp_file"
        return 1
    fi

    gm_step "Extracting to ${install_dir}..."
    if tar xzf "$tmp_file" -C "$install_dir" 2>/dev/null; then
        gm_ok "Proton-GE ${tag_name} installed!"
        gm_notify "🍷 Proton-GE" "${tag_name} installed successfully"
    else
        gm_fail "Extraction failed"
        return 1
    fi

    rm -f "$tmp_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LAUNCH WITH PROTON
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_proton_launch() {
    local exe="$1"  proton_version="${2:-}"

    # Find Proton binary
    local proton_bin=""

    if [[ -n "$proton_version" ]]; then
        # Search in install dirs for specified version
        while IFS= read -r proton_dir; do
            local candidate="${proton_dir}/${proton_version}/proton"
            if [[ -x "$candidate" ]]; then
                proton_bin="$candidate"
                break
            fi
        done < <(_proton_find_dirs)
    else
        # Find newest installed Proton-GE
        while IFS= read -r proton_dir; do
            local newest
            newest="$(find "$proton_dir" -maxdepth 2 -name 'proton' -type f 2>/dev/null | \
                      sort -rV | head -1)"
            if [[ -n "$newest" ]] && [[ -x "$newest" ]]; then
                proton_bin="$newest"
                break
            fi
        done < <(_proton_find_dirs)
    fi

    if [[ -z "$proton_bin" ]]; then
        gm_fail "No Proton version found"
        gm_info "Install Proton-GE: ash gaming proton install"
        return 1
    fi

    gm_kv "Proton"  "$proton_bin"
    gm_kv "Game"    "$exe"

    # Set up Wine prefix
    local pfx_dir="${_GM_STATE_DIR}/prefixes/$(basename "$exe" .exe)"
    mkdir -p "$pfx_dir" 2>/dev/null || true
    gm_kv "Prefix"  "${pfx_dir/#$HOME/~}"

    gm_step "Launching via Proton..."
    PROTON_NO_ESYNC=0 \
    PROTON_NO_FSYNC=0 \
    STEAM_COMPAT_DATA_PATH="$pfx_dir" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="" \
        "$proton_bin" run "$exe" 2>/dev/null &

    gm_ok "Launched  (PID: $!)"
    gm_notify "🍷 Proton" "Launching: $(basename "$exe")"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_gaming_proton() {
    local action="list"
    local version="latest"
    local target_exe=""
    local proton_version=""

    for arg in "${@:-}"; do
        case "$arg" in
            list|-l)        action="list"    ;;
            install|-i)     action="install" ;;
            run|-r)         action="run"     ;;
            info|status)    action="info"    ;;
            remove|delete)  action="remove"  ;;
            --version=*|-v=*) version="${arg#*=}" ;;
            --proton=*)     proton_version="${arg#*=}" ;;
            *.exe|*.EXE)    target_exe="$arg"; action="run" ;;
            GE-Proton*|Proton*) proton_version="$arg" ;;
        esac
    done

    gm_section "🍷" "Proton / WINE" "$(_glav)"

    case "$action" in
        list)
            gm_kv "Search dirs" "$(< <(_proton_find_dirs | head -3 | tr '\n' '  ') cat)"
            printf '\n  %sInstalled Proton versions:%s\n\n' "$(_gdim)" "$(_gr)"
            _proton_list_installed
            ;;

        install)
            gm_kv "Version"  "$version"
            _proton_install_ge "$version"
            ;;

        run)
            if [[ -z "$target_exe" ]]; then
                printf '  %sEXE file path: %s' "$(_gyellow)" "$(_gr)"
                read -r target_exe
            fi
            [[ -z "$target_exe" ]] && { gm_info "No executable specified"; return 0; }
            _proton_launch "$target_exe" "$proton_version"
            ;;

        info)
            gm_section "ℹ️ " "Proton Info" "$(_gdim)"
            gm_kv "Steam compat dir" \
                "${_GM_STEAM_COMPAT_DIR/#$HOME/~}"

            # Check for protonup-qt
            if command -v protonup &>/dev/null; then
                gm_kv "ProtonUp-Qt"   "installed  (GUI manager)"
            fi

            # WINE version if available
            if command -v wine &>/dev/null; then
                local wine_ver
                wine_ver="$(wine --version 2>/dev/null | head -1 || echo '?')"
                gm_kv "System WINE"  "$wine_ver"
            fi
            ;;

        remove)
            gm_section "🗑️ " "Remove Proton" "$(_gred)"
            printf '  %sProton version to remove: %s' "$(_gyellow)" "$(_gr)"
            local rm_version; read -r rm_version
            [[ -z "$rm_version" ]] && { gm_info "Cancelled"; return 0; }

            local removed=0
            while IFS= read -r proton_dir; do
                local target="${proton_dir}/${rm_version}"
                if [[ -d "$target" ]]; then
                    printf '  %sRemove %s? [y/N] %s' \
                        "$(_gyellow)" "$target" "$(_gr)"
                    local ans; read -r ans
                    if [[ "${ans,,}" == "y" ]]; then
                        rm -rf "$target" && gm_ok "Removed: ${rm_version}" && \
                            (( removed++ )) || true
                    fi
                fi
            done < <(_proton_find_dirs)

            (( removed == 0 )) && gm_info "Version not found: ${rm_version}"
            ;;
    esac

    printf '\n'
}
