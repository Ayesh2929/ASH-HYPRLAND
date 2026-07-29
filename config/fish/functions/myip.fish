#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌍 MYIP.FISH — Ultra IP Information System                                 ║
# ║  ASH Dotfiles v5.0 OMEGA • Ultra-Grade Function                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   myip                        — Show all IP info (default)
#   myip -p / --public          — Public IP only
#   myip -l / --local           — Local IPs only
#   myip -f / --full            — Full detailed report
#   myip -g / --geo             — Geolocation info
#   myip -d / --dns             — DNS info
#   myip -v / --vpn             — VPN/proxy detection
#   myip -6 / --ipv6            — IPv6 info
#   myip -c / --copy            — Copy public IP to clipboard
#   myip -j / --json            — Raw JSON output
#   myip -w / --watch           — Watch mode (refresh every 30s)
#   myip -q / --qr              — QR code of public IP
#   myip --interfaces           — All network interfaces
#   myip --route                — Routing table
#   myip --check <ip>           — Lookup specific IP
#   myip --history              — IP change history
#   myip --speed                — Quick ping test

# ─── Constants ────────────────────────────────────────────────────────────────

set -l __MYIP_VERSION    "5.0.0"
set -l __MYIP_CACHE_DIR  "$HOME/.cache/ash/myip"
set -l __MYIP_CACHE_TTL  300  # 5 minutes
set -l __MYIP_TIMEOUT    6
set -l __MYIP_HISTORY    "$HOME/.cache/ash/myip/ip-history.log"

# IP providers (tried in order for redundancy)
set -l __MYIP_PROVIDERS \
    "https://api.ipify.org?format=json" \
    "https://api.my-ip.io/ip.json" \
    "https://icanhazip.com" \
    "https://checkip.amazonaws.com" \
    "https://ifconfig.me/ip"

# Geo provider
set -l __MYIP_GEO_URL "https://ipwho.is"

# ─── Color Palette ─────────────────────────────────────────────────────────────

set -l CLR_RESET    (set_color normal)
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

function __myip_ok   -a msg; echo $CLR_BGREEN"  ✅  $msg"$CLR_RESET; end
function __myip_err  -a msg; echo $CLR_BRED"  ❌  $msg"$CLR_RESET >&2; end
function __myip_warn -a msg; echo $CLR_BYELLOW"  ⚠️   $msg"$CLR_RESET; end
function __myip_tip  -a msg; echo $CLR_BCYAN"  💡  $msg"$CLR_RESET; end
function __myip_info -a msg; echo $CLR_BBLUE"  ℹ️   $msg"$CLR_RESET; end
function __myip_dim  -a msg; echo $CLR_DIM"       $msg"$CLR_RESET; end

function __myip_field -a label -a value -a color
    printf "  $CLR_DIM%-22s$CLR_RESET $color%s$CLR_RESET\n" "$label" "$value"
end

function __myip_separator
    echo $CLR_BBLUE"  ─────────────────────────────────────────────────"$CLR_RESET
end

# ─── Ensure Cache Dir ─────────────────────────────────────────────────────────

function __myip_ensure_dirs
    test -d $__MYIP_CACHE_DIR; or mkdir -p $__MYIP_CACHE_DIR
end

# ─── Cache Helpers ────────────────────────────────────────────────────────────

function __myip_cache_get -a key
    set -l cache_file "$__MYIP_CACHE_DIR/$key.cache"
    if not test -f $cache_file
        return 1
    end

    set -l now (date +%s)
    set -l mtime (stat -c %Y $cache_file 2>/dev/null; or stat -f %m $cache_file 2>/dev/null)
    if test -z "$mtime"
        return 1
    end

    set -l age (math $now - $mtime)
    if test $age -gt $__MYIP_CACHE_TTL
        rm -f $cache_file
        return 1
    end

    cat $cache_file
    return 0
end

function __myip_cache_set -a key -a value
    __myip_ensure_dirs
    echo $value > "$__MYIP_CACHE_DIR/$key.cache"
