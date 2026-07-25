# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐳  DOCKER COMPOSE — FISH COMPLETIONS v5.0 OMEGA                          ║
# ║  Ultra Premium • v1 + v2 • Dynamic Services • Live Container State         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Binary detection (support both docker-compose v1 and docker compose v2) ───
function __dc_binary
    if command -q docker-compose
        echo docker-compose
    else
        echo "docker compose"
    end
end

function __dc_cmd
    eval (__dc_binary) $argv 2>/dev/null
end

# ══════════════════════════════════════════════════════════════════════════════
#  GUARDS
# ══════════════════════════════════════════════════════════════════════════════

function __dc_no_subcommand
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            build config create down events exec images kill logs pause \
            port ps pull push restart rm run scale start stop top \
            unpause up version wait watch alpha beta convert ls \
            --help -h --version -v
            return 1
        end
    end
    return 0
end

function __dc_sub_is --argument-names sub
    contains -- "$sub" (commandline -poc)
end

function __dc_seen_any
    set -l tokens (commandline -poc)
    for arg in $argv
        if contains -- "$arg" $tokens
            return 0
        end
    end
    return 1
end

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC DATA SOURCES
# ══════════════════════════════════════════════════════════════════════════════

# ── Parse compose file for services ───────────────────────────────────────────
function __dc_services
    # Try docker compose ps first (works when project is up)
    set -l running (__dc_cmd ps --services 2>/dev/null)
    if test -n "$running"
        echo $running | tr ' ' '\n'
        return
    end
    # Parse compose file directly
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml \
              docker-compose.override.yml docker-compose.override.yaml
        if test -f "$f"
            command awk '
                /^[a-zA-Z]/ && !/^(version|services|networks|volumes|configs|secrets)/ { next }
                /^services:/ { in_services=1; next }
                /^[a-zA-Z]/ && in_services { in_services=0 }
                in_services && /^  [a-zA-Z]/ { gsub(/:.*$/, ""); gsub(/^  /, ""); print }
            ' "$f" 2>/dev/null
            return
        end
    end
end

# ── Running services ───────────────────────────────────────────────────────────
function __dc_running_services
    __dc_cmd ps --services --filter status=running 2>/dev/null | tr ' ' '\n'
end

# ── Stopped services ───────────────────────────────────────────────────────────
function __dc_stopped_services
    __dc_cmd ps --services --filter status=stopped 2>/dev/null | tr ' ' '\n'
end

# ── All containers (running + stopped) ────────────────────────────────────────
function __dc_containers
    __dc_cmd ps -a --format "{{.Name}}\t{{.Status}}" 2>/dev/null
end

# ── Container IDs ─────────────────────────────────────────────────────────────
function __dc_container_ids
    __dc_cmd ps -q 2>/dev/null
end

# ── Profiles from compose file ────────────────────────────────────────────────
function __dc_profiles
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml
        if test -f "$f"
            command awk '/profiles:/{flag=1; next} flag && /^      -/{gsub(/^[ -]+/,""); print; next} flag && !/^[ -]/{flag=0}' "$f" 2>/dev/null
            return
        end
    end
end

# ── Networks from compose file ────────────────────────────────────────────────
function __dc_networks
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml
        if test -f "$f"
            command awk '/^networks:/{flag=1; next} flag && /^  [a-zA-Z]/{gsub(/:.*$/,""); print; next} flag && /^[^ ]/{flag=0}' "$f" 2>/dev/null
        end
    end
    docker network ls --format "{{.Name}}" 2>/dev/null
end

# ── Volumes from compose file ──────────────────────────────────────────────────
function __dc_volumes
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml
        if test -f "$f"
            command awk '/^volumes:/{flag=1; next} flag && /^  [a-zA-Z]/{gsub(/:.*$/,""); print; next} flag && /^[^ ]/{flag=0}' "$f" 2>/dev/null
        end
    end
    docker volume ls --format "{{.Name}}" 2>/dev/null
end

# ── Compose files ──────────────────────────────────────────────────────────────
function __dc_compose_files
    find . -maxdepth 1 -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -o -name "compose*.yml" -o -name "compose*.yaml" 2>/dev/null | sed 's|^\./||'
end

