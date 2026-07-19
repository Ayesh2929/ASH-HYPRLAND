# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — compress Ultra                                     ║
# ║  Universal archiver: smart format selection, progress, split & encryption  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function compress --description "Universal archive creator with smart format selection"

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

    set -l _output    ""   # output archive name
    set -l _format    ""   # format: tar.gz | zip | 7z | zst | bz2 | xz | rar
    set -l _sources       # files/dirs to compress
    set -l _level    6    # compression level 1-9 (or 1-22 for zst)
    set -l _password ""   # encryption password
    set -l _split    ""   # split size (e.g. 100m, 1g)
    set -l _verbose  0
    set -l _quiet    0
    set -l _dry_run  0
    set -l _no_hidden 0   # exclude hidden files
    set -l _exclude   ""  # exclude pattern
    set -l _encrypt  0
    set -l _fast     0    # fastest compression
    set -l _best     0    # best compression
    set -l _test     1    # test after creating (default on)
    set -l _no_test  0

    # ── Help ──────────────────────────────────────────────────────────────────
    function __cmp_help --description "Print compress help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🗜️   compress — Universal Archive Creator         ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  compress [options] -o <output> <sources...>"
        echo "          compress [options] <output.ext> <sources...>"
        echo ""
        echo "  $BOLD Format auto-detection:$R (from output file extension)"
        printf "    $CYAN%-20s$R  %s\n" \
            ".tar.gz / .tgz"     "gzip-compressed tar (default)" \
            ".tar.bz2 / .tbz2"  "bzip2-compressed tar (better ratio)" \
            ".tar.xz / .txz"    "xz-compressed tar (excellent ratio)" \
            ".tar.zst / .tzst"  "zstd-compressed tar (fast + good ratio)" \
            ".tar.lz4 / .tlz4"  "lz4-compressed tar (fastest)" \
            ".zip"               "ZIP archive (universal compat)" \
            ".7z"                "7-Zip (best compression)" \
            ".gz"                "gzip single file" \
            ".bz2"               "bzip2 single file" \
            ".xz"                "xz single file" \
            ".zst"               "zstd single file" \
            ".tar"               "uncompressed tar"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "-o, --output <file>" "Output archive filename" \
            "-f, --format <fmt>"  "Force format (tar.gz|zip|7z|zst|xz|bz2)" \
            "-l, --level <1-9>"   "Compression level (default: 6)" \
            "--fast"              "Fastest compression (level 1)" \
            "--best"              "Best compression (level 9/22)" \
            "-p, --password <pw>" "Encrypt archive with password" \
            "-s, --split <size>"  "Split into parts (e.g. 100m, 1g)" \
            "-x, --exclude <pat>" "Exclude files matching pattern" \
            "--no-hidden"         "Exclude hidden files/directories" \
            "--no-test"           "Skip integrity test after creation" \
            "-v, --verbose"       "Verbose output" \
            "-q, --quiet"         "Suppress all output" \
            "-n, --dry-run"       "Preview without creating"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "compress backup.tar.gz ~/projects/     # Compress directory" \
            "compress -o app.zip src/ tests/        # ZIP two directories" \
            "compress data.tar.zst --best ./data/   # Best ratio with zstd" \
            "compress logs.tar.gz /var/log/ --fast  # Fast compression" \
            "compress secure.7z -p mypass docs/     # Password-encrypted 7z" \
            "compress large.tar.gz -s 500m ~/data/  # Split into 500MB parts" \
            "compress -f xz output.xz file.txt      # Force xz format"
        echo ""
    end

    if test (count $argv) -eq 0; or contains -- --help $argv; or contains -- -h $argv
        __cmp_help
        return 0
    end

    # ── Parse args ────────────────────────────────────────────────────────────
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case -o --output
                set _i (math $_i + 1); set _output $argv[$_i]
            case -o=* --output=*
                set _output (string replace -r '^-o=|^--output=' '' $arg)
            case -f --format
                set _i (math $_i + 1); set _format $argv[$_i]
            case -f=* --format=*
                set _format (string replace -r '^-f=|^--format=' '' $arg)
            case -l --level
                set _i (math $_i + 1); set _level $argv[$_i]
            case -l=* --level=*
                set _level (string replace -r '^-l=|^--level=' '' $arg)
            case -p --password
                set _i (math $_i + 1); set _password $argv[$_i]; set _encrypt 1
            case -s --split
                set _i (math $_i + 1); set _split $argv[$_i]
            case -x --exclude
                set _i (math $_i + 1); set _exclude $argv[$_i]
            case --no-hidden;    set _no_hidden 1
            case --no-test;      set _no_test   1
            case --fast;         set _fast      1; set _level 1
            case --best;         set _best      1; set _level 9
            case -v --verbose;   set _verbose   1
            case -q --quiet;     set _quiet     1
            case -n --dry-run;   set _dry_run   1
            case --help -h;      __cmp_help; return 0
            case '*'
                # First non-flag could be output file (has an extension)
                if test -z "$_output" && string match -qr '\.[^/]+$' $arg && not test -e $arg
                    set _output $arg
                else
                    set --append _sources $arg
                end
        end
        set _i (math $_i + 1)
    end

    # ── Validate ──────────────────────────────────────────────────────────────
    if test -z "$_output"
        echo "  $RED✗$R  Output filename required (-o output.tar.gz)"
        return 1
    end

    if test (count $_sources) -eq 0
        echo "  $RED✗$R  No source files/directories specified"
        return 1
    end

    # Validate sources
    for src in $_sources
        if not test -e $src
            echo "  $RED✗$R  Source not found: $src"
            return 1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 OUTPUT HELPERS                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __cmp_ok   --description "Print ok"
        test $_quiet -eq 1 && return
        printf "  $GREEN✓$R  %s\n" $argv[1]
    end
    function __cmp_fail --description "Print fail"
        printf "  $RED✗$R  %s\n" $argv[1] >&2
    end
    function __cmp_info --description "Print info"
        test $_quiet -eq 1 && return
        printf "  $CYAN›$R  $DIM%s$R\n" $argv[1]
    end
    function __cmp_warn --description "Print warn"
        test $_quiet -eq 1 && return
        printf "  $YELLOW⚠$R  %s\n" $argv[1]
    end

    # ── Human-readable sizes ───────────────────────────────────────────────────
    function __cmp_human --description "Human-readable byte size"
        set -l b $argv[1]
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
    # ║  🔍 FORMAT DETECTION                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Auto-detect from output extension
    if test -z "$_format"
        set -l out_lower (string lower $_output)
        switch $out_lower
            case '*.tar.gz'  '*.tgz';   set _format "tar.gz"
            case '*.tar.bz2' '*.tbz2' '*.tbz'; set _format "tar.bz2"
            case '*.tar.xz'  '*.txz';   set _format "tar.xz"
            case '*.tar.zst' '*.tzst';  set _format "tar.zst"
            case '*.tar.lz4' '*.tlz4';  set _format "tar.lz4"
            case '*.tar.lz'  '*.tlz';   set _format "tar.lz"
            case '*.tar.br';             set _format "tar.br"
            case '*.tar';                set _format "tar"
            case '*.zip';                set _format "zip"
            case '*.7z' '*.7zip';        set _format "7z"
            case '*.rar';                set _format "rar"
            case '*.gz';                 set _format "gz"
            case '*.bz2';               set _format "bz2"
            case '*.xz';                set _format "xz"
            case '*.zst';               set _format "zst"
            case '*.lz4';               set _format "lz4"
            case '*'
                # Default to tar.gz
                set _format "tar.gz"
                set _output "$_output.tar.gz"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 PRE-COMPRESSION ANALYSIS                                            ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Calculate source size
    set -l src_bytes 0
    set -l src_files 0

    for src in $_sources
        set -l bytes (du -sb $src 2>/dev/null | awk '{print $1}')
        test -n "$bytes" && set src_bytes (math $src_bytes + $bytes)
        set -l fcount (find $src -type f 2>/dev/null | wc -l | string trim)
        set src_files (math $src_files + $fcount)
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    if test $_quiet -eq 0
        printf "\n"
        printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$PURPLE║  🗜️   Compressing → %-38s║$R\n" \
            (string sub --length 38 (basename $_output))
        printf "  $BOLD$PURPLE╠══════════════════════════════════════════════════════╣$R\n"
        printf "  $BOLD$PURPLE║$R  $BOLD%-12s$R  %-42s$PURPLE║$R\n" \
            "Format:" "$_format"
        printf "  $BOLD$PURPLE║$R  $BOLD%-12s$R  %-42s$PURPLE║$R\n" \
            "Sources:" (string join ', ' (basename --multiple $_sources) | string sub --length 42)
        printf "  $BOLD$PURPLE║$R  $BOLD%-12s$R  %-42s$PURPLE║$R\n" \
            "Input size:" (__cmp_human $src_bytes)" ($src_files files)"
        printf "  $BOLD$PURPLE║$R  $BOLD%-12s$R  %-42s$PURPLE║$R\n" \
            "Level:" "$_level"(test $_fast -eq 1 && echo " (fastest)" || test $_best -eq 1 && echo " (best)")
        test -n "$_password" && \
            printf "  $BOLD$PURPLE║$R  $BOLD%-12s$R  %-42s$PURPLE║$R\n" "Encrypted:" "yes (password set)"
        test -n "$_split" && \
            printf "  $BOLD$PURPLE║$R  $BOLD%-12s$R  %-42s$PURPLE║$R\n" "Split:" $_split
        printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n"
        printf "\n"
    end

    if test $_dry_run -eq 1
        __cmp_info "DRY-RUN: no files created"
        functions --erase __cmp_help __cmp_ok __cmp_fail __cmp_info __cmp_warn __cmp_human 2>/dev/null
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🗜️  COMPRESSION ENGINE                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _ts (date +%s)

    # ── Common tar flags ───────────────────────────────────────────────────────
    set -l _tar_verbose ""
    test $_verbose -eq 1 && set _tar_verbose "v"

    set -l _tar_exclude ""
    if test -n "$_exclude"
        set _tar_exclude "--exclude='$_exclude'"
    end
    if test $_no_hidden -eq 1
        set _tar_exclude "$_tar_exclude --exclude='.*'"
    end

    set -l _created 0

    switch $_format

        # ── tar.gz ────────────────────────────────────────────────────────────
        case tar.gz tgz
            set -l gzip_level (test $_best -eq 1 && echo "--best" || test $_fast -eq 1 && echo "--fast" || echo "-$_level")

            if command -q pigz
                # Parallel gzip (much faster on multi-core)
                eval "tar -$_tar_verbose""cf - $_tar_exclude $_sources | pigz $gzip_level > '$_output'" 2>/dev/null
                __cmp_info "Using pigz (parallel gzip)"
            else
                eval "tar -$_tar_verbose""czf '$_output' $_tar_exclude $_sources" 2>/dev/null
            end
            test $status -eq 0 && set _created 1

        # ── tar.bz2 ───────────────────────────────────────────────────────────
        case tar.bz2 tbz2 tbz
            if command -q pbzip2
                eval "tar -${_tar_verbose}cf - $\_tar_exclude $_sources | pbzip2 -$_level > '$_output'" 2>/dev/null
                __cmp_info "Using pbzip2 (parallel bzip2)"
            else
                eval "tar -${_tar_verbose}cjf '$_output' $\_tar_exclude $_sources" 2>/dev/null
            end
            test $status -eq 0 && set _created 1

        # ── tar.xz ────────────────────────────────────────────────────────────
        case tar.xz txz
            set -l xz_threads (nproc 2>/dev/null; or sysctl -n hw.logicalcpu 2>/dev/null; or echo 1)
            eval "tar -${_tar_verbose}cf - $\_tar_exclude $_sources | xz -$_level -T$xz_threads > '$_output'" 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── tar.zst ───────────────────────────────────────────────────────────
        case tar.zst tzst
            if not command -q zstd
                __cmp_fail "zstd not installed"
                return 1
            end
            # zstd level 1-22; map 1-9 to 1-22 range
            set -l zst_level $_level
            test $_best -eq 1 && set zst_level 22
            set -l zst_threads (nproc 2>/dev/null; or echo 4)

            eval "tar -${_tar_verbose}cf - $\_tar_exclude $_sources | zstd -$zst_level -T$zst_threads -o '$_output'" 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── tar.lz4 ───────────────────────────────────────────────────────────
        case tar.lz4 tlz4
            if not command -q lz4
                __cmp_fail "lz4 not installed"
                return 1
            end
            eval "tar -${_tar_verbose}cf - $\_tar_exclude $_sources | lz4 -$_level > '$_output'" 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── tar.lz ────────────────────────────────────────────────────────────
        case tar.lz tlz
            if not command -q lzip
                __cmp_fail "lzip not installed"
                return 1
            end
            eval "tar -${_tar_verbose}cf - $\_tar_exclude $_sources | lzip -$_level > '$_output'" 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── tar (uncompressed) ────────────────────────────────────────────────
        case tar
            eval "tar -${_tar_verbose}cf '$_output' $\_tar_exclude $_sources" 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── ZIP ───────────────────────────────────────────────────────────────
        case zip
            if command -q zip
                set -l zip_args "-$_level -r"
                test $_verbose  -eq 0 && set zip_args "$zip_args -q"
                test -n "$_password" && set zip_args "$zip_args --password '$_password'"
                test -n "$_exclude"  && set zip_args "$zip_args -x '$_exclude'"
                test $_no_hidden -eq 1 && set zip_args "$zip_args -x '*/.*'"
                eval "zip $zip_args '$_output' $_sources" 2>/dev/null
                test $status -eq 0 && set _created 1
            else if command -q python3
                python3 -c "
