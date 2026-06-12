#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SMART WORKSPACE PROFILES                      ║
# ║           Save/restore complete workspace environments                      ║
# ║           UNIQUE FEATURE: Profiles with apps, theme, layout, settings      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: workspace-profiles.sh [create|apply|list|delete|export|import] [name]
#
# EXAMPLES:
#   ash workspace profile create coding
#   ash workspace profile apply coding
#   ash workspace profile list
#   ash workspace profile delete gaming

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly PROFILES_DIR="${HOME}/.local/share/ash-dots/workspace-profiles"
readonly LOG_FILE="${CACHE_DIR}/logs/profiles.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 CREATE PROFILE
# ═══════════════════════════════════════════════════════════════════════════════

create_profile() {
    local name="$1"
    local profile_file="${PROFILES_DIR}/${name}.json"

    mkdir -p "${PROFILES_DIR}"

    info "Capturing workspace profile: ${name}"

    # Get current state
    local clients workspaces active_ws monitors

    clients=$(hyprctl clients -j 2>/dev/null || echo "[]")
    workspaces=$(hyprctl workspaces -j 2>/dev/null || echo "[]")
    active_ws=$(hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.id // 1' 2>/dev/null || echo "1")
    monitors=$(hyprctl monitors -j 2>/dev/null || echo "[]")

    # Get current theme
    local current_wallpaper=""
    [[ -f "${CACHE_DIR}/wallpaper/last" ]] && current_wallpaper=$(cat "${CACHE_DIR}/wallpaper/last")

    # Get current power profile
    local power_profile="balanced"
    [[ -f "${CACHE_DIR}/power-profile" ]] && power_profile=$(cat "${CACHE_DIR}/power-profile")

    # Get current font size (from kitty)
    local font_size="12"
    if [[ -f "${HOME}/.config/kitty/kitty.conf" ]]; then
        font_size=$(grep "^font_size" "${HOME}/.config/kitty/kitty.conf" 2>/dev/null \
            | awk '{print $2}' | head -1 || echo "12")
    fi

    # Export variables for Python heredoc
    export CLIENTS="${clients}"
    export WORKSPACES="${workspaces}"
    export ACTIVE_WS="${active_ws}"
    export CURRENT_WALLPAPER="${current_wallpaper}"
    export POWER_PROFILE="${power_profile}"
    export FONT_SIZE="${font_size}"
    export PROFILE_NAME="${name}"
    export PROFILE_FILE="${profile_file}"

    # Build profile JSON
    python3 - << 'PYEOF' 2>/dev/null
import json
import os
from datetime import datetime

clients = json.loads(os.environ.get("CLIENTS", "[]"))
workspaces = json.loads(os.environ.get("WORKSPACES", "[]"))

# Extract relevant client info
client_list = []
for c in clients:
    if c.get("class"):
        client_list.append({
            "class":      c.get("class", ""),
            "title":      c.get("title", ""),
            "workspace":  c.get("workspace", {}).get("id", 1),
            "floating":   c.get("floating", False),
            "fullscreen": c.get("fullscreen", False),
            "at":         c.get("at", [0, 0]),
            "size":       c.get("size", [800, 600])
        })

# Map classes to launch commands
APP_COMMANDS = {
    "kitty":        "kitty",
    "alacritty":    "alacritty",
    "wezterm":      "wezterm",
    "firefox":      "firefox",
    "chromium":     "chromium",
    "code":         "code",
    "code-oss":     "code",
    "nvim":         "kitty -e nvim",
    "nemo":         "nemo",
    "thunar":       "thunar",
    "discord":      "discord",
    "spotify":      "spotify",
    "steam":        "steam",
    "obsidian":     "obsidian",
    "slack":        "slack",
    "telegram-desktop": "telegram-desktop",
}

for c in client_list:
    cls = c.get("class", "").lower()
    c["command"] = APP_COMMANDS.get(cls, cls)

profile = {
    "name":             os.environ.get("PROFILE_NAME", ""),
    "created":          datetime.now().isoformat(),
    "active_workspace": int(os.environ.get("ACTIVE_WS", "1")),
    "wallpaper":        os.environ.get("CURRENT_WALLPAPER", ""),
    "power_profile":    os.environ.get("POWER_PROFILE", "balanced"),
    "font_size":        float(os.environ.get("FONT_SIZE", "12")),
    "clients":          client_list,
    "settings": {
        "animations":  True,
        "blur":        True,
        "notifications": True,
        "idle_inhibit": False,
    }
}

profile_file = os.environ.get("PROFILE_FILE", "")
with open(profile_file, "w") as f:
    json.dump(profile, f, indent=2)

print(f"  Profile saved: {profile_file}")
print(f"  Apps captured: {len(client_list)}")
PYEOF
    if [[ $? -ne 0 ]]; then
        warn "Python3 required for profile creation"
        return 1
    fi

    ok "Profile '${name}' created with $(echo "${clients}" | jq 'length' 2>/dev/null || echo '?') apps"
    log "INFO" "Profile created: ${name}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ▶️ APPLY PROFILE
# ═══════════════════════════════════════════════════════════════════════════════

apply_profile() {
    local name="$1"
    local profile_file="${PROFILES_DIR}/${name}.json"

    if [[ ! -f "${profile_file}" ]]; then
        warn "Profile not found: ${name}"
        list_profiles
        return 1
    fi

    info "Applying workspace profile: ${name}"

    # Read profile
    local wallpaper power_profile font_size active_ws
    wallpaper=$(jq -r '.wallpaper // ""' "${profile_file}" 2>/dev/null)
    power_profile=$(jq -r '.power_profile // "balanced"' "${profile_file}" 2>/dev/null)
    font_size=$(jq -r '.font_size // 12' "${profile_file}" 2>/dev/null)
    active_ws=$(jq -r '.active_workspace // 1' "${profile_file}" 2>/dev/null)

    # ── Apply wallpaper ───────────────────────────────────────────────────────
    if [[ -n "${wallpaper}" ]] && [[ -f "${wallpaper}" ]]; then
        info "Setting wallpaper..."
        "${HOME}/.config/hypr/scripts/theme/theme-engine.sh" "${wallpaper}" apply \
            &>/dev/null & disown
        ok "Wallpaper: $(basename "${wallpaper}")"
    fi

    # ── Apply power profile ───────────────────────────────────────────────────
    info "Setting power profile: ${power_profile}"
    "${HOME}/.config/hypr/scripts/system/power-profile.sh" "${power_profile}" \
        &>/dev/null || true
    ok "Power: ${power_profile}"

    # ── Apply font size to Kitty ──────────────────────────────────────────────
    if [[ -n "${font_size}" ]]; then
        info "Setting font size: ${font_size}"
        # Update kitty if running
        pgrep -x kitty &>/dev/null && \
            kitty @ --to unix:/tmp/kitty set-font-size "${font_size}" \
            2>/dev/null || true
        ok "Font size: ${font_size}"
    fi

    # ── Launch apps in correct workspaces ─────────────────────────────────────
    info "Launching apps..."
    local launched=0

    while IFS= read -r client; do
        local class command workspace floating
        class=$(echo "${client}" | jq -r '.class // ""')
        command=$(echo "${client}" | jq -r '.command // .class')
        workspace=$(echo "${client}" | jq -r '.workspace // 1')
        floating=$(echo "${client}" | jq -r '.floating // false')

        [[ -z "${command}" ]] && continue

        # Check if app already running
        if pgrep -x "${class}" &>/dev/null; then
            # Move existing window to correct workspace
            hyprctl dispatch movetoworkspace "${workspace},class:${class}" \
                2>/dev/null || true
        else
            # Launch app in workspace
            local rule="[workspace ${workspace} silent]"
            [[ "${floating}" == "true" ]] && rule="[workspace ${workspace} float silent]"

            if command -v "${command%% *}" &>/dev/null; then
                hyprctl dispatch exec "${rule} ${command}" 2>/dev/null || true
                ((launched++)) || true
                sleep 0.1
            fi
        fi
    done < <(jq -c '.clients[]' "${profile_file}" 2>/dev/null)

    ok "Launched ${launched} apps"

    # ── Switch to active workspace ────────────────────────────────────────────
    sleep 0.5
    hyprctl dispatch workspace "${active_ws}" 2>/dev/null || true
    ok "Active workspace: ${active_ws}"

    # ── Apply settings ────────────────────────────────────────────────────────
    local animations
    animations=$(jq -r '.settings.animations // true' "${profile_file}" 2>/dev/null)
    if [[ "${animations}" == "false" ]]; then
        hyprctl keyword animations:enabled false 2>/dev/null || true
    fi

    local idle_inhibit
    idle_inhibit=$(jq -r '.settings.idle_inhibit // false' "${profile_file}" 2>/dev/null)
    if [[ "${idle_inhibit}" == "true" ]]; then
        "${HOME}/.config/hypr/scripts/system/idle-inhibit.sh" enable \
            2>/dev/null || true
    fi

    notify-send "📁 Profile Applied" \
        "'${name}' workspace profile loaded" \
        --app-name="ASH Workspace" \
        --expire-time=3000 \
        2>/dev/null || true

    ok "Profile '${name}' applied!"
    log "INFO" "Profile applied: ${name}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LIST PROFILES
# ═══════════════════════════════════════════════════════════════════════════════

list_profiles() {
    if [[ ! -d "${PROFILES_DIR}" ]] || \
       [[ -z "$(ls "${PROFILES_DIR}"/*.json 2>/dev/null)" ]]; then
        echo "  No profiles saved yet"
        echo "  Create one: ash workspace profile create coding"
        return 0
    fi

    echo ""
    echo -e "  \033[1m\033[95m📁 Workspace Profiles:\033[0m"
    echo ""

    for profile_file in "${PROFILES_DIR}"/*.json; do
        local name apps created
        name=$(basename "${profile_file}" .json)
        apps=$(jq '.clients | length' "${profile_file}" 2>/dev/null || echo "?")
        created=$(jq -r '.created // ""' "${profile_file}" 2>/dev/null | cut -dT -f1)

        printf "  \033[96m%-20s\033[0m  %s apps  created: %s\n" \
            "${name}" "${apps}" "${created}"
    done
    echo ""

    # Rofi picker if available and no args
    if command -v rofi &>/dev/null; then
        local selected
        selected=$(ls "${PROFILES_DIR}"/*.json 2>/dev/null \
            | xargs -I{} basename {} .json \
            | rofi -dmenu -i \
                -p "📁 Apply Profile" \
                -theme-str 'window { width: 400px; } listview { lines: 8; }' \
                2>/dev/null) || return 0
        [[ -n "${selected}" ]] && apply_profile "${selected}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🗑️ DELETE PROFILE
# ═══════════════════════════════════════════════════════════════════════════════

delete_profile() {
    local name="$1"
    local profile_file="${PROFILES_DIR}/${name}.json"

    if [[ ! -f "${profile_file}" ]]; then
        warn "Profile not found: ${name}"
        return 1
    fi

    rm -f "${profile_file}"
    ok "Profile deleted: ${name}"
    log "INFO" "Profile deleted: ${name}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 BUILT-IN PROFILES
# ═══════════════════════════════════════════════════════════════════════════════

create_builtin_profiles() {
    mkdir -p "${PROFILES_DIR}"

    # ── Coding Profile ────────────────────────────────────────────────────────
    cat > "${PROFILES_DIR}/coding.json" << 'EOF'
{
  "name": "coding",
  "created": "builtin",
  "active_workspace": 1,
  "wallpaper": "",
  "power_profile": "performance",
  "font_size": 11,
  "clients": [
    {"class": "kitty",   "command": "kitty", "workspace": 1, "floating": false},
    {"class": "firefox", "command": "firefox", "workspace": 2, "floating": false},
    {"class": "kitty",   "command": "kitty -e lazygit", "workspace": 3, "floating": false}
  ],
  "settings": {
    "animations": true,
    "blur": true,
    "notifications": true,
    "idle_inhibit": false
  }
}
EOF

    # ── Gaming Profile ────────────────────────────────────────────────────────
    cat > "${PROFILES_DIR}/gaming.json" << 'EOF'
{
  "name": "gaming",
  "created": "builtin",
  "active_workspace": 8,
  "wallpaper": "",
  "power_profile": "performance",
  "font_size": 12,
  "clients": [
    {"class": "steam", "command": "steam", "workspace": 8, "floating": false}
  ],
  "settings": {
    "animations": false,
    "blur": false,
    "notifications": false,
    "idle_inhibit": true
  }
}
EOF

    # ── Meeting Profile ───────────────────────────────────────────────────────
    cat > "${PROFILES_DIR}/meeting.json" << 'EOF'
{
  "name": "meeting",
  "created": "builtin",
  "active_workspace": 1,
  "wallpaper": "",
  "power_profile": "balanced",
  "font_size": 14,
  "clients": [
    {"class": "firefox", "command": "firefox", "workspace": 1, "floating": false}
  ],
  "settings": {
    "animations": true,
    "blur": false,
    "notifications": false,
    "idle_inhibit": true
  }
}
EOF

    ok "Built-in profiles created: coding, gaming, meeting"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-list}"
    local name="${2:-}"

    mkdir -p "${PROFILES_DIR}" "${CACHE_DIR}/logs"

    # Install built-in profiles on first run
    if [[ ! -f "${PROFILES_DIR}/coding.json" ]]; then
        create_builtin_profiles
    fi

    case "${action}" in
        create | save | c)
            [[ -z "${name}" ]] && { warn "Usage: workspace-profiles.sh create NAME"; exit 1; }
            create_profile "${name}"
            ;;
        apply | load | a)
            if [[ -z "${name}" ]]; then
                list_profiles  # Shows Rofi picker
            else
                apply_profile "${name}"
            fi
            ;;
        list | ls | l)
            list_profiles
            ;;
        delete | remove | rm)
            [[ -z "${name}" ]] && { warn "Usage: workspace-profiles.sh delete NAME"; exit 1; }
            delete_profile "${name}"
            ;;
        init | builtin)
            create_builtin_profiles
            ;;
        *)
            echo "Usage: workspace-profiles.sh [create|apply|list|delete|init] [name]"
            echo ""
            echo "  create NAME   → Save current workspace as profile"
            echo "  apply NAME    → Restore workspace profile"
            echo "  list          → Show all profiles (Rofi picker)"
            echo "  delete NAME   → Remove profile"
            echo "  init          → Create built-in profiles (coding/gaming/meeting)"
            exit 1
            ;;
    esac
}

main "$@"