end

# ─── HTTP Fetch ───────────────────────────────────────────────────────────────

function __myip_fetch -a url
    if not command -q curl
        __myip_err "curl required"
        return 1
    end
    curl -s --max-time $__MYIP_TIMEOUT \
        --user-agent "ash-dotfiles/5.0 (myip)" \
        "$url"
    return $status
end

# ─── Extract Public IP ────────────────────────────────────────────────────────

function __myip_get_public
    # Check cache first
    set -l cached (__myip_cache_get "public_ip")
    if test $status -eq 0 -a -n "$cached"
        echo $cached
        return 0
    end

    # Try each provider
    for provider in $__MYIP_PROVIDERS
        set -l result (__myip_fetch $provider 2>/dev/null)
        if test $status -ne 0 -o -z "$result"
            continue
        end

        # Extract IP from JSON or plain text
        set -l ip ""
        if string match -q "*{*" $result
            # JSON response
            set ip (echo $result | python3 -c \
                "import sys,json; d=json.load(sys.stdin); print(d.get('ip', d.get('query','')))" \
                2>/dev/null)
        else
            # Plain text response
            set ip (string trim $result)
        end

        # Validate it looks like an IP
        if string match -qr '^(\d{1,3}\.){3}\d{1,3}$' $ip
            __myip_cache_set "public_ip" $ip
            echo $ip
            return 0
        end
    end

    return 1
end

# ─── Get Public IPv6 ──────────────────────────────────────────────────────────

function __myip_get_public_v6
    set -l cached (__myip_cache_get "public_ipv6")
    if test $status -eq 0 -a -n "$cached"
        echo $cached
        return 0
    end

    set -l result (__myip_fetch "https://api6.ipify.org?format=json" 2>/dev/null)
    if test $status -ne 0
        return 1
    end

    set -l ip (echo $result | python3 -c \
        "import sys,json; print(json.load(sys.stdin).get('ip',''))" 2>/dev/null)

    if test -n "$ip"
        __myip_cache_set "public_ipv6" $ip
        echo $ip
        return 0
    end
    return 1
end

# ─── Get Geo Info ─────────────────────────────────────────────────────────────

function __myip_get_geo -a ip
    if test -z "$ip"
        set ip (__myip_get_public)
    end

    set -l cache_key "geo_$ip"
    set -l cached (__myip_cache_get $cache_key)
    if test $status -eq 0 -a -n "$cached"
        echo $cached
        return 0
    end

    set -l result (__myip_fetch "$__MYIP_GEO_URL/$ip")
    if test $status -ne 0 -o -z "$result"
        return 1
    end

    __myip_cache_set $cache_key $result
    echo $result
    return 0
end

# ─── Get Local IPs ────────────────────────────────────────────────────────────

function __myip_get_local
    set -l ips

    if command -q ip
        set ips (ip -4 addr show 2>/dev/null | \
            grep -oP '(?<=inet\s)\d+(\.\d+){3}' | \
            grep -v '^127\.')
    else if command -q ifconfig
        set ips (ifconfig 2>/dev/null | \
            grep -oP '(?<=inet\s)\d+(\.\d+){3}' | \
            grep -v '^127\.')
    end

    echo $ips
end

# ─── Get Interface Details ────────────────────────────────────────────────────

function __myip_get_interfaces
    if not command -q ip
        __myip_err "ip command not found (install iproute2)"
        return 1
    end

    ip -4 addr show 2>/dev/null
end

# ─── Flag IP as VPN/Proxy ─────────────────────────────────────────────────────

