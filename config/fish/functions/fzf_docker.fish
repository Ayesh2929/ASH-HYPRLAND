#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🐳  FZF_DOCKER.FISH  ·  ASH Dotfiles v5.0 OMEGA                                ║
# ║  Ultra Interactive Docker Management System                                      ║
# ║  Containers · Images · Volumes · Networks · Compose · Stats · Logs · Exec       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# FUNCTIONS:
#   fzf_docker              — Main Docker dashboard / menu
#   fzf_docker_container    — Container manager (run/stop/rm/exec/logs)
#   fzf_docker_image        — Image manager (pull/run/rm/inspect/tag)
#   fzf_docker_volume       — Volume manager
#   fzf_docker_network      — Network manager
#   fzf_docker_compose      — Docker Compose project manager
#   fzf_docker_stats        — Live resource stats
#   fzf_docker_logs         — Log browser with follow/filter
#   fzf_docker_exec         — Shell into container
#   fzf_docker_clean        — System cleanup wizard
#
# KEYBINDS:
#   Ctrl+Alt+D   — Docker dashboard
#   Ctrl+Alt+C   — Container picker

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __FD_VERSION  "5.0.0"
set -g __FD_DATA_DIR "$HOME/.local/share/ash/fzf-docker"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  PALETTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g _R  (set_color normal)
set -g _B  (set_color --bold)
set -g _D  (set_color brblack)
set -g _W  (set_color white)
set -g _RE (set_color brred)
set -g _GR (set_color brgreen)
set -g _YE (set_color bryellow)
set -g _BL (set_color brblue)
set -g _CY (set_color brcyan)
set -g _MG (set_color brmagenta)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  INTERNAL UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fd_dirs;  mkdir -p $__FD_DATA_DIR; end
function __fd_ok   -a m; echo "$_GR  ✔  $m$_R"; end
function __fd_err  -a m; echo "$_RE  ✘  $m$_R" >&2; end
function __fd_warn -a m; echo "$_YE  ⚠  $m$_R"; end
function __fd_tip  -a m; echo "$_CY  ›  $m$_R"; end
function __fd_info -a m; echo "$_BL  ℹ  $m$_R"; end

function __fd_require_fzf
    command -q fzf; and return 0
    __fd_err "fzf required — install: paru -S fzf"
    return 1
end

function __fd_require_docker
    command -q docker; or begin
        __fd_err "docker not found"
        return 1
    end
    docker info >/dev/null 2>&1; or begin
        __fd_err "Docker daemon not running — start: sudo systemctl start docker"
        return 1
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  FZF BASE OPTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __FD_FZF_OPTS \
    "--border=rounded" \
    "--height=88%" \
    "--layout=reverse" \
    "--info=inline" \
    "--ansi" \
    "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8" \
    "--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8" \
    "--color=info:#cba6ac,prompt:#89b4fa,pointer:#f5c2e7" \
    "--color=marker:#a6e3a1,spinner:#f5c2e7,header:#89dceb" \
    "--pointer=❯" \
    "--marker=●" \
    "--bind=ctrl-/:toggle-preview" \
    "--bind=ctrl-u:preview-page-up" \
    "--bind=ctrl-d:preview-page-down" \
    "--bind=ctrl-a:select-all" \
    "--bind=ctrl-space:toggle"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  STATUS COLORS & ICONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fd_status_icon -a status
    switch $status
        case running;  echo "🟢"
        case exited;   echo "🔴"
        case paused;   echo "🟡"
        case created;  echo "🔵"
        case dead;     echo "💀"
        case restarting; echo "🔄"
        case '*';      echo "⚫"
    end
end

