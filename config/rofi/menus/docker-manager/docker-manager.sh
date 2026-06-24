#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Docker Manager Script                             ║
# ║                                                                              ║
# ║  Full Docker/Podman container management via Rofi custom mode.             ║
# ║  Supports: containers, images, volumes, networks, compose stacks.          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly MAX_ITEMS=100
readonly LOG_LINES=50          # Lines of logs to follow
readonly STATS_INTERVAL=2      # Stats refresh interval

# Detect Docker or Podman
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    readonly DOCKER_CMD="docker"
elif command -v podman &>/dev/null; then
    readonly DOCKER_CMD="podman"
else
    readonly DOCKER_CMD="docker"
fi

# ══════════════════════════════════════════════════════════════════════════════
# §02  ENGINE INFO
# ══════════════════════════════════════════════════════════════════════════════

get_engine_info() {
    if ! $DOCKER_CMD info &>/dev/null 2>&1; then
        echo "offline|0|0|0"
        return
    fi

    local total running stopped images
    total=$(   $DOCKER_CMD ps -aq      2>/dev/null | wc -l || echo 0)
    running=$( $DOCKER_CMD ps -q       2>/dev/null | wc -l || echo 0)
    stopped=$( $DOCKER_CMD ps -aq -f status=exited 2>/dev/null | wc -l || echo 0)
    images=$(  $DOCKER_CMD images -q   2>/dev/null | wc -l || echo 0)

    echo "online|${total}|${running}|${images}"
}

get_engine_version() {
    $DOCKER_CMD version --format '{{.Server.Version}}' 2>/dev/null | head -1 || echo "unknown"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  STATUS INDICATORS
# ══════════════════════════════════════════════════════════════════════════════

status_icon() {
    case "${1,,}" in
        running)        echo "●" ;;
        exited|stopped) echo "○" ;;
        paused)         echo "⏸" ;;
        restarting)     echo "⟳" ;;
        dead|removing)  echo "✗" ;;
        created)        echo "+" ;;
        *)              echo "?" ;;
    esac
}

format_size() {
    local bytes="${1:-0}"
    # Handle Docker size format strings like "5.57MB" directly
    if [[ "$bytes" =~ [A-Za-z] ]]; then
        echo "$bytes"
        return
    fi
    if   (( bytes < 1024 ));           then printf "%dB"     "$bytes"
    elif (( bytes < 1048576 ));         then printf "%.1fKB"  "$(echo "scale=1; $bytes/1024"       | bc 2>/dev/null || echo 0)"
    elif (( bytes < 1073741824 ));      then printf "%.1fMB"  "$(echo "scale=1; $bytes/1048576"    | bc 2>/dev/null || echo 0)"
    else                                     printf "%.2fGB"  "$(echo "scale=2; $bytes/1073741824" | bc 2>/dev/null || echo 0)"
    fi
}

