# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — docker_exec Ultra                                  ║
# ║  Smart Docker exec: auto shell detection, fzf picker, command presets      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function docker_exec --description "Smart Docker container exec with auto-shell & fzf picker"

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
    set -l BLUE   (set_color 0db7ed)
    set -l PURPLE (set_color magenta)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 DETECT DOCKER                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    command -q docker || begin
        printf "  $RED✗$R  Docker not installed\n"; return 1
    end

    docker info >/dev/null 2>&1 || begin
        printf "  $RED✗$R  Docker daemon not running\n"; return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dke_help --description "Print help"
        echo ""
        echo $BOLD$BLUE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$BLUE"  ║  🐳  docker_exec — Smart Container Exec              ║"$R
        echo $BOLD$BLUE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  docker_exec [container] [command] [options]"
        echo ""
        echo "  $BOLD Arguments:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "(none)"           "Interactive fzf container picker" \
            "<container>"      "Container name or ID" \
            "<container> <cmd>" "Run specific command in container"
        echo ""
        echo "  $BOLD Presets:$R  (use instead of container name)"
        printf "    $CYAN%-22s$R  %s\n" \
            "logs [container]"   "Tail logs of container" \
            "stats [container]"  "Live resource stats" \
            "top [container]"    "Process list in container" \
            "env [container]"    "Show environment variables" \
            "files [container]"  "Browse filesystem (ncdu/du)" \
            "root [container]"   "Exec as root user"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "--root, -r"      "Execute as root user" \
            "--user <u>, -u"  "Execute as specific user" \
            "--no-tty, -T"    "Disable TTY allocation" \
            "--workdir <dir>" "Set working directory" \
            "--shell <sh>"    "Force specific shell (bash/sh/zsh/fish)" \
            "--quiet, -q"     "Minimal output" \
            "--help, -h"      "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "docker_exec                    # Interactive picker" \
            "docker_exec my-container       # Shell into container" \
            "docker_exec my-container bash  # Force bash" \
            "docker_exec my-app 'ls -la /'  # Run command" \
            "docker_exec logs my-nginx      # Tail logs" \
            "docker_exec env my-api         # Show environment" \
            "docker_exec root my-db         # Exec as root"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _container ""
    set -l _command   ""
    set -l _user      ""
    set -l _workdir   ""
    set -l _shell     ""
    set -l _tty       1
    set -l _root      0
    set -l _quiet     0
    set -l _mode      shell   # shell | logs | stats | top | env | files | root

    if contains -- --help $argv; or contains -- -h $argv
        __dke_help; return 0
    end

    # Parse first arg: mode presets
    if test (count $argv) -gt 0
        switch $argv[1]
            case logs;   set _mode logs;  set argv $argv[2..-1]
            case stats;  set _mode stats; set argv $argv[2..-1]
            case top;    set _mode top;   set argv $argv[2..-1]
            case env;    set _mode env;   set argv $argv[2..-1]
            case files;  set _mode files; set argv $argv[2..-1]
            case root;   set _mode root;  set _root 1; set argv $argv[2..-1]
        end
    end

    # First non-flag arg is container
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case --root -r;         set _root   1
            case --no-tty -T;       set _tty    0
            case --quiet -q;        set _quiet  1
            case --user=*
                set _user (string replace '--user=' '' $arg)
            case --user -u
                set _i (math $_i + 1); set _user $argv[$_i]
            case --workdir=*
                set _workdir (string replace '--workdir=' '' $arg)
            case --workdir -w
                set _i (math $_i + 1); set _workdir $argv[$_i]
            case --shell=*
                set _shell (string replace '--shell=' '' $arg)
            case --shell -s
                set _i (math $_i + 1); set _shell $argv[$_i]
            case '*'
                if test -z "$_container"
                    set _container $arg
                else
                    # Rest is the command
                    set _command (string join ' ' $argv[$_i..-1])
                    break
                end
        end
        set _i (math $_i + 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 CONTAINER SELECTION                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dke_pick_container --description "Interactive container picker"
        set -l filter $argv[1]   # all | running
        test -z "$filter" && set filter running

        set -l docker_args "-a"
        test "$filter" = running && set docker_args ""

        command -q fzf || begin
            docker ps $docker_args --format '{{.Names}}' 2>/dev/null | head -1
            return
        end

        docker ps $docker_args \
            --format "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null |
        fzf --ansi \
            --no-sort \
            --border-label "  🐳 Select Container " \
            --border rounded \
            --prompt "  📦 " \
            --pointer "▶" \
            --preview '
                ct=$(echo {} | awk "{print \$1}")
                echo ""
                echo "  Container: $ct"
                echo ""
                docker inspect "$ct" 2>/dev/null | python3 -m json.tool 2>/dev/null | \
                    grep -E "\"(Image|Status|Cmd|Entrypoint|Env|WorkingDir|Mounts)\"" | head -20
                echo ""
                echo "  Recent logs:"
                docker logs --tail=10 "$ct" 2>/dev/null
            ' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header "  Enter:exec  Ctrl-L:logs  Ctrl-T:top  Ctrl-E:env  " \
            --bind 'ctrl-l:execute(docker logs -f {1} | less -R)' \
            --bind 'ctrl-t:execute(docker top {1} | less)' \
            --bind 'ctrl-e:execute(docker exec {1} env | sort | less)' \
            --height 75% |
        awk '{print $1}'
    end

    # ── Get container if not provided ─────────────────────────────────────────
    if test -z "$_container"
        set _container (__dke_pick_container)
        test -z "$_container" && return 0
    end

    # ── Validate container exists ─────────────────────────────────────────────
    if not docker inspect "$_container" >/dev/null 2>&1
        printf "  $RED✗$R  Container not found: $_container\n"
        printf "  $DIM  Run: docker ps -a   to list containers$R\n"
        return 1
    end

    # ── Get container status ───────────────────────────────────────────────────
    set -l _ct_status (docker inspect --format '{{.State.Status}}' "$_container" 2>/dev/null)
    set -l _ct_image  (docker inspect --format '{{.Config.Image}}' "$_container" 2>/dev/null)
    set -l _ct_id     (docker inspect --format '{{.Id}}' "$_container" 2>/dev/null | string sub --length 12)

    # ── Auto-start stopped container if needed ────────────────────────────────
    if test "$_ct_status" != running
        if test "$_mode" = logs
            # Logs work on stopped containers
            true
        else
            printf "  $YELLOW⚠$R  Container '$_container' is not running ($DIM$_ct_status$R)\n"
            read -P "  Start it? [Y/n] " start_it
            if not string match -qi 'n*' $start_it
                docker start "$_container" >/dev/null 2>&1
                and begin
                    printf "  $GREEN✓$R  Started: $_container\n"
                    sleep 0.5
                end
                or begin
                    printf "  $RED✗$R  Failed to start container\n"
                    return 1
                end
            else
                return 0
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🐚 SHELL DETECTION                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dke_detect_shell --description "Detect best shell in container"
        set -l ct $argv[1]

        # User override
        test -n "$_shell" && echo $_shell && return

        # Try shells in preference order
        for sh in bash zsh fish ash sh
            if docker exec $ct which $sh >/dev/null 2>&1
                echo $sh
                return
            end
        end

        echo sh  # Fallback
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 BUILD EXEC FLAGS                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __dke_build_flags --description "Build docker exec flags"
        set -l flags "-i"

        test $_tty -eq 1 && set flags "$flags -t"

        # User flag
        if test $_root -eq 1
            set flags "$flags --user root"
        else if test -n "$_user"
            set flags "$flags --user $_user"
        end

        # Working directory
        test -n "$_workdir" && set flags "$flags --workdir '$_workdir'"

        # Environment passthrough
        set -l pass_vars TERM COLORTERM LANG
        for var in $pass_vars
            if set -q $var
                set flags "$flags --env $var=$$var"
            end
        end

        echo $flags
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  HEADER                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_quiet -eq 0
        printf "\n"
        printf "  $BOLD$BLUE╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$BLUE║  🐳  Exec: %-46s║$R\n" \
            (string sub --length 46 "$_container ($_ct_image)")
        printf "  $BOLD$BLUE║  %-52s║$R\n" \
            "  ID: $_ct_id  ·  Status: $_ct_status  ·  Mode: $_mode"
        printf "  $BOLD$BLUE╚══════════════════════════════════════════════════════╝$R\n\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _flags (__dke_build_flags)

    switch $_mode

        # ── SHELL: Interactive shell ───────────────────────────────────────────
        case shell root
            set -l sh (__dke_detect_shell $_container)
            printf "  $GREEN✓$R  Shell: $CYAN$sh$R  $DIM│  Container: $_container$R\n\n"

            if test -n "$_command"
                # Run specific command
                eval "docker exec $_flags '$_container' $sh -c '$_command'"
            else
                # Interactive shell
                eval "docker exec $_flags '$_container' $sh"
            end

        # ── LOGS: Tail container logs ─────────────────────────────────────────
        case logs
            printf "  $GREEN✓$R  Streaming logs: $CYAN$_container$R\n"
            printf "  $DIM  Ctrl-C to stop$R\n\n"

            set -l log_args "-f --tail=100"
            test -n "$_command" && set log_args "$log_args --since='$_command'"

            eval "docker logs $log_args '$_container'" 2>&1 | \
                command -q bat && bat --language=log --style=plain --color=always \
                    --paging=never || cat

        # ── STATS: Live resource monitor ──────────────────────────────────────
        case stats
            printf "  $GREEN✓$R  Live stats: $CYAN$_container$R\n"
            printf "  $DIM  Ctrl-C to stop$R\n\n"
            docker stats "$_container"

        # ── TOP: Process list ──────────────────────────────────────────────────
        case top
            printf "  $GREEN✓$R  Processes in: $CYAN$_container$R\n\n"
            docker top "$_container" 2>/dev/null | \
            while read -l line
                if string match -q 'UID*' $line
                    printf "  $BOLD$CYAN%s$R\n" $line
                else
                    printf "  $DIM%s$R\n" $line
                end
            end
            printf "\n"

        # ── ENV: Environment variables ─────────────────────────────────────────
        case env
            printf "  $GREEN✓$R  Environment: $CYAN$_container$R\n\n"
            printf "  $BOLD$CYAN%-30s  %s$R\n" "VARIABLE" "VALUE"
            printf "  $DIM%s$R\n" (string repeat -n 65 "─")

            docker exec "$_container" env 2>/dev/null | sort | \
            while read -l line
                set -l key (string split '=' $line)[1]
                set -l val (string split '=' $line | tail -1)

                # Mask secrets
                set -l masked_val $val
                for pattern in PASSWORD SECRET KEY TOKEN PASS PRIVATE
                    if string match -qi "*$pattern*" $key
                        set masked_val (string repeat -n (math "min(8, string length $val)") "●")
                        break
                    end
                end

                printf "  $CYAN%-30s$R  $DIM%s$R\n" \
                    (string sub --length 30 $key) \
                    (string sub --length 35 $masked_val)
            end
            printf "\n"

        # ── FILES: Browse filesystem ───────────────────────────────────────────
        case files
            printf "  $GREEN✓$R  Filesystem: $CYAN$_container$R\n\n"

            # Try ncdu → du → ls fallback
            if docker exec "$_container" which ncdu >/dev/null 2>&1
                docker exec -it "$_container" ncdu /
            else if docker exec "$_container" which du >/dev/null 2>&1
                printf "  $DIM  Disk usage (top 20):$R\n\n"
                docker exec "$_container" sh -c \
                    "du -sh /* 2>/dev/null | sort -rh | head -20" 2>/dev/null | \
                while read -l line
                    set -l size (echo $line | awk '{print $1}')
                    set -l path (echo $line | awk '{print $2}')
                    printf "  $CYAN%-8s$R  $DIM%s$R\n" $size $path
                end
                printf "\n"
            else
                docker exec "$_container" ls -la / 2>/dev/null
            end

        # ── RUN COMMAND: Execute specific command ──────────────────────────────
        case '*'
            if test -n "$_command"
                printf "  $GREEN✓$R  Running in $CYAN$_container$R: $DIM$_command$R\n\n"
                eval "docker exec $_flags '$_container' sh -c '$_command'"
            else
                # Default: interactive shell
                set -l sh (__dke_detect_shell $_container)
                printf "  $GREEN✓$R  Shell: $CYAN$sh$R  $DIM│  Container: $_container$R\n\n"
                eval "docker exec $_flags '$_container' $sh"
            end
    end

    set -l _rc $status

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __dke_help __dke_pick_container __dke_detect_shell \
        __dke_build_flags 2>/dev/null

    return $_rc

end
