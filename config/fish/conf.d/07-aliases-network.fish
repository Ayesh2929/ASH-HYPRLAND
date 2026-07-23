#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗               ║
# ║  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝               ║
# ║  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝                ║
# ║  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗                ║
# ║  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗               ║
# ║  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝               ║
# ║                                                                                  ║
# ║   🌐 NETWORK ALIASES — ASH Dotfiles v5.0 OMEGA                                 ║
# ║   Connectivity • DNS • HTTP • SSH • VPN • Security • Monitoring                 ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_aliases_network_initialized && exit 0
set -g __ash_aliases_network_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌍 IP ADDRESS — Public & local
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Public IP — multiple fallbacks for reliability
alias pubip    "curl \
                  --silent \
                  --max-time 5 \
                  --fail \
                  'https://api.ipify.org?format=json' \
                | jq --raw-output '.ip'"

alias pubip4   "curl \
                  --silent \
                  --max-time 5 \
                  --fail \
                  'https://api4.ipify.org?format=json' \
                | jq --raw-output '.ip'"

alias pubip6   "curl \
                  --silent \
                  --max-time 5 \
                  --fail \
                  'https://api6.ipify.org?format=json' \
                | jq --raw-output '.ip'"

alias myip     "curl \
                  --silent \
                  --max-time 5 \
                  'https://ipinfo.io' \
                | jq '{ip,city,region,country,org,timezone}'"

alias geoip    "curl \
                  --silent \
                  --max-time 5 \
                  'https://ipinfo.io'"              # Full geo info

alias myipfast "curl \
                  --silent \
                  --max-time 3 \
                  ifconfig.me && echo"              # Fastest fallback

# Local IPs — Wayland-aware (no X11 deps)
alias localip  "ip \
                  --brief \
                  address \
                  show \
                  scope global"

alias localips "ip \
                  address \
                  show \
                  scope global \
                | grep 'inet ' \
                | awk '{print \$2}'"

alias iface    "ip \
                  --brief \
                  link \
                  show"                             # Network interfaces

alias ipall    "ip \
                  address \
                  show"                             # All IP addresses

alias iprt     "ip \
                  route \
                  show"                             # Routing table

alias iprt6    "ip \
                  -6 route \
                  show"                             # IPv6 routing table

alias gateway  "ip \
                  route \
                  show default \
                | awk '/default/ {print \$3}'"      # Default gateway

alias macaddr  "ip \
                  link \
                  show \
                | awk '/link\\/ether/ {print \$2}'"  # MAC addresses


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏓 PING & CONNECTIVITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq gping
    # gping: visual ping with graph
    alias ping     "gping"
    alias ping4    "gping \
                      --ipv4"
    alias ping6    "gping \
                      --ipv6"
    alias pingg    "gping \
                      google.com \
                      cloudflare.com \
                      1.1.1.1"                      # Ping multiple hosts
else
    alias ping     "ping \
                      --count=5 \
                      --interval=0.5"
    alias ping6    "ping6 \
                      --count=5"
    alias pingg    "ping \
                      --count=5 \
                      google.com"
end

alias pingcheck "ping \
                   --count=3 \
                   --quiet \
                   8.8.8.8 \
                 && echo '✅ Internet: OK' \
                 || echo '❌ Internet: OFFLINE'"

alias isonline  "pingcheck"
alias netcheck  "curl \
                   --silent \
                   --max-time 5 \
                   'https://www.google.com' \
                   > /dev/null \
                 && echo '✅ HTTP: Online' \
                 || echo '❌ HTTP: Offline'"

# MTR (traceroute + ping combined)
if command -sq mtr
    alias mtr      "mtr \
                      --report \
                      --report-cycles=5"
    alias mtrnc    "mtr \
                      --no-dns \
                      --report"                     # No DNS resolution
    alias mtrj     "mtr \
                      --json \
                      --report"                     # JSON output
end

# Traditional traceroute
alias tracert  "traceroute \
                  --icmp \
                  --max-hops=30"

