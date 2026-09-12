#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  📦 ASH DEPENDENCY CHECKER — capability-based, distro-aware resolution        ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Key idea: never depend on a *package name*, depend on a *capability*.        ║
# ║    capability "screenshot" ← grim | flameshot | spectacle | maim             ║
# ║    capability "notify"     ← dunst | mako | swaync | notify-send             ║
# ║                                                                               ║
# ║  That makes the dotfiles work unchanged on Arch, Fedora, Debian, openSUSE,    ║
# ║  Void, Gentoo, NixOS and Alpine, and lets the installer print the exact       ║
# ║  right package name for the detected distro.                                  ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_DEPENDENCY_CHECKER_LOADED:-}" ]] && return 0
readonly _ASH_DEPENDENCY_CHECKER_LOADED=1
readonly ASH_DEPCHECK_VERSION="5.0.0"

# capability -> "provider1 provider2 …"  (first available wins)
declare -gA ASH_CAPABILITY_PROVIDERS=(
    [terminal]="kitty foot alacritty wezterm ghostty"
    [launcher]="rofi rofi-wayland wofi fuzzel bemenu"
    [notify]="dunst mako swaync fnott"
    [notification-daemon]="dunst mako swaync fnott"
    [statusbar]="waybar eww ags"
    [lock]="hyprlock swaylock gtklock"
    [idle]="hypridle swayidle"
    [wallpaper]="swww hyprpaper swaybg mpvpaper"
    [screenshot]="grim flameshot spectacle maim scrot"
    [screenshot-region]="slurp flameshot"
    [screencast]="wf-recorder wl-screenrec gpu-screen-recorder"
    [clipboard]="wl-clipboard wl-cliphist cliphist"
    [clipboard-history]="cliphist clipman wl-clip-persist"
    [portal]="xdg-desktop-portal-hyprland xdg-desktop-portal-wlr"
    [auth-agent]="polkit-gnome polkit-kde-agent hyprpolkitagent mate-polkit lxqt-policykit"
    [keyring]="gnome-keyring kwalletd6 kwalletd5"
    [audio]="pipewire wireplumber pulseaudio"
    [audio-control]="wpctl pactl pamixer"
    [brightness]="brightnessctl light ddcutil"
    [network-manager]="NetworkManager nmcli iwd"
    [bluetooth]="bluez bluetoothctl bluetui"
    [font]="fc-list fc-match"
    [image]="magick convert imagemagick"
    [image-identify]="identify magick"
    [pdf]="zathura evince mupdf"
    [file-manager]="yazi nnn ranger thunar dolphin nautilus"
    [text-editor]="nvim vim helix micro code"
    [shell]="fish bash zsh"
    [prompt]="starship"
    [fetch]="fastfetch neofetch"
    [sysmon]="btop htop top"
    [audio-visual]="cava"
    [git-tui]="lazygit gitui"
    [jq]="jq"
    [json]="jq python3"
    [yaml]="yq python3"
    [japanese-input]="fcitx5 ibus"
    [font-emoji]="fc-list"
    [color-picker]="hyprpicker grabc"
    [ocr]="tesseract"
    [qr]="qrencode"
    [archive]="tar zip unzip 7z"
    [compression]="zstd xz gzip"
    [crypto]="openssl gpg age"
    [curl]="curl wget"
    [gpu-nvidia]="nvidia-smi"
    [gpu-amd]="radeontop rocm-smi"
    [gamemode]="gamemode"
    [mangohud]="mangohud"
    [hyprland]="Hyprland hyprctl"
)

# distro key -> "provider:packagename" overrides, used only for reporting.
declare -gA ASH_PACKAGE_MAP=()

