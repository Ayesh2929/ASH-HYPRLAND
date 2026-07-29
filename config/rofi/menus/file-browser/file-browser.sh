#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — File Browser Script                               ║
# ║                                                                              ║
# ║  Full file system browser as Rofi custom mode. Navigate directories,       ║
# ║  open files with xdg-open, copy paths, delete, create, bookmark and        ║
# ║  view file metadata with rich MIME-type icons.                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-filebrowser"
readonly CWD_FILE="${STATE_DIR}/cwd"
readonly HIDDEN_FILE="${STATE_DIR}/show-hidden"
readonly SORT_FILE="${STATE_DIR}/sort-mode"
readonly BOOKMARKS_FILE="${HOME}/.local/share/ash-dotfiles/fb-bookmarks.txt"
readonly RECENT_FILE="${HOME}/.local/share/ash-dotfiles/fb-recent.txt"
readonly CLIPBOARD_FILE="${STATE_DIR}/clipboard"
readonly MAX_RECENT=20

# Default starting directory
readonly DEFAULT_DIR="${HOME}"

# ══════════════════════════════════════════════════════════════════════════════
# §02  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

setup_state() {
    mkdir -p "$STATE_DIR"
    [[ ! -f "$CWD_FILE" ]] && echo "$DEFAULT_DIR" > "$CWD_FILE"
    [[ ! -f "$HIDDEN_FILE" ]] && echo "false" > "$HIDDEN_FILE"
    [[ ! -f "$SORT_FILE" ]] && echo "name" > "$SORT_FILE"
}

get_cwd()    { cat "$CWD_FILE"    2>/dev/null || echo "$HOME"; }
get_hidden() { cat "$HIDDEN_FILE" 2>/dev/null || echo "false"; }
get_sort()   { cat "$SORT_FILE"   2>/dev/null || echo "name"; }

set_cwd()    { echo "$1" > "$CWD_FILE"; }

toggle_hidden() {
    local current
    current=$(get_hidden)
    if [[ "$current" == "true" ]]; then
        echo "false" > "$HIDDEN_FILE"
    else
        echo "true" > "$HIDDEN_FILE"
    fi
}

cycle_sort() {
    local current
    current=$(get_sort)
    case "$current" in
        name)     echo "time"   > "$SORT_FILE" ;;
        time)     echo "size"   > "$SORT_FILE" ;;
        size)     echo "type"   > "$SORT_FILE" ;;
        type)     echo "name"   > "$SORT_FILE" ;;
        *)        echo "name"   > "$SORT_FILE" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  FILE TYPE → ICON + COLOR
# ══════════════════════════════════════════════════════════════════════════════

