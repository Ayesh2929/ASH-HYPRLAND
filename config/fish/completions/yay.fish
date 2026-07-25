# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📦  YAY — FISH COMPLETIONS v5.0 OMEGA                                     ║
# ║  Ultra Premium • AUR Helper • Smart Context • Dynamic Package Data         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guards ─────────────────────────────────────────────────────────────────────
function __yay_no_operation
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            -S -Sy -Su -Syu -Syuu -Ss -Si -Sl -Sg -Sc -Scc \
            -R -Rs -Rn -Rns -Ru -Rcns \
            -Q -Qi -Ql -Qo -Qp -Qu -Qs -Qm -Qn -Qe -Qd -Qt \
            -U -Uf \
            -D -Dq \
            -G \
            -h --help --version -V \
            -P --show \
            -Y --yay \
            --sync --remove --query --upgrade --database --getpkgbuild \
            --deptest --files --stats --gendb
            return 1
        end
    end
    return 0
end

function __yay_op_is
    test -n "$argv[1]"; or return 1
    set -l tokens (commandline -poc)
    contains -- "$argv[1]" $tokens
end

function __yay_flag_is
    set -l tokens (commandline -poc)
    for t in $tokens
        if contains -- "$t" $argv
            return 0
        end
    end
    return 1
end

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC PACKAGE DATA
# ══════════════════════════════════════════════════════════════════════════════

function __yay_installed
    pacman -Qq 2>/dev/null
end

function __yay_installed_desc
    pacman -Qq 2>/dev/null | while read -l p
        set -l d (pacman -Qi "$p" 2>/dev/null | awk -F': ' '/^Description/{print $2; exit}')
        printf "%s\t%s\n" "$p" "$d"
    end
end

function __yay_explicit
    pacman -Qqe 2>/dev/null
end

function __yay_orphans
    pacman -Qqdt 2>/dev/null
end

function __yay_aur
    pacman -Qqm 2>/dev/null
end

function __yay_upgradeable
    yay -Qu 2>/dev/null | awk '{print $1"\t"$2" → "$4}'
end

function __yay_groups
    pacman -Sg 2>/dev/null | sort -u
end

function __yay_local_pkgs
    ls *.pkg.tar.* 2>/dev/null
    ls *.pkg.tar   2>/dev/null
end

# ── Search AUR (cached) ────────────────────────────────────────────────────────
function __yay_aur_search --argument-names term
    if test -n "$term"
        yay -Sl aur 2>/dev/null | awk '{print $2}' | grep -i -- "$term" | head -50
    else
        pacman -Qqm 2>/dev/null
    end
end

# ══════════════════════════════════════════════════════════════════════════════
#  OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -f -n __yay_no_operation -a \
    "-S\t📦 Sync/install packages" \
    "-Sy\t🔄 Sync databases" \
    "-Su\t⬆️  System upgrade" \
    "-Syu\t🔄 Sync & full upgrade" \
    "-Syuu\t⬆️  Sync + allow downgrade" \
    "-Ss\t🔍 Search packages (repo + AUR)" \
    "-Si\t📖 Show package info" \
    "-Sl\t📋 List repo packages" \
    "-Sg\t📦 List/install package groups" \
    "-Sc\t🧹 Clean package cache" \
    "-Scc\t🧹 Purge all caches" \
    "-R\t🗑️  Remove package" \
    "-Rs\t🗑️  Remove + unneeded dependencies" \
    "-Rn\t🗑️  Remove + saved configs" \
    "-Rns\t🗑️  Remove + deps + configs" \
    "-Q\t🔍 Query installed packages" \
    "-Qi\t📖 Installed package info" \
    "-Ql\t📋 List package files" \
    "-Qo\t🔍 Find package owning file" \
    "-Qu\t⬆️  List upgradeable packages" \
    "-Qs\t🔍 Search installed packages" \
    "-Qm\t🌐 List AUR/foreign packages" \
    "-Qn\t📦 List native repo packages" \
    "-Qe\t📦 List explicitly installed" \
    "-Qd\t🔗 List dependency installs" \
    "-Qt\t🗑️  List unneeded deps (orphans)" \
    "-Qp\t📖 Query a .pkg.tar file" \
    "-U\t⬆️  Upgrade from local .pkg.tar" \
    "-D\t🏷️  Modify install reason" \
    "-G\t📜 Get PKGBUILD from AUR" \
    "-P\t📊 Print yay config/stats" \
    "-Y\t⚙️  Yay-specific options" \
    "--stats\t📊 Show package statistics" \
    "--gendb\t🗄️  Generate AUR database" \
    "-V\t📌 Show version" \
    "-h\t❓ Help" \
    "--help\t❓ Help" \
    "--version\t📌 Version"

