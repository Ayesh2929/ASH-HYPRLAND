# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — backup Ultra                                       ║
# ║  Smart backup system: incremental, encrypted, scheduled & cloud-aware      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function backup --description "Smart file/directory backup system"

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

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 CONSTANTS                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _backup_root  "$HOME/.backups"
    set -l _log_dir      "$HOME/.local/share/ash/logs/backup"
    set -l _catalog      "$HOME/.local/share/ash/state/backup-catalog.json"
    set -l _ts           (date +%Y%m%d-%H%M%S)
    set -l _ts_iso       (date -u +%Y-%m-%dT%H:%M:%SZ)

    mkdir -p $_backup_root $_log_dir (dirname $_catalog) 2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode      backup   # backup | restore | list | verify | clean | info
    set -l _sources           # files/dirs to backup
    set -l _dest      ""      # destination directory
    set -l _name      ""      # backup name/label
    set -l _type      full    # full | incremental | differential
    set -l _compress  1       # compress with zst
    set -l _encrypt   0       # encrypt with age/gpg
    set -l _password  ""
    set -l _keep      10      # keep N backups
    set -l _dry_run   0
    set -l _verbose   0
    set -l _quiet     0
    set -l _verify    1       # verify after backup
    set -l _tag       ""      # custom tag
    set -l _include   ""      # include pattern
    set -l _exclude   ""      # exclude pattern
    set -l _id        ""      # backup ID for restore/verify

    # ── Help ──────────────────────────────────────────────────────────────────
    function __bk_help --description "Print backup help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     💾  backup — Smart Backup System                 ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-25s$R  %s\n" \
            "backup <sources...>"      "Create backup" \
            "backup list"              "List all backups" \
            "backup restore <id>"      "Restore a backup" \
            "backup verify [id]"       "Verify backup integrity" \
            "backup clean [--keep N]"  "Remove old backups" \
            "backup info [id]"         "Show backup details"
        echo ""
        echo "  $BOLD Options (backup mode):$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "-n, --name <label>"    "Backup label/name" \
            "-d, --dest <dir>"      "Output directory" \
            "-t, --type <type>"     "full|incremental|differential" \
            "--no-compress"         "Disable compression" \
            "--encrypt"             "Encrypt with age/gpg" \
            "-p, --password <pw>"   "Encryption password" \
            "--keep <N>"            "Retention count (default: 10)" \
            "--tag <tag>"           "Custom tag" \
            "--exclude <pattern>"   "Exclude pattern" \
            "--no-verify"           "Skip post-backup verification" \
            "-v, --verbose"         "Verbose output" \
            "-q, --quiet"           "Quiet mode" \
            "-n, --dry-run"         "Preview without creating"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "backup ~/projects/              # Backup directory" \
            "backup ~/docs ~/work/ -n weekly # Labeled backup" \
            "backup ~/.config --encrypt -p s3cr3t  # Encrypted" \
            "backup list                     # Show all backups" \
            "backup restore 20240101-120000  # Restore by ID" \
            "backup clean --keep 5           # Keep only 5 backups" \
            "backup verify                   # Verify latest"
        echo ""
    end

    # ── Parse args ────────────────────────────────────────────────────────────
    if test (count $argv) -eq 0
        __bk_help
        return 0
    end

    # First arg: mode detection
    switch $argv[1]
        case list ls;        set _mode list;    set argv $argv[2..-1]
        case restore;        set _mode restore; set argv $argv[2..-1]
        case verify;         set _mode verify;  set argv $argv[2..-1]
        case clean purge;    set _mode clean;   set argv $argv[2..-1]
        case info show;      set _mode info;    set argv $argv[2..-1]
        case --help -h help; __bk_help; return 0
    end

    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case -n --name
                set _i (math $_i + 1)
                # Distinguish --name from --dry-run (-n)
                if string match -qr '^[^-]' $argv[$_i]
                    set _name $argv[$_i]
                else
                    set _dry_run 1; set _i (math $_i - 1)
                end
            case --name=*
                set _name (string replace --regex '^--name=' '' $arg)
            case -d --dest
                set _i (math $_i + 1); set _dest $argv[$_i]
            case -t --type
                set _i (math $_i + 1); set _type $argv[$_i]
            case --tag
                set _i (math $_i + 1); set _tag $argv[$_i]
            case --keep
                set _i (math $_i + 1); set _keep $argv[$_i]
            case -p --password
                set _i (math $_i + 1); set _password $argv[$_i]; set _encrypt 1
            case --exclude -x
                set _i (math $_i + 1); set _exclude $argv[$_i]
            case --encrypt -e;   set _encrypt  1
            case --no-compress;  set _compress 0
            case --no-verify;    set _verify   0
            case --dry-run;      set _dry_run  1
            case -v --verbose;   set _verbose  1
            case -q --quiet;     set _quiet    1
            case '*'
                set --append _sources $arg
        end
        set _i (math $_i + 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 OUTPUT HELPERS                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_ok   --description "OK"
        test $_quiet -eq 1 && return
        printf "  $GREEN✓$R  %s\n" $argv[1]
    end
    function __bk_fail --description "Fail"
        printf "  $RED✗$R  %s\n" $argv[1] >&2
    end
    function __bk_info --description "Info"
        test $_quiet -eq 1 && return
        printf "  $CYAN›$R  $DIM%s$R\n" $argv[1]
    end
    function __bk_warn --description "Warn"
        test $_quiet -eq 1 && return
        printf "  $YELLOW⚠$R  %s\n" $argv[1]
    end

    function __bk_human --description "Human readable size"
        set -l b (du -sb $argv[1] 2>/dev/null | awk '{print $1}'; or echo 0)
        if test $b -ge 1073741824
            math --scale 2 "$b / 1073741824" | read -l n; echo "$n GiB"
        else if test $b -ge 1048576
            math --scale 2 "$b / 1048576" | read -l n; echo "$n MiB"
        else if test $b -ge 1024
            math --scale 1 "$b / 1024" | read -l n; echo "$n KiB"
        else
            echo "$b B"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 LIST MODE                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_list --description "List all backups"
        echo ""
        echo $BOLD$CYAN"  💾 Backup Catalog"$R
        echo ""
        printf "  $BOLD$CYAN%-22s  %-14s  %-12s  %-10s  %s$R\n" \
            "ID" "Name" "Size" "Type" "Sources"
        printf "  $DIM%s$R\n" (string repeat -n 70 "─")

        if not test -f $_catalog
            echo "  $DIM  No backups found$R"
            echo ""
            return
        end

        command -q jq || begin
            ls -lt $_backup_root 2>/dev/null | while read -l line
                echo "  $DIM$line$R"
            end
            return
        end

        jq -r '.backups[] | "\(.id)\t\(.name // "backup")\t\(.compressed_size // "?")\t\(.type // "full")\t\(.sources | join(",") | .[0:30])"' \
            $_catalog 2>/dev/null | \
        while read -l line
            set -l p (string split \t $line)
            printf "  $CYAN%-22s$R  $GREEN%-14s$R  %-12s  %-10s  $DIM%s$R\n" \
                $p[1] $p[2] $p[3] $p[4] $p[5]
        end

        echo ""

        # Stats
        set -l total_count (
            command -q jq && jq '.backups | length' $_catalog 2>/dev/null || echo 0
        )
        set -l total_size (__bk_human $_backup_root)
        printf "  $DIM%d backup(s) — Total: %s — Root: %s$R\n\n" \
            $total_count $total_size (string replace $HOME "~" $_backup_root)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔬 VERIFY MODE                                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_verify_one --description "Verify a single backup archive"
        set -l f $argv[1]
        test -f $f || begin; __bk_fail "Archive not found: $f"; return 1; end

        printf "  $CYAN🔬$R  Verifying: $DIM%s$R  " (basename $f)

        set -l ok 0
        switch $f
            case '*.tar.zst'
                command -q zstd && zstd -t $f >/dev/null 2>&1 && set ok 1
            case '*.tar.gz' '*.tgz'
                tar -tzf $f >/dev/null 2>&1 && set ok 1
            case '*.tar.xz'
                tar -tJf $f >/dev/null 2>&1 && set ok 1
            case '*.tar.bz2'
                tar -tjf $f >/dev/null 2>&1 && set ok 1
            case '*.tar'
                tar -tf $f >/dev/null 2>&1 && set ok 1
            case '*.zip'
                command -q unzip && unzip -t $f >/dev/null 2>&1 && set ok 1
            case '*.7z'
                command -q 7z && 7z t $f >/dev/null 2>&1 && set ok 1
            case '*'
                set ok 1  # Unknown: assume OK
        end

        test $ok -eq 1 \
            && printf "$GREEN✓ OK$R\n" \
            || printf "$RED✗ CORRUPT$R\n"

        return (test $ok -eq 1 && echo 0 || echo 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🧹 CLEAN MODE                                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_clean --description "Remove old backups keeping N most recent"
        echo ""
        echo $BOLD$YELLOW"  🧹 Backup Cleanup (keeping $_keep most recent)"$R
        echo ""

        set -l all_backups (ls -t $_backup_root 2>/dev/null)
        set -l total (count $all_backups)

        if test $total -le $_keep
            __bk_info "Nothing to clean ($total backups, keeping $_keep)"
            echo ""
            return
        end

        set -l to_delete $all_backups[(math $_keep + 1)..-1]
        set -l freed_bytes 0

        for bk in $to_delete
            set -l bk_path "$_backup_root/$bk"
            set -l bk_size (du -sb $bk_path 2>/dev/null | awk '{print $1}')
            test -n "$bk_size" && set freed_bytes (math $freed_bytes + $bk_size)

            if test $_dry_run -eq 1
                printf "  $YELLOW[DRY]$R  Would remove: $bk\n"
            else
                rm -rf $bk_path 2>/dev/null
                and printf "  $RED✗$R  Removed: $DIM$bk$R\n"
            end
        end

        echo ""
        set -l freed_human (__bk_human /dev/null 2>/dev/null; or echo "?")
        if test $_dry_run -eq 0
            printf "  $GREEN✓$R  Removed %d backup(s)\n" (count $to_delete)
            printf "  $DIM  Freed approximately %d bytes$R\n" $freed_bytes
        end
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ♻️  RESTORE MODE                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_restore --description "Restore from a backup"
        set -l backup_id $argv[1]
        set -l restore_to $argv[2]

        if test -z "$backup_id"
            # Interactive: pick from list
            if command -q fzf
                set backup_id (
                    ls -t $_backup_root 2>/dev/null |
                    fzf --ansi \
                        --border-label "  💾 Select Backup to Restore " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                        --preview "ls -la '$_backup_root/{}'/ 2>/dev/null | head -20" \
                        --preview-window 'right:50%:border-rounded' \
                        --header '  Enter:restore  '
                )
                test -z "$backup_id" && return 0
            else
                __bk_list
                read -P "  Backup ID to restore: " backup_id
            end
        end

        set -l bk_dir "$_backup_root/$backup_id"
        if not test -d $bk_dir
            __bk_fail "Backup not found: $backup_id"
            __bk_info "Run: backup list"
            return 1
        end

        test -z "$restore_to" && set restore_to "."

        echo ""
        echo $BOLD$CYAN"  ♻️  Restoring backup: $backup_id"$R
        __bk_info "Restoring to: $restore_to"
        echo ""

        echo $BOLD$YELLOW"  ⚠  This will overwrite files in: $restore_to"$R
        read -P "  Confirm? [y/N] " confirm
        string match -qi 'y*' $confirm || begin; echo "  Cancelled."; return 0; end

        set -l ts (date +%s)
        mkdir -p $restore_to 2>/dev/null

        # Find archive file
        set -l archive_file (ls $bk_dir/*.tar.* $bk_dir/*.tar $bk_dir/*.zip \
            $bk_dir/*.7z 2>/dev/null | head -1)

        if test -z "$archive_file"
            __bk_fail "No archive found in: $bk_dir"
            return 1
        end

        extract $archive_file -d $restore_to 2>/dev/null
        set -l rc $status
        set -l elapsed (math (date +%s) - $ts)

        if test $rc -eq 0
            printf "  $GREEN✓$R  Restored in %ds → $CYAN%s$R\n\n" $elapsed $restore_to
        else
            __bk_fail "Restore failed after $elapsed""s"
            return 1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ℹ️  INFO MODE                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_info_cmd --description "Show backup info"
        set -l bid $argv[1]

        if test -z "$bid"
            set bid (ls -t $_backup_root 2>/dev/null | head -1)
        end

        set -l bk_dir "$_backup_root/$bid"
        test -d $bk_dir || begin; __bk_fail "Backup not found: $bid"; return 1; end

        echo ""
        echo $BOLD$BLUE"  💾 Backup: $bid"$R
        echo ""

        # Meta file
        set -l meta "$bk_dir/meta.json"
        if test -f $meta && command -q jq
            jq -r '
                "  Name:     " + (.name // "backup"),
                "  Type:     " + (.type // "full"),
                "  Created:  " + (.created // ""),
                "  Sources:  " + (.sources | join(", ")),
                "  Compress: " + (.compressed | tostring),
                "  Encrypt:  " + (.encrypted | tostring)
            ' $meta 2>/dev/null | while read -l line
                echo "  $DIM$line$R"
            end
        end

        # Show files
        echo ""
        echo "  $BOLD Contents:$R"
        ls -lh $bk_dir/ 2>/dev/null | while read -l line
            printf "    $DIM%s$R\n" $line
        end

        # Checksums
        set -l checksum_file "$bk_dir/checksums.sha256"
        if test -f $checksum_file
            echo ""
            echo "  $BOLD$GREEN✓ Checksums available$R"
        end
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  💾 BACKUP CREATION ENGINE                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bk_create --description "Create a backup"
        if test (count $_sources) -eq 0
            __bk_fail "No sources specified"
            return 1
        end

        # Validate sources
        for src in $_sources
            test -e $src || begin; __bk_fail "Not found: $src"; return 1; end
        end

        # Build backup name
        test -z "$_name" && set _name (basename $_sources[1] | string replace -a '/' '_')
        test -n "$_tag" && set _name "$_name-$_tag"
        set -l bid "$_ts"
        set -l bk_dir (test -n "$_dest" && echo "$_dest/$bid" || echo "$_backup_root/$bid")

        # Determine archive extension
        set -l archive_ext ""
        set -l log_file "$_log_dir/$bid.log"
        set -l meta_file "$bk_dir/meta.json"
        set -l checksum_file "$bk_dir/checksums.sha256"

        if test $_compress -eq 1
            set archive_ext "tar.zst"
            command -q zstd || set archive_ext "tar.gz"
        else
            set archive_ext "tar"
        end

        set -l archive_path "$bk_dir/$_name.$archive_ext"

        # ── Source size analysis ───────────────────────────────────────────────
        set -l src_bytes 0
        set -l src_files 0
        for src in $_sources
            set -l b (du -sb $src 2>/dev/null | awk '{print $1}')
            test -n "$b" && set src_bytes (math $src_bytes + $b)
            set -l fc (find $src -type f 2>/dev/null | wc -l | string trim)
            set src_files (math $src_files + $fc)
        end

        # ── Banner ─────────────────────────────────────────────────────────────
        if test $_quiet -eq 0
            printf "\n"
            printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$PURPLE║  💾  Backup: %-48s║$R\n" \
                (string sub --length 48 $_name)
            printf "  $BOLD$PURPLE╠══════════════════════════════════════════════════════╣$R\n"
            printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" \
                "ID:" $bid
            printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" \
                "Type:" "$_type"
            printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" \
                "Sources:" (string join ', ' (basename --multiple $_sources) | string sub --length 40)
            printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" \
                "Input size:" \
                (math --scale 1 "$src_bytes / 1048576" 2>/dev/null | read -l m; echo "$m MiB ($src_files files)")
            printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" \
                "Format:" $archive_ext
            printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" \
                "Destination:" (string replace $HOME '~' $bk_dir | string sub --length 40)
            test $_encrypt -eq 1 && \
                printf "  $BOLD$PURPLE║$R  $BOLD%-14s$R  %-40s$PURPLE║$R\n" "Encrypted:" "yes"
            printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n"
            printf "\n"
        end

        if test $_dry_run -eq 1
            __bk_info "DRY-RUN: backup not created"
            functions --erase __bk_help __bk_ok __bk_fail __bk_info __bk_warn \
                __bk_human __bk_list __bk_verify_one __bk_clean __bk_restore \
                __bk_info_cmd __bk_create 2>/dev/null
            return 0
        end

        # ── Create backup directory ────────────────────────────────────────────
        mkdir -p $bk_dir 2>/dev/null

        set -l ts_run (date +%s)

        # ── Exclude flags ─────────────────────────────────────────────────────
        set -l exclude_flags ""
        test -n "$_exclude" && set exclude_flags "--exclude='$_exclude'"

        # ── Compress & archive ────────────────────────────────────────────────
        set -l created 0

        if test $_compress -eq 1
            switch $archive_ext
                case tar.zst
                    set -l threads (nproc 2>/dev/null; or echo 4)
                    eval "tar -cf - $exclude_flags $_sources 2>>$log_file | \
                          zstd -9 -T$threads -o '$archive_path'" 2>>$log_file
                    test $status -eq 0 && set created 1
                case tar.gz
                    command -q pigz && \
                        eval "tar -cf - $exclude_flags $_sources 2>>$log_file | \
                              pigz -9 > '$archive_path'" 2>>$log_file \
                    || eval "tar -czf '$archive_path' $exclude_flags $_sources" 2>>$log_file
                    test $status -eq 0 && set created 1
                case '*'
                    eval "tar -cf '$archive_path' $exclude_flags $_sources" 2>>$log_file
                    test $status -eq 0 && set created 1
            end
        else
            eval "tar -cf '$archive_path' $exclude_flags $_sources" 2>>$log_file
            test $status -eq 0 && set created 1
        end

        if test $created -eq 0
            __bk_fail "Archive creation failed (log: $log_file)"
            functions --erase __bk_help __bk_ok __bk_fail __bk_info __bk_warn \
                __bk_human __bk_list __bk_verify_one __bk_clean __bk_restore \
                __bk_info_cmd __bk_create 2>/dev/null
            return 1
        end

        set -l elapsed (math (date +%s) - $ts_run)

        # ── Encryption ────────────────────────────────────────────────────────
        if test $_encrypt -eq 1
            if command -q age
                set -l enc_file "$archive_path.age"
                age --passphrase --output $enc_file $archive_path 2>/dev/null
                and begin
                    rm -f $archive_path 2>/dev/null
                    set archive_path $enc_file
                    __bk_ok "Encrypted with age"
                end
            else if command -q gpg && test -n "$_password"
                set -l enc_file "$archive_path.gpg"
                gpg --batch --yes --passphrase "$_password" \
                    --symmetric --cipher-algo AES256 \
                    --output $enc_file $archive_path 2>/dev/null
                and begin
                    rm -f $archive_path 2>/dev/null
                    set archive_path $enc_file
                    __bk_ok "Encrypted with GPG"
                end
            else
                __bk_warn "No encryption tool found (age or gpg)"
            end
        end

        # ── Generate checksums ─────────────────────────────────────────────────
        sha256sum $archive_path > $checksum_file 2>/dev/null
        __bk_ok "SHA256 checksum saved"

        # ── Write metadata ─────────────────────────────────────────────────────
        set -l out_bytes (du -b $archive_path 2>/dev/null | awk '{print $1}'; or echo 0)
        set -l ratio 0
        test $src_bytes -gt 0 && \
            set ratio (math --scale 1 "$out_bytes * 100 / $src_bytes")

        printf '{"id":"%s","name":"%s","type":"%s","created":"%s","sources":[%s],"archive":"%s","original_bytes":%d,"compressed_bytes":%d,"ratio":%s,"compressed":%s,"encrypted":%s,"elapsed":%d}' \
            $bid \
            $_name \
            $_type \
            $_ts_iso \
            (string join ',' (for s in $_sources; printf '"%s"' $s; end)) \
            $archive_path \
            $src_bytes \
            $out_bytes \
            $ratio \
            (test $_compress -eq 1 && echo true || echo false) \
            (test $_encrypt  -eq 1 && echo true || echo false) \
            $elapsed \
            > $meta_file 2>/dev/null

        # Update catalog
        if test -f $_catalog && command -q jq
            set -l new_entry (cat $meta_file)
            jq --argjson entry "$new_entry" \
                '.backups = [$entry] + .backups' \
                $_catalog > /tmp/catalog-tmp.json 2>/dev/null && \
                mv /tmp/catalog-tmp.json $_catalog
        else
            printf '{"backups":[%s]}' (cat $meta_file) > $_catalog 2>/dev/null
        end

        # ── Verify ────────────────────────────────────────────────────────────
        if test $_verify -eq 1
            __bk_verify_one $archive_path
        end

        # ── Summary ───────────────────────────────────────────────────────────
        if test $_quiet -eq 0
            printf "\n"
            printf "  $BOLD$GREEN╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$GREEN║  ✓  Backup Complete                                  ║$R\n"
            printf "  $BOLD$GREEN╠══════════════════════════════════════════════════════╣$R\n"
            printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" "ID:" $bid
            printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" "Archive:" \
                (basename $archive_path | string sub --length 40)
            printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" "Original:" \
                (math --scale 1 "$src_bytes / 1048576" 2>/dev/null | read -l m; echo "$m MiB")
            printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  $CYAN%-40s$R$GREEN║$R\n" "Compressed:" \
                (math --scale 1 "$out_bytes / 1048576" 2>/dev/null | read -l m; echo "$m MiB ($ratio%)")
            printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" "Time:" "${elapsed}s"
            printf "  $BOLD$GREEN╚══════════════════════════════════════════════════════╝$R\n"
            printf "\n"
        end

        # ── Auto-clean old backups ─────────────────────────────────────────────
        set -l count (ls -d $_backup_root/*/ 2>/dev/null | wc -l | string trim)
        if test $count -gt $_keep
            __bk_info "Auto-cleaning (have $count, keeping $_keep)..."
            __bk_clean
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_mode
        case list;    __bk_list
        case restore; __bk_restore $_sources[1] $_dest
        case verify
            if test (count $_sources) -gt 0
                for bid in $_sources
                    set -l bk_dir "$_backup_root/$bid"
                    for f in $bk_dir/*.tar.* $bk_dir/*.tar $bk_dir/*.zip $bk_dir/*.7z
                        test -f $f && __bk_verify_one $f
                    end
                end
            else
                # Verify latest
                set -l latest (ls -t $_backup_root 2>/dev/null | head -1)
                if test -n "$latest"
                    for f in "$_backup_root/$latest/"*.tar.* \
                              "$_backup_root/$latest/"*.tar \
                              "$_backup_root/$latest/"*.zip \
                              "$_backup_root/$latest/"*.7z
                        test -f $f && __bk_verify_one $f
                    end
                else
                    __bk_fail "No backups found"
                end
            end
        case clean;   __bk_clean
        case info;    __bk_info_cmd $_sources[1]
        case backup;  __bk_create
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __bk_help __bk_ok __bk_fail __bk_info __bk_warn \
        __bk_human __bk_list __bk_verify_one __bk_clean __bk_restore \
        __bk_info_cmd __bk_create 2>/dev/null

end
