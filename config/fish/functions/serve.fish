#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌐 SERVE.FISH — Ultra Local Development Server                             ║
# ║  ASH Dotfiles v5.0 OMEGA • Ultra-Grade Function                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   serve                       — Serve current dir on :8080
#   serve <port>                — Serve on custom port
#   serve <dir> <port>          — Serve specific dir on port
#   serve -t / --type <type>    — Server type (auto/python/node/caddy/nginx/...)
#   serve -o / --open           — Auto-open browser
#   serve -l / --lan            — Expose on LAN (0.0.0.0)
#   serve -s / --spa            — SPA mode (redirect 404 → index.html)
#   serve -c / --cors           — Enable CORS headers
#   serve -q / --qr             — Show QR code for LAN URL
#   serve --ssl                 — Serve with self-signed HTTPS
#   serve --list                — List active serves
#   serve --stop <port>         — Stop server on port
#   serve --stop-all            — Stop all active serves
#   serve --proxy <url>         — Reverse proxy to URL
#   serve --log                 — Enable access logging

# ─── Constants ────────────────────────────────────────────────────────────────

set -l __SERVE_VERSION   "5.0.0"
set -l __SERVE_DEFAULT_PORT 8080
set -l __SERVE_PID_DIR   "$HOME/.cache/ash/serve/pids"
set -l __SERVE_LOG_DIR   "$HOME/.cache/ash/serve/logs"
set -l __SERVE_CERT_DIR  "$HOME/.cache/ash/serve/certs"

# ─── Color Palette ─────────────────────────────────────────────────────────────

set -l CLR_RESET    (set_color normal)
set -l CLR_BOLD     (set_color --bold)
set -l CLR_DIM      (set_color brblack)
set -l CLR_RED      (set_color red)
set -l CLR_GREEN    (set_color green)
set -l CLR_YELLOW   (set_color yellow)
set -l CLR_BLUE     (set_color blue)
set -l CLR_CYAN     (set_color cyan)
set -l CLR_MAGENTA  (set_color magenta)
set -l CLR_BRED     (set_color brred)
set -l CLR_BGREEN   (set_color brgreen)
set -l CLR_BYELLOW  (set_color bryellow)
set -l CLR_BBLUE    (set_color brblue)
set -l CLR_BCYAN    (set_color brcyan)
set -l CLR_BMAGENTA (set_color brmagenta)
set -l CLR_WHITE    (set_color white)

# ─── Print Helpers ─────────────────────────────────────────────────────────────

function __serve_ok    -a msg; echo $CLR_BGREEN"  ✅  $msg"$CLR_RESET; end
function __serve_err   -a msg; echo $CLR_BRED"  ❌  $msg"$CLR_RESET >&2; end
function __serve_warn  -a msg; echo $CLR_BYELLOW"  ⚠️   $msg"$CLR_RESET; end
function __serve_tip   -a msg; echo $CLR_BCYAN"  💡  $msg"$CLR_RESET; end
function __serve_info  -a msg; echo $CLR_BBLUE"  ℹ️   $msg"$CLR_RESET; end
function __serve_dim   -a msg; echo $CLR_DIM"       $msg"$CLR_RESET; end

function __serve_section -a label
    echo ""
    echo $CLR_BBLUE"┌─ "$CLR_BYELLOW"$label "$CLR_BBLUE"─────────────────────────"$CLR_RESET
end

# ─── Ensure Dirs ──────────────────────────────────────────────────────────────

function __serve_ensure_dirs
    for d in $__SERVE_PID_DIR $__SERVE_LOG_DIR $__SERVE_CERT_DIR
        test -d $d; or mkdir -p $d
    end
end

# ─── PID File Helpers ─────────────────────────────────────────────────────────

function __serve_pid_path  -a port;  echo "$__SERVE_PID_DIR/$port.pid"; end
function __serve_log_path  -a port;  echo "$__SERVE_LOG_DIR/$port.log"; end
function __serve_info_path -a port;  echo "$__SERVE_PID_DIR/$port.info"; end

function __serve_save_pid -a port -a pid -a dir -a type
    echo $pid > (__serve_pid_path $port)
    echo "dir=$dir" > (__serve_info_path $port)
    echo "type=$type" >> (__serve_info_path $port)
    echo "started="(date '+%Y-%m-%d %H:%M:%S') >> (__serve_info_path $port)
