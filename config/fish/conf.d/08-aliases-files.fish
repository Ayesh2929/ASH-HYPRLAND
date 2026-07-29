#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗██╗     ███████╗     █████╗ ██╗     ██╗ █████╗ ███████╗███████╗    ║
# ║  ██╔════╝██║██║     ██╔════╝    ██╔══██╗██║     ██║██╔══██╗██╔════╝██╔════╝    ║
# ║  █████╗  ██║██║     █████╗      ███████║██║     ██║███████║███████╗█████╗      ║
# ║  ██╔══╝  ██║██║     ██╔══╝      ██╔══██║██║     ██║██╔══██║╚════██║██╔══╝      ║
# ║  ██║     ██║███████╗███████╗    ██║  ██║███████╗██║██║  ██║███████║███████╗    ║
# ║  ╚═╝     ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ║
# ║                                                                                  ║
# ║   📁 FILE MANAGEMENT ALIASES — ASH Dotfiles v5.0 OMEGA                         ║
# ║   Navigation • Archives • Permissions • Hashing • Media • Text Processing       ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_aliases_files_initialized && exit 0
set -g __ash_aliases_files_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧭 NAVIGATION — Smart directory traversal
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Directory shortcuts ───────────────────────────────────────────────────────
alias ..      "cd .."
alias ...     "cd ../.."
alias ....    "cd ../../.."
alias .....   "cd ../../../.."
alias ......  "cd ../../../../.."
alias -- -    "cd -"
alias back    "cd -"
alias prev    "cd -"

# ── XDG quick-jump ────────────────────────────────────────────────────────────
alias cdconf  "cd $XDG_CONFIG_HOME"
alias cddata  "cd $XDG_DATA_HOME"
alias cdcache "cd $XDG_CACHE_HOME"
alias cdstate "cd $XDG_STATE_HOME"
alias cddl    "cd $XDG_DOWNLOAD_DIR"
alias cddoc   "cd $XDG_DOCUMENTS_DIR"
alias cdpic   "cd $XDG_PICTURES_DIR"
alias cdvid   "cd $XDG_VIDEOS_DIR"
alias cdmus   "cd $XDG_MUSIC_DIR"
alias cddesk  "cd $XDG_DESKTOP_DIR"

# ── ASH quick-jump ────────────────────────────────────────────────────────────
alias cdash   "cd $ASH_HOME"
alias cdashc  "cd $ASH_CONFIG"
alias cdasht  "cd $ASH_THEMES"
alias cdashp  "cd $ASH_PLUGINS"
alias cdashs  "cd $ASH_SNAPSHOTS"
alias cdashl  "cd $ASH_LOGS"

# ── Config dirs quick-jump ────────────────────────────────────────────────────
alias cdhypr  "cd $XDG_CONFIG_HOME/hypr"
alias cdnvim  "cd $XDG_CONFIG_HOME/nvim"
alias cdfish  "cd $XDG_CONFIG_HOME/fish"
alias cdway   "cd $XDG_CONFIG_HOME/waybar"
alias cdrofi  "cd $XDG_CONFIG_HOME/rofi"
alias cdkitty "cd $XDG_CONFIG_HOME/kitty"

# ── Smart mkdir + cd ──────────────────────────────────────────────────────────
alias mkcd    "mkdir --parents --verbose (string join ' ' $argv) && cd (string join ' ' $argv)"
alias take    "mkdir --parents --verbose $argv && cd $argv"

# ── Repo root jump ────────────────────────────────────────────────────────────
alias groot   "cd (git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias cdgit   "groot"

# ── Recent directories (requires zoxide) ─────────────────────────────────────
command -sq zoxide && begin
    alias j     "cd"                               # zoxide wraps cd already
    alias ji    "zi"                               # Interactive zoxide
    alias jl    "zoxide query --list \
                   --score \
                 | head -20"                       # Top 20 frecent dirs
    alias jclean "zoxide clean"                    # Remove stale entries
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 FILE OPERATIONS — Copy, move, delete with safety
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Core operations (safety-first) ───────────────────────────────────────────
alias cp      "cp \
                 --interactive \
                 --verbose \
                 --preserve=all"
