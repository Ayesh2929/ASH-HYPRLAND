# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Docker Ultra Configuration                         ║
# ║  Docker, Docker Compose, Buildx, multi-arch & full container ecosystem     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_docker_loaded && exit 0
set --global _ash_docker_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Exit early if Docker not available
if not command -q docker
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_docker_log        "$HOME/.local/share/ash/logs/docker.log"
set --global _ash_docker_cache      "$HOME/.local/share/ash/cache/docker"
set --global _ash_docker_cache_ttl  30   # seconds

mkdir -p (dirname $_ash_docker_log) 2>/dev/null
mkdir -p $_ash_docker_cache 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI PRIMITIVES                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _dk_reset   (set_color normal)
set -g _dk_bold    (set_color --bold)
set -g _dk_blue    (set_color 0db7ed)   # Docker blue
set -g _dk_cyan    (set_color cyan)
set -g _dk_green   (set_color green)
set -g _dk_yellow  (set_color yellow)
set -g _dk_red     (set_color red)
set -g _dk_purple  (set_color magenta)
set -g _dk_dim     (set_color brblack)
set -g _dk_white   (set_color white)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT CONFIGURATION                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Docker host (support rootless Docker)
if test -S "$XDG_RUNTIME_DIR/docker.sock"
    set --export DOCKER_HOST "unix://$XDG_RUNTIME_DIR/docker.sock"
else if test -S "/var/run/docker.sock"
    set --export DOCKER_HOST "unix:///var/run/docker.sock"
end

# Docker BuildKit (faster builds, better caching, multi-platform)
set --export DOCKER_BUILDKIT        1
set --export COMPOSE_DOCKER_CLI_BUILD 1

# Compose v2 settings
set --export COMPOSE_MENU           0
set --export COMPOSE_ANSI           auto

# BuildKit inline cache
set --export BUILDKIT_INLINE_CACHE  1

# Docker content trust (disable for dev speed)
set --export DOCKER_CONTENT_TRUST   0

# Colima support (macOS Docker alternative)
if command -q colima && test -S "$HOME/.colima/default/docker.sock"
    set --export DOCKER_HOST "unix://$HOME/.colima/default/docker.sock"
end

# Podman compatibility alias
if not command -q docker && command -q podman
    alias docker=podman
    alias docker-compose='podman-compose'
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 UI HELPERS                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __dk_header --description "Print a Docker section header"
    set -l title $argv[1]
    set -l width 54
    set -l padded (string pad --right --width $width $title)
    echo ""
    echo $_dk_bold$_dk_blue"  ╔══════════════════════════════════════════════════════╗"$_dk_reset
    echo $_dk_bold$_dk_blue"  ║  $_dk_white$padded$_dk_blue  ║"$_dk_reset
    echo $_dk_bold$_dk_blue"  ╚══════════════════════════════════════════════════════╝"$_dk_reset
    echo ""
end

function __dk_log --description "Write to Docker log"
    echo "["(date '+%Y-%m-%d %H:%M:%S')"] $argv" >> $_ash_docker_log 2>/dev/null
end

function __dk_cached --description "Return cached output or compute and cache"
    set -l key   $argv[1]
    set -l cmd   $argv[2..-1]
    set -l cache "$_ash_docker_cache/$key"

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        if test $age -lt $_ash_docker_cache_ttl
            cat $cache; return
        end
    end

    set -l result (eval $cmd 2>/dev/null)
    echo $result > $cache 2>/dev/null
    echo $result
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DYNAMIC COMPLETION SOURCES                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __dk_containers --description "List running container names"
    docker ps --format '{{.Names}}\t{{.Image}} ({{.Status}})' 2>/dev/null
end

function __dk_containers_all --description "List all container names"
    docker ps -a --format '{{.Names}}\t{{.Image}} ({{.Status}})' 2>/dev/null
end

function __dk_images --description "List local Docker images"
    docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}} — {{.CreatedSince}}' 2>/dev/null | \
        grep -v '<none>'
end

function __dk_volumes --description "List Docker volumes"
    docker volume ls --format '{{.Name}}\t{{.Driver}}' 2>/dev/null
end

function __dk_networks --description "List Docker networks"
    docker network ls --format '{{.Name}}\t{{.Driver}} ({{.Scope}})' 2>/dev/null
end

function __dk_contexts --description "List Docker contexts"
    docker context ls --format '{{.Name}}\t{{.DockerEndpoint}}' 2>/dev/null
end