function __myip_vpn_check -a ip -a geo_json
    # Simple heuristic checks for VPN/proxy detection

    set -l flags

    # Check if WireGuard interface exists
    if command -q ip
        if ip link show 2>/dev/null | grep -q 'wg[0-9]'
            set -a flags "WireGuard"
        end

        if ip link show 2>/dev/null | grep -q 'tun[0-9]\|tap[0-9]'
            set -a flags "VPN tunnel"
        end
    end

    # Check from geo JSON
    if test -n "$geo_json"
        set -l org (echo $geo_json | python3 -c \
            "import sys,json; d=json.load(sys.stdin); print(d.get('connection',{}).get('org',''))" \
            2>/dev/null | string lower)

        set -l vpn_keywords vpn proxy hosting datacenter cloud digitalocean linode vultr ovh aws amazon azure google
        for kw in $vpn_keywords
            if string match -q "*$kw*" $org
                set -a flags "Hosting/VPN ISP ($org)"
                break
            end
        end
    end

    if test (count $flags) -eq 0
        echo "None detected"
    else
        string join ", " $flags
    end
end

# ─── Display: Default View ────────────────────────────────────────────────────

function __myip_display_default
    echo ""
    echo $CLR_BBLUE"  ╔═══════════════════════════════════════════════════╗"$CLR_RESET
    echo $CLR_BBLUE"  ║  "$CLR_BCYAN"🌍  ASH myip — Network Information Report  "$CLR_BBLUE"     ║"$CLR_RESET
    echo $CLR_BBLUE"  ╚═══════════════════════════════════════════════════╝"$CLR_RESET
    echo ""

    # ── Public IP ─────────────────────────────────────────────────────────────
    echo $CLR_BYELLOW"  🌐 PUBLIC IP"$CLR_RESET
    __myip_separator

    set -l pub_ip (__myip_get_public)
    if test $status -eq 0 -a -n "$pub_ip"
        __myip_field "IPv4:" $pub_ip $CLR_BGREEN
    else
        __myip_field "IPv4:" "Failed to fetch" $CLR_BRED
    end

    # Try IPv6
    set -l pub_ipv6 (__myip_get_public_v6 2>/dev/null)
    if test -n "$pub_ipv6"
        __myip_field "IPv6:" $pub_ipv6 $CLR_BCYAN
    end

    echo ""

    # ── Local IPs ─────────────────────────────────────────────────────────────
    echo $CLR_BYELLOW"  🏠 LOCAL NETWORK"$CLR_RESET
    __myip_separator

    set -l local_ips (__myip_get_local)
    if test (count $local_ips) -gt 0
        for ip in $local_ips
            __myip_field "Local IPv4:" $ip $CLR_BMAGENTA
        end
    else
        __myip_field "Local IPv4:" "Not found" $CLR_DIM
    end

    __myip_field "Loopback:" "127.0.0.1 / ::1" $CLR_DIM

    echo ""

    # ── Geo Info ──────────────────────────────────────────────────────────────
    echo $CLR_BYELLOW"  📍 LOCATION"$CLR_RESET
    __myip_separator

    if test -n "$pub_ip"
        set -l geo (__myip_get_geo $pub_ip)
        if test $status -eq 0 -a -n "$geo"
            set -l city    (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('city','?'))" 2>/dev/null)
            set -l region  (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('region','?'))" 2>/dev/null)
            set -l country (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('country','?'))" 2>/dev/null)
            set -l country_code (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('country_code',''))" 2>/dev/null)
            set -l lat     (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('latitude','?'))" 2>/dev/null)
            set -l lon     (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('longitude','?'))" 2>/dev/null)
            set -l tz      (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('timezone',{}).get('id','?'))" 2>/dev/null)
            set -l isp     (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('connection',{}).get('isp','?'))" 2>/dev/null)
            set -l org     (echo $geo | python3 -c "import sys,json; print(json.load(sys.stdin).get('connection',{}).get('org','?'))" 2>/dev/null)

            __myip_field "City:"        $city                $CLR_WHITE
            __myip_field "Region:"      $region              $CLR_WHITE
            __myip_field "Country:"     "$country ($country_code)" $CLR_WHITE
            __myip_field "Coordinates:" "$lat°, $lon°"  $CLR_DIM
            __myip_field "Timezone:"    $tz                  $CLR_BCYAN
            __myip_field "ISP:"         $isp                 $CLR_DIM
            __myip_field "Org:"         $org                 $CLR_DIM
        else
            __myip_dim "Geolocation unavailable (check internet)"
        end
    end

    echo ""

    # ── VPN Check ─────────────────────────────────────────────────────────────
    echo $CLR_BYELLOW"  🛡️  PRIVACY"$CLR_RESET
    __myip_separator

    # Check VPN interfaces
    set -l vpn_info ""
    if command -q ip
        set -l wg (ip link show 2>/dev/null | grep 'wg[0-9]' | head -1)
        set -l tun (ip link show 2>/dev/null | grep 'tun[0-9]\|tap[0-9]' | head -1)

        if test -n "$wg"
            __myip_field "WireGuard:" "🟢 Active" $CLR_BGREEN
        else
            __myip_field "WireGuard:" "⚫ Inactive" $CLR_DIM
        end

        if test -n "$tun"
            __myip_field "VPN Tunnel:" "🟢 Active ($tun)" $CLR_BGREEN
        else
            __myip_field "VPN Tunnel:" "⚫ Inactive" $CLR_DIM
        end
    end

    # Check DNS leaks (compare DNS vs IP geo)
    set -l dns_servers (cat /etc/resolv.conf 2>/dev/null | grep '^nameserver' | awk '{print $2}')
    if test (count $dns_servers) -gt 0
        __myip_field "DNS Servers:" (string join ", " $dns_servers) $CLR_BYELLOW
    end

    echo ""

    # ── Hostname ──────────────────────────────────────────────────────────────
    echo $CLR_BYELLOW"  💻 SYSTEM"$CLR_RESET
    __myip_separator

    __myip_field "Hostname:"    (hostname)                              $CLR_WHITE
    __myip_field "Default GW:"  (ip route 2>/dev/null | grep default | awk '{print $3}' | head -1) $CLR_DIM
    __myip_field "Updated:"     (date '+%Y-%m-%d %H:%M:%S')            $CLR_DIM

    echo ""
    echo $CLR_DIM"  💡 Run 'myip --full' for detailed report | 'myip -c' to copy IP"$CLR_RESET
    echo ""