alias mv      "mv \
                 --interactive \
                 --verbose"
alias rm      "rm \
                 --interactive=once \
                 --verbose"
alias ln      "ln \
                 --interactive \
                 --verbose"
alias mkdir   "mkdir \
                 --parents \
                 --verbose"
alias rmdir   "rmdir \
                 --verbose"
alias touch   "touch \
                 --verbose 2>/dev/null \
               || command touch"

# ── Copy with progress (rsync-powered) ───────────────────────────────────────
if command -sq rsync
    alias cpr     "rsync \
                     --archive \
                     --verbose \
                     --progress \
                     --human-readable \
                     --partial"                    # Resumable copy
    alias cprf    "rsync \
                     --archive \
                     --verbose \
                     --progress \
                     --human-readable \
                     --partial \
                     --delete"                     # Mirror (delete dest extras)
    alias cpd     "rsync \
                     --archive \
                     --verbose \
                     --progress \
                     --human-readable \
                     --dry-run"                    # Preview copy
else
    alias cpr     "cp \
                     --recursive \
                     --interactive \
                     --verbose \
                     --preserve=all"
end

# ── Batch rename (perl rename / mmv) ─────────────────────────────────────────
command -sq rename && begin
    alias ren     "rename \
                     --verbose"
    alias renn    "rename \
                     --verbose \
                     --no-act"                     # Dry-run rename
end

# ── Secure delete ─────────────────────────────────────────────────────────────
command -sq shred && begin
    alias shred   "shred \
                     --verbose \
                     --random-source=/dev/urandom \
                     --iterations=3 \
                     --remove"
    alias wipe    "shred"
end

# ── Trash (safer rm) ─────────────────────────────────────────────────────────
command -sq trash-put && begin
    alias del     "trash-put"
    alias undelete "trash-restore"
    alias trashls "trash-list"
    alias trashempty "trash-empty"
    alias trashsize "du -sh ~/.local/share/Trash 2>/dev/null \
                      || du -sh ~/.Trash 2>/dev/null"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 PERMISSIONS — chmod, chown, ACL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── chmod shortcuts ───────────────────────────────────────────────────────────
alias chmod    "chmod \
                  --verbose"
alias chownv   "chown \
                  --verbose"
alias chgrp    "chgrp \
                  --verbose"

# Common permission patterns
alias chmox    "chmod \
                  --verbose \
                  +x"                              # Make executable
alias chmod755 "chmod \
                  --verbose \
                  755"                             # rwxr-xr-x
alias chmod644 "chmod \
                  --verbose \
                  644"                             # rw-r--r--
alias chmod600 "chmod \
                  --verbose \
                  600"                             # rw------- (private files)
alias chmod700 "chmod \
                  --verbose \
                  700"                             # rwx------ (private dirs)
alias chmod400 "chmod \
                  --verbose \
                  400"                             # r-------- (read-only)
alias chmod777 "chmod \
                  --verbose \
                  777"                             # ⚠️  rwxrwxrwx (dangerous)

# Recursive permission fixes
alias fixperms-dirs  "find . -type d -exec chmod 755 {} +"
alias fixperms-files "find . -type f -exec chmod 644 {} +"
alias fixperms-exec  "find . -type f -name '*.sh' -exec chmod 755 {} +"
alias fixperms-all   "fixperms-dirs && fixperms-files"
alias fixperms-ssh   "chmod 700 ~/.ssh && \
                      chmod 600 ~/.ssh/id_* 2>/dev/null && \
                      chmod 644 ~/.ssh/*.pub 2>/dev/null && \
                      chmod 644 ~/.ssh/authorized_keys 2>/dev/null && \
                      chmod 644 ~/.ssh/known_hosts 2>/dev/null && \
                      echo '✓ SSH permissions fixed'"
