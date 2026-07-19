# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — docker_cleanup Ultra                               ║
# ║  Complete Docker resource cleanup: containers, images, volumes & networks   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function docker_cleanup --description "Complete Docker resource cleanup system"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l BLUE   (set_color 0db7ed)   # Docker blue
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 DETECT DOCKER                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    command -q docker || begin
        printf "  $RED✗$R  Docker not installed\n"; return 1
    end

    docker info >/dev/null 2>&1 || begin
        printf "  $RED✗$R  Docker daemon not running\n"
        printf "  $DIM  Start with: sudo systemctl start docker$R\n"
        return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_help --description "Print help"
        echo ""
        echo $BOLD$BLUE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$BLUE"  ║  🐳  docker_cleanup — Docker Resource Cleaner        ║"$R
        echo $BOLD$BLUE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  docker_cleanup [target] [options]"
        echo ""
        echo "  $BOLD Targets:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "(none)"          "Interactive cleanup with fzf" \
            "all"             "Remove ALL unused resources" \
            "safe"            "Remove only stopped/unused (default)" \
            "containers"      "Stop and remove containers" \
            "images"          "Remove images" \
            "volumes"         "Remove volumes" \
            "networks"        "Remove unused networks" \
            "dangling"        "Remove only dangling images" \
            "exited"          "Remove only exited containers" \
            "old [days]"      "Remove images older than N days" \
            "cache"           "Clear build cache" \
            "stats"           "Show resource usage statistics" \
            "status"          "Show cleanup opportunities"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "--dry-run, -n" "Preview without deleting" \
            "--force, -f"   "Skip confirmation prompts" \
            "--quiet, -q"   "Minimal output" \
            "--all, -a"     "Include running containers" \
            "--help, -h"    "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "docker_cleanup               # Interactive mode" \
            "docker_cleanup safe          # Remove stopped/unused safely" \
            "docker_cleanup all           # Nuclear option (confirm required)" \
            "docker_cleanup images        # Clean images with picker" \
            "docker_cleanup old 30        # Remove images older than 30 days" \
            "docker_cleanup stats         # Disk usage overview" \
            "docker_cleanup --dry-run all # Preview all cleanup"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode    safe
    set -l _dry_run 0
    set -l _force   0
    set -l _quiet   0
    set -l _all_res 0   # include running/active resources
    set -l _days    30

    if contains -- --help $argv; or contains -- -h $argv
        __dkc_help; return 0
    end

    # First arg: mode
    if test (count $argv) -gt 0
        switch $argv[1]
            case all safe containers images volumes networks \
                 dangling exited cache stats status old pick
                set _mode $argv[1]
                set argv $argv[2..-1]
                if test "$_mode" = old && string match -qr '^\d+$' $argv[1]
                    set _days $argv[1]
                    set argv $argv[2..-1]
                end
        end
    end

    for arg in $argv
        switch $arg
            case --dry-run -n;  set _dry_run 1
            case --force -f;    set _force   1
            case --quiet -q;    set _quiet   1
            case --all -a;      set _all_res 1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 OUTPUT HELPERS                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_ok   --description "OK"
        test $_quiet -eq 1 && return
        printf "  $GREEN✓$R  %s\n" $argv[1]
    end
    function __dkc_del  --description "Deleted"
        printf "  $RED✗$R  $DIM%s$R\n" $argv[1]
    end
    function __dkc_info --description "Info"
        test $_quiet -eq 1 && return
        printf "  $CYAN›$R  $DIM%s$R\n" $argv[1]
    end
    function __dkc_warn --description "Warn"
        printf "  $YELLOW⚠$R  %s\n" $argv[1]
    end
    function __dkc_dry  --description "Dry-run"
        printf "  $YELLOW[DRY]$R  %s\n" $argv[1]
    end
    function __dkc_section --description "Section header"
        test $_quiet -eq 1 && return
        printf "\n  $BOLD$BLUE%s  %s$R\n" $argv[1] $argv[2]
        printf "  $DIM%s$R\n" (string repeat -n 55 "─")
    end

    function __dkc_human --description "Human-readable bytes"
        set -l b $argv[1]
        if test $b -ge 1073741824 2>/dev/null
            math --scale 2 "$b / 1073741824" | read -l n; echo "$n GiB"
        else if test $b -ge 1048576 2>/dev/null
            math --scale 2 "$b / 1048576" | read -l n; echo "$n MiB"
        else if test $b -ge 1024 2>/dev/null
            math --scale 1 "$b / 1024" | read -l n; echo "$n KiB"
        else
            echo "${b}B"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 STATS MODE                                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$_mode" = stats
        printf "\n  $BOLD$BLUE╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$BLUE║  🐳  Docker Resource Usage                           ║$R\n"
        printf "  $BOLD$BLUE╚══════════════════════════════════════════════════════╝$R\n\n"

        docker system df 2>/dev/null | while read -l line
            if string match -q 'TYPE*' $line
                printf "  $BOLD$CYAN%s$R\n" $line
            else
                printf "  %s\n" $line
            end
        end

        printf "\n  $BOLD Running containers:$R\n"
        docker ps --format "    $GREEN●$R  {{.Names}}  $DIM({{.Image}})$R  {{.Status}}" 2>/dev/null | \
            while read -l line; printf "%s\n" $line; end

        printf "\n  $BOLD Disk usage detail:$R\n"
        printf "    $DIM%-20s$R  %s\n" "Images:" (docker system df --format '{{.ImagesSize}}' 2>/dev/null | head -1)
        printf "    $DIM%-20s$R  %s\n" "Containers:" (docker system df --format '{{.ContainersSize}}' 2>/dev/null | head -1)
        printf "    $DIM%-20s$R  %s\n" "Build cache:" (docker system df --format '{{.BuildCacheSize}}' 2>/dev/null | head -1)

        printf "\n"
        functions --erase __dkc_help __dkc_ok __dkc_del __dkc_info \
            __dkc_warn __dkc_dry __dkc_section __dkc_human 2>/dev/null
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 STATUS MODE: Show what can be cleaned                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$_mode" = status
        printf "\n  $BOLD$BLUE  🐳 Docker Cleanup Opportunities$R\n\n"

        set -l stopped_ct   (docker ps -aq --filter status=exited 2>/dev/null | wc -l | string trim)
        set -l dangling_img (docker images -f dangling=true -q 2>/dev/null | wc -l | string trim)
        set -l total_img    (docker images -q 2>/dev/null | wc -l | string trim)
        set -l unused_vol   (docker volume ls -q --filter dangling=true 2>/dev/null | wc -l | string trim)
        set -l total_vol    (docker volume ls -q 2>/dev/null | wc -l | string trim)

        printf "  $BOLD%-28s$R  $CYAN%s$R\n" "Stopped containers:" $stopped_ct
        printf "  $BOLD%-28s$R  $CYAN%s$R\n" "Dangling images:" $dangling_img
        printf "  $BOLD%-28s$R  $CYAN%s$R\n" "Total images:" $total_img
        printf "  $BOLD%-28s$R  $CYAN%s$R\n" "Unused volumes:" $unused_vol
        printf "  $BOLD%-28s$R  $CYAN%s$R\n" "Total volumes:" $total_vol

        set -l total_reclaimable (math $stopped_ct + $dangling_img + $unused_vol)
        printf "\n"

        if test $total_reclaimable -gt 0
            printf "  $YELLOW💡$R  %d resource(s) ready to remove\n" $total_reclaimable
            printf "  $DIM  Run: docker_cleanup safe   for safe cleanup$R\n"
            printf "  $DIM  Run: docker_cleanup all    for full cleanup$R\n"
        else
            printf "  $GREEN✓$R  Docker resources are clean!\n"
        end
        printf "\n"
        functions --erase __dkc_help __dkc_ok __dkc_del __dkc_info \
            __dkc_warn __dkc_dry __dkc_section __dkc_human 2>/dev/null
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  BANNER                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _docker_ver (docker --version 2>/dev/null | awk '{print $3}' | string replace ',' '')
    set -l _ts_start   (date +%s)

    if test $_quiet -eq 0
        printf "\n"
        printf "  $BOLD$BLUE╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$BLUE║  🐳  Docker Cleanup: %-32s║$R\n" \
            "$_mode  $(test $_dry_run -eq 1 && echo '[DRY-RUN]')"
        printf "  $BOLD$BLUE╚══════════════════════════════════════════════════════╝$R\n\n"
    end

    set -l _del_count 0
    set -l _freed_bytes 0

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🧹 CONTAINER CLEANUP                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_clean_containers --description "Clean containers"
        set -l filter "--filter status=exited --filter status=dead --filter status=created"
        test $_all_res -eq 1 && set filter ""

        set -l containers (eval "docker ps -aq $filter" 2>/dev/null)

        if test -z "$containers"
            __dkc_ok "No containers to remove"
            return 0
        end

        set -l ct_count (echo $containers | wc -w | string trim)
        __dkc_info "Found $ct_count container(s) to remove"

        if test $_dry_run -eq 1
            for ct in $containers
                set -l name (docker inspect --format '{{.Name}}' $ct 2>/dev/null | string trim -c '/')
                __dkc_dry "container: $name ($ct)"
            end
            return 0
        end

        # Stop running ones first if --all
        if test $_all_res -eq 1
            set -l running (docker ps -q 2>/dev/null)
            if test -n "$running"
                __dkc_warn "Stopping running containers..."
                docker stop $running 2>/dev/null >/dev/null
            end
        end

        docker container prune -f 2>/dev/null >/dev/null
        and begin
            __dkc_ok "$ct_count container(s) removed"
            set -g _del_count (math $_del_count + $ct_count)
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖼️  IMAGE CLEANUP                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_clean_images --description "Clean images"
        set -l prune_flag ""
        test $_all_res -eq 1 && set prune_flag "--all"

        set -l images (eval "docker images -q $prune_flag" 2>/dev/null | sort -u)

        if test -z "$images"
            __dkc_ok "No images to remove"
            return 0
        end

        set -l img_count (echo $images | wc -w | string trim)
        __dkc_info "Found $img_count image(s) to remove"

        if test $_dry_run -eq 1
            for img in $images
                set -l tag (docker inspect --format '{{.RepoTags}}' $img 2>/dev/null | \
                    string replace '[' '' | string replace ']' '' | awk '{print $1}')
                test -z "$tag" && set tag "<dangling>"
                __dkc_dry "image: $tag ($img)"
            end
            return 0
        end

        docker image prune -f $prune_flag 2>/dev/null >/dev/null
        and begin
            __dkc_ok "Images pruned"
            set -g _del_count (math $_del_count + $img_count)
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  💾 VOLUME CLEANUP                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_clean_volumes --description "Clean unused volumes"
        set -l volumes (docker volume ls -q --filter dangling=true 2>/dev/null)

        if test -z "$volumes"
            __dkc_ok "No unused volumes to remove"
            return 0
        end

        set -l vol_count (echo $volumes | wc -w | string trim)
        __dkc_info "Found $vol_count unused volume(s)"

        if test $_dry_run -eq 1
            for vol in $volumes
                __dkc_dry "volume: $vol"
            end
            return 0
        end

        if test $_force -eq 0 && test $_mode != all && test $_mode != safe
            read -P "  Remove $vol_count volume(s)? Data will be LOST. [y/N] " confirm
            string match -qi 'y*' $confirm || begin
                __dkc_info "Volumes skipped"
                return 0
            end
        end

        docker volume prune -f 2>/dev/null >/dev/null
        and begin
            __dkc_ok "$vol_count volume(s) removed"
            set -g _del_count (math $_del_count + $vol_count)
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🌐 NETWORK CLEANUP                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_clean_networks --description "Clean unused networks"
        set -l networks (docker network ls -q --filter type=custom 2>/dev/null)

        if test -z "$networks"
            __dkc_ok "No custom networks to prune"
            return 0
        end

        if test $_dry_run -eq 1
            __dkc_dry "network prune (unused custom networks)"
            return 0
        end

        docker network prune -f 2>/dev/null >/dev/null
        and __dkc_ok "Unused networks removed"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🏗️  BUILD CACHE CLEANUP                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dkc_clean_cache --description "Clean build cache"
        set -l cache_size (docker system df --format '{{.BuildCacheSize}}' 2>/dev/null | head -1)
        __dkc_info "Build cache size: $cache_size"

        if test $_dry_run -eq 1
            __dkc_dry "builder prune (build cache: $cache_size)"
            return 0
        end

        docker builder prune -f 2>/dev/null >/dev/null
        and __dkc_ok "Build cache cleared"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_mode

        # ── SAFE: Remove stopped containers, dangling images, unused networks ──
        case safe
            __dkc_section "🐳" "Safe Docker Cleanup"

            __dkc_info "Removing stopped containers..."
            __dkc_clean_containers

            __dkc_info "Removing dangling images..."
            docker image prune -f 2>/dev/null >/dev/null
            and __dkc_ok "Dangling images removed"

            __dkc_info "Removing unused networks..."
            __dkc_clean_networks

            __dkc_info "Removing unused volumes..."
            __dkc_clean_volumes

        # ── ALL: Full nuclear cleanup ──────────────────────────────────────────
        case all
            printf "  $BOLD$RED\n  ⚠  FULL DOCKER CLEANUP — ALL unused resources will be removed\n\n$R"

            if test $_force -eq 0
                read -P "  Type 'clean' to confirm: " confirm
                test "$confirm" = clean || begin
                    printf "  $DIM  Cancelled$R\n\n"; return 0
                end
            end

            __dkc_section "🐳" "Full Docker Cleanup"

            set _all_res 1

            __dkc_info "Stopping all running containers..."
            set -l running (docker ps -q 2>/dev/null)
            if test -n "$running"
                test $_dry_run -eq 0 && docker stop $running 2>/dev/null >/dev/null
                test $_dry_run -eq 1 && __dkc_dry "stop all running containers"
            end

            __dkc_clean_containers
            __dkc_clean_images
            __dkc_clean_volumes
            __dkc_clean_networks
            __dkc_clean_cache

            # Final: full system prune
            if test $_dry_run -eq 0
                docker system prune -af --volumes 2>/dev/null >/dev/null
                __dkc_ok "Full system prune complete"
            else
                __dkc_dry "docker system prune -af --volumes"
            end

        # ── CONTAINERS only ───────────────────────────────────────────────────
        case containers
            __dkc_section "📦" "Container Cleanup"

            if command -q fzf && test $_dry_run -eq 0
                # Interactive picker
                set -l selected (
                    docker ps -a \
                        --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null |
                    fzf --ansi \
                        --multi \
                        --border-label "  🐳 Select Containers to Remove " \
                        --border rounded \
                        --prompt "  📦 " \
                        --pointer "▶" \
                        --marker "✓" \
                        --preview 'docker inspect {1} 2>/dev/null | python3 -m json.tool | head -30' \
                        --preview-window 'right:50%:border-rounded' \
                        --header '  Tab:multi  Enter:remove  Ctrl-S:stop first  ' \
                        --bind 'ctrl-s:execute(docker stop {1})+reload(docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}")' \
                        --height 70% |
                    awk '{print $1}'
                )
                for ct in $selected
                    docker rm -f $ct 2>/dev/null
                    and __dkc_del $ct
                    and set _del_count (math $_del_count + 1)
                end
            else
                __dkc_clean_containers
            end

        # ── IMAGES only ───────────────────────────────────────────────────────
        case images
            __dkc_section "🖼️ " "Image Cleanup"

            if command -q fzf && test $_dry_run -eq 0
                set -l selected (
                    docker images \
                        --format "{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" \
                        2>/dev/null |
                    fzf --ansi \
                        --multi \
                        --border-label "  🐳 Select Images to Remove " \
                        --border rounded \
                        --prompt "  🖼️  " \
                        --pointer "▶" \
                        --marker "✓" \
                        --preview 'docker inspect {1} 2>/dev/null | python3 -m json.tool | head -25' \
                        --preview-window 'right:50%:border-rounded' \
                        --header '  Tab:multi  Enter:remove  ' \
                        --height 70% |
                    awk '{print $1}'
                )
                for img in $selected
                    docker rmi -f $img 2>/dev/null
                    and __dkc_del $img
                    and set _del_count (math $_del_count + 1)
                end
            else
                __dkc_clean_images
            end

        # ── VOLUMES only ──────────────────────────────────────────────────────
        case volumes
            __dkc_section "💾" "Volume Cleanup"
            set _force 1
            __dkc_clean_volumes

        # ── NETWORKS only ─────────────────────────────────────────────────────
        case networks
            __dkc_section "🌐" "Network Cleanup"
            __dkc_clean_networks

        # ── DANGLING images only ──────────────────────────────────────────────
        case dangling
            __dkc_section "🏷️ " "Dangling Image Cleanup"
            __dkc_info "Removing dangling (untagged) images..."

            if test $_dry_run -eq 1
                set -l count (docker images -f dangling=true -q 2>/dev/null | wc -l | string trim)
                __dkc_dry "$count dangling images would be removed"
            else
                docker image prune -f 2>/dev/null >/dev/null
                and __dkc_ok "Dangling images removed"
            end

        # ── EXITED containers only ────────────────────────────────────────────
        case exited
            __dkc_section "⏹️ " "Exited Container Cleanup"
            __dkc_clean_containers

        # ── OLD images (by age) ────────────────────────────────────────────────
        case old
            __dkc_section "📅" "Old Image Cleanup (>$_days days)"

            set -l old_images (
                docker images --format "{{.ID}}\t{{.CreatedAt}}" 2>/dev/null | \
                while read -l line
                    set -l parts (string split \t $line)
                    set -l img_id $parts[1]
                    set -l created $parts[2]

                    # Parse date and check age
                    set -l created_ts (date -d "$created" +%s 2>/dev/null; \
                        or date -jf "%Y-%m-%d %H:%M:%S" "$created" +%s 2>/dev/null)
                    set -l now_ts (date +%s)
                    set -l age_days (math --scale 0 "($now_ts - $created_ts) / 86400" 2>/dev/null)

                    test $age_days -gt $_days 2>/dev/null && echo $img_id
                end
            )

            if test -z "$old_images"
                printf "  $GREEN✓$R  No images older than $_days days\n\n"
            else
                set -l count (echo $old_images | wc -w | string trim)
                __dkc_info "$count images older than $_days days"

                for img in $old_images
                    set -l tag (docker inspect --format '{{.RepoTags}}' $img 2>/dev/null | \
                        string replace -a '[' '' | string replace -a ']' '' | string trim | awk '{print $1}')
                    test -z "$tag" && set tag "<untagged>"

                    if test $_dry_run -eq 1
                        __dkc_dry "image: $tag"
                    else
                        docker rmi -f $img 2>/dev/null
                        and __dkc_del $tag
                        and set _del_count (math $_del_count + 1)
                    end
                end
            end

        # ── CACHE only ────────────────────────────────────────────────────────
        case cache
            __dkc_section "🏗️ " "Build Cache Cleanup"
            __dkc_clean_cache

        # ── INTERACTIVE (default) ─────────────────────────────────────────────
        case '*' pick
            if not command -q fzf
                printf "  $YELLOW⚠$R  fzf not found — running 'safe' mode\n\n"
                set _mode safe
                # Fall through to safe
                __dkc_clean_containers
                docker image prune -f 2>/dev/null >/dev/null
                __dkc_clean_networks
            else
                # Build menu
                set -l menu_items \
                    "🐳 Safe cleanup      | stopped containers + dangling images + unused networks" \
                    "📦 Containers        | remove stopped/exited containers" \
                    "🖼️  Images            | remove unused/dangling images" \
                    "💾 Volumes           | remove unused volumes (DATA LOSS)" \
                    "🌐 Networks          | remove unused networks" \
                    "🏗️  Build cache       | clear Docker build cache" \
                    "📅 Old images (30d)  | remove images older than 30 days" \
                    "💣 Full cleanup      | remove ALL unused resources"

                set -l selection (
                    printf '%s\n' $menu_items |
                    fzf --ansi \
                        --border-label "  🐳 Docker Cleanup Menu " \
                        --border rounded \
                        --prompt "  🐳 " \
                        --pointer "▶" \
                        --preview '
                            docker system df 2>/dev/null
                            echo ""
                            echo "Running containers:"
                            docker ps --format "  ● {{.Names}} ({{.Image}})" 2>/dev/null | head -10
                        ' \
                        --preview-window 'right:45%:border-rounded' \
                        --header '  Select cleanup action  ' \
                        --no-multi \
                        --height 60%
                )

                test -z "$selection" && begin; printf "  $DIM  Cancelled$R\n\n"; return 0; end

                # Map selection to mode
                switch $selection
                    case '*Safe*';      set _mode safe
                    case '*Containers*'; set _mode containers
                    case '*Images*';     set _mode images
                    case '*Volumes*';    set _mode volumes
                    case '*Networks*';   set _mode networks
                    case '*cache*';      set _mode cache
                    case '*Old*';        set _mode old
                    case '*Full*';       set _mode all; set _force 1
                end

                # Re-dispatch
                docker_cleanup $_mode (test $_dry_run -eq 1 && echo --dry-run)
                return $status
            end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 SUMMARY                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╗

    set -l _elapsed (math (date +%s) - $_ts_start)

    printf "\n  $DIM%s$R\n" (string repeat -n 55 "─")

    if test $_dry_run -eq 1
        printf "  $YELLOW⚠$R  DRY-RUN complete — no changes made\n"
    else
        printf "  $GREEN✓$R  Docker cleanup done  $DIM·$R  $DIM%ds$R\n" $_elapsed
    end

    # Show final disk usage
    docker system df 2>/dev/null | while read -l line
        printf "  $DIM%s$R\n" $line
    end
    printf "\n"

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __dkc_help __dkc_ok __dkc_del __dkc_info __dkc_warn \
        __dkc_dry __dkc_section __dkc_human __dkc_clean_containers \
        __dkc_clean_images __dkc_clean_volumes __dkc_clean_networks \
        __dkc_clean_cache 2>/dev/null

end
