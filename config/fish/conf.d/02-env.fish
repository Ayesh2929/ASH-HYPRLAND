#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🌍 CORE ENVIRONMENT VARIABLES                                                  ║
# ║                                                                                  ║
# ║  02-env.fish — All non-XDG, non-path environment variables                     ║
# ║  Depends on: 00-xdg.fish, 01-path.fish                                         ║
# ║                                                                                  ║
# ║  Sections:                                                                       ║
# ║    • Editor & Pager                                                              ║
# ║    • Locale & Terminal                                                           ║
# ║    • Color & UI                                                                  ║
# ║    • Tool behavior                                                               ║
# ║    • Development flags                                                           ║
# ║    • Security environment                                                        ║
# ║    • ASH system environment                                                      ║
# ║                                                                                  ║
# ║  ASH Dotfiles v5.0 OMEGA                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_env_initialized && exit 0
set -g __ash_env_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✏️  EDITOR — Preference chain
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Resolve best available editor at startup (cached)
function __ash_resolve_editor
    for __ed in nvim hx vim vi nano
        if command -sq $__ed
            echo $__ed
            return 0
        end
    end
    echo vi  # POSIX fallback always available
end

set -gx EDITOR      (command -sq nvim && echo nvim || __ash_resolve_editor)
set -gx VISUAL      $EDITOR
set -gx GIT_EDITOR  $EDITOR
set -gx SUDO_EDITOR $EDITOR
set -gx FCEDIT      $EDITOR     # fc (shell history editor)
set -gx SYSTEMD_EDITOR $EDITOR  # systemctl edit

functions --erase __ash_resolve_editor


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📖 PAGER — Smart pager configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx PAGER less

# LESS options — tuned for readability and performance
set -gx LESS (string join " " \
    "--RAW-CONTROL-CHARS" \      # Pass ANSI color codes through
    "--quit-if-one-screen" \     # Exit if content fits on screen
    "--no-init" \                # Don't clear screen on exit
    "--ignore-case" \            # Smart case search
    "--LONG-PROMPT" \            # Show position in file
    "--tabs=4" \                 # 4-space tabs
    "--mouse" \                  # Enable mouse scrolling
    "--wheel-lines=3" \          # 3 lines per mouse wheel tick
    "--jump-target=5" \          # Target line near top on search
    "--incsearch"                # Incremental search
)

# bat-powered man pages (rich syntax highlighting)
if command -sq bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p --pager=\"less $LESS\"'"
    set -gx MANROFFOPT "-c"
else if command -sq nvim
    set -gx MANPAGER "nvim +Man!"
end

# bat configuration
if command -sq bat
    set -gx BAT_PAGER         "less $LESS"
    set -gx BAT_STYLE         "numbers,changes,header-filename,rule,snip"
    set -gx BAT_TABS          "4"
end

# ── Man page ANSI colors (less fallback) ──────────────────────────────────────
set -gx LESS_TERMCAP_mb (printf "\e[01;31m")   # Start blink  → bold red
set -gx LESS_TERMCAP_md (printf "\e[01;36m")   # Start bold   → cyan
set -gx LESS_TERMCAP_me (printf "\e[0m")        # End mode
set -gx LESS_TERMCAP_se (printf "\e[0m")        # End standout
set -gx LESS_TERMCAP_so (printf "\e[01;44;33m") # Standout     → yellow on blue
set -gx LESS_TERMCAP_ue (printf "\e[0m")        # End underline
set -gx LESS_TERMCAP_us (printf "\e[01;32m")   # Underline    → bold green


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 LOCALE & ENCODING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx LANG     en_US.UTF-8
set -gx LC_ALL   en_US.UTF-8
set -gx LC_CTYPE en_US.UTF-8
# Leave LC_TIME, LC_NUMERIC etc unset — inherit from LANG
# Explicit overrides if user set different locale:
set -q LC_TIME      || set -gx LC_TIME      en_US.UTF-8
set -q LC_NUMERIC   || set -gx LC_NUMERIC   en_US.UTF-8
set -q LC_MONETARY  || set -gx LC_MONETARY  en_US.UTF-8
set -q LC_MESSAGES  || set -gx LC_MESSAGES  en_US.UTF-8
set -q LC_PAPER     || set -gx LC_PAPER     en_US.UTF-8
set -q LC_ADDRESS   || set -gx LC_ADDRESS   en_US.UTF-8
set -q LC_TELEPHONE || set -gx LC_TELEPHONE en_US.UTF-8
set -q LC_MEASUREMENT || set -gx LC_MEASUREMENT en_US.UTF-8


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖥️  TERMINAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Resolve preferred terminal emulator
function __ash_resolve_terminal
    for __term in kitty wezterm foot alacritty
        command -sq $__term && echo $__term && return 0
    end
    echo xterm