# ── Distro / platform detection ──────────────────────────────────────────────
ash_dep_detect_distro() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        local id="" id_like=""
        id="$(awk -F= '/^ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null)"
        id_like="$(awk -F= '/^ID_LIKE=/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null)"

        case "$id" in
            arch|manjaro|endeavouros|cachyos|garuda) printf 'arch'; return ;;
            fedora|rhel|centos|rocky|almalinux)      printf 'fedora'; return ;;
            debian|ubuntu|pop|linuxmint|kali|elementary|zorin) printf 'debian'; return ;;
            opensuse*|sles)                           printf 'opensuse'; return ;;
            void)                                     printf 'void'; return ;;
            gentoo)                                   printf 'gentoo'; return ;;
            alpine)                                   printf 'alpine'; return ;;
            nixos)                                    printf 'nixos'; return ;;
        esac

        case "$id_like" in
            *arch*)   printf 'arch';   return ;;
            *fedora*) printf 'fedora'; return ;;
            *debian*|*ubuntu*) printf 'debian'; return ;;
            *suse*)   printf 'opensuse'; return ;;
        esac
    fi

    if command -v pacman >/dev/null 2>&1; then printf 'arch'
    elif command -v dnf >/dev/null 2>&1; then printf 'fedora'
    elif command -v apt >/dev/null 2>&1;  then printf 'debian'
    elif command -v zypper >/dev/null 2>&1; then printf 'opensuse'
    elif command -v xbps-install >/dev/null 2>&1; then printf 'void'
    elif command -v emerge >/dev/null 2>&1; then printf 'gentoo'
    elif command -v apk >/dev/null 2>&1; then printf 'alpine'
    elif command -v nix-env >/dev/null 2>&1; then printf 'nixos'
    else printf 'unknown'
    fi
}

ash_dep_package_manager() {
    case "$(ash_dep_detect_distro)" in
        arch)     printf 'pacman' ;;
        fedora)   printf 'dnf' ;;
        debian)   printf 'apt' ;;
        opensuse) printf 'zypper' ;;
        void)     printf 'xbps' ;;
        gentoo)   printf 'emerge' ;;
        alpine)   printf 'apk' ;;
        nixos)    printf 'nix' ;;
        *)        printf 'unknown' ;;
    esac
}

# Prints the exact install command for the current distro.
ash_dep_install_hint() {
    local -a packages=("$@")
    (( ${#packages[@]} == 0 )) && return 0

    local joined="${packages[*]}"
    case "$(ash_dep_detect_distro)" in
        arch)     printf 'sudo pacman -S --needed %s' "$joined" ;;
        fedora)   printf 'sudo dnf install %s' "$joined" ;;
        debian)   printf 'sudo apt install %s' "$joined" ;;
        opensuse) printf 'sudo zypper install %s' "$joined" ;;
        void)     printf 'sudo xbps-install -S %s' "$joined" ;;
        gentoo)   printf 'sudo emerge --ask %s' "$joined" ;;
        alpine)   printf 'sudo apk add %s' "$joined" ;;
        nixos)    printf 'nix-env -iA %s   # or add to configuration.nix' "$joined" ;;
        *)        printf 'install: %s' "$joined" ;;
    esac
}

# ── Capability probing ───────────────────────────────────────────────────────
ash_dep_has_command() { command -v "${1:-}" >/dev/null 2>&1; }

# Returns the first provider found for a capability (empty when unsatisfied).
ash_dep_resolve_capability() {
    local capability="$1"
    local providers="${ASH_CAPABILITY_PROVIDERS[$capability]:-}"
    [[ -z "$providers" ]] && return 1

    local p
    for p in $providers; do
        if command -v "$p" >/dev/null 2>&1; then printf '%s' "$p"; return 0; fi
    done
    return 1
}

ash_dep_has_capability() {
    local capability="$1"
    # Hyprland-specific capabilities may need a running compositor
    if [[ "$capability" == "hyprland" ]]; then
        command -v Hyprland >/dev/null 2>&1 || command -v hyprctl >/dev/null 2>&1
        return $?
    fi
    ash_dep_resolve_capability "$capability" >/dev/null 2>&1
}

