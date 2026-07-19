# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — SSH Agent Ultra Configuration                      ║
# ║  Intelligent SSH agent management with keychain, 1Password & GPG support  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_ssh_agent_loaded && exit 0
set --global _ash_ssh_agent_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_ssh_dir        "$HOME/.ssh"
set --global _ash_ssh_env_file   "$HOME/.local/share/ash/state/ssh-agent.env"
set --global _ash_ssh_sock_link  "$XDG_RUNTIME_DIR/ssh-agent.sock"
set --global _ash_ssh_log        "$HOME/.local/share/ash/logs/ssh-agent.log"
set --global _ash_ssh_config     "$_ash_ssh_dir/config"
set --global _ash_ssh_timeout    7200   # 2 hours default key lifetime
set --global _ash_ssh_max_tries  3      # Max pinentry attempts

# Default key names to auto-load (relative to ~/.ssh/)
set --global _ash_ssh_default_keys \
    id_ed25519 \
    id_ed25519_sk \
    id_ecdsa_sk \
    id_rsa \
    id_ecdsa \
    work_ed25519 \
    personal_ed25519 \
    github_ed25519 \
    gitlab_ed25519 \
    deploy_ed25519

mkdir -p (dirname $_ash_ssh_env_file) 2>/dev/null
mkdir -p (dirname $_ash_ssh_log)      2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _ssh_reset   (set_color normal)
set -g _ssh_bold    (set_color --bold)
set -g _ssh_cyan    (set_color cyan)
set -g _ssh_green   (set_color green)
set -g _ssh_yellow  (set_color yellow)
set -g _ssh_red     (set_color red)
set -g _ssh_blue    (set_color blue)
set -g _ssh_purple  (set_color magenta)
set -g _ssh_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📝 LOGGING                                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_log --description "Write timestamped log entry"
    set -l level $argv[1]
    set -l msg   (string join ' ' $argv[2..-1])
    set -l ts    (date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] [$level] $msg" >> $_ash_ssh_log 2>/dev/null
end

function __ssh_info  --description "Info log + console"
    __ssh_log INFO $argv
end

function __ssh_warn  --description "Warn log + console"
    __ssh_log WARN $argv
    echo $_ssh_yellow"  ⚠ $argv"$_ssh_reset >&2
end