get_file_icon() {
    local file="$1"
    local name="${file##*/}"
    local ext="${name##*.}"
    local ext_lower="${ext,,}"

    # Directory
    if [[ -d "$file" ]]; then
        case "${name,,}" in
            .git|.svn|.hg)             echo "󰊢" ;;
            node_modules|vendor)        echo "󰎙" ;;
            .config|.local|.cache)      echo "󰒓" ;;
            downloads)                  echo "󰇚" ;;
            documents)                  echo "󰈙" ;;
            pictures|photos|images)     echo "󰋩" ;;
            videos|movies)              echo "󰎁" ;;
            music|audio)                echo "󰝚" ;;
            desktop)                    echo "󰇄" ;;
            projects|code|dev|src)      echo "󰅩" ;;
            backup|backups)             echo "󰕉" ;;
            *)                          echo "󰉋" ;;
        esac
        return
    fi

    # Symlink
    if [[ -L "$file" ]]; then
        echo "󰉒"
        return
    fi

    # File by extension
    case "$ext_lower" in
        # Documents
        pdf)                        echo "󰈦" ;;
        doc|docx|odt|rtf)           echo "󰈬" ;;
        xls|xlsx|ods|csv)           echo "󰈛" ;;
        ppt|pptx|odp)               echo "󰈧" ;;
        txt|text)                   echo "󰈙" ;;
        md|markdown|rst)            echo "󰍔" ;;
        epub|mobi|azw)              echo "󰂺" ;;

        # Images
        jpg|jpeg|png|gif|webp|bmp|svg|ico|tiff|tif|avif|heic|heif)
                                    echo "󰷆" ;;
        raw|cr2|nef|arw|dng)        echo "󰄃" ;;
        psd|xcf|ai)                 echo "󰋩" ;;

        # Video
        mp4|mkv|avi|mov|wmv|flv|webm|m4v|vob|3gp|ogv)
                                    echo "󰎁" ;;

        # Audio
        mp3|flac|wav|aac|ogg|wma|m4a|opus|alac|aiff)
                                    echo "󰎵" ;;
        mid|midi)                   echo "󰍎" ;;

        # Archives
        zip|tar|gz|bz2|xz|7z|rar|zst|lz4|br)
                                    echo "󰛫" ;;
        iso|img|dmg)                echo "󰻨" ;;
        deb|rpm|pkg|apk)            echo "󰏗" ;;

        # Code / source
        py|pyw)                     echo "󰌠" ;;
        js|mjs|cjs)                 echo "󰌞" ;;
        ts|tsx)                     echo "󰛦" ;;
        jsx)                        echo "󰜈" ;;
        rs)                         echo "󱘗" ;;
        go)                         echo "󰟓" ;;
        c|cc)                       echo "󰙱" ;;
        cpp|cxx|c++)                echo "󰙲" ;;
        h|hpp)                      echo "󰙳" ;;
        java|kt|kts)                echo "󰬷" ;;
        rb|rake)                    echo "󰴭" ;;
        php)                        echo "󰌟" ;;
        lua)                        echo "󰢱" ;;
        sh|bash|zsh|fish|ksh)       echo "󰆍" ;;
        ps1|psm1|psd1)              echo "󰨊" ;;
        html|htm)                   echo "󰌝" ;;
        css|scss|sass|less)         echo "󰌜" ;;
        vue|svelte|astro)           echo "󰡄" ;;
        r|rmd)                      echo "󰟔" ;;
        matlab|m)                   echo "󰿛" ;;
        sql)                        echo "󰆼" ;;
        zig)                        echo "󱨴" ;;
        ex|exs)                     echo "󱔉" ;;
        hs|lhs)                     echo "󰲒" ;;
        nix)                        echo "󱄅" ;;
        dart)                       echo "󰙸" ;;
        swift)                      echo "󰛥" ;;

        # Config / data
        json|jsonc)                 echo "󰅩" ;;
        yaml|yml)                   echo "󰰐" ;;
        toml)                       echo "󰅪" ;;
        xml|xhtml)              echo "󰗀" ;;
        ini|conf|cfg|config)        echo "󰒓" ;;
        env|dotenv)                 echo "󰙟" ;;
        lock)                       echo "󰌋" ;;
        dockerfile)                 echo "󰡨" ;;
        makefile|gnumakefile)       echo "󱁤" ;;

        # System / binary
        so|dll|dylib)               echo "󰗮" ;;
        out|bin|run|elf)            echo "󱪲" ;;
        ko|mod)                     echo "󰍁" ;;

        # Fonts
        ttf|otf|woff|woff2|eot)    echo "󰛖" ;;

        # Database
        db|sqlite|sqlite3)          echo "󰆼" ;;

        # Version control
        patch|diff)                 echo "󰤋" ;;

        # Key / cert
        pem|crt|cer|key|p12|pfx)   echo "󰌋" ;;

        # Unknown
        *)
            if [[ -x "$file" ]]; then
                echo "󱪲"
            else
                echo "󰈙"
            fi
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  FILE METADATA FORMATTERS
# ══════════════════════════════════════════════════════════════════════════════

format_size() {
    local bytes="${1:-0}"
    if   (( bytes < 1024 ));          then printf "%dB"      "$bytes"
    elif (( bytes < 1048576 ));        then printf "%.1fKB"   "$(echo "scale=1; $bytes/1024"        | bc 2>/dev/null || echo 0)"
    elif (( bytes < 1073741824 ));     then printf "%.1fMB"   "$(echo "scale=1; $bytes/1048576"     | bc 2>/dev/null || echo 0)"
    else                                    printf "%.2fGB"   "$(echo "scale=2; $bytes/1073741824"  | bc 2>/dev/null || echo 0)"
    fi
}

format_date() {
    local file="$1"
    local mtime
    mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
    local now
    now=$(date +%s)
    local diff=$(( now - mtime ))

    if   (( diff < 3600 ));   then printf "%dm ago"   $(( diff / 60 ))
    elif (( diff < 86400 ));  then printf "%dh ago"   $(( diff / 3600 ))
    elif (( diff < 604800 )); then printf "%dd ago"   $(( diff / 86400 ))
    else                           date -d "@${mtime}" '+%b %d' 2>/dev/null || date -r "$mtime" '+%b %d' 2>/dev/null || echo "old"
    fi
}