# Network connectivity matrix
alias nettest  "echo '─── DNS ───' && \
                dig +short google.com @8.8.8.8 && \
                echo '─── HTTP ───' && \
                curl -so /dev/null -w '%{http_code}' https://google.com && echo && \
                echo '─── Latency ───' && \
                ping -c3 -q 8.8.8.8 | tail -1"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 DNS — Lookup, resolution, debugging
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq dog
    # dog: modern DNS client (like dig but better)
    alias dig      "dog"
    alias dns      "dog"
    alias dnsa     "dog \
                      --type A"
    alias dnsaaaa  "dog \
                      --type AAAA"
    alias dnsmx    "dog \
                      --type MX"
    alias dnstxt   "dog \
                      --type TXT"
    alias dnscname "dog \
                      --type CNAME"
    alias dnsns    "dog \
                      --type NS"
    alias dnssoa   "dog \
                      --type SOA"
    alias dnssrv   "dog \
                      --type SRV"
    alias dnsptr   "dog \
                      --type PTR"
    alias dnsrev   "dog \
                      --type PTR \
                      --edns-client-subnet=0.0.0.0/0"  # Reverse DNS
    alias dnsj     "dog \
                      --json \
                      | jq"                         # JSON output
    alias dnscf    "dog \
                      @1.1.1.1"                     # Query via Cloudflare
    alias dnsgoog  "dog \
                      @8.8.8.8"                     # Query via Google
    alias dnsdoh   "dog \
                      --https \
                      @https://cloudflare-dns.com/dns-query"  # DNS over HTTPS

else if command -sq drill
    alias dig      "drill"
    alias dns      "drill"
else
    # dig with sane defaults
    alias dig      "dig \
                      +short \
                      +answer"
    alias dns      "dig \
                      +short \
                      +answer"
end

# DNS resolution test (both IPv4 and IPv6)
alias dnstest  "echo '─── A Record ───' && \
                dig +short A google.com @1.1.1.1 && \
                echo '─── AAAA Record ───' && \
                dig +short AAAA google.com @1.1.1.1"

# Current DNS servers
alias dnsservers "cat /etc/resolv.conf \
                  | grep '^nameserver' \
                  | awk '{print \$2}'"

# DNS cache flush
alias dnsflush "sudo systemd-resolve \
                  --flush-caches && \
                echo '✓ DNS cache flushed'"

alias dnsstats "systemd-resolve \
                  --statistics"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔌 PORTS & SOCKETS — Listening, connections
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ss: modern netstat replacement
alias ports    "ss \
                  --tcp \
                  --udp \
                  --listening \
                  --numeric \
                  --processes"

alias ports4   "ss \
                  --tcp \
                  --udp \
                  --listening \
                  --numeric \
                  --processes \
                  --ipv4"

alias ports6   "ss \
                  --tcp \
                  --udp \
                  --listening \
                  --numeric \
                  --processes \
                  --ipv6"

alias portsp   "ss \
                  --tcp \
                  --listening \
                  --processes \
                  --numeric \
                | column --table"                   # Pretty formatted

alias conns    "ss \
                  --tcp \
                  --established \
                  --numeric \
                  --processes"                      # Active connections

alias connsall "ss \
                  --all \
                  --numeric \
                  --processes \
                  --extended"

alias tcpstates "ss \
                   --tcp \
                   --all \
                   --numeric \
                 | awk 'NR>1 {print \$1}' \
                 | sort \
                 | uniq -c \
                 | sort -rn"                        # TCP state distribution

alias lsof-net "lsof \
                  -i \
                  -n \
                  -P"                               # Network file descriptors

alias whoport  "ss \
                  --listening \
                  --numeric \
                  --processes \
                  src :\$argv[1] 2>/dev/null \
                || echo 'Usage: whoport <port>'"    # Who is using port

alias openports "nmap \
                   --open \
                   -sV \
                   localhost 2>/dev/null \
                 || ss --listening --numeric --processes"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 HTTP — curl, wget, httpie
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# curl with sensible defaults
alias curl     "curl \
                  --silent \
                  --show-error \
                  --location \
                  --retry 3 \
                  --retry-delay 2 \
                  --max-time 30"

alias curlv    "curl \
                  --verbose \
                  --location \
                  --retry 3"                        # Verbose curl