alias fixperms-gpg   "chmod 700 $GNUPGHOME && \
                      find $GNUPGHOME -type f -exec chmod 600 {} + && \
                      echo '✓ GPG permissions fixed'"

# Permission inspection
alias lsperms  "stat \
                  --format='%A %a %U:%G %n'"
alias lsperms2 "ls \
                  --numeric-uid-gid \
                  -la"

# Find world-writable files (security audit)
alias findworld "find . \
                   -type f \
                   -perm -o+w \
                   -not -path './.git/*'"
alias findsuid  "find / \
                   -perm /4000 \
                   -type f \
                   2>/dev/null"
alias findsgid  "find / \
                   -perm /2000 \
                   -type f \
                   2>/dev/null"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔗 SYMLINKS — Create, inspect, repair
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias lns      "ln \
                  --symbolic \
                  --verbose"
alias lnsf     "ln \
                  --symbolic \
                  --force \
                  --verbose"
alias lnsr     "ln \
                  --symbolic \
                  --relative \
                  --verbose"                       # Relative symlink
alias readlink "readlink \
                  --canonicalize"                  # Resolve full path
alias rlink    "readlink \
                  --canonicalize"

# Find broken symlinks
alias brokenlinks "find . \
                     -type l \
                     -not -follow \
                     -print \
                     2>/dev/null"
alias fixlinks  "find . \
                   -type l \
                   -not -follow \
                   -delete \
                   2>/dev/null && \
                 echo '✓ Broken symlinks removed'"

# List all symlinks
alias lslinks  "find . \
                  -maxdepth 3 \
                  -type l \
                  -exec ls -la {} +"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 ARCHIVE & COMPRESSION — Unified interface
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── ouch (universal archive tool) ────────────────────────────────────────────
if command -sq ouch
    alias extract  "ouch decompress"
    alias compress "ouch compress"
    alias lsarch   "ouch list"
    alias peek     "ouch list"                     # Peek inside archive

    # Format-specific compress helpers
    alias mktar    "ouch compress $argv --format tar.gz"
    alias mkzip    "ouch compress $argv --format zip"
    alias mkzst    "ouch compress $argv --format tar.zst"
    alias mkbz2    "ouch compress $argv --format tar.bz2"
    alias mkxz     "ouch compress $argv --format tar.xz"
    alias mk7z     "ouch compress $argv --format 7z"

else
    # ── tar fallback ──────────────────────────────────────────────────────────
    alias extract  "_ash_extract"                  # fish function in functions/
    alias mktar    "tar --create \
                      --gzip \
                      --verbose \
                      --file"
    alias mktarbz2 "tar --create \
                      --bzip2 \
                      --verbose \
                      --file"
    alias mktarxz  "tar --create \
                      --xz \
                      --verbose \
                      --file"
    alias lsarch   "tar --list \
                      --verbose \
                      --file"
end

# ── tar shortcuts ─────────────────────────────────────────────────────────────
alias tarcreate "tar \
                   --create \
                   --gzip \
                   --verbose \
                   --file"
alias tarextract "tar \
                    --extract \
                    --verbose \
                    --file"
alias tarlist   "tar \
                   --list \
                   --verbose \
                   --file"
alias tarpeek   "tar \
                   --list \
                   --file"                         # Quick list (no verbose)

# ── zip shortcuts ─────────────────────────────────────────────────────────────
command -sq zip && begin
    alias mkzip    "zip \
                      --recurse-paths \
                      --verbose"
    alias mknzip   "zip \
                      --recurse-paths \
                      --verbose \
                      --encrypt"                   # Encrypted zip
    alias zipls    "unzip \
                      --list"
    alias unzipv   "unzip \
                      --verbose"
end