# ── Env files ──────────────────────────────────────────────────────────────────
function __dc_env_files
    find . -maxdepth 1 -name ".env*" -o -name "*.env" 2>/dev/null | sed 's|^\./||'
end

# ── Shell completions for exec ─────────────────────────────────────────────────
function __dc_shells
    printf '%s\t%s\n' \
        /bin/sh    "POSIX sh" \
        /bin/bash  "Bash" \
        /bin/fish  "Fish" \
        /bin/zsh   "Zsh" \
        sh         "sh" \
        bash       "Bash" \
        ash        "Alpine sh"
end

# ══════════════════════════════════════════════════════════════════════════════
#  SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l dc_commands \
    "up\t🚀 Create & start containers" \
    "down\t🛑 Stop & remove containers" \
    "start\t▶️  Start services" \
    "stop\t⏹️  Stop services" \
    "restart\t🔄 Restart services" \
    "build\t🔨 Build service images" \
    "pull\t⬇️  Pull service images" \
    "push\t⬆️  Push service images" \
    "ps\t📋 List containers" \
    "logs\t📜 View output from containers" \
    "exec\t🖥️  Execute command in container" \
    "run\t🏃 Run one-off command" \
    "config\t⚙️  Validate & view config" \
    "images\t🖼️  List images" \
    "rm\t🗑️  Remove stopped containers" \
    "kill\t💀 Kill containers" \
    "pause\t⏸️  Pause services" \
    "unpause\t▶️  Unpause services" \
    "top\t📊 Display running processes" \
    "port\t🔌 Print public port" \
    "events\t📡 Receive real-time events" \
    "scale\t📈 Set service replicas" \
    "wait\t⏳ Block until containers stop" \
    "watch\t👁️  Watch & rebuild on change" \
    "version\t📌 Show version"

# Register subcommands
complete -c docker-compose -f -n __dc_no_subcommand -a "$dc_commands"
complete -c docker          -f -n "__dc_sub_is compose; and __dc_no_subcommand" \
    -a "$dc_commands"

# ── Global flags ───────────────────────────────────────────────────────────────
for bin in docker-compose docker
    complete -c $bin -l help         -s h -d "Show help"                      -f
    complete -c $bin -l version      -s v -d "Show version"                   -f
    complete -c $bin -l file         -s f -d "Compose file path"              -F \
        -a "(__dc_compose_files)"
    complete -c $bin -l env-file          -d "Env file path"                  -F \
        -a "(__dc_env_files)"
    complete -c $bin -l project-name -s p -d "Project name"                   -f
    complete -c $bin -l project-directory  -d "Specify working directory"     -F
    complete -c $bin -l profile           -d "Specify a profile to enable"    -f \
        -a "(__dc_profiles)"
    complete -c $bin -l no-ansi           -d "Disable ANSI control chars"     -f
    complete -c $bin -l verbose           -d "Show verbose output"            -f
    complete -c $bin -l log-level         -d "Log level" -f \
        -a "DEBUG\tDebug INFO\tInfo WARNING\tWarning ERROR\tError CRITICAL\tCritical"
    complete -c $bin -l tls               -d "Use TLS"                        -f
    complete -c $bin -l tlscacert         -d "TLS CA cert"                    -F
    complete -c $bin -l tlscert           -d "TLS cert"                       -F
    complete -c $bin -l tlskey            -d "TLS key"                        -F
    complete -c $bin -l tlsverify         -d "Verify TLS"                     -f
    complete -c $bin -l skip-hostname-check -d "Skip TLS hostname check"      -f
    complete -c $bin -l compatibility     -d "v1 compatibility mode"          -f
    complete -c $bin -l parallel          -d "Max parallel operations"        -f
    complete -c $bin -l dry-run           -d "Execute in dry run mode"        -f
    complete -c $bin -l ansi              -d "Control ANSI output" -f \
        -a "never\tNo ANSI always\tAlways ANSI auto\tAuto detect"
    complete -c $bin -l progress          -d "Progress output type" -f \
        -a "auto\tAuto detect tty\tForce tty plain\tPlain quiet\tQuiet"
end