alias curlj    "curl \
                  --silent \
                  --show-error \
                  --location \
                  --header 'Accept: application/json' \
                | jq"                               # curl + JSON pretty-print

alias curlt    "curl \
                  --silent \
                  --output /dev/null \
                  --write-out '%{time_total}s'"     # Timing only

alias curlh    "curl \
                  --head \
                  --location \
                  --silent \
                  --show-error"                     # Headers only

alias curlcert "curl \
                  --verbose \
                  --head \
                  2>&1 \
                | grep 'SSL'"                       # SSL/TLS info

alias curldl   "curl \
                  --remote-name \
                  --location \
                  --progress-bar \
                  --continue-at -"                  # Download with resume

# HTTP timing breakdown
alias curltime "curl \
                  --silent \
                  --output /dev/null \
                  --write-out '
DNS lookup:        %{time_namelookup}s
TCP connect:       %{time_connect}s
TLS handshake:     %{time_appconnect}s
Server processing: %{time_pretransfer}s
TTFB:              %{time_starttransfer}s
─────────────────────────────────
Total:             %{time_total}s
HTTP status:       %{http_code}
Download size:     %{size_download} bytes
'"

# httpie (if installed)
if command -sq http
    alias get      "http \
                      --follow \
                      --pretty=all"
    alias post     "http \
                      POST \
                      --follow \
                      --pretty=all"
    alias httpj    "http \
                      --follow \
                      --print=b \
                      Accept:application/json"
end

# wget with sensible defaults
if command -sq wget
    alias wget     "wget \
                      --quiet \
                      --show-progress \
                      --progress=bar:force \
                      --continue"
    alias wgets    "wget \
                      --spider \
                      --quiet"                      # Check URL without downloading
end

# xh (httpie replacement in Rust)
if command -sq xh
    alias xh       "xh \
                      --follow"
    alias xhj      "xh \
                      --follow \
                      --header='Accept: application/json'"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔒 SSH — Secure shell & tunneling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias ssh      "ssh \
                  -o ServerAliveInterval=60 \
                  -o ServerAliveCountMax=3 \
                  -o ConnectTimeout=10"

alias sshv     "ssh \
                  -v \
                  -o ServerAliveInterval=60"        # Verbose SSH

alias sshnc    "ssh \
                  -o StrictHostKeyChecking=no \
                  -o UserKnownHostsFile=/dev/null"  # Skip host key check (labs only)

alias sshf     "ssh \
                  -f \
                  -N"                               # Background SSH (for tunnels)

# SSH tunnels
alias sshtun   "ssh \
                  -L"                               # Local port forward: sshtun 8080:host:80 user@server
alias sshrtunn "ssh \
                  -R"                               # Remote port forward
alias sshdyn   "ssh \
                  -D \
                  -f \
                  -N"                               # SOCKS5 proxy tunnel

# SSH key management
alias sshkeys  "ssh-add \
                  --list"
alias sshkeysa "ssh-add"
alias sshkeygen "ssh-keygen \
                   --type ed25519 \
                   --comment"
alias sshpub   "cat $HOME/.ssh/id_ed25519.pub \
                  2>/dev/null \
                || cat $HOME/.ssh/id_rsa.pub \
                  2>/dev/null"
alias sshcp    "ssh-copy-id \
                  --identity-file $HOME/.ssh/id_ed25519.pub"

# SSH config
alias sshconfig "bat $HOME/.ssh/config \
                   2>/dev/null \
                 || cat $HOME/.ssh/config"
alias sshconfigedit "nvim $HOME/.ssh/config"

# SSH known hosts
alias sshknown "bat $HOME/.ssh/known_hosts \
                  2>/dev/null"
alias sshrmhost "ssh-keygen \
                   --remove"                        # Remove host from known_hosts

# SCP / rsync alternatives
alias scp      "scp \
                  -r \
                  -C \
                  -P 22"