end

set -gx TERMINAL    (__ash_resolve_terminal)
set -gx TERM_PROGRAM_VERSION (fish --version 2>&1 | string match -r '\d+\.\d+\.\d+')
functions --erase __ash_resolve_terminal

# Force 24-bit true color support
set -gx COLORTERM   truecolor
set -gx CLICOLOR    1
set -gx CLICOLOR_FORCE 0  # Don't force in pipes (let tools decide)

# ── Browser ───────────────────────────────────────────────────────────────────
for __browser in firefox chromium google-chrome-stable brave-browser epiphany
    if command -sq $__browser
        set -gx BROWSER $__browser
        break
    end
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 COLOR DEFINITIONS — LS_COLORS & terminal palette
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Comprehensive LS_COLORS with ASH theme-aware base palette

set -gx LS_COLORS (string join ":" \
    "no=0" \                      # Normal
    "fi=0" \                      # Regular file
    "di=1;34" \                   # Directory
    "ln=35" \                     # Symbolic link
    "pi=33" \                     # Named pipe (FIFO)
    "so=32" \                     # Socket
    "bd=34;46" \                  # Block device
    "cd=34;43" \                  # Character device
    "ex=1;32" \                   # Executable file
    "su=30;41" \                  # setuid
    "sg=30;46" \                  # setgid
    "tw=30;42" \                  # Sticky other-writable dir
    "ow=34;42" \                  # Other-writable dir
    "or=31;1" \                   # Orphaned symlink
    "mi=0;31" \                   # Missing file
    "*.tar=1;31" "*.tgz=1;31" "*.tbz2=1;31" "*.txz=1;31" \
    "*.zip=1;31" "*.z=1;31" "*.Z=1;31" "*.gz=1;31" "*.bz2=1;31" \
    "*.7z=1;31" "*.rar=1;31" "*.xz=1;31" "*.zst=1;31" \
    "*.deb=1;31" "*.rpm=1;31" "*.apk=1;31" \
    "*.jpg=35" "*.jpeg=35" "*.png=35" "*.gif=35" "*.webp=35" \
    "*.svg=35" "*.bmp=35" "*.ico=35" "*.tiff=35" "*.tif=35" \
    "*.avif=35" "*.jxl=35" "*.heic=35" "*.heif=35" \
    "*.mp4=36" "*.mkv=36" "*.avi=36" "*.mov=36" "*.wmv=36" \
    "*.webm=36" "*.flv=36" "*.m4v=36" "*.mpg=36" "*.mpeg=36" \
    "*.mp3=36" "*.flac=36" "*.ogg=36" "*.wav=36" "*.m4a=36" \
    "*.aac=36" "*.opus=36" "*.wma=36" \
    "*.py=33" "*.pyc=90" "*.pyo=90" \
    "*.rs=1;33" \
    "*.go=36" \
    "*.ts=34" "*.tsx=34" \
    "*.js=33" "*.jsx=33" "*.mjs=33" "*.cjs=33" \
    "*.lua=34" \
    "*.sh=32" "*.bash=32" "*.fish=32" "*.zsh=32" \
    "*.c=36" "*.h=36" "*.cpp=1;36" "*.hpp=1;36" "*.cc=1;36" \
    "*.java=33" "*.kt=33" "*.scala=33" "*.groovy=33" \
    "*.rb=31" "*.pl=31" "*.php=35" "*.swift=33" \
    "*.zig=33" "*.nim=33" "*.v=36" "*.ex=35" "*.exs=35" \
    "*.json=33" "*.jsonc=33" "*.json5=33" \
    "*.toml=33" "*.yaml=33" "*.yml=33" "*.ini=33" "*.cfg=33" \
    "*.conf=33" "*.env=33" \
    "*.xml=33" "*.html=35" "*.htm=35" "*.css=35" "*.scss=35" "*.sass=35" \
    "*.md=37" "*.rst=37" "*.txt=37" "*.org=37" \
    "*.pdf=35" "*.doc=35" "*.docx=35" "*.xls=35" "*.xlsx=35" "*.ppt=35" \
    "*.db=31" "*.sqlite=31" "*.sqlite3=31" "*.sql=31" \
    "*.nix=34" "*.dockerfile=36" "Dockerfile=36" "*.dockerignore=90" \
    "*.lock=90" "*.log=90" "*.bak=90" "*.old=90" "*.orig=90" \
    "*.diff=32" "*.patch=32" \
    "*.cert=33" "*.pem=33" "*.key=31" "*.pub=32" \
    ".gitignore=90" ".gitattributes=90" ".editorconfig=90" \
    "Makefile=1;33" "Justfile=1;33" "Taskfile.yml=1;33"
)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 FZF GLOBAL CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq fzf
    set -gx FZF_DEFAULT_COMMAND \
        "fd --type f --hidden --follow \
         --exclude .git --exclude node_modules \
         --exclude .cache --exclude __pycache__ \
         --exclude target --exclude dist --exclude build"

    set -gx FZF_DEFAULT_OPTS (string join \
        "\n    " \
        "--height=65%" \
        "--min-height=20" \
        "--layout=reverse" \
        "--border=rounded" \
        "--border-label=' ⚡ ASH ' " \
        "--border-label-pos=3" \
        "--info=inline-right" \
        "--prompt='  '" \
        "--pointer=' '" \
        "--marker=' '" \
        "--separator='─'" \
        "--scrollbar='│'" \
        "--preview-window=right:55%:border-left:wrap" \
        "--bind='ctrl-/:toggle-preview'" \
        "--bind='ctrl-u:preview-half-page-up'" \
        "--bind='ctrl-d:preview-half-page-down'" \
        "--bind='ctrl-a:select-all'" \
        "--bind='ctrl-x:deselect-all'" \
        "--bind='ctrl-f:page-down'" \
        "--bind='ctrl-b:page-up'" \
        "--bind='alt-j:preview-down'" \
        "--bind='alt-k:preview-up'" \
        "--bind='alt-up:first'" \
        "--bind='alt-down:last'" \
        "--bind='ctrl-y:execute-silent(wl-copy -n {+} 2>/dev/null || xclip -selection c {+} 2>/dev/null)'" \
        "--bind='ctrl-e:execute(\$EDITOR {+} </dev/tty >/dev/tty)'" \
        "--bind='ctrl-o:execute(xdg-open {} 2>/dev/null &)'" \
        "--bind='?:toggle-preview'" \
        "--bind='esc:cancel'" \
        # ── Catppuccin Mocha theme ──────────────────────────────────────────
        "--color='bg+:#313244'" \
        "--color='bg:#1e1e2e'" \
        "--color='spinner:#f5e0dc'" \
        "--color='hl:#f38ba8'" \
        "--color='fg:#cdd6f4'" \
        "--color='header:#f38ba8'" \
        "--color='info:#cba6f7'" \
        "--color='pointer:#f5e0dc'" \
        "--color='marker:#a6e3a1'" \
        "--color='fg+:#cdd6f4'" \
        "--color='prompt:#cba6f7'" \
        "--color='hl+:#f38ba8'" \
        "--color='border:#313244'" \
        "--color='label:#cba6f7'" \
        "--color='preview-border:#45475a'" \
        "--color='preview-label:#cba6f7'" \
        "--color='separator:#45475a'" \
        "--color='scrollbar:#45475a'" \
        "--ansi"
    )

    # CTRL-T: file finder with bat preview
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS (string join " " \
        "--preview='bat --style=numbers,changes --color=always --line-range=:300 {} 2>/dev/null" \
        "         || eza --tree --color=always --icons --level=3 {} 2>/dev/null" \
        "         || cat {}'" \
        "--header='  Ctrl-/ preview • Ctrl-Y copy • Ctrl-E edit'"
    )

    # ALT-C: directory finder with eza tree preview
    set -gx FZF_ALT_C_COMMAND \
        "fd --type d --hidden --follow \
         --exclude .git --exclude node_modules \
         --exclude .cache --exclude __pycache__"
    set -gx FZF_ALT_C_OPTS (string join " " \
        "--preview='eza --tree --color=always --icons --level=3 {} 2>/dev/null'" \
        "--header='  ALT-C: change directory'"
    )

    # CTRL-R: history search (enhanced; atuin takes over if installed)
    set -gx FZF_CTRL_R_OPTS (string join " " \
        "--preview='echo {}'" \
        "--preview-window=down:3:hidden:wrap" \
        "--bind='ctrl-/:toggle-preview'" \
        "--bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy 2>/dev/null)'" \
        "--header='  Ctrl-/ preview • Ctrl-Y copy command'" \
        "--sort" \
        "--exact"
    )
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐙 GIT CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx GIT_TERMINAL_PROMPT     1
set -gx GIT_MERGE_AUTOEDIT      no