function __fd_status_color -a status
    switch $status
        case running;    echo $_GR
        case exited;     echo $_RE
        case paused;     echo $_YE
        case created;    echo $_BL
        case dead;       echo "$_RE$_B"
        case restarting; echo $_CY
        case '*';        echo $_D
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  DOCKER DASHBOARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fd_dashboard_header
    set -l containers_running (docker ps -q 2>/dev/null | wc -l | string trim)
    set -l containers_all     (docker ps -aq 2>/dev/null | wc -l | string trim)
    set -l images_count       (docker images -q 2>/dev/null | wc -l | string trim)
    set -l volumes_count      (docker volume ls -q 2>/dev/null | wc -l | string trim)
    set -l networks_count     (docker network ls -q 2>/dev/null | wc -l | string trim)

    set -l disk_usage (docker system df --format "{{.Size}}" 2>/dev/null | \
        awk '{sum+=$1} END{print sum}'; or echo "?")

    echo ""
    echo "$_BL  ╔══════════════════════════════════════════════════════════════════╗$_R"
    echo "$_BL  ║$_R  🐳  $_CY$_B Docker Dashboard$_R  ·  $_D v$__FD_VERSION · ASH Dotfiles OMEGA$_R      $_BL║$_R"
    echo "$_BL  ╠══════════════════════════════════════════════════════════════════╣$_R"
    printf "$_BL  ║$_R  🟢 Running: $_GR%-4s$_R  📦 Total: $_CY%-4s$_R  🖼  Images: $_MG%-4s$_R  " \
        $containers_running $containers_all $images_count
    printf "💾 Vols: $_YE%-4s$_R  🌐 Nets: $_BL%-4s  $__BL║$_R\n" \
        $volumes_count $networks_count
    echo "$_BL  ╚══════════════════════════════════════════════════════════════════╝$_R"
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONTAINER LIST FORMATTER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fd_container_list -a show_all
    set -l flag (test "$show_all" = "all"; and echo "-a"; or echo "")

    # Header
    printf "\033[90m  %-4s %-16s %-22s %-14s %-12s  %-16s  %s\033[0m\n" \
        "" "ID" "NAME" "STATUS" "CPU/MEM" "IMAGE" "PORTS"
    printf "\033[34m  %s\033[0m\n" (string repeat -n 78 '─')

    docker ps $flag \
        --format "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}" \
        2>/dev/null | while read -l line

        set -l parts (string split '\t' $line)
        set -l id     $parts[1]
        set -l name   $parts[2]
        set -l status $parts[3]
        set -l image  $parts[4]
        set -l ports  $parts[5]

        # Extract state keyword
        set -l state  (echo $status | awk '{print $1}' | string lower)
        set -l icon   (__fd_status_icon $state)
        set -l col    (__fd_status_color $state)

        # CPU/MEM (only for running)
        set -l cpu_mem ""
        if test "$state" = "running"
            set cpu_mem (docker stats --no-stream --format "{{.CPUPerc}}/{{.MemUsage}}" \
                $id 2>/dev/null | head -1; or echo "?/?")
        end

        set -l ports_short (string shorten -m 18 $ports)
        set -l image_short (string shorten -m 18 $image)
        set -l name_short  (string shorten -m 20 $name)

        printf "  %s $col%-16s$_R $_CY%-22s$_R $col%-14s$_R $_D%-12s$_R  $_MG%-18s$_R  $_D%s$_R\n" \
            $icon \
            $id \
            $name_short \
            (string shorten -m 14 $status) \
            $cpu_mem \
            $image_short \
            $ports_short
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONTAINER PREVIEW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __FD_CTR_PREVIEW '
  id=$(echo {} | awk "{print \$2}" | grep -oP "^[a-f0-9]+")
  [ -z "$id" ] && exit

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🐳  Container: $id"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "── Info ──────────────────────────────────────────────"
  docker inspect "$id" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)[0]
