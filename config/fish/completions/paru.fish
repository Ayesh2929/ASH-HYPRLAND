# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📦  PARU — FISH COMPLETIONS v5.0 OMEGA                                    ║
# ║  Ultra Premium • AUR + Pacman • Dynamic Package Lists • Smart Context      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guards ─────────────────────────────────────────────────────────────────────
function __paru_no_operation
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            -S -Sy -Su -Syu -Syuu -Ss -Si -Sl -Sg -Sc -Scc \
            -R -Rs -Rn -Rns -Ru -Rcns \
            -Q -Qi -Ql -Qo -Qp -Qu -Qs -Qm -Qn -Qe -Qd \
            -U -Uf \
            -D -Dq \
            -G \
            -h --help --version \
            --sync --remove --query --upgrade --database --getpkgbuild \
            --deptest --files
            return 1
        end
    end
    return 0
end

function __paru_op_is
    test -n "$argv[1]"; or return 1
    set -l tokens (commandline -poc)
    contains -- "$argv[1]" $tokens
end

function __paru_flag_is
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

# ── Installed packages ─────────────────────────────────────────────────────────
function __paru_installed
    pacman -Qq 2>/dev/null
end

function __paru_installed_with_desc
    pacman -Qq 2>/dev/null | while read -l pkg
        set -l desc (pacman -Qi "$pkg" 2>/dev/null | awk -F': ' '/^Description/{print $2; exit}')
        printf "%s\t%s\n" "$pkg" "$desc"
    end
end

# ── Explicitly installed packages ─────────────────────────────────────────────
function __paru_explicit
    pacman -Qqe 2>/dev/null
end

# ── Orphan packages ────────────────────────────────────────────────────────────
function __paru_orphans
    pacman -Qqdt 2>/dev/null
end

# ── AUR packages (from cache) ──────────────────────────────────────────────────
function __paru_aur
    pacman -Qqm 2>/dev/null
end

# ── Foreign (AUR) packages ─────────────────────────────────────────────────────
function __paru_foreign
    pacman -Qqm 2>/dev/null
end

# ── Packages with updates available ───────────────────────────────────────────
function __paru_upgradeable
    paru -Qu 2>/dev/null | awk '{print $1"\t"$2" → "$4}'
end

# ── Package groups ─────────────────────────────────────────────────────────────
function __paru_groups
    pacman -Sg 2>/dev/null | sort -u
end

# ── Available repos ────────────────────────────────────────────────────────────
function __paru_repos
    pacman-conf --repo-list 2>/dev/null
    echo "aur"
end

# ── Installed package files ────────────────────────────────────────────────────
function __paru_pkg_files --argument-names pkg
    test -n "$pkg"; and pacman -Ql "$pkg" 2>/dev/null | awk '{print $2}'
end

# ── Local .pkg.tar files ───────────────────────────────────────────────────────
function __paru_local_pkgs
    ls *.pkg.tar.* 2>/dev/null
    ls *.pkg.tar   2>/dev/null
end

# ══════════════════════════════════════════════════════════════════════════════
#  OPERATIONS (first-level flags)
# ══════════════════════════════════════════════════════════════════════════════

complete -c paru -f -n __paru_no_operation -a \
    "-S\t📦 Sync/install packages" \
    "-Sy\t🔄 Sync databases" \
    "-Su\t⬆️  System upgrade" \
    "-Syu\t🔄 Sync & upgrade (recommended)" \
    "-Syuu\t⬆️  Sync & full upgrade (downgrade allowed)" \
    "-Ss\t🔍 Search packages" \
    "-Si\t📖 Show package info" \
    "-Sl\t📋 List repo packages" \
    "-Sg\t📦 List/install package groups" \
    "-Sc\t🧹 Clean package cache" \
    "-Scc\t🧹 Clean all cache" \
    "-R\t🗑️  Remove package" \
    "-Rs\t🗑️  Remove + unneeded deps" \
    "-Rn\t🗑️  Remove + config files" \
    "-Rns\t🗑️  Remove + deps + configs" \
    "-Q\t🔍 Query installed packages" \
    "-Qi\t📖 Installed package info" \
    "-Ql\t📋 Installed package files" \
    "-Qo\t🔍 Find package owning file" \
    "-Qu\t⬆️  List upgradeable packages" \
    "-Qs\t🔍 Search installed packages" \
    "-Qm\t🌐 List foreign (AUR) packages" \
    "-Qn\t📦 List native (repo) packages" \
    "-Qe\t📦 List explicit installs" \
    "-Qd\t🗑️  List dependency-only installs" \
    "-Qp\t📖 Query a .pkg.tar file" \
    "-U\t⬆️  Upgrade from local file" \
    "-D\t🔧 Set install reason" \
    "-G\t⬇️  Download PKGBUILD from AUR" \
    "--sync\t📦 Sync operation" \
    "--remove\t🗑️  Remove operation" \
    "--query\t🔍 Query operation" \
    "--upgrade\t⬆️  Upgrade from file" \
    "--database\t🗄️  Database operation" \
    "--getpkgbuild\t📜 Get PKGBUILD" \
    "--files\t📂 File search" \
    "--deptest\t🧪 Test dependencies" \
    "-h\t❓ Show help" \
    "--help\t❓ Show help" \
    "--version\t📌 Show version"