end

# ─── Display: Public Only ─────────────────────────────────────────────────────

function __myip_display_public
    set -l ip (__myip_get_public)
    if test $status -eq 0 -a -n "$ip"
        echo $ip
    else
        __myip_err "Could not determine public IP"
        return 1
    end
end

# ─── Display: Local Only ──────────────────────────────────────────────────────

function __myip_display_local
    set -l ips (__myip_get_local)
    if test (count $ips) -gt 0
        for ip in $ips
            echo $ip
        end
    else
        __myip_err "No local IPs found"
        return 1
    end
end

# ─── Display: Full Report ─────────────────────────────────────────────────────

function __myip_display_full
    set -l pub_ip (__myip_get_public)
    set -l geo    (__myip_get_geo $pub_ip 2>/dev/null)

    echo ""
    echo $CLR_BBLUE"  ╔═══════════════════════════════════════════════════════╗"$CLR_RESET
    echo $CLR_BBLUE"  ║  "$CLR_BCYAN"🌍  ASH myip — Full Network Report                "$CLR_BBLUE"║"$CLR_RESET
    echo $CLR_BBLUE"  ╚═══════════════════════════════════════════════════════╝"$CLR_RESET
    echo ""

    # Public IPs
    echo $CLR_BYELLOW"  🌐 PUBLIC ADDRESSES"$CLR_RESET
    __myip_separator
    __myip_field "IPv4 Public:"  (test -n "$pub_ip"; and echo $pub_ip; or echo "N/A") $CLR_BGREEN
    __myip_field "IPv6 Public:"  (__myip_get_public_v6 2>/dev/null; or echo "N/A")   $CLR_BCYAN
    echo ""

    # Local interfaces
    echo $CLR_BYELLOW"  🏠 LOCAL INTERFACES"$CLR_RESET
    __myip_separator

    if command -q ip
        ip -4 addr show 2>/dev/null | while read -l line
            if string match -q '*<*>*' $line
                set -l iface (echo $line | awk '{print $2}' | string replace -r ':$' '')
                printf "  $CLR_BYELLOW%-15s$CLR_RESET\n" $iface
            else if string match -q '    inet *' $line
                set -l addr (echo $line | awk '{print $2}')
                printf "    $CLR_DIM%-10s$CLR_RESET $CLR_BMAGENTA%s$CLR_RESET\n" "inet:" $addr
            end
        end
    end
    echo ""

    # Full geo
    echo $CLR_BYELLOW"  📍 FULL GEOLOCATION"$CLR_RESET
    __myip_separator

    if test -n "$geo"
        echo $geo | python3 -c "
