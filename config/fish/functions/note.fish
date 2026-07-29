# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — note Ultra                                         ║
# ║  Terminal note system: markdown, tags, search, sync & rich display         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function note --description "Terminal note-taking system with markdown & tagging"

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
    set -l PINK   (set_color F5C2E7)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 PATHS & CONSTANTS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _notes_dir   "$HOME/.local/share/ash/notes"
    set -l _index_file  "$HOME/.local/share/ash/notes/.index.json"
    set -l _config_file "$HOME/.config/ash/notes.conf"
    set -l _ts          (date +%Y%m%d-%H%M%S)
    set -l _ts_iso      (date -u +%Y-%m-%dT%H:%M:%SZ)
    set -l _editor      (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)

    mkdir -p $_notes_dir 2>/dev/null

    # ── Load config ────────────────────────────────────────────────────────────
    set -l _default_ext "md"
    set -l _date_format "+%Y-%m-%d %H:%M"
    set -l _max_preview 8

    if test -f $_config_file
        source $_config_file 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __note_help --description "Print help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     📝  note — Terminal Note System                  ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  note [command] [options]"
        echo ""
        echo "  $BOLD Commands:$R"
        printf "    $CYAN%-24s$R  %s\n" \
            "(none)"          "Quick capture — open editor for new note" \
            "new [title]"     "Create a new named note" \
            "ls [tag]"        "List all notes (optionally by tag)" \
            "view <id|title>" "View a note" \
            "edit <id|title>" "Edit a note" \
            "find <query>"    "Full-text search notes" \
            "tag <id> <tags>" "Add tags to a note" \
            "delete <id>"     "Delete a note" \
            "pick"            "Interactive fzf note browser" \
            "today"           "Today's journal / daily note" \
            "append <id>"     "Append text to a note" \
            "export <id>"     "Export note to HTML/PDF" \
            "stats"           "Note collection statistics" \
            "sync"            "Sync notes with git remote"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "-t, --tag <tag>"    "Set tag(s) when creating" \
            "--plain"            "Plain text (no markdown)" \
            "--title <title>"    "Set note title" \
            "--dir <dir>"        "Override notes directory" \
            "-h, --help"         "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "note                          # Quick new note in editor" \
            "note new 'Meeting notes'      # Named note" \
            "note new -t work,meeting      # Note with tags" \
            "note ls                       # List all notes" \
            "note ls work                  # List tagged 'work'" \
            "note find 'API design'        # Search notes" \
            "note today                    # Open today's journal" \
            "note pick                     # Interactive browser" \
            "note view meeting-notes       # View a specific note" \
            "note append meeting 'action'  # Append to note"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _cmd    new     # default: create
    set -l _title  ""
    set -l _tags   ""
    set -l _query  ""
    set -l _id     ""
    set -l _plain  0
    set -l _extra

    if test (count $argv) -eq 0
        set _cmd quick
    else
        switch $argv[1]
            case new create;       set _cmd new;    set argv $argv[2..-1]
            case ls list show-all; set _cmd ls;     set argv $argv[2..-1]
            case view cat read;    set _cmd view;   set argv $argv[2..-1]
            case edit open;        set _cmd edit;   set argv $argv[2..-1]
            case find search grep; set _cmd find;   set argv $argv[2..-1]
            case tag tags label;   set _cmd tag;    set argv $argv[2..-1]
            case delete rm del;    set _cmd delete; set argv $argv[2..-1]
            case pick browse;      set _cmd pick;   set argv $argv[2..-1]
            case today journal;    set _cmd today;  set argv $argv[2..-1]
            case append add-to;    set _cmd append; set argv $argv[2..-1]
            case export;           set _cmd export; set argv $argv[2..-1]
            case stats info;       set _cmd stats;  set argv $argv[2..-1]
            case sync push;        set _cmd sync;   set argv $argv[2..-1]
            case --help -h help;   __note_help; return 0
            case '*'
                # Treat as title for quick note
                set _cmd new
                set _title (string join ' ' $argv)
                set argv
        end
    end

    # Parse remaining options
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case -t --tag
                set _i (math $_i + 1); set _tags $argv[$_i]
            case -t=* --tag=*
                set _tags (string replace -r '^-t=|^--tag=' '' $arg)
            case --title=*
                set _title (string replace '--title=' '' $arg)
            case --title
                set _i (math $_i + 1); set _title $argv[$_i]
            case --plain; set _plain 1
            case '*'
                if test -z "$_id" && test -z "$_query"
                    set _id $arg
                    set _query $arg
                else
                    set --append _extra $arg
                end
        end
        set _i (math $_i + 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  HELPER FUNCTIONS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Note ID from title ─────────────────────────────────────────────────────
    function __note_slug --description "Convert title to filesystem slug"
        string lower $argv[1] | \
            string replace -a ' ' '-' | \
            string replace -r '[^a-z0-9\-]' '' | \
            string sub --length 50
    end

    # ── Note file path from ID/title ───────────────────────────────────────────
    function __note_path --description "Get note file path"
        set -l id $argv[1]

        # Direct file match
        for ext in md txt rst org
            if test -f "$_notes_dir/$id.$ext"
                echo "$_notes_dir/$id.$ext"
                return 0
            end
        end

        # Partial name match
        set -l matches (ls $_notes_dir 2>/dev/null | grep -i $id | head -1)
        if test -n "$matches"
            echo "$_notes_dir/$matches"
            return 0
        end

        return 1
    end

    # ── Get note metadata from frontmatter ────────────────────────────────────
    function __note_meta --description "Read YAML frontmatter from note"
        set -l file $argv[1]
        set -l field $argv[2]
        test -f $file || return 1

        grep "^$field:" $file 2>/dev/null | head -1 | \
            awk -F': ' '{print $2}' | string trim
    end

    # ── Write frontmatter header ───────────────────────────────────────────────
    function __note_frontmatter --description "Write YAML frontmatter"
        set -l title $argv[1]
        set -l tags  $argv[2]

        printf '---\ntitle: "%s"\ndate: %s\ntags: [%s]\ndate_ts: %s\n---\n\n' \
            $title $_ts_iso $tags $_ts
    end

    # ── Format note listing row ────────────────────────────────────────────────
    function __note_row --description "Format a note list row"
        set -l file  $argv[1]
        set -l title (__note_meta $file title | string replace '"' '')
        set -l date  (__note_meta $file date | string sub --length 10)
        set -l tags  (__note_meta $file tags | string replace -a '[' '' | string replace -a ']' '')
        set -l lines (wc -l < $file 2>/dev/null | string trim)
        set -l name  (basename $file | string replace -r '\.(md|txt|rst|org)$' '')

        test -z "$title" && set title $name
        test -z "$date"  && set date  (date -r $file '+%Y-%m-%d' 2>/dev/null; or echo "unknown")

        printf "  $CYAN%-28s$R  $DIM%-12s$R  $YELLOW%-18s$R  $DIM%3s lines$R\n" \
            (string sub --length 28 $title) $date \
            (string sub --length 18 $tags) $lines
    end

    # ── Update index ───────────────────────────────────────────────────────────
    function __note_reindex --description "Rebuild notes index"
        command -q jq || return 0

        set -l entries

        for f in $_notes_dir/*.md $_notes_dir/*.txt
            test -f $f || continue
            set -l title (__note_meta $f title | string replace '"' '')
            set -l tags  (__note_meta $f tags)
            set -l date  (__note_meta $f date)
            set -l name  (basename $f)
            test -z "$title" && set title (basename $f | string replace -r '\.\w+$' '')

            set --append entries \
                (printf '{"file":"%s","title":"%s","tags":%s,"date":"%s"}' \
                    $name "$title" (test -n "$tags" && echo $tags || echo "[]") "$date")
        end

        printf '[%s]' (string join ',' $entries) > $_index_file 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 COMMAND DISPATCH                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_cmd

        # ── QUICK: Open editor for new note ───────────────────────────────────
        case quick
            set -l file "$_notes_dir/quick-$_ts.$_default_ext"

            if test $_plain -eq 0
                __note_frontmatter "Quick Note" "" > $file
            end

            $_editor $file
            test -s $file && printf "\n  $GREEN✓$R  Saved: $DIM%s$R\n\n" (basename $file) \
                || rm -f $file

        # ── NEW: Create named note ─────────────────────────────────────────────
        case new
            test -z "$_title" && begin
                read -P "  Note title: " _title
                test -z "$_title" && set _title "untitled-$_ts"
            end

            set -l slug (__note_slug "$_title")
            set -l ext  (test $_plain -eq 1 && echo txt || echo $_default_ext)
            set -l file "$_notes_dir/$slug.$ext"

            # Handle duplicate
            if test -f $file
                set file "$_notes_dir/$slug-$_ts.$ext"
            end

            if test $_plain -eq 0
                __note_frontmatter "$_title" "$_tags" > $file
            end

            $_editor $file

            if test -s $file
                __note_reindex
                printf "\n  $GREEN✓$R  Created: $CYAN%s$R  $DIM(%s)$R\n\n" \
                    "$_title" (basename $file)
            else
                rm -f $file
                printf "  $DIM  (empty note discarded)$R\n\n"
            end

        # ── LIST: List all notes ───────────────────────────────────────────────
        case ls
            printf "\n"
            printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$PURPLE║     📝  Notes  %-38s║$R\n" \
                (test -n "$_id" && echo "(tag: $_id)" || echo "")
            printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n\n"

            printf "  $BOLD$CYAN%-28s  %-12s  %-18s  %s$R\n" \
                "TITLE" "DATE" "TAGS" "SIZE"
            printf "  $DIM%s$R\n" (string repeat -n 72 "─")

            set -l count 0

            for f in (ls -t $_notes_dir/*.md $_notes_dir/*.txt 2>/dev/null)
                test -f $f || continue

                # Filter by tag
                if test -n "$_id"
                    set -l note_tags (__note_meta $f tags)
                    string match -qi "*$_id*" $note_tags || continue
                end

                __note_row $f
                set count (math $count + 1)
            end

            printf "\n  $DIM  %d note(s) in %s$R\n\n" $count \
                (string replace $HOME '~' $_notes_dir)

        # ── VIEW: Display a note ───────────────────────────────────────────────
        case view
            set -l file (__note_path "$_id")

            if test -z "$file"
                printf "  $RED✗$R  Note not found: '$_id'\n"
                printf "  $DIM  Run: note ls   to list all notes$R\n\n"
                return 1
            end

            set -l title (__note_meta $file title | string replace '"' '')
            set -l date  open
            set -l tags  (__note_meta $file tags)
            test -z "$title" && set title (basename $file | string replace -r '\.\w+$' '')

            printf "\n"
            printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$PURPLE║  📝 %-52s║$R\n" (string sub --length 52 "$title")
            printf "  $BOLD$PURPLE║  $DIM%-54s$PURPLE║$R\n" \
                "  $date  ·  $tags"
            printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n\n"

            # Render: glow → bat → cat
            if command -q glow
                glow $file
            else if command -q bat
                bat --language=markdown --style=plain --color=always \
                    --paging=auto $file
            else
                # Strip frontmatter for plain display
                awk '/^---$/{if(NR==1){skip=1;next} if(skip){skip=0;next}} !skip' $file | \
                    while read -l line
                        printf "  %s\n" $line
                    end
            end
            printf "\n"

        # ── EDIT: Edit a note ──────────────────────────────────────────────────
        case edit
            set -l file (__note_path "$_id")

            if test -z "$file"
                printf "  $YELLOW⚠$R  Note not found: '$_id'\n"
                read -P "  Create it? [Y/n] " create_it
                string match -qi 'n*' $create_it && return 0
                set _title "$_id"
                set _cmd new
                # Re-dispatch
                note new "$_title"
                return $status
            end

            $_editor $file
            __note_reindex
            printf "  $GREEN✓$R  Updated: $DIM%s$R\n\n" (basename $file)

        # ── FIND: Full-text search ─────────────────────────────────────────────
        case find
            test -z "$_query" && begin
                read -P "  Search query: " _query
                test -z "$_query" && return 0
            end

            printf "\n  $BOLD$CYAN  🔍 Searching: \"$_query\"$R\n\n"

            set -l found 0

            if command -q rg
                rg --color=always --ignore-case --with-filename --line-number \
                    "$_query" $_notes_dir/ 2>/dev/null | \
                while read -l line
                    set -l file  (echo $line | cut -d: -f1)
                    set -l lnum  (echo $line | cut -d: -f2)
                    set -l text  (echo $line | cut -d: -f3-)
                    set -l title (__note_meta $file title | string replace '"' '')
                    test -z "$title" && set title (basename $file)

                    printf "  $PURPLE%-28s$R  $DIM:%-4s$R  %s\n" \
                        (string sub --length 28 $title) $lnum \
                        (string replace -i "$_query" $YELLOW"$_query"$R (string sub --length 50 $text))
                    set found (math $found + 1)
                end
            else
                grep -rli "$_query" $_notes_dir/ 2>/dev/null | \
                while read -l file
                    set -l title (__note_meta $file title | string replace '"' '')
                    test -z "$title" && set title (basename $file)
                    printf "  $CYAN%-30s$R  $DIM%s$R\n" $title \
                        (string replace $HOME '~' $file)
                    set found (math $found + 1)
                end
            end

            test $found -eq 0 && printf "  $DIM  No results for '$_query'$R\n"
            printf "\n"

        # ── TAG: Add/view tags ─────────────────────────────────────────────────
        case tag
            set -l file (__note_path "$_id")

            if test -z "$file"
                printf "  $RED✗$R  Note not found: '$_id'\n"; return 1
            end

            set -l new_tags (string join ' ' $_extra)

            if test -z "$new_tags"
                # View current tags
                set -l current (__note_meta $file tags)
                printf "  $CYAN  Tags for %s:$R  %s\n\n" \
                    (basename $file) $current
            else
                # Update tags in frontmatter
                set -l current (__note_meta $file tags | \
                    string replace '[' '' | string replace ']' '')
                set -l updated "$current, $new_tags"

                python3 -c "
import re
with open('$file', 'r') as f:
    content = f.read()
content = re.sub(r'^tags: \[.*\]', f'tags: [$updated]', content, flags=re.MULTILINE)
with open('$file', 'w') as f:
    f.write(content)
" 2>/dev/null
                __note_reindex
                printf "  $GREEN✓$R  Tags updated: $YELLOW%s$R\n\n" $updated
            end

        # ── DELETE: Remove a note ──────────────────────────────────────────────
        case delete
            set -l file (__note_path "$_id")

            if test -z "$file"
                printf "  $RED✗$R  Note not found: '$_id'\n"; return 1
            end

            set -l title (__note_meta $file title | string replace '"' '')
            test -z "$title" && set title (basename $file)

            printf "  $YELLOW⚠$R  Delete: $CYAN%s$R\n" $title
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || begin
                printf "  $DIM  Cancelled$R\n\n"; return 0
            end

            rm -f $file
            __note_reindex
            printf "  $GREEN✓$R  Deleted: $DIM%s$R\n\n" $title

        # ── PICK: Interactive fzf browser ──────────────────────────────────────
        case pick
            if not command -q fzf
                note ls; return 0
            end

            set -l selected (
                begin
                    for f in (ls -t $_notes_dir/*.md $_notes_dir/*.txt 2>/dev/null)
                        test -f $f || continue
                        set -l title (__note_meta $f title | string replace '"' '')
                        set -l date  (__note_meta $f date | string sub --length 10)
                        set -l tags  (__note_meta $f tags | \
                            string replace '[' '' | string replace ']' '' | string trim)
                        test -z "$title" && set title (basename $f | string replace -r '\.\w+$' '')
                        printf "%s\t%s\t%s\t%s\n" $f $title $date $tags
                    end
                end |
                fzf --ansi \
                    --no-sort \
                    --border-label "  📝 Note Browser " \
                    --border rounded \
                    --prompt "  📝 " \
                    --pointer "▶" \
                    --delimiter \t \
                    --with-nth '2,3,4' \
                    --preview '
                        file={1}
                        if command -v glow >/dev/null 2>&1; then
                            glow "$file" 2>/dev/null
                        elif command -v bat >/dev/null 2>&1; then
                            bat --color=always --style=plain --language=markdown "$file"
                        else
                            cat "$file"
                        fi
                    ' \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --header '  Enter:view  Ctrl-E:edit  Ctrl-D:delete  Ctrl-Y:copy  ' \
                    --bind 'ctrl-e:execute('$_editor' {1})+reload(echo "")' \
                    --bind 'ctrl-d:execute(rm -f {1})+reload(ls '$_notes_dir'/*.md 2>/dev/null)' \
                    --bind 'ctrl-y:execute-silent(cat {1} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)' \
                    --height 85% |
                cut -f1
            )

            test -n "$selected" && note view (basename $selected | string replace -r '\.\w+$' '')

        # ── TODAY: Daily journal ───────────────────────────────────────────────
        case today
            set -l date_str (date '+%Y-%m-%d')
            set -l day_name (date '+%A, %B %-d %Y')
            set -l file     "$_notes_dir/journal-$date_str.md"

            if not test -f $file
                printf '---\ntitle: "Journal: %s"\ndate: %s\ntags: [journal, daily]\n---\n\n# %s\n\n## 🌅 Morning\n\n\n\n## ✅ Goals\n\n- [ ] \n- [ ] \n- [ ] \n\n## 📝 Notes\n\n\n\n## 🌙 Evening Reflection\n\n\n' \
                    "$day_name" $_ts_iso "$day_name" > $file
            end

            printf "  $CYAN📔$R  Opening journal: $BOLD%s$R\n\n" $day_name
            $_editor $file
            __note_reindex

        # ── APPEND: Add text to existing note ─────────────────────────────────
        case append
            set -l file (__note_path "$_id")

            if test -z "$file"
                printf "  $RED✗$R  Note not found: '$_id'\n"; return 1
            end

            set -l text (string join ' ' $_extra)

            if test -z "$text"
                printf "  $DIM  Enter text to append (Ctrl-D when done):$R\n"
                set text (command cat)
            end

            printf "\n\n---\n*Appended: %s*\n\n%s\n" "$_ts_iso" "$text" >> $file
            printf "  $GREEN✓$R  Appended to: $DIM%s$R\n\n" (basename $file)

        # ── EXPORT: Export note ────────────────────────────────────────────────
        case export
            set -l file (__note_path "$_id")
            set -l fmt  (test -n "$_extra[1]" && echo $_extra[1] || echo html)

            if test -z "$file"
                printf "  $RED✗$R  Note not found: '$_id'\n"; return 1
            end

            set -l out_base (basename $file | string replace -r '\.\w+$' '')

            switch $fmt
                case html
                    if command -q pandoc
                        pandoc $file -o "$out_base.html" 2>/dev/null
                        and printf "  $GREEN✓$R  Exported: $CYAN%s.html$R\n\n" $out_base
                    else
                        printf "  $YELLOW⚠$R  Install pandoc for HTML export\n\n"
                    end
                case pdf
                    if command -q pandoc
                        pandoc $file -o "$out_base.pdf" 2>/dev/null
                        and printf "  $GREEN✓$R  Exported: $CYAN%s.pdf$R\n\n" $out_base
                    else
                        printf "  $YELLOW⚠$R  Install pandoc for PDF export\n\n"
                    end
                case txt
                    cat $file > "$out_base.txt" 2>/dev/null
                    printf "  $GREEN✓$R  Exported: $CYAN%s.txt$R\n\n" $out_base
            end

        # ── STATS: Collection statistics ──────────────────────────────────────
        case stats
            set -l note_files (ls $_notes_dir/*.md $_notes_dir/*.txt 2>/dev/null)
            set -l total (count $note_files)
            set -l total_words 0
            set -l total_lines 0
            set -l oldest_date "9999"
            set -l newest_date "0000"

            for f in $note_files
                test -f $f || continue
                set -l words (wc -w < $f 2>/dev/null | string trim)
                set -l lines (wc -l < $f 2>/dev/null | string trim)
                set total_words (math $total_words + $words)
                set total_lines (math $total_lines + $lines)
                set -l d (__note_meta $f date | string sub --length 10)
                test -n "$d" && test "$d" < $oldest_date && set oldest_date $d
                test -n "$d" && test "$d" > $newest_date && set newest_date $d
            end

            printf "\n  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$PURPLE║     📊  Note Collection Statistics                   ║$R\n"
            printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n\n"
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Total notes:"  $total
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Total words:"  $total_words
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Total lines:"  $total_lines
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Oldest note:"  $oldest_date
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Newest note:"  $newest_date
            printf "  $BOLD%-20s$R  $DIM%s$R\n"  "Location:"     \
                (string replace $HOME '~' $_notes_dir)
            printf "\n"

            # Tag cloud
            printf "  $BOLD  Tag Cloud:$R\n  "
            cat $_notes_dir/*.md 2>/dev/null | grep '^tags:' | \
                grep -oP '[a-zA-Z0-9_-]+' | sort | uniq -c | sort -rn | head -15 | \
                awk '{printf "%s(%d) ", $2, $1}'
            printf "\n\n"

        # ── SYNC: Git sync ────────────────────────────────────────────────────
        case sync
            if not test -d "$_notes_dir/.git"
                printf "  $YELLOW⚠$R  Notes directory is not a git repo\n"
                read -P "  Initialize git? [Y/n] " init_git
                string match -qi 'n*' $init_git && return 0
                git -C $_notes_dir init -q
                git -C $_notes_dir add .
                git -C $_notes_dir commit -q -m "Initial notes commit"
                printf "  $GREEN✓$R  Git initialized\n"
                return 0
            end

            printf "  $CYAN  Syncing notes...$R\n"
            git -C $_notes_dir add .
            set -l changed (git -C $_notes_dir status --porcelain 2>/dev/null | wc -l | string trim)

            if test $changed -gt 0
                git -C $_notes_dir commit -q -m "Notes sync: $(date '+%Y-%m-%d %H:%M')"
                printf "  $GREEN✓$R  Committed $changed change(s)\n"
            end

            git -C $_notes_dir pull --rebase -q 2>/dev/null && \
                git -C $_notes_dir push -q 2>/dev/null
            and printf "  $GREEN✓$R  Synced with remote\n\n"
            or  printf "  $YELLOW⚠$R  Sync complete (no remote configured)\n\n"
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __note_help __note_slug __note_path __note_meta \
        __note_frontmatter __note_row __note_reindex 2>/dev/null

end