# ── zstd (fastest compression) ───────────────────────────────────────────────
command -sq zstd && begin
    alias mkcmp    "zstd \
                      --compress \
                      --ultra \
                      --level=22"                  # Maximum compression
    alias mkzst    "tar \
                      --create \
                      --use-compress-program=zstd \
                      --verbose \
                      --file"
    alias extzst   "tar \
                      --extract \
                      --use-compress-program=zstd \
                      --verbose \
                      --file"
end

# ── Archive inspection ────────────────────────────────────────────────────────
alias zipinfo  "zipinfo -v 2>/dev/null || unzip -v"

# Archive size comparison helper
alias compstats "echo 'Compression ratio for current directory:' && \
                 du -sh . | awk '{print \"Original: \"\$1}' && \
                 tar -czf /tmp/.ash_comptest.tgz . 2>/dev/null && \
                 du -sh /tmp/.ash_comptest.tgz | awk '{print \"gzip:     \"\$1}' && \
                 rm /tmp/.ash_comptest.tgz"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 HASHING & CHECKSUMS — Verify integrity
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Hash generation ───────────────────────────────────────────────────────────
alias md5      "md5sum"
alias sha1     "sha1sum"
alias sha256   "sha256sum"
alias sha512   "sha512sum"
alias sha3     "sha3-256sum 2>/dev/null || rhash \
                  --sha3-256"
alias b2sum    "b2sum"                             # BLAKE2

# Hash & compare (file vs. expected)
alias md5check   "md5sum \
                    --check"
alias sha1check  "sha1sum \
                    --check"
alias sha256check "sha256sum \
                     --check"
alias sha512check "sha512sum \
                     --check"

# Quick file hash (just the hash, no filename)
alias md5q     "md5sum $argv | awk '{print \$1}'"
alias sha256q  "sha256sum $argv | awk '{print \$1}'"
alias sha512q  "sha512sum $argv | awk '{print \$1}'"

# Hash a string directly
alias hashstr  "echo -n $argv | sha256sum | awk '{print \$1}'"

# ── rhash (multi-algorithm) ───────────────────────────────────────────────────
command -sq rhash && begin
    alias rhash    "rhash \
                      --all"                       # All hashes at once
    alias rhashv   "rhash \
                      --verify"
    alias magnet   "rhash \
                      --magnet"                    # Magnet link from file
end

# ── Certificate fingerprints ──────────────────────────────────────────────────
alias certfp   "openssl x509 \
                  --noout \
                  --fingerprint \
                  --sha256 \
                  --in"

# GPG hash
command -sq gpg && begin
    alias gpgverify "gpg \
                       --verify"
    alias gpgkeys   "gpg \
                       --list-keys"
    alias gpgskeys  "gpg \
                       --list-secret-keys"
    alias gpgimport "gpg \
                       --import"
    alias gpgexport "gpg \
                       --export \
                       --armor"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 FILE INSPECTION — Type, content, metadata
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── File type & info ──────────────────────────────────────────────────────────
alias filetype "file \
                  --brief \
                  --mime-type"
alias filemime "file \
                  --mime-type \
                  --mime-encoding"
alias fileinfo "file \
                  --brief \
                  --dereference"                   # Follow symlinks
alias xattr    "getfattr \
                  --dump \
                  --no-dereference 2>/dev/null \
                || xattr -l 2>/dev/null \
                || lsattr"                         # Extended attributes

# stat (detailed file info)
alias stat     "stat \
                  --format='
  📄 File    : %n
  📏 Size    : %s bytes (%b blocks)
  🔐 Perms   : %A (%a)
  👤 Owner   : %U (%u)
  👥 Group   : %G (%g)
  📅 Access  : %x
  📅 Modify  : %y
  📅 Change  : %z
  🔗 Inode   : %i
  🔗 Links   : %h'"

# ── Content inspection ────────────────────────────────────────────────────────
# Hex dump
alias hex      "xxd"
alias hexdump  "xxd"
alias hd       "hexd ump \
                  --canonical"