# ══════════════════════════════════════════════════════════════════════════════
#  UP
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is up" \
        -f -a "(__dc_services)" -d "Service name"

    complete -c $bin -n "__dc_sub_is up" \
        -s d -l detach            -d "Run in background (detached)"           -f
    complete -c $bin -n "__dc_sub_is up" \
        -l no-build               -d "Don't build before starting"            -f
    complete -c $bin -n "__dc_sub_is up" \
        -l no-start               -d "Don't start after creating"             -f
    complete -c $bin -n "__dc_sub_is up" \
        -l build                  -d "Build images before starting"           -f
    complete -c $bin -n "__dc_sub_is up" \
        -l no-deps                -d "Don't start linked services"            -f
    complete -c $bin -n "__dc_sub_is up" \
        -l force-recreate         -d "Recreate containers"                    -f
    complete -c $bin -n "__dc_sub_is up" \
        -l no-recreate            -d "Don't recreate existing containers"     -f
    complete -c $bin -n "__dc_sub_is up" \
        -l no-log-prefix          -d "Don't print log prefix"                 -f
    complete -c $bin -n "__dc_sub_is up" \
        -l remove-orphans         -d "Remove orphaned containers"             -f
    complete -c $bin -n "__dc_sub_is up" \
        -l renew-anon-volumes -V   -d "Recreate anonymous volumes"            -f
    complete -c $bin -n "__dc_sub_is up" \
        -l scale                  -d "Scale service to N instances"           -f
    complete -c $bin -n "__dc_sub_is up" \
        -l abort-on-container-exit -d "Stop if any container stops"          -f
    complete -c $bin -n "__dc_sub_is up" \
        -l abort-on-container-failure -d "Stop if any container fails"       -f
    complete -c $bin -n "__dc_sub_is up" \
        -l exit-code-from         -d "Return exit code from service"         -f \
        -a "(__dc_services)"
    complete -c $bin -n "__dc_sub_is up" \
        -l timeout -t             -d "Shutdown timeout (seconds)"            -f
    complete -c $bin -n "__dc_sub_is up" \
        -l wait                   -d "Wait for services to be healthy"        -f
    complete -c $bin -n "__dc_sub_is up" \
        -l wait-timeout           -d "Timeout for --wait (seconds)"          -f
    complete -c $bin -n "__dc_sub_is up" \
        -l timestamps             -d "Show timestamps in logs"               -f
    complete -c $bin -n "__dc_sub_is up" \
        -l quiet-pull             -d "Pull without printing progress"        -f
    complete -c $bin -n "__dc_sub_is up" \
        -l pull                   -d "Pull image policy" -f \
        -a "always\tAlways pull missing\tPull if missing never\tNever pull"
    complete -c $bin -n "__dc_sub_is up" \
        -l menu                   -d "Enable interactive shortcuts"          -f
    complete -c $bin -n "__dc_sub_is up" \
        -l watch -w               -d "Watch & rebuild on change"             -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  DOWN
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is down" \
        -l rmi                    -d "Remove images" -f \
        -a "all\tAll images local\tOnly local images"
    complete -c $bin -n "__dc_sub_is down" \
        -s v -l volumes           -d "Remove named volumes"                  -f
    complete -c $bin -n "__dc_sub_is down" \
        -l remove-orphans         -d "Remove orphaned containers"             -f
    complete -c $bin -n "__dc_sub_is down" \
        -s t -l timeout           -d "Shutdown timeout (seconds)"            -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  BUILD
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is build" \
        -f -a "(__dc_services)" -d "Service name"

    complete -c $bin -n "__dc_sub_is build" \
        -l build-arg              -d "Set build-time variable"               -f
    complete -c $bin -n "__dc_sub_is build" \
        -l compress               -d "Compress build context with gzip"      -f
    complete -c $bin -n "__dc_sub_is build" \
        -l force-rm               -d "Always remove intermediate containers" -f
    complete -c $bin -n "__dc_sub_is build" \
        -l memory -m              -d "Memory limit"                          -f
    complete -c $bin -n "__dc_sub_is build" \
        -l no-cache               -d "Don't use cache"                       -f
    complete -c $bin -n "__dc_sub_is build" \
        -l no-rm                  -d "Keep intermediate containers"          -f
    complete -c $bin -n "__dc_sub_is build" \
        -l parallel               -d "Build in parallel"                     -f
    complete -c $bin -n "__dc_sub_is build" \
        -l progress               -d "Set progress output type" -f \
        -a "auto plain tty quiet"
    complete -c $bin -n "__dc_sub_is build" \
        -l pull                   -d "Always pull newer base image"          -f
    complete -c $bin -n "__dc_sub_is build" \
        -s q -l quiet             -d "Suppress build output"                 -f
    complete -c $bin -n "__dc_sub_is build" \
        -l ssh                    -d "SSH agent socket for BuildKit"         -f
    complete -c $bin -n "__dc_sub_is build" \
        -l push                   -d "Push after build"                      -f
    complete -c $bin -n "__dc_sub_is build" \
        -l with-dependencies      -d "Build deps first"                      -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  LOGS
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is logs" \
        -f -a "(__dc_services)" -d "Service name"

    complete -c $bin -n "__dc_sub_is logs" \
        -s f -l follow            -d "Follow log output"                     -f
    complete -c $bin -n "__dc_sub_is logs" \
        -l no-color               -d "Disable color output"                  -f
    complete -c $bin -n "__dc_sub_is logs" \
        -l no-log-prefix          -d "Don't print service prefix"            -f
    complete -c $bin -n "__dc_sub_is logs" \
        -s t -l timestamps        -d "Show timestamps"                       -f
    complete -c $bin -n "__dc_sub_is logs" \
        -l tail                   -d "Lines from end to show" -f \
        -a "10 20 50 100 200 500 all"
    complete -c $bin -n "__dc_sub_is logs" \
        -l since                  -d "Show logs since timestamp"             -f \
        -a "1m\t1 minute 5m\t5 minutes 1h\t1 hour 24h\t24 hours"
    complete -c $bin -n "__dc_sub_is logs" \
        -l until                  -d "Show logs until timestamp"             -f
    complete -c $bin -n "__dc_sub_is logs" \
        -s n -l index             -d "Index of container (for scaled svc)"   -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  EXEC
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is exec; and not __dc_seen_any (__dc_services)" \
        -f -a "(__dc_running_services)" -d "Running service"

    complete -c $bin -n "__dc_sub_is exec" \
        -s d -l detach            -d "Run in background"                     -f
    complete -c $bin -n "__dc_sub_is exec" \
        -l privileged             -d "Give extended privileges"              -f
    complete -c $bin -n "__dc_sub_is exec" \
        -s u -l user              -d "Run as user"                           -f
    complete -c $bin -n "__dc_sub_is exec" \
        -s T -l no-TTY            -d "Disable TTY allocation"                -f
    complete -c $bin -n "__dc_sub_is exec" \
        -s e -l env               -d "Set environment variable KEY=VAL"      -f
    complete -c $bin -n "__dc_sub_is exec" \
        -s w -l workdir           -d "Working directory"                     -F
    complete -c $bin -n "__dc_sub_is exec" \
        -l index                  -d "Container index (scaled services)"     -f
    complete -c $bin -n "__dc_sub_is exec" \
        -s i -l interactive       -d "Keep STDIN open"                       -f

    # Command completions after service name
    complete -c $bin -n "__dc_sub_is exec; and __dc_seen_any (__dc_services)" \
        -f -a "(__dc_shells)" -d "Shell / command"
    complete -c $bin -n "__dc_sub_is exec; and __dc_seen_any (__dc_services)" \
        -f -a "(__fish_complete_command)"