if command -sq rsync
    alias rsync    "rsync \
                      --archive \
                      --verbose \
                      --compress \
                      --progress \
                      --human-readable \
                      --partial"
    alias rsyncssh "rsync \
                      --archive \
                      --verbose \
                      --compress \
                      --progress \
                      --human-readable \
                      --partial \
                      --rsh=ssh"
    alias rsyncdry "rsync \
                      --archive \
                      --verbose \
                      --compress \
                      --dry-run"                    # Preview what would sync
end

# SSHFS (mount remote FS)
command -sq sshfs && begin
    alias sshfsmount "sshfs \
                        -o reconnect \
                        -o ServerAliveInterval=15 \
                        -o ServerAliveCountMax=3"
    alias sshfsumount "fusermount \
                         --unmount"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📶 WIFI — NetworkManager / iw
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq nmcli
    alias wifi      "nmcli \
                       device wifi"
    alias wifiscan  "nmcli \
                       device wifi list \
                       --rescan yes"
    alias wificonn  "nmcli \
                       device wifi connect"
    alias wifidisc  "nmcli \
                       device disconnect"
    alias wifistatus "nmcli \
                        --fields DEVICE,STATE,CONNECTION \
                        device status"
    alias wifishow  "nmcli \
                       connection show \
                       --active"
    alias wifipwd   "nmcli \
                       --show-secrets \
                       connection show"             # Show WiFi password
    alias netoff    "nmcli networking off"
    alias neton     "nmcli networking on"
    alias nmrestart "sudo systemctl restart NetworkManager \
                     && echo '✓ NetworkManager restarted'"

    # Hotspot
    alias hotspot   "nmcli device wifi hotspot \
                       con-name hotspot \
                       ssid 'ASH-Hotspot' \
                       band bg \
                       channel 6 \
                       password"

    # Connection management
    alias netls     "nmcli connection show"
    alias netup     "nmcli connection up"
    alias netdown   "nmcli connection down"
    alias netdel    "nmcli connection delete"
end

if command -sq iw
    alias iwscan    "sudo iw dev \
                       (ip link show | awk '/UP/ {print \$2}' | grep -v lo | head -1 | tr -d :) \
                       scan \
                     | grep SSID"
    alias iwinfo    "iw dev"
    alias iwlink    "iw dev \
                       (ip link show | awk '/state UP/ {print \$2}' | head -1 | tr -d :) \
                       link"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔵 BLUETOOTH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq bluetoothctl
    alias bt        "bluetoothctl"
    alias bton      "bluetoothctl power on && echo '✓ Bluetooth ON'"
    alias btoff     "bluetoothctl power off && echo '✓ Bluetooth OFF'"
    alias btscan    "bluetoothctl scan on"
    alias btpair    "bluetoothctl pair"
    alias btconn    "bluetoothctl connect"
    alias btdisc    "bluetoothctl disconnect"
    alias btls      "bluetoothctl paired-devices"
    alias btinfo    "bluetoothctl info"
    alias bttrust   "bluetoothctl trust"
    alias btremove  "bluetoothctl remove"
    alias btstatus  "bluetoothctl show \
                      | grep -E 'Name|Powered|Discoverable|Pairable'"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 VPN — WireGuard & OpenVPN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq wg
    alias wg-up     "sudo wg-quick up"
    alias wg-down   "sudo wg-quick down"
    alias wg-status "sudo wg show"
    alias wg-ls     "sudo wg show interfaces"
    alias wgconf    "bat /etc/wireguard/*.conf \
                      2>/dev/null"
end

# VPN via NetworkManager
command -sq nmcli && begin
    alias vpnls    "nmcli connection show \
                      --active \
                    | grep vpn"
    alias vpnup    "nmcli connection up"
    alias vpndown  "nmcli connection down"
    alias vpnstat  "nmcli \
                      --fields DEVICE,TYPE,STATE \
                      device status \
                    | grep vpn"
end

# Mullvad VPN
command -sq mullvad && begin
    alias mvpn     "mullvad"
    alias mvpnon   "mullvad connect"
    alias mvpnoff  "mullvad disconnect"
    alias mvpnst   "mullvad status"
    alias mvpnls   "mullvad relay list"
end