# delta (git diff viewer)
if command -sq delta
    set -gx GIT_PAGER  "delta"
    set -gx DELTA_PAGER "less $LESS"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐳 DOCKER & CONTAINER ENVIRONMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx DOCKER_BUILDKIT              1    # Enable BuildKit (faster, better caching)
set -gx COMPOSE_DOCKER_CLI_BUILD     1    # Use Docker CLI in compose
set -gx COMPOSE_BAKE_TF             1    # Enable bake targets
set -gx BUILDKIT_PROGRESS           plain  # Structured build output


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔒 SECURITY & PRIVACY ENVIRONMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GPG agent for SSH auth and signing
set -gx GPG_TTY     (tty)
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"

# Ensure GPG prompts to the right TTY
command -sq gpg-connect-agent \
    && gpg-connect-agent updatestartuptty /bye &>/dev/null

# OpenSSL / TLS
set -gx SSL_CERT_FILE   /etc/ssl/certs/ca-certificates.crt
set -gx CURL_CA_BUNDLE  /etc/ssl/certs/ca-certificates.crt
set -gx REQUESTS_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt  # Python requests


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 DEVELOPMENT ENVIRONMENT FLAGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Compiler flags for native-speed local builds ──────────────────────────────
set -gx MAKEFLAGS      "-j(nproc)"
set -gx CMAKE_BUILD_PARALLEL_LEVEL (nproc)