# ══════════════════════════════════════════════════════════════════════════════
#  SYNC OPERATION FLAGS (-S)
# ══════════════════════════════════════════════════════════════════════════════

# -S: package names from repos + AUR
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -f -k -a "(paru -Sl 2>/dev/null | awk '{print \$2\"\t\"\$4}' | head -200)"

# -S flags
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu -Syuu -Ss -Si -Sl -Sg -Sc -Scc; or __paru_op_is --sync" \
    -s y -l refresh   -d "Refresh package databases"       -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu -Syuu; or __paru_op_is --sync" \
    -s u -l sysupgrade -d "Upgrade all packages"           -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -s s -l search    -d "Search package names/desc"       -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -s i -l info      -d "View package info"               -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -s l -l list      -d "List packages in repo"           -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -s g -l groups    -d "View package groups"             -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -s c -l clean     -d "Remove old packages from cache"  -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -s p -l print     -d "Print targets (dry run)"         -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -l needed         -d "Skip up-to-date packages"        -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -l asexplicit     -d "Mark as explicitly installed"    -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -l asdeps         -d "Mark as dependency"              -f
complete -c paru -n "__paru_op_is -S; or __paru_op_is --sync" \
    -l overwrite      -d "Overwrite conflicting files"     -f

# ── Paru-specific sync flags ───────────────────────────────────────────────────
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l skipreview     -d "Skip PKGBUILD review step"       -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l review         -d "Review PKGBUILDs before install" -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l nocheck        -d "Skip check() function"           -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l redownload     -d "Redownload all PKGBUILDs"        -f \
    -a "all\tAll packages yes\tConfirm redownload"
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l rebuild        -d "Rebuild packages"                -f \
    -a "all\tAll AUR packages tree\tDep tree yes\tConfirm"
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l sudoloop       -d "Loop sudo to avoid timeout"      -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l devel          -d "Check -git/-svn devel packages"  -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l newsonupgrade  -d "Print AUR news on upgrade"       -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l cleanafter     -d "Clean build dir after install"   -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l noupgrademenu  -d "No upgrade selection menu"       -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l combinedupgrade -d "Combine sync and AUR upgrade"   -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l batchinstall   -d "Batch AUR install"               -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l useask         -d "Use --ask flag"                  -f
complete -c paru -n "__paru_op_is -S -Sy -Su -Syu; or __paru_op_is --sync" \
    -l upgrademenu    -d "Show upgrade selection menu"     -f

# ── Repo filter ────────────────────────────────────────────────────────────────
complete -c paru -n "__paru_op_is -S -Ss -Si -Sl; or __paru_op_is --sync" \
    -l repo           -d "Target official repos only"      -f
complete -c paru -n "__paru_op_is -S -Ss -Si -Sl; or __paru_op_is --sync" \
    -l aur            -d "Target AUR only"                 -f

# ══════════════════════════════════════════════════════════════════════════════
#  REMOVE OPERATION FLAGS (-R)
# ══════════════════════════════════════════════════════════════════════════════

# -R: installed package names
complete -c paru -n "__paru_op_is -R -Rs -Rn -Rns -Ru -Rcns; or __paru_op_is --remove" \
    -f -k -a "(__paru_installed)"

complete -c paru -n "__paru_op_is -R -Rs -Rn -Rns; or __paru_op_is --remove" \
    -s s -l recursive  -d "Remove unneeded dependencies"   -f
complete -c paru -n "__paru_op_is -R -Rs -Rn -Rns; or __paru_op_is --remove" \
    -s n -l nosave     -d "Remove config files too"        -f
complete -c paru -n "__paru_op_is -R -Rs -Rn -Rns; or __paru_op_is --remove" \
    -s u -l unneeded   -d "Remove only if not required"    -f