# Tailscale
command -sq tailscale && begin
    alias ts       "tailscale"
    alias tson     "tailscale up"
    alias tsoff    "tailscale down"
    alias tsstat   "tailscale status"
    alias tsping   "tailscale ping"
    alias tsip     "tailscale ip"
    alias tsnet    "tailscale netcheck"
end

# Check VPN status
alias vpncheck "curl \
                  --silent \
                  --max-time 5 \
                  'https://am.i.mullvad.net/json' \
                  2>/dev/null \
                | jq '{mullvad_exit_ip,country,city}' \
                || myip"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔥 FIREWALL — nftables / ufw / iptables
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq ufw
    alias fwstatus  "sudo ufw status verbose"
    alias fwrules   "sudo ufw status numbered"
    alias fwon      "sudo ufw enable"
    alias fwoff     "sudo ufw disable"
    alias fwallow   "sudo ufw allow"
    alias fwdeny    "sudo ufw deny"
    alias fwdel     "sudo ufw delete"
    alias fwreset   "sudo ufw reset"
    alias fwlog     "sudo ufw logging on"
    alias fwreload  "sudo ufw reload"

else if command -sq nft
    alias fwstatus  "sudo nft list ruleset"
    alias fwrules   "sudo nft list tables"
    alias fwflush   "sudo nft flush ruleset"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 BANDWIDTH & MONITORING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq bandwhich
    alias bw       "sudo bandwhich"                 # Bandwidth by process
    alias netmon   "sudo bandwhich \
                      --raw"                        # Raw bandwidth display
end

if command -sq nethogs
    alias nethogs  "sudo nethogs"
    alias netuse   "sudo nethogs \
                      -d 1"                         # 1-second refresh
end

if command -sq iftop
    alias iftop    "sudo iftop \
                      -n \
                      -N"                           # No DNS, no ports
end

if command -sq nload
    alias nload    "nload \
                      -u M \
                      -U M \
                      -t 500"                       # Megabit units
end

# speedtest
if command -sq speedtest-cli
    alias speed    "speedtest-cli \
                      --simple"
    alias speedj   "speedtest-cli \
                      --json \
                    | jq '{download,upload,ping,server}'"
else if command -sq speedtest
    alias speed    "speedtest"
end

# Network stats via ip
alias netstats "ip \
                  --statistics \
                  link"

alias rxrate   "cat /sys/class/net/*/statistics/rx_bytes \
                  2>/dev/null"
alias txrate   "cat /sys/class/net/*/statistics/tx_bytes \
                  2>/dev/null"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 SECURITY SCANNING — nmap, sslscan
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq nmap
    alias nmap     "nmap \
                      --reason"
    alias nmapscan "sudo nmap \
                      --sV \
                      --sC \
                      -O"                           # Full service/OS detection
    alias nmapfast "nmap \
                      --open \
                      -F"                           # Fast top-100 ports
    alias nmaplocal "sudo nmap \
                       --sn \
                       192.168.1.0/24"              # Ping scan local network
    alias nmapvuln "sudo nmap \
                      --script vuln"                # Vulnerability scan
    alias nmapudp  "sudo nmap \
                      --sU \
                      --top-ports 100"              # UDP scan top 100
    alias nmapall  "sudo nmap \
                      --sV \
                      --sC \
                      -p- \
                      --min-rate=5000"              # All ports scan
end

if command -sq sslscan
    alias sslcheck "sslscan \
                      --no-failed"
    alias ssltls   "sslscan \
                      --tlsall"                     # Full TLS check
end

# SSL certificate check via openssl
alias certcheck "echo | \
                 openssl s_client \
                   --connect \
                   --servername"
alias certexpiry "echo | \
                  openssl s_client \
                    --connect 2>/dev/null \
                  | openssl x509 \
                    --noout \
                    --dates"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖧  SERVERS — Quick local servers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Python HTTP server
alias serve    "python3 \
                  -m http.server \
                  8000 \
                  --bind 0.0.0.0 \
                  --directory ."
alias serve8   "python3 \
                  -m http.server"                   # Custom port: serve8 3000