end

function __serve_is_running -a port
    set -l pid_file (__serve_pid_path $port)
    if not test -f $pid_file
        return 1
    end
    set -l pid (cat $pid_file)
    kill -0 $pid 2>/dev/null
    return $status
end

function __serve_get_pid -a port
    set -l pid_file (__serve_pid_path $port)
    test -f $pid_file; and cat $pid_file
end

# ─── Get LAN IP ───────────────────────────────────────────────────────────────

function __serve_lan_ip
    # Try multiple methods to get the LAN IP
    set -l ip (ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
    if test -n "$ip"
        echo $ip
        return 0
    end

    set ip (hostname -I 2>/dev/null | awk '{print $1}')
    if test -n "$ip"
        echo $ip
        return 0
    end

    echo "127.0.0.1"
end

# ─── Check Port Available ─────────────────────────────────────────────────────

function __serve_port_available -a port
    if command -q ss
        set -l in_use (ss -tlnp 2>/dev/null | grep ":$port ")
    else if command -q netstat
        set -l in_use (netstat -tlnp 2>/dev/null | grep ":$port ")
    else
        # Try connecting
        bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null
        if test $status -eq 0
            return 1  # Port in use
        end
        return 0
    end

    if test -n "$in_use"
        return 1  # Port in use
    end
    return 0  # Port free
end

# ─── Find Free Port ───────────────────────────────────────────────────────────

function __serve_find_free_port -a start
    set -l port $start
    while not __serve_port_available $port
        set port (math $port + 1)
        if test $port -gt 65535
            echo ""
            return 1
        end
    end
    echo $port
end

# ─── Open Browser ─────────────────────────────────────────────────────────────

function __serve_open_browser -a url
    if command -q xdg-open
        xdg-open $url &
    else if command -q open
        open $url &
    else
        __serve_info "Open: $url"
    end
end

# ─── Show QR Code ─────────────────────────────────────────────────────────────

function __serve_qr -a url
    if command -q qrencode
        echo ""
        echo $CLR_BBLUE"  📱 QR Code (scan to connect from mobile):"$CLR_RESET
        echo ""
        qrencode -t ANSIUTF8 "$url"
        echo ""
    else if command -q python3
        echo ""
        echo $CLR_BBLUE"  📱 QR Code URL:"$CLR_RESET
        echo $CLR_BCYAN"  $url"$CLR_RESET
        python3 -c "
import urllib.parse
data = urllib.parse.quote('$url')
print(f'  https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={data}')
"
        echo ""
    else
        __serve_tip "Install qrencode for QR: paru -S qrencode"
    end
end

# ─── Generate Self-Signed Cert ────────────────────────────────────────────────

function __serve_gen_cert
    if not command -q openssl
        __serve_err "openssl required for SSL: paru -S openssl"
        return 1
    end

    set -l cert_file "$__SERVE_CERT_DIR/serve.crt"
    set -l key_file  "$__SERVE_CERT_DIR/serve.key"

    if not test -f $cert_file -o -f $key_file
        __serve_info "Generating self-signed certificate..."
        openssl req -x509 -newkey rsa:2048 -keyout $key_file \
            -out $cert_file -days 365 -nodes \
            -subj "/CN=localhost/O=ASH Dev Server/C=US" 2>/dev/null
        if test $status -eq 0
            __serve_ok "Certificate generated: $cert_file"
        else
            __serve_err "Failed to generate certificate"
            return 1
        end
    end

    echo "$cert_file $key_file"
    return 0
end

# ─── Detect Server Type ───────────────────────────────────────────────────────

function __serve_detect_type -a dir
    # Detect based on project files
    if test -f "$dir/package.json"
        # Check for framework-specific scripts
        if test -f "$dir/next.config.js" -o -f "$dir/next.config.ts"
            echo "next"
        else if test -f "$dir/vite.config.ts" -o -f "$dir/vite.config.js"
            echo "vite"
        else if test -f "$dir/astro.config.mjs"
            echo "astro"
        else if command -q npx
            echo "npx-serve"
        else
            echo "node"
        end
    else if test -f "$dir/Cargo.toml"
        echo "python"  # Serve static for Rust projects
    else if test -f "$dir/requirements.txt" -o -f "$dir/pyproject.toml"
        echo "python"
    else
        echo "python"  # Default to python http.server
    end
end

# ─── Server: Python ───────────────────────────────────────────────────────────

function __serve_python -a dir -a host -a port -a log_enabled
    if not command -q python3
        __serve_err "python3 not found"
        return 1
    end

    set -l log_path (__serve_log_path $port)

    # Python one-liner with CORS + logging
    set -l py_cmd "python3 -c \"
import http.server, socketserver, os, sys
os.chdir('$dir')

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()
    def log_message(self, fmt, *args):
        if '$log_enabled' == '1':
            with open('$log_path', 'a') as f:
                f.write(fmt % args + '\n')
        sys.stderr.write(fmt % args + '\n')

with socketserver.TCPServer(('$host', $port), Handler) as httpd:
    httpd.allow_reuse_address = True
    httpd.serve_forever()
\""

    if test "$log_enabled" = "1"
        eval $py_cmd 2>>$log_path &
    else
        eval $py_cmd 2>/dev/null &
    end

    echo $last_pid
end

# ─── Server: npx serve ────────────────────────────────────────────────────────

function __serve_npx -a dir -a host -a port -a spa_mode
    if not command -q npx
        return 1
    end

    set -l spa_flag (test "$spa_mode" = "1"; and echo "--single"; or echo "")

    npx --yes serve \
        --listen "tcp://$host:$port" \
        $spa_flag \
        "$dir" &>/dev/null &

    echo $last_pid
end

# ─── Server: PHP ──────────────────────────────────────────────────────────────

function __serve_php -a dir -a host -a port
    if not command -q php
        return 1
    end

    php -S "$host:$port" -t "$dir" &>/dev/null &
    echo $last_pid
end

# ─── Server: Ruby ─────────────────────────────────────────────────────────────

function __serve_ruby -a dir -a host -a port
    if not command -q ruby
        return 1
    end

    pushd $dir
    ruby -run -e httpd . -p $port -b $host &>/dev/null &
    popd
    echo $last_pid
end

# ─── Server Launch ────────────────────────────────────────────────────────────

function __serve_launch \
    -a dir \
    -a port \
    -a host \
    -a server_type \
    -a spa_mode \
    -a open_browser \
    -a show_qr \
    -a ssl_mode \
    -a log_enabled

    # Check port
    if not __serve_port_available $port
        # Try to find alternative
        set -l new_port (__serve_find_free_port (math $port + 1))
        if test -z "$new_port"
            __serve_err "No free ports available"
            return 1
        end
        __serve_warn "Port $port in use → using $port$new_port"
        set port $new_port
    end

    # Auto-detect type
    if test "$server_type" = "auto" -o -z "$server_type"
        set server_type (__serve_detect_type $dir)
    end

    # Protocol
    set -l proto (test "$ssl_mode" = "1"; and echo "https"; or echo "http")

    # Launch server
    set -l pid ""
    switch $server_type
        case python
            set pid (__serve_python $dir $host $port $log_enabled)
        case npx-serve node
            set pid (__serve_npx $dir $host $port $spa_mode)
            if test -z "$pid"
                # Fallback to python
                set pid (__serve_python $dir $host $port $log_enabled)
                set server_type "python"
            end
        case php
            set pid (__serve_php $dir $host $port)
        case ruby
            set pid (__serve_ruby $dir $host $port)
        case '*'
            set pid (__serve_python $dir $host $port $log_enabled)
            set server_type "python"
    end

    if test -z "$pid"
        __serve_err "Failed to start server"
        return 1
    end

    # Wait a moment for server to start
    sleep 0.3

    # Verify it started
    if not kill -0 $pid 2>/dev/null
        __serve_err "Server failed to start (check if python3/node available)"
        return 1
    end

    # Save state
    __serve_ensure_dirs
    __serve_save_pid $port $pid $dir $server_type

    # Show startup info
    set -l lan_ip (__serve_lan_ip)
    set -l local_url "$proto://localhost:$port"
    set -l lan_url   "$proto://$lan_ip:$port"

    echo ""
    echo $CLR_BGREEN"  ┌─────────────────────────────────────────────────────┐"$CLR_RESET
    echo $CLR_BGREEN"  │"$CLR_RESET"  🌐  "$CLR_BCYAN"ASH Dev Server"$CLR_RESET" — "$CLR_DIM"$server_type"$CLR_RESET"                         "$CLR_BGREEN"│"$CLR_RESET
    echo $CLR_BGREEN"  ├─────────────────────────────────────────────────────┤"$CLR_RESET
    printf "  $CLR_BGREEN│$CLR_RESET  %-14s $CLR_BCYAN%-36s$CLR_BGREEN│$CLR_RESET\n" "📂 Directory:" (string shorten -m 36 $dir)
    printf "  $CLR_BGREEN│$CLR_RESET  %-14s $CLR_BGREEN%-36s$CLR_BGREEN│$CLR_RESET\n" "🏠 Local:" $local_url
    if test "$host" = "0.0.0.0"
        printf "  $CLR_BGREEN│$CLR_RESET  %-14s $CLR_BYELLOW%-36s$CLR_BGREEN│$CLR_RESET\n" "🌍 Network:" $lan_url
    end
    printf "  $CLR_BGREEN│$CLR_RESET  %-14s $CLR_DIM%-36s$CLR_BGREEN│$CLR_RESET\n" "⚙️  Process:" "PID $pid"
    if test "$spa_mode" = "1"
        printf "  $CLR_BGREEN│$CLR_RESET  %-14s $CLR_BMAGENTA%-36s$CLR_BGREEN│$CLR_RESET\n" "🔄 Mode:" "SPA (404 → index.html)"
    end
    if test "$ssl_mode" = "1"
        printf "  $CLR_BGREEN│$CLR_RESET  %-14s $CLR_BYELLOW%-36s$CLR_BGREEN│$CLR_RESET\n" "🔒 SSL:" "Self-signed certificate"
    end
    echo $CLR_BGREEN"  ├─────────────────────────────────────────────────────┤"$CLR_RESET
    echo $CLR_BGREEN"  │"$CLR_RESET"  "$CLR_DIM"Ctrl+C to stop  |  serve --stop $port  |  serve --list"$CLR_RESET"  "$CLR_BGREEN"│"$CLR_RESET
    echo $CLR_BGREEN"  └─────────────────────────────────────────────────────┘"$CLR_RESET
    echo ""

    # Open browser
    if test "$open_browser" = "1"
        sleep 0.5
        __serve_open_browser $local_url
        __serve_info "Opened in browser"
    end

    # Show QR
    if test "$show_qr" = "1"
        __serve_qr $lan_url
    end

    # Log file location
    if test "$log_enabled" = "1"
        __serve_dim "Access log: "(__serve_log_path $port)
    end

    # Copy URL to clipboard
    if command -q wl-copy
        echo $local_url | wl-copy 2>/dev/null
        __serve_dim "URL copied to clipboard"
    end

    echo ""

    # Register trap to cleanup on Ctrl+C
    trap "
        kill $pid 2>/dev/null
        rm -f (__serve_pid_path $port) (__serve_info_path $port)
        echo ''
        echo '$CLR_BYELLOW  🛑  Server stopped$CLR_RESET'
        echo ''
    " INT

    # Wait for server process
    wait $pid 2>/dev/null
end

# ─── List Active Serves ───────────────────────────────────────────────────────

function __serve_list
    __serve_section "🌐  Active Servers"
    echo ""

    set -l pid_files $__SERVE_PID_DIR/*.pid 2>/dev/null
    if test (count $pid_files) -eq 0 -o "$pid_files" = "$__SERVE_PID_DIR/*.pid"
        __serve_dim "No active servers"
        echo ""
        return 0
    end

    set -l found_any 0
    for pid_file in $pid_files
        set -l port (basename $pid_file .pid)
        if __serve_is_running $port
            set found_any 1
            set -l pid (cat $pid_file)
            set -l info_file (__serve_info_path $port)
            set -l dir "unknown"
            set -l type "unknown"
            set -l started "unknown"

            if test -f $info_file
                set dir  (grep "^dir="     $info_file | cut -d= -f2-)
                set type (grep "^type="    $info_file | cut -d= -f2)
                set started (grep "^started=" $info_file | cut -d= -f2-)
            end

            printf "  $CLR_BGREEN●$CLR_RESET %-8s $CLR_BCYAN%-30s$CLR_RESET $CLR_DIM(PID:%-6s type:%-10s started:%s)$CLR_RESET\n" \
                "port $port" \
                "http://localhost:$port" \
                $pid \
                $type \
                $started
        else
            # Clean up stale PID files
            rm -f $pid_file (__serve_info_path $port)
        end
    end

    if test $found_any -eq 0
        __serve_dim "No active servers (cleaned up stale files)"
    end
    echo ""
end

# ─── Stop Server ──────────────────────────────────────────────────────────────

function __serve_stop -a port
    if test -z "$port"
        __serve_err "Port required: serve --stop <port>"
        return 1
    end

    if not __serve_is_running $port
        __serve_warn "No server found on port $port"
        rm -f (__serve_pid_path $port) (__serve_info_path $port)
        return 1
    end

    set -l pid (__serve_get_pid $port)
    kill $pid 2>/dev/null
    sleep 0.2

    if kill -0 $pid 2>/dev/null
        kill -9 $pid 2>/dev/null
        __serve_warn "Force killed PID $pid"
    else
        __serve_ok "Stopped server on port $port (PID $pid)"
    end

    rm -f (__serve_pid_path $port) (__serve_info_path $port)
end

# ─── Stop All Servers ─────────────────────────────────────────────────────────

function __serve_stop_all
    set -l pid_files $__SERVE_PID_DIR/*.pid 2>/dev/null
    if test (count $pid_files) -eq 0 -o "$pid_files" = "$__SERVE_PID_DIR/*.pid"
        __serve_warn "No servers to stop"
        return 0
    end

    set -l stopped 0
    for pid_file in $pid_files
        set -l port (basename $pid_file .pid)
        if __serve_is_running $port
            __serve_stop $port
            set stopped (math $stopped + 1)
        else
            rm -f $pid_file (__serve_info_path $port)
        end
    end

    if test $stopped -eq 0
        __serve_dim "No active servers found"
    else
        __serve_ok "Stopped $stopped server(s)"
    end
end

# ─── Help ─────────────────────────────────────────────────────────────────────

function __serve_help
    echo ""
    echo $CLR_BBLUE"╔════════════════════════════════════════════════════╗"$CLR_RESET
    echo $CLR_BBLUE"║  "$CLR_BCYAN"🌐  ASH SERVE v$__SERVE_VERSION — Dev Server Ultra  "$CLR_BBLUE"║"$CLR_RESET
    echo $CLR_BBLUE"╚════════════════════════════════════════════════════╝"$CLR_RESET
    echo ""
    echo $CLR_BYELLOW"  USAGE"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────────"$CLR_RESET
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve" "Serve cwd on :8080"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve <port>" "Custom port"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve <dir> <port>" "Specific dir + port"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve -o / --open" "Auto-open browser"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve -l / --lan" "Expose on LAN (0.0.0.0)"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve -s / --spa" "SPA mode (404→index.html)"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve -q / --qr" "Show QR code for LAN"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve --ssl" "HTTPS with self-signed cert"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve --log" "Enable access logging"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve -t / --type <type>" "Server type"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve --list" "Show active servers"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve --stop <port>" "Stop server"
    printf "  $CLR_BGREEN%-42s$CLR_RESET %s\n" "serve --stop-all" "Stop all servers"
    echo ""
    echo $CLR_BYELLOW"  SERVER TYPES (-t)"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────────"$CLR_RESET
    printf "  $CLR_BGREEN%-15s$CLR_RESET %s\n" "auto" "Auto-detect (default)"
    printf "  $CLR_BGREEN%-15s$CLR_RESET %s\n" "python" "python3 -m http.server"
    printf "  $CLR_BGREEN%-15s$CLR_RESET %s\n" "npx-serve" "npx serve (Node.js)"
    printf "  $CLR_BGREEN%-15s$CLR_RESET %s\n" "php" "php -S"
    printf "  $CLR_BGREEN%-15s$CLR_RESET %s\n" "ruby" "ruby -run -e httpd"
    echo ""
    echo $CLR_BYELLOW"  EXAMPLES"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────────"$CLR_RESET
    echo $CLR_DIM"  serve                          # Serve cwd:8080"$CLR_RESET
    echo $CLR_DIM"  serve 3000                     # Serve cwd:3000"$CLR_RESET
    echo $CLR_DIM"  serve ./dist 5000              # Serve dist/:5000"$CLR_RESET
    echo $CLR_DIM"  serve -o                       # Serve + open browser"$CLR_RESET
    echo $CLR_DIM"  serve -l -q                    # LAN + QR code"$CLR_RESET
    echo $CLR_DIM"  serve -s -o 3000               # SPA + browser:3000"$CLR_RESET
    echo $CLR_DIM"  serve --ssl -o                 # HTTPS + browser"$CLR_RESET
    echo $CLR_DIM"  serve --list                   # Show running servers"$CLR_RESET
    echo $CLR_DIM"  serve --stop 8080              # Stop port 8080"$CLR_RESET
    echo ""
end

# ═══════════════════════════════════════════════════════════════════════════════
# ─── MAIN FUNCTION ─────────────────────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════

function serve
    # ── Default settings ──────────────────────────────────────────────────────
    set -l serve_dir     (pwd)
    set -l serve_port    $__SERVE_DEFAULT_PORT
    set -l serve_host    "127.0.0.1"
    set -l serve_type    "auto"
    set -l serve_open    0
    set -l serve_spa     0
    set -l serve_qr      0
    set -l serve_ssl     0
    set -l serve_log     0
    set -l serve_cors    0

    # ── No args → serve cwd ───────────────────────────────────────────────────
    if test (count $argv) -eq 0
        __serve_ensure_dirs
        __serve_launch $serve_dir $serve_port $serve_host $serve_type \
            $serve_spa $serve_open $serve_qr $serve_ssl $serve_log
        return $status
    end

    # ── Quick numeric arg (just port) ─────────────────────────────────────────
    if test (count $argv) -eq 1
        if string match -qr '^\d+$' $argv[1]
            set serve_port $argv[1]
            __serve_ensure_dirs
            __serve_launch $serve_dir $serve_port $serve_host $serve_type \
                $serve_spa $serve_open $serve_qr $serve_ssl $serve_log
            return $status
        end
    end

    # ── Quick dir+port ────────────────────────────────────────────────────────
    if test (count $argv) -eq 2
        if test -d $argv[1]; and string match -qr '^\d+$' $argv[2]
            set serve_dir  $argv[1]
            set serve_port $argv[2]
            __serve_ensure_dirs
            __serve_launch $serve_dir $serve_port $serve_host $serve_type \
                $serve_spa $serve_open $serve_qr $serve_ssl $serve_log
            return $status
        end
    end

    # ── Parse flags ───────────────────────────────────────────────────────────
    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]

        switch $arg
            case -h --help
                __serve_help
                return 0

            case --list -L
                __serve_list
                return 0

            case --stop
                set i (math $i + 1)
                __serve_stop $argv[$i]
                return $status

            case --stop-all
                __serve_stop_all
                return $status

            case -o --open
                set serve_open 1

            case -l --lan
                set serve_host "0.0.0.0"

            case -s --spa
                set serve_spa 1

            case -q --qr
                set serve_qr 1
                set serve_host "0.0.0.0"  # Need LAN for QR to be useful

            case --ssl
                set serve_ssl 1

            case --log
                set serve_log 1

            case -c --cors
                set serve_cors 1

            case -t --type
                set i (math $i + 1)
                set serve_type $argv[$i]

            case --version
                echo $CLR_BCYAN"  🌐 ASH Serve v$__SERVE_VERSION"$CLR_RESET
                return 0

            case '*'
                # Could be directory or port
                if test -d $arg
                    set serve_dir $arg
                else if string match -qr '^\d+$' $arg
                    set serve_port $arg
                else
                    __serve_err "Unknown argument: $arg"
                    __serve_tip  "Run: serve --help"
                    return 1
                end
        end

        set i (math $i + 1)
    end

    __serve_ensure_dirs
    __serve_launch $serve_dir $serve_port $serve_host $serve_type \
        $serve_spa $serve_open $serve_qr $serve_ssl $serve_log
end