function __dk_compose_services --description "List services from compose file"
    set -l compose_file
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml
        if test -f $f
            set compose_file $f; break
        end
    end
    test -z "$compose_file" && return
    command -q docker && docker compose config --services 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 DOCKER INFO DASHBOARD                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function docker-info-rich --description "Show rich Docker system dashboard"
    __dk_header "🐳  Docker System Dashboard"

    # Daemon info
    set -l version (docker version --format '{{.Server.Version}}' 2>/dev/null; or echo "unreachable")
    set -l engine  (docker version --format '{{.Server.Os}}/{{.Server.Arch}}' 2>/dev/null)

    echo "  "$_dk_bold"Engine:     "$_dk_reset $_dk_blue$version$_dk_reset "  "$_dk_dim$engine$_dk_reset
    echo "  "$_dk_bold"Host:       "$_dk_reset $_dk_dim$DOCKER_HOST$_dk_reset
    echo "  "$_dk_bold"BuildKit:   "$_dk_reset (test "$DOCKER_BUILDKIT" = 1 && echo $_dk_green"enabled"$_dk_reset || echo $_dk_dim"disabled"$_dk_reset)
    echo ""

    # Resource counts
    set -l running   (docker ps -q 2>/dev/null | count)
    set -l total     (docker ps -aq 2>/dev/null | count)
    set -l images    (docker images -q 2>/dev/null | count)
    set -l volumes   (docker volume ls -q 2>/dev/null | count)
    set -l networks  (docker network ls -q 2>/dev/null | count)

    echo "  "$_dk_bold"Resources:"$_dk_reset
    printf "    $_dk_green%-14s$_dk_reset %s containers\n" "Running:" "$running / $total total"
    printf "    $_dk_cyan%-14s$_dk_reset %s\n"  "Images:"   $images
    printf "    $_dk_yellow%-14s$_dk_reset %s\n" "Volumes:"  $volumes
    printf "    $_dk_purple%-14s$_dk_reset %s\n" "Networks:" $networks
    echo ""

    # Disk usage
    echo "  "$_dk_bold"Disk Usage:"$_dk_reset
    docker system df 2>/dev/null | while read -l line
        echo "    "$_dk_dim$line$_dk_reset
    end
    echo ""

    # Active context
    set -l ctx (docker context show 2>/dev/null)
    echo "  "$_dk_bold"Context:    "$_dk_reset $_dk_cyan$ctx$_dk_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📦 CONTAINER MANAGEMENT                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-ls: Rich container listing ───────────────────────────────────────
function docker-ls --description "Rich interactive container listing"
    set -l show_all $argv[1]
    set -l flag     ""
    test "$show_all" = all || test "$show_all" = -a && set flag "--all"

    __dk_header "🐳  Containers"

    docker ps $flag \
        --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}" \
        2>/dev/null | \
    while read -l line
        if string match -q 'NAMES*' $line
            echo "  "$_dk_bold$_dk_blue$line$_dk_reset
        else
            # Color by status
            if string match -q 'Up*' $line
                echo "  "$_dk_green$line$_dk_reset
            else if string match -q 'Exited*' $line
                echo "  "$_dk_dim$line$_dk_reset
            else if string match -q 'Paused*' $line
                echo "  "$_dk_yellow$line$_dk_reset
            else
                echo "  "$line
            end
        end
    end
    echo ""
end

# ─── docker-exec-smart: Intelligent container shell ───────────────────────────
function docker-exec-smart --description "Smart exec into container with best shell"
    set -l container $argv[1]
    set -l cmd       $argv[2]

    # Interactive fuzzy picker if no container given
    if test -z "$container"
        set container (
            docker ps --format '{{.Names}}\t{{.Image}} — {{.Status}}' 2>/dev/null |
            fzf --ansi \
                --border-label "  🐳 Select Container " \
                --border rounded \
                --prompt "  " \
                --pointer "▶" \
                --marker "✓" \
                --preview 'docker inspect {1} 2>/dev/null | python3 -m json.tool | head -40' \
                --preview-window 'right:45%:border-rounded' \
                --header '  Enter:exec  Ctrl-L:logs  Ctrl-I:inspect  ' \
                --bind 'ctrl-l:execute(docker logs -f {1} | less -R)' \
                --bind 'ctrl-i:execute(docker inspect {1} | python3 -m json.tool | less)' \
            | awk '{print $1}'
        )
        test -z "$container" && return 0
    end

    if test -z "$cmd"
        # Try shells in order of preference
        for shell in bash zsh fish sh
            if docker exec $container which $shell &>/dev/null
                docker exec -it $container $shell
                return
            end
        end
        docker exec -it $container sh
    else
        docker exec -it $container $cmd
    end
end

