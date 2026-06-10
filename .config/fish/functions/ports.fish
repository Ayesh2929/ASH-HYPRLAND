# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — PORTS FUNCTION                               ║
# ║           Show listening network ports                                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function ports -d "Show open/listening network ports"
    set -l c_header (set_color -o cyan)
    set -l c_port   (set_color -o green)
    set -l c_proc   (set_color yellow)
    set -l c_proto  (set_color magenta)
    set -l c_reset  (set_color normal)

    set -l filter "${argv[1]:-}"

    echo ""
    echo -s $c_header"  Listening Ports"$c_reset
    echo -s "  "(string repeat -n 50 "─")

    if command -q ss
        if test -n "$filter"
            ss -tulpn 2>/dev/null | grep -E "^(Netid|.*$filter)" | while read -l line
                # Format output
                set -l proto (echo $line | awk '{print $1}')
                set -l addr  (echo $line | awk '{print $5}')
                set -l proc  (echo $line | awk '{print $7}' | grep -oP '(?<=").*(?=")' || echo "?")
                printf "  $c_proto%-6s$c_reset $c_port%-30s$c_reset $c_proc%s$c_reset\n" \
                    "$proto" "$addr" "$proc"
            end
        else
            ss -tulpn 2>/dev/null | awk 'NR>1 {
                printf "  %-6s %-30s %s\n", $1, $5, $7
            }' | while read -l line
                echo "  $line"
            end
        end
    else if command -q netstat
        netstat -tulpn 2>/dev/null | grep LISTEN
    else
        echo "  Neither ss nor netstat available"
    end

    echo ""
end

complete -c ports -s h -l help -d "Show help"
complete -c ports -x -d "Filter by port/process name"