# ══════════════════════════════════════════════════════════════════════════════
#  SYNC OPERATION (-S)
# ══════════════════════════════════════════════════════════════════════════════

# -S: package completions from repo + AUR
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -f -k -a "(yay -Sl 2>/dev/null | awk '{print \$2\"\t\"\$4}' | head -200)"

# Standard sync flags
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -s y -l refresh      -d "Refresh package databases"         -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -s u -l sysupgrade   -d "Upgrade all packages"              -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -s s -l search       -d "Search packages"                   -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -s i -l info         -d "View package info (extra: -ii)"    -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -s l -l list         -d "List packages in repo"             -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -s g -l groups       -d "View package groups"               -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -s c -l clean        -d "Clean package cache"               -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -s p -l print        -d "Print targets (no install)"        -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -l needed            -d "Skip up-to-date packages"          -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -l asexplicit        -d "Mark as explicitly installed"      -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -l asdeps            -d "Mark as dependency"                -f
complete -c yay -n "__yay_op_is -S; or __yay_op_is --sync" \
    -l overwrite         -d "Overwrite conflicting files"       -f

# ── Yay-specific AUR flags ─────────────────────────────────────────────────────
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l devel             -d "Include -git/-svn devel packages"  -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l timeupdate        -d "Update devel on time difference"   -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l nodevel           -d "Exclude devel packages"            -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l rebuild           -d "Rebuild AUR packages"              -f \
    -a "no\tDefault yes\tRebuild all PKGBUILDS only\tIf PKGBUILD changed"
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l redownload        -d "Re-download PKGBUILD"              -f \
    -a "no\tDefault yes\tAll all\tAll + dependencies"
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l sudoloop          -d "Keep sudo alive during build"      -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l nosudoloop        -d "Don't loop sudo"                   -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l cleanmenu         -d "Clean ask before build"            -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l nocleanmenu       -d "Don't ask to clean"                -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l diffmenu          -d "Show diff menu"                    -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l nodiffmenu        -d "Don't show diff menu"              -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l editmenu          -d "Show edit menu"                    -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l noeditmebu        -d "Don't show edit menu"              -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l askremovemake     -d "Ask to remove makedeps"            -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l removemake        -d "Remove makedeps after install"     -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l noremovemake      -d "Keep makedeps after install"       -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l pgpfetch          -d "Auto-fetch PGP keys"               -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l nopgpfetch        -d "Don't fetch PGP keys"              -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l useask            -d "Use --ask flag for pacman"         -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l combinedupgrade   -d "Combine official + AUR upgrade"    -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l batchinstall      -d "Batch AUR installs"                -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l nocheck           -d "Skip check() in PKGBUILD"          -f
complete -c yay -n "__yay_op_is -S -Sy -Su -Syu; or __yay_op_is --sync" \
    -l develsuffix       -d "Suffix for devel packages"         -f

# Filter by source
complete -c yay -n "__yay_op_is -S -Ss -Si -Sl; or __yay_op_is --sync" \
    -l repo              -d "Limit to official repos only"      -f
complete -c yay -n "__yay_op_is -S -Ss -Si -Sl; or __yay_op_is --sync" \
    -l aur               -d "Limit to AUR only"                 -f

# ══════════════════════════════════════════════════════════════════════════════
#  REMOVE OPERATION (-R)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -R -Rs -Rn -Rns; or __yay_op_is --remove" \
    -f -k -a "(__yay_installed)"

complete -c yay -n "__yay_op_is -R -Rs -Rn -Rns; or __yay_op_is --remove" \
    -s s -l recursive    -d "Remove unneeded dependencies"      -f
complete -c yay -n "__yay_op_is -R -Rs -Rn -Rns; or __yay_op_is --remove" \
    -s n -l nosave       -d "Remove config files"               -f
complete -c yay -n "__yay_op_is -R; or __yay_op_is --remove" \
    -s u -l unneeded     -d "Remove only if not required"       -f
complete -c yay -n "__yay_op_is -R; or __yay_op_is --remove" \
    -s c -l cascade      -d "Remove all dependent packages"     -f
complete -c yay -n "__yay_op_is -R; or __yay_op_is --remove" \
    -s p -l print        -d "Dry run: show targets"             -f