# ─── docker-logs-smart: Interactive log viewer ────────────────────────────────
function docker-logs-smart --description "Interactive Docker log viewer with filtering"
    set -l container $argv[1]
    set -l lines     $argv[2]
    test -z "$lines" && set lines 100

    if test -z "$container"
        set container (
            docker ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null |
            fzf --border-label "  📋 Select Container for Logs " \
                --border rounded \
                --prompt "  " \
                --pointer "▶" \
                --preview 'docker logs --tail=20 {1} 2>/dev/null' \
                --preview-window 'down:40%:border-rounded:wrap' \
            | awk '{print $1}'
        )
        test -z "$container" && return 0
    end

    # Pipe logs through bat or less
    if command -q bat
        docker logs -f --tail=$lines $container 2>&1 | \
            bat --language=log --style=plain --color=always --paging=never
    else
        docker logs -f --tail=$lines $container 2>&1
    end
end

# ─── docker-stop-all: Stop all running containers ─────────────────────────────
function docker-stop-all --description "Stop all running Docker containers"
    set -l running (docker ps -q 2>/dev/null)

    if test -z "$running"
        echo $_dk_yellow"  ℹ  No running containers"$_dk_reset
        return
    end

    set -l count (echo $running | wc -w)
    echo ""
    echo $_dk_yellow"  ⏹  Stopping $count container(s)..."$_dk_reset
    echo $running | xargs docker stop
    echo $_dk_green"  ✓ All containers stopped"$_dk_reset
    echo ""
end

# ─── docker-rm-stopped: Remove all stopped containers ─────────────────────────
function docker-rm-stopped --description "Remove all stopped containers"
    set -l stopped (docker ps -aq --filter status=exited 2>/dev/null)

    if test -z "$stopped"
        echo $_dk_dim"  ℹ  No stopped containers"$_dk_reset
        return
    end

    set -l count (echo $stopped | wc -w)
    echo ""
    echo $_dk_yellow"  🗑  Removing $count stopped container(s)..."$_dk_reset
    docker container prune -f
    echo $_dk_green"  ✓ Stopped containers removed"$_dk_reset
    echo ""
end

# ─── docker-kill-all: Kill all running containers ─────────────────────────────
function docker-kill-all --description "Kill all running Docker containers"
    set -l running (docker ps -q 2>/dev/null)
    test -z "$running" && begin; echo $_dk_dim"  No running containers"$_dk_reset; return; end

    echo ""
    echo $_dk_red"  💀 Killing all running containers..."$_dk_reset
    echo $running | xargs docker kill
    echo $_dk_green"  ✓ All containers killed"$_dk_reset
    echo ""
end

# ─── docker-stats-rich: Rich resource stats ───────────────────────────────────
function docker-stats-rich --description "Show rich Docker container resource stats"
    docker stats \
        --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" \
        $argv
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖼️  IMAGE MANAGEMENT                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-images-rich: Rich image listing ───────────────────────────────────
function docker-images-rich --description "Rich Docker image listing with sizes"
    __dk_header "🖼️   Docker Images"

    docker images \
        --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" \
        2>/dev/null | \
    while read -l line
        if string match -q 'REPOSITORY*' $line
            echo "  "$_dk_bold$_dk_blue$line$_dk_reset
        else
            echo "  "$line
        end
    end
    echo ""

    # Total size
    set -l total (docker system df --format '{{.ImagesSize}}' 2>/dev/null | head -1)
    echo "  "$_dk_dim"Total images size: $total"$_dk_reset
    echo ""
end

# ─── docker-rmi-dangling: Remove dangling images ──────────────────────────────
function docker-rmi-dangling --description "Remove all dangling (untagged) images"
    set -l dangling (docker images -f dangling=true -q 2>/dev/null)

    if test -z "$dangling"
        echo $_dk_dim"  ℹ  No dangling images found"$_dk_reset
        return
    end

    set -l count (echo $dangling | wc -w)
    echo ""
    echo $_dk_yellow"  🗑  Removing $count dangling image(s)..."$_dk_reset
    docker image prune -f
    echo $_dk_green"  ✓ Dangling images removed"$_dk_reset
    echo ""
end

# ─── docker-rmi-all: Remove all images ───────────────────────────────────────
function docker-rmi-all --description "Remove ALL Docker images (with confirmation)"
    set -l images (docker images -q 2>/dev/null)
    test -z "$images" && begin; echo $_dk_dim"  No images found"$_dk_reset; return; end

    set -l count (echo $images | wc -w)
    echo ""
    echo $_dk_red"  ⚠  This will remove ALL $count image(s)!"$_dk_reset
    read -P "  Confirm? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    docker rmi -f $images
    echo $_dk_green"  ✓ All images removed"$_dk_reset
    echo ""
end

# ─── docker-pull-latest: Pull & update all tagged images ──────────────────────
function docker-pull-latest --description "Update all local Docker images to latest"
    echo ""
    echo $_dk_cyan"  🔄 Pulling latest versions of all images..."$_dk_reset
    echo ""

    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | \
        grep -v '<none>' | \
        sort -u | \
        while read -l image
            echo "  "$_dk_dim"Pulling: "$image$_dk_reset
            docker pull $image 2>/dev/null
            and echo $_dk_green"    ✓ "$image$_dk_reset
            or  echo $_dk_yellow"    ⚠ skipped: "$image$_dk_reset
        end
    echo ""