import zipfile, os, sys

archive = '$_output'
sources = '$_sources'.split()
level = $_level

with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=level) as zf:
    for src in sources:
        if os.path.isdir(src):
            for root, dirs, files in os.walk(src):
                for file in files:
                    fp = os.path.join(root, file)
                    zf.write(fp)
        else:
            zf.write(src)
print('Created:', archive)
" 2>/dev/null
                test $status -eq 0 && set _created 1
            else
                __cmp_fail "zip or python3 required for ZIP format"
                return 1
            end

        # ── 7-Zip ─────────────────────────────────────────────────────────────
        case 7z 7zip
            set -l exe ""
            command -q 7z  && set exe 7z
            command -q 7zz && set exe 7zz
            if test -z "$exe"
                __cmp_fail "7z or 7zz not installed"
                return 1
            end

            # 7z level: -mx=1 to -mx=9
            set -l args "a -mx=$_level"
            test $_verbose  -eq 0 && set args "$args -bso0 -bsp0"
            test -n "$_password" && set args "$args -mhe=on -p'$_password'"
            test -n "$_exclude"  && set args "$args -x!'$_exclude'"
            test $_split -eq 1 && test -n "$_split" && set args "$args -v$_split"

            eval "$exe $args '$_output' $_sources" 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── Single-file: gz ───────────────────────────────────────────────────
        case gz
            if test (count $_sources) -gt 1
                __cmp_warn "gz compresses a single file — using first source only"
            end
            if command -q pigz
                pigz -$_level -c $_sources[1] > $_output 2>/dev/null
            else
                gzip -$_level -c $_sources[1] > $_output 2>/dev/null
            end
            test $status -eq 0 && set _created 1

        # ── Single-file: bz2 ──────────────────────────────────────────────────
        case bz2
            bzip2 -$_level -c $_sources[1] > $_output 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── Single-file: xz ───────────────────────────────────────────────────
        case xz
            xz -$_level -c $_sources[1] > $_output 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── Single-file: zst ──────────────────────────────────────────────────
        case zst zstd
            command -q zstd || begin; __cmp_fail "zstd not installed"; return 1; end
            set -l zst_level (test $_best -eq 1 && echo 22 || echo $_level)
            zstd -$zst_level $_sources[1] -o $_output 2>/dev/null
            test $status -eq 0 && set _created 1

        # ── Single-file: lz4 ──────────────────────────────────────────────────
        case lz4
            command -q lz4 || begin; __cmp_fail "lz4 not installed"; return 1; end
            lz4 -$_level $_sources[1] $_output 2>/dev/null
            test $status -eq 0 && set _created 1

        case '*'
            __cmp_fail "Unknown format: $_format"
            functions --erase __cmp_help __cmp_ok __cmp_fail __cmp_info __cmp_warn __cmp_human 2>/dev/null
            return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 POST-COMPRESSION REPORT                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l elapsed (math (date +%s) - $_ts)

    if test $_created -eq 1
        set -l out_bytes (du -b $_output 2>/dev/null | awk '{print $1}'; or echo 0)
        set -l ratio 0
        test $src_bytes -gt 0 && \
            set ratio (math --scale 1 "$out_bytes * 100 / $src_bytes")
        set -l savings (math --scale 1 "100 - $ratio")

        printf "\n"
        printf "  $BOLD$GREEN╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$GREEN║  ✓  Compression Complete                             ║$R\n"
        printf "  $BOLD$GREEN╠══════════════════════════════════════════════════════╣$R\n"
        printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" \
            "Archive:" (string sub --length 40 $_output)
        printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" \
            "Original:" (__cmp_human $src_bytes)
        printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" \
            "Compressed:" (__cmp_human $out_bytes)
        printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  $CYAN%-40s$R$GREEN║$R\n" \
            "Ratio:" "$ratio% ($savings% space saved)"
        printf "  $BOLD$GREEN║$R  $BOLD%-14s$R  %-40s$GREEN║$R\n" \
            "Time:" "${elapsed}s"
        printf "  $BOLD$GREEN╚══════════════════════════════════════════════════════╝$R\n"
        printf "\n"

        # Integrity test
        if test $_no_test -eq 0
            printf "  $CYAN🔬$R  Verifying integrity... "
            set -l verify_ok 0
            switch $_format
                case 'tar*' 'tgz' 'tbz*' 'txz' 'tzst'
                    tar -tf $_output >/dev/null 2>&1 && set verify_ok 1
                case zip
                    command -q unzip && unzip -t $_output >/dev/null 2>&1 && set verify_ok 1
                    or command -q python3 && python3 -m zipfile --test $_output >/dev/null 2>&1 && set verify_ok 1
                case 7z
                    command -q 7z && 7z t $_output >/dev/null 2>&1 && set verify_ok 1
                case gz bz2 xz zst
                    test $verify_ok -eq 0
                    switch $_format
                        case gz;  gzip -t $_output 2>/dev/null && set verify_ok 1
                        case bz2; bzip2 -t $_output 2>/dev/null && set verify_ok 1
                        case xz;  xz -t $_output 2>/dev/null && set verify_ok 1
                        case zst; command -q zstd && zstd -t $_output 2>/dev/null && set verify_ok 1
                    end
                case '*'
                    set verify_ok 1  # Skip for unknown formats
            end

            if test $verify_ok -eq 1
                printf "$GREEN✓ OK$R\n\n"
            else
                printf "$RED✗ FAILED$R\n"
                __cmp_warn "Archive may be corrupt — check: $_output"
                printf "\n"
            end
        end

        # List split parts if splitting was used
        if test -n "$_split"
            printf "  $BOLD Split parts:$R\n"
            ls -lh ${_output}.* 2>/dev/null | while read -l line
                printf "    $DIM%s$R\n" $line
            end
            printf "\n"
        end

    else
        printf "\n  $RED✗$R  Compression failed after $elapsed""s\n"
        printf "  $DIM  Check for: missing tools, permissions, disk space$R\n\n"
        functions --erase __cmp_help __cmp_ok __cmp_fail __cmp_info __cmp_warn __cmp_human 2>/dev/null
        return 1
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __cmp_help __cmp_ok __cmp_fail __cmp_info __cmp_warn __cmp_human 2>/dev/null
    return 0

end