# ── Rust ──────────────────────────────────────────────────────────────────────
set -gx CARGO_NET_GIT_FETCH_WITH_CLI true
set -gx RUST_BACKTRACE               1
set -gx RUST_LOG                     warn

# ── Go ────────────────────────────────────────────────────────────────────────
set -gx GOPROXY "https://proxy.golang.org,direct"
set -gx GONOSUMDB "*"
set -gx GOFLAGS "-mod=mod"

# ── Python ────────────────────────────────────────────────────────────────────
set -gx PYTHONDONTWRITEBYTECODE 1   # Don't create .pyc files
set -gx PYTHONUNBUFFERED        1   # Unbuffered stdout/stderr
set -gx PYTHONFAULTHANDLER      1   # Better crash reports

# ── Node.js ───────────────────────────────────────────────────────────────────
set -gx NODE_OPTIONS             "--max-old-space-size=8192"
set -gx NPM_CONFIG_PROGRESS      true
set -gx NPM_CONFIG_SAVE_PREFIX   "~"

# ── Java ──────────────────────────────────────────────────────────────────────
set -gx _JAVA_OPTIONS (string join " " \
    "-Dawt.useSystemAAFontSettings=on" \
    "-Dswing.aatext=true" \
    "-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel" \
    "-Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel" \
    "-Xss4m"
)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🤖 ASH SYSTEM IDENTITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx ASH_VERSION    "5.0.0-omega"
set -gx ASH_SHELL      fish
set -gx ASH_SHELL_V    (fish --version 2>&1 | string match -r '\d+\.\d+\.\d+')
set -gx ASH_OS         (uname -s | string lower)
set -gx ASH_ARCH       (uname -m)
set -gx ASH_HOSTNAME   (hostname -s 2>/dev/null || hostname)
set -gx ASH_SESSION_ID (uuidgen 2>/dev/null || echo "session-"(date +%s))
set -gx ASH_SESSION_START (date -Iseconds 2>/dev/null || date)

# ── Distro detection ──────────────────────────────────────────────────────────
if test -f /etc/os-release
    set -l __os_id (grep '^ID=' /etc/os-release | string replace 'ID=' '')
    set -gx ASH_DISTRO (string trim --chars='"' $__os_id)
    set -e __os_id
else
    set -gx ASH_DISTRO "unknown"
end

# ── Current theme & mode (read from state files) ──────────────────────────────
set -gx ASH_CURRENT_THEME \
    (cat "$ASH_STATE/current-theme" 2>/dev/null || echo "catppuccin-mocha")
set -gx ASH_CURRENT_MODE \
    (cat "$ASH_STATE/current-mode" 2>/dev/null || echo "default")
set -gx ASH_CURRENT_PROFILE \
    (cat "$ASH_STATE/current-profile" 2>/dev/null || echo "default")

# ── Privacy mode propagation ──────────────────────────────────────────────────
set -q ASH_PRIVACY_MODE || set -gx ASH_PRIVACY_MODE 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 ANALYTICS — Only if opted in
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if test "$ASH_ANALYTICS" = "1" && test "$ASH_PRIVACY_MODE" != "1"
    # Increment session counter (fire-and-forget, non-blocking)
    set -l __count_file "$ASH_STATE/session-count"
    set -l __count (math (cat $__count_file 2>/dev/null || echo 0) + 1)
    echo $__count > $__count_file 2>/dev/null &
    set -e __count_file __count
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ♻️  CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -e __browser