format_uptime() {
    local status="$1"
    # Docker "Up 2 hours" → "2h"
    echo "$status" | sed \
        's/Up //; s/ hours\?/h/; s/ minutes\?/m/; s/ seconds\?/s/; s/ days\?/d/; s/ weeks\?/w/' | \
        head -c 10
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_dk() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Docker" \
        --icon=utilities-terminal \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:docker-manager \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  CONTAINER ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

exec_container() {
    local name="$1"
    local shell

    # Detect available shell in container
    for sh in bash sh ash zsh; do
        if $DOCKER_CMD exec "$name" which "$sh" &>/dev/null 2>&1; then
            shell="$sh"
            break
        fi
    done

    shell="${shell:-sh}"
    notify_dk "⚡ Exec into $name" "Shell: $shell" "low"

    kitty \
        --class docker-exec \
        --title "Docker exec: $name" \
        --override font_size=12.5 \
        -e bash -c "$DOCKER_CMD exec -it $name $shell; \
            echo; echo 'Container shell exited. Press Enter.'; read" \
        &>/dev/null & disown
}

follow_logs() {
    local name="$1"
    notify_dk "󰋩 Logs: $name" "Following last ${LOG_LINES} lines" "low"

    kitty \
        --class docker-logs \
        --title "Docker logs: $name" \
        -e bash -c "$DOCKER_CMD logs -f --tail ${LOG_LINES} $name; \
            echo; echo 'Log stream ended. Press Enter.'; read" \
        &>/dev/null & disown
}

toggle_container() {
    local name="$1" status="$2"

    if [[ "${status,,}" == "running" ]]; then
        $DOCKER_CMD stop "$name" &>/dev/null && \
            notify_dk "⏹ Stopped" "$name" "normal"
    else
        $DOCKER_CMD start "$name" &>/dev/null && \
            notify_dk "▶ Started" "$name" "low"
    fi
}

remove_container() {
    local name="$1" status="$2"

    # Confirm
    local confirm
    confirm=$(printf "Yes, remove\nNo, cancel" | \
        rofi -dmenu \
            -p "Remove container: $name?" \
            -mesg "Status: <b>$status</b>\nThis cannot be undone" \
            -theme-str "
                window { width: 320px; }
                listview { lines: 2; }
                element selected.normal {
                    background-color: #f38ba8;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "No, cancel")

    if [[ "$confirm" == "Yes, remove" ]]; then
        # Force stop if running
        [[ "${status,,}" == "running" ]] && \
            $DOCKER_CMD stop "$name" &>/dev/null || true

        $DOCKER_CMD rm "$name" &>/dev/null && \
            notify_dk "󰩹 Removed container" "$name" "normal"
    fi
}

show_container_stats() {
    local name="$1"

    kitty \
        --class docker-stats \
        --title "Docker stats: $name" \
        -e bash -c "$DOCKER_CMD stats $name; \
            echo; echo 'Press Enter to exit.'; read" \
        &>/dev/null & disown
}

inspect_container() {
    local name="$1"

    local info
    info=$($DOCKER_CMD inspect "$name" 2>/dev/null | \
        jq -r '.[0] | {
            ID: .Id[:12],
            Image: .Config.Image,
            Status: .State.Status,
            IP: (.NetworkSettings.Networks | to_entries[0].value.IPAddress // "none"),
            Ports: (.NetworkSettings.Ports | to_entries | map("\(.key)→\(.value[0].HostPort // "none")") | join(", ")),
            RestartPolicy: .HostConfig.RestartPolicy.Name,
            Mounts: ([.Mounts[].Source] | join(", "))
        } | to_entries[] | "\(.key): \(.value)"' 2>/dev/null || \
        echo "Inspect failed")

    notify_dk "󰋩 $name" "$info" "low"
}

kill_container() {
    local name="$1"
    $DOCKER_CMD kill "$name" &>/dev/null && \
        notify_dk "💀 Killed" "$name" "critical"
}

copy_container_id() {
    local name="$1"
    local id
    id=$($DOCKER_CMD ps -aqf "name=^${name}$" 2>/dev/null | head -1 || \
         $DOCKER_CMD ps -aqf "name=${name}" 2>/dev/null | head -1 || echo "")

    if [[ -n "$id" ]]; then
        echo -n "$id" | wl-copy 2>/dev/null && \
            notify_dk "󰆏 ID copied" "$id" "low"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  IMAGE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

pull_image() {
    local image="${1:-}"

    if [[ -z "$image" ]]; then
        image=$(rofi -dmenu \
            -p "Pull image" \
            -filter "nginx:alpine" \
            -mesg "Enter image name[:tag] to pull" \
            -theme-str "window { width: 400px; } listview { lines: 0; }" \
            2>/dev/null || echo "")
    fi

    [[ -z "$image" ]] && return

    notify_dk "󰇚 Pulling image" "$image" "low"

    kitty \
        --class docker-pull \
        --title "Docker pull: $image" \
        -e bash -c "$DOCKER_CMD pull $image; \
            echo; echo 'Done. Press Enter.'; read" \
        &>/dev/null & disown
}

remove_image() {
    local image_id="$1" image_name="$2"

    local confirm
    confirm=$(printf "Yes, remove\nNo, cancel" | \
        rofi -dmenu \
            -p "Remove image: ${image_name}?" \
            -theme-str "window { width: 300px; } listview { lines: 2; }
                element selected.normal { background-color: #f38ba8; text-color: #1e1e2e; }" \
            2>/dev/null || echo "No, cancel")

    [[ "$confirm" != "Yes, remove" ]] && return

    $DOCKER_CMD rmi "$image_id" &>/dev/null && \
        notify_dk "󰩹 Image removed" "$image_name" "normal"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  COMPOSE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

find_compose_files() {
    find "${HOME}" \
        -maxdepth 5 \
        -name "docker-compose.yml" \
        -o -name "docker-compose.yaml" \
        -o -name "compose.yml" \
        -o -name "compose.yaml" \
        2>/dev/null | head -20
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  CONTEXT MENU PER CONTAINER
# ══════════════════════════════════════════════════════════════════════════════

show_container_menu() {
    local name="$1" status="$2" image="$3"

    local is_running=false
    [[ "${status,,}" == "running" ]] && is_running=true

    local entries=()

    $is_running && entries+=(
        "⚡  Execute Shell (bash/sh)"
        "󰋩  Follow Logs"
        "󰊚  Container Stats"
        "─────────────────────────"
        "⏹  Stop Container"
        "⏸  Pause Container"
    ) || entries+=(
        "▶  Start Container"
    )

    entries+=(
        "󰋩  Inspect / Info"
        "󰆏  Copy Container ID"
        "━━━━━━━━━━━━━━━━━━━━━━━━━"
        "🔄  Update Image: $image"
        "━━━━━━━━━━━━━━━━━━━━━━━━━"
        "󰩹  Remove Container"
        "💀  Force Kill"
        "━━━━━━━━━━━━━━━━━━━━━━━━━"
        "✖  Cancel"
    )

    local choice
    choice=$(printf '%s\n' "${entries[@]}" | \
        rofi -dmenu \
            -p "$(status_icon "$status") $name" \
            -mesg "Image: <b>$image</b>  ·  Status: <b>$status</b>" \
            -theme-str "
                window { width: 360px; height: 0px; }
                listview { lines: 14; columns: 1; }
                element { padding: 8px 16px; border-radius: 8px; }
                element selected.normal {
                    background-color: #89b4fa;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "✖  Cancel")

    case "$choice" in
        "⚡  Execute"*)         exec_container      "$name" ;;
        "󰋩  Follow Logs")       follow_logs         "$name" ;;
        "󰊚  Container Stats")   show_container_stats "$name" ;;
        "⏹  Stop"*)             toggle_container    "$name" "running" ;;
        "⏸  Pause"*)            $DOCKER_CMD pause   "$name" &>/dev/null; notify_dk "⏸ Paused" "$name" ;;
        "▶  Start"*)            toggle_container    "$name" "stopped" ;;
        "󰋩  Inspect"*)          inspect_container   "$name" ;;
        "󰆏  Copy Container ID") copy_container_id  "$name" ;;
        "🔄  Update"*)          pull_image          "$image" ;;
        "󰩹  Remove"*)           remove_container    "$name" "$status" ;;
        "💀  Force Kill")        kill_container      "$name" ;;
        *) ;;
    esac
}