import sys, json
data = json.load(sys.stdin)
fields = [
    ('ip',              'IP Address'),
    ('city',            'City'),
    ('region',          'Region'),
    ('region_code',     'Region Code'),
    ('country',         'Country'),
    ('country_code',    'Country Code'),
    ('postal',          'Postal Code'),
    ('latitude',        'Latitude'),
    ('longitude',       'Longitude'),
    ('calling_code',    'Calling Code'),
    ('capital',         'Capital'),
    ('borders',         'Borders'),
    ('flag',            'Flag Emoji'),
]
for key, label in fields:
    val = data.get(key, '')
    if val:
        print(f'  \033[90m{label:<20}\033[0m \033[97m{val}\033[0m')

tz = data.get('timezone', {})
if tz:
    print(f'  \033[90m{\"Timezone\":<20}\033[0m \033[96m{tz.get(\"id\",\"?\")}\033[0m')
    print(f'  \033[90m{\"UTC Offset\":<20}\033[0m \033[96m{tz.get(\"utc\",\"?\")}\033[0m')
    print(f'  \033[90m{\"Current Time\":<20}\033[0m \033[96m{tz.get(\"current_time\",\"?\")}\033[0m')

conn = data.get('connection', {})
if conn:
    print(f'  \033[90m{\"ASN\":<20}\033[0m \033[90m{conn.get(\"asn\",\"?\")}\033[0m')
    print(f'  \033[90m{\"ISP\":<20}\033[0m \033[90m{conn.get(\"isp\",\"?\")}\033[0m')
    print(f'  \033[90m{\"Organization\":<20}\033[0m \033[90m{conn.get(\"org\",\"?\")}\033[0m')
" 2>/dev/null
    end

    echo ""

    # Routing
    echo $CLR_BYELLOW"  🛣️  ROUTING"$CLR_RESET
    __myip_separator
    if command -q ip
        ip route 2>/dev/null | while read -l line
            echo $CLR_DIM"  $line"$CLR_RESET
        end
    end

    echo ""

    # DNS
    echo $CLR_BYELLOW"  🔍 DNS CONFIGURATION"$CLR_RESET
    __myip_separator
    if test -f /etc/resolv.conf
        cat /etc/resolv.conf | grep -v '^#' | grep -v '^$' | while read -l line
            echo $CLR_DIM"  $line"$CLR_RESET
        end
    end

    echo ""
end

# ─── Display: JSON ────────────────────────────────────────────────────────────

function __myip_display_json
    set -l pub_ip (__myip_get_public)
    set -l geo    (__myip_get_geo $pub_ip 2>/dev/null)

    if test -n "$geo"
        echo $geo | python3 -m json.tool 2>/dev/null; or echo $geo
    else
        echo '{"error": "Could not fetch IP info"}'
    end
end

# ─── Display: Interfaces ──────────────────────────────────────────────────────