complete -c paru -n "__paru_op_is -R; or __paru_op_is --remove" \
    -s c -l cascade    -d "Remove all dependent packages"  -f
complete -c paru -n "__paru_op_is -R; or __paru_op_is --remove" \
    -s p -l print      -d "Dry run: show what would be removed" -f
complete -c paru -n "__paru_op_is -R; or __paru_op_is --remove" \
    -l noprogressbar   -d "Disable progress bar"           -f

# ══════════════════════════════════════════════════════════════════════════════
#  QUERY OPERATION FLAGS (-Q)
# ══════════════════════════════════════════════════════════════════════════════

# -Q: installed package names
complete -c paru -n "__paru_op_is -Q -Qi -Ql -Qu -Qs -Qm -Qn -Qe -Qd; or __paru_op_is --query" \
    -f -k -a "(__paru_installed)"

complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s i -l info       -d "View package info"              -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s l -l list       -d "List package files"             -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s o -l owns       -d "Find which pkg owns file"       -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s p -l file       -d "Query a package file"           -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s u -l upgrades   -d "List upgradeable packages"      -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s s -l search     -d "Search installed packages"      -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s m -l foreign    -d "List foreign (AUR) packages"    -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s n -l native     -d "List native (repo) packages"    -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s e -l explicit   -d "List explicitly installed"      -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s d -l deps       -d "List dependency installs"       -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s t -l unrequired -d "List packages not required"     -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s g -l groups     -d "Filter by package group"        -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s k -l check      -d "Check package integrity"        -f
complete -c paru -n "__paru_op_is -Q; or __paru_op_is --query" \
    -s q -l quiet      -d "Quiet output (only names)"      -f

# -Qo: complete with local files
complete -c paru -n "__paru_op_is -Qo; or (__paru_op_is -Q; and __paru_flag_is -o --owns)" \
    -F

# -Qp: complete with local .pkg.tar files
complete -c paru -n "__paru_op_is -Qp; or (__paru_op_is -Q; and __paru_flag_is -p --file)" \
    -f -a "(__paru_local_pkgs)"

# ══════════════════════════════════════════════════════════════════════════════
#  UPGRADE OPERATION FLAGS (-U)
# ══════════════════════════════════════════════════════════════════════════════

complete -c paru -n "__paru_op_is -U -Uf; or __paru_op_is --upgrade" \
    -F

complete -c paru -n "__paru_op_is -U -Uf; or __paru_op_is --upgrade" \
    -l asexplicit -d "Mark as explicitly installed" -f
complete -c paru -n "__paru_op_is -U -Uf; or __paru_op_is --upgrade" \
    -l asdeps     -d "Mark as dependency"           -f
complete -c paru -n "__paru_op_is -U -Uf; or __paru_op_is --upgrade" \
    -l needed     -d "Skip if up to date"           -f
complete -c paru -n "__paru_op_is -U -Uf; or __paru_op_is --upgrade" \
    -l overwrite  -d "Overwrite conflicting files"  -f

# ══════════════════════════════════════════════════════════════════════════════
#  DATABASE OPERATION (-D)
# ══════════════════════════════════════════════════════════════════════════════

complete -c paru -n "__paru_op_is -D; or __paru_op_is --database" \
    -f -k -a "(__paru_installed)"

complete -c paru -n "__paru_op_is -D; or __paru_op_is --database" \
    -l asexplicit -d "Mark packages as explicit" -f
complete -c paru -n "__paru_op_is -D; or __paru_op_is --database" \
    -l asdeps     -d "Mark packages as deps"     -f
complete -c paru -n "__paru_op_is -D; or __paru_op_is --database" \
    -s k -l check -d "Check database"            -f
complete -c paru -n "__paru_op_is -D; or __paru_op_is --database" \
    -s q -l quiet -d "Quiet output"              -f

# ══════════════════════════════════════════════════════════════════════════════
#  GET PKGBUILD (-G)
# ══════════════════════════════════════════════════════════════════════════════

complete -c paru -n "__paru_op_is -G; or __paru_op_is --getpkgbuild" \
    -f -k -a "(paru -Sl aur 2>/dev/null | awk '{print \$2}' | head -100)"

complete -c paru -n "__paru_op_is -G; or __paru_op_is --getpkgbuild" \
    -s p -l print     -d "Print PKGBUILD to stdout"    -f
complete -c paru -n "__paru_op_is -G; or __paru_op_is --getpkgbuild" \
    -s d -l deps      -d "Download with deps"          -f

