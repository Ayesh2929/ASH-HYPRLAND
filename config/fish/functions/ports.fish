# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ports Ultra                                        ║
# ║  Network port inspector: listening, processes, scanning & rich dashboard   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ports --description "Network port inspector and process manager"

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
    # ║  📚 WELL-KNOWN PORT DATABASE                                            ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Format: port:name:description:icon
    set -l _port_db \
        "21:FTP:File Transfer Protocol:" \
        "22:SSH:Secure Shell:" \
        "23:Telnet:Telnet Protocol:" \
        "25:SMTP:Mail Transfer:" \
        "53:DNS:Domain Name System:" \
        "67:DHCP:Dynamic Host Config:" \
        "80:HTTP:Web Server:" \
        "110:POP3:Mail Retrieval:" \
        "143:IMAP:Mail Access:" \
        "161:SNMP:Network Management:" \
        "389:LDAP:Directory Access:" \
        "443:HTTPS:Secure Web:" \
        "445:SMB:File Sharing:" \
        "465:SMTPS:Secure Mail:" \
        "514:Syslog:System Logging:" \
        "587:SMTP:Mail Submission:" \
        "631:IPP:Print Protocol:" \
        "993:IMAPS:Secure Mail:" \
        "995:POP3S:Secure Mail:" \
        "1080:SOCKS:Proxy:" \
        "1194:OpenVPN:VPN:" \
        "1433:MSSQL:SQL Server:" \
        "1521:Oracle:Oracle DB:" \
        "2049:NFS:Network Filesystem:" \
        "2375:Docker:Docker API:" \
        "2376:Docker-TLS:Docker TLS:" \
        "3000:Dev:Development Server:" \
        "3001:Dev:Development Server:" \
        "3306:MySQL:MySQL Database:" \
        "3389:RDP:Remote Desktop:" \
        "4200:Angular:Angular Dev:" \
        "4443:HTTPS-Alt:Alt HTTPS:" \
        "5000:Dev:Development Server:" \
        "5001:Dev:Development Server:" \
        "5173:Vite:Vite Dev Server:" \
        "5432:PostgreSQL:PostgreSQL DB:" \
        "5672:AMQP:RabbitMQ:" \
        "5900:VNC:Remote Desktop:" \
        "6379:Redis:Redis Cache:" \
        "6443:K8s-API:Kubernetes API:" \
        "7000:Cassandra:Cassandra DB:" \
        "8000:HTTP-Alt:Alt HTTP / Dev:" \
        "8001:HTTP-Alt:Alt HTTP:" \
        "8080:HTTP-Proxy:HTTP Proxy/Dev:" \
        "8081:HTTP-Alt:Alt HTTP:" \
        "8086:InfluxDB:InfluxDB:" \
        "8088:HTTP-Alt:Alt HTTP:" \
        "8443:HTTPS-Alt:Alt HTTPS:" \
        "8888:Jupyter:Jupyter Notebook:" \
        "9000:PHP-FPM:PHP FastCGI:" \
        "9090:Prometheus:Prometheus:" \
        "9092:Kafka:Apache Kafka:" \
        "9100:Node-Exp:Node Exporter:" \
        "9200:Elasticsearch:Elasticsearch:" \
        "9300:Elasticsearch:ES Cluster:" \
        "11211:Memcached:Memcached:" \
        "15672:RabbitMQ:RabbitMQ Mgmt:" \
        "27017:MongoDB:MongoDB:" \
        "27018:MongoDB:MongoDB Shard:" \
        "50000:Jenkins:Jenkins CI:" \
        "51413:BitTorrent:BitTorrent:"

    function __port_lookup --description "Lookup port name and icon"
        set -l port $argv[1]
        for entry in $_port_db
            set -l parts (string split ':' $entry)
            if test $parts[1] = $port
                echo "$parts[4] $parts[2]"
                return
            end
        end
        echo "  ?"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __ports_help --description "Print ports help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🔌  ports — Network Port Inspector               ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  ports [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "(none)"          "Show all listening ports" \
            "all"             "Show all connections (listen + established)" \
            "tcp"             "TCP ports only" \
            "udp"             "UDP ports only" \
            "pid <pid>"       "Ports used by process ID" \
            "proc <name>"     "Ports used by process name" \
            "check <port>"    "Check if a port is in use" \
            "kill <port>"     "Kill process using a port" \
            "scan <host>"     "Quick port scan of host" \
            "known"           "Show well-known port reference" \
            "watch"           "Live port monitor (auto-refresh)"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "-4, --ipv4"    "IPv4 only" \
            "-6, --ipv6"    "IPv6 only" \
            "-n, --numeric" "No hostname resolution" \
            "-p, --pick"    "Interactive picker (fzf)" \
            "-s, --sort"    "Sort by: port|pid|proc (default: port)" \
            "-h, --help"    "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "ports                  # All listening ports" \
            "ports all              # All connections" \
            "ports check 8080       # Is port 8080 in use?" \
            "ports kill 3000        # Kill process on port 3000" \
            "ports proc nginx       # Ports used by nginx" \
            "ports scan 192.168.1.1 # Scan common ports" \
            "ports watch            # Live port monitor" \
            "ports known 443        # What is port 443?"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode     listen   # listen | all | tcp | udp | pid | proc | check | kill | scan | known | watch
    set -l _target   ""       # port number, pid, process name, or host
    set -l _ipv4     0
    set -l _ipv6     0
    set -l _numeric  0
    set -l _pick     0
    set -l _sort     port
    set -l _proto    ""

    if test (count $argv) -eq 0
        true  # default mode: listen
    else
        switch $argv[1]
            case --help -h help;   __ports_help; return 0
            case all;              set _mode all;    set argv $argv[2..-1]
            case tcp;              set _mode tcp;    set _proto tcp; set argv $argv[2..-1]
            case udp;              set _mode udp;    set _proto udp; set argv $argv[2..-1]
            case pid;              set _mode pid;    set _target $argv[2]
            case proc process;     set _mode proc;   set _target $argv[2]
            case check test;       set _mode check;  set _target $argv[2]
            case kill close;       set _mode kill;   set _target $argv[2]
            case scan;             set _mode scan;   set _target $argv[2]
            case known info;       set _mode known;  set _target $argv[2]
            case watch monitor;    set _mode watch
        end
    end

    for arg in $argv
        switch $arg
            case -4 --ipv4;     set _ipv4    1
            case -6 --ipv6;     set _ipv6    1
            case -n --numeric;  set _numeric 1
            case -p --pick;     set _pick    1
            case --sort=*
                set _sort (string replace '--sort=' '' $arg)
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  BACKEND DETECTION: ss | netstat | lsof                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __ports_backend --description "Detect best port inspection tool"
        command -q ss      && echo ss      && return
        command -q netstat && echo netstat && return
        command -q lsof    && echo lsof    && return
        echo ""
    end

    set -l _backend (__ports_backend)

    if test -z "$_backend"
        printf "  $RED✗$R  No port inspection tool found\n"
        printf "  $DIM  Install: iproute2 (ss), net-tools (netstat), or lsof$R\n"
        return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 DATA COLLECTORS                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __ports_get_listening --description "Get all listening ports"
        set -l proto_filter $argv[1]   # tcp | udp | ""

        switch $_backend
            case ss
                set -l flags "-tlnp"
                test "$proto_filter" = udp && set flags "-ulnp"
                test -z "$proto_filter" && set flags "-tulnp"
                ss $flags 2>/dev/null | tail -n +2
            case netstat
                set -l flags "-tlnp"
                test "$proto_filter" = udp && set flags "-ulnp"
                test -z "$proto_filter" && set flags "-tulnp"
                netstat $flags 2>/dev/null | grep -E 'LISTEN|udp'
            case lsof
                set -l proto "+c0"
                test -n "$proto_filter" && set proto "-i $proto_filter"
                lsof -nP -i $proto_filter 2>/dev/null | grep LISTEN
        end
    end

    function __ports_get_all --description "Get all connections"
        switch $_backend
            case ss
                ss -tunap 2>/dev/null | tail -n +2
            case netstat
                netstat -tunap 2>/dev/null | tail -n +2
            case lsof
                lsof -nP -i 2>/dev/null
        end
    end

    function __ports_by_pid --description "Get ports for a PID"
        set -l pid $argv[1]
        switch $_backend
            case ss
                ss -tlnp 2>/dev/null | grep "pid=$pid,"
            case lsof
                lsof -nP -p $pid -i 2>/dev/null
            case netstat
                netstat -tlnp 2>/dev/null | grep "$pid/"
        end
    end

    function __ports_by_proc --description "Get ports for a process name"
        set -l pname $argv[1]
        switch $_backend
            case ss
                ss -tlnp 2>/dev/null | grep "\"$pname\""
            case lsof
                lsof -nP -c $pname -i 2>/dev/null | grep LISTEN
            case netstat
                netstat -tlnp 2>/dev/null | grep $pname
        end
    end

    function __ports_who_uses --description "Find what process uses a port"
        set -l port $argv[1]
        switch $_backend
            case ss
                ss -tlnp "sport = :$port" 2>/dev/null | tail -n +2
            case lsof
                lsof -nP -i ":$port" 2>/dev/null
            case netstat
                netstat -tlnp 2>/dev/null | awk -v p=":$port" '$4 ~ p || $4 ~ ":$port"'
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 ROW RENDERER                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __ports_render_row --description "Render a port row with colors"
        set -l proto  $argv[1]   # tcp | udp
        set -l local  $argv[2]   # local address:port
        set -l state  $argv[3]   # LISTEN | ESTABLISHED | etc
        set -l pid    $argv[4]   # PID
        set -l proc   $argv[5]   # process name

        # Extract port from local address
        set -l port (string replace -r '^.*:' '' $local)
        set -l addr (string replace ":$port" '' $local)

        # Well-known port info
        set -l port_info (__port_lookup $port)
        set -l port_icon (echo $port_info | awk '{print $1}')
        set -l port_name (echo $port_info | awk '{$1=""; print $0}' | string trim)
        test -z "$port_name" && set port_name ""

        # State color
        set -l state_color $DIM
        switch $state
            case LISTEN LISTENING
                set state_color $GREEN
            case ESTABLISHED
                set state_color $CYAN
            case TIME_WAIT
                set state_color $YELLOW
            case CLOSE_WAIT
                set state_color $ORANGE
            case '*'
                set state_color $DIM
        end

        # Proto color
        set -l proto_color $BLUE
        test "$proto" = udp && set proto_color $PURPLE

        # Port number color (well-known vs ephemeral)
        set -l port_color $CYAN
        test $port -lt 1024 2>/dev/null && set port_color $YELLOW
        test $port -gt 49151 2>/dev/null && set port_color $DIM

        printf "  %s%-4s%s  %s%-6s%s  %-22s  %s%-18s%s  %-6s  %s%-18s%s  %s%s%s\n" \
            $proto_color $proto $R \
            $port_color $port $R \
            $DIM$addr$R \
            $state_color $state $R \
            $DIM$pid$R \
            $CYAN $proc $R \
            $DIM$port_icon $port_name$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 MAIN TABLE RENDERER                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __ports_table --description "Render ports table"
        set -l data_lines $argv

        # Header
        printf "\n"
        printf "  $BOLD$CYAN%-4s  %-6s  %-22s  %-18s  %-6s  %-18s  %s$R\n" \
            "PROT" "PORT" "LOCAL ADDRESS" "STATE" "PID" "PROCESS" "SERVICE"
        printf "  $DIM%s$R\n" (string repeat -n 95 "─")

        set -l count 0

        for line in $data_lines
            # Parse ss output
            set -l parts (string split -n ' ' $line)

            switch $_backend
                case ss
                    # ss format: Netid State Local-Addr Peer-Addr Process
                    set -l netid  $parts[1]
                    set -l state  $parts[2]
                    set -l local  $parts[5]
                    set -l proc   ""
                    set -l pid    ""

                    # Extract PID/process from ss output
                    if string match -q '*pid=*' $line
                        set pid  (string match -r 'pid=(\d+)' $line | tail -1)
                        set proc (string match -r '"([^"]+)"' $line | tail -1 | string trim -c '"')
                    end

                    # Normalize proto
                    set -l proto tcp
                    string match -q 'udp*' $netid && set proto udp

                    __ports_render_row $proto $local $state $pid $proc
                    set count (math $count + 1)

                case lsof
                    # lsof format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
                    set -l proc  $parts[1]
                    set -l pid   $parts[2]
                    set -l name  $parts[-1]
                    set -l proto (string lower $parts[5])
                    set -l state (string match -r '\((\w+)\)' $line | tail -1 | string trim -c '()')
                    test -z "$state" && set state ""

                    # Parse port from NAME field (host:port or *:port)
                    set -l local_addr $name

                    __ports_render_row $proto $local_addr $state $pid $proc
                    set count (math $count + 1)

                case netstat
                    # netstat format: Proto Recv-Q Send-Q Local-Addr Foreign-Addr State PID/Program
                    set -l proto $parts[1]
                    set -l local $parts[4]
                    set -l state $parts[6]
                    set -l pidproc (test (count $parts) -ge 7 && echo $parts[7] || echo "-")
                    set -l pid  (string split '/' $pidproc)[1]
                    set -l proc (string split '/' $pidproc)[2]
                    test -z "$proc" && set proc "-"

                    __ports_render_row $proto $local $state $pid $proc
                    set count (math $count + 1)
            end
        end

        printf "  $DIM%s$R\n" (string repeat -n 95 "─")
        printf "  $DIM%d port(s) shown  ·  backend: $_backend$R\n\n" $count
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_mode

        # ── Listen / TCP / UDP ────────────────────────────────────────────────
        case listen tcp udp
            set -l banner "Listening Ports"
            test "$_mode" = tcp && set banner "TCP Listening Ports"
            test "$_mode" = udp && set banner "UDP Listening Ports"

            printf "\n  $BOLD$PURPLE🔌 %s$R  $DIM— backend: %s$R\n" $banner $_backend

            set -l data (__ports_get_listening $_proto)

            if test $_pick -eq 1 && command -q fzf
                set -l selected (
                    printf '%s\n' $data |
                    fzf --ansi \
                        --border-label "  🔌 Listening Ports " \
                        --border rounded \
                        --prompt "  🔍 " \
                        --pointer "▶" \
                        --header "  Enter:select  Ctrl-K:kill process  " \
                        --bind 'ctrl-k:execute(
                            port=$(echo {} | grep -oP ":\K\d+" | head -1)
                            pid=$(ss -tlnp "sport = :$port" 2>/dev/null | grep -oP "pid=\K\d+" | head -1)
                            test -n "$pid" && kill $pid && echo "Killed PID $pid"
                        )+reload(ss -tulnp 2>/dev/null | tail -n +2)' \
                        --height 60%
                )
                test -n "$selected" && echo $selected
            else
                __ports_table $data
            end

        # ── All connections ───────────────────────────────────────────────────
        case all
            printf "\n  $BOLD$PURPLE🔌 All Connections$R  $DIM— backend: $_backend$R\n"
            set -l data (__ports_get_all)
            __ports_table $data

        # ── By PID ────────────────────────────────────────────────────────────
        case pid
            if test -z "$_target"
                printf "  $RED✗$R  Usage: ports pid <PID>\n"
                return 1
            end
            if not kill -0 $_target 2>/dev/null
                printf "  $RED✗$R  No process with PID: $_target\n"
                return 1
            end
            set -l proc_name (ps -o comm= -p $_target 2>/dev/null | string trim)
            printf "\n  $BOLD$PURPLE🔌 Ports for PID $_target$R  $DIM($proc_name)$R\n"
            set -l data (__ports_by_pid $_target)
            test -n "$data" && __ports_table $data \
                || printf "  $DIM  No ports found for PID $_target$R\n\n"

        # ── By process name ───────────────────────────────────────────────────
        case proc
            if test -z "$_target"
                printf "  $RED✗$R  Usage: ports proc <process-name>\n"
                return 1
            end
            printf "\n  $BOLD$PURPLE🔌 Ports for process: $_target$R\n"
            set -l data (__ports_by_proc $_target)
            test -n "$data" && __ports_table $data \
                || printf "  $DIM  No ports found for process '$_target'$R\n\n"

        # ── Check specific port ───────────────────────────────────────────────
        case check
            if test -z "$_target"
                printf "  $RED✗$R  Usage: ports check <port>\n"
                return 1
            end
            printf "\n  $BOLD$CYAN🔍 Checking port: $_target$R\n\n"

            set -l port_info (__port_lookup $_target)
            set -l service_info ""
            for entry in $_port_db
                set -l parts (string split ':' $entry)
                if test $parts[1] = $_target
                    printf "  $DIM›$R  Service:     $CYAN%s$R — $DIM%s$R\n" \
                        "$parts[4] $parts[2]" $parts[3]
                    break
                end
            end

            set -l data (__ports_who_uses $_target)

            if test -n "$data"
                printf "  $RED●$R  Port $BOLD$_target$R is $RED$BOLD IN USE$R\n\n"
                __ports_table $data

                # Get PID for kill suggestion
                set -l pid (echo $data | grep -oP 'pid=\K\d+' | head -1)
                if test -z "$pid"
                    set pid (echo $data | awk 'NR==2{print $7}' | cut -d/ -f1)
                end
                test -n "$pid" && \
                    printf "  $DIM  Kill with: ports kill $_target$R\n\n"
            else
                printf "  $GREEN●$R  Port $BOLD$_target$R is $GREEN$BOLD AVAILABLE$R\n\n"
            end

        # ── Kill process on port ───────────────────────────────────────────────
        case kill
            if test -z "$_target"
                printf "  $RED✗$R  Usage: ports kill <port>\n"
                return 1
            end

            printf "\n  $BOLD$RED⚠  Kill process on port: $_target$R\n\n"

            # Find PID
            set -l pid ""
            switch $_backend
                case ss
                    set pid (ss -tlnp "sport = :$_target" 2>/dev/null | \
                        grep -oP 'pid=\K\d+' | head -1)
                case lsof
                    set pid (lsof -ti :$_target 2>/dev/null | head -1)
                case netstat
                    set pid (netstat -tlnp 2>/dev/null | \
                        awk -v p=":$_target" '$4 ~ p {print $7}' | \
                        cut -d/ -f1 | head -1)
            end

            if test -z "$pid"
                printf "  $DIM  No process found on port $_target$R\n\n"
                return 0
            end

            set -l proc_name (ps -o comm= -p $pid 2>/dev/null | string trim)
            printf "  $DIM›$R  Process: $CYAN$proc_name$R  $DIM(PID: $pid)$R\n"
            read -P "  Kill? [y/N] " confirm
            string match -qi 'y*' $confirm || begin; echo "  Cancelled."; return 0; end

            kill -TERM $pid 2>/dev/null
            sleep 0.5

            # Verify killed
            if kill -0 $pid 2>/dev/null
                printf "  $YELLOW⚠$R  Process still running — sending SIGKILL\n"
                kill -KILL $pid 2>/dev/null
                and printf "  $GREEN✓$R  Process killed (SIGKILL)\n\n"
            else
                printf "  $GREEN✓$R  Process terminated (SIGTERM)\n\n"
            end

        # ── Port scan ─────────────────────────────────────────────────────────
        case scan
            if test -z "$_target"
                printf "  $RED✗$R  Usage: ports scan <host>\n"
                return 1
            end

            printf "\n  $BOLD$CYAN🔍 Scanning: $_target$R  $DIM(common ports)$R\n\n"

            # Common ports to scan
            set -l common_ports \
                21 22 23 25 53 80 110 143 443 445 \
                3000 3306 3389 5432 5672 5900 6379 \
                8080 8443 8888 9090 9200 27017

            set -l open_count 0

            printf "  $BOLD$CYAN%-7s  %-6s  %-20s  %s$R\n" "STATE" "PORT" "SERVICE" "BANNER"
            printf "  $DIM%s$R\n" (string repeat -n 60 "─")

            for port in $common_ports
                # Quick TCP connect test
                if command -q nc
                    nc -z -w 1 $_target $port 2>/dev/null
                    set -l rc $status
                else if command -q bash
                    bash -c "exec 3<>/dev/tcp/$_target/$port" 2>/dev/null
                    set -l rc $status
                    bash -c "exec 3>&-" 2>/dev/null
                else
                    continue
                end

                set -l port_info (__port_lookup $port)
                set -l service_icon (echo $port_info | awk '{print $1}')
                set -l service_name (echo $port_info | awk '{$1=""; print $0}' | string trim)
                test -z "$service_name" && set service_name "unknown"

                if test $rc -eq 0
                    printf "  $GREEN%-7s$R  $CYAN%-6s$R  %s %-18s\n" \
                        "OPEN" $port $service_icon $service_name
                    set open_count (math $open_count + 1)
                end
            end

            printf "  $DIM%s$R\n" (string repeat -n 60 "─")
            printf "  $DIM%d open port(s) found on %s$R\n\n" $open_count $_target

        # ── Known port reference ──────────────────────────────────────────────
        case known
            if test -n "$_target"
                # Lookup specific port
                echo ""
                for entry in $_port_db
                    set -l parts (string split ':' $entry)
                    if test $parts[1] = $_target
                        printf "  $BOLD$CYAN%s  Port %s$R\n\n" $parts[4] $parts[1]
                        printf "  $BOLD%-12s$R  %s\n" "Service:" $parts[2]
                        printf "  $BOLD%-12s$R  %s\n" "Protocol:" "TCP/UDP"
                        printf "  $BOLD%-12s$R  %s\n" "Description:" $parts[3]
                        echo ""
                        return
                    end
                end
                printf "  $DIM  Port $_target not in well-known database$R\n\n"
            else
                # Show all known ports
                printf "\n  $BOLD$PURPLE📚 Well-Known Ports Reference$R\n\n"
                printf "  $BOLD$CYAN%-6s  %-12s  %-22s  %s$R\n" \
                    "PORT" "SERVICE" "DESCRIPTION" "ICON"
                printf "  $DIM%s$R\n" (string repeat -n 60 "─")

                for entry in $_port_db
                    set -l parts (string split ':' $entry)
                    set -l port_color $CYAN
                    test $parts[1] -lt 1024 2>/dev/null && set port_color $YELLOW

                    printf "  $port_color%-6s$R  $BOLD%-12s$R  %-22s  %s\n" \
                        $parts[1] $parts[2] \
                        (string sub --length 22 $parts[3]) $parts[4]
                end
                printf "\n  $DIM%d well-known ports$R\n\n" (count $_port_db)
            end

        # ── Live watch ────────────────────────────────────────────────────────
        case watch
            printf "\n  $BOLD$CYAN👁  Live Port Monitor$R  $DIM(Ctrl-C to stop)$R\n\n"

            set -l interval 2
            set -l prev_data ""

            while true
                set -l data (__ports_get_listening "")
                set -l current_data (string join '\n' $data)

                if test "$current_data" != "$prev_data"
                    clear
                    printf "  $BOLD$CYAN👁  Live Port Monitor$R  $DIM%s  (refresh: every %ds)$R\n" \
                        (date '+%H:%M:%S') $interval

                    # Show diff if we have previous data
                    if test -n "$prev_data"
                        printf "  $YELLOW⚡ Changes detected$R\n"
                    end

                    __ports_table $data
                    set prev_data $current_data
                end

                sleep $interval
            end
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __ports_help __port_lookup __ports_backend \
        __ports_get_listening __ports_get_all __ports_by_pid \
        __ports_by_proc __ports_who_uses __ports_render_row __ports_table 2>/dev/null
    set --erase _port_db 2>/dev/null

end