get_dir_info() {
    local dir="$1"
    local count=0
    count=$(find "$dir" -maxdepth 1 -not -name "." 2>/dev/null | wc -l) || true
    echo "${count} items"
}

get_mime_type() {
    local file="$1"
    file --mime-type -b "$file" 2>/dev/null | head -1 || echo "application/octet-stream"
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  DIRECTORY SORTING
# ══════════════════════════════════════════════════════════════════════════════

list_sorted() {
    local dir="$1"
    local sort_mode
    sort_mode=$(get_sort)
    local show_hidden
    show_hidden=$(get_hidden)

    local find_args=(-maxdepth 1 -not -name ".")
    [[ "$show_hidden" != "true" ]] && find_args+=(-not -name ".*")

    case "$sort_mode" in
        time)
            find "$dir" "${find_args[@]}" -printf "%T@ %p\n" 2>/dev/null | \
                sort -rn | awk '{print $2}' | \
                while read -r f; do
                    [[ -d "$f" ]] && echo "D|$f" || echo "F|$f"
                done
            ;;
        size)
            # Dirs first, then by size desc
            find "$dir" "${find_args[@]}" -type d -printf "D|%p\n" 2>/dev/null | sort -t'|' -k2
            find "$dir" "${find_args[@]}" -type f -printf "%s|F|%p\n" 2>/dev/null | \
                sort -rn | awk -F'|' '{print $2"|"$3}'
            ;;
        type)
            find "$dir" "${find_args[@]}" -printf "%y|%p\n" 2>/dev/null | \
                sort -t'|' -k1,1 -k2,2 | awk -F'|' '{
                    if($1=="d") print "D|"$2; else print "F|"$2
                }'
            ;;
        *)  # name (default)
            find "$dir" "${find_args[@]}" -type d -printf "D|%p\n" 2>/dev/null | sort -t'|' -k2 -f
            find "$dir" "${find_args[@]}" -type f -printf "F|%p\n" 2>/dev/null | sort -t'|' -k2 -f
            find "$dir" "${find_args[@]}" -type l -printf "L|%p\n" 2>/dev/null | sort -t'|' -k2 -f
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  BOOKMARKS & RECENT
# ══════════════════════════════════════════════════════════════════════════════

ensure_bookmarks() {
    mkdir -p "$(dirname "$BOOKMARKS_FILE")"
    if [[ ! -f "$BOOKMARKS_FILE" ]]; then
        cat > "$BOOKMARKS_FILE" << 'DEFAULTS'
🏠 Home|/home/$USER
󰇚 Downloads|/home/$USER/Downloads
󰈙 Documents|/home/$USER/Documents
󰷆 Pictures|/home/$USER/Pictures
󰎁 Videos|/home/$USER/Videos
󰝚 Music|/home/$USER/Music
 Projects|/home/$USER/Projects
 ASH Config|/home/$USER/.config/ash-dotfiles
DEFAULTS
    fi
}

add_bookmark() {
    local dir="$1"
    local name
    name=$(basename "$dir")
    ensure_bookmarks
    echo "󰈿 ${name}|${dir}" >> "$BOOKMARKS_FILE"
    notify_fb "Bookmark added" "$name" "low"
}

add_to_recent() {
    local path="$1"
    mkdir -p "$(dirname "$RECENT_FILE")"
    local tmp
    tmp=$(mktemp)
    echo "${path}|$(date +%s)" | cat - "$RECENT_FILE" 2>/dev/null > "$tmp" || true
    grep -vF "${path}|" "$RECENT_FILE" 2>/dev/null >> "$tmp" || true
    head -"$MAX_RECENT" "$tmp" > "$RECENT_FILE" 2>/dev/null || true
    rm -f "$tmp"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_fb() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Files" \
        --icon=system-file-manager \
        --urgency="$urgency" \
        --expire-time=2500 \
        --hint=string:x-dunst-stack-tag:file-browser \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_recent_entries() {
    printf '─── RECENT FILES & DIRS ──────────────────\0nonselectable\x1ftrue\n'

    if [[ ! -f "$RECENT_FILE" ]]; then
        printf '  No recent files yet\0nonselectable\x1ftrue\n'
        return
    fi

    local count=0
    while IFS='|' read -r path ts; do
        [[ -z "$path" ]] && continue
        [[ ! -e "$path" ]] && continue   # Skip if no longer exists

        local icon
        icon=$(get_file_icon "$path")
        local name
        name=$(basename "$path")
        local age
        age=$(format_date "$path")

        local display
        display=$(printf '%s  %-35s  %s' "$icon" "${name:0:33}" "$age")

        printf '%s\0info\x1fopen\x1fmeta\x1f%s\n' "$display" "$path"

        (( count++ )) || true
        [[ $count -ge 15 ]] && break
    done < "$RECENT_FILE"
}