function __ssh_error --description "Error log + console"
    __ssh_log ERROR $argv
    echo $_ssh_red"  ✗ $argv"$_ssh_reset >&2
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION: 1Password, GPG, Keychain, systemd                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_detect_backend --description "Detect best available SSH agent backend"
    # Priority 1: 1Password SSH agent (most secure)
    if command -q op && test -S "$HOME/.1password/agent.sock"
        echo "1password"
        return
    end

    # Priority 2: systemd user ssh-agent socket
    if test -S "$XDG_RUNTIME_DIR/ssh-agent.socket" 2>/dev/null
        echo "systemd"
        return
    end

    # Priority 3: Keychain (cross-shell agent manager)
    if command -q keychain
        echo "keychain"
        return
    end

    # Priority 4: GPG agent with SSH support
    if command -q gpgconf && gpgconf --list-dirs agent-ssh-socket 2>/dev/null | read -l gpg_sock
        if test -S $gpg_sock
            echo "gpg"
            return
        end
    end

    # Priority 5: Gnome/KDE keyring SSH agent
    if test -S "$XDG_RUNTIME_DIR/keyring/ssh" 2>/dev/null
        echo "gnome-keyring"
        return
    end

    # Fallback: Native ssh-agent
    echo "native"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔑 BACKEND: 1Password SSH Agent                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_setup_1password --description "Configure 1Password SSH agent"
    set -l op_sock "$HOME/.1password/agent.sock"

    if not test -S $op_sock
        __ssh_warn "1Password agent socket not found: $op_sock"
        return 1
    end

    set --export SSH_AUTH_SOCK $op_sock
    __ssh_info "1Password SSH agent connected: $op_sock"

    # Verify connectivity
    if ssh-add -l &>/dev/null; or test $status -eq 1
        echo $_ssh_green"  󰢏 SSH Agent: 1Password"$_ssh_reset
        return 0
    else
        __ssh_warn "1Password agent socket exists but is unresponsive"
        return 1
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔐 BACKEND: GPG Agent SSH Support                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_setup_gpg --description "Configure GPG agent for SSH"
    set -l gpg_sock (gpgconf --list-dirs agent-ssh-socket 2>/dev/null)

    if test -z "$gpg_sock"
        __ssh_warn "GPG agent SSH socket not found"
        return 1
    end

    # Ensure GPG agent is running
    gpgconf --launch gpg-agent 2>/dev/null

    # Wait briefly for socket
    set -l tries 0
    while not test -S $gpg_sock && test $tries -lt 5
        sleep 0.2
        set tries (math $tries + 1)
    end

    if not test -S $gpg_sock
        __ssh_warn "GPG agent failed to start"
        return 1
    end

    set --export SSH_AUTH_SOCK $gpg_sock
    set --export GPG_TTY (tty 2>/dev/null)

    # Refresh GPG agent TTY
    gpg-connect-agent updatestartuptty /bye 2>/dev/null

    __ssh_info "GPG SSH agent: $gpg_sock"
    echo $_ssh_green"  󰢏 SSH Agent: GPG"$_ssh_reset
    return 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🗝️  BACKEND: Keychain                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_setup_keychain --description "Configure keychain SSH agent"
    # Collect existing private keys
    set -l keys_to_load
    for key in $_ash_ssh_default_keys
        set -l keypath "$_ash_ssh_dir/$key"
        if test -f $keypath && not string match -q '*.pub' $keypath
            set --append keys_to_load $keypath
        end
    end

    # Run keychain (starts agent if not running, reuses if running)
    set -l keychain_opts \
        --quiet \
        --nogui \
        --timeout (math $_ash_ssh_timeout / 60) \
        --agents ssh

    if test (count $keys_to_load) -gt 0
        keychain $keychain_opts $keys_to_load 2>/dev/null
    else
        keychain $keychain_opts 2>/dev/null
    end

    # Source keychain environment
    set -l keychain_env "$HOME/.keychain/(hostname)-fish"
    if test -f $keychain_env
        source $keychain_env
        __ssh_info "Keychain loaded: $keychain_env"
        echo $_ssh_green"  󰢏 SSH Agent: Keychain"$_ssh_reset
        return 0
    end

    __ssh_warn "Keychain environment file not found"
    return 1
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔒 BACKEND: systemd SSH Agent Socket                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_setup_systemd --description "Configure systemd-managed SSH agent"
    set -l sock "$XDG_RUNTIME_DIR/ssh-agent.socket"

    if not test -S $sock
        # Try to activate it
        if command -q systemctl
            systemctl --user start ssh-agent.socket 2>/dev/null
            sleep 0.5
        end
    end

    if test -S $sock
        set --export SSH_AUTH_SOCK $sock
        __ssh_info "systemd SSH agent: $sock"
        echo $_ssh_green"  󰢏 SSH Agent: systemd"$_ssh_reset
        return 0
    end

    __ssh_warn "systemd SSH agent socket not available"
    return 1
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 BACKEND: Gnome Keyring                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_setup_gnome_keyring --description "Configure Gnome Keyring SSH agent"
    set -l sock "$XDG_RUNTIME_DIR/keyring/ssh"

    if test -S $sock
        set --export SSH_AUTH_SOCK $sock
        __ssh_info "Gnome Keyring SSH agent: $sock"
        echo $_ssh_green"  󰢏 SSH Agent: Gnome Keyring"$_ssh_reset
        return 0
    end

    __ssh_warn "Gnome Keyring SSH socket not found"
    return 1
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  BACKEND: Native ssh-agent (fallback)                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_agent_running --description "Check if a valid SSH agent is reachable"
    test -n "$SSH_AUTH_SOCK" && test -S "$SSH_AUTH_SOCK" || return 1
    ssh-add -l &>/dev/null
    set -l rc $status
    # rc=0 → keys loaded, rc=1 → agent running but no keys, rc=2 → not running
    test $rc -ne 2
end

function __ssh_load_env --description "Load saved SSH agent environment"
    test -f $_ash_ssh_env_file || return 1
    set -l pid_line (grep SSH_AGENT_PID $_ash_ssh_env_file 2>/dev/null)
    set -l sock_line (grep SSH_AUTH_SOCK $_ash_ssh_env_file 2>/dev/null)
    test -z "$pid_line" && return 1

    # Parse values
    set -l saved_pid  (string match -r '\d+' $pid_line)
    set -l saved_sock (string match -r '"([^"]+)"' $sock_line | head -1 | string trim -c '"')

    # Validate process is still alive
    if not kill -0 $saved_pid 2>/dev/null
        __ssh_info "Saved agent PID $saved_pid is dead"
        return 1
    end

    set --export SSH_AGENT_PID $saved_pid
    set --export SSH_AUTH_SOCK $saved_sock
    __ssh_info "Restored agent PID=$saved_pid SOCK=$saved_sock"
    return 0