D = \"\033[90m\"; W = \"\033[97m\"; R = \"\033[0m\"; GR = \"\033[92m\"; CY = \"\033[96m\"
def p(l,v,c=W): print(f\"  {D}{l:<22}{R} {c}{v}{R}\")
p(\"Name:\",       data[\"Name\"].lstrip(\"/\"))
p(\"Status:\",     data[\"State\"][\"Status\"],  GR)
p(\"Image:\",      data[\"Config\"][\"Image\"])
p(\"Created:\",    data[\"Created\"][:19])
p(\"Restart:\",    data[\"HostConfig\"][\"RestartPolicy\"][\"Name\"])
mounts = data.get(\"Mounts\",[])
p(\"Mounts:\",     str(len(mounts))+\" volume(s)\")
nets = list(data[\"NetworkSettings\"][\"Networks\"].keys())
p(\"Networks:\",   \", \".join(nets))
ports = data[\"NetworkSettings\"][\"Ports\"]
for k,v in (ports or {}).items():
    if v: p(\"Port:\", f\"{v[0][\'HostPort\']} → {k}\", CY)
env = data[\"Config\"].get(\"Env\",[]) or []
p(\"Env vars:\",   str(len(env)))
" 2>/dev/null

  echo ""
  echo "── Resource Usage ─────────────────────────────────────"
  state=$(docker inspect --format "{{.State.Status}}" "$id" 2>/dev/null)
  if [ "$state" = "running" ]; then
    docker stats --no-stream --format \
      "  CPU: {{.CPUPerc}}   MEM: {{.MemUsage}}   NET: {{.NetIO}}   BLOCK: {{.BlockIO}}" \
      "$id" 2>/dev/null
  else
    echo "  (container not running)"
  fi

  echo ""
  echo "── Recent Logs ─────────────────────────────────────────"
  docker logs --tail=15 "$id" 2>&1 | head -15
'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONTAINER ACTION MENU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fd_container_action -a id
    test -z "$id"; and return 1

    set -l name   (docker inspect --format '{{.Name}}' $id 2>/dev/null | string trim -c '/')
    set -l state  (docker inspect --format '{{.State.Status}}' $id 2>/dev/null)
    set -l image  (docker inspect --format '{{.Config.Image}}' $id 2>/dev/null)

    set -l actions
    switch $state
        case running
            set -a actions "⏸️   Pause"
            set -a actions "⏹️   Stop (SIGTERM)"
            set -a actions "💀  Kill (SIGKILL)"
            set -a actions "🔄  Restart"
            set -a actions "🖥️   Exec shell"
            set -a actions "📋  Exec command"
            set -a actions "📜  Logs (follow)"
            set -a actions "📊  Live stats"
        case paused
            set -a actions "▶️   Unpause"
            set -a actions "⏹️   Stop"
        case exited created
            set -a actions "▶️   Start"
            set -a actions "🗑️   Remove container"
        case '*'
            set -a actions "▶️   Start"
            set -a actions "🗑️   Remove container"
    end

    set -a actions "📜  Logs (tail)"
    set -a actions "🔍  Inspect (JSON)"
    set -a actions "📁  Copy from container"
    set -a actions "📤  Copy to container"
    set -a actions "📋  Copy container ID"
    set -a actions "🏷️   Commit as image"
    set -a actions "🌐  Show port mappings"
    set -a actions "📦  Show mounts/volumes"
    set -a actions "🔗  Show networks"
    set -a actions "🗑️   Remove (force)"
    set -a actions "↩️   Cancel"

    set -l action (printf '%s\n' $actions | fzf \
        --prompt "  🐳 $name [$state] ❯ " \
        --height=65% \
        --layout=reverse \
        --border=rounded \
        --no-preview \
        --color="header:italic:cyan" \
        --header "  ID: $id  |  Image: $image")

    test -z "$action"; and return 0

    switch $action
        case "*Pause*"
            docker pause $id; and __fd_ok "Paused: $name"

        case "*Unpause*"
            docker unpause $id; and __fd_ok "Unpaused: $name"

        case "*Stop*"
            docker stop $id; and __fd_ok "Stopped: $name"

        case "*Kill*"
            docker kill $id; and __fd_ok "Killed: $name"

        case "*Restart*"
            docker restart $id; and __fd_ok "Restarted: $name"

        case "*Start*"
            docker start $id; and __fd_ok "Started: $name"

        case "*Exec shell*"
            fzf_docker_exec $id

        case "*Exec command*"
            set -l cmd (read -P "  📋 Command to run in $name: ")
            test -n "$cmd"; and docker exec -it $id sh -c $cmd

        case "*Logs (follow)*"
            docker logs -f --tail=50 $id

        case "*Logs (tail)*"
            set -l n (read -P "  📜 Tail lines [100]: ")
            test -z "$n"; and set n 100
            docker logs --tail=$n $id 2>&1 | bat --style=plain --color=always \
                --language=log 2>/dev/null; or docker logs --tail=$n $id

        case "*stats*"
            docker stats $id

        case "*Inspect*"
            docker inspect $id | bat --style=full --color=always \
                --language=json 2>/dev/null; \
                or docker inspect $id | python3 -m json.tool | less

        case "*Copy from*"
            set -l src (read -P "  📁 Container path: ")
            set -l dst (read -P "  📁 Local destination [./]: ")
            test -z "$dst"; and set dst "./"
            test -n "$src"; and docker cp "$id:$src" $dst
            and __fd_ok "Copied to: $dst"

        case "*Copy to*"
            set -l src (read -P "  📤 Local file: ")
            set -l dst (read -P "  📁 Container path: ")
            test -n "$src" -a -n "$dst"; and docker cp $src "$id:$dst"
            and __fd_ok "Copied to container: $dst"

        case "*Copy container ID*"
            command -q wl-copy; and echo $id | wl-copy; and __fd_ok "Copied: $id"
            command -q xclip;  and echo $id | xclip -selection clipboard

        case "*Commit*"
            set -l tag (read -P "  🏷️  Image tag [myimage:latest]: ")
            test -z "$tag"; and set tag "myimage:latest"
            docker commit $id $tag
            and __fd_ok "Committed as: $tag"

        case "*port*"
            docker port $id 2>/dev/null | while read -l l; echo "  $_CY$l$_R"; end
            test $status -ne 0; and __fd_warn "No port mappings"

        case "*mounts*"
            docker inspect --format '{{range .Mounts}}{{.Source}} → {{.Destination}} ({{.Type}}){{"\n"}}{{end}}' \
                $id | while read -l l; echo "  $_MG$l$_R"; end

        case "*networks*"
            docker inspect --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{"\n"}}{{end}}' \
                $id | while read -l l; echo "  $_BL$l$_R"; end

        case "*Remove (force)*"
            set -l confirm (read -P "  ⚠  Force remove '$name'? [y/N] ")
            if test "$confirm" = "y" -o "$confirm" = "Y"
                docker rm -f $id; and __fd_ok "Removed: $name"
            end

        case "*Remove container*"
            set -l confirm (read -P "  🗑️  Remove '$name'? [y/N] ")
            if test "$confirm" = "y" -o "$confirm" = "Y"
                docker rm $id; and __fd_ok "Removed: $name"
            end
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CORE — fzf_docker
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker --description "🐳 Docker management dashboard"
    __fd_require_fzf;    or return 1
    __fd_require_docker; or return 1

    set -l sections \
        "🐳  Containers   — run/stop/exec/logs" \
        "🖼   Images       — pull/run/tag/delete" \
        "💾  Volumes      — create/inspect/rm" \
        "🌐  Networks     — create/connect/rm" \
        "🏗️   Compose      — up/down/logs/build" \
        "📊  Live Stats   — resource usage" \
        "🧹  System Clean — prune/cleanup"

    __fd_dashboard_header

    set -l choice (printf '%s\n' $sections | fzf \
        $__FD_FZF_OPTS \
        --no-preview \
        --prompt "  🐳 Docker ❯ " \
        --header "  Select section  |  Esc=exit")

    test -z "$choice"; and return 0

    switch $choice
        case "*Containers*";  fzf_docker_container
        case "*Images*";      fzf_docker_image
        case "*Volumes*";     fzf_docker_volume
        case "*Networks*";    fzf_docker_network
        case "*Compose*";     fzf_docker_compose
        case "*Stats*";       fzf_docker_stats
        case "*Clean*";       fzf_docker_clean
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONTAINER MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_container --description "🐳 Interactive container manager"
    __fd_require_fzf;    or return 1
    __fd_require_docker; or return 1

    set -l show_all 1

    set -l result (__fd_container_list all | fzf \
        $__FD_FZF_OPTS \
        --header-lines=2 \
        --multi \
        --prompt "  📦 Containers ❯ " \
        --header "  Enter=action  Ctrl+L=logs  Ctrl+E=exec  Ctrl+S=stop  Ctrl+K=kill  Ctrl+R=restart  Tab=multi" \
        --preview $__FD_CTR_PREVIEW \
        --preview-window "right:50%:wrap" \
        --expect "enter,ctrl-l,ctrl-e,ctrl-s,ctrl-k,ctrl-r,ctrl-x,esc")

    test -z "$result"; and return 0

    set -l key   (echo $result | head -1)
    set -l lines (echo $result | tail -n +2)
    set -l id    (echo $lines | head -1 | awk '{print $2}' | grep -oP '^[a-f0-9]+')

    test -z "$id"; and return 0

    switch $key
        case "enter" ""
            __fd_container_action $id

        case "ctrl-l"
            fzf_docker_logs $id

        case "ctrl-e"
            fzf_docker_exec $id

        case "ctrl-s"
            # Multi-stop
            set -l ids (echo $lines | string split '\n' | while read -l l
                echo $l | awk '{print $2}' | grep -oP '^[a-f0-9]+'
            end | grep -v '^$')
            set -l n (count $ids)
            set -l confirm (read -P "  ⏹️  Stop $n container(s)? [y/N] ")
            if test "$confirm" = "y" -o "$confirm" = "Y"
                for i in $ids
                    docker stop $i; and __fd_ok "Stopped: $i"
                end
            end

        case "ctrl-k"
            set -l confirm (read -P "  💀 Kill $id? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker kill $id
                and __fd_ok "Killed: $id"

        case "ctrl-r"
            docker restart $id; and __fd_ok "Restarted: $id"

        case "ctrl-x"
            set -l confirm (read -P "  🗑️  Remove $id? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker rm -f $id
                and __fd_ok "Removed: $id"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  IMAGE MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_image --description "🖼  Docker image manager"
    __fd_require_fzf;    or return 1
    __fd_require_docker; or return 1

    set -l result (docker images \
        --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" \
        2>/dev/null \
        | column -t -s $'\t' \
        | fzf \
            $__FD_FZF_OPTS \
            --multi \
            --prompt "  🖼  Images ❯ " \
            --header "  Enter=action  Ctrl+R=run  Ctrl+X=remove  Ctrl+P=pull new  Ctrl+/=preview" \
            --preview '
                img=$(echo {} | awk "{print \$1}")
                docker inspect "$img" 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)[0]
R=\"\033[0m\"; D=\"\033[90m\"; W=\"\033[97m\"; CY=\"\033[96m\"
def p(l,v,c=W): print(f\"  {D}{l:<22}{R} {c}{v}{R}\")
p(\"Repository:\",  d[\"RepoTags\"][0] if d[\"RepoTags\"] else \"<none>\")
p(\"ID:\",          d[\"Id\"][:19])
p(\"Created:\",     d[\"Created\"][:19])
p(\"Size:\",        str(round(d[\"Size\"]/1048576,1))+\" MiB\")
p(\"Arch:\",        d[\"Architecture\"])
p(\"OS:\",          d[\"Os\"])
cmd = d[\"Config\"].get(\"Cmd\") or []
p(\"Cmd:\",         \" \".join(cmd))
ep  = d[\"Config\"].get(\"Entrypoint\") or []
p(\"Entrypoint:\",  \" \".join(ep))
ports = d[\"Config\"].get(\"ExposedPorts\") or {}
p(\"Ports:\",       \", \".join(ports.keys()))
" 2>/dev/null
                echo ""
                echo "── Layers ──────────────────────────────────────────"
                docker history --no-trunc "$img" 2>/dev/null | head -15
            ' \
            --preview-window "right:52%:wrap" \
            --expect "enter,ctrl-r,ctrl-x,ctrl-p,ctrl-t,esc")

    test -z "$result"; and return 0

    set -l key   (echo $result | head -1)
    set -l lines (echo $result | tail -n +2)
    set -l img   (echo $lines | head -1 | awk '{print $1}')

    test -z "$img"; and return 0

    switch $key
        case "enter" ""
            set -l img_actions \
                "▶️   Run container" \
                "🏷️   Tag image" \
                "📤  Push to registry" \
                "💾  Save to tar" \
                "🔍  Inspect (JSON)" \
                "📋  Copy image ID" \
                "📜  Show history" \
                "🗑️   Remove image" \
                "🗑️   Remove (force)"

            set -l act (printf '%s\n' $img_actions | fzf \
                --prompt "  🖼  $img ❯ " \
                --height=45% --layout=reverse --border=rounded --no-preview)
            test -z "$act"; and return 0

            switch $act
                case "*Run*"
                    fzf_docker_run_wizard $img
                case "*Tag*"
                    set -l tag (read -P "  🏷️  New tag: ")
                    test -n "$tag"; and docker tag $img $tag; and __fd_ok "Tagged: $img → $tag"
                case "*Push*"
                    docker push $img
                    and __fd_ok "Pushed: $img"
                case "*Save*"
                    set -l out (read -P "  💾 Output file [$img.tar]: ")
                    test -z "$out"; and set out (string replace ':' '-' $img)".tar"
                    docker save -o $out $img
                    and __fd_ok "Saved to: $out"
                case "*Inspect*"
                    docker inspect $img | bat --style=full --color=always \
                        --language=json 2>/dev/null; \
                        or docker inspect $img | python3 -m json.tool | less
                case "*Copy*"
                    set -l id (docker inspect --format '{{.Id}}' $img | head -c 12)
                    command -q wl-copy; and echo $id | wl-copy; and __fd_ok "Copied: $id"
                case "*history*"
                    docker history $img | less
                case "*Remove image*"
                    docker rmi $img; and __fd_ok "Removed: $img"
                case "*force*"
                    docker rmi -f $img; and __fd_ok "Force removed: $img"
            end

        case "ctrl-r"
            fzf_docker_run_wizard $img

        case "ctrl-x"
            # Multi-remove
            set -l imgs (echo $lines | string split '\n' | awk '{print $1}' | grep -v '^$')
            set -l n (count $imgs)
            set -l confirm (read -P "  🗑️  Remove $n image(s)? [y/N] ")
            if test "$confirm" = "y" -o "$confirm" = "Y"
                for i in $imgs
                    docker rmi $i; and __fd_ok "Removed: $i"
                end
            end

        case "ctrl-p"
            set -l new_img (read -P "  📥 Image to pull [nginx:latest]: ")
            test -z "$new_img"; and set new_img "nginx:latest"
            docker pull $new_img
            and __fd_ok "Pulled: $new_img"

        case "ctrl-t"
            set -l tag (read -P "  🏷️  New tag for $img: ")
            test -n "$tag"; and docker tag $img $tag; and __fd_ok "Tagged"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  RUN WIZARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_run_wizard --description "🐳 Docker run wizard"
    set -l img $argv[1]
    test -z "$img"; and set img (read -P "  🖼  Image: ")
    test -z "$img"; and return 0

    set -l name    (read -P "  📛 Name [auto]: ")
    set -l ports   (read -P "  🔌 Ports [e.g. 8080:80]: ")
    set -l volumes (read -P "  💾 Volumes [e.g. /host:/container]: ")
    set -l env_str (read -P "  🌿 Env vars [KEY=val,KEY2=val2]: ")
    set -l detach  (read -P "  🏃 Detached? [Y/n]: ")
    set -l cmd     (read -P "  ⚡ Command [empty=default]: ")

    set -l run_args
    test "$detach" != "n" -a "$detach" != "N"; and set -a run_args "-d"
    test -n "$name";    and set -a run_args "--name=$name"
    test -n "$ports";   and for p in (string split ',' $ports); set -a run_args "-p" $p; end
    test -n "$volumes"; and for v in (string split ',' $volumes); set -a run_args "-v" $v; end
    test -n "$env_str"; and for e in (string split ',' $env_str); set -a run_args "-e" $e; end
    set -a run_args "--restart=unless-stopped"

    echo ""
    __fd_info "Running: docker run $run_args $img $cmd"
    echo ""

    docker run $run_args $img $cmd
    and __fd_ok "Container started"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  VOLUME MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_volume --description "💾 Docker volume manager"
    __fd_require_fzf;    or return 1
    __fd_require_docker; or return 1

    set -l result (docker volume ls \
        --format "{{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" 2>/dev/null \
        | column -t -s $'\t' \
        | fzf \
            $__FD_FZF_OPTS \
            --multi \
            --prompt "  💾 Volumes ❯ " \
            --header "  Enter=inspect  Ctrl+X=remove  Ctrl+N=new  Ctrl+/=preview" \
            --preview '
                vol=$(echo {} | awk "{print \$1}")
                docker volume inspect "$vol" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30
                echo ""
                echo "── Containers using this volume ──────────────"
                docker ps -a --filter "volume=$vol" \
                  --format "  {{.Names}} ({{.Status}})" 2>/dev/null
            ' \
            --preview-window "right:50%:wrap" \
            --expect "enter,ctrl-x,ctrl-n,esc")

    test -z "$result"; and return 0
    set -l key  (echo $result | head -1)
    set -l vol  (echo $result | tail -1 | awk '{print $1}')

    switch $key
        case "enter" ""
            docker volume inspect $vol \
                | bat --style=full --color=always --language=json 2>/dev/null \
                | less -R

        case "ctrl-x"
            set -l confirm (read -P "  🗑️  Remove volume '$vol'? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker volume rm $vol
                and __fd_ok "Removed volume: $vol"

        case "ctrl-n"
            set -l name (read -P "  💾 Volume name: ")
            test -n "$name"; and docker volume create $name; and __fd_ok "Created: $name"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  NETWORK MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_network --description "🌐 Docker network manager"
    __fd_require_fzf;    or return 1
    __fd_require_docker; or return 1

    set -l result (docker network ls \
        --format "{{.Name}}\t{{.Driver}}\t{{.Scope}}\t{{.ID}}" 2>/dev/null \
        | column -t -s $'\t' \
        | fzf \
            $__FD_FZF_OPTS \
            --prompt "  🌐 Networks ❯ " \
            --header "  Enter=inspect  Ctrl+X=remove  Ctrl+N=new  Ctrl+/=preview" \
            --preview '
                net=$(echo {} | awk "{print \$1}")
                docker network inspect "$net" 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)[0]
R=\"\033[0m\"; D=\"\033[90m\"; W=\"\033[97m\"; CY=\"\033[96m\"
def p(l,v,c=W): print(f\"  {D}{l:<22}{R} {c}{v}{R}\")
p(\"Name:\",   d[\"Name\"])
p(\"Driver:\", d[\"Driver\"])
p(\"Scope:\",  d[\"Scope\"])
ipam = d.get(\"IPAM\",{}).get(\"Config\",[])
for c in ipam: p(\"Subnet:\", c.get(\"Subnet\",\"\"), CY)
containers = d.get(\"Containers\",{})
print(f\"  {D}Containers:  ({len(containers)}){R}\")
for cid,cv in list(containers.items())[:8]:
    print(f\"  {CY}  {cv[\'Name\']:<20}{R} {D}{cv[\'IPv4Address\']}{R}\")
" 2>/dev/null
            ' \
            --preview-window "right:50%:wrap" \
            --expect "enter,ctrl-x,ctrl-n,esc")

    test -z "$result"; and return 0
    set -l key (echo $result | head -1)
    set -l net (echo $result | tail -1 | awk '{print $1}')

    switch $key
        case "enter" ""
            docker network inspect $net \
                | bat --style=full --color=always --language=json 2>/dev/null \
                | less -R

        case "ctrl-x"
            set -l confirm (read -P "  🗑️  Remove network '$net'? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker network rm $net
                and __fd_ok "Removed network: $net"

        case "ctrl-n"
            set -l name   (read -P "  🌐 Network name: ")
            set -l driver (read -P "  🔧 Driver [bridge]: ")
            test -z "$name"; and return 0
            test -z "$driver"; and set driver "bridge"
            docker network create --driver $driver $name
            and __fd_ok "Created: $name ($driver)"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  COMPOSE MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_compose --description "🏗️  Docker Compose project manager"
    __fd_require_fzf;    or return 1
    __fd_require_docker; or return 1

    # Find compose files
    set -l compose_files (fd -g 'docker-compose*.yml' -g 'docker-compose*.yaml' \
        -g 'compose*.yml' -g 'compose*.yaml' \
        $HOME --max-depth 6 2>/dev/null; \
        or find $HOME -maxdepth 6 -name 'docker-compose*.yml' \
            -o -name 'compose*.yml' 2>/dev/null)

    if test (count $compose_files) -eq 0
        __fd_warn "No docker-compose files found"
        return 1
    end

    set -l result (printf '%s\n' $compose_files | fzf \
        $__FD_FZF_OPTS \
        --prompt "  🏗️  Compose Project ❯ " \
        --header "  Enter=actions  Ctrl+/=preview" \
        --preview '
            bat --style=full --color=always {} 2>/dev/null || cat {}
        ' \
        --preview-window "right:55%:wrap" \
        --no-multi)

    test -z "$result"; and return 0

    set -l compose_file $result
    set -l project_dir  (dirname $compose_file)

    set -l action (printf \
        "▶️   Up (detached)\n▶️   Up (foreground)\n⏹️   Down\n⏹️   Down (volumes)\n🔄  Restart\n🔨  Build\n🔨  Build (no cache)\n📜  Logs\n📜  Logs (follow)\n📋  PS (list services)\n⚡  Exec into service\n📥  Pull images\n↩️   Cancel" \
        | fzf \
            --prompt "  🏗️  $(basename $project_dir) ❯ " \
            --height=50% --layout=reverse \
            --border=rounded --no-preview \
            --header "  $compose_file")

    test -z "$action"; and return 0

    pushd $project_dir

    switch $action
        case "*Up (detached)*"
            docker compose -f $compose_file up -d
        case "*Up (foreground)*"
            docker compose -f $compose_file up
        case "*Down*" "*Down (volumes)*"
            set -l v_flag (string match -q "*volumes*" $action; and echo "-v"; or echo "")
            docker compose -f $compose_file down $v_flag
        case "*Restart*"
            docker compose -f $compose_file restart
        case "*Build (no cache)*"
            docker compose -f $compose_file build --no-cache
        case "*Build*"
            docker compose -f $compose_file build
        case "*Logs (follow)*"
            docker compose -f $compose_file logs -f --tail=50
        case "*Logs*"
            docker compose -f $compose_file logs --tail=100 | less
        case "*PS*"
            docker compose -f $compose_file ps
        case "*Exec*"
            set -l svc (docker compose -f $compose_file ps --services 2>/dev/null | fzf \
                --prompt "  ⚡ Service ❯ " \
                --height=30% --layout=reverse --border=rounded --no-preview)
            test -n "$svc"; and docker compose -f $compose_file exec $svc sh
        case "*Pull*"
            docker compose -f $compose_file pull
    end

    popd
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  LOGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_logs --description "📜 Docker log browser"
    __fd_require_docker; or return 1

    set -l id $argv[1]

    if test -z "$id"
        set id (docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}" \
            | column -t -s $'\t' \
            | fzf $__FD_FZF_OPTS \
                --prompt "  📜 Logs ❯ " \
                --no-preview --no-multi \
                | awk '{print $1}')
        test -z "$id"; and return 0
    end

    set -l name (docker inspect --format '{{.Name}}' $id 2>/dev/null | string trim -c '/')

    set -l mode (printf "Follow (-f)\nTail 100\nTail 500\nAll logs\nSince 1h\nGrep pattern" | fzf \
        --prompt "  📜 Mode ❯ " \
        --height=30% --layout=reverse --border=rounded --no-preview \
        --header "  Logs: $name ($id)")

    test -z "$mode"; and return 0

    switch $mode
        case "*Follow*"
            docker logs -f --tail=50 $id
        case "Tail 100"
            docker logs --tail=100 $id 2>&1 | bat --style=plain --color=always \
                --language=log 2>/dev/null; or docker logs --tail=$n $id
        case "Tail 500"
            docker logs --tail=500 $id 2>&1 | less -R
        case "All logs"
            docker logs $id 2>&1 | less -R
        case "*1h*"
            docker logs --since=1h $id 2>&1 | less -R
        case "*Grep*"
            set -l pattern (read -P "  🔍 Pattern: ")
            test -n "$pattern"
                and docker logs $id 2>&1 | grep --color=always -i $pattern | less -R
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  EXEC INTO CONTAINER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_exec --description "🖥️  Shell into container"
    __fd_require_docker; or return 1

    set -l id $argv[1]

    if test -z "$id"
        set id (docker ps --format "{{.ID}}\t{{.Names}}\t{{.Image}}" \
            | column -t -s $'\t' \
            | fzf $__FD_FZF_OPTS \
                --prompt "  🖥️  Exec ❯ " \
                --no-preview --no-multi \
                | awk '{print $1}')
        test -z "$id"; and return 0
    end

    set -l shell (printf "sh\nbash\nzsh\nfish\nsh -c 'command'" | fzf \
        --prompt "  🐚 Shell ❯ " \
        --height=25% --layout=reverse --border=rounded --no-preview)

    test -z "$shell"; and set shell "sh"
    docker exec -it $id $shell
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  LIVE STATS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_stats --description "📊 Docker live resource stats"
    __fd_require_docker; or return 1
    docker stats --format \
        "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  SYSTEM CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_clean --description "🧹 Docker system cleanup wizard"
    __fd_require_docker; or return 1

    echo ""
    echo "$_BL  ┌─ $_YE🧹 Docker System Cleanup$_R"
    echo ""

    # Show disk usage first
    __fd_info "Current disk usage:"
    docker system df 2>/dev/null | while read -l line
        echo "  $_D$line$_R"
    end
    echo ""

    set -l options \
        "🐳  Remove stopped containers" \
        "🖼   Remove dangling images" \
        "🖼   Remove all unused images" \
        "💾  Remove unused volumes" \
        "🌐  Remove unused networks" \
        "💣  Full system prune (safe)" \
        "💣  Full system prune + volumes (DESTRUCTIVE)" \
        "↩️   Cancel"

    set -l choice (printf '%s\n' $options | fzf \
        --prompt "  🧹 Cleanup ❯ " \
        --height=45% --layout=reverse \
        --border=rounded --no-preview \
        --header "  Select cleanup operation")

    test -z "$choice"; and return 0

    switch $choice
        case "*stopped containers*"
            docker container prune -f
            and __fd_ok "Removed stopped containers"
        case "*dangling images*"
            docker image prune -f
            and __fd_ok "Removed dangling images"
        case "*unused images*"
            set -l confirm (read -P "  ⚠  Remove ALL unused images? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker image prune -af
                and __fd_ok "Removed all unused images"
        case "*volumes*" "*unused volumes*"
            set -l confirm (read -P "  ⚠  Remove unused volumes? [y/N] ")
            if test "$confirm" = "y" -o "$confirm" = "Y"
                docker volume prune -f
                and __fd_ok "Removed unused volumes"
            end
        case "*networks*"
            docker network prune -f
            and __fd_ok "Removed unused networks"
        case "*Full system prune (safe)*"
            set -l confirm (read -P "  ⚠  System prune (no volumes)? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker system prune -f
                and __fd_ok "System pruned"
        case "*DESTRUCTIVE*"
            set -l confirm (read -P "  💣 DESTROY all unused resources + volumes? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and docker system prune -af --volumes
                and __fd_ok "Complete cleanup done"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  KEY BINDINGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fd_bind_keys
    bind \e\cd fzf_docker
    bind \e\cc fzf_docker_container

    if bind -M insert >/dev/null 2>&1
        bind -M insert \e\cd fzf_docker
        bind -M insert \e\cc fzf_docker_container
    end
end

status is-interactive; and __fd_bind_keys

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_docker_help
    echo ""
    echo "$_BL  ╔══════════════════════════════════════════════════════════════╗$_R"
    echo "$_BL  ║$_R  🐳  $_CY$_B fzf_docker$_R · $_D v$__FD_VERSION · ASH Dotfiles OMEGA$_R       $_BL║$_R"
    echo "$_BL  ╚══════════════════════════════════════════════════════════════╝$_R"
    echo ""
    printf "  $_YE%-38s$_R %s\n" "FUNCTION"                     "DESCRIPTION"
    printf "  $_D%s$_R\n" (string repeat -n 66 '─')
    printf "  $_GR%-38s$_R %s\n" "fzf_docker"                   "Main dashboard"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_container"         "Container manager"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_image"             "Image manager"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_volume"            "Volume manager"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_network"           "Network manager"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_compose"           "Compose project manager"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_logs [id]"         "Log browser"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_exec [id]"         "Shell into container"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_stats"             "Live resource stats"
    printf "  $_GR%-38s$_R %s\n" "fzf_docker_clean"             "System cleanup wizard"
    echo ""
    printf "  $_CY%-20s$_R %s\n" "Ctrl+Alt+D"  "Docker dashboard"
    printf "  $_CY%-20s$_R %s\n" "Ctrl+Alt+C"  "Container picker"
    echo ""
end
