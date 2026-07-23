# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — stopwatch Ultra                                    ║
# ║  Precise stopwatch: laps, splits, history, export & rich display           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function stopwatch --description "Precise stopwatch with laps, splits & history"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╗

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
    # ║  📁 PATHS                                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _sw_history "$HOME/.local/share/ash/state/stopwatch-history.json"
    mkdir -p (dirname $_sw_history) 2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __sw_help --description "Print help"
        echo ""
        echo $BOLD$GREEN"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$GREEN"  ║     ⏱️   stopwatch — Precision Stopwatch              ║"$R
        echo $BOLD$GREEN"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  stopwatch [options]"
        echo ""
        echo "  $BOLD Controls (while running):$R"
        printf "    $CYAN%-14s$R  %s\n" \
            "Enter / L"    "Record a lap / split" \
            "Ctrl-C"       "Stop and show results" \
            "R"            "Reset lap counter" \
            "Q"            "Quit without saving"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-20s$R  %s\n" \
            "-l, --label <text>" "Name this stopwatch session" \
            "--laps"             "Start in lap mode (show splits)" \
            "--compact"          "Minimal one-line display" \
            "--no-save"          "Don't save to history" \
            "--history"          "Show past sessions" \
            "--export <file>"    "Export history to CSV" \
            "-h, --help"         "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "stopwatch                     # Simple stopwatch" \
            "stopwatch -l 'API benchmark'  # Named session" \
            "stopwatch --laps              # Lap mode" \
            "stopwatch --history           # View past sessions" \
            "stopwatch --export times.csv  # Export history"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _label   ""
    set -l _laps    0
    set -l _compact 0
    set -l _no_save 0
    set -l _mode    run    # run | history | export

    contains -- --help $argv; or contains -- -h $argv; and begin
        __sw_help; return 0
    end

    contains -- --history $argv; and set _mode history
    contains -- --export  $argv; and set _mode export

    for arg in $argv
        switch $arg
            case --laps;      set _laps    1
            case --compact;   set _compact 1
            case --no-save;   set _no_save 1
            case --history;   set _mode history
            case --export=*
                set _mode export
                set _export_file (string replace '--export=' '' $arg)
            case -l=* --label=*
                set _label (string replace -r '^-l=|^--label=' '' $arg)
            case -l --label
                # Next arg is label
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  UTILITY FUNCTIONS                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── High-resolution time (nanoseconds) ────────────────────────────────────
    function __sw_now --description "Get current time in milliseconds"
        set -l ns (date +%s%N 2>/dev/null)
        if test -n "$ns" && string match -qr '^\d{13,}$' $ns
            math --scale 0 "$ns / 1000000"
        else
            math (date +%s) \* 1000
        end
    end

    # ── Format milliseconds ────────────────────────────────────────────────────
    function __sw_format --description "Format ms to HH:MM:SS.mmm"
        set -l ms   $argv[1]
        set -l show_ms $argv[2]
        test -z "$show_ms" && set show_ms 1

        set -l h  (math --scale 0 "$ms / 3600000")
        set -l m  (math --scale 0 "($ms % 3600000) / 60000")
        set -l s  (math --scale 0 "($ms % 60000) / 1000")
        set -l ms_r (math "$ms % 1000")

        if test $show_ms -eq 1
            if test $h -gt 0
                printf "%d:%02d:%02d.%03d" $h $m $s $ms_r
            else
                printf "%02d:%02d.%03d" $m $s $ms_r
            end
        else
            if test $h -gt 0
                printf "%d:%02d:%02d" $h $m $s
            else
                printf "%02d:%02d" $m $s
            end
        end
    end

    # ── Format large display (bold digits) ────────────────────────────────────
    function __sw_big_display --description "Large time display"
        set -l ms $argv[1]
        set -l h  (math --scale 0 "$ms / 3600000")
        set -l m  (math --scale 0 "($ms % 3600000) / 60000")
        set -l s  (math --scale 0 "($ms % 60000) / 1000")
        set -l cs (math --scale 0 "($ms % 1000) / 10")

        if test $h -gt 0
            printf "$BOLD$GREEN%d:%02d:%02d$CYAN.%02d$R" $h $m $s $cs
        else
            printf "$BOLD$GREEN%02d:%02d$CYAN.%02d$R" $m $s $cs
        end
    end

    # ── Progress indicator (time-based animation) ─────────────────────────────
    function __sw_indicator --description "Animated running indicator"
        set -l ms $argv[1]
        set -l frames "◐" "◓" "◑" "◒"
        set -l idx (math $ms / 250 % 4 + 1)
        echo $frames[$idx]
    end

    # ── Lap delta display ──────────────────────────────────────────────────────
    function __sw_lap_row --description "Render a lap row"
        set -l lap_num  $argv[1]
        set -l lap_ms   $argv[2]   # lap split time
        set -l total_ms $argv[3]   # total elapsed at this lap
        set -l best_ms  $argv[4]   # best lap ms

        set -l lap_str   (__sw_format $lap_ms)
        set -l total_str (__sw_format $total_ms)

        # Color by comparison to best
        set -l lap_color $GREEN
        if test -n "$best_ms" && test $lap_ms -eq $best_ms
            set lap_color $CYAN
            set -l flag "$CYAN ← best$R"
        else if test -n "$best_ms" && test $lap_ms -gt (math $best_ms \* 1.2) 2>/dev/null
            set lap_color $RED
        else
            set -l flag ""
        end

        printf "  $DIM  Lap %-3s$R  $lap_color%-14s$R  $DIM(total: %-14s)$R%s\n" \
            $lap_num $lap_str $total_str $flag
    end

    # ── Save to history ────────────────────────────────────────────────────────
    function __sw_save_history --description "Save session to history"
        set -l total_ms  $argv[1]
        set -l label     $argv[2]
        set -l laps_json $argv[3]
        test -z "$laps_json" && set laps_json "[]"

        command -q jq || return 0

        set -l ts  (date -u +%Y-%m-%dT%H:%M:%SZ)
        set -l entry (printf \
            '{"ts":"%s","label":"%s","total_ms":%d,"total_fmt":"%s","laps":%s}' \
            $ts "$label" $total_ms (__sw_format $total_ms) "$laps_json")

        if test -f $_sw_history
            jq --argjson e "$entry" \
                '[ $e ] + . | .[0:100]' \
                $_sw_history > /tmp/sw-hist-tmp.json 2>/dev/null && \
                mv /tmp/sw-hist-tmp.json $_sw_history
        else
            printf '[%s]\n' "$entry" > $_sw_history 2>/dev/null
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📜 HISTORY MODE                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$_mode" = history
        printf "\n  $BOLD$GREEN  ⏱️  Stopwatch History$R\n\n"

        if not test -f $_sw_history
            printf "  $DIM  No history yet — run stopwatch to record sessions$R\n\n"
            return 0
        end

        printf "  $BOLD$GREEN%-22s  %-25s  %-10s  %s$R\n" \
            "DATE/TIME" "LABEL" "DURATION" "LAPS"
        printf "  $DIM%s$R\n" (string repeat -n 65 "─")

        command -q jq && \
            jq -r '.[] | "\(.ts | .[0:16])\t\(.label // "—")\t\(.total_fmt)\t\((.laps // []) | length)"' \
                $_sw_history 2>/dev/null | \
            while read -l line
                set -l parts (string split \t $line)
                printf "  $CYAN%-22s$R  $DIM%-25s$R  $GREEN%-10s$R  $DIM%s laps$R\n" \
                    $parts[1] \
                    (string sub --length 25 $parts[2]) \
                    $parts[3] $parts[4]
            end

        printf "\n"
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📤 EXPORT MODE                                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$_mode" = export
        set -l out (test -n "$_export_file" && echo $_export_file || echo "stopwatch-export.csv")

        if not test -f $_sw_history
            printf "  $RED✗$R  No history to export\n\n"
            return 1
        end

        printf "timestamp,label,total_ms,total_formatted,lap_count\n" > $out

        command -q jq && \
            jq -r '.[] | [.ts, (.label // ""), .total_ms, .total_fmt, ((.laps // []) | length)] | @csv' \
                $_sw_history 2>/dev/null >> $out

        printf "  $GREEN✓$R  Exported to: $CYAN%s$R\n\n" $out
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⏱️  MAIN STOPWATCH ENGINE                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _start_ms  (__sw_now)
    set -l _lap_start $_start_ms
    set -l _laps_data  # Array of "lap_ms:total_ms"
    set -l _lap_count  0
    set -l _best_lap   ""
    set -l _session_label (test -n "$_label" && echo "$_label" || echo "Stopwatch")

    # ── Banner ─────────────────────────────────────────────────────────────────
    printf "\n"
    printf "  $BOLD$GREEN╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$GREEN║  ⏱️   %-50s║$R\n" \
        "$_session_label"
    printf "  $BOLD$GREEN║  %-52s║$R\n" \
        "  Started: $(date '+%H:%M:%S')  ·  $(test $_laps -eq 1 && echo 'Lap mode' || echo 'Press Enter for lap')"
    printf "  $BOLD$GREEN╚══════════════════════════════════════════════════════╝$R\n\n"

    if test $_compact -eq 0
        printf "  $DIM  Controls: Enter=lap  Ctrl-C=stop  Q=quit$R\n\n"
        printf "  $DIM  Time display area:$R\n"
        printf "\n\n\n"  # Reserve space for display
    end

    # ── Signal handler ────────────────────────────────────────────────────────
    set -g _sw_running 1

    function __sw_on_sigint --on-signal SIGINT
        set -g _sw_running 0
    end

    # ── Input polling function ─────────────────────────────────────────────────
    function __sw_check_input --description "Non-blocking input check"
        # Use read with timeout
        if read -t 0 -n 1 _key 2>/dev/null
            switch $_key
                case q Q
                    set -g _sw_running 0
                    set -g _sw_quit 1
                case l L r R '' \n
                    set -g _sw_lap_triggered 1
            end
        end
    end

    # ── Main loop ──────────────────────────────────────────────────────────────
    set -g _sw_lap_triggered 0
    set -g _sw_quit          0

    # Put terminal in raw mode for single-key input
    if command -q stty
        stty -echo -icanon min 0 time 0 2>/dev/null
    end

    while test $_sw_running -eq 1
        set -l now_ms   (__sw_now)
        set -l total_ms (math $now_ms - $_start_ms)
        set -l lap_ms   (math $now_ms - $_lap_start)

        # ── Check for keypress (non-blocking) ─────────────────────────────────
        if read -t 0.05 -n 1 _input_key 2>/dev/null
            switch $_input_key
                case q Q
                    set _sw_running 0
                    set _sw_quit    1
                    break
                case l L r R '' \n \r
                    set _sw_lap_triggered 1
            end
        end

        # ── Handle lap trigger ────────────────────────────────────────────────
        if test $_sw_lap_triggered -eq 1
            set _sw_lap_triggered 0
            set _lap_count (math $_lap_count + 1)

            # Best lap tracking
            if test -z "$_best_lap" || test $lap_ms -lt $_best_lap
                set _best_lap $lap_ms
            end

            set --append _laps_data "$lap_ms:$total_ms"

            # Render lap
            if test $_compact -eq 0
                printf "\r  $CYAN  Lap %d  $GREEN%s  $DIM(total: %s)$R\n" \
                    $_lap_count \
                    (__sw_format $lap_ms) \
                    (__sw_format $total_ms)
            end

            set _lap_start $now_ms
        end

        # ── Render time display ────────────────────────────────────────────────
        if test $_compact -eq 1
            set -l indicator (__sw_indicator $total_ms)
            printf "\r  $indicator  %s  $DIM(lap %d: %s)$R  " \
                (__sw_big_display $total_ms) \
                $_lap_count \
                (__sw_format $lap_ms)
        else
            # Move up to reserved display area
            printf "\033[4A"  # Move up 4 lines

            set -l indicator (__sw_indicator $total_ms)

            printf "  $indicator  %s%s\n" \
                (__sw_big_display $total_ms) \
                (string repeat -n 5 " ")

            printf "\n"

            # Lap info
            if test $_lap_count -gt 0
                printf "  $DIM  Laps: %-3d  Best: %-14s  Last: %s$R%s\n" \
                    $_lap_count \
                    (__sw_format $_best_lap) \
                    (__sw_format (echo $_laps_data[-1] | cut -d: -f1)) \
                    (string repeat -n 5 " ")
            else
                printf "  $DIM  Press Enter to record a lap$R%s\n" \
                    (string repeat -n 20 " ")
            end

            printf "\n"
        end
    end

    # Restore terminal
    command -q stty && stty echo icanon 2>/dev/null

    functions --erase __sw_on_sigint 2>/dev/null

    # ── Final stop time ───────────────────────────────────────────────────────
    set -l _stop_ms  (__sw_now)
    set -l _total_ms (math _stop_ms - $_start_ms)

    # ── Results display ────────────────────────────────────────────────────────
    printf "\n\n"
    printf "  $BOLD$GREEN╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$GREEN║  ⏱️   Results: %-43s║$R\n" \
        (string sub --length 43 "$_session_label")
    printf "  $BOLD$GREEN╠══════════════════════════════════════════════════════╣$R\n"
    printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  $GREEN%s$R%s$GREEN║$R\n" \
        "Total time:" (__sw_format $_total_ms) \
        (string repeat -n (math 38 - (string length (__sw_format $_total_ms))) " ")
    printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  $CYAN%s$R%s$GREEN║$R\n" \
        "Laps:" \
        $_lap_count \
        (string repeat -n (math 38 - (string length $_lap_count)) " ")
    printf "  $BOLD$GREEN╚══════════════════════════════════════════════════════╝$R\n\n"

    # ── Show laps ──────────────────────────────────────────────────────────────
    if test $_lap_count -gt 0
        printf "  $BOLD$CYAN  Lap Breakdown:$R\n\n"
        printf "  $BOLD$CYAN  %-5s  %-16s  %-16s  %s$R\n" \
            "LAP" "SPLIT" "TOTAL" "NOTE"
        printf "  $DIM%s$R\n" (string repeat -n 55 "─")

        set -l i 1
        for entry in $_laps_data
            set -l lap_ms   (echo $entry | cut -d: -f1)
            set -l total_ms (echo $entry | cut -d: -f2)

            # Highlight best/worst
            set -l note ""
            set -l color $GREEN
            if test "$lap_ms" = "$_best_lap"
                set note $CYAN"← best"$R
                set color $CYAN
            end

            # Find worst lap
            set -l worst_ms $_laps_data[1]
            for e in $_laps_data
                set -l m (echo $e | cut -d: -f1)
                test $m -gt $worst_ms 2>/dev/null && set worst_ms $m
            end
            test "$lap_ms" = "$worst_ms" && test $_lap_count -gt 1 && begin
                set note $RED"← slow"$R
                set color $RED
            end

            printf "  $DIM  %-5s$R  $color%-16s$R  $DIM%-16s$R  %s\n" \
                "#$i" (__sw_format $lap_ms) (__sw_format $total_ms) $note
            set i (math $i + 1)
        end

        # Statistics
        if test $_lap_count -gt 1
            set -l total_lap_ms 0
            for entry in $_laps_data
                set -l m (echo $entry | cut -d: -f1)
                set total_lap_ms (math $total_lap_ms + $m)
            end
            set -l avg_ms (math --scale 0 "$total_lap_ms / $_lap_count")

            printf "\n  $DIM%s$R\n" (string repeat -n 55 "─")
            printf "  $DIM  Best:    %-14s$R\n" (__sw_format $_best_lap)
            printf "  $DIM  Average: %-14s$R\n" (__sw_format $avg_ms)
            printf "  $DIM  Worst:   %-14s$R\n" (__sw_format $worst_ms)
        end
        printf "\n"
    end

    # ── Save to history ────────────────────────────────────────────────────────
    if test $_no_save -eq 0 && test $_sw_quit -eq 0 && test $_total_ms -gt 1000
        set -l laps_json "[]"

        if test $_lap_count -gt 0 && command -q jq
            set -l entries
            for entry in $_laps_data
                set -l m (echo $entry | cut -d: -f1)
                set -l t (echo $entry | cut -d: -f2)
                set --append entries (printf '{"ms":%d,"fmt":"%s","total_ms":%d}' \
                    $m (__sw_format $m) $t)
            end
            set laps_json "["(string join ',' $entries)"]"
        end

        __sw_save_history $_total_ms "$_session_label" "$laps_json"
        printf "  $DIM  Stopwatch session saved to history$R\n\n"
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __sw_help __sw_now __sw_format __sw_big_display \
        __sw_indicator __sw_lap_row __sw_save_history \
        __sw_on_sigint __sw_check_input 2>/dev/null
    set --erase _sw_running _sw_quit _sw_lap_triggered 2>/dev/null

end