# ══════════════════════════════════════════════════════════════════════════════
#  FILES OPERATION (--files)
# ══════════════════════════════════════════════════════════════════════════════

complete -c paru -n "__paru_op_is --files" \
    -s l -l list    -d "List files in package" -f
complete -c paru -n "__paru_op_is --files" \
    -s o -l owns    -d "Find owner of file"    -f
complete -c paru -n "__paru_op_is --files" \
    -s s -l search  -d "Search for file"       -f
complete -c paru -n "__paru_op_is --files" \
    -s y -l refresh -d "Refresh file databases" -f
complete -c paru -n "__paru_op_is --files" \
    -s x -l regex   -d "Search with regex"     -f
complete -c paru -n "__paru_op_is --files" \
    -s q -l quiet   -d "Quiet output"          -f

# ══════════════════════════════════════════════════════════════════════════════
#  GLOBAL FLAGS (available with any operation)
# ══════════════════════════════════════════════════════════════════════════════

complete -c paru \
    -l noconfirm      -d "Skip all confirmation prompts"   -f
complete -c paru \
    -l confirm        -d "Always ask for confirmation"     -f
complete -c paru \
    -l noprogressbar  -d "Disable progress bar"            -f
complete -c paru \
    -l ask            -d "Set a number for auto-answers"   -f
complete -c paru \
    -l noscriptlet    -d "Don't run install scripts"       -f
complete -c paru \
    -l dbpath         -d "Set alternate database path"     -F
complete -c paru \
    -l root           -d "Set alternate installation root" -F
complete -c paru \
    -l cachedir       -d "Set alternate cache dir"         -F
complete -c paru \
    -l logfile        -d "Set alternate log file"          -F
complete -c paru \
    -l gpgdir         -d "Set alternate GPG dir"           -F
complete -c paru \
    -l hookdir        -d "Set alternate hook dir"          -F
complete -c paru \
    -l color          -d "Color output" -f \
    -a "always\tAlways color auto\tAuto detect never\tNever"
complete -c paru \
    -l debug          -d "Enable debug output"             -f
complete -c paru \
    -l verbose        -d "Verbose output"                  -f
complete -c paru \
    -l arch           -d "Set alternate architecture"      -f \
    -a "x86_64 aarch64 armv7h i686"

# ── Paru global config flags ───────────────────────────────────────────────────
complete -c paru \
    -l topdown        -d "Show results top-down"           -f
complete -c paru \
    -l bottomup       -d "Show results bottom-up"          -f
complete -c paru \
    -l limit          -d "Limit number of results"         -f
complete -c paru \
    -l sortby         -d "Sort AUR results by" -f \
    -a "votes\tVote count popularity\tPopularity score name\tName updated\tLast updated"
complete -c paru \
    -l searchby       -d "Search AUR by" -f \
    -a "name\tPackage name name-desc\tName + description maintainer\tMaintainer depends\tDependencies provides\tProvides"
complete -c paru \
    -l aururl         -d "Custom AUR URL"                  -f
complete -c paru \
    -l clonedir       -d "AUR clone directory"             -F
complete -c paru \
    -l makepkgconf    -d "Custom makepkg.conf"             -F
complete -c paru \
    -l mflags         -d "Extra makepkg flags"             -f
complete -c paru \
    -l gpgflags       -d "Extra GPG flags"                 -f
complete -c paru \
    -l fmflags        -d "Extra makepkg flags (foreign)"   -f
complete -c paru \
    -l bat            -d "Bat viewer for diffs"            -f
complete -c paru \
    -l batflags       -d "Extra bat flags"                 -f
complete -c paru \
    -l editor         -d "PKGBUILD editor" -f \
    -a "nvim\tNeovim vim\tVim nano\tNano helix\tHelix code\tVSCode"
complete -c paru \
    -l editorflags    -d "Extra editor flags"              -f
complete -c paru \
    -l sudo           -d "Sudo command" -f \
    -a "sudo\tSystem sudo doas\tOpenBSD doas run0\tSystemd run0"
complete -c paru \
    -l sudoflags      -d "Extra sudo flags"                -f
complete -c paru \
    -l completioninterval -d "Completion cache interval"   -f
complete -c paru \
    -l localrepo      -d "Use a local pacman repo"         -f
complete -c paru \
    -l chroot         -d "Build in clean chroot"           -f
complete -c paru \
    -l sign           -d "Sign built packages"             -f
complete -c paru \
    -l signdb         -d "Sign databases"                  -f
complete -c paru \
    -l keeprepodir    -d "Keep repo directory"             -f