function __myip_display_interfaces
    echo ""
    echo $CLR_BYELLOW"  🔌 Network Interfaces"$CLR_RESET
    __myip_separator
    echo ""

    if not command -q ip
        __myip_err "ip command required"
        return 1
    end

    ip -4 addr show 2>/dev/null | while read -l line
        if string match -q '*: *: <*' $line
            set -l iface (echo $line | awk '{print $2}' | string replace -r ':$' '')
            set -l state (echo $line | grep -oP '(?<=state )\w+')
            set -l mtu   (echo $line | grep -oP '(?<=mtu )\d+')

            set -l state_color (test "$state" = "UP"; and echo $CLR_BGREEN; or echo $CLR_DIM)

            printf "\n  $CLR_BYELLOW%-18s$CLR_RESET $state_color%-8s$CLR_RESET MTU: $CLR_DIM%s$CLR_RESET\n" \
                $iface $state $mtu

        else if string match -q '    inet *' $line
            set -l addr  (echo $line | awk '{print $2}')
            set -l bcast (echo $line | awk '{print $4}')
            printf "    $CLR_DIM%-10s$CLR_RESET $CLR_BMAGENTA%-20s$CLR_RESET $CLR_DIM%s$CLR_RESET\n" \
                "inet:" $addr $bcast

        else if string match -q '    link/*' $line
            set -l mac (echo $line | awk '{print $2}')
            printf "    $CLR_DIM%-10s$CLR_RESET $CLR_DIM%s$CLR_RESET\n" "MAC:" $mac
        end
    end
    echo ""
end

# ─── Display: Routing Table ───────────────────────────────────────────────────

function __myip_display_route
    echo ""
    echo $CLR_BYELLOW"  🛣️  Routing Table"$CLR_RESET
    __myip_separator
    echo ""

    if command -q ip
        ip route 2>/dev/null | while read -l line
            echo "  $CLR_DIM$line$CLR_RESET"
        end
    else if command -q netstat
        netstat -rn 2>/dev/null | while read -l line
            echo "  $CLR_DIM$line$CLR_RESET"
        end
    else
        __myip_err "No routing tool found"
    end
    echo ""
end

# ─── Check Specific IP ────────────────────────────────────────────────────────

function __myip_check -a ip
    if test -z "$ip"
        __myip_err "IP required: myip --check <ip>"
        return 1
    end

    echo ""
    echo $CLR_BBLUE"  🔍 IP Lookup: $ip"$CLR_RESET
    __myip_separator
    echo ""

    set -l geo (__myip_get_geo $ip)
    if test $status -eq 0 -a -n "$geo"
        echo $geo | python3 -c "
import sys, json
data = json.load(sys.stdin)
print_fields = [
    ('ip',        'IP Address',   '\033[92m'),
    ('city',      'City',         '\033[97m'),
    ('region',    'Region',       '\033[97m'),
    ('country',   'Country',      '\033[97m'),
    ('latitude',  'Latitude',     '\033[90m'),
    ('longitude', 'Longitude',    '\033[90m'),
    ('flag',      'Flag',         '\033[97m'),
]
for key, label, color in print_fields:
    val = data.get(key, '')
    if val:
        print(f'  \033[90m{label:<20}\033[0m {color}{val}\033[0m')

tz = data.get('timezone', {})
if tz:
    print(f'  \033[90m{\"Timezone\":<20}\033[0m \033[96m{tz.get(\"id\",\"?\")}\033[0m')
conn = data.get('connection', {})
if conn:
    print(f'  \033[90m{\"ISP\":<20}\033[0m \033[90m{conn.get(\"isp\",\"?\")}\033[0m')
    print(f'  \033[90m{\"ASN\":<20}\033[0m \033[90m{conn.get(\"asn\",\"?\")}\033[0m')
" 2>/dev/null
    else
        __myip_err "Could not fetch info for: $ip"
    end
    echo ""
end

# ─── Copy to Clipboard ────────────────────────────────────────────────────────