# ══════════════════════════════════════════════════════════════════════════════
#  QUERY OPERATION (-Q)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -Q -Qi -Ql -Qu -Qs -Qm -Qn -Qe -Qd -Qt; or __yay_op_is --query" \
    -f -k -a "(__yay_installed)"

complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s i -l info         -d "Package info (-ii for extended)"   -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s l -l list         -d "List package files"                -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s o -l owns         -d "Find owning package"               -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s p -l file         -d "Query package file"                -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s u -l upgrades     -d "List upgradeable"                  -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s s -l search       -d "Search installed"                  -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s m -l foreign      -d "List foreign (AUR) packages"       -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s n -l native       -d "List native packages"              -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s e -l explicit     -d "List explicitly installed"         -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s d -l deps         -d "List dep-installed"                -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s t -l unrequired   -d "List unrequired packages"          -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s g -l groups       -d "Filter by package group"           -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s k -l check        -d "Verify package integrity"          -f
complete -c yay -n "__yay_op_is -Q; or __yay_op_is --query" \
    -s q -l quiet        -d "Quiet output (names only)"         -f

# -Qo: file completions
complete -c yay -n "__yay_op_is -Qo; or (__yay_op_is -Q; and __yay_flag_is -o --owns)" \
    -F

# -Qp: local pkg files
complete -c yay -n "__yay_op_is -Qp; or (__yay_op_is -Q; and __yay_flag_is -p --file)" \
    -f -a "(__yay_local_pkgs)"

# ══════════════════════════════════════════════════════════════════════════════
#  UPGRADE OPERATION (-U)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -U -Uf; or __yay_op_is --upgrade" \
    -F

complete -c yay -n "__yay_op_is -U -Uf; or __yay_op_is --upgrade" \
    -l asexplicit -d "Mark as explicit"    -f
complete -c yay -n "__yay_op_is -U -Uf; or __yay_op_is --upgrade" \
    -l asdeps     -d "Mark as dep"        -f
complete -c yay -n "__yay_op_is -U -Uf; or __yay_op_is --upgrade" \
    -l needed     -d "Skip if up to date" -f

# ══════════════════════════════════════════════════════════════════════════════
#  DATABASE OPERATION (-D)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -D; or __yay_op_is --database" \
    -f -k -a "(__yay_installed)"

complete -c yay -n "__yay_op_is -D; or __yay_op_is --database" \
    -l asexplicit -d "Mark as explicit" -f
complete -c yay -n "__yay_op_is -D; or __yay_op_is --database" \
    -l asdeps     -d "Mark as dep"      -f
complete -c yay -n "__yay_op_is -D; or __yay_op_is --database" \
    -s k -l check -d "Check database"   -f
complete -c yay -n "__yay_op_is -D; or __yay_op_is --database" \
    -s q -l quiet -d "Quiet output"     -f

# ══════════════════════════════════════════════════════════════════════════════
#  GET PKGBUILD (-G)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -G; or __yay_op_is --getpkgbuild" \
    -f -k -a "(__yay_aur)"

complete -c yay -n "__yay_op_is -G; or __yay_op_is --getpkgbuild" \
    -s f -l force    -d "Overwrite existing"      -f
complete -c yay -n "__yay_op_is -G; or __yay_op_is --getpkgbuild" \
    -l git           -d "Clone from git"          -f
complete -c yay -n "__yay_op_is -G; or __yay_op_is --getpkgbuild" \
    -l gitflags      -d "Extra git flags"         -f

# ══════════════════════════════════════════════════════════════════════════════
#  PRINT / SHOW OPERATION (-P)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s c -l complete  -d "Print completion info"      -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s d -l defaultconfig -d "Print default config"   -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s g -l currentconfig -d "Print current config"   -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s n -l numberupgrades -d "Print number of upgrades" -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s s -l stats     -d "Print package statistics"   -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s q -l quiet     -d "Quiet output"               -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s u -l upgrades  -d "Print upgrade count"        -f
complete -c yay -n "__yay_op_is -P; or __yay_op_is --show" \
    -s w -l news      -d "Print AUR news"             -f

# ══════════════════════════════════════════════════════════════════════════════
#  YAY OPTIONS (-Y)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -s c -l clean       -d "Remove unneeded deps"          -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l gendb             -d "Generate development package DB" -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l editmenu          -d "Show PKGBUILD edit menu"      -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l noeditmebu        -d "No PKGBUILD edit menu"        -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l diffmenu          -d "Show diff menu"               -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l nodiffmenu        -d "No diff menu"                 -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l cleanmenu         -d "Show clean menu"              -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l nocleanmenu       -d "No clean menu"                -f
complete -c yay -n "__yay_op_is -Y; or __yay_op_is --yay" \
    -l save              -d "Save config to file"          -f

