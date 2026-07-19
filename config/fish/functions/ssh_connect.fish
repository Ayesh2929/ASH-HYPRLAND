# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ssh_connect Ultra                                  ║
# ║  Smart SSH client: config browser, tunnels, key mgmt & session tracking    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ssh_connect --description "Smart SSH connection manager with config browser"

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
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 CONSTANTS                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _ssh_dir        "$HOME/.ssh"
    set -l _ssh_config     "$_ssh_dir/config"
    set -l _known_hosts    "$_ssh_dir/known_hosts"
    set -l _history_file   "$HOME/.local/share/ash/state/ssh-history.json"
    set -l _log_file       "$HOME/.local/share/ash/logs/ssh-connect.log"

    mkdir -p (dirname $_history_file) 2>/dev/null
    mkdir -p (dirname $_log_file)     2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __ssh_help --description "Print help"
        echo ""
        echo $BOLD$CYAN"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$CYAN"  ║     🔌  ssh_connect — Smart SSH Manager              ║"$R
        echo $BOLD$CYAN"  ║      config browser, tunnels, key mgmt & session tracking   ║"$R
        echo $BOLD$CYAN"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  ssh_connect [host] [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-24s$R  %s\n" \
            "(none)"              "Interactive host picker (fzf)" \
            "<host>"              "Connect to host directly" \
            "list"                "List all configured hosts" \
            "add <host>"          "Add new SSH host to config" \
            "remove <host>"       "Remove host from config" \
            "edit [host]"         "Edit SSH config in editor" \
            "scan <host>"         "Scan host key" \
            "copy-key [host]"     "Copy public key to host" \
            "tunnel <spec>"       "Create SSH tunnel" \
            "history"             "Show recent connections" \
            "ping <host>"         "Test SSH connectivity" \
            "info <host>"         "Show host configuration"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "-p, --port <port>"  "Override port" \
            "-u, --user <user>"  "Override username" \
            "-i, --key <file>"   "Override identity file" \
            "-L <spec>"          "Local port forward" \
            "-R <spec>"          "Remote port forward" \
            "-D <port>"          "Dynamic SOCKS proxy" \
            "-A"                 "Enable agent forwarding" \
            "-X"                 "Enable X11 forwarding" \
            "-J <jump>"          "Jump host (bastion)" \
            "-v"                 "Verbose connection" \
            "--tmux"             "Open in new tmux window" \
            "--help, -h"         "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "ssh_connect                    # Interactive picker" \
            "ssh_connect myserver           # Connect directly" \
            "ssh_connect add prod.server.io # Add new host" \
            "ssh_connect list               # List all hosts" \
            "ssh_connect tunnel 8080:localhost:80 myserver  # Tunnel" \
            "ssh_connect copy-key myserver  # Deploy SSH key" \
            "ssh_connect ping myserver      # Test connection" \
            "ssh_connect history            # Recent connections"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode     pick
    set -l _host     ""
    set -l _port     ""
    set -l _user     ""
    set -l _key      ""
    set -l _verbose  0
    set -l _tmux     0
    set -l _agent    0
    set -l _x11      0
    set -l _jump     ""
    set -l _local_fwd  ""
    set -l _remote_fwd ""
    set -l _socks    ""
    set -l _extra_args

    if contains -- --help $argv; or contains -- -h $argv
        __ssh_help; return 0
    end

    # First arg: mode
    if test (count $argv) -gt 0
        switch $argv[1]
            case list ls;         set _mode list;     set argv $argv[2..-1]
            case add;             set _mode add;      set argv $argv[2..-1]
            case remove rm del;   set _mode remove;   set argv $argv[2..-1]
            case edit;            set _mode edit;     set argv $argv[2..-1]
            case scan;            set _mode scan;     set argv $argv[2..-1]
            case copy-key;        set _mode copy-key; set argv $argv[2..-1]
            case tunnel;          set _mode tunnel;   set argv $argv[2..-1]
            case history recent;  set _mode history;  set argv $argv[2..-1]
            case ping test;       set _mode ping;     set argv $argv[2..-1]
            case info show;       set _mode info;     set argv $argv[2..-1]
            case '*'
                # First arg is host
                if not string match -q '-*' $argv[1]
                    set _mode connect
                    set _host $argv[1]
                    set argv $argv[2..-1]
                end
        end
    end

    # Parse remaining options
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case -p --port
                set _i (math $_i + 1); set _port $argv[$_i]
            case -p=* --port=*
                set _port (string replace -r '^-p=|^--port=' '' $arg)
            case -u --user
                set _i (math $_i + 1); set _user $argv[$_i]
            case -i --key
                set _i (math $_i + 1); set _key  $argv[$_i]
            case -L
                set _i (math $_i + 1); set _local_fwd $argv[$_i]
            case -R
                set _i (math $_i + 1); set _remote_fwd $argv[$_i]
            case -D
                set _i (math $_i + 1); set _socks $argv[$_i]
            case -J
                set _i (math $_i + 1); set _jump $argv[$_i]
            case -A --agent;   set _agent   1
            case -X --x11;     set _x11     1
            case -v --verbose; set _verbose 1
            case --tmux;       set _tmux    1
            case '*'
                test -z "$_host" && set _host $arg || set --append _extra_args $arg
        end
        set _i (math $_i + 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 HELPER FUNCTIONS                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Parse SSH config hosts ────────────────────────────────────────────────
    function __ssh_get_hosts --description "Parse all hosts from SSH config"
        set -l config_files \
            $_ssh_config \
            "$_ssh_dir/config.d/"*.conf 2>/dev/null

        for cfg in $config_files
            test -f $cfg || continue
            grep -i "^Host " $cfg 2>/dev/null | \
                awk '{print $2}' | grep -v '\*'
        end

        # Also include from known_hosts
        if test -f $_known_hosts
            awk '{print $1}' $_known_hosts 2>/dev/null | \
                cut -d, -f1 | sort -u | grep -v '^\[' | grep -v '^|'
        end
    end

    # ── Get host configuration ────────────────────────────────────────────────
    function __ssh_get_config --description "Get SSH config for a host"
        set -l host $argv[1]
        ssh -G $host 2>/dev/null
    end

    # ── Build SSH command flags ────────────────────────────────────────────────
    function __ssh_build_flags --description "Build SSH flags from options"
        set -l flags "-o ConnectTimeout=10"
        set flags "$flags -o ServerAliveInterval=60"
        set flags "$flags -o ServerAliveCountMax=3"
        set flags "$flags -o StrictHostKeyChecking=accept-new"

        test -n "$_port"       && set flags "$flags -p $_port"
        test -n "$_user"       && set flags "$flags -l $_user"
        test -n "$_key"        && set flags "$flags -i $_key"
        test -n "$_jump"       && set flags "$flags -J $_jump"
        test -n "$_local_fwd"  && set flags "$flags -L $_local_fwd"
        test -n "$_remote_fwd" && set flags "$flags -R $_remote_fwd"
        test -n "$_socks"      && set flags "$flags -D $_socks"
        test $_agent   -eq 1   && set flags "$flags -A"
        test $_x11     -eq 1   && set flags "$flags -X"
        test $_verbose -eq 1   && set flags "$flags -v"

        echo $flags
    end

    # ── Record to history ──────────────────────────────────────────────────────
    function __ssh_record_history --description "Record SSH connection to history"
        set -l host $argv[1]
        set -l ts   (date -u +%Y-%m-%dT%H:%M:%SZ)

        # Log file
        echo "[$ts] $host" >> $_log_file 2>/dev/null

        # JSON history (keep last 50)
        if command -q jq && test -f $_history_file
            set -l new_entry (printf '{"host":"%s","ts":"%s"}' $host $ts)
            jq --argjson e "$new_entry" \
                '[ $e ] + . | .[0:50]' \
                $_history_file > /tmp/ssh-hist-tmp.json 2>/dev/null && \
                mv /tmp/ssh-hist-tmp.json $_history_file 2>/dev/null
        else
            printf '[{"host":"%s","ts":"%s"}]\n' $host $ts > $_history_file 2>/dev/null
        end
    end

    # ── Print connection header ────────────────────────────────────────────────
    function __ssh_header --description "Print SSH connection header"
        set -l host $argv[1]
        set -l cfg  (__ssh_get_config $host)

        set -l real_host (echo $cfg | grep '^hostname ' | awk '{print $2}')
        set -l real_user (echo $cfg | grep '^user '     | awk '{print $2}')
        set -l real_port (echo $cfg | grep '^port '     | awk '{print $2}')
        set -l real_key  (echo $cfg | grep '^identityfile' | awk '{print $2}' | head -1)

        test -z "$real_host" && set real_host $host
        test -z "$real_user" && set real_user $USER
        test -z "$real_port" && set real_port 22

        printf "\n"
        printf "  $BOLD$CYAN╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$CYAN║  🔌  SSH: %-46s║$R\n" \
            (string sub --length 46 "$real_user@$real_host:$real_port")
        printf "  $BOLD$CYAN║  %-52s║$R\n" \
            "  Alias: $host  ·  Key: $(basename $real_key 2>/dev/null)"
        printf "  $BOLD$CYAN╚══════════════════════════════════════════════════════╝$R\n"
        printf "\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_mode

        # ── INTERACTIVE PICKER ────────────────────────────────────────────────
        case pick
            set -l all_hosts (__ssh_get_hosts | sort -u)

            if test (count $all_hosts) -eq 0
                printf "  $YELLOW⚠$R  No SSH hosts configured\n"
                printf "  $DIM  Add hosts: ssh_connect add <hostname>$R\n\n"
                return 0
            end

            if not command -q fzf
                printf "  $BOLD  SSH Hosts:$R\n"
                for h in $all_hosts; printf "    $CYAN•$R  %s\n" $h; end
                echo ""
                read -P "  Host to connect: " _host
                test -z "$_host" && return 0
                set _mode connect
                __ssh_header $_host
                eval "ssh (__ssh_build_flags) '$_host'"
                return $status
            end

            set _host (
                begin
                    # Add metadata to each host
                    for h in $all_hosts
                        set -l cfg (ssh -G $h 2>/dev/null | \
                            grep -E '^(hostname|user|port|identityfile)' | head -4)
                        set -l hostname (echo $cfg | grep hostname | awk '{print $2}')
                        set -l user     (echo $cfg | grep '^user' | awk '{print $2}')
                        set -l port     (echo $cfg | grep '^port' | awk '{print $2}')
                        test -z "$hostname" && set hostname ""
                        test -z "$port"     && set port "22"
                        printf "%s\t%s\t%s\t%s\n" $h "$user@$hostname" $port ""
                    end
                end |
                fzf --ansi \
                    --no-sort \
                    --border-label "  🔌 SSH Connection Manager " \
                    --border rounded \
                    --prompt "  🔑 " \
                    --pointer "▶" \
                    --delimiter \t \
                    --preview '
                        host=$(echo {1})
                        echo ""
                        echo "  Host alias:  $host"
                        echo "  Config:"
                        ssh -G "$host" 2>/dev/null | \
                            grep -E "^(hostname|user|port|identityfile|proxycommand|proxyjump)" | \
                            awk "{printf \"    %-20s %s\n\", \$1, \$2}"
                        echo ""
                        echo "  Last connected:"
                        grep -h "$host" '"$_log_file"' 2>/dev/null | tail -5 | \
                            awk "{print \"    \" \$0}"
                    ' \
                    --preview-window 'right:45%:border-rounded:wrap' \
                    --header '  Enter:connect  Ctrl-C:copy-key  Ctrl-I:info  Ctrl-T:tunnel  ' \
                    --bind 'ctrl-c:execute(ssh-copy-id {1})+abort' \
                    --bind 'ctrl-i:execute(ssh -G {1} | less)' \
                    --bind 'ctrl-t:execute(
                        read -P "  Local port: " lp
                        read -P "  Remote port: " rp
                        ssh -N -L $lp:localhost:$rp {1}
                    )' \
                    --height 75% |
                awk '{print $1}'
            )

            test -z "$_host" && return 0
            set _mode connect
            # Fall through to connect

            __ssh_header $_host
            __ssh_record_history $_host

            set -l flags (__ssh_build_flags)

            if test $_tmux -eq 1 && command -q tmux && set -q TMUX
                tmux new-window -n "ssh:$_host" "ssh $flags '$_host'"
            else
                eval "ssh $flags '$_host'"
            end

        # ── CONNECT: Direct connection ─────────────────────────────────────────
        case connect
            if test -z "$_host"
                printf "  $RED✗$R  No host specified\n"
                return 1
            end

            __ssh_header $_host
            __ssh_record_history $_host

            set -l flags (__ssh_build_flags)

            if test $_tmux -eq 1 && command -q tmux && set -q TMUX
                tmux new-window -n "ssh:$_host" "ssh $flags '$_host'"
            else
                eval "ssh $flags '$_host'"
            end

        # ── LIST: Show all configured hosts ────────────────────────────────────
        case list
            printf "\n  $BOLD$CYAN  🔌 SSH Hosts$R\n\n"
            printf "  $BOLD$CYAN%-22s  %-25s  %-6s  %s$R\n" \
                "ALIAS" "HOSTNAME" "PORT" "USER"
            printf "  $DIM%s$R\n" (string repeat -n 65 "─")

            for h in (__ssh_get_hosts | sort -u)
                set -l cfg      (ssh -G $h 2>/dev/null)
                set -l hostname (echo $cfg | grep '^hostname' | awk '{print $2}')
                set -l user     (echo $cfg | grep '^user '   | awk '{print $2}')
                set -l port     (echo $cfg | grep '^port '   | awk '{print $2}')
                set -l id_file  (echo $cfg | grep '^identityfile' | awk '{print $2}' | head -1)

                test -z "$port"     && set port "22"
                test -z "$user"     && set user $USER
                test -z "$hostname" && set hostname $h

                set -l key_icon ""
                test -n "$id_file" && set key_icon "🔑"

                printf "  $CYAN%-22s$R  $DIM%-25s$R  $BLUE%-6s$R  $GREEN%-10s$R  %s\n" \
                    (string sub --length 22 $h) \
                    (string sub --length 25 $hostname) \
                    $port $user $key_icon
            end
            printf "\n"

        # ── ADD: Add new SSH host ──────────────────────────────────────────────
        case add
            set -l alias_name  $_host
            test -z "$alias_name" && read -P "  Host alias: " alias_name
            test -z "$alias_name" && return 1

            read -P "  Hostname/IP:     " hostname
            read -P "  Username [$USER]: " username
            read -P "  Port [22]:        " port
            read -P "  Identity file:    " identity

            test -z "$hostname" && begin
                printf "  $RED✗$R  Hostname required\n"; return 1
            end
            test -z "$username" && set username $USER
            test -z "$port"     && set port 22

            # Choose config file
            set -l target_config $_ssh_config
            if test -d "$_ssh_dir/config.d"
                set target_config "$_ssh_dir/config.d/$alias_name.conf"
            end

            # Check for duplicate
            if grep -qi "^Host $alias_name$" $target_config 2>/dev/null
                printf "  $YELLOW⚠$R  Host '$alias_name' already exists in $target_config\n"
                read -P "  Overwrite? [y/N] " confirm
                string match -qi 'y*' $confirm || return 0
            end

            # Write host entry
            set -l entry "\n# Added by ASH — $(date '+%Y-%m-%d')\nHost $alias_name\n"
            set entry "$entry    HostName $hostname\n"
            set entry "$entry    User $username\n"
            set entry "$entry    Port $port\n"
            test -n "$identity" && set entry "$entry    IdentityFile $identity\n"
            set entry "$entry    AddKeysToAgent yes\n"
            set entry "$entry    ServerAliveInterval 60\n"
            set entry "$entry    ServerAliveCountMax 3\n"
            set entry "$entry    StrictHostKeyChecking accept-new\n"

            printf $entry >> $target_config 2>/dev/null

            printf "\n  $GREEN✓$R  Host added: $CYAN%s$R → %s\n" $alias_name $target_config
            printf "  $DIM  Connect: ssh_connect %s$R\n\n" $alias_name

            # Offer to scan host key
            read -P "  Scan host key now? [Y/n] " scan_key
            if not string match -qi 'n*' $scan_key
                ssh-keyscan -p $port -H $hostname >> $_known_hosts 2>/dev/null
                and printf "  $GREEN✓$R  Host key added to known_hosts\n"
            end

            # Offer to copy SSH key
            read -P "  Copy SSH public key to host? [Y/n] " copy_key
            if not string match -qi 'n*' $copy_key
                ssh-copy-id -p $port "$username@$hostname" 2>/dev/null \
                    and printf "  $GREEN✓$R  Public key copied\n" \
                    or  printf "  $YELLOW⚠$R  Key copy failed — may need manual setup\n"
            end
            printf "\n"

        # ── REMOVE: Remove SSH host ────────────────────────────────────────────
        case remove
            set -l target $_host
            if test -z "$target"
                printf "  Usage: ssh_connect remove <host-alias>\n"
                return 1
            end

            printf "  $YELLOW⚠$R  Remove host: $CYAN$target$R\n"
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0

            # Find and remove from config files
            for cfg in $_ssh_config "$_ssh_dir/config.d/"*.conf
                test -f $cfg || continue
                if grep -qi "^Host $target\$" $cfg 2>/dev/null
                    # Remove the Host block
                    python3 -c "
import re, sys
with open('$cfg', 'r') as f:
    content = f.read()

# Remove the Host block
pattern = r'\n?# Added by.*?\n' if '# Added by' in content else ''
block_pattern = r'\nHost $target\n(?:(?!Host ).+\n)*'
content = re.sub(block_pattern, '\n', content, flags=re.MULTILINE)
with open('$cfg', 'w') as f:
    f.write(content)
print('Removed from: $cfg')
" 2>/dev/null
                    and printf "  $GREEN✓$R  Removed '$target' from $cfg\n"
                end
            end
            printf "\n"

        # ── EDIT: Edit SSH config ──────────────────────────────────────────────
        case edit
            set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)
            set -l config_target $_ssh_config

            if test -n "$_host"
                # Find file containing this host
                for cfg in $_ssh_config "$_ssh_dir/config.d/"*.conf
                    test -f $cfg || continue
                    grep -qi "^Host $_host" $cfg 2>/dev/null && \
                        set config_target $cfg && break
                end
            end

            $editor $config_target

        # ── SCAN: Add host key to known_hosts ──────────────────────────────────
        case scan
            if test -z "$_host"
                printf "  Usage: ssh_connect scan <hostname>\n"
                return 1
            end

            set -l port_flag ""
            test -n "$_port" && set port_flag "-p $_port"

            printf "  $CYAN🔍$R  Scanning: $_host\n"
            eval "ssh-keyscan $port_flag -H '$_host'" >> $_known_hosts 2>/dev/null
            and printf "  $GREEN✓$R  Host key saved to known_hosts\n\n"
            or  printf "  $RED✗$R  Scan failed\n\n"

        # ── COPY-KEY: Deploy public key ────────────────────────────────────────
        case copy-key
            if test -z "$_host"
                set _host (__ssh_get_hosts | sort -u |
                    fzf --border-label "  🔑 Select Host " \
                        --border rounded \
                        --prompt "  " \
                        --no-multi 2>/dev/null)
                test -z "$_host" && return 0
            end

            set -l ssh_flags ""
            test -n "$_port" && set ssh_flags "$ssh_flags -p $_port"
            test -n "$_user" && set ssh_flags "$ssh_flags -l $_user"

            printf "  $CYAN🔑$R  Copying public key to: $_host\n"
            eval "ssh-copy-id $ssh_flags '$_host'"
            set -l rc $status
            test $rc -eq 0 \
                && printf "  $GREEN✓$R  Key deployed successfully\n\n" \
                || printf "  $RED✗$R  Failed to copy key\n\n"
            return $rc

        # ── TUNNEL: Create SSH tunnel ──────────────────────────────────────────
        case tunnel
            # spec: local_port:remote_host:remote_port host
            set -l spec   $_host
            set -l t_host $_extra_args[1]

            if test -z "$spec" || test -z "$t_host"
                printf "\n  $BOLD$CYAN  SSH Tunnel Creator$R\n\n"
                read -P "  Host: " t_host
                test -z "$t_host" && return 1

                printf "  Tunnel type: [L]ocal / [R]emote / [D]ynamic SOCKS\n"
                read -P "  Type [L]: " t_type
                string lower $t_type | read -l t_type
                test -z "$t_type" && set t_type l

                read -P "  Local port:  " l_port
                read -P "  Remote host [localhost]: " r_host
                read -P "  Remote port: " r_port

                test -z "$r_host" && set r_host localhost

                switch $t_type
                    case l local
                        printf "\n  $CYAN🔀$R  Local tunnel: localhost:%s → %s:%s via %s\n" \
                            $l_port $r_host $r_port $t_host
                        ssh -N -L "$l_port:$r_host:$r_port" $t_host
                    case r remote
                        printf "\n  $CYAN🔀$R  Remote tunnel: %s:%s → localhost:%s\n" \
                            $t_host $l_port $r_port
                        ssh -N -R "$l_port:localhost:$r_port" $t_host
                    case d dynamic socks
                        printf "\n  $CYAN🧦$R  SOCKS5 proxy: localhost:%s via %s\n" \
                            $l_port $t_host
                        ssh -N -D $l_port $t_host
                end
            else
                # Direct: ssh_connect tunnel 8080:localhost:80 myhost
                printf "  $CYAN🔀$R  Tunnel: $spec → $t_host\n"
                set -l flags (__ssh_build_flags)
                eval "ssh -N -L '$spec' $flags '$t_host'"
            end

        # ── HISTORY: Show recent connections ───────────────────────────────────
        case history
            printf "\n  $BOLD$CYAN  📜 Recent SSH Connections$R\n\n"

            if test -f $_history_file && command -q jq
                printf "  $BOLD$CYAN%-22s  %s$R\n" "HOST" "TIMESTAMP"
                printf "  $DIM%s$R\n" (string repeat -n 45 "─")

                jq -r '.[] | "\(.host)\t\(.ts)"' $_history_file 2>/dev/null | \
                while read -l line
                    set -l parts (string split \t $line)
                    printf "  $CYAN%-22s$R  $DIM%s$R\n" \
                        (string sub --length 22 $parts[1]) $parts[2]
                end
            else if test -f $_log_file
                tail -30 $_log_file | while read -l line
                    printf "  $DIM%s$R\n" $line
                end
            else
                printf "  $DIM  No connection history yet$R\n"
            end
            printf "\n"

        # ── PING: Test SSH connectivity ────────────────────────────────────────
        case ping
            if test -z "$_host"
                printf "  Usage: ssh_connect ping <host>\n"
                return 1
            end

            set -l port_flag ""
            test -n "$_port" && set port_flag "-p $_port"

            printf "\n  $CYAN🏓$R  Testing SSH to: $_host\n\n"

            set -l ts_start (date +%s%N 2>/dev/null; or date +%s)
            ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
                -o BatchMode=yes $port_flag "$_host" true 2>/dev/null
            set -l rc $status
            set -l ts_end (date +%s%N 2>/dev/null; or date +%s)
            set -l elapsed_ms (math --scale 1 "($ts_end - $ts_start) / 1000000" 2>/dev/null; or echo "?")

            if test $rc -eq 0
                printf "  $GREEN✓$R  SSH reachable  $DIM(%sms)$R\n\n" $elapsed_ms
            else
                printf "  $RED✗$R  SSH unreachable $DIM(%sms)$R\n\n" $elapsed_ms
                return 1
            end

        # ── INFO: Show host configuration ──────────────────────────────────────
        case info
            if test -z "$_host"
                printf "  Usage: ssh_connect info <host>\n"
                return 1
            end

            printf "\n  $BOLD$CYAN  🔌 SSH Config: $_host$R\n\n"
            printf "  $BOLD$CYAN%-24s  %s$R\n" "OPTION" "VALUE"
            printf "  $DIM%s$R\n" (string repeat -n 55 "─")

            ssh -G "$_host" 2>/dev/null | \
                grep -E '^(hostname|user|port|identityfile|proxycommand|proxyjump|serveraliveinterval|compression|forwardagent|addkeystoagent)' | \
                while read -l line
                    set -l key (echo $line | awk '{print $1}')
                    set -l val (echo $line | awk '{$1=""; print $0}' | string trim)
                    printf "  $CYAN%-24s$R  $DIM%s$R\n" $key $val
                end

            printf "\n"
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __ssh_help __ssh_get_hosts __ssh_get_config \
        __ssh_build_flags __ssh_record_history __ssh_header 2>/dev/null

    return 0

end
