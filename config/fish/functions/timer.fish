# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — timer Ultra                                        ║
# ║  Feature-rich countdown timer: Pomodoro, presets, notifications & visuals  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function timer --description "Countdown timer with Pomodoro, presets & notifications"

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
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╗

    function __timer_help --description "Print help"
        echo ""
        echo $BOLD$ORANGE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$ORANGE"  ║     ⏱️   timer — Countdown Timer                      ║"$R
        echo $BOLD$ORANGE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  timer <duration> [options]"
        echo ""
        echo "  $BOLD Duration formats:$R"
        printf "    $CYAN%-16s$R  %s\n" \
            "25m"       "25 minutes" \
            "90s"       "90 seconds" \
            "1h30m"     "1 hour 30 minutes" \
            "1h30m45s"  "1 hour 30 minutes 45 seconds" \
            "25"        "25 minutes (default unit)"
        echo ""
        echo "  $BOLD Presets:$R"
        printf "    $CYAN%-16s$R  %s\n" \
            "pomodoro"  "25m focus + 5m break cycle" \
            "short"     "5 minutes" \
            "long"      "15 minutes" \
            "focus"     "50 minutes" \
            "break"     "10 minutes" \
            "lunch"     "30 minutes" \
            "hour"      "60 minutes"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-20s$R  %s\n" \
            "-l, --label <text>"  "Custom label for the timer" \
            "-n, --notify"        "Send desktop notification on end" \
            "--sound"             "Play sound on completion" \
            "--no-bar"            "Disable progress bar" \
            "--compact"           "Minimal one-line output" \
            "-h, --help"          "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "timer 25m                    # 25 minute countdown" \
            "timer 1h30m                  # 1.5 hour timer" \
            "timer pomodoro               # Pomodoro cycle" \
            "timer 90s --label 'API test' # Labeled timer" \
            "timer 5m --notify            # With notification"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _duration ""
    set -l _label    ""
    set -l _notify   0
    set -l _sound    0
    set -l _no_bar   0
    set -l _compact  0
    set -l _pomodoro 0
    set -l _total_secs 0

    if test (count $argv) -eq 0
        __timer_help; return 0
    end

    contains -- --help $argv; or contains -- -h $argv; and begin
        __timer_help; return 0
    end

    # First arg: duration or preset
    set _duration $argv[1]
    set argv $argv[2..-1]

    for arg in $argv
        switch $arg
            case -l --label
                set _label $argv[(math (contains -i -- $arg $argv) + 1)]
            case -l=* --label=*
                set _label (string replace -r '^-l=|^--label=' '' $arg)
            case -n --notify;   set _notify  1
            case --sound;       set _sound   1
            case --no-bar;      set _no_bar  1
            case --compact;     set _compact 1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🕐 DURATION PARSER                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __timer_parse_duration --description "Parse duration string to seconds"
        set -l input $argv[1]
        set -l total 0

        # Preset shortcuts
        switch $input
            case pomodoro pomo pm;  set _pomodoro 1; echo 1500; return
            case short s;           echo 300;  return
            case long l;            echo 900;  return
            case focus f;           echo 3000; return
            case break br;          echo 600;  return
            case lunch lunch-break; echo 1800; return
            case hour h 1h;         echo 3600; return
        end

        # Parse h/m/s format
        for match in (string match -ra '\d+[hHmMsS]' $input)
            set -l num (string match -r '^\d+' $match)
            set -l unit (string lower (string replace -r '^\d+' '' $match))

            switch $unit
                case h; set total (math $total + ($num * 3600))
                case m; set total (math $total + ($num * 60))
                case s; set total (math $total + $num)
            end
        end

        # Pure number = minutes
        if test $total -eq 0 && string match -qr '^\d+$' $input
            set total (math $input \* 60)
        end

        echo $total
    end

    set _total_secs (__timer_parse_duration "$_duration")

    if test _total_secs -le 0
        printf "  $RED✗$R  Invalid duration: '$_duration'\n"
        printf "  $DIM  Examples: 25m  1h30m  90s  pomodoro$R\n\n"
        return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  UTILITY FUNCTIONS                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __timer_format --description "Format seconds as HH:MM:SS or MM:SS"
        set -l secs $argv[1]
        set -l h (math --scale 0 "$secs / 3600")
        set -l m (math --scale 0 "($secs % 3600) / 60")
        set -l s (math --scale 0 "$secs % 60")

        if test $h -gt 0
            printf "%d:%02d:%02d" $h $m $s
        else
            printf "%02d:%02d" $m $s
        end
    end

    function __timer_progress_bar --description "Render animated progress bar"
        set -l elapsed  $argv[1]
        set -l total    $argv[2]
        set -l width    $argv[3]
        test -z "$width" && set width 35

        set -l pct    (math --scale 2 "$elapsed * 100 / $total")
        set -l filled (math --scale 0 "$elapsed * $width / $total")
        set -l empty  (math $width - $filled)

        # Color: green → yellow → orange → red
        set -l bar_color $GREEN
        test $pct -gt 50 && set bar_color $CYAN
        test $pct -gt 75 && set bar_color $YELLOW
        test $pct -gt 90 && set bar_color $ORANGE
        test $pct -gt 97 && set bar_color $RED

        set -l bar (string repeat -n $filled "█")
        set -l emp (string repeat -n $empty  "░")

        printf "%s%s%s%s  %s%5.1f%%%s" \
            $bar_color $bar $DIM $emp $bar_color $pct $R
    end

    function __timer_notify --description "Send desktop notification"
        set -l title $argv[1]
        set -l body  $argv[2]

        if command -q notify-send
            notify-send \
                --app-name="ASH Timer" \
                --icon="alarm-clock" \
                --urgency=critical \
                "$title" "$body" 2>/dev/null
        else if command -q terminal-notifier
            terminal-notifier -title "$title" -message "$body" 2>/dev/null
        else if command -q osascript
            osascript -e "display notification \"$body\" with title \"$title\"" 2>/dev/null
        end
    end

    function __timer_sound --description "Play completion sound"
        if command -q paplay
            paplay "$HOME/.local/share/ash/sounds/pomodoro-end.ogg" 2>/dev/null || \
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null
        else if command -q aplay
            aplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null
        else if command -q afplay
            afplay /System/Library/Sounds/Glass.aiff 2>/dev/null
        else
            # ASCII bell
            printf '\a'
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🍅 POMODORO MODE                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __timer_pomodoro --description "Run a full Pomodoro cycle"
        set -l round 0
        set -l total_rounds 4

        while true
            set round (math $round + 1)

            # ── Focus session ───────────────────────────────────────────────
            printf "\n  $BOLD$RED🍅 Pomodoro #%d/$total_rounds — Focus (25:00)$R\n\n" $round
            __timer_run 1500 "🍅 Focus #$round"

            __timer_sound
            __timer_notify "🍅 Pomodoro Complete!" "Focus session #$round done. Take a break!"

            printf "\n  $BOLD$GREEN  Focus complete!$R\n\n"

            # ── Break ────────────────────────────────────────────────────────
            if test $round -eq $total_rounds
                printf "  $BOLD$PURPLE  🎉 All %d Pomodoros complete! Take a long break (15-30 min)$R\n\n" $total_rounds
                __timer_run 900 "☕ Long Break"
                __timer_notify "☕ Long Break Over!" "Ready for a new Pomodoro set?"
                break
            else
                printf "  $BOLD$CYAN  ☕ Short Break (5:00)$R\n\n"
                __timer_run 300 "☕ Short Break"
                __timer_notify "⏱️ Break Over!" "Round $(math $round + 1) starting..."
            end

            read -P "  Continue to Pomodoro #$(math $round + 1)? [Y/n] " cont
            string match -qi 'n*' $cont && break
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⏱️  CORE TIMER ENGINE                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __timer_run --description "Run the countdown timer"
        set -l total   $argv[1]
        set -l label   $argv[2]
        test -z "$label" && set label "Timer"

        set -l end_ts  (math (date +%s) + $total)
        set -l start   (date +%s)

        # Large digit display (compact ASCII art for time)
        function __digits --description "Get time in HH:MM:SS"
            __timer_format $argv[1]
        end

        # Compact mode
        if test $_compact -eq 1
            while true
                set -l now     (date +%s)
                set -l remaining (math $end_ts - $now)
                test $remaining -le 0 && break

                set -l elapsed (math $now - $start)
                set -l time_str (__digits $remaining)

                if test $_no_bar -eq 0
                    set -l bar (__timer_progress_bar $elapsed $total 25)
                    printf "\r  $ORANGE⏱$R  $BOLD%-14s$R  %s  %s" \
                        "$label" $time_str $bar
                else
                    printf "\r  $ORANGE⏱$R  $BOLD%-14s$R  $YELLOW%s$R" \
                        "$label" $time_str
                end

                sleep 1
            end
            printf "\r  $GREEN✓$R  $BOLD%-14s$R  Done!%s\n" \
                "$label" (string repeat -n 30 " ")
            return 0
        end

        # ── Full display ───────────────────────────────────────────────────────
        printf "  $BOLD$ORANGE  Label: %s$R\n" $label
        printf "  $BOLD  Duration: %s$R\n\n" (__timer_format $total)
        printf "  $DIM  Ctrl-C to cancel$R\n\n"

        set -l _spin_frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
        set -l _spin_idx 1

        # Handle Ctrl-C gracefully
        function __timer_sigint --on-signal SIGINT
            printf "\n\n  $YELLOW⚠$R  Timer cancelled\n\n"
            functions --erase __timer_sigint
            return 130
        end

        while true
            set -l now       (date +%s)
            set -l remaining (math $end_ts - $now)

            test $remaining -le 0 && break

            set -l elapsed  (math $now - $start)
            set -l time_str (__digits $remaining)

            # Spinner frame
            set -l spin $_spin_frames[$_spin_idx]
            set _spin_idx (math ($_spin_idx % (count $_spin_frames)) + 1)

            # Color for remaining time
            set -l time_color $GREEN
            set -l pct (math --scale 0 "$elapsed * 100 / $total")
            test $pct -gt 50 && set time_color $CYAN
            test $pct -gt 75 && set time_color $YELLOW
            test $pct -gt 90 && set time_color $ORANGE
            test $pct -gt 97 && set time_color $RED

            # Clear and redraw
            printf "\033[5A" 2>/dev/null  # Move up 5 lines

            printf "  $DIM%s$R  $time_color$BOLD%s$R%s\n" \
                $spin $time_str (string repeat -n 10 " ")
            printf "\n"

            if test $_no_bar -eq 0
                printf "  %s\n" (__timer_progress_bar $elapsed $total 40)
                printf "\n"
            end

            printf "  $DIM  Elapsed: %-12s$R\n" (__timer_format $elapsed)

            sleep 1
        end

        functions --erase __timer_sigint 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  HEADER & LAUNCH                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _display_label (test -n "$_label" && echo "$_label" || echo "Timer")
    set -l _time_str (__timer_format $_total_secs)

    printf "\n"
    printf "  $BOLD$ORANGE╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$ORANGE║  ⏱️   %-50s║$R\n" \
        "$_display_label — $_time_str"
    printf "  $BOLD$ORANGE║  %-52s║$R\n" \
        "  Started: $(date '+%H:%M:%S')  ·  Ends: $(date -d "+$_total_secs seconds" '+%H:%M:%S' 2>/dev/null)"
    printf "  $BOLD$ORANGE╚══════════════════════════════════════════════════════╝$R\n"
    printf "\n\n\n\n\n"  # Reserve lines for display

    # ── Run Pomodoro cycle ────────────────────────────────────────────────────
    if test $_pomodoro -eq 1
        __timer_pomodoro
    else
        __timer_run $_total_secs "$_display_label"
    end

    # ── Completion ────────────────────────────────────────────────────────────
    set -l _elapsed_real (math (date +%s) - (date -d "-$_total_secs seconds" +%s 2>/dev/null; or echo 0))

    printf "\n\n"
    printf "  $BOLD$GREEN╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$GREEN║  ✅  Timer Complete!                                  ║$R\n"
    printf "  $BOLD$GREEN║  %-52s║$R\n" \
        "  $_display_label  ·  Duration: $_time_str"
    printf "  $BOLD$GREEN╚══════════════════════════════════════════════════════╝$R\n\n"

    # Notification
    if test $_notify -eq 1; or set -q ASH_TIMER_NOTIFY
        __timer_notify "⏱️ Timer Done!" "$_display_label ($_time_str)"
    end

    # Sound
    if test $_sound -eq 1; or set -q ASH_TIMER_SOUND
        __timer_sound
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __timer_help __timer_parse_duration __timer_format \
        __timer_progress_bar __timer_notify __timer_sound \
        __timer_pomodoro __timer_run __digits 2>/dev/null
    set --erase _spin_frames _spin_idx 2>/dev/null

end