end

# ─── docker-dive: Inspect image layers ────────────────────────────────────────
function docker-dive --description "Inspect Docker image layers with dive"
    set -l image $argv[1]

    if test -z "$image"
        set image (
            __dk_images |
            fzf --border-label "  🔍 Select Image to Inspect " \
                --border rounded \
                --prompt "  🖼️  " \
            | awk '{print $1}'
        )
        test -z "$image" && return 0
    end

    if command -q dive
        dive $image
    else
        echo $_dk_yellow"  💡 Install dive for layer inspection: https://github.com/wagoodman/dive"$_dk_reset
        echo ""
        echo "  Showing layers via docker history:"
        docker history --human --format "table {{.ID}}\t{{.CreatedBy}}\t{{.Size}}" $image
    end
end

# ─── docker-build-smart: Build with progress & tags ───────────────────────────
function docker-build-smart --description "Smart docker build with tag, cache, and progress"
    set -l tag      $argv[1]
    set -l context  $argv[2]
    set -l platform $argv[3]

    test -z "$context" && set context "."

    if test -z "$tag"
        # Auto-tag from directory name + git branch
        set -l dir_name (basename $PWD | string lower)
        set -l branch   (git branch --show-current 2>/dev/null | string replace '/' '-')
        test -n "$branch" && set tag "$dir_name:$branch" || set tag "$dir_name:latest"
        echo $_dk_dim"  Auto-tag: $tag"$_dk_reset
    end

    set -l build_cmd docker build \
        --tag $tag \
        --progress=plain \
        --label "built-at="(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --label "git-commit="(git rev-parse --short HEAD 2>/dev/null; or echo "none")

    if test -n "$platform"
        set build_cmd $build_cmd --platform $platform
    end

    echo ""
    echo $_dk_cyan"  🔨 Building: $tag"$_dk_reset
    echo ""

    set -l ts (date +%s)
    eval $build_cmd $context $argv[4..-1]
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)

    echo ""
    if test $rc -eq 0
        echo $_dk_green"  ✓ Build successful: $tag"$_dk_reset
        echo $_dk_dim"  ⏱  Build time: $elapsed"s$_dk_reset
    else
        echo $_dk_red"  ✗ Build failed after $elapsed"s$_dk_reset
    end
    echo ""
    return $rc
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 VOLUME & NETWORK MANAGEMENT                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-volumes-rich: Rich volume listing ─────────────────────────────────
function docker-volumes-rich --description "Rich Docker volume listing with sizes"
    __dk_header "💾  Docker Volumes"

    docker volume ls --format '{{.Name}}\t{{.Driver}}\t{{.Mountpoint}}' 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $_dk_cyan%-35s$_dk_reset  $_dk_dim%-10s$_dk_reset  %s\n" \
            $parts[1] $parts[2] $_dk_dim$parts[3]$_dk_reset
    end
    echo ""
end

# ─── docker-networks-rich: Rich network listing ───────────────────────────────
function docker-networks-rich --description "Rich Docker network listing"
    __dk_header "🌐  Docker Networks"

    docker network ls \
        --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}\t{{.ID}}" \
        2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_dk_bold$_dk_blue$line$_dk_reset
        else
            echo "  "$line
        end
    end
    echo ""
end

# ─── docker-network-inspect: Show network containers ──────────────────────────
function docker-network-inspect --description "Inspect a Docker network and show connected containers"
    set -l net $argv[1]

    if test -z "$net"
        set net (
            __dk_networks |
            fzf --border-label "  🌐 Select Network " \
                --border rounded \
                --prompt "  " \
            | awk '{print $1}'
        )
        test -z "$net" && return 0
    end

    docker network inspect $net 2>/dev/null | \
        command -q python3 && python3 -m json.tool | \
        command -q bat && bat --language=json --style=plain || cat
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🧹 SYSTEM CLEANUP                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-clean: Smart tiered cleanup ───────────────────────────────────────
function docker-clean --description "Smart Docker cleanup with options"
    set -l level $argv[1]
    test -z "$level" && set level "safe"

    echo ""
    echo $_dk_cyan"  🧹 Docker cleanup ($level)..."$_dk_reset
    echo ""

    switch $level
        case safe
            # Remove stopped containers, dangling images, unused networks
            docker container prune -f
            docker image prune -f
            docker network prune -f
            echo $_dk_green"  ✓ Removed: stopped containers, dangling images, unused networks"$_dk_reset

        case volumes
            docker container prune -f
            docker image prune -f
            docker network prune -f
            docker volume prune -f
            echo $_dk_green"  ✓ Removed: containers, images, networks, volumes"$_dk_reset

        case all
            echo $_dk_red"  ⚠  This removes ALL unused Docker data!"$_dk_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            docker system prune -af --volumes
            echo $_dk_green"  ✓ Full Docker cleanup complete"$_dk_reset

        case '*'
            echo "  Usage: docker-clean [safe|volumes|all]"
            return 1
    end

    # Show reclaimed space
    echo ""
    docker system df 2>/dev/null
    echo ""