build_bookmarks_entries() {
    ensure_bookmarks

    printf '─── BOOKMARKS ────────────────────────────\0nonselectable\x1ftrue\n'

    while IFS='|' read -r label path; do
        [[ -z "$label" || -z "$path" ]] && continue

        # Expand $USER
        path="${path/\$USER/$USER}"

        local icon="󰈿"
        [[ -d "$path" ]] && icon="󰉋"
        [[ ! -e "$path" ]] && icon="󰉢"  # Broken

        local display
        display=$(printf '%s  %-35s  %s' "$icon" "${label}" "${path/$HOME/~}")

        printf '%s\0info\x1fcd\x1fmeta\x1f%s\n' "$display" "$path"
    done < "$BOOKMARKS_FILE"

    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰈿  Add current dir to bookmarks\0info\x1fbookmark-add\n'
}

build_drives_entries() {
    printf '─── MOUNTED DRIVES ───────────────────────\0nonselectable\x1ftrue\n'

    # Parse /proc/mounts for interesting entries
    while IFS=' ' read -r device mountpoint fstype options dump pass; do
        # Skip uninteresting
        case "$fstype" in
            proc|sysfs|devtmpfs|devpts|tmpfs|securityfs|cgroup*|pstore|bpf|tracefs|debugfs|mqueue|hugetlbfs|fusectl|ramfs) continue ;;
        esac
        [[ "$mountpoint" == "/" ]] && continue
        [[ "$mountpoint" =~ ^/sys|^/proc|^/dev|^/run ]] && continue
        [[ ! -d "$mountpoint" ]] && continue

        local icon="󰋊"
        case "$device" in
            /dev/sd*)   icon="󰋊" ;;
            /dev/nvme*) icon="󰋊" ;;
            /dev/loop*) icon="󰻨" ;;
            *)
                [[ "$mountpoint" =~ usb|media ]] && icon="󱊞"
                [[ "$mountpoint" =~ nfs|smb|cifs|sshfs ]] && icon="󰛳"
                ;;
        esac

        local display
        display=$(printf '%s  %-30s  %s' \
            "$icon" \
            "${mountpoint/$HOME/~}" \
            "$fstype")

        printf '%s\0info\x1fcd\x1fmeta\x1f%s\n' "$display" "$mountpoint"

    done < /proc/mounts 2>/dev/null || true

    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰡃  Open udisksctl manager\0info\x1fudisks\n'
}