command -sq hexyl && \
    alias hex "hexyl"                              # Beautiful hex viewer

# String extraction
alias strings  "strings \
                  --all \
                  --encoding=s"

# Binary check
alias isbinary "file \
                  --brief \
                  --mime-encoding $argv \
                | grep -q binary \
                && echo '🔴 Binary' \
                || echo '🟢 Text'"

# Word/line/char count
alias wc       "wc \
                  --lines \
                  --words \
                  --chars"
alias wcl      "wc --lines"
alias wcw      "wc --words"
alias wcc      "wc --bytes"

# ── Image metadata (exiftool) ─────────────────────────────────────────────────
command -sq exiftool && begin
    alias exif    "exiftool \
                     --printConv"
    alias exifgps "exiftool \
                     -GPSLatitude \
                     -GPSLongitude \
                     -GPSAltitude"
    alias exifdate "exiftool \
                     -DateTimeOriginal \
                     -CreateDate \
                     -FileModifyDate"
    alias exifstrip "exiftool \
                      -all= \
                      --verbose"                   # Strip ALL metadata
end

# ── Media info ────────────────────────────────────────────────────────────────
command -sq mediainfo && begin
    alias minfo   "mediainfo"
    alias minfov  "mediainfo \
                     --Full"
    alias minfoj  "mediainfo \
                     --Output=JSON \
                   | jq"
end

command -sq ffprobe && begin
    alias ffinfo  "ffprobe \
                     -v quiet \
                     -print_format json \
                     -show_format \
                     -show_streams \
                   | jq"
    alias ffcodec "ffprobe \
                     -v quiet \
                     -show_streams \
                     -select_streams v:0 \
                   | grep codec_name"
end

# ── PDF inspection ────────────────────────────────────────────────────────────
command -sq pdfinfo && begin
    alias pdfinfo  "pdfinfo"
    alias pdfpages "pdfinfo $argv \
                    | grep Pages"
end

command -sq pdftotext && begin
    alias pdftxt   "pdftotext \
                      -layout"                     # Extract text preserving layout
    alias pdfgrep  "pdfgrep \
                      --recursive \
                      --ignore-case"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔎 FIND & SEARCH — fd, rg, locate
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── fd (fast find) ────────────────────────────────────────────────────────────
if command -sq fd
    alias fdf      "fd --type f"                   # Files only
    alias fdd      "fd --type d"                   # Dirs only
    alias fdl      "fd --type l"                   # Symlinks
    alias fdx      "fd --type x"                   # Executables
    alias fde      "fd --extension"                # By extension
    alias fda      "fd --hidden --no-ignore"       # Find all (everything)
    alias fdlarge  "fd --type f --size +100M"      # Files > 100MB
    alias fdrecent "fd --type f --changed-within=1d"  # Modified last 24h
    alias fdold    "fd --type f --changed-before=30d" # Not modified in 30d
    alias fdempty  "fd --type f --size 0"          # Empty files
    alias fdemptyd "fd --type d --empty"           # Empty dirs
    alias fdtmp    "fd --type f --extension tmp \
                      --extension log \
                      --extension bak"             # Temp/junk files
    alias fddup    "fdupes \
                      --recursive \
                      --size \
                      . 2>/dev/null \
                    || echo 'Install fdupes for duplicate finding'"

else
    # ── GNU find fallback ─────────────────────────────────────────────────────
    alias fdf      "find . -type f"
    alias fdd      "find . -type d"
    alias fdl      "find . -type l"
    alias fde      "find . -name '*.\$argv[1]'"
    alias fda      "find . -not -path '*/.git/*'"
    alias fdlarge  "find . -type f -size +100M \
                      -exec ls -lh {} + \
                    | sort -k5 -hr"
    alias fdrecent "find . -type f -mtime -1"
    alias fdempty  "find . -type f -empty"
    alias fdemptyd "find . -type d -empty"
