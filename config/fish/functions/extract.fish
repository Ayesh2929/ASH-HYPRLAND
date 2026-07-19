# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — extract Ultra                                      ║
# ║  Universal archive extractor: 40+ formats, smart detection & rich output   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function extract --description "Universal archive extractor (40+ formats)"

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
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _files       # files to extract
    set -l _dest    ""  # destination directory
    set -l _verbose  0
    set -l _quiet    0
    set -l _list     0  # list contents only
    set -l _dry_run  0
    set -l _strip    0  # strip leading path components
    set -l _into     1  # extract into subdir (named after archive)
    set -l _flat     0  # extract flat (no subdir)
    set -l _overwrite 0
    set -l _password ""
    set -l _test     0  # test archive integrity

    # ── Help ──────────────────────────────────────────────────────────────────
    if test (count $argv) -eq 0; or contains -- --help $argv; or contains -- -h $argv
        __extr_help
        return 0
    end

    function __extr_help --description "Print extract help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     📦  extract — Universal Archive Extractor        ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  extract <archive(s)...> [options]"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-22s$R  %s\n" "-d, --dest <dir>"    "Extract to specific directory"
        printf "    $CYAN%-22s$R  %s\n" "-f, --flat"          "Extract flat (no subdir wrapper)"
        printf "    $CYAN%-22s$R  %s\n" "-l, --list"          "List contents without extracting"
        printf "    $CYAN%-22s$R  %s\n" "-t, --test"          "Test archive integrity"
        printf "    $CYAN%-22s$R  %s\n" "-p, --password <pw>" "Archive password (zip/7z/rar)"
        printf "    $CYAN%-22s$R  %s\n" "-o, --overwrite"     "Overwrite existing files"
        printf "    $CYAN%-22s$R  %s\n" "-v, --verbose"       "Verbose extraction output"
        printf "    $CYAN%-22s$R  %s\n" "-q, --quiet"         "Suppress all output"
        printf "    $CYAN%-22s$R  %s\n" "-n, --dry-run"       "Preview without extracting"
        printf "    $CYAN%-22s$R  %s\n" "-h, --help"          "Show this help"
        echo ""
        echo "  $BOLD Supported Formats:$R"
        printf "    $DIM%-35s$R  %s\n" \
            ".tar .tar.gz .tgz .tar.bz2" "Tape archives" \
            ".tar.xz .txz .tar.zst .tzst" "Compressed tape archives" \
            ".tar.lz .tar.lzma .tar.lz4" "Compressed tape archives" \
            ".gz .bz2 .xz .zst .lz4 .lz" "Single-file compression" \
            ".zip .jar .war .ear .apk .ipa" "ZIP family" \
            ".7z .7zip" "7-Zip" \
            ".rar .cbr" "RAR archives" \
            ".deb .rpm" "Linux packages" \
            ".dmg .pkg .xar" "macOS packages" \
            ".iso .img" "Disk images" \
            ".cab .msi" "Windows packages" \
            ".zlib .lzo .snappy" "Low-level compression" \
            ".ar .a .deb" "AR archives" \
            ".cpio .shar" "Misc archives"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "extract archive.tar.gz                # Extract to ./archive/" \
            "extract archive.zip -d /tmp/out       # Extract to /tmp/out/" \
            "extract *.tar.gz                      # Batch extract all .tar.gz" \
            "extract archive.rar -l                # List contents only" \
            "extract archive.7z -p mypassword      # Extract with password" \
            "extract archive.tar.gz --flat         # No subdirectory wrapper" \
            "extract archive.zip --test            # Verify integrity"
        echo ""
    end

    # ── Parse args ────────────────────────────────────────────────────────────
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case -d --dest
                set _i (math $_i + 1)
                set _dest $argv[$_i]
            case -d=* --dest=*
                set _dest (string replace -r '^-d=|^--dest=' '' $arg)
            case -f --flat;       set _flat     1; set _into 0
            case -l --list;       set _list     1
            case -t --test;       set _test     1
            case -v --verbose;    set _verbose  1
            case -q --quiet;      set _quiet    1
            case -n --dry-run;    set _dry_run  1
            case -o --overwrite;  set _overwrite 1
            case -p --password
                set _i (math $_i + 1)
                set _password $argv[$_i]
            case -p=* --password=*
                set _password (string replace -r '^-p=|^--password=' '' $arg)
            case --help -h
                __extr_help; return 0
            case '*'
                set --append _files $arg
        end
        set _i (math $_i + 1)
    end

    if test (count $_files) -eq 0
        echo "  $RED✗$R  No archive files specified"
        return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 OUTPUT HELPERS                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __extr_ok --description "Print success"
        test $_quiet -eq 1 && return
        printf "  $GREEN✓$R  %s\n" $argv[1]
    end

    function __extr_fail --description "Print failure"
        printf "  $RED✗$R  %s\n" $argv[1] >&2
    end

    function __extr_info --description "Print info"
        test $_quiet -eq 1 && return
        printf "  $CYAN›$R  $DIM%s$R\n" $argv[1]
    end

    function __extr_warn --description "Print warning"
        test $_quiet -eq 1 && return
        printf "  $YELLOW⚠$R  %s\n" $argv[1]
    end

    # ── Spinner ────────────────────────────────────────────────────────────────
    set -l _spin "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
    set -l _sidx 1

    function __extr_spin_frame --description "Get spinner frame"
        set -l f $_spin[$_sidx]
        set -g _sidx (math ($_sidx % (count $_spin)) + 1)
        echo $f
    end

    # ── File size helper ───────────────────────────────────────────────────────
    function __extr_human_size --description "Human-readable file size"
        set -l bytes (du -b $argv[1] 2>/dev/null | awk '{print $1}')
        test -z "$bytes" && echo "?" && return
        if test $bytes -ge 1073741824
            math --scale 1 "$bytes / 1073741824" | read -l n; echo "$n GiB"
        else if test $bytes -ge 1048576
            math --scale 1 "$bytes / 1048576" | read -l n; echo "$n MiB"
        else if test $bytes -ge 1024
            math --scale 1 "$bytes / 1024" | read -l n; echo "$n KiB"
        else
            echo "$bytes B"
        end
    end

    # ── MIME type detector ─────────────────────────────────────────────────────
    function __extr_detect_type --description "Detect archive type from magic bytes"
        set -l f $argv[1]
        test -f $f || return 1

        # Try file command first (most accurate)
        if command -q file
            set -l mime (file --mime-type -b $f 2>/dev/null)
            echo $mime
            return
        end

        # Fallback: extension-based
        set -l ext (string lower (string match -r '\.[^.]+$' $f))
        echo "application/x-$ext"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📄 LIST CONTENTS                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __extr_list --description "List archive contents"
        set -l f $argv[1]
        set -l ext (string lower $f)

        switch $f
            case '*.tar' '*.tar.gz' '*.tgz' '*.tar.bz2' '*.tbz2' \
                 '*.tar.xz' '*.txz' '*.tar.zst' '*.tzst' \
                 '*.tar.lz' '*.tar.lzma' '*.tar.lz4'
                tar -tvf $f 2>/dev/null

            case '*.zip' '*.jar' '*.war' '*.ear' '*.apk' '*.ipa'
                if command -q unzip
                    unzip -l $f 2>/dev/null
                else
                    command -q python3 && python3 -m zipfile --list $f
                end

            case '*.7z' '*.7zip'
                command -q 7z   && 7z l $f
                command -q 7zz  && 7zz l $f

            case '*.rar' '*.cbr'
                command -q unrar && unrar l $f
                command -q rar   && rar l $f

            case '*.deb'
                command -q dpkg && dpkg --contents $f

            case '*.rpm'
                command -q rpm && rpm -qlp $f

            case '*.iso'
                command -q isoinfo && isoinfo -l -i $f

            case '*.gz'
                command -q zcat && zcat -l $f

            case '*'
                command -q bsdtar && bsdtar -tvf $f
                or tar -tvf $f 2>/dev/null
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔬 INTEGRITY TEST                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __extr_test --description "Test archive integrity"
        set -l f $argv[1]

        switch $f
            case '*.tar*' '*.tgz' '*.tbz2' '*.txz' '*.tzst'
                tar -tf $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"

            case '*.zip' '*.jar' '*.war' '*.apk'
                command -q unzip && begin
                    unzip -t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"
                end

            case '*.7z'
                command -q 7z && begin
                    7z t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"
                end

            case '*.rar'
                command -q unrar && begin
                    unrar t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"
                end

            case '*.gz'
                gzip -t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"

            case '*.bz2'
                bzip2 -t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"

            case '*.xz'
                xz -t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"

            case '*.zst'
                command -q zstd && begin
                    zstd -t $f >/dev/null 2>&1; and echo "OK" || echo "CORRUPT"
                end

            case '*'
                echo "UNKNOWN"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📦 CORE EXTRACTION ENGINE                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __extr_one --description "Extract a single archive"
        set -l f    $argv[1]
        set -l dest $argv[2]

        # Verbose flags
        set -l vflag ""
        test $_verbose -eq 1 && set vflag "v"

        # Check file exists
        if not test -f $f
            __extr_fail "File not found: $f"
            return 1
        end

        # Destination
        set -l extract_to $dest
        if test -z "$extract_to"
            if test $_flat -eq 1
                set extract_to "."
            else
                # Named after archive (strip all extensions)
                set -l basename (basename $f)
                set -l stem $basename
                for ext in .tar.gz .tar.bz2 .tar.xz .tar.zst .tar.lz .tar.lzma \
                            .tar.lz4 .tgz .tbz2 .txz .tzst .tar
                    set stem (string replace "$ext" "" $stem)
                end
                # Strip single extension if still has one
                set stem (string replace -r '\.[^.]+$' '' $stem)
                set extract_to $stem
            end
        end

        # Create destination
        if test $_dry_run -eq 0
            mkdir -p $extract_to 2>/dev/null
        else
            __extr_info "DRY-RUN: would create: $extract_to/"
        end

        # Password option
        set -l pwflag ""
        test -n "$_password" && set pwflag "-p$_password"

        # Overwrite
        set -l owflag ""
        test $_overwrite -eq 1 && set owflag "--overwrite"

        # ── Format dispatch ────────────────────────────────────────────────────
        set -l extracted 0

        switch (string lower $f)

            # ── tar family ────────────────────────────────────────────────────
            case '*.tar'
                set -l cmd "tar -x"$vflag"f '$f' -C '$extract_to'"
                test $_dry_run -eq 1 && __extr_info "DRY: $cmd" && return 0
                eval $cmd 2>/dev/null && set extracted 1

            case '*.tar.gz' '*.tgz'
                set -l cmd "tar -x${vflag}zf '$f' -C '$extract_to'"
                test $_dry_run -eq 1 && __extr_info "DRY: $cmd" && return 0
                eval $cmd 2>/dev/null && set extracted 1

            case '*.tar.bz2' '*.tbz' '*.tbz2'
                set -l cmd "tar -x${vflag}jf '$f' -C '$extract_to'"
                test $_dry_run -eq 1 && __extr_info "DRY: $cmd" && return 0
                eval $cmd 2>/dev/null && set extracted 1

            case '*.tar.xz' '*.txz'
                set -l cmd "tar -x${vflag}Jf '$f' -C '$extract_to'"
                test $_dry_run -eq 1 && __extr_info "DRY: $cmd" && return 0
                eval $cmd 2>/dev/null && set extracted 1

            case '*.tar.zst' '*.tzst'
                if command -q zstd
                    test $_dry_run -eq 1 && __extr_info "DRY: tar --zstd -x${vflag}f" && return 0
                    tar --zstd -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "zstd not installed"
                    return 1
                end

            case '*.tar.lz' '*.tlz'
                test $_dry_run -eq 1 && __extr_info "DRY: tar --lzip" && return 0
                tar --lzip -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1

            case '*.tar.lzma' '*.tlzma'
                test $_dry_run -eq 1 && __extr_info "DRY: tar --lzma" && return 0
                tar --lzma -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1

            case '*.tar.lz4' '*.tlz4'
                if command -q lz4
                    test $_dry_run -eq 1 && __extr_info "DRY: lz4 | tar" && return 0
                    lz4 -dc $f | tar -x${vflag}f - -C $extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "lz4 not installed"
                    return 1
                end

            case '*.tar.br' '*.tbr'
                if command -q brotli
                    test $_dry_run -eq 1 && __extr_info "DRY: brotli | tar" && return 0
                    brotli -dc $f | tar -x${vflag}f - -C $extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "brotli not installed"
                    return 1
                end

            # ── Single-file compression ────────────────────────────────────────
            case '*.gz'
                set -l out "$extract_to/"(basename $f .gz)
                test $_dry_run -eq 1 && __extr_info "DRY: gunzip → $out" && return 0
                gunzip -c $f > $out 2>/dev/null && set extracted 1

            case '*.bz2'
                set -l out "$extract_to/"(basename $f .bz2)
                test $_dry_run -eq 1 && __extr_info "DRY: bunzip2 → $out" && return 0
                bunzip2 -c $f > $out 2>/dev/null && set extracted 1

            case '*.xz'
                set -l out "$extract_to/"(basename $f .xz)
                test $_dry_run -eq 1 && __extr_info "DRY: xz -d → $out" && return 0
                xz -dc $f > $out 2>/dev/null && set extracted 1

            case '*.zst'
                set -l out "$extract_to/"(basename $f .zst)
                test $_dry_run -eq 1 && __extr_info "DRY: zstd -d → $out" && return 0
                command -q zstd && zstd -dc $f > $out 2>/dev/null && set extracted 1

            case '*.lz4'
                set -l out "$extract_to/"(basename $f .lz4)
                test $_dry_run -eq 1 && __extr_info "DRY: lz4 -d → $out" && return 0
                command -q lz4 && lz4 -dc $f > $out 2>/dev/null && set extracted 1

            case '*.lz'
                set -l out "$extract_to/"(basename $f .lz)
                test $_dry_run -eq 1 && __extr_info "DRY: lzip -d → $out" && return 0
                command -q lzip && lzip -dc $f > $out 2>/dev/null && set extracted 1

            case '*.br'
                set -l out "$extract_to/"(basename $f .br)
                test $_dry_run -eq 1 && __extr_info "DRY: brotli -d → $out" && return 0
                command -q brotli && brotli -dc $f > $out 2>/dev/null && set extracted 1

            case '*.Z'
                set -l out "$extract_to/"(basename $f .Z)
                test $_dry_run -eq 1 && __extr_info "DRY: uncompress → $out" && return 0
                uncompress -c $f > $out 2>/dev/null && set extracted 1

            case '*.zlib'
                set -l out "$extract_to/"(basename $f .zlib)
                test $_dry_run -eq 1 && __extr_info "DRY: python inflate → $out" && return 0
                command -q python3 && \
                    python3 -c "