show_image_menu() {
    local image_id="$1" image_name="$2" image_size="$3"

    local choice
    choice=$(printf '%s\n' \
        "▶  Run Container from Image" \
        "󰇚  Pull/Update Image" \
        "󰋩  Inspect Image" \
        "󰆏  Copy Image ID" \
        "━━━━━━━━━━━━━━━━━━━━━━━━" \
        "󰩹  Remove Image" \
        "✖  Cancel" | \
        rofi -dmenu \
            -p "󰋩 $image_name" \
            -mesg "ID: <b>${image_id:0:12}</b>  ·  Size: <b>$image_size</b>" \
            -theme-str "
                window { width: 340px; }
                listview { lines: 7; }
                element selected.normal {
                    background-color: #89b4fa;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "✖  Cancel")

    case "$choice" in
        "▶  Run"*)
            local args
            args=$(rofi -dmenu \
                -p "docker run args" \
                -filter "-d --name mycontainer" \
                -theme-str "window { width: 450px; } listview { lines: 0; }" \
                2>/dev/null || echo "-d")
            kitty --class docker-run \
                -e bash -c "$DOCKER_CMD run $args $image_name; \
                    echo; echo 'Done. Press Enter.'; read" \
                &>/dev/null & disown
            ;;
        "󰇚  Pull/Update"*)      pull_image "$image_name" ;;
        "󰋩  Inspect"*)
            local info
            info=$($DOCKER_CMD inspect "$image_id" 2>/dev/null | \
                jq -r '.[0] | "Created: \(.Created[:19])\nArch: \(.Architecture)\nOS: \(.Os)\nLayers: \(.RootFS.Layers | length)"' \
                2>/dev/null || echo "Inspect failed")
            notify_dk "󰋩 $image_name" "$info" "low"
            ;;
        "󰆏  Copy Image ID")
            echo -n "$image_id" | wl-copy 2>/dev/null && \
                notify_dk "󰆏 Copied" "${image_id:0:12}" "low"
            ;;
        "󰩹  Remove"*)           remove_image "$image_id" "$image_name" ;;
        *) ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_container_entries() {
    local filter="${1:-all}"    # all | running | stopped

    # Running containers
    if [[ "$filter" == "all" || "$filter" == "running" ]]; then
        local running
        running=$($DOCKER_CMD ps \
            --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}' \
            2>/dev/null | head -"$MAX_ITEMS" || true)

        if [[ -n "$running" ]]; then
            printf '─── RUNNING ──────────────────────────────\0nonselectable\x1ftrue\n'

            while IFS=$'\t' read -r name image status ports size; do
                [[ -z "$name" ]] && continue

                local uptime
                uptime=$(format_uptime "$status")

                local ports_short
                ports_short=$(echo "$ports" | \
                    sed 's/0\.0\.0\.0://g; s/:::/ /g; s/->[0-9]*\/tcp//g' | \
                    head -c 20)

                local size_short
                size_short=$(echo "$size" | awk '{print $1}')

                local display
                display=$(printf '● 󰡨  %-18s  %-22s  %-8s  ↓%-7s  %s' \
                    "${name:0:16}" \
                    "${image:0:20}" \
                    "$uptime" \
                    "$size_short" \
                    "$ports_short")

                printf '%s\0info\x1fcontainer\x1fmeta\x1f%s|running|%s\n' \
                    "$display" "$name" "$image"

            done <<< "$running"
        fi
    fi

    # Stopped/exited containers
    if [[ "$filter" == "all" || "$filter" == "stopped" ]]; then
        local stopped
        stopped=$($DOCKER_CMD ps -a \
            --filter "status=exited" \
            --filter "status=created" \
            --filter "status=dead" \
            --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Size}}' \
            2>/dev/null | head -20 || true)

        if [[ -n "$stopped" ]]; then
            printf '─── STOPPED / EXITED ─────────────────────\0nonselectable\x1ftrue\n'

            while IFS=$'\t' read -r name image status size; do
                [[ -z "$name" ]] && continue

                local status_icon
                status_icon=$(status_icon "$(echo "$status" | awk '{print $1}')")

                local display
                display=$(printf '%s 󰡨  %-18s  %-22s  %-18s  %s' \
                    "$status_icon" \
                    "${name:0:16}" \
                    "${image:0:20}" \
                    "${status:0:16}" \
                    "$(echo "$size" | awk '{print $1}')")

                printf '%s\0info\x1fcontainer\x1fmeta\x1f%s|stopped|%s\n' \
                    "$display" "$name" "$image"

            done <<< "$stopped"
        fi
    fi
}

