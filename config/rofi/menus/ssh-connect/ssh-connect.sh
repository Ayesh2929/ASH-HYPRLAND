#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — SSH Connection Manager Script                     ║
# ║                                                                              ║
# ║  Full SSH host management: parse ~/.ssh/config, known_hosts, custom hosts. ║
# ║  Connect, SFTP, tunnel, copy-id, VS Code remote, mosh, ping and manage.    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly SSH_CONFIG="${HOME}/.ssh/config"
readonly KNOWN_HOSTS="${HOME}/.ssh/known_hosts"
readonly CUSTOM_HOSTS="${HOME}/.config/ash-dotfiles/ash-cli/data/ssh-hosts.conf"
readonly FAVORITES_FILE="${HOME}/.local/share/ash-dotfiles/ssh-favorites.txt"
readonly HISTORY_FILE="${HOME}/.local/share/ash-dotfiles/ssh-history.txt"
readonly PING_TIMEOUT=2        # Seconds for reachability check
readonly PING_CACHE_AGE=60     # Seconds to cache ping results
readonly PING_CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-ssh-ping"
readonly MAX_HISTORY=30
readonly MAX_HOSTS=100

# ══════════════════════════════════════════════════════════════════════════════
# §02  HOST DISCOVERY & PARSING
# ══════════════════════════════════════════════════════════════════════════════

# Parse ~/.ssh/config for Host entries
parse_ssh_config() {
    [[ ! -f "$SSH_CONFIG" ]] && return

    local host user hostname port identity_file
    host="" user="" hostname="" port="22" identity_file=""

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        local key value
        key=$(echo "$line" | awk '{print tolower($1)}')
        value=$(echo "$line" | awk '{$1=""; print substr($0,2)}' | xargs 2>/dev/null || echo "")

        case "$key" in
            host)
                # Emit previous host if valid
                if [[ -n "$host" && "$host" != "*" && ! "$host" =~ \* ]]; then
                    local h="${hostname:-$host}"
                    local u="${user:-$USER}"
                    local p="${port:-22}"
                    echo "${host}|${h}|${p}|${u}|${identity_file:-}|config"
                fi
                host="$value"
                hostname="" user="" port="22" identity_file=""
                ;;
            hostname)     hostname="$value" ;;
            user)         user="$value" ;;
            port)         port="$value" ;;
            identityfile) identity_file="${value/#~/$HOME}" ;;
        esac
    done < "$SSH_CONFIG"

    # Emit last host
    if [[ -n "$host" && "$host" != "*" && ! "$host" =~ \* ]]; then
        echo "${host}|${hostname:-$host}|${port:-22}|${user:-$USER}|${identity_file:-}|config"
    fi
}