end

function __ssh_start_native_agent --description "Start a new native ssh-agent process"
    __ssh_info "Starting new ssh-agent..."

    # Start agent, capture environment
    set -l agent_output (ssh-agent -t $_ash_ssh_timeout 2>/dev/null)
    if test $status -ne 0
        __ssh_error "Failed to start ssh-agent"
        return 1
    end

    # Parse and export variables
    for line in $agent_output
        switch $line
            case 'SSH_AUTH_SOCK=*'
                set --export SSH_AUTH_SOCK (string match -r 'SSH_AUTH_SOCK=([^;]+)' $line | tail -1)
            case 'SSH_AGENT_PID=*'
                set --export SSH_AGENT_PID (string match -r 'SSH_AGENT_PID=(\d+)' $line | tail -1)
        end
    end

    # Persist environment for future shells
    echo $agent_output > $_ash_ssh_env_file 2>/dev/null

    # Create stable symlink for SSH_AUTH_SOCK
    if test -n "$_ash_ssh_sock_link"
        ln -sf $SSH_AUTH_SOCK $_ash_ssh_sock_link 2>/dev/null
    end

    __ssh_info "New agent started: PID=$SSH_AGENT_PID SOCK=$SSH_AUTH_SOCK"
    echo $_ssh_green"  󰢏 SSH Agent: native (PID: $SSH_AGENT_PID)"$_ssh_reset
    return 0
end

function __ssh_setup_native --description "Setup native ssh-agent with env persistence"
    # Try to reuse existing agent first
    if __ssh_load_env && __ssh_agent_running
        __ssh_info "Reusing existing agent PID=$SSH_AGENT_PID"
        return 0
    end

    # Check if already forwarded (SSH session)
    if test -n "$SSH_AUTH_SOCK" && __ssh_agent_running
        __ssh_info "Using forwarded agent: $SSH_AUTH_SOCK"
        echo $_ssh_cyan"  󰢏 SSH Agent: forwarded"$_ssh_reset
        return 0
    end

    # Start fresh agent
    __ssh_start_native_agent
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🗝️  KEY MANAGEMENT: Auto-load SSH keys                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_load_keys --description "Auto-load SSH keys into agent"
    __ssh_agent_running || return 1

    # Get currently loaded key fingerprints
    set -l loaded_fps (ssh-add -l 2>/dev/null | awk '{print $2}')

    set -l loaded_count   0
    set -l skipped_count  0
    set -l failed_count   0
    set -l missing_count  0

    for keyname in $_ash_ssh_default_keys
        set -l keypath "$_ash_ssh_dir/$keyname"

        # Skip if private key doesn't exist
        if not test -f $keypath
            set missing_count (math $missing_count + 1)
            continue
        end

        # Skip public keys
        string match -q '*.pub' $keypath && continue

        # Check if already loaded (compare fingerprints)
        set -l key_fp (ssh-keygen -lf $keypath 2>/dev/null | awk '{print $2}')
        if test -n "$key_fp" && contains $key_fp $loaded_fps
            set skipped_count (math $skipped_count + 1)
            __ssh_info "Key already loaded: $keyname ($key_fp)"
            continue
        end

        # Load key — use AddKeysToAgent from SSH config if possible
        set -l add_opts
        # Add with confirmation for powerful keys
        if string match -q '*deploy*' $keyname; or string match -q '*root*' $keyname
            set add_opts -c
        end

        if ssh-add $add_opts -t $_ash_ssh_timeout $keypath 2>/dev/null
            set loaded_count (math $loaded_count + 1)
            __ssh_info "Loaded key: $keyname"
        else
            set failed_count (math $failed_count + 1)
            __ssh_warn "Failed to load key: $keyname (may require passphrase)"
        end
    end

    # Summary feedback (only if anything happened)
    if test (math $loaded_count + $failed_count) -gt 0
        echo ""
        test $loaded_count  -gt 0 && echo $_ssh_green"  ✓ Loaded $loaded_count SSH key(s)"$_ssh_reset
        test $failed_count  -gt 0 && echo $_ssh_yellow"  ⚠ Failed $failed_count key(s) (passphrase required)"$_ssh_reset
        test $skipped_count -gt 0 && echo $_ssh_dim"  ↷ Skipped $skipped_count already-loaded key(s)"$_ssh_reset
        echo ""
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 MAIN INITIALIZATION                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ssh_agent_init --description "Initialize SSH agent using best available backend"
    # Skip if already running and healthy
    if __ssh_agent_running
        __ssh_info "Existing healthy agent found: $SSH_AUTH_SOCK"
        return 0
    end

    # Detect and setup best backend
    set -l backend (__ssh_detect_backend)
    __ssh_info "Selected SSH backend: $backend"

    switch $backend
        case '1password'
            __ssh_setup_1password; or __ssh_setup_native
        case gpg
            __ssh_setup_gpg; or __ssh_setup_native
        case keychain
            __ssh_setup_keychain; or __ssh_setup_native
        case systemd
            __ssh_setup_systemd; or __ssh_setup_native
        case 'gnome-keyring'
            __ssh_setup_gnome_keyring; or __ssh_setup_native
        case native
            __ssh_setup_native
        case '*'
            __ssh_setup_native
    end

    # Auto-load default keys (only for non-managed backends)
    if not contains $backend 1password gpg gnome-keyring keychain
        __ssh_load_keys
    end