build_image_entries() {
    local images
    images=$($DOCKER_CMD images \
        --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}' \
        2>/dev/null | head -30 || true)

    if [[ -z "$images" ]]; then
        printf '󰋩  No images found\0nonselectable\x1ftrue\n'
        printf '󰇚  Pull an image\0info\x1fpull-image\n'
        return
    fi

    printf '─── IMAGES ───────────────────────────────\0nonselectable\x1ftrue\n'

    while IFS=$'\t' read -r name id size created; do
        [[ -z "$name" ]] && continue

        # Format created date
        local age
        age=$(echo "$created" | awk '{print $1}')

        local display
        display=$(printf '󰋩  %-32s  %-8s  %-12s  %s' \
            "${name:0:30}" \
            "${id:0:12}" \
            "$size" \
            "$age")

        printf '%s\0info\x1fimage\x1fmeta\x1f%s|%s|%s\n' \
            "$display" "$id" "$name" "$size"

    done <<< "$images"

    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰇚  Pull / download new image\0info\x1fpull-image\n'
    printf '󰩹  System prune (remove unused)\0info\x1fsystem-prune\n'
}

build_compose_entries() {
    printf '─── COMPOSE STACKS ───────────────────────\0nonselectable\x1ftrue\n'

    local compose_files
    compose_files=$(find_compose_files)

    if [[ -z "$compose_files" ]]; then
        printf '  No docker-compose files found\0nonselectable\x1ftrue\n'
        printf '  Searched in ~/  (depth 5)\0info\x1fnone\n'
        return
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local dir
        dir=$(dirname "$file")
        local name
        name=$(basename "$dir")
        local display_path="${file/$HOME/~}"

        # Check if this stack is running
        local running=false
        cd "$dir" 2>/dev/null && {
            if $DOCKER_CMD compose ps -q 2>/dev/null | grep -q .; then
                running=true
            fi
        } || true

        local status_mark="○"
        $running && status_mark="●"

        local display
        display=$(printf '%s 󰕨  %-22s  %s' \
            "$status_mark" \
            "${name:0:20}" \
            "${display_path:0:45}")

        printf '%s\0info\x1fcompose\x1fmeta\x1f%s|%s\n' \
            "$display" "$dir" "$file"

    done <<< "$compose_files"
}

