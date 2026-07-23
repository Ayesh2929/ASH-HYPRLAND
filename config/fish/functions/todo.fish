# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — todo Ultra                                         ║
# ║  Feature-rich todo list: priorities, projects, due dates & rich display    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function todo --description "Feature-rich terminal todo list manager"

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
    # ║  📁 PATHS & CONSTANTS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╗

    set -l _todo_file  "$HOME/.local/share/ash/todos.json"
    set -l _done_file  "$HOME/.local/share/ash/done.json"
    set -l _ts_iso     (date -u +%Y-%m-%dT%H:%M:%SZ)
    set -l _today      (date +%Y-%m-%d)

    mkdir -p (dirname $_todo_file) 2>/dev/null

    # Initialize empty files
    if not test -f $_todo_file
        echo '[]' > $_todo_file
    end
    if not test -f $_done_file
        echo '[]' > $_done_file
    end

    # ── Require jq ────────────────────────────────────────────────────────────
    if not command -q jq
        printf "  $RED✗$R  jq required: pacman -S jq  /  apt install jq\n"
        return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __todo_help --description "Print help"
        echo ""
        echo $BOLD$YELLOW"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$YELLOW"  ║     ✅  todo — Terminal Task Manager                 ║"$R
        echo $BOLD$YELLOW"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  todo [command] [options]"
        echo ""
        echo "  $BOLD Commands:$R"
        printf "    $CYAN%-24s$R  %s\n" \
            "(none) / ls"      "List pending todos" \
            "add <text>"       "Add a new todo" \
            "done <id>"        "Mark as complete" \
            "undone <id>"      "Reopen a completed todo" \
            "edit <id> <text>" "Edit todo text" \
            "delete <id>"      "Delete a todo" \
            "clear"            "Remove all completed" \
            "pick"             "Interactive fzf picker" \
            "all"              "Show all (pending + done)" \
            "done-list"        "List completed todos" \
            "project <name>"   "Filter by project" \
            "due [date]"       "Show/filter by due date" \
            "overdue"          "Show overdue todos" \
            "stats"            "Task statistics"
        echo ""
        echo "  $BOLD Options (for add):$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "-p, --priority <1-3>" "Priority: 1=high 2=med 3=low" \
            "-d, --due <date>"     "Due date (YYYY-MM-DD or 'tomorrow')" \
            "-P, --project <name>" "Project name" \
            "-t, --tag <tag>"      "Add tag"
        echo ""
        echo "  $BOLD Priority:$R"
        printf "    $RED%-5s$R  %s\n"    "!1"  "High priority"
        printf "    $YELLOW%-5s$R  %s\n" "!2"  "Medium priority (default)"
        printf "    $DIM%-5s$R  %s\n"    "!3"  "Low priority"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "todo                              # List pending" \
            "todo add 'Fix auth bug' -p 1      # High priority" \
            "todo add 'Deploy app' -d tomorrow # With due date" \
            "todo add 'Write tests' -P backend # In project" \
            "todo done 3                       # Complete #3" \
            "todo edit 5 'Updated task text'   # Edit #5" \
            "todo pick                         # Interactive" \
            "todo overdue                      # Past due tasks" \
            "todo stats                        # Statistics"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _cmd      ls
    set -l _text     ""
    set -l _priority 2
    set -l _due      ""
    set -l _project  ""
    set -l _tag      ""
    set -l _id       ""

    if test (count $argv) -eq 0
        set _cmd ls
    else
        switch $argv[1]
            case add a '+';          set _cmd add;       set argv $argv[2..-1]
            case done check tick;    set _cmd done;      set argv $argv[2..-1]
            case undone reopen;      set _cmd undone;    set argv $argv[2..-1]
            case delete rm del;      set _cmd delete;    set argv $argv[2..-1]
            case edit update;        set _cmd edit;      set argv $argv[2..-1]
            case clear purge;        set _cmd clear;     set argv $argv[2..-1]
            case pick interactive;   set _cmd pick;      set argv $argv[2..-1]
            case all show-all;       set _cmd all;       set argv $argv[2..-1]
            case done-list completed; set _cmd done-list; set argv $argv[2..-1]
            case project proj;       set _cmd project;   set argv $argv[2..-1]
            case due;                set _cmd due;       set argv $argv[2..-1]
            case overdue late;       set _cmd overdue;   set argv $argv[2..-1]
            case stats;              set _cmd stats;     set argv $argv[2..-1]
            case ls list show;       set _cmd ls;        set argv $argv[2..-1]
            case --help -h help;     __todo_help; return 0
            case '*'
                # Treat as 'add' if it doesn't look like a command
                set _cmd add
        end
    end

    # Parse options
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case -p --priority
                set _i (math $_i + 1); set _priority $argv[$_i]
            case -p=* --priority=*
                set _priority (string replace -r '^-p=|^--priority=' '' $arg)
            case -d --due
                set _i (math $_i + 1); set _due $argv[$_i]
            case -P --project
                set _i (math $_i + 1); set _project $argv[$_i]
            case -t --tag
                set _i (math $_i + 1); set _tag $argv[$_i]
            case '*'
                if test -z "$_id" && string match -qr '^\d+$' $arg
                    set _id $arg
                else
                    set _text (string join ' ' (test -n "$_text" && echo $_text) $arg)
                end
        end
        set _i (math $_i + 1)
    end

    # Parse priority from text (!1 !2 !3)
    if string match -qr '!([123])' "$_text"
        set _priority (string match -r '!([123])' "$_text" | tail -1)
        set _text (string replace -r '!([123])\s*' '' "$_text" | string trim)
    end

    # Normalize due date shortcuts
    switch $_due
        case today;     set _due $_today
        case tomorrow;  set _due (date -d 'tomorrow' +%Y-%m-%d 2>/dev/null; \
                            or date -v +1d +%Y-%m-%d 2>/dev/null; \
                            or echo "")
        case 'next week'
            set _due (date -d 'next week' +%Y-%m-%d 2>/dev/null; \
                or date -v +7d +%Y-%m-%d 2>/dev/null; or echo "")
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  HELPER FUNCTIONS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╗

    # ── Next available ID ──────────────────────────────────────────────────────
    function __todo_next_id --description "Get next todo ID"
        set -l max_todo (jq '[.[].id] | max // 0' $_todo_file 2>/dev/null; or echo 0)
        set -l max_done (jq '[.[].id] | max // 0' $_done_file 2>/dev/null; or echo 0)
        math (math "max($max_todo, $max_done)") + 1
    end

    # ── Priority icon & color ──────────────────────────────────────────────────
    function __todo_prio_icon --description "Priority display"
        set -l p $argv[1]
        switch $p
            case 1; echo "$RED❗$R"
            case 2; echo "$YELLOW●$R"
            case 3; echo "$DIM○$R"
            case '*'; echo "$DIM●$R"
        end
    end

    function __todo_prio_color --description "Priority color"
        set -l p $argv[1]
        switch $p
            case 1; set_color red
            case 2; set_color yellow
            case 3; set_color brblack
            case '*'; set_color normal
        end
    end

    # ── Due date display ───────────────────────────────────────────────────────
    function __todo_due_display --description "Format due date with color"
        set -l due $argv[1]
        test -z "$due" && return

        if test "$due" = "$_today"
            printf " $YELLOW[due today]$R"
        else if test "$due" < $_today
            printf " $RED[overdue: $due]$R"
        else
            printf " $DIM[due: $due]$R"
        end
    end

    # ── Render todo row ────────────────────────────────────────────────────────
    function __todo_row --description "Render a single todo row"
        set -l todo_json $argv[1]

        set -l id      (echo $todo_json | jq -r '.id')
        set -l text    (echo $todo_json | jq -r '.text')
        set -l prio    (echo $todo_json | jq -r '.priority // 2')
        set -l project (echo $todo_json | jq -r '.project // ""')
        set -l due     (echo $todo_json | jq -r '.due // ""')
        set -l tags    (echo $todo_json | jq -r '(.tags // []) | join(", ")')
        set -l done    (echo $todo_json | jq -r '.done // false')

        set -l prio_icon  (__todo_prio_icon $prio)
        set -l prio_color (__todo_prio_color $prio)

        set -l done_icon ""
        test "$done" = true && set done_icon $GREEN"✓$R"

        # Project badge
        set -l project_badge ""
        test -n "$project" && set project_badge " $CYAN[$project]$R"

        # Tag badge
        set -l tag_badge ""
        test -n "$tags" && set tag_badge " $DIM#$tags$R"

        # Due display
        set -l due_str (__todo_due_display $due)

        printf "  %s%s  $prio_color%-4s$R  %-45s%s%s%s\n" \
            $done_icon $prio_icon \
            "#$id" \
            (string sub --length 45 $text) \
            $project_badge $tag_badge $due_str
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 COMMAND DISPATCH                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_cmd

        # ── LIST: Show pending todos ───────────────────────────────────────────
        case ls
            set -l total  (jq 'length' $_todo_file 2>/dev/null; or echo 0)
            set -l done_c (jq '[.[] | select(.done == true)] | length' $_todo_file 2>/dev/null; or echo 0)
            set -l pend_c (math $total - $done_c)

            printf "\n"
            printf "  $BOLD$YELLOW╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$YELLOW║  ✅  Todo List  %-37s║$R\n" \
                "  $pend_c pending  ·  $done_c done"
            printf "  $BOLD$YELLOW╚══════════════════════════════════════════════════════╝$R\n\n"

            # Group by priority
            for prio in 1 2 3
                set -l prio_label
                switch $prio
                    case 1; set prio_label "$RED  ❗ High Priority$R"
                    case 2; set prio_label "$YELLOW  ● Medium Priority$R"
                    case 3; set prio_label "$DIM  ○ Low Priority$R"
                end

                set -l items (
                    jq -c \
                        --argjson p $prio \
                        '[.[] | select(.done != true and .priority == $p)] | sort_by(.id)[]' \
                        $_todo_file 2>/dev/null
                )

                if test (count $items) -gt 0
                    printf "  $BOLD%s$R\n" $prio_label
                    for item in $items
                        __todo_row $item
                    end
                    printf "\n"
                end
            end

            # Uncategorized (no priority)
            set -l uncat (
                jq -c '[.[] | select(.done != true and (.priority == null or .priority == 0))][]' \
                    $_todo_file 2>/dev/null
            )
            for item in $uncat; __todo_row $item; end

            if test $total -eq 0
                printf "  $GREEN✓$R  No pending todos! Enjoy your day 🎉\n"
            end

            test $done_c -gt 0 && \
                printf "  $DIM  %d completed — run 'todo done-list' to view$R\n" $done_c
            printf "\n"

        # ── ADD: Create new todo ───────────────────────────────────────────────
        case add
            test -z "$_text" && begin
                read -P "  Todo text: " _text
                test -z "$_text" && return 0
            end

            set -l new_id (__todo_next_id)
            set -l tags_json (test -n "$_tag" && printf '["'$_tag'"]' || echo '[]')
            set -l due_json  (test -n "$_due" && printf '"%s"' $_due || echo 'null')
            set -l proj_json (test -n "$_project" && printf '"%s"' $_project || echo 'null')

            set -l new_item (printf '{
                "id": %d,
                "text": "%s",
                "priority": %d,
                "project": %s,
                "due": %s,
                "tags": %s,
                "done": false,
                "created": "%s"
            }' $new_id \
               (string replace '"' '\"' "$_text") \
               $_priority \
               $proj_json \
               $due_json \
               $tags_json \
               $_ts_iso)

            jq --argjson item "$new_item" '. + [$item]' \
                $_todo_file > /tmp/todo-tmp.json 2>/dev/null && \
                mv /tmp/todo-tmp.json $_todo_file

            # Display confirmation
            printf "\n  $GREEN✓$R  Added "
            __todo_prio_icon $_priority
            printf "  $BOLD#%d$R  %s" $new_id "$_text"
            test -n "$_project" && printf "  $CYAN[%s]$R" $_project
            test -n "$_due"     && __todo_due_display $_due
            printf "\n\n"

        # ── DONE: Mark complete ────────────────────────────────────────────────
        case done
            set -l ids

            if test -z "$_id" && test -z "$_text"
                # Interactive picker
                if command -q fzf
                    set -l selected (
                        jq -r '.[] | select(.done != true) | "\(.id)\t\(.text)"' \
                            $_todo_file 2>/dev/null |
                        fzf --ansi --multi \
                            --border-label "  ✅ Complete Todos " \
                            --border rounded \
                            --prompt "  ✅ " \
                            --pointer "▶" \
                            --marker "✓" \
                            --header '  Tab:multi  Enter:done  ' \
                            --height 50% |
                        awk '{print $1}'
                    )
                    set ids $selected
                else
                    todo ls
                    read -P "  ID to complete: " _id
                    set ids $_id
                end
            else
                set ids $_id (string split ' ' "$_text" | grep -E '^\d+$')
            end

            for id in $ids
                set -l item_text (
                    jq -r --argjson id $id \
                        '.[] | select(.id == $id) | .text' \
                        $_todo_file 2>/dev/null
                )

                test -z "$item_text" && begin
                    printf "  $RED✗$R  Todo #$id not found\n"
                    continue
                end

                # Mark done in todos.json
                jq --argjson id $id --arg ts $_ts_iso \
                    '(.[] | select(.id == $id)) |= . + {"done": true, "completed": $ts}' \
                    $_todo_file > /tmp/todo-tmp.json 2>/dev/null && \
                    mv /tmp/todo-tmp.json $_todo_file

                # Move to done archive
                set -l done_item (
                    jq -c --argjson id $id \
                        '.[] | select(.id == $id)' \
                        $_todo_file 2>/dev/null
                )
                jq --argjson item "$done_item" '. + [$item]' \
                    $_done_file > /tmp/done-tmp.json 2>/dev/null && \
                    mv /tmp/done-tmp.json $_done_file

                printf "  $GREEN✓$R  Completed #$id: $DIM%s$R\n" \
                    (string sub --length 50 $item_text)
            end
            printf "\n"

        # ── UNDONE: Reopen completed todo ──────────────────────────────────────
        case undone
            test -z "$_id" && begin
                read -P "  ID to reopen: " _id
                test -z "$_id" && return 0
            end

            jq --argjson id $_id \
                '(.[] | select(.id == $id)) |= . + {"done": false, "completed": null}' \
                $_todo_file > /tmp/todo-tmp.json 2>/dev/null && \
                mv /tmp/todo-tmp.json $_todo_file

            printf "  $YELLOW↩$R  Reopened #$_id\n\n"

        # ── EDIT: Update todo text ─────────────────────────────────────────────
        case edit
            test -z "$_id" && begin
                read -P "  ID to edit: " _id
                test -z "$_id" && return 0
            end

            if test -z "$_text"
                set -l current (
                    jq -r --argjson id $_id \
                        '.[] | select(.id == $id) | .text' \
                        $_todo_file 2>/dev/null
                )
                printf "  Current: $DIM%s$R\n" $current
                read -P "  New text: " _text
                test -z "$_text" && return 0
            end

            jq --argjson id $_id --arg text "$_text" \
                '(.[] | select(.id == $id)) |= . + {"text": $text}' \
                $_todo_file > /tmp/todo-tmp.json 2>/dev/null && \
                mv /tmp/todo-tmp.json $_todo_file

            printf "  $GREEN✓$R  Updated #$_id: $DIM%s$R\n\n" "$_text"

        # ── DELETE: Remove todo ────────────────────────────────────────────────
        case delete
            test -z "$_id" && begin
                read -P "  ID to delete: " _id
                test -z "$_id" && return 0
            end

            set -l item_text (
                jq -r --argjson id $_id \
                    '.[] | select(.id == $id) | .text' \
                    $_todo_file 2>/dev/null
            )

            printf "  $YELLOW⚠$R  Delete #$_id: $DIM%s$R\n" \
                (string sub --length 50 $item_text)
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || begin
                printf "  $DIM  Cancelled$R\n\n"; return 0
            end

            jq --argjson id $_id \
                '[.[] | select(.id != $id)]' \
                $_todo_file > /tmp/todo-tmp.json 2>/dev/null && \
                mv /tmp/todo-tmp.json $_todo_file

            printf "  $RED✗$R  Deleted #$_id\n\n"

        # ── CLEAR: Remove all completed ────────────────────────────────────────
        case clear
            set -l done_count (
                jq '[.[] | select(.done == true)] | length' $_todo_file 2>/dev/null; or echo 0
            )

            if test $done_count -eq 0
                printf "  $DIM  No completed todos to clear$R\n\n"
                return 0
            end

            printf "  $YELLOW⚠$R  Clear %d completed todo(s)?\n" $done_count
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || begin
                printf "  $DIM  Cancelled$R\n\n"; return 0
            end

            jq '[.[] | select(.done != true)]' \
                $_todo_file > /tmp/todo-tmp.json 2>/dev/null && \
                mv /tmp/todo-tmp.json $_todo_file

            printf "  $GREEN✓$R  Cleared %d completed todos\n\n" $done_count

        # ── PICK: Interactive fzf browser ──────────────────────────────────────
        case pick
            if not command -q fzf
                todo ls; return 0
            end

            set -l action (
                jq -r '.[] | select(.done != true) |
                    "\(.id) |\(.priority)| \(.text) \(if .project then "[\(.project)]" else "" end) \(if .due then "[due: \(.due)]" else "" end)"' \
                    $_todo_file 2>/dev/null |
                fzf --ansi \
                    --no-sort \
                    --border-label "  ✅ Todo Manager " \
                    --border rounded \
                    --prompt "  ✅ " \
                    --pointer "▶" \
                    --marker "✓" \
                    --multi \
                    --preview '
                        id=$(echo {} | awk "{print \$1}")
                        jq --argjson id "$id" \
                            ".[] | select(.id == \$id)" \
                            '"$_todo_file"' 2>/dev/null | python3 -m json.tool
                    ' \
                    --preview-window 'right:40%:border-rounded' \
                    --header '  Enter:done  Ctrl-D:delete  Ctrl-E:edit  Ctrl-P:priority  ' \
                    --bind 'ctrl-d:execute(
                        id=$(echo {} | awk "{print \$1}")
                        jq --argjson id "$id" "[.[] | select(.id != \$id)]" '"$_todo_file"' > /tmp/td.json && mv /tmp/td.json '"$_todo_file"'
                    )+reload(jq -r '"'"'.[] | select(.done != true) | "\(.id) |\(.priority)| \(.text)"'"'"' '"$_todo_file"' 2>/dev/null)' \
                    --height 75% |
                awk '{print $1}'
            )

            for id in $action
                string match -qr '^\d+$' $id || continue
                todo done $id
            end

        # ── ALL: Show everything ───────────────────────────────────────────────
        case all
            todo ls
            todo done-list

        # ── DONE-LIST: Show completed ──────────────────────────────────────────
        case done-list
            set -l items (
                jq -c '[.[] | select(.done == true)] | sort_by(.completed) | reverse | .[0:20][]' \
                    $_todo_file 2>/dev/null
            )

            test (count $items) -eq 0 && begin
                printf "  $DIM  No completed todos$R\n\n"
                return 0
            end

            printf "\n  $BOLD$GREEN  ✓ Completed (last 20)$R\n\n"

            for item in $items
                set -l id        (echo $item | jq -r '.id')
                set -l text      (echo $item | jq -r '.text')
                set -l completed (echo $item | jq -r '.completed // "" | .[0:10]')

                printf "  $GREEN✓$R  $DIM#%-4s$R  %-45s  $DIM%s$R\n" \
                    $id (string sub --length 45 $text) $completed
            end
            printf "\n"

        # ── PROJECT: Filter by project ─────────────────────────────────────────
        case project
            set -l proj (test -n "$_id" && echo $_id || echo $_text)

            if test -z "$proj"
                # List all projects
                printf "\n  $BOLD$CYAN  📁 Projects$R\n\n"
                jq -r '[.[] | select(.done != true) | .project // "none"] | group_by(.) | .[] | "\(.[0]): \(length)"' \
                    $_todo_file 2>/dev/null | \
                while read -l line
                    set -l pname (echo $line | cut -d: -f1)
                    set -l count (echo $line | cut -d: -f2 | string trim)
                    printf "  $CYAN%-20s$R  $DIM%s tasks$R\n" $pname $count
                end
                printf "\n"
                return 0
            end

            printf "\n  $BOLD$CYAN  📁 Project: %s$R\n\n" $proj

            for item in (jq -c --arg p "$proj" \
                '[.[] | select(.done != true and .project == $p)][]' \
                $_todo_file 2>/dev/null)
                __todo_row $item
            end
            printf "\n"

        # ── OVERDUE: Show past-due items ───────────────────────────────────────
        case overdue
            printf "\n  $BOLD$RED  ⏰ Overdue Todos$R\n\n"

            set -l found 0
            for item in (jq -c \
                --arg today "$_today" \
                '[.[] | select(.done != true and .due != null and .due < $today)]
                | sort_by(.due)[]' \
                $_todo_file 2>/dev/null)
                __todo_row $item
                set found (math $found + 1)
            end

            if test $found -eq 0
                printf "  $GREEN✓$R  No overdue todos!\n"
            end
            printf "\n"

        # ── DUE: Show by due date ──────────────────────────────────────────────
        case due
            set -l filter_date (test -n "$_id" && echo $_id || echo $_today)

            printf "\n  $BOLD$ORANGE  📅 Due: %s$R\n\n" $filter_date

            for item in (jq -c \
                --arg d "$filter_date" \
                '[.[] | select(.done != true and .due == $d)][]' \
                $_todo_file 2>/dev/null)
                __todo_row $item
            end
            printf "\n"

        # ── STATS: Task statistics ─────────────────────────────────────────────
        case stats
            set -l total   (jq 'length'                                         $_todo_file 2>/dev/null; or echo 0)
            set -l pending (jq '[.[] | select(.done != true)] | length'         $_todo_file 2>/dev/null; or echo 0)
            set -l done_c  (jq '[.[] | select(.done == true)] | length'         $_todo_file 2>/dev/null; or echo 0)
            set -l high    (jq '[.[] | select(.done != true and .priority==1)] | length' $_todo_file 2>/dev/null; or echo 0)
            set -l overdue (jq --arg t "$_today" \
                '[.[] | select(.done != true and .due != null and .due < $t)] | length' \
                $_todo_file 2>/dev/null; or echo 0)

            set -l pct 0
            test $total -gt 0 && set pct (math --scale 0 "$done_c * 100 / $total")

            printf "\n  $BOLD$YELLOW╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$YELLOW║     📊  Todo Statistics                              ║$R\n"
            printf "  $BOLD$YELLOW╚══════════════════════════════════════════════════════╝$R\n\n"

            # Progress bar
            set -l bar_len (math --scale 0 "$pct * 30 / 100")
            set -l bar_empty (math 30 - $bar_len)
            printf "  $BOLD  Progress:  $R$GREEN%s$DIM%s$R  $BOLD%d%%$R\n\n" \
                (string repeat -n $bar_len "█") \
                (string repeat -n $bar_empty "░") \
                $pct

            printf "  $BOLD%-22s$R  $CYAN%s$R\n" "Total todos:"       $total
            printf "  $BOLD%-22s$R  $YELLOW%s$R\n" "Pending:"          $pending
            printf "  $BOLD%-22s$R  $GREEN%s$R\n"  "Completed:"        $done_c
            printf "  $BOLD%-22s$R  $RED%s$R\n"    "High priority:"    $high
            test $overdue -gt 0 && \
                printf "  $BOLD%-22s$R  $RED%s$R\n" "Overdue:" $overdue

            # Project breakdown
            printf "\n  $BOLD  By Project:$R\n"
            jq -r '[.[] | select(.done != true) | .project // "inbox"] |
                group_by(.) | .[] | "\(.[0]) \(length)"' \
                $_todo_file 2>/dev/null | sort -k2 -rn | \
            while read -l line
                set -l pname (echo $line | awk '{print $1}')
                set -l count (echo $line | awk '{print $2}')
                printf "    $CYAN%-18s$R  $DIM%d tasks$R\n" $pname $count
            end
            printf "\n"
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __todo_help __todo_next_id __todo_prio_icon \
        __todo_prio_color __todo_due_display __todo_row 2>/dev/null

end