end

# ══════════════════════════════════════════════════════════════════════════════
#  RUN
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is run; and not __dc_seen_any (__dc_services)" \
        -f -a "(__dc_services)" -d "Service name"

    complete -c $bin -n "__dc_sub_is run" \
        -s d -l detach            -d "Run in background"                     -f
    complete -c $bin -n "__dc_sub_is run" \
        -l name                   -d "Container name"                        -f
    complete -c $bin -n "__dc_sub_is run" \
        -l entrypoint             -d "Override entrypoint"                   -f
    complete -c $bin -n "__dc_sub_is run" \
        -s e -l env               -d "Set environment variable"              -f
    complete -c $bin -n "__dc_sub_is run" \
        -s l -l label             -d "Set label"                             -f
    complete -c $bin -n "__dc_sub_is run" \
        -s u -l user              -d "Run as user"                           -f
    complete -c $bin -n "__dc_sub_is run" \
        -l no-deps                -d "Don't start linked services"           -f
    complete -c $bin -n "__dc_sub_is run" \
        -l rm                     -d "Remove after run"                      -f
    complete -c $bin -n "__dc_sub_is run" \
        -s p -l publish           -d "Publish ports"                         -f
    complete -c $bin -n "__dc_sub_is run" \
        -l service-ports          -d "Use service's ports"                   -f
    complete -c $bin -n "__dc_sub_is run" \
        -l use-aliases            -d "Use service network aliases"           -f
    complete -c $bin -n "__dc_sub_is run" \
        -s v -l volume            -d "Bind mount a volume"                   -F
    complete -c $bin -n "__dc_sub_is run" \
        -s T -l no-TTY            -d "Disable pseudo-TTY"                    -f
    complete -c $bin -n "__dc_sub_is run" \
        -s w -l workdir           -d "Working directory inside container"    -F
    complete -c $bin -n "__dc_sub_is run" \
        -l build                  -d "Build image before running"            -f
    complete -c $bin -n "__dc_sub_is run" \
        -l quiet-pull             -d "Pull without printing progress"        -f
    complete -c $bin -n "__dc_sub_is run" \
        -s i -l interactive       -d "Keep STDIN open"                       -f

    complete -c $bin -n "__dc_sub_is run; and __dc_seen_any (__dc_services)" \
        -f -a "(__dc_shells)" -d "Shell / command"
    complete -c $bin -n "__dc_sub_is run; and __dc_seen_any (__dc_services)" \
        -f -a "(__fish_complete_command)"