build_volume_entries() {
    printf '─── VOLUMES ──────────────────────────────\0nonselectable\x1ftrue\n'

    local volumes
    volumes=$($DOCKER_CMD volume ls \
        --format '{{.Name}}\t{{.Driver}}\t{{.Scope}}' \
        2>/dev/null | head -20 || true)

    if [[ -z "$volumes" ]]; then
        printf '  No volumes found\0nonselectable\x1ftrue\n'
        return
    fi

    while IFS=$'\t' read -r name driver scope; do
        [[ -z "$name" ]] && continue

        local display
        display=$(printf '󰋊  %-30s  %-8s  %s' \
            "${name:0:28}" "$driver" "$scope")

        printf '%s\0info\x1fvolume\x1fmeta\x1f%s\n' "$display" "$name"

    done <<< "$volumes"

    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰩹  Remove unused volumes\0info\x1fvolume-prune\n'
}

build_all_entries() {
    local engine_state
    IFS='|' read -r state total running images <<< "$(get_engine_info)"

    if [[ "$state" == "offline" ]]; then
        printf '󰡨  Docker engine not running\0nonselectable\x1ftrue\n'
        printf '▶  Start Docker service\0info\x1fstart-engine\n'
        printf '  Install Docker Desktop\0info\x1fnone\n'
        return
    fi

    build_container_entries "all"
    build_image_entries

    printf '─── ACTIONS ──────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰡨  Open lazydocker (TUI)\0info\x1fopen-lazydocker\n'
    printf '󰕨  Compose stacks browser\0info\x1fview-compose\n'
    printf '󰋊  Volume manager\0info\x1fview-volumes\n'
    printf '󰛳  Network list\0info\x1fview-networks\n'
    printf '🧹  System prune (cleanup)\0info\x1fsystem-prune\n'
    printf '  Open Portainer (web UI)\0info\x1fopen-portainer\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        container)
            IFS='|' read -r name status image <<< "$meta"
            [[ -n "$name" ]] && show_container_menu "$name" "$status" "$image"
            ;;
        image)
            IFS='|' read -r id name size <<< "$meta"
            [[ -n "$id" ]] && show_image_menu "$id" "$name" "$size"
            ;;
        compose)
            IFS='|' read -r dir file <<< "$meta"
            if [[ -n "$dir" ]]; then
                local choice
                choice=$(printf '%s\n' \
                    "▶  docker compose up -d" \
                    "⏹  docker compose down" \
                    "󰋩  docker compose logs -f" \
                    "󰊚  docker compose ps" \
                    "  Edit compose file" | \
                    rofi -dmenu \
                        -p "󰕨 $(basename "$dir")" \
                        -mesg "Stack: <b>$file</b>" \
                        -theme-str "window { width: 350px; } listview { lines: 5; }" \
                        2>/dev/null || echo "")

                case "$choice" in
                    "▶"*)
                        kitty --class docker-compose \
                            -e bash -c "cd $dir && $DOCKER_CMD compose up -d; \
                                echo; echo 'Done. Press Enter.'; read" \
                            &>/dev/null & disown
                        ;;
                    "⏹"*)
                        cd "$dir" && $DOCKER_CMD compose down &>/dev/null && \
                            notify_dk "⏹ Compose down" "$(basename "$dir")" "normal"
                        ;;
                    "󰋩"*)
                        kitty --class docker-compose-logs \
                            -e bash -c "cd $dir && $DOCKER_CMD compose logs -f --tail 50; \
                                echo; echo 'Done. Press Enter.'; read" \
                            &>/dev/null & disown
                        ;;
                    "  Edit"*)
                        kitty --class float-term -e nvim "$file" &>/dev/null & disown
                        ;;
                esac
            fi
            ;;
        volume)
            local vol_name="$meta"
            if [[ -n "$vol_name" ]]; then
                local mountpoint
                mountpoint=$($DOCKER_CMD volume inspect "$vol_name" \
                    --format '{{.Mountpoint}}' 2>/dev/null || echo "")
                notify_dk "󰋊 Volume: $vol_name" "Mountpoint: ${mountpoint:-unknown}" "low"
            fi
            ;;
        pull-image)     pull_image "" ;;
        open-lazydocker)
            command -v lazydocker &>/dev/null && \
                kitty --class lazydocker -e lazydocker &>/dev/null & disown || \
                notify_dk "lazydocker not found" "paru -S lazydocker" "normal"
            ;;
        open-portainer)
            xdg-open "http://localhost:9000" &>/dev/null & disown
            ;;
        view-compose)
            # Switch to compose view
            build_compose_entries
            return 0
            ;;
        view-volumes)
            build_volume_entries
            return 0
            ;;
        view-networks)
            printf '─── NETWORKS ─────────────────────────────\0nonselectable\x1ftrue\n'
            $DOCKER_CMD network ls \
                --format '󰛳  {{.Name}}\t{{.Driver}}\t{{.Scope}}' \
                2>/dev/null | \
                while IFS=$'\t' read -r name driver scope; do
                    printf '%s  %-15s  %s\0info\x1fnone\n' "$name" "$driver" "$scope"
                done
            return 0
            ;;
        system-prune)
            local confirm
            confirm=$(printf "Yes, prune\nNo, cancel" | \
                rofi -dmenu \
                    -p "System prune?" \
                    -mesg "Remove all stopped containers, unused images,\norphan networks and build cache" \
                    -theme-str "window { width: 380px; } listview { lines: 2; }
                        element selected.normal { background-color: #f38ba8; text-color: #1e1e2e; }" \
                    2>/dev/null || echo "No, cancel")

            [[ "$confirm" != "Yes, prune" ]] && return

            notify_dk "🧹 Pruning…" "Removing unused resources" "normal"
            kitty --class docker-prune \
                -e bash -c "$DOCKER_CMD system prune -f; \
                    echo; echo 'Done. Press Enter.'; read" \
                &>/dev/null & disown
            ;;
        volume-prune)
            $DOCKER_CMD volume prune -f &>/dev/null && \
                notify_dk "🧹 Volumes pruned" "" "normal"
            ;;
        start-engine)
            systemctl start docker 2>/dev/null || \
                notify_dk "Cannot start Docker" "Try: sudo systemctl start docker" "critical"
            ;;
        none|"") return 0 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --list)     $DOCKER_CMD ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null ;;
        --running)  $DOCKER_CMD ps  --format '{{.Names}}\t{{.Status}}' 2>/dev/null ;;
        --images)   $DOCKER_CMD images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' 2>/dev/null ;;
        --exec)     [[ -n "${2:-}" ]] && exec_container "$2" ;;
        --logs)     [[ -n "${2:-}" ]] && follow_logs "$2" ;;
        --pull)     pull_image "${2:-}" ;;
        --prune)    $DOCKER_CMD system prune -f 2>/dev/null ;;
        --help|-h)
            echo "ASH Docker Manager v5.0"
            echo "Engine: $DOCKER_CMD"
            echo ""
            echo "Usage: docker-manager.sh [OPTION] [CONTAINER]"
            echo "  --list         List all containers"
            echo "  --running      List running containers"
            echo "  --images       List images"
            echo "  --exec NAME    Exec into container"
            echo "  --logs NAME    Follow container logs"
            echo "  --pull IMAGE   Pull image"
            echo "  --prune        System prune"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show dk \
        -modi "dk:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/docker-manager/docker-manager.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_all_entries
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    # If dispatch returns entries, output them
    dispatch_action "$local_action" "$meta_value"
    build_all_entries
    exit 0
fi

# Ctrl+S: Start/stop
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r name status image <<< "$meta_value"
    [[ -n "$name" ]] && toggle_container "$name" "${status:-stopped}"
    build_all_entries
    exit 0
fi

# Ctrl+P: Pull image
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    pull_image ""
    build_all_entries
    exit 0
fi

# Ctrl+R: Remove
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r name status rest <<< "$meta_value"
    [[ -n "$name" ]] && remove_container "$name" "${status:-stopped}"
    build_all_entries
    exit 0
fi

# Ctrl+L: Open lazydocker
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    dispatch_action "open-lazydocker"
    exit 0
fi

# Ctrl+F: Follow logs
if [[ "${ROFI_RETV}" -eq 17 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r name rest <<< "$meta_value"
    [[ -n "$name" ]] && follow_logs "$name"
    exit 0
fi

# Alt+Enter: View logs
if [[ "${ROFI_RETV}" -eq 23 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r name rest <<< "$meta_value"
    [[ -n "$name" ]] && follow_logs "$name"
    exit 0
fi

# Re-filter
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_all_entries
    exit 0
fi