end

# ─── docker-prune-images-old: Remove images older than N days ─────────────────
function docker-prune-images-old --description "Remove Docker images older than N days"
    set -l days $argv[1]
    test -z "$days" && set days 30

    echo ""
    echo $_dk_yellow"  🗑  Removing images older than $days days..."$_dk_reset
    docker image prune -a --force --filter "until=$days""d"
    echo $_dk_green"  ✓ Old images removed"$_dk_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐙 DOCKER COMPOSE                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Find compose file ────────────────────────────────────────────────────────
function __dk_compose_file --description "Find compose file in current or parent dirs"
    set -l dir (pwd)
    while test "$dir" != "/"
        for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml
            if test -f "$dir/$f"
                echo "$dir/$f"
                return
            end
        end
        set dir (dirname $dir)
    end
end

# ─── dcu: Compose up ──────────────────────────────────────────────────────────
function dcu --wraps='docker compose up' --description "docker compose up --detach"
    set -l ts (date +%s)
    docker compose up --detach --remove-orphans $argv
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)
    test $rc -eq 0 && echo $_dk_green"  ✓ Stack up ($elapsed"s")"$_dk_reset
    return $rc
end

# ─── dcub: Compose up with build ──────────────────────────────────────────────
function dcub --description "docker compose up --build --detach"
    set -l ts (date +%s)
    docker compose up --build --detach --remove-orphans $argv
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)
    test $rc -eq 0 && echo $_dk_green"  ✓ Stack built & up ($elapsed"s")"$_dk_reset
    return $rc
end

# ─── dcd: Compose down ────────────────────────────────────────────────────────
function dcd --wraps='docker compose down' --description "docker compose down"
    docker compose down --remove-orphans $argv
    and echo $_dk_green"  ✓ Stack down"$_dk_reset
end

# ─── dcdv: Compose down + volumes ─────────────────────────────────────────────
function dcdv --description "docker compose down --volumes"
    echo $_dk_yellow"  ⚠  Removing containers AND volumes..."$_dk_reset
    read -P "  Confirm? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0
    docker compose down --remove-orphans --volumes $argv
    and echo $_dk_green"  ✓ Stack and volumes removed"$_dk_reset
end

# ─── dcl: Compose logs ────────────────────────────────────────────────────────
function dcl --wraps='docker compose logs' --description "docker compose logs --follow"
    set -l service $argv[1]
    if test -n "$service"
        docker compose logs -f --tail=100 $argv
    else
        # Interactive service picker
        set -l svc (
            __dk_compose_services |
            fzf --border-label "  📋 Select Service for Logs " \
                --border rounded \
                --prompt "  " \
                --multi \
                --header '  Tab:multi-select  Enter:follow  '
        )
        test -z "$svc" && docker compose logs -f --tail=100 || docker compose logs -f --tail=100 $svc
    end
end

# ─── dce: Compose exec ────────────────────────────────────────────────────────
function dce --description "docker compose exec (interactive shell)"
    set -l service $argv[1]

    if test -z "$service"
        set service (
            __dk_compose_services |
            fzf --border-label "  🐳 Select Service " \
                --border rounded \
                --prompt "  " \
            | awk '{print $1}'
        )
        test -z "$service" && return 0
    end

    set -l shell $argv[2]
    test -z "$shell" && set shell sh

    # Try bash first, fallback to sh
    docker compose exec $service bash 2>/dev/null || docker compose exec $service sh
end

# ─── dcps: Compose ps (rich) ──────────────────────────────────────────────────
function dcps --wraps='docker compose ps' --description "docker compose ps (rich)"
    __dk_header "🐙  Compose Services"
    docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_dk_bold$_dk_blue$line$_dk_reset
        else if string match -q '*running*' $line
            echo "  "$_dk_green$line$_dk_reset
        else if string match -q '*exited*' $line
            echo "  "$_dk_dim$line$_dk_reset
        else
            echo "  "$line
        end
    end
    echo ""
end

# ─── dcr: Compose restart service ────────────────────────────────────────────
function dcr --description "docker compose restart (with service picker)"
    set -l service $argv[1]

    if test -z "$service"
        set service (
            __dk_compose_services |
            fzf --border-label "  🔄 Restart Service " \
                --border rounded \
                --prompt "  " \
                --multi \
                --header '  Tab:multi  Enter:restart  '
        )
        test -z "$service" && return 0
    end

    docker compose restart $service
    and echo $_dk_green"  ✓ Restarted: $service"$_dk_reset