import zlib, sys
with open('$f','rb') as i, open('$out','wb') as o:
    o.write(zlib.decompress(i.read()))
" 2>/dev/null && set extracted 1

            # ── ZIP family ────────────────────────────────────────────────────
            case '*.zip' '*.jar' '*.war' '*.ear' '*.apk' '*.ipa' '*.xpi' '*.crx'
                if command -q unzip
                    set -l unzip_args "-q"
                    test $_verbose  -eq 1 && set unzip_args ""
                    test $_overwrite -eq 1 && set unzip_args "$unzip_args -o"
                    test -n "$_password" && set unzip_args "$unzip_args -P '$_password'"
                    test $_dry_run -eq 1 && __extr_info "DRY: unzip $unzip_args '$f' -d '$extract_to'" && return 0
                    eval "unzip $unzip_args '$f' -d '$extract_to'" 2>/dev/null && set extracted 1
                else if command -q python3
                    test $_dry_run -eq 1 && __extr_info "DRY: python3 -m zipfile -e" && return 0
                    python3 -m zipfile -e $f $extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "unzip or python3 required"
                    return 1
                end

            # ── 7-Zip ─────────────────────────────────────────────────────────
            case '*.7z' '*.7zip'
                set -l exe ""
                command -q 7z  && set exe 7z
                command -q 7zz && set exe 7zz
                if test -z "$exe"
                    __extr_fail "7z or 7zz not installed"
                    return 1
                end
                set -l args "e -o'$extract_to'"
                test $_verbose  -eq 0 && set args "$args -bso0 -bsp0"
                test $_overwrite -eq 1 && set args "$args -aoa"
                test -n "$_password" && set args "$args -p'$_password'"
                test $_dry_run -eq 1 && __extr_info "DRY: $exe x $args '$f'" && return 0
                eval "$exe x $args '$f'" 2>/dev/null && set extracted 1

            # ── RAR ───────────────────────────────────────────────────────────
            case '*.rar' '*.cbr'
                if command -q unrar
                    set -l args "x -idq"
                    test $_verbose  -eq 1 && set args "x"
                    test -n "$_password" && set args "$args -p'$_password'"
                    test $_dry_run -eq 1 && __extr_info "DRY: unrar $args '$f' '$extract_to/'" && return 0
                    eval "unrar $args '$f' '$extract_to/'" 2>/dev/null && set extracted 1
                else if command -q rar
                    test $_dry_run -eq 1 && __extr_info "DRY: rar x '$f' '$extract_to/'" && return 0
                    rar x $f $extract_to/ 2>/dev/null && set extracted 1
                else if command -q bsdtar
                    test $_dry_run -eq 1 && __extr_info "DRY: bsdtar -xf" && return 0
                    bsdtar -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "unrar, rar, or bsdtar required for RAR files"
                    return 1
                end

            # ── Linux packages ────────────────────────────────────────────────
            case '*.deb'
                test $_dry_run -eq 1 && __extr_info "DRY: dpkg-deb -x" && return 0
                if command -q dpkg-deb
                    dpkg-deb -x $f $extract_to 2>/dev/null && set extracted 1
                else if command -q ar
                    cd $extract_to 2>/dev/null && ar x (realpath $f) 2>/dev/null
                    for subpkg in data.tar*
                        test -f $subpkg && tar -xf $subpkg 2>/dev/null && rm -f $subpkg
                    end
                    cd - >/dev/null && set extracted 1
                else
                    __extr_fail "dpkg-deb or ar required for .deb"
                    return 1
                end

            case '*.rpm'
                test $_dry_run -eq 1 && __extr_info "DRY: rpm2cpio | cpio" && return 0
                if command -q rpm2cpio && command -q cpio
                    rpm2cpio $f | cpio -idm${vflag} --directory=$extract_to 2>/dev/null
                    and set extracted 1
                else if command -q bsdtar
                    bsdtar -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "rpm2cpio + cpio or bsdtar required for .rpm"
                    return 1
                end

            # ── macOS packages ─────────────────────────────────────────────────
            case '*.dmg'
                test $_dry_run -eq 1 && __extr_info "DRY: hdiutil/7z extract" && return 0
                if command -q hdiutil
                    set -l mount_pt (mktemp -d)
                    hdiutil attach -quiet -mountpoint $mount_pt $f 2>/dev/null
                    cp -r $mount_pt/. $extract_to/ 2>/dev/null
                    hdiutil detach -quiet $mount_pt 2>/dev/null
                    rmdir $mount_pt 2>/dev/null
                    set extracted 1
                else if command -q 7z
                    7z x $f -o$extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "hdiutil (macOS) or 7z required for .dmg"
                    return 1
                end

            case '*.pkg' '*.xar'
                test $_dry_run -eq 1 && __extr_info "DRY: xar -xf" && return 0
                command -q xar && xar -xf $f -C $extract_to 2>/dev/null && set extracted 1
                or begin; __extr_fail "xar not installed"; return 1; end

            # ── ISO / disk images ──────────────────────────────────────────────
            case '*.iso' '*.img'
                test $_dry_run -eq 1 && __extr_info "DRY: 7z / bsdtar extract" && return 0
                if command -q 7z
                    7z x $f -o$extract_to 2>/dev/null && set extracted 1
                else if command -q bsdtar
                    bsdtar -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1
                else if command -q isoinfo
                    __extr_warn "isoinfo only lists — use 7z or bsdtar for extraction"
                    return 1
                else
                    __extr_fail "7z or bsdtar required for ISO/IMG"
                    return 1
                end

            # ── Windows packages ───────────────────────────────────────────────
            case '*.cab'
                test $_dry_run -eq 1 && __extr_info "DRY: cabextract / 7z" && return 0
                if command -q cabextract
                    cabextract -d $extract_to $f 2>/dev/null && set extracted 1
                else if command -q 7z
                    7z x $f -o$extract_to 2>/dev/null && set extracted 1
                else
                    __extr_fail "cabextract or 7z required for .cab"
                    return 1
                end

            case '*.msi'
                test $_dry_run -eq 1 && __extr_info "DRY: 7z extract" && return 0
                command -q 7z && 7z x $f -o$extract_to 2>/dev/null && set extracted 1
                or begin; __extr_fail "7z required for .msi"; return 1; end

            # ── AR / CPIO ─────────────────────────────────────────────────────
            case '*.a' '*.ar'
                test $_dry_run -eq 1 && __extr_info "DRY: ar x" && return 0
                command -q ar || begin; __extr_fail "ar not installed"; return 1; end
                cd $extract_to 2>/dev/null && ar x (realpath $f) 2>/dev/null
                cd - >/dev/null && set extracted 1

            case '*.cpio'
                test $_dry_run -eq 1 && __extr_info "DRY: cpio -idm" && return 0
                command -q cpio || begin; __extr_fail "cpio not installed"; return 1; end
                cpio -idm${vflag} < $f --directory=$extract_to 2>/dev/null && set extracted 1

            # ── Fallback: bsdtar (handles many formats) ────────────────────────
            case '*'
                test $_dry_run -eq 1 && __extr_info "DRY: bsdtar / tar -xf" && return 0
                if command -q bsdtar
                    bsdtar -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1
                else
                    tar -x${vflag}f $f -C $extract_to 2>/dev/null && set extracted 1
                end
        end

        return (test $extracted -eq 1 && echo 0 || echo 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MAIN DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _total   (count $_files)
    set -l _success 0
    set -l _failed  0
    set -l _ts_start (date +%s)

    # Banner
    if test $_quiet -eq 0
        printf "\n"
        if test $_list -eq 1
            printf "  $BOLD$CYAN📋 Listing archive contents$R\n"
        else if test $_test -eq 1
            printf "  $BOLD$CYAN🔬 Testing archive integrity$R\n"
        else
            printf "  $BOLD$CYAN📦 Extracting %d archive(s)$R\n" $_total
        end
        printf "\n"
    end

    for f in $_files

        # Resolve absolute path
        set -l abs_f (realpath $f 2>/dev/null; or echo $f)

        if not test -f $abs_f
            __extr_fail "Not found: $f"
            set _failed (math $_failed + 1)
            continue
        end

        set -l size (__extr_human_size $abs_f)
        set -l base (basename $f)

        # ── LIST MODE ─────────────────────────────────────────────────────────
        if test $_list -eq 1
            printf "  $BOLD$BLUE📄 %s$R  $DIM(%s)$R\n\n" $base $size
            __extr_list $abs_f
            printf "\n"
            continue
        end

        # ── TEST MODE ─────────────────────────────────────────────────────────
        if test $_test -eq 1
            printf "  $CYAN🔬$R  %-40s  $DIM(%s)$R  " $base $size
            set -l result (__extr_test $abs_f)
            if test "$result" = OK
                printf "$GREEN%s$R\n" $result
                set _success (math $_success + 1)
            else
                printf "$RED%s$R\n" $result
                set _failed (math $_failed + 1)
            end
            continue
        end

        # ── EXTRACT MODE ──────────────────────────────────────────────────────
        printf "  $CYAN📦$R  $BOLD%-38s$R  $DIM%s$R\n" \
            (string sub --length 38 $base) $size

        set -l ts (date +%s)

        __extr_one $abs_f $_dest
        set -l rc $status

        set -l elapsed (math (date +%s) - $ts)

        if test $rc -eq 0
            # Count extracted files
            set -l out_dir $_dest
            if test -z "$out_dir"
                set out_dir (string replace -r '\.(tar\.(gz|bz2|xz|zst|lz|lzma|lz4|br)|tgz|tbz2|txz|tzst|gz|bz2|xz|zst|lz4|lz|zip|7z|rar|jar|deb|rpm|iso|img|cab|tar)$' '' (basename $abs_f) | string replace -r '\.[^.]+$' '')
            end

            set -l file_count 0
            test -d "$out_dir" && \
                set file_count (find $out_dir -type f 2>/dev/null | wc -l | string trim)

            printf "     $GREEN✓$R  → $CYAN%s/$R  $DIM(%d files, %ds)$R\n" \
                $out_dir $file_count $elapsed
            set _success (math $_success + 1)
        else
            printf "     $RED✗$R  Extraction failed $DIM(%ds)$R\n" $elapsed
            set _failed (math $_failed + 1)
        end
    end

    # ── Summary ────────────────────────────────────────────────────────────────
    if test $_list -eq 0 && test $_quiet -eq 0
        set -l elapsed (math (date +%s) - $_ts_start)
        printf "\n"
        printf "  $DIM%s$R\n" (string repeat -n 50 "─")

        if test $_test -eq 1
            printf "  $BOLD%s$R  $GREEN%d passed$R  " "" $_success
            test $_failed -gt 0 && printf "$RED%d failed$R  " $_failed
        else if test $_total -gt 1
            printf "  $BOLD%d archive(s)$R  $GREEN%d extracted$R  " $_total $_success
            test $_failed -gt 0 && printf "$RED%d failed$R  " $_failed
        end

        test $_total -gt 0 && printf "$DIM⏱ %ds$R" $elapsed
        printf "\n\n"
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __extr_help __extr_ok __extr_fail __extr_info __extr_warn \
        __extr_spin_frame __extr_human_size __extr_detect_type \
        __extr_list __extr_test __extr_one 2>/dev/null
    set --erase _spin _sidx 2>/dev/null

    return (test $_failed -eq 0 && echo 0 || echo 1)

end