end

# ── locate (fast index-based search) ─────────────────────────────────────────
command -sq plocate || command -sq locate && begin
    alias loc      "plocate 2>/dev/null || locate"
    alias locupd   "sudo updatedb"                 # Update locate index
end

# ── Duplicate finder ──────────────────────────────────────────────────────────
command -sq fdupes && begin
    alias dupes    "fdupes \
                      --recursive \
                      --size \
                      --order=name"
    alias dupesrm  "fdupes \
                      --recursive \
                      --delete \
                      --noprompt"                  # ⚠️  Auto-remove duplicates
end

command -sq rmlint && begin
    alias finddupes "rmlint \
                       --types=duplicates \
                       --output=sh:./rmlint.sh"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖼️  IMAGE PROCESSING — ImageMagick, ffmpeg
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq magick || command -sq convert
    set -l __img_cmd (command -sq magick && echo "magick" || echo "convert")

    # Image conversion
    alias img2jpg  "$__img_cmd \
                      -quality 85 \
                      -strip"                      # Convert to JPEG
    alias img2png  "$__img_cmd \
                      -strip"                      # Convert to PNG
    alias img2webp "$__img_cmd \
                      -quality 85 \
                      -strip"                      # Convert to WebP
    alias img2avif "$__img_cmd \
                      -quality 80 \
                      -strip"                      # Convert to AVIF

    # Image resize
    alias imgresize "$__img_cmd \
                       -resize"                    # imgresize img.jpg 1920x1080 out.jpg
    alias imgthumb  "$__img_cmd \
                       -thumbnail \
                       200x200 \
                       -gravity center \
                       -extent 200x200"

    # Image info
    alias imginfo   "$__img_cmd identify \
                       -verbose 2>/dev/null \
                    || magick identify -verbose"
    alias imgsize   "$__img_cmd identify \
                       -format '%wx%h\n'"

    # Image optimization
    alias imgopt    "$__img_cmd \
                       -strip \
                       -quality 85 \
                       -interlace Plane"           # Progressive JPEG

    # Strip metadata (privacy)
    alias imgstrip  "$__img_cmd \
                       -strip"

    set -e __img_cmd
end

# ── pngquant / jpegoptim ──────────────────────────────────────────────────────
command -sq pngquant && \
    alias pngopt   "pngquant \
                      --force \
                      --strip \
                      --quality=70-90 \
                      --speed=1"

command -sq jpegoptim && \
    alias jpgopt   "jpegoptim \
                      --strip-all \
                      --max=85"

# ── ffmpeg shortcuts ──────────────────────────────────────────────────────────
if command -sq ffmpeg
    alias ff       "ffmpeg"
    alias ffinfo   "ffprobe -v quiet -show_format -show_streams"
    alias ff2mp4   "ffmpeg -i $argv[1] -c:v libx264 -crf 23 -c:a aac -b:a 192k"
    alias ff2gif   "ffmpeg -i $argv[1] -vf 'fps=15,scale=640:-1:flags=lanczos' \
                      -c:v gif"
    alias ff2webm  "ffmpeg -i $argv[1] -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus"
    alias ffcompress "ffmpeg -i $argv[1] -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2' \
                       -c:v libx264 -crf 28 -preset slow -c:a aac -b:a 128k"
    alias fftrim   "ffmpeg -ss $argv[1] -to $argv[2] -i $argv[3] -c copy"
    alias ffextract "ffmpeg -i $argv[1] -vn -acodec copy"   # Extract audio
    alias ffscreenshot "ffmpeg -i $argv[1] -vframes 1 -q:v 2"
    alias ffwallpaper "ffmpeg -i $argv[1] -q:v 1 -vframes 1 \
                         $ASH_WALLPAPERS_DIR/(basename $argv[1] | \
                         string replace -r '\.[^.]+\$' '.jpg')"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 TEXT PROCESSING — sed, awk, sort, jq, yq
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── sed shortcuts ─────────────────────────────────────────────────────────────
alias sedi     "sed \
                  --in-place"                      # In-place edit