end

# ─── dcpull: Pull all compose images ──────────────────────────────────────────
function dcpull --description "docker compose pull all images"
    echo ""
    echo $_dk_cyan"  🔄 Pulling latest compose images..."$_dk_reset
    docker compose pull $argv
    echo $_dk_green"  ✓ Images updated"$_dk_reset
    echo ""
end

# ─── compose-env: Show compose environment ────────────────────────────────────
function dcenv --description "Show effective docker compose environment"
    docker compose config --environment 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏗️  BUILDX & MULTI-PLATFORM                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-buildx-setup: Setup multi-platform builder ────────────────────────
function docker-buildx-setup --description "Create and configure a multi-platform buildx builder"
    set -l name $argv[1]
    test -z "$name" && set name "ash-builder"

    echo ""
    echo $_dk_cyan"  🏗️  Setting up multi-platform builder: $name"$_dk_reset
    echo ""

    # Create builder with QEMU emulation support
    docker buildx create \
        --name $name \
        --driver docker-container \
        --driver-opt image=moby/buildkit:buildx-stable-1 \
        --platform linux/amd64,linux/arm64,linux/arm/v7 \
        --use 2>/dev/null \
    or docker buildx use $name 2>/dev/null

    # Bootstrap
    docker buildx inspect --bootstrap 2>/dev/null
    echo ""
    echo $_dk_green"  ✓ Builder ready: $name"$_dk_reset
    echo ""

    # Show available platforms
    echo $_dk_dim"  Platforms: linux/amd64, linux/arm64, linux/arm/v7"$_dk_reset
    echo ""
end

# ─── docker-build-multi: Multi-platform build & push ──────────────────────────
function docker-build-multi --description "Build and push multi-platform Docker image"
    set -l image    $argv[1]
    set -l context  $argv[2]
    test -z "$context" && set context "."

    if test -z "$image"
        echo "  Usage: docker-build-multi <image:tag> [context]"
        return 1
    end

    set -l platforms "linux/amd64,linux/arm64"

    echo ""
    echo $_dk_cyan"  🏗️  Building multi-platform: $image"$_dk_reset
    echo "  Platforms: $platforms"
    echo ""

    set -l ts (date +%s)
    docker buildx build \
        --platform $platforms \
        --tag $image \
        --push \
        --progress=plain \
        $context $argv[3..-1]
    set -l elapsed (math (date +%s) - $ts)

    echo ""
    echo $_dk_green"  ✓ Multi-platform image pushed: $image ($elapsed"s")"$_dk_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔒 SECURITY & SCANNING                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-scan: Security vulnerability scan ─────────────────────────────────
function docker-scan --description "Scan Docker image for vulnerabilities"
    set -l image $argv[1]

    if test -z "$image"
        set image (
            __dk_images |
            fzf --border-label "  🔒 Select Image to Scan " \
                --border rounded \
                --prompt "  🔍 " \
            | awk '{print $1}'
        )
        test -z "$image" && return 0
    end

    echo ""
    echo $_dk_cyan"  🔒 Scanning: $image"$_dk_reset
    echo ""

    if command -q trivy
        trivy image --severity HIGH,CRITICAL $image
    else if command -q grype
        grype $image
    else if command -q snyk
        snyk container test $image
    else
        echo $_dk_yellow"  💡 Install trivy, grype, or snyk for image scanning"$_dk_reset
        docker scout cves $image 2>/dev/null \
            || echo $_dk_red"  ✗ No scanner available"$_dk_reset
    end
end

# ─── docker-sbom: Generate software bill of materials ─────────────────────────
function docker-sbom --description "Generate SBOM for a Docker image"
    set -l image $argv[1]
    test -z "$image" && begin; echo "  Usage: docker-sbom <image>"; return 1; end

    set -l output "sbom-"(string replace ':' '-' $image)".json"

    if command -q syft
        syft $image -o json > $output
        echo $_dk_green"  ✓ SBOM saved: $output"$_dk_reset
    else
        docker sbom $image 2>/dev/null > $output \
            and echo $_dk_green"  ✓ SBOM saved: $output"$_dk_reset \
            or echo $_dk_yellow"  💡 Install syft for full SBOM support"$_dk_reset
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐛 DEBUGGING & INSPECTION                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-inspect-rich: Pretty-printed inspect ──────────────────────────────
function docker-inspect-rich --description "Pretty-print docker inspect output"
    set -l resource $argv[1]

    if test -z "$resource"
        set resource (
            docker ps -a --format '{{.Names}}\t{{.Image}}' 2>/dev/null |
            fzf --border-label "  🔍 Inspect " \
                --border rounded \
            | awk '{print $1}'
        )
        test -z "$resource" && return 0
    end

    docker inspect $resource 2>/dev/null | \
        command -q python3 && python3 -m json.tool | \
        command -q bat && bat --language=json || cat