# Parse ~/.ssh/known_hosts for additional hosts
parse_known_hosts() {
    [[ ! -f "$KNOWN_HOSTS" ]] && return

    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^\|1\| ]] && continue   # Skip hashed entries

        local host_field
        host_field=$(echo "$line" | awk '{print $1}')

        # Handle comma-separated multiple hosts
        IFS=',' read -ra hosts <<< "$host_field"
        for host in "${hosts[@]}"; do
            # Skip if IP-only and already in config
            local hostname="$host"
            local port="22"

            # Handle [host]:port format
            if [[ "$host" =~ ^\[(.+)\]:([0-9]+)$ ]]; then
                hostname="${BASH_REMATCH[1]}"
                port="${BASH_REMATCH[2]}"
            fi

            [[ -z "$hostname" ]] && continue
            [[ "$hostname" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && continue   # Skip bare IPs

            echo "${hostname}|${hostname}|${port}|${USER}||known_hosts"
        done
    done < "$KNOWN_HOSTS" | sort -u
}

# Parse ASH custom hosts file
parse_custom_hosts() {
    [[ ! -f "$CUSTOM_HOSTS" ]] && return

    while IFS='|' read -r alias hostname port user identity tags; do
        [[ "$alias" =~ ^# ]] && continue
        [[ -z "$alias" ]] && continue
        echo "${alias}|${hostname}|${port:-22}|${user:-$USER}|${identity:-}|custom"
    done < "$CUSTOM_HOSTS"
}

# Get all unique hosts (config takes priority)
get_all_hosts() {
    local -A seen=()
    local -a all=()

    # Priority: config → custom → known_hosts
    while IFS='|' read -r alias hostname port user identity source; do
        local key="${alias,,}"
        if [[ -z "${seen[$key]:-}" ]]; then
            seen[$key]=1
            all+=("${alias}|${hostname}|${port}|${user}|${identity}|${source}")
        fi
    done < <({
        parse_ssh_config
        parse_custom_hosts
        parse_known_hosts
    } | head -"$MAX_HOSTS")

    printf '%s\n' "${all[@]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  REACHABILITY CHECKING
# ══════════════════════════════════════════════════════════════════════════════

mkdir -p "$PING_CACHE_DIR"

check_host_reachable() {
    local hostname="$1" port="${2:-22}"
    local cache_key
    cache_key=$(echo "${hostname}:${port}" | tr '/:.' '_')
    local cache_file="${PING_CACHE_DIR}/${cache_key}"

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        if [[ $age -lt $PING_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi

    # Check reachability
    local result
    if timeout "$PING_TIMEOUT" bash -c \
        ">/dev/tcp/${hostname}/${port}" 2>/dev/null; then
        result="online"
    else
        result="offline"
    fi

    echo "$result" > "$cache_file"
    echo "$result"
}

get_latency() {
    local hostname="$1"
    local latency
    latency=$(ping -c1 -W"$PING_TIMEOUT" "$hostname" 2>/dev/null | \
        grep -oP 'time=\K[0-9.]+' | head -1 || echo "")
    [[ -n "$latency" ]] && echo "${latency%.*}ms" || echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  FAVORITES & HISTORY
# ══════════════════════════════════════════════════════════════════════════════

ensure_files() {
    mkdir -p "$(dirname "$FAVORITES_FILE")" \
             "$(dirname "$HISTORY_FILE")"
    touch "$FAVORITES_FILE" "$HISTORY_FILE" 2>/dev/null || true
}

is_favorite() {
    grep -qxF "$1" "$FAVORITES_FILE" 2>/dev/null
}

toggle_favorite() {
    local alias="$1"
    if is_favorite "$alias"; then
        local tmp
        tmp=$(mktemp)
        grep -vxF "$alias" "$FAVORITES_FILE" > "$tmp" 2>/dev/null || true
        mv "$tmp" "$FAVORITES_FILE"
        notify_sh "★ Unfavorited" "$alias" "low"
    else
        echo "$alias" >> "$FAVORITES_FILE"
        notify_sh "★ Favorited" "$alias" "low"
    fi
}

add_to_history() {
    local alias="$1"
    ensure_files

    local tmp
    tmp=$(mktemp)
    echo "${alias}|$(date +%s)" | cat - "$HISTORY_FILE" > "$tmp" 2>/dev/null || true
    grep -vF "${alias}|" "$HISTORY_FILE" 2>/dev/null >> "$tmp" || true
    head -"$MAX_HISTORY" "$tmp" > "$HISTORY_FILE" 2>/dev/null || true
    rm -f "$tmp"
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  SSH OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════

build_ssh_cmd() {
    local hostname="$1" port="$2" user="$3" identity="${4:-}"
    local cmd="ssh -p $port"
    [[ -n "$identity" && -f "$identity" ]] && cmd+=" -i $identity"
    cmd+=" ${user}@${hostname}"
    echo "$cmd"
}

connect_ssh() {
    local alias="$1" hostname="$2" port="$3" user="$4" identity="${5:-}"

    add_to_history "$alias"
    notify_sh "󰢹 Connecting…" "${user}@${hostname}:${port}" "low"

    local ssh_cmd
    ssh_cmd=$(build_ssh_cmd "$hostname" "$port" "$user" "$identity")

    kitty \
        --class ssh-terminal \
        --title "SSH: ${alias}" \
        --override font_size=12.5 \
        -e bash -c "$ssh_cmd; echo; echo 'Connection closed. Press Enter to exit.'; read" \
        &>/dev/null & disown
}

connect_sftp() {
    local alias="$1" hostname="$2" port="$3" user="$4" identity="${5:-}"

    add_to_history "$alias"
    notify_sh "󰣘 SFTP…" "${user}@${hostname}:${port}" "low"

    local sftp_cmd="sftp -P $port"
    [[ -n "$identity" && -f "$identity" ]] && sftp_cmd+=" -i $identity"
    sftp_cmd+=" ${user}@${hostname}"

    # Try yazi or kitty sftp
    if command -v yazi &>/dev/null; then
        kitty \
            --class sftp-browser \
            --title "SFTP: ${alias}" \
            -e bash -c "$sftp_cmd" \
            &>/dev/null & disown
    else
        kitty \
            --class sftp-browser \
            -e bash -c "$sftp_cmd" \
            &>/dev/null & disown
    fi
}

setup_tunnel() {
    local alias="$1" hostname="$2" port="$3" user="$4"

    # Prompt for tunnel config
    local config
    config=$(rofi -dmenu \
        -p "󰒓 Tunnel (local:remote:remoteport)" \
        -filter "8080:localhost:80" \
        -mesg "Format: <b>LOCAL_PORT:REMOTE_HOST:REMOTE_PORT</b>\nExample: 8080:localhost:80" \
        -theme-str "window { width: 480px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    [[ -z "$config" ]] && return

    IFS=':' read -r local_port remote_host remote_port <<< "$config"

    notify_sh "󰒓 Tunnel starting" \
        "localhost:${local_port} → ${remote_host}:${remote_port} via ${alias}" \
        "normal"

    kitty \
        --class ssh-tunnel \
        --title "Tunnel: ${alias}" \
        -e bash -c "ssh -p $port -L ${local_port}:${remote_host}:${remote_port} \
            -N ${user}@${hostname}; echo 'Tunnel closed. Press Enter.'; read" \
        &>/dev/null & disown
}

copy_ssh_id() {
    local hostname="$1" port="$2" user="$3"

    local key_file="${HOME}/.ssh/id_ed25519.pub"
    [[ ! -f "$key_file" ]] && key_file="${HOME}/.ssh/id_rsa.pub"
    [[ ! -f "$key_file" ]] && {
        notify_sh "No SSH key" "Generate with: ssh-keygen -t ed25519" "normal"
        return
    }

    notify_sh "󰆿 Copying SSH key…" "to ${user}@${hostname}" "low"
    kitty \
        --class ssh-keycopy \
        -e bash -c "ssh-copy-id -i $key_file -p $port ${user}@${hostname}; \
            echo; echo 'Done. Press Enter.'; read" \
        &>/dev/null & disown
}

open_vscode_remote() {
    local alias="$1" hostname="$2" port="$3" user="$4"

    if command -v code &>/dev/null; then
        code --remote "ssh-remote+${user}@${hostname}" . &>/dev/null & disown
        notify_sh "󰘓 VS Code Remote" "${alias}" "low"
    else
        notify_sh "VS Code not found" "Install code or code-oss" "normal"
    fi
}

connect_mosh() {
    local alias="$1" hostname="$2" port="$3" user="$4"

    if ! command -v mosh &>/dev/null; then
        notify_sh "mosh not installed" "paru -S mosh" "normal"
        return
    fi

    add_to_history "$alias"
    notify_sh "󰋌 Mosh connecting…" "${user}@${hostname}" "low"

    kitty \
        --class mosh-terminal \
        --title "Mosh: ${alias}" \
        -e bash -c "mosh --ssh='ssh -p $port' ${user}@${hostname}; \
            echo; echo 'Disconnected. Press Enter.'; read" \
        &>/dev/null & disown
}

copy_connection_string() {
    local hostname="$1" port="$2" user="$3"
    local conn_str="${user}@${hostname}"
    [[ "$port" != "22" ]] && conn_str="ssh -p ${port} ${conn_str}"

    echo -n "$conn_str" | wl-copy 2>/dev/null && \
        notify_sh "󰆏 Copied" "$conn_str" "low"
}

add_host_dialog() {
    # Collect host info via rofi prompts
    local alias
    alias=$(rofi -dmenu \
        -p "Host alias" \
        -mesg "Enter a short name for this host" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    [[ -z "$alias" ]] && return

    local hostname
    hostname=$(rofi -dmenu \
        -p "Hostname / IP" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    [[ -z "$hostname" ]] && return

    local user
    user=$(rofi -dmenu \
        -p "Username" \
        -filter "$USER" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "$USER")

    local port
    port=$(rofi -dmenu \
        -p "Port" \
        -filter "22" \
        -theme-str "window { width: 200px; } listview { lines: 0; }" \
        2>/dev/null || echo "22")

    # Append to SSH config
    mkdir -p "$(dirname "$SSH_CONFIG")"
    chmod 700 "$(dirname "$SSH_CONFIG")"
    cat >> "$SSH_CONFIG" << SSHHOST

Host ${alias}
    HostName ${hostname}
    User ${user}
    Port ${port}
SSHHOST

    notify_sh "Host added" "$alias → ${user}@${hostname}:${port}" "low"
}

show_key_info() {
    local info=""

    # List SSH keys
    for keyfile in "${HOME}/.ssh/"*.pub; do
        [[ -f "$keyfile" ]] || continue
        local fingerprint
        fingerprint=$(ssh-keygen -lf "$keyfile" 2>/dev/null | awk '{print $2" "$3" "$4}' || echo "?")
        info+="$(basename "$keyfile"): $fingerprint\n"
    done

    # Check ssh-agent
    if ssh-add -l &>/dev/null 2>&1; then
        local agent_keys
        agent_keys=$(ssh-add -l 2>/dev/null | wc -l)
        info+="\nAgent: ${agent_keys} key(s) loaded"
    else
        info+="\nAgent: not running"
    fi

    if [[ -n "$info" ]]; then
        notify_sh "󰌋 SSH Keys" "$info" "low"
    else
        notify_sh "No SSH keys found" "Generate: ssh-keygen -t ed25519" "normal"
    fi
}

ping_host() {
    local hostname="$1" alias="$2"
    local latency
    latency=$(get_latency "$hostname")

    if [[ -n "$latency" ]]; then
        notify_sh "● ${alias} online" "Latency: $latency" "low"
    else
        notify_sh "○ ${alias} unreachable" "$hostname" "normal"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_sh() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH SSH" \
        --icon=utilities-terminal \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:ssh-connect \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_host_display() {
    local alias="$1" hostname="$2" port="$3" user="$4" identity="$5" source="$6"

    local is_fav=false
    local in_history=false
    is_favorite "$alias" && is_fav=true
    grep -qF "${alias}|" "$HISTORY_FILE" 2>/dev/null && in_history=true

    # Check reachability (background, cached)
    local status="○" latency=""
    local cached_status
    cached_status=$(check_host_reachable "$hostname" "$port" 2>/dev/null || echo "offline")

    if [[ "$cached_status" == "online" ]]; then
        status="●"
        # Get cached latency if available
        local cache_key
        cache_key=$(echo "${hostname}:${port}" | tr '/:.' '_')
        local lat_cache="${PING_CACHE_DIR}/${cache_key}.latency"
        if [[ -f "$lat_cache" ]]; then
            latency=$(cat "$lat_cache")
        fi
    fi

    local fav_mark=""
    $is_fav && fav_mark="★ "

    local history_mark=""
    $in_history && ! $is_fav && history_mark="  "

    local status_color
    [[ "$status" == "●" ]] && status_color="<online>" || status_color=""

    # Source badge
    local source_badge=""
    case "$source" in
        config)      source_badge="" ;;
        custom)      source_badge=" ⭐" ;;
        known_hosts) source_badge=" 󰌋" ;;
    esac

    # Identity indicator
    local key_indicator=""
    [[ -n "$identity" ]] && key_indicator=" 󰌋"

    local display
    display=$(printf '%s%s󰢹  %-18s  %-22s  %-5s  %-12s  %s %s%s%s' \
        "$fav_mark" \
        "$history_mark" \
        "${alias:0:16}" \
        "${hostname:0:20}" \
        "$port" \
        "${user:0:10}" \
        "$status" \
        "${latency}" \
        "$key_indicator" \
        "$source_badge")

    echo "$display"
}

build_entries() {
    local filter="${1:-all}"
    ensure_files

    # Favorites section
    if [[ "$filter" == "favorites" ]] || [[ "$filter" == "all" ]]; then
        local favs
        favs=$(cat "$FAVORITES_FILE" 2>/dev/null || true)

        if [[ -n "$favs" ]]; then
            printf '─── FAVORITES ────────────────────────────\0nonselectable\x1ftrue\n'

            while IFS= read -r fav_alias; do
                [[ -z "$fav_alias" ]] && continue

                while IFS='|' read -r alias hostname port user identity source; do
                    [[ "$alias" != "$fav_alias" ]] && continue

                    local display
                    display=$(build_host_display "$alias" "$hostname" "$port" "$user" "$identity" "$source")

                    printf '%s\0info\x1fconnect\x1fmeta\x1f%s|%s|%s|%s|%s\n' \
                        "$display" "$alias" "$hostname" "$port" "$user" "${identity:-}"

                done < <(get_all_hosts)
            done <<< "$favs"
        fi
    fi

    # Recent section
    if [[ "$filter" == "recent" ]] || [[ "$filter" == "all" ]]; then
        if [[ -s "$HISTORY_FILE" ]]; then
            printf '─── RECENT ───────────────────────────────\0nonselectable\x1ftrue\n'

            local count=0
            while IFS='|' read -r recent_alias ts; do
                [[ -z "$recent_alias" ]] && continue
                is_favorite "$recent_alias" && continue   # Skip if in favorites

                while IFS='|' read -r alias hostname port user identity source; do
                    [[ "$alias" != "$recent_alias" ]] && continue

                    local display
                    display=$(build_host_display "$alias" "$hostname" "$port" "$user" "$identity" "$source")

                    printf '%s\0info\x1fconnect\x1fmeta\x1f%s|%s|%s|%s|%s\n' \
                        "$display" "$alias" "$hostname" "$port" "$user" "${identity:-}"

                    (( count++ )) || true
                    [[ $count -ge 8 ]] && break 2
                done < <(get_all_hosts)
            done < "$HISTORY_FILE"
        fi
    fi

    # All hosts section
    if [[ "$filter" == "all" ]]; then
        printf '─── ALL HOSTS ────────────────────────────\0nonselectable\x1ftrue\n'
    fi

    local count=0
    while IFS='|' read -r alias hostname port user identity source; do
        [[ -z "$alias" ]] && continue

        # Category filter
        if [[ "$filter" != "all" && "$filter" != "recent" && "$filter" != "favorites" ]]; then
            # Custom group filter (tag-based)
            local tags
            tags=$(grep "^${alias}|" "$CUSTOM_HOSTS" 2>/dev/null | cut -d'|' -f6 || echo "")
            [[ "$tags" != *"$filter"* ]] && continue
        fi

        # Skip favorites and recent (already shown)
        if [[ "$filter" == "all" ]]; then
            is_favorite "$alias" && continue
            grep -qF "${alias}|" "$HISTORY_FILE" 2>/dev/null && continue
        fi

        local display
        display=$(build_host_display "$alias" "$hostname" "$port" "$user" "$identity" "$source")

        printf '%s\0info\x1fconnect\x1fmeta\x1f%s|%s|%s|%s|%s\n' \
            "$display" "$alias" "$hostname" "$port" "$user" "${identity:-}"

        (( count++ )) || true
        [[ $count -ge 40 ]] && break

    done < <(get_all_hosts | sort -t'|' -k1 -f)

    # Actions
    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰐕  Add New Host\0info\x1fadd-host\n'
    printf '󰌋  Manage SSH Keys\0info\x1fkey-info\n'
    printf '  Edit SSH Config\0info\x1fedit-config\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  CONTEXT MENU FOR HOST
# ══════════════════════════════════════════════════════════════════════════════

show_host_menu() {
    local alias="$1" hostname="$2" port="$3" user="$4" identity="${5:-}"

    local is_fav=false
    is_favorite "$alias" && is_fav=true

    local entries=(
        "󰢹  Connect (SSH shell)"
        "󰣘  Browse Files (SFTP)"
        "󰒓  Set up Tunnel"
        "󰘓  Open in VS Code Remote"
        "󰋌  Connect via Mosh"
        "─────────────────────────"
        $( $is_fav && echo "★  Remove from favorites" || echo "★  Add to favorites")
        "󰆿  Copy SSH ID to host"
        "󰆏  Copy connection string"
        "  Ping / check latency"
        "  Edit in SSH config"
        "─────────────────────────"
        "✖  Cancel"
    )

    local choice
    choice=$(printf '%s\n' "${entries[@]}" | \
        rofi -dmenu \
            -p "󰢹 ${alias} [${user}@${hostname}:${port}]" \
            -theme-str "
                window { width: 360px; height: 0px; }
                listview { lines: 13; columns: 1; }
                element { padding: 8px 16px; border-radius: 8px; }
                element selected.normal {
                    background-color: #89dceb;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "✖  Cancel")

    case "$choice" in
        "󰢹  Connect"*)      connect_ssh    "$alias" "$hostname" "$port" "$user" "$identity" ;;
        "󰣘  Browse"*)       connect_sftp   "$alias" "$hostname" "$port" "$user" "$identity" ;;
        "󰒓  Set up Tunnel")  setup_tunnel   "$alias" "$hostname" "$port" "$user" ;;
        "󰘓  Open in VS Code"*) open_vscode_remote "$alias" "$hostname" "$port" "$user" ;;
        "󰋌  Connect via Mosh") connect_mosh "$alias" "$hostname" "$port" "$user" ;;
        "★  Add"*|"★  Remove"*) toggle_favorite "$alias" ;;
        "󰆿  Copy SSH ID"*)   copy_ssh_id   "$hostname" "$port" "$user" ;;
        "󰆏  Copy"*)          copy_connection_string "$hostname" "$port" "$user" ;;
        "  Ping"*)           ping_host     "$hostname" "$alias" ;;
        "  Edit"*)
            kitty --class float-term -e \
                nvim "$SSH_CONFIG" +/"Host $alias" &>/dev/null & disown
            ;;
        *) ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        connect)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            show_host_menu "$alias" "$hostname" "$port" "$user" "$identity"
            ;;
        sftp)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            connect_sftp "$alias" "$hostname" "$port" "$user" "$identity"
            ;;
        tunnel)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            setup_tunnel "$alias" "$hostname" "$port" "$user"
            ;;
        fav-toggle)
            IFS='|' read -r alias rest <<< "$meta"
            toggle_favorite "$alias"
            ;;
        copy-string)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            copy_connection_string "$hostname" "$port" "$user"
            ;;
        ping)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            ping_host "$hostname" "$alias"
            ;;
        add-host)   add_host_dialog ;;
        key-info)   show_key_info ;;
        edit-config)
            kitty --class float-term -e nvim "$SSH_CONFIG" &>/dev/null & disown
            ;;
        vscode)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            open_vscode_remote "$alias" "$hostname" "$port" "$user"
            ;;
        mosh)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            connect_mosh "$alias" "$hostname" "$port" "$user"
            ;;
        copy-id)
            IFS='|' read -r alias hostname port user identity <<< "$meta"
            copy_ssh_id "$hostname" "$port" "$user"
            ;;
        none|"")    return 0 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --connect)  [[ -n "${2:-}" ]] && {
                        while IFS='|' read -r alias hostname port user identity source; do
                            [[ "$alias" == "$2" ]] && \
                                connect_ssh "$alias" "$hostname" "$port" "$user" "$identity" && break
                        done < <(get_all_hosts)
                    } ;;
        --list)     get_all_hosts | awk -F'|' '{print $1"\t"$2":"$4}' ;;
        --ping)     [[ -n "${2:-}" ]] && check_host_reachable "$2" && get_latency "$2" ;;
        --help|-h)
            echo "ASH SSH Manager v5.0"
            echo ""
            echo "Usage: ssh-connect.sh [OPTION] [HOST]"
            echo "  --connect HOST  Connect to host"
            echo "  --list          List all hosts"
            echo "  --ping HOST     Check host reachability"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show ssh \
        -modi "ssh:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/ssh-connect/ssh-connect.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    ensure_files
    build_entries "all"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    build_entries "all"
    exit 0