build_dir_entries() {
    local cwd
    cwd=$(get_cwd)

    # Validate directory
    if [[ ! -d "$cwd" ]]; then
        set_cwd "$HOME"
        cwd="$HOME"
    fi

    # Parent directory (if not at root)
    if [[ "$cwd" != "/" ]]; then
        local parent
        parent=$(dirname "$cwd")
        printf '󰉑  ..  (parent directory)\0info\x1fcd\x1fmeta\x1f%s\n' "$parent"
    fi

    # Sort mode indicator in a section header
    local sort_mode icon_sort
    sort_mode=$(get_sort)
    case "$sort_mode" in
        name) icon_sort="󰗴 Name" ;;
        time) icon_sort="󰃰 Modified" ;;
        size) icon_sort="󰆳 Size" ;;
        type) icon_sort="󰈙 Type" ;;
    esac

    printf '─── %s ─ sort: %s ─────────────────\0nonselectable\x1ftrue\n' \
        "$(echo "${cwd/$HOME/~}" | head -c 30)" "$icon_sort"

    # List files
    local count=0
    while IFS='|' read -r type filepath; do
        [[ -z "$filepath" ]] && continue

        local name
        name=$(basename "$filepath")
        local icon
        icon=$(get_file_icon "$filepath")
        local size_str="" date_str=""
        date_str=$(format_date "$filepath")

        if [[ "$type" == "D" ]]; then
            # Directory: show item count
            local dir_count
            dir_count=$(find "$filepath" -maxdepth 1 -not -name "." 2>/dev/null | wc -l | tr -d ' ' || echo "?")
            size_str="${dir_count} items"
        else
            # File: show size
            local bytes
            bytes=$(stat -c %s "$filepath" 2>/dev/null || echo 0)
            size_str=$(format_size "$bytes")
        fi

        # Permissions indicator
        local perm_indicator=""
        [[ -x "$filepath" && ! -d "$filepath" ]] && perm_indicator="*"
        [[ -L "$filepath" ]] && perm_indicator="→"

        local display
        display=$(printf '%s%s  %-30s  %-10s  %-8s  %s' \
            "$icon" \
            "$perm_indicator" \
            "${name:0:28}" \
            "$size_str" \
            "$date_str" \
            "")

        # Directories get 'cd' action, files get 'open' action
        if [[ "$type" == "D" ]]; then
            printf '%s\0info\x1fcd\x1fmeta\x1f%s\n' "$display" "$filepath"
        else
            printf '%s\0info\x1fopen\x1fmeta\x1f%s\n' "$display" "$filepath"
        fi

        (( count++ )) || true

    done < <(list_sorted "$cwd" 2>/dev/null || true)

    if [[ $count -eq 0 ]]; then
        printf '  (empty directory)\0nonselectable\x1ftrue\n'
    fi

    # Footer actions
    printf '─── ACTIONS ──────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰝰  New File Here\0info\x1fnew-file\n'
    printf '󰉌  New Folder Here\0info\x1fnew-dir\n'
    printf '  Open in Thunar\0info\x1fopen-thunar\n'
    printf '  Open Terminal Here\0info\x1fopen-term\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  FILE OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════

open_file() {
    local path="$1"

    if [[ -d "$path" ]]; then
        set_cwd "$path"
        add_to_recent "$path"
        return
    fi

    add_to_recent "$path"
    xdg-open "$path" &>/dev/null & disown
    notify_fb "󱁉 Opening" "$(basename "$path")" "low"
}

open_with() {
    local path="$1"
    local app
    app=$(rofi -dmenu \
        -p "Open with" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")
    [[ -n "$app" ]] && "$app" "$path" &>/dev/null & disown
}

copy_path() {
    local path="$1"
    echo -n "$path" | wl-copy 2>/dev/null && \
        notify_fb "󰆏 Path copied" "${path/$HOME/~}" "low"
}

delete_file() {
    local path="$1"
    local name
    name=$(basename "$path")

    # Confirm
    local confirm
    confirm=$(printf "Yes, delete\nNo, cancel" | \
        rofi -dmenu \
            -p "Delete: $name?" \
            -mesg "This will move <b>$name</b> to trash" \
            -theme-str "window { width: 320px; } listview { lines: 2; }
                element selected.normal { background-color: #f38ba8; text-color: #1e1e2e; }" \
            2>/dev/null || echo "No, cancel")

    if [[ "$confirm" == "Yes, delete" ]]; then
        if command -v gio &>/dev/null; then
            gio trash "$path" &>/dev/null && \
                notify_fb "󰩹 Trashed" "$name" "low"
        else
            rm -rf "$path" && \
                notify_fb "󰩹 Deleted" "$name" "normal"
        fi
    fi
}

new_file() {
    local cwd
    cwd=$(get_cwd)
    local name
    name=$(rofi -dmenu \
        -p "New file name" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")
    if [[ -n "$name" ]]; then
        touch "${cwd}/${name}" && \
            notify_fb "New file created" "$name" "low"
    fi
}

new_dir() {
    local cwd
    cwd=$(get_cwd)
    local name
    name=$(rofi -dmenu \
        -p "New folder name" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")
    if [[ -n "$name" ]]; then
        mkdir -p "${cwd}/${name}" && \
            notify_fb "New folder created" "$name" "low"
    fi
}

jump_to_path() {
    local target
    # shellcheck disable=SC2088
    target=$(rofi -dmenu \
        -p "󱁉 Jump to path" \
        -filter "~/" \
        -theme-str "window { width: 500px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    if [[ -n "$target" ]]; then
        target="${target/#~/$HOME}"
        if [[ -d "$target" ]]; then
            set_cwd "$target"
        elif [[ -f "$target" ]]; then
            set_cwd "$(dirname "$target")"
            open_file "$target"
        else
            notify_fb "Not found" "$target" "normal"
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        cd)         [[ -d "$meta" ]] && set_cwd "$meta" || notify_fb "Not a directory" "$meta" "normal" ;;
        open)       open_file "$meta" ;;
        open-with)  open_with "$meta" ;;
        copy-path)  copy_path "$meta" ;;
        delete)     delete_file "$meta" ;;
        new-file)   new_file ;;
        new-dir)    new_dir ;;
        bookmark-add) add_bookmark "$(get_cwd)" ;;
        toggle-hidden) toggle_hidden ;;
        cycle-sort) cycle_sort ;;
        go-up)
            local parent
            parent=$(dirname "$(get_cwd)")
            set_cwd "$parent"
            ;;
        open-thunar)
            command -v thunar &>/dev/null && \
                thunar "$(get_cwd)" &>/dev/null & disown || \
                notify_fb "Thunar not found" "" "normal"
            ;;
        open-term)
            kitty --working-directory "$(get_cwd)" &>/dev/null & disown
            ;;
        jump-path)  jump_to_path ;;
        udisks)
            command -v gnome-disks &>/dev/null && \
                gnome-disks &>/dev/null & disown || \
                notify_fb "No disk manager found" "" "normal"
            ;;
        none|"")    return 0 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --open)     [[ -n "${2:-}" ]] && open_file "$2" ;;
        --cd)       [[ -n "${2:-}" ]] && set_cwd "$2" ;;
        --cwd)      get_cwd ;;
        --reset)    echo "$HOME" > "$CWD_FILE" && echo "Reset to HOME" ;;
        --help|-h)
            echo "ASH File Browser v5.0"
            echo ""
            echo "Usage: file-browser.sh [OPTION] [PATH]"
            echo "  --open PATH  Open file/directory"
            echo "  --cd PATH    Set current directory"
            echo "  --cwd        Show current directory"
            echo "  --reset      Reset to home directory"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