end

# ── Run initialization ────────────────────────────────────────────────────────
__ssh_agent_init

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC FUNCTIONS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── ssh-agent-status ─────────────────────────────────────────────────────────
function ssh-agent-status --description "Show SSH agent status and loaded keys"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l red    (set_color red)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     󰢏  SSH Agent Status                          ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════╝"$reset
    echo ""

    # Agent info
    if test -n "$SSH_AGENT_PID"
        echo "  "$bold"PID     "$reset $green$SSH_AGENT_PID$reset
    end
    if test -n "$SSH_AUTH_SOCK"
        echo "  "$bold"Socket  "$reset $dim$SSH_AUTH_SOCK$reset
    end

    set -l backend (__ssh_detect_backend)
    echo "  "$bold"Backend "$reset $cyan$backend$reset
    echo ""

    # Loaded keys
    set -l key_list (ssh-add -l 2>/dev/null)
    set -l rc $status

    if test $rc -eq 0
        echo "  "$bold$green"Loaded Keys:"$reset
        echo "  "$dim"──────────────────────────────────────────────────"$reset
        for key in $key_list
            echo "  "$green" "$reset $key
        end
    else if test $rc -eq 1
        echo "  "$yellow"⚠  No keys loaded"$reset
    else
        echo "  "$red"✗  Agent not running or not accessible"$reset
    end

    echo ""

    # Available keys on disk
    echo "  "$bold"Available Keys:"$reset
    echo "  "$dim"──────────────────────────────────────────────────"$reset
    for keyname in $_ash_ssh_default_keys
        set -l keypath "$_ash_ssh_dir/$keyname"
        if test -f $keypath
            set -l fp (ssh-keygen -lf $keypath 2>/dev/null)
            echo "  "$green" $keyname"$reset" "$dim$fp$reset
        end
    end

    echo ""
end

# ─── ssh-add-all ──────────────────────────────────────────────────────────────
function ssh-add-all --description "Load all available SSH keys into agent"
    echo ""
    echo $_ssh_cyan"  🔑 Loading all SSH keys..."$_ssh_reset
    echo ""
    __ssh_load_keys
end

# ─── ssh-forget-all ───────────────────────────────────────────────────────────
function ssh-forget-all --description "Remove all keys from SSH agent"
    if ssh-add -D 2>/dev/null
        echo $_ssh_green"  ✓ All SSH keys removed from agent"$_ssh_reset
        __ssh_info "All keys removed from agent"
    else
        echo $_ssh_red"  ✗ Failed to remove keys"$_ssh_reset
    end
end

# ─── ssh-restart ──────────────────────────────────────────────────────────────
function ssh-restart --description "Restart the SSH agent"
    echo ""
    echo $_ssh_cyan"  🔄 Restarting SSH agent..."$_ssh_reset

    # Kill existing agent
    if test -n "$SSH_AGENT_PID"
        kill -TERM $SSH_AGENT_PID 2>/dev/null
        __ssh_info "Killed agent PID=$SSH_AGENT_PID"
    end

    # Clean up state
    rm -f $_ash_ssh_env_file $_ash_ssh_sock_link 2>/dev/null
    set --erase SSH_AGENT_PID SSH_AUTH_SOCK

    # Reinitialize
    set --erase _ash_ssh_agent_loaded
    __ssh_agent_init

    echo ""