end

# ══════════════════════════════════════════════════════════════════════════════
#  PS
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is ps" \
        -f -a "(__dc_services)" -d "Service name"

    complete -c $bin -n "__dc_sub_is ps" \
        -s a -l all               -d "Show all stopped containers"           -f
    complete -c $bin -n "__dc_sub_is ps" \
        -l services               -d "Display services"                      -f
    complete -c $bin -n "__dc_sub_is ps" \
        -l filter                 -d "Filter by property" -f \
        -a "status=running status=stopped status=paused status=restarting status=dead name="
    complete -c $bin -n "__dc_sub_is ps" \
        -l format                 -d "Format output" -f \
        -a "table\tTable view json\tJSON lines"
    complete -c $bin -n "__dc_sub_is ps" \
        -s q -l quiet             -d "Only display IDs"                      -f
    complete -c $bin -n "__dc_sub_is ps" \
        -l status                 -d "Filter by status" -f \
        -a "paused\tPaused restarting\tRestarting removing\tRemoving running\tRunning dead\tDead created\tCreated exited\tExited"
    complete -c $bin -n "__dc_sub_is ps" \
        -s n -l last              -d "Show last N containers"                -f
    complete -c $bin -n "__dc_sub_is ps" \
        -l orphans                -d "Include orphaned containers"           -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  STOP / START / RESTART / KILL / PAUSE / UNPAUSE
# ══════════════════════════════════════════════════════════════════════════════

for sub in stop start restart kill pause unpause
    for bin in docker-compose docker
        complete -c $bin -n "__dc_sub_is $sub" \
            -f -a "(__dc_services)" -d "Service name"
    end
end

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is stop" \
        -s t -l timeout           -d "Shutdown timeout (seconds)"            -f

    complete -c $bin -n "__dc_sub_is restart" \
        -s t -l timeout           -d "Restart timeout (seconds)"             -f
    complete -c $bin -n "__dc_sub_is restart" \
        -l no-deps                -d "Don't restart dependencies"            -f

    complete -c $bin -n "__dc_sub_is kill" \
        -s s -l signal            -d "Signal to send" -f \
        -a "SIGTERM\tGraceful SIGKILL\tForce kill SIGINT\tInterrupt SIGHUP\tHangup SIGSTOP\tStop"
end