# ── Requirement specs ────────────────────────────────────────────────────────
# A requirement string is:  <kind>:<name>[:<fallback>]
#   cmd:grim                     a command must exist
#   cap:screenshot               any provider of the capability must exist
#   file:/etc/xdg/foo.conf       a path must exist
#   version:bash:5.0             a command's --version must be >= 5.0
ash_dep_check_requirement() {
    local spec="$1"
    local kind="${spec%%:*}"
    local rest="${spec#*:}"
    local name="${rest%%:*}"
    local fallback=""
    [[ "$rest" == *:* ]] && fallback="${rest#*:}"

    case "$kind" in
        cmd)
            if ash_dep_has_command "$name"; then return 0; fi
            if [[ -n "$fallback" ]]; then
                local f
                for f in $fallback; do ash_dep_has_command "$f" && return 0; done
            fi
            return 1
            ;;
        cap)
            if ash_dep_has_capability "$name"; then return 0; fi
            if [[ -n "$fallback" ]]; then
                local alt
                for alt in $fallback; do ash_dep_has_capability "$alt" && return 0; done
            fi
            return 1
            ;;
        file)
            [[ -e "$name" ]] && return 0
            return 1
            ;;
        version)
            local required="$fallback"
            ash_dep_has_command "$name" || return 1
            local actual
            actual="$("$name" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"
            [[ -z "$actual" ]] && return 0
            ash_semver_gte "$actual" "$required" 2>/dev/null && return 0
            return 1
            ;;
        *)
            # Bare name → treat as a command
            ash_dep_has_command "$kind"
            ;;
    esac
}

# ash_dep_check_set <spec…>  →  0 when every requirement is met
ash_dep_check_set() {
    local missing=0 spec
    for spec in "$@"; do
        ash_dep_check_requirement "$spec" || { (( missing += 1 )); }
    done
    return $(( missing > 0 ? 1 : 0 ))
}

