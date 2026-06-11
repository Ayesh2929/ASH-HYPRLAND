# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — PORTS FUNCTION                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function ports -d "Show listening network ports"
    set -l c_header (set_color -o 89b4fa)
    set -l c_port   (set_color a6e3a1)
    set -l c_proc   (set_color f9e2af)
    set -l c_reset  (set_color normal)
    set -l filter   $argv[1]

    echo ""
    echo -s $c_header"  Listening Ports"$c_reset
    echo "  ─────────────────────────────────────────"

    if command -q ss
        if test -n "$filter"
            ss -tulpn 2>/dev/null | grep -E "^(Netid|.*$filter)" | awk '
                NR==1 { printf "  %-8s %-30s %s\n", $1, $5, "Process"; next }
                { printf "  %-8s %-30s %s\n", $1, $5, $7 }
            '
        else
            ss -tulpn 2>/dev/null | awk '
                NR==1 { printf "  %-8s %-30s %s\n", $1, $5, "Process"; next }
                { printf "  %-8s %-30s %s\n", $1, $5, $7 }
            '
        end
    else if command -q netstat
        netstat -tulpn 2>/dev/null | grep LISTEN
    else
        echo "  ss or netstat not found"
    end
    echo ""
end

complete -c ports -x -d "Filter string (port number or process)"