# MODE tracking via ROFI_DATA
CURRENT_VIEW="${ROFI_DATA:-files}"

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true
    setup_state

    rofi \
        -show fb \
        -modi "fb:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/file-browser/file-browser.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    setup_state
    case "$CURRENT_VIEW" in
        recent)    build_recent_entries    ;;
        bookmarks) build_bookmarks_entries ;;
        drives)    build_drives_entries    ;;
        *)         build_dir_entries       ;;
    esac
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"

    # Rebuild current view after action
    case "$CURRENT_VIEW" in
        recent)    build_recent_entries    ;;
        bookmarks) build_bookmarks_entries ;;
        drives)    build_drives_entries    ;;
        *)         build_dir_entries       ;;
    esac
    exit 0
fi

# Ctrl+H: Toggle hidden
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    toggle_hidden
    build_dir_entries
    exit 0
fi

# Ctrl+S: Cycle sort
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    cycle_sort
    build_dir_entries
    exit 0
fi

# Ctrl+B: Bookmark current dir
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    add_bookmark "$(get_cwd)"
    build_dir_entries
    exit 0
fi

# Ctrl+C: Copy path
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && copy_path "$meta_value"
    build_dir_entries
    exit 0
fi

# Ctrl+N: New file
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    new_file
    build_dir_entries
    exit 0
fi

# Ctrl+R: Refresh
if [[ "${ROFI_RETV}" -eq 15 ]]; then
    build_dir_entries
    exit 0
fi

# Ctrl+T: Open terminal here
if [[ "${ROFI_RETV}" -eq 17 ]]; then
    dispatch_action "open-term"
    exit 0
fi

# Delete: Delete file
if [[ "${ROFI_RETV}" -eq 18 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && delete_file "$meta_value"
    build_dir_entries
    exit 0
fi

# Ctrl+L: Jump to path
if [[ "${ROFI_RETV}" -eq 23 ]]; then
    jump_to_path
    build_dir_entries
    exit 0
fi

# Backspace: Navigate up
if [[ "${ROFI_RETV}" -eq 24 ]]; then
    parent=$(dirname "$(get_cwd)")
    set_cwd "$parent"
    build_dir_entries
    exit 0
fi

# Re-filter
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    case "$CURRENT_VIEW" in
        recent)    build_recent_entries    ;;
        bookmarks) build_bookmarks_entries ;;
        drives)    build_drives_entries    ;;
        *)         build_dir_entries       ;;
    esac
    exit 0
fi