# ── Reporting ────────────────────────────────────────────────────────────────
# ash_dep_report <spec…>   prints a colourised satisfaction table
ash_dep_report() {
    local ok=0 missing=0 spec

    printf '  distro   : %s (%s)\n' "$(ash_dep_detect_distro)" "$(ash_dep_package_manager)"
    printf '  %s\n' "$(printf '─%.0s' $(seq 1 56))"

    local -a missing_packages=()

    for spec in "$@"; do
        local kind="${spec%%:*}" display="${spec#*:}"
        local satisfied=0 resolved=""

        if ash_dep_check_requirement "$spec"; then
            satisfied=1
            if [[ "$kind" == "cap" ]]; then
                resolved="$(ash_dep_resolve_capability "${display%%:*}" || true)"
            elif [[ "$kind" == "cmd" ]]; then
                resolved="$(command -v "${display%%:*}" 2>/dev/null || true)"
            fi
        fi

        if (( satisfied == 1 )); then
            (( ok += 1 ))
            printf '  ✓ %-32s %s\n' "$spec" "${resolved:+→ $resolved}"
        else
            (( missing += 1 ))
            printf '  ✗ %-32s missing\n' "$spec"
            if [[ "$kind" == "cmd" ]]; then
                missing_packages+=("${display%%:*}")
            fi
        fi
    done

    printf '  %s\n' "$(printf '─%.0s' $(seq 1 56))"
    printf '  %d satisfied, %d missing\n' "$ok" "$missing"

    if (( ${#missing_packages[@]} > 0 )); then
        printf '\n  Install with:\n    %s\n' "$(ash_dep_install_hint "${missing_packages[@]}")"
    fi

    return $(( missing > 0 ? 1 : 0 ))
}

# Prints the package names a capability can be satisfied by on this distro.
ash_dep_package_for_capability() {
    local capability="$1"
    local providers="${ASH_CAPABILITY_PROVIDERS[$capability]:-}"
    [[ -z "$providers" ]] && return 1

    local distro; distro="$(ash_dep_detect_distro)"
    local p
    for p in $providers; do
        local key="${distro}:${p}"
        if [[ -n "${ASH_PACKAGE_MAP[$key]:-}" ]]; then
            printf '%s\n' "${ASH_PACKAGE_MAP[$key]}"
        else
            printf '%s\n' "$p"
        fi
    done
}

# ── Tiered sets used by the installer and doctor ─────────────────────────────
ash_dep_critical() {
    printf '%s\n' \
        "cmd:Hyprland" \
        "cmd:hyprctl" \
        "cmd:bash:5.0" \
        "cmd:git" \
        "cmd:jq"
}

ash_dep_recommended() {
    printf '%s\n' \
        "cap:terminal" \
        "cap:launcher" \
        "cap:notify" \
        "cap:statusbar" \
        "cap:lock" \
        "cap:idle" \
        "cap:wallpaper" \
        "cap:portal" \
        "cap:audio-control" \
        "cmd:fish" \
        "cmd:nvim" \
        "cmd:fc-list"
}

ash_dep_optional() {
    printf '%s\n' \
        "cap:screenshot" \
        "cap:screencast" \
        "cap:clipboard" \
        "cap:brightness" \
        "cap:bluetooth" \
        "cap:color-picker" \
        "cap:ocr" \
        "cap:file-manager" \
        "cap:sysmon" \
        "cap:audio-visual" \
        "cap:git-tui" \
        "cmd:lazygit" \
        "cmd:cava"
}

# ── Auto-install (used by `ash install --auto-deps`) ─────────────────────────
ash_dep_install_missing() {
    local dry_run="${1:-0}"
    local -a to_install=()
    local spec

    while IFS= read -r spec || [[ -n "$spec" ]]; do
        [[ -z "$spec" ]] && continue
        ash_dep_check_requirement "$spec" && continue
        local name="${spec#*:}"; name="${name%%:*}"
        to_install+=("$name")
    done < <( { ash_dep_critical; ash_dep_recommended; } )

    (( ${#to_install[@]} == 0 )) && { printf '  ✓ all required packages present\n'; return 0; }

    # De-duplicate
    local -a unique
    mapfile -t unique < <(printf '%s\n' "${to_install[@]}" | LC_ALL=C sort -u)

    local cmd; cmd="$(ash_dep_install_hint "${unique[@]}")"
    printf '  Packages to install (%d):\n' "${#unique[@]}"
    printf '    %s\n' "${unique[@]}"
    printf '\n  Command:\n    %s\n' "$cmd"

    if [[ "$dry_run" == "1" ]]; then
        printf '\n  (dry-run — nothing installed)\n'
        return 0
    fi

    ash_log_info "installing ${#unique[@]} package(s)…" 2>/dev/null || true
    # shellcheck disable=SC2086
    eval "$cmd" || {
        ash_log_error "package installation failed" 2>/dev/null || true
        return 1
    }
    return 0
}

# ── Environment sanity ───────────────────────────────────────────────────────
ash_dep_environment_report() {
    printf '  platform    : %s\n' "$(uname -srm 2>/dev/null || echo unknown)"
    printf '  distro      : %s\n' "$(ash_dep_detect_distro)"
    printf '  pkg manager : %s\n' "$(ash_dep_package_manager)"
    printf '  session     : %s\n' "${XDG_SESSION_TYPE:-unknown}"
    printf '  desktop     : %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
    printf '  wayland     : %s\n' "${WAYLAND_DISPLAY:-not set}"
    printf '  shell       : %s\n' "${SHELL:-unknown}"
    printf '  bash        : %s\n' "${BASH_VERSION:-unknown}"
    printf '  cores       : %s\n' "$(nproc 2>/dev/null || echo '?')"
    printf '  memory      : %s\n' "$(awk '/MemTotal/ {printf "%.1f GiB", $2/1048576}' /proc/meminfo 2>/dev/null || echo unknown)"

    if [[ -d /sys/class/power_supply ]] && ls /sys/class/power_supply/ 2>/dev/null | grep -qi '^BAT'; then
        printf '  chassis     : laptop (battery detected)\n'
    else
        printf '  chassis     : desktop\n'
    fi

    local gpu="unknown"
    if command -v lspci >/dev/null 2>&1; then
        if lspci 2>/dev/null | grep -qi 'nvidia'; then gpu="nvidia"
        elif lspci 2>/dev/null | grep -qiE 'amd|radeon'; then gpu="amd"
        elif lspci 2>/dev/null | grep -qi 'intel.*graphics'; then gpu="intel"; fi
    fi
    printf '  gpu         : %s\n' "$gpu"
}