# ══════════════════════════════════════════════════════════════════════════════
#  RM
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is rm" \
        -f -a "(__dc_stopped_services)" -d "Stopped service"

    complete -c $bin -n "__dc_sub_is rm" \
        -s f -l force             -d "Don't ask for confirmation"            -f
    complete -c $bin -n "__dc_sub_is rm" \
        -s s -l stop              -d "Stop containers before removing"       -f
    complete -c $bin -n "__dc_sub_is rm" \
        -s v -l volumes           -d "Remove anonymous volumes"              -f
    complete -c $bin -n "__dc_sub_is rm" \
        -s a -l all               -d "Deprecated: use -a"                    -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  PULL / PUSH
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is pull" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is pull" \
        -l ignore-pull-failures   -d "Continue if pull fails"                -f
    complete -c $bin -n "__dc_sub_is pull" \
        -l include-deps           -d "Pull services' dependencies"           -f
    complete -c $bin -n "__dc_sub_is pull" \
        -s q -l quiet             -d "Suppress progress output"              -f
    complete -c $bin -n "__dc_sub_is pull" \
        -l policy                 -d "Pull policy" -f \
        -a "always\tAlways pull missing\tOnly if missing never\tNever"

    complete -c $bin -n "__dc_sub_is push" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is push" \
        -l ignore-push-failures   -d "Continue if push fails"                -f
    complete -c $bin -n "__dc_sub_is push" \
        -s q -l quiet             -d "Suppress progress output"              -f
    complete -c $bin -n "__dc_sub_is push" \
        -l include-deps           -d "Push dependent services too"           -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  CONFIG
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is config" \
        -l format                 -d "Format output" -f \
        -a "yaml\tYAML json\tJSON"
    complete -c $bin -n "__dc_sub_is config" \
        -s q -l quiet             -d "Only validate, no output"              -f
    complete -c $bin -n "__dc_sub_is config" \
        -l no-interpolate         -d "Don't interpolate env vars"            -f
    complete -c $bin -n "__dc_sub_is config" \
        -l no-normalize           -d "Don't normalize output"                -f
    complete -c $bin -n "__dc_sub_is config" \
        -l resolve-image-digests  -d "Pin image digests"                     -f
    complete -c $bin -n "__dc_sub_is config" \
        -l profiles               -d "List profiles instead of config"       -f
    complete -c $bin -n "__dc_sub_is config" \
        -l services               -d "Print service names"                   -f
    complete -c $bin -n "__dc_sub_is config" \
        -l volumes                -d "Print volume names"                    -f
    complete -c $bin -n "__dc_sub_is config" \
        -l images                 -d "Print image names"                     -f
    complete -c $bin -n "__dc_sub_is config" \
        -l hash                   -d "Print hash of service config"          -f \
        -a "(__dc_services)"
    complete -c $bin -n "__dc_sub_is config" \
        -l lock                   -d "Output pinned image digests"           -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  SCALE / PORT / TOP / IMAGES / EVENTS / WAIT / WATCH
# ══════════════════════════════════════════════════════════════════════════════

for bin in docker-compose docker
    complete -c $bin -n "__dc_sub_is scale" \
        -f -a "(__dc_services)" -d "service=N"
    complete -c $bin -n "__dc_sub_is scale" \
        -s t -l timeout           -d "Shutdown timeout"                      -f

    complete -c $bin -n "__dc_sub_is port" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is port" \
        -l protocol               -d "Protocol" -f -a "tcp udp"
    complete -c $bin -n "__dc_sub_is port" \
        -l index                  -d "Container index (scaled services)"     -f

    complete -c $bin -n "__dc_sub_is top" \
        -f -a "(__dc_services)" -d "Service name"

    complete -c $bin -n "__dc_sub_is images" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is images" \
        -s q -l quiet             -d "Only display image IDs"                -f
    complete -c $bin -n "__dc_sub_is images" \
        -l format                 -d "Output format" -f \
        -a "table json"

    complete -c $bin -n "__dc_sub_is events" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is events" \
        -l json                   -d "Output events as JSON"                 -f

    complete -c $bin -n "__dc_sub_is wait" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is wait" \
        -l remove-orphans         -d "Remove orphaned containers"            -f
    complete -c $bin -n "__dc_sub_is wait" \
        -l down-project           -d "Stops the project when done"           -f

    complete -c $bin -n "__dc_sub_is watch" \
        -f -a "(__dc_services)" -d "Service name"
    complete -c $bin -n "__dc_sub_is watch" \
        -l no-up                  -d "Don't run up before watching"          -f
    complete -c $bin -n "__dc_sub_is watch" \
        -l quiet                  -d "Only log watch actions"                -f
    complete -c $bin -n "__dc_sub_is watch" \
        -l prune                  -d "Prune dangling images on rebuild"      -f
end