function __myip_copy
    set -l ip (__myip_get_public)
    if test -z "$ip"
        __myip_err "Could not get public IP"
        return 1
    end

    if command -q wl-copy
        echo $ip | wl-copy
        __myip_ok "Copied to Wayland clipboard: $ip"
    else if command -q xclip
        echo $ip | xclip -selection clipboard
        __myip_ok "Copied to X11 clipboard: $ip"
    else if command -q xsel
        echo $ip | xsel --clipboard --input
        __myip_ok "Copied to clipboard: $ip"
    else
        echo $ip
        __myip_warn "No clipboard tool. Printed above."
    end
end

# ─── QR Code ─────────────────────────────────────────────────────────────────

function __myip_qr
    set -l ip (__myip_get_public)
    if test -z "$ip"
        __myip_err "Could not get public IP"
        return 1
    end

    echo ""
    echo $CLR_BBLUE"  📱 Public IP QR Code: $ip"$CLR_RESET
    echo ""

    if command -q qrencode
        qrencode -t ANSIUTF8 $ip
    else if command -q python3
        python3 -c "
import urllib.parse
ip = '$ip'
url = f'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={urllib.parse.quote(ip)}'
print(f'  QR URL: {url}')
" 2>/dev/null
        __myip_tip "Install qrencode: paru -S qrencode"
    else
        echo $CLR_BCYAN"  $ip"$CLR_RESET
        __myip_tip "Install qrencode for QR display"
    end
    echo ""
end

# ─── IP History ───────────────────────────────────────────────────────────────

function __myip_history
    echo ""
    echo $CLR_BYELLOW"  📜 IP Change History"$CLR_RESET
    __myip_separator
    echo ""

    __myip_ensure_dirs

    if not test -f $__MYIP_HISTORY
        __myip_dim "No history yet"
        __myip_dim "(IPs are logged automatically on each myip run)"
        echo ""
        return 0
    end

    # Show last 20 entries
    tail -20 $__MYIP_HISTORY | while read -l line
        echo "  $CLR_DIM$line$CLR_RESET"
    end
    echo ""
end

# ─── Speed/Ping Test ──────────────────────────────────────────────────────────

function __myip_speed
    echo ""
    echo $CLR_BYELLOW"  ⚡ Network Ping Test"$CLR_RESET
    __myip_separator
    echo ""

    set -l hosts \
        "1.1.1.1:Cloudflare" \
        "8.8.8.8:Google" \
        "9.9.9.9:Quad9" \
        "208.67.222.222:OpenDNS"

    for entry in $hosts
        set -l host  (string split ':' $entry)[1]
        set -l label (string split ':' $entry)[2]

        if command -q ping
            set -l result (ping -c 3 -W 3 $host 2>/dev/null | \
                grep 'avg' | grep -oP '[\d.]+/[\d.]+/[\d.]+/[\d.]+')
            if test -n "$result"
                set -l avg (echo $result | cut -d/ -f2)
                printf "  $CLR_DIM%-15s$CLR_RESET $CLR_BGREEN%-15s$CLR_RESET $CLR_BCYAN%s ms (avg)$CLR_RESET\n" \
                    "$label" $host $avg
            else
                printf "  $CLR_DIM%-15s$CLR_RESET $CLR_DIM%-15s$CLR_RESET $CLR_BRED%s$CLR_RESET\n" \
                    "$label" $host "Timeout"
            end
        end
    end
    echo ""
end

# ─── Watch Mode ───────────────────────────────────────────────────────────────

function __myip_watch
    set -l interval 30
    echo ""
    __myip_info "Watch mode — refreshing every "$interval"s (Ctrl+C to stop)"
    echo ""

    while true
        clear
        myip
        echo $CLR_DIM"  Refreshing in "$interval"s... (Ctrl+C to stop)"$CLR_RESET
        sleep $interval
    end
end

# ─── Log IP ───────────────────────────────────────────────────────────────────

function __myip_log_ip -a ip
    if test -z "$ip"
        return 0
    end

    __myip_ensure_dirs

    # Log if IP changed
    set -l last_ip ""
    if test -f $__MYIP_HISTORY
        set last_ip (tail -1 $__MYIP_HISTORY | awk '{print $1}')
    end

    if test "$ip" != "$last_ip"
        echo "$ip  "(date '+%Y-%m-%d %H:%M:%S')"  change" >> $__MYIP_HISTORY
    end