end

# ─── ssh-agent-stop ───────────────────────────────────────────────────────────
function ssh-agent-stop --description "Stop the SSH agent"
    if test -n "$SSH_AGENT_PID"
        ssh-agent -k 2>/dev/null
        set --erase SSH_AGENT_PID SSH_AUTH_SOCK
        rm -f $_ash_ssh_env_file $_ash_ssh_sock_link 2>/dev/null
        echo $_ssh_yellow"  ⏹ SSH agent stopped"$_ssh_reset
        __ssh_info "Agent stopped"
    else
        echo $_ssh_dim"  ℹ  No agent running"$_ssh_reset
    end
end

# ─── ssh-agent-forward ────────────────────────────────────────────────────────
function ssh-agent-forward --description "SSH with agent forwarding enabled"
    if test (count $argv) -eq 0
        echo "  Usage: ssh-agent-forward <host> [ssh-options...]"
        return 1
    end
    ssh -A $argv
end

# ─── ssh-keygen-ed25519 ───────────────────────────────────────────────────────
function ssh-keygen-ed25519 --description "Generate a new Ed25519 SSH keypair"
    set -l name    $argv[1]
    set -l comment $argv[2]

    if test -z "$name"
        read -P "  Key name (e.g. github_ed25519): " name
    end
    if test -z "$name"
        echo $_ssh_red"  ✗ Key name is required"$_ssh_reset
        return 1
    end
    if test -z "$comment"
        set comment "$USER@"(hostname)"_"(date +%Y%m%d)
    end

    set -l keypath "$_ash_ssh_dir/$name"

    if test -f $keypath
        echo $_ssh_yellow"  ⚠ Key already exists: $keypath"$_ssh_reset
        read -P "  Overwrite? [y/N] " confirm
        string match -qi 'y*' $confirm || return 0
    end

    echo ""
    echo $_ssh_cyan"  🔑 Generating Ed25519 keypair..."$_ssh_reset
    ssh-keygen -t ed25519 -a 100 -C $comment -f $keypath

    if test $status -eq 0
        echo ""
        echo $_ssh_green"  ✓ Key generated: $keypath"$_ssh_reset
        echo $_ssh_green"  ✓ Public key:    $keypath.pub"$_ssh_reset
        echo ""
        echo "  Public key:"
        echo $_ssh_dim(cat $keypath.pub)$_ssh_reset
        echo ""

        # Offer to load into agent
        read -P "  Load into agent now? [Y/n] " load_now
        if not string match -qi 'n*' $load_now
            ssh-add -t $_ash_ssh_timeout $keypath
        end
    else
        echo $_ssh_red"  ✗ Key generation failed"$_ssh_reset
        return 1
    end
end

# ─── ssh-copy-id-clip ─────────────────────────────────────────────────────────
function ssh-copy-id-clip --description "Copy SSH public key to clipboard"
    set -l key $argv[1]
    test -z "$key" && set key "id_ed25519"
    set -l pubkey "$_ash_ssh_dir/$key.pub"

    if not test -f $pubkey
        echo $_ssh_red"  ✗ Public key not found: $pubkey"$_ssh_reset
        return 1
    end

    set -l content (cat $pubkey)

    if command -q wl-copy
        echo $content | wl-copy
        echo $_ssh_green"  ✓ Copied to clipboard (Wayland): $pubkey"$_ssh_reset
    else if command -q xclip
        echo $content | xclip -selection clipboard
        echo $_ssh_green"  ✓ Copied to clipboard (X11): $pubkey"$_ssh_reset
    else
        echo $_ssh_yellow"  ℹ  No clipboard tool found. Public key:"$_ssh_reset
        echo $content
    end
end