end

# ─── docker-port-map: Show all port mappings ──────────────────────────────────
function docker-port-map --description "Show all container port mappings"
    __dk_header "🔌  Port Mappings"

    docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        if test -n "$parts[2]" && test "$parts[2]" != ""
            printf "  $_dk_cyan%-25s$_dk_reset  $_dk_green%s$_dk_reset\n" $parts[1] $parts[2]
        end
    end
    echo ""
end

# ─── docker-env-list: Show container environment variables ────────────────────
function docker-env-list --description "Show environment variables of a container"
    set -l container $argv[1]

    if test -z "$container"
        set container (
            __dk_containers |
            fzf --border-label "  📋 Select Container " \
                --border rounded \
            | awk '{print $1}'
        )
        test -z "$container" && return 0
    end

    docker inspect $container \
        --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | \
        sort | \
        while read -l line
            set -l key (string split '=' $line)[1]
            set -l val (string split '=' $line)[2..-1] | string join '='
            printf "  $_dk_cyan%-30s$_dk_reset $_dk_dim%s$_dk_reset\n" $key $val
        end
end

# ─── docker-top-all: Show processes in all containers ─────────────────────────
function docker-top-all --description "Show top processes in all running containers"
    echo ""
    for container in (docker ps -q 2>/dev/null)
        set -l name (docker inspect $container --format '{{.Name}}' | string trim -c '/')
        echo $_dk_bold$_dk_blue"  ┌─ $name ───────────────────────────────────"$_dk_reset
        docker top $container 2>/dev/null | head -5 | while read -l line
            echo "  │ "$_dk_dim$line$_dk_reset
        end
        echo ""
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 REGISTRY OPERATIONS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── docker-push-retag: Retag and push image ──────────────────────────────────
function docker-push-retag --description "Retag a local image and push to registry"
    set -l source $argv[1]
    set -l target $argv[2]

    if test -z "$source" || test -z "$target"
        echo "  Usage: docker-push-retag <source:tag> <registry/image:tag>"
        return 1
    end

    echo ""
    echo $_dk_cyan"  🏷️  Retagging: $source → $target"$_dk_reset
    docker tag $source $target
    and begin
        echo $_dk_cyan"  ⬆  Pushing: $target"$_dk_reset
        docker push $target
        and echo $_dk_green"  ✓ Pushed: $target"$_dk_reset
    end
end

# ─── docker-login-all: Login to multiple registries ───────────────────────────
function docker-login-all --description "Login to common Docker registries"
    echo ""
    echo $_dk_cyan"  🔑 Docker Registry Login"$_dk_reset
    echo ""

    set -l registries \
        "Docker Hub:docker.io" \
        "GitHub GHCR:ghcr.io" \
        "GitLab:registry.gitlab.com"

    for reg_entry in $registries
        set -l parts (string split ':' $reg_entry)
        set -l name $parts[1]
        set -l host $parts[2]

        echo "  "$_dk_bold$name$_dk_reset" ($host)"
        read -P "  Login? [y/N] " do_login
        if string match -qi 'y*' $do_login
            docker login $host
        end
        echo ""
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 DOCKERFILE HELPERS                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── dockerfile-lint: Lint Dockerfile ────────────────────────────────────────
function dockerfile-lint --description "Lint Dockerfile with hadolint"
    set -l file $argv[1]
    test -z "$file" && set file "Dockerfile"

    if not test -f $file
        echo $_dk_red"  ✗ Not found: $file"$_dk_reset
        return 1
    end

    if command -q hadolint
        hadolint $file
    else if command -q docker
        docker run --rm -i hadolint/hadolint < $file
    else
        echo $_dk_yellow"  💡 Install hadolint: https://github.com/hadolint/hadolint"$_dk_reset
    end
end