end

# ─── Help ─────────────────────────────────────────────────────────────────────

function __myip_help
    echo ""
    echo $CLR_BBLUE"╔═══════════════════════════════════════════════════╗"$CLR_RESET
    echo $CLR_BBLUE"║  "$CLR_BCYAN"🌍  ASH myip v$__MYIP_VERSION — IP Info Ultra       "$CLR_BBLUE"║"$CLR_RESET
    echo $CLR_BBLUE"╚═══════════════════════════════════════════════════╝"$CLR_RESET
    echo ""
    echo $CLR_BYELLOW"  USAGE"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────"$CLR_RESET
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip" "Full IP report (default)"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -p / --public" "Public IP only"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -l / --local" "Local IPs only"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -f / --full" "Detailed full report"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -g / --geo" "Geolocation info"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -j / --json" "Raw JSON output"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -c / --copy" "Copy public IP to clipboard"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -q / --qr" "QR code of public IP"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip -w / --watch" "Auto-refresh mode"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip --interfaces" "All network interfaces"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip --route" "Routing table"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip --check <ip>" "Lookup specific IP"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip --history" "IP change history"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "myip --speed" "Ping test"
    echo ""
    echo $CLR_BYELLOW"  EXAMPLES"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────"$CLR_RESET
    echo $CLR_DIM"  myip                          # Full summary"$CLR_RESET
    echo $CLR_DIM"  myip -p                       # Just the IP"$CLR_RESET
    echo $CLR_DIM"  myip -c                       # Copy to clipboard"$CLR_RESET
    echo $CLR_DIM"  myip --check 8.8.8.8          # Lookup Google DNS"$CLR_RESET
    echo $CLR_DIM"  myip --full                   # Everything"$CLR_RESET
    echo ""
end

# ═══════════════════════════════════════════════════════════════════════════════
# ─── MAIN FUNCTION ─────────────────────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════

function myip
    # ── No args → default view ─────────────────────────────────────────────────
    if test (count $argv) -eq 0
        __myip_display_default
        # Log the IP silently
        __myip_log_ip (__myip_cache_get "public_ip" 2>/dev/null) &
        return 0
    end

    # ── Parse flags ───────────────────────────────────────────────────────────
    switch $argv[1]

        case -h --help
            __myip_help

        case -p --public
            __myip_display_public

        case -l --local
            __myip_display_local

        case -f --full
            __myip_display_full

        case -g --geo
            set -l ip (__myip_get_public)
            __myip_check $ip

        case -j --json
            __myip_display_json

        case -c --copy
            __myip_copy

        case -q --qr
            __myip_qr

        case -6 --ipv6
            set -l v6 (__myip_get_public_v6)
            if test $status -eq 0 -a -n "$v6"
                echo $v6
            else
                __myip_warn "No IPv6 address found"
                return 1
            end

        case -w --watch
            __myip_watch

        case --interfaces
            __myip_display_interfaces

        case --route
            __myip_display_route

        case --check
            if test (count $argv) -lt 2
                __myip_err "Usage: myip --check <ip>"
                return 1
            end
            __myip_check $argv[2]

        case --history
            __myip_history

        case --speed
            __myip_speed

        case --flush-cache
            rm -f $__MYIP_CACHE_DIR/*.cache
            __myip_ok "Cache flushed"

        case --version
            echo $CLR_BCYAN"  🌍 ASH myip v$__MYIP_VERSION"$CLR_RESET

        case '*'
            # Could be an IP address to check
            if string match -qr '^(\d{1,3}\.){3}\d{1,3}$' $argv[1]
                __myip_check $argv[1]
            else
                __myip_err "Unknown option: $argv[1]"
                __myip_tip  "Run: myip --help"
                return 1
            end
    end
end