# ─── ssh-host-add ─────────────────────────────────────────────────────────────
function ssh-host-add --description "Interactively add a new SSH host to config"
    echo ""
    echo $_ssh_bold$_ssh_cyan"  ╔══════════════════════════════╗"$_ssh_reset
    echo $_ssh_bold$_ssh_cyan"  ║  Add SSH Host                ║"$_ssh_reset
    echo $_ssh_bold$_ssh_cyan"  ╚══════════════════════════════╝"$_ssh_reset
    echo ""

    read -P "  Alias (Host):     " alias
    read -P "  Hostname/IP:      " hostname
    read -P "  Username:         " user
    read -P "  Port [22]:        " port
    read -P "  IdentityFile:     " identity
    read -P "  Config file [~/.ssh/config.d/hosts.conf]: " config_file

    test -z "$alias"    && begin; echo $_ssh_red"  ✗ Alias required"$_ssh_reset; return 1; end
    test -z "$hostname" && begin; echo $_ssh_red"  ✗ Hostname required"$_ssh_reset; return 1; end
    test -z "$user"     && set user $USER
    test -z "$port"     && set port 22
    test -z "$config_file" && set config_file "$_ash_ssh_dir/config.d/hosts.conf"

    mkdir -p (dirname $config_file) 2>/dev/null

    set -l entry "\n# Added by ASH on "(date '+%Y-%m-%d')"\n"
    set entry $entry"Host $alias\n"
    set entry $entry"    HostName $hostname\n"
    set entry $entry"    User $user\n"
    set entry $entry"    Port $port\n"
    test -n "$identity" && set entry $entry"    IdentityFile $identity\n"
    set entry $entry"    AddKeysToAgent yes\n"
    set entry $entry"    ServerAliveInterval 60\n"
    set entry $entry"    ServerAliveCountMax 3\n"

    printf $entry >> $config_file
    echo ""
    echo $_ssh_green"  ✓ Host '$alias' added to $config_file"$_ssh_reset
    echo ""
    echo "  Connect with: "$_ssh_cyan"ssh $alias"$_ssh_reset
    echo ""
end

# ─── ssh-scan-host ────────────────────────────────────────────────────────────
function ssh-scan-host --description "Scan and add host key to known_hosts"
    set -l host $argv[1]
    set -l port (test -n $argv[2] && echo $argv[2] || echo 22)

    if test -z "$host"
        echo "  Usage: ssh-scan-host <host> [port]"
        return 1
    end

    echo $_ssh_cyan"  🔍 Scanning $host:$port..."$_ssh_reset
    ssh-keyscan -p $port -H $host >> "$_ash_ssh_dir/known_hosts" 2>/dev/null
    and echo $_ssh_green"  ✓ Host key added: $host"$_ssh_reset
    or  echo $_ssh_red"  ✗ Failed to scan: $host"$_ssh_reset
end

# ─── ssh-tunnel ───────────────────────────────────────────────────────────────
function ssh-tunnel --description "Create SSH tunnels (local/remote/dynamic)"
    set -l type     $argv[1]   # local | remote | dynamic | socks
    set -l host     $argv[2]
    set -l local_p  $argv[3]
    set -l remote_p $argv[4]
    set -l remote_h (test -n $argv[5] && echo $argv[5] || echo localhost)

    if test -z "$host"
        echo "  Usage:"
        echo "    ssh-tunnel local  <host> <local-port> <remote-port> [remote-host]"
        echo "    ssh-tunnel remote <host> <remote-port> <local-port> [local-host]"
        echo "    ssh-tunnel socks  <host> <local-port>"
        return 1
    end

    switch $type
        case local
            echo $_ssh_cyan"  🔀 Local tunnel: localhost:$local_p → $remote_h:$remote_p via $host"$_ssh_reset
            ssh -N -L $local_p:$remote_h:$remote_p $host
        case remote
            echo $_ssh_cyan"  🔀 Remote tunnel: $host:$local_p → localhost:$remote_p"$_ssh_reset
            ssh -N -R $local_p:localhost:$remote_p $host
        case socks dynamic
            echo $_ssh_cyan"  🧦 SOCKS5 proxy: localhost:$local_p via $host"$_ssh_reset
            ssh -N -D $local_p $host
        case '*'
            echo $_ssh_red"  ✗ Unknown tunnel type: $type"$_ssh_reset
            return 1
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add sas    'ssh-agent-status'
abbr --add saa    'ssh-add-all'
abbr --add saD    'ssh-forget-all'
abbr --add sar    'ssh-restart'
abbr --add sax    'ssh-agent-stop'
abbr --add saF    'ssh-agent-forward'
abbr --add sak    'ssh-keygen-ed25519'
abbr --add sacp   'ssh-copy-id-clip'
abbr --add sah    'ssh-host-add'
abbr --add sast   'ssh-scan-host'
abbr --add satun  'ssh-tunnel'
abbr --add sal    'ssh-add -l'
abbr --add saL    'ssh-add -L'
abbr --add sad    'ssh-add -d'
abbr --add sat    "ssh-add -t $_ash_ssh_timeout"