fi

# Ctrl+F: Toggle favorite
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r alias rest <<< "$meta_value"
    [[ -n "$alias" ]] && toggle_favorite "$alias"
    build_entries "all"
    exit 0
fi

# Ctrl+T: Tunnel
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    dispatch_action "tunnel" "$meta_value"
    build_entries "all"
    exit 0
fi

# Ctrl+C: Copy connection string
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    dispatch_action "copy-string" "$meta_value"
    build_entries "all"
    exit 0
fi

# Ctrl+N: Add host
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    add_host_dialog
    build_entries "all"
    exit 0
fi

# Ctrl+R: Refresh
if [[ "${ROFI_RETV}" -eq 17 ]]; then
    rm -rf "$PING_CACHE_DIR"
    mkdir -p "$PING_CACHE_DIR"
    build_entries "all"
    exit 0
fi

# Ctrl+P: Ping
if [[ "${ROFI_RETV}" -eq 16 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r alias hostname rest <<< "$meta_value"
    [[ -n "$hostname" ]] && ping_host "$hostname" "$alias"
    build_entries "all"
    exit 0
fi

# Ctrl+S: SFTP
if [[ "${ROFI_RETV}" -eq 20 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    dispatch_action "sftp" "$meta_value"
    exit 0
fi

# Alt+Enter: SFTP connect
if [[ "${ROFI_RETV}" -eq 22 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    dispatch_action "sftp" "$meta_value"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_entries "all"
    exit 0
fi