alias sedib    "sed \
                  --in-place=.bak"                 # In-place with backup
alias sedstrip "sed \
                  --regexp-extended \
                  's/\x1b\[[0-9;]*m//g'"           # Strip ANSI color codes

# ── awk shortcuts ─────────────────────────────────────────────────────────────
alias awkf1    "awk '{print \$1}'"                 # Print field 1
alias awkf2    "awk '{print \$2}'"                 # Print field 2
alias awkf3    "awk '{print \$3}'"                 # Print field 3
alias awkfl    "awk '{print \$NF}'"                # Print last field
alias awksum   "awk '{sum += \$1} END {print sum}'" # Sum a column
alias awkavg   "awk '{sum += \$1} END {print sum/NR}'" # Average a column

# ── sort / uniq shortcuts ─────────────────────────────────────────────────────
alias sortnum  "sort \
                  --numeric-sort"
alias sortrev  "sort \
                  --reverse"
alias sorthum  "sort \
                  --human-numeric-sort"             # Sort human sizes (1K, 2M)
alias sortuniq "sort \
                  --unique"                         # Sort + deduplicate
alias dupes    "sort | uniq -d"                    # Show duplicates
alias uniqc    "sort | uniq -c | sort -rn"         # Count occurrences

# ── jq (JSON) ─────────────────────────────────────────────────────────────────
if command -sq jq
    alias jq       "jq \
                      --color-output"
    alias jqpp     "jq '.'"                        # Pretty-print JSON
    alias jqc      "jq \
                      --compact-output"            # Compact JSON
    alias jqkeys   "jq 'keys'"                     # JSON object keys
    alias jqlen    "jq 'length'"                   # Array/object length
    alias jqflat   "jq '[.. | scalars]'"           # Flatten all values
    alias jsonfix  "jq '.' < $argv \
                      > /tmp/fixed.json && \
                    mv /tmp/fixed.json $argv"      # Fix & format JSON file
    alias jsondiff "diff \
                      <(jq -S . $argv[1]) \
                      <(jq -S . $argv[2])"         # Semantic JSON diff
end

# ── yq (YAML/TOML/XML) ───────────────────────────────────────────────────────
command -sq yq && begin
    alias yqpp     "yq eval . \
                      --prettyPrint"               # Pretty-print YAML
    alias yaml2json "yq eval \
                       --output-format=json"       # YAML → JSON
    alias json2yaml "yq eval \
                       --input-format=json \
                       --output-format=yaml"       # JSON → YAML
    alias toml2yaml "yq eval \
                       --input-format=toml"        # TOML → YAML
end

# ── csvkit ────────────────────────────────────────────────────────────────────
command -sq csvkit && begin
    alias csvview  "csvlook \
                      --max-rows 50"               # Tabular CSV view
    alias csvjson  "csvjson \
                      --indentation 2"             # CSV → JSON
    alias csvsql   "csvsql"                        # SQL on CSV files
    alias csvstat  "csvstat"                        # CSV statistics
    alias csvgrep  "csvgrep \
                      --no-blanks"
    alias csvcut   "csvcut"                         # Extract columns
end

# ── Misc text tools ───────────────────────────────────────────────────────────
alias linecount  "wc -l"
alias stripblank 'grep --invert-match '\''^[[:space:]]*$'\'''              # Remove blank lines
alias stripdups  'awk '\''!seen[$0]++'\'''             # Remove duplicate lines
alias trimws     'sed '\''s/^[[:space:]]*//;s/[[:space:]]*$//'\'''  # Trim whitespace
alias dos2unix   "sed --in-place 's/\r//'"        # Convert line endings
alias unix2dos   'sed --in-place '\''s/$/\r/'\'''       # Convert line endings
alias nl         "nl \
                    --number-all \
                    --number-format=rz"            # Number lines