# ══════════════════════════════════════════════════════════════════════════════
#  GLOBAL FLAGS (all operations)
# ══════════════════════════════════════════════════════════════════════════════

complete -c yay \
    -l noconfirm         -d "Skip confirmation prompts"     -f
complete -c yay \
    -l confirm           -d "Always ask for confirmation"   -f
complete -c yay \
    -l noprogressbar     -d "Disable progress bar"          -f
complete -c yay \
    -l ask               -d "Pre-answer with bitmask"       -f
complete -c yay \
    -l noscriptlet       -d "Skip install scripts"          -f
complete -c yay \
    -l dbpath            -d "Alternate database path"       -F
complete -c yay \
    -l root              -d "Alternate install root"        -F
complete -c yay \
    -l cachedir          -d "Alternate cache directory"     -F
complete -c yay \
    -l logfile           -d "Alternate log file"            -F
complete -c yay \
    -l gpgdir            -d "Alternate GPG directory"       -F
complete -c yay \
    -l hookdir           -d "Alternate hook directory"      -F
complete -c yay \
    -l color             -d "Colorized output" -f \
    -a "always\tAlways auto\tAuto never\tNever"
complete -c yay \
    -l debug             -d "Enable debug output"           -f
complete -c yay \
    -l verbose           -d "Verbose output"                -f
complete -c yay \
    -l arch              -d "Target architecture"           -f \
    -a "x86_64 aarch64 armv7h i686"

# ── Yay-specific global ────────────────────────────────────────────────────────
complete -c yay \
    -l aururl            -d "Custom AUR URL"                -f
complete -c yay \
    -l aurrpcurl         -d "Custom AUR RPC URL"            -f
complete -c yay \
    -l builddir          -d "Build directory"               -F
complete -c yay \
    -l editor            -d "PKGBUILD editor"               -f \
    -a "nvim\tNeovim vim\tVim nano\tNano helix\tHelix code\tVSCode"
complete -c yay \
    -l editorflags       -d "Extra editor flags"            -f
complete -c yay \
    -l makepkg           -d "Makepkg command"               -f
complete -c yay \
    -l makepkgconf       -d "Custom makepkg.conf"           -F
complete -c yay \
    -l mflags            -d "Extra makepkg flags"           -f
complete -c yay \
    -l gpgflags          -d "Extra GPG flags"               -f
complete -c yay \
    -l pacman            -d "Pacman command"                -f
complete -c yay \
    -l tar               -d "Tar command"                   -f
complete -c yay \
    -l git               -d "Git command"                   -f
complete -c yay \
    -l gpg               -d "GPG command"                   -f
complete -c yay \
    -l sudo              -d "Sudo command"                  -f \
    -a "sudo\tSystem sudo doas\tOpenBSD doas run0\tSystemd run0"
complete -c yay \
    -l sudoflags         -d "Extra sudo flags"              -f
complete -c yay \
    -l sortby            -d "Sort AUR results by"           -f \
    -a "votes\tVote count popularity\tPopularity name\tName updated\tLast updated"
complete -c yay \
    -l searchby          -d "Search AUR by field"           -f \
    -a "name\tPackage name name-desc\tName+Description maintainer\tMaintainer depends\tDependencies provides\tProvides submitter\tSubmitter"
complete -c yay \
    -l limit             -d "Limit number of results"       -f
complete -c yay \
    -l topdown           -d "Show results top-down"         -f
complete -c yay \
    -l bottomup          -d "Show results bottom-up"        -f
complete -c yay \
    -l requestsplitn     -d "AUR request split size"        -f
complete -c yay \
    -l completioninterval -d "Completion cache refresh interval" -f
complete -c yay \
    -l answerclean       -d "Pre-answer clean question"     -f \
    -a "None\tAsk yes\tYes no\tNo"
complete -c yay \
    -l answerdiff        -d "Pre-answer diff question"      -f \
    -a "None\tAsk yes\tYes no\tNo"
complete -c yay \
    -l answeredit        -d "Pre-answer edit question"      -f \
    -a "None\tAsk yes\tYes no\tNo"
complete -c yay \
    -l answerupgrade     -d "Pre-answer upgrade question"   -f \
    -a "None\tAsk all\tAll none\tNone"