# ─── dockerfile-new: Create Dockerfile templates ──────────────────────────────
function dockerfile-new --description "Create a Dockerfile template"
    set -l type $argv[1]
    test -z "$type" && set type node

    if test -f Dockerfile
        echo $_dk_yellow"  ⚠  Dockerfile already exists"$_dk_reset
        read -P "  Overwrite? [y/N] " confirm
        string match -qi 'y*' $confirm || return 0
    end

    switch $type
        case node nodejs
            printf '# ── Build stage ───────────────────────────────────────────────────────────\nFROM node:21-alpine AS builder\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci --only=production\n\n# ── Runtime stage ─────────────────────────────────────────────────────────\nFROM node:21-alpine AS runtime\nWORKDIR /app\nCOPY --from=builder /app/node_modules ./node_modules\nCOPY . .\nUSER node\nEXPOSE 3000\nHEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1\nCMD ["node", "dist/index.js"]\n' \
                > Dockerfile

        case python
            printf '# ── Build stage ───────────────────────────────────────────────────────────\nFROM python:3.12-slim AS builder\nWORKDIR /app\nCOPY requirements*.txt ./\nRUN pip install --no-cache-dir --user -r requirements.txt\n\n# ── Runtime stage ─────────────────────────────────────────────────────────\nFROM python:3.12-slim AS runtime\nWORKDIR /app\nCOPY --from=builder /root/.local /root/.local\nCOPY . .\nENV PATH=/root/.local/bin:$PATH\nUSER nobody\nEXPOSE 8000\nHEALTHCHECK --interval=30s CMD python -c "import urllib.request; urllib.request.urlopen('"'"'http://localhost:8000/health'"'"')"\nCMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]\n' \
                > Dockerfile

        case rust
            printf '# ── Build stage ───────────────────────────────────────────────────────────\nFROM rust:1.75-slim AS builder\nWORKDIR /app\nRUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*\nCOPY Cargo.toml Cargo.lock ./\nRUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src\nCOPY src ./src\nRUN touch src/main.rs && cargo build --release\n\n# ── Runtime stage ─────────────────────────────────────────────────────────\nFROM debian:bookworm-slim AS runtime\nRUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*\nCOPY --from=builder /app/target/release/app /usr/local/bin/app\nUSER nobody\nEXPOSE 8080\nCMD ["app"]\n' \
                > Dockerfile

        case go golang
            printf '# ── Build stage ───────────────────────────────────────────────────────────\nFROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY go.mod go.sum ./\nRUN go mod download\nCOPY . .\nRUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o app ./cmd/app/\n\n# ── Runtime stage ─────────────────────────────────────────────────────────\nFROM scratch AS runtime\nCOPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/\nCOPY --from=builder /app/app /app\nEXPOSE 8080\nHEALTHCHECK --interval=30s CMD ["/app", "health"]\nENTRYPOINT ["/app"]\n' \
                > Dockerfile

        case '*'
            echo "  Usage: dockerfile-new [node|python|rust|go]"
            return 1
    end

    echo $_dk_green"  ✓ Dockerfile created ($type)"$_dk_reset

    # Also create .dockerignore
    if not test -f .dockerignore
        printf '.git\n.gitignore\nnode_modules\n.env\n*.log\n.DS_Store\nREADME.md\ndocs/\ntests/\n.github/\n*.test.*\ncoverage/\n' \
            > .dockerignore
        echo $_dk_green"  ✓ .dockerignore created"$_dk_reset
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core Docker
abbr --add dk      'docker'
abbr --add dkps    'docker-ls'
abbr --add dkpsa   'docker-ls all'
abbr --add dkst    'docker-stats-rich'
abbr --add dki     'docker-images-rich'
abbr --add dkv     'docker-volumes-rich'
abbr --add dkn     'docker-networks-rich'
abbr --add dkinfo  'docker-info-rich'
abbr --add dkex    'docker-exec-smart'
abbr --add dklog   'docker-logs-smart'
abbr --add dkbld   'docker-build-smart'
abbr --add dkbldm  'docker-build-multi'
abbr --add dkpull  'docker-pull-latest'
abbr --add dkinsp  'docker-inspect-rich'
abbr --add dkport  'docker-port-map'
abbr --add dkenv   'docker-env-list'
abbr --add dktop   'docker-top-all'
abbr --add dkscan  'docker-scan'
abbr --add dksbom  'docker-sbom'
abbr --add dkdive  'docker-dive'
abbr --add dklint  'dockerfile-lint'
abbr --add dknew   'dockerfile-new'
abbr --add dkpush  'docker-push-retag'

# Cleanup
abbr --add dkclean 'docker-clean safe'
abbr --add dkprune 'docker-clean all'
abbr --add dkrms   'docker-rm-stopped'
abbr --add dkrmdi  'docker-rmi-dangling'
abbr --add dkrmai  'docker-rmi-all'
abbr --add dkstop  'docker-stop-all'
abbr --add dkkill  'docker-kill-all'

# Compose
abbr --add dcu     'dcu'
abbr --add dcub    'dcub'
abbr --add dcd     'dcd'
abbr --add dcdv    'dcdv'
abbr --add dcl     'dcl'
abbr --add dce     'dce'
abbr --add dcps    'dcps'
abbr --add dcr     'dcr'
abbr --add dcpull  'dcpull'
abbr --add dcenv   'dcenv'
abbr --add dcbld   'docker compose build'
abbr --add dcrun   'docker compose run --rm'
abbr --add dcscl   'docker compose scale'
abbr --add dccfg   'docker compose config'

# Buildx
abbr --add dkbx    'docker buildx'
abbr --add dkbxls  'docker buildx ls'
abbr --add dkbxset 'docker-buildx-setup'