# HTTPS with python (self-signed)
alias servehttps "python3 -c \"
import http.server, ssl, os
httpd = http.server.HTTPServer(('', 4443), http.server.SimpleHTTPRequestHandler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain('/tmp/cert.pem', '/tmp/key.pem')
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
print('HTTPS: https://localhost:4443')
httpd.serve_forever()
\""

# BusyBox httpd (very fast)
command -sq busybox && begin
    alias servefast "busybox httpd \
                       -f \
                       -p 8000"
end

# PHP development server
command -sq php && begin
    alias servephp "php \
                      -S \
                      localhost:8000"
end

# Ruby WEBrick
command -sq ruby && begin
    alias serveruby "ruby \
                       -run \
                       -e httpd \
                       . \
                       -p 8000"
end

# Node.js (npx serve)
command -sq npx && begin
    alias servenode "npx serve \
                       --listen 8000 \
                       --cors"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 WEB TOOLS — Misc HTTP utilities
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WHOIS
alias whois    "whois \
                  --no-recursion"

# Headers inspection
alias headers  "curl \
                  --head \
                  --silent \
                  --location \
                  --max-time 10"

# Redirect chain follower
alias redirects "curl \
                   --location \
                   --max-redirs 10 \
                   --write-out '%{url_effective}\n' \
                   --output /dev/null \
                   --silent"

# URL encode/decode
alias urlencode "python3 \
                   -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))'"
alias urldecode "python3 \
                   -c 'import sys,urllib.parse; print(urllib.parse.unquote(sys.argv[1]))'"

# JSON formatting
alias jsonpp   "python3 \
                  -m json.tool \
                  --indent 2"
command -sq jq && alias jqpp "jq '.'"

# Base64 encode/decode
alias b64e     "base64 \
                  --wrap=0"
alias b64d     "base64 \
                  --decode"

# QR code for URLs
command -sq qrencode && begin
    alias qr     "qrencode \
                    --type=ANSIUTF8 \
                    --level=H"
    alias qrfile "qrencode \
                    --type=PNG \
                    --output"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🕵️  PROXY — HTTP proxy management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias proxyon  "set -gx http_proxy  'http://127.0.0.1:8080' && \
                set -gx https_proxy 'http://127.0.0.1:8080' && \
                set -gx ftp_proxy   'http://127.0.0.1:8080' && \
                set -gx no_proxy    'localhost,127.0.0.1,::1' && \
                echo '✓ HTTP Proxy enabled (127.0.0.1:8080)'"

alias proxyoff "set -e http_proxy && \
                set -e https_proxy && \
                set -e ftp_proxy && \
                set -e no_proxy && \
                echo '✓ HTTP Proxy disabled'"

alias proxystat "echo \"http_proxy:  \$http_proxy\" && \
                 echo \"https_proxy: \$https_proxy\" && \
                 echo \"no_proxy:    \$no_proxy\""

# Tor proxy (requires tor service)
alias torproxy "set -gx http_proxy  'socks5://127.0.0.1:9050' && \
                set -gx https_proxy 'socks5://127.0.0.1:9050' && \
                echo '✓ Tor SOCKS5 proxy enabled'"

alias torcheck "curl \
                  --silent \
                  --proxy socks5://127.0.0.1:9050 \
                  'https://check.torproject.org/api/ip' \
                | jq"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🩺 NETWORK DIAGNOSTICS — All-in-one report
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias netreport "echo '
╔═══════════════════════════════════════════╗
║     🌐 ASH NETWORK DIAGNOSTIC REPORT     ║
╚═══════════════════════════════════════════╝

📍 Local Interfaces:' && \
ip --brief address && \
echo '\n🌍 Public IP:' && \
curl -s --max-time 3 ifconfig.me && echo && \
echo '\n🔌 Listening Ports:' && \
ss -tlnp | tail -n +2 | head -20 && \
echo '\n🏓 Ping (Google):' && \
ping -c 2 -q 8.8.8.8 | tail -1 && \
echo '\n🔍 DNS Resolution:' && \
dig +short google.com @1.1.1.1 2>/dev/null | head -3 && \
echo '\n🔒 VPN Status:' && \
(wg show 2>/dev/null | head -3 || nmcli -f TYPE,STATE device | grep vpn || echo 'No VPN detected') && \
echo"