alias tac        "tac"                             # Reverse file (last line first)
alias shuf       "shuf"                            # Shuffle lines randomly
alias cols       "column \
                    --table \
                    --separator=\t"                # Tabular output
alias colscsv    "column \
                    --table \
                    --separator=,"                 # CSV tabular


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💾 DISK MANAGEMENT — Mount, format, partition
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias mount    "mount \
                  --verbose"
alias umount   "umount \
                  --verbose"
alias mounts   "mount \
                | column --table"                  # Pretty-print mounts
alias dfu      "df \
                  --human-readable \
                  --print-type \
                | column --table"                  # Disk usage formatted

alias lsblk    "lsblk \
                  --output NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS,UUID,LABEL"
alias lsblkj   "lsblk \
                  --json \
                  --output-all \
                | jq"

alias blkid    "sudo blkid \
                  --output=list"

# USB mounting helper
alias mountusb "udisksctl mount \
                  --block-device"
alias umountusb "udisksctl unmount \
                   --block-device"
alias ejectusb  "udisksctl power-off \
                   --block-device"

# SMART disk health
command -sq smartctl && begin
    alias diskhealth "sudo smartctl \
                        --health \
                        --info"
    alias disktest   "sudo smartctl \
                        --test=short"
    alias disklog    "sudo smartctl \
                        --log=error"
end

# Disk benchmark
command -sq fio && begin
    alias diskbench "fio \
                       --name=benchmark \
                       --rw=randrw \
                       --rwmixread=70 \
                       --bs=4k \
                       --numjobs=4 \
                       --size=1G \
                       --runtime=30 \
                       --group_reporting"
end

# dd with progress
alias ddp      "dd \
                  bs=64K \
                  conv=noerror,sync \
                  status=progress"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📂 DOTFILES — Quick access to ASH dotfiles configs
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dotfiles "cd (git -C $ASH_HOME rev-parse \
                    --show-toplevel 2>/dev/null \
                  || echo $ASH_HOME)"
alias dotedit  "nvim $ASH_HOME"
alias dotsync  "ash cloud sync-up && \
                echo '✓ Dotfiles synced'"
alias dotpull  "ash cloud sync-down && \
                exec fish"
alias dotdiff  "git -C $ASH_HOME diff"
alias dotstatus "git -C $ASH_HOME status --short"
alias dotlog   "git -C $ASH_HOME log \
                  --oneline \
                  --graph \
                  -20"
alias dotsnap  "ash snapshot create && \
                echo '✓ Dotfiles snapshot created'"
alias dotrestore "ash snapshot restore"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP — Temporary & cache files
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias cleanpyc  "find . -type f -name '*.pyc' -delete && \
                 find . -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null && \
                 echo '✓ Python cache cleaned'"

alias cleands   "find . -type f -name '.DS_Store' -delete && \
                 echo '✓ .DS_Store files removed'"

alias cleanlog  "find $ASH_LOGS -type f -name '*.log' \
                   -mtime +30 -delete && \
                 echo '✓ Old logs (30d+) cleaned'"

alias cleancache "rm -rf $XDG_CACHE_HOME/pip \
                          $XDG_CACHE_HOME/npm \
                          $XDG_CACHE_HOME/go \
                          $XDG_CACHE_HOME/cargo && \
                  echo '✓ Package caches cleaned'"

alias cleantmp  "find /tmp -user $USER \
                   -mtime +1 \
                   -delete \
                   2>/dev/null && \
                 echo '✓ /tmp cleaned'"

alias cleanash  "ash cache clean && \
                 echo '✓ ASH cache cleaned'"

# Full cleanup
alias cleanall  "cleanpyc && cleands && cleanlog && cleantmp && \
                 echo '✓ Full cleanup complete'"