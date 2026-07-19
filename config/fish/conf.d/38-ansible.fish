# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Ansible Ultra Configuration                        ║
# ║  Configuration management, playbooks, vault, inventory & full IaC support  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_ansible_loaded && exit 0
set --global _ash_ansible_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

command -q ansible || exit 0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_ansible_log      "$HOME/.local/share/ash/logs/ansible.log"
set --global _ash_ansible_cache    "$HOME/.local/share/ash/cache/ansible"
set --global _ash_ansible_cfg_dir  "$HOME/.config/ansible"
set --global _ash_ansible_roles    "$HOME/.ansible/roles"

mkdir -p (dirname $_ash_ansible_log) 2>/dev/null
mkdir -p $_ash_ansible_cache         2>/dev/null
mkdir -p $_ash_ansible_cfg_dir       2>/dev/null
mkdir -p $_ash_ansible_roles         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _an_reset   (set_color normal)
set -g _an_bold    (set_color --bold)
set -g _an_cyan    (set_color cyan)
set -g _an_green   (set_color green)
set -g _an_yellow  (set_color yellow)
set -g _an_red     (set_color red)
set -g _an_blue    (set_color blue)
set -g _an_dim     (set_color brblack)
set -g _an_ansible (set_color EE0000)  # Ansible red

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core config ────────────────────────────────────────────────────────────────
set --export ANSIBLE_CONFIG           "$HOME/.config/ansible/ansible.cfg"
set --export ANSIBLE_ROLES_PATH       "$HOME/.ansible/roles:/usr/share/ansible/roles"
set --export ANSIBLE_COLLECTIONS_PATH "$HOME/.ansible/collections:/usr/share/ansible/collections"

# Performance tuning
set --export ANSIBLE_PIPELINING        true
set --export ANSIBLE_SSH_PIPELINING    true
set --export ANSIBLE_FORKS             20
set --export ANSIBLE_GATHERING         smart
set --export ANSIBLE_FACT_CACHING      jsonfile
set --export ANSIBLE_FACT_CACHING_CONNECTION "$HOME/.ansible/facts_cache"
set --export ANSIBLE_FACT_CACHING_TIMEOUT    3600

mkdir -p "$HOME/.ansible/facts_cache" 2>/dev/null

# Display
set --export ANSIBLE_STDOUT_CALLBACK  yaml
set --export ANSIBLE_FORCE_COLOR      1
set --export ANSIBLE_DIFF_ALWAYS      false

# ── Vault ─────────────────────────────────────────────────────────────────────
# Auto-detect vault password file
for vault_file in \
    "$HOME/.ansible/vault-password" \
    "$HOME/.vault-password" \
    ".vault-password"
    if test -f $vault_file
        set --export ANSIBLE_VAULT_PASSWORD_FILE $vault_file
        break
    end
end

# ── Generate ansible.cfg if missing ───────────────────────────────────────────
if not test -f $ANSIBLE_CONFIG
    cat > $ANSIBLE_CONFIG << 'EOF'
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ansible.cfg — ASH DOTFILES v5.0                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

[defaults]
# Performance
forks              = 20
gathering          = smart
fact_caching       = jsonfile
fact_caching_connection = ~/.ansible/facts_cache
fact_caching_timeout = 3600
pipelining         = True

# Display
stdout_callback    = yaml
force_color        = True
display_skipped_hosts = False

# SSH
remote_user        = ansible
host_key_checking  = False
ssh_args           = -C -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no

# Roles/collections
roles_path         = ~/.ansible/roles
collections_paths  = ~/.ansible/collections

# Logging
log_path           = ~/.local/share/ash/logs/ansible.log

[privilege_escalation]
become             = False
become_method      = sudo
become_user        = root
become_ask_pass    = False

[ssh_connection]
pipelining         = True
control_path       = /tmp/ansible-ssh-%%h-%%p-%%r
EOF
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 PROJECT DETECTION                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_ansible_is_project --description "Check if current dir has Ansible files"
    for indicator in \
        ansible.cfg \
        playbook.yml playbook.yaml \
        site.yml site.yaml \
        inventory hosts
        test -f $indicator && return 0
    end
    test -d roles      && return 0
    test -d playbooks  && return 0
    test -d inventory  && return 0
    return 1
end

function __ash_ansible_on_dir_change --on-variable PWD \
    --description "Detect Ansible project on directory change"
    __ash_ansible_is_project || return

    # Use local ansible.cfg if present
    if test -f ansible.cfg
        set --export ANSIBLE_CONFIG (realpath ansible.cfg)
        echo $_an_dim"  🔴 Ansible project (local config)"$_an_reset
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  CORE ANSIBLE FUNCTIONS                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── ansible-play: Run playbook with smart options ────────────────────────────
function ansible-play --description "Run Ansible playbook with smart options"
    set -l playbook  $argv[1]
    set -l inventory $argv[2]
    set -l tags      $argv[3]

    # Auto-detect playbook
    if test -z "$playbook"
        if command -q fzf
            set playbook (
                find . -name "*.yml" -o -name "*.yaml" 2>/dev/null |
                grep -v ".galaxy" | grep -v "requirements" |
                fzf --ansi \
                    --border-label "  🔴 Select Playbook " \
                    --border rounded \
                    --prompt "  📋 " \
                    --pointer "▶" \
                    --preview 'bat --language=yaml --style=plain --color=always {} 2>/dev/null || cat {}' \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --header '  Enter:run  '
            )
            test -z "$playbook" && return 0
        else
            echo "  Usage: ansible-play <playbook.yml> [inventory] [tags]"
            return 1
        end
    end

    # Auto-detect inventory
    if test -z "$inventory"
        for inv_candidate in hosts inventory inventory/hosts inventory/production.yml
            if test -f $inv_candidate
                set inventory $inv_candidate
                break
            end
        end
    end

    set -l run_cmd ansible-playbook $playbook

    # Add inventory
    test -n "$inventory" && set run_cmd $run_cmd -i $inventory

    # Add tags
    test -n "$tags" && set run_cmd $run_cmd --tags $tags

    # Add verbosity flag if ANSIBLE_VERBOSE is set
    set -q ANSIBLE_VERBOSE && set run_cmd $run_cmd -v

    echo ""
    echo $_an_ansible"  🔴 Running playbook: $playbook"$_an_reset
    test -n "$inventory" && echo "  Inventory: "$_an_dim$inventory$_an_reset
    test -n "$tags"      && echo "  Tags:      "$_an_dim$tags$_an_reset
    echo ""

    set -l ts (date +%s)
    eval $run_cmd $argv[4..-1]
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)

    echo ""
    if test $rc -eq 0
        echo $_an_green"  ✓ Playbook complete ($elapsed"s")"$_an_reset
    else
        echo $_an_red"  ✗ Playbook failed ($elapsed"s")"$_an_reset
    end
    echo ""
    return $rc
end

# ─── ansible-check: Dry-run playbook ──────────────────────────────────────────
function ansible-check --description "Dry-run Ansible playbook (--check --diff)"
    set -l playbook  $argv[1]
    set -l inventory $argv[2]

    test -z "$playbook" && begin; echo "  Usage: ansible-check <playbook.yml> [inventory]"; return 1; end

    set -l check_cmd ansible-playbook --check --diff $playbook
    test -n "$inventory" && set check_cmd $check_cmd -i $inventory

    echo ""
    echo $_an_cyan"  🔍 Check mode: $playbook"$_an_reset
    echo ""
    eval $check_cmd $argv[3..-1]
end

# ─── ansible-ping: Ping inventory hosts ───────────────────────────────────────
function ansible-ping --description "Ping all hosts in inventory"
    set -l pattern   $argv[1]
    set -l inventory $argv[2]

    test -z "$pattern" && set pattern all

    set -l ping_cmd ansible $pattern -m ping
    test -n "$inventory" && set ping_cmd $ping_cmd -i $inventory

    echo ""
    echo $_an_cyan"  🏓 Pinging: $pattern"$_an_reset
    echo ""
    eval $ping_cmd $argv[3..-1]
end

# ─── ansible-facts: Gather and display facts ──────────────────────────────────
function ansible-facts --description "Gather facts from hosts interactively"
    set -l host      $argv[1]
    set -l fact      $argv[2]
    set -l inventory $argv[3]

    if test -z "$host"
        echo "  Usage: ansible-facts <host|group> [fact-filter] [inventory]"
        return 1
    end

    set -l facts_cmd ansible $host -m setup

    test -n "$inventory" && set facts_cmd $facts_cmd -i $inventory
    test -n "$fact"      && set facts_cmd $facts_cmd --args "filter=$fact"

    echo ""
    echo $_an_cyan"  📊 Gathering facts: $host"$_an_reset
    echo ""

    eval $facts_cmd $argv[4..-1] 2>/dev/null | \
        command -q bat && bat --language=json --style=plain --color=always || cat
end

# ─── ansible-vault-smart: Smart vault operations ─────────────────────────────
function ansible-vault-smart --description "Smart Ansible vault management"
    set -l action $argv[1]
    set -l file   $argv[2]

    switch $action
        case encrypt
            test -z "$file" && begin; echo "  Usage: ansible-vault-smart encrypt <file>"; return 1; end
            ansible-vault encrypt $file
            and echo $_an_green"  ✓ Encrypted: $file"$_an_reset

        case decrypt
            test -z "$file" && begin; echo "  Usage: ansible-vault-smart decrypt <file>"; return 1; end
            echo $_an_yellow"  ⚠  Decrypting vault file (will be plaintext!)"$_an_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            ansible-vault decrypt $file
            and echo $_an_yellow"  ✓ Decrypted: $file (re-encrypt when done!)"$_an_reset

        case view
            test -z "$file" && begin; echo "  Usage: ansible-vault-smart view <file>"; return 1; end
            ansible-vault view $file 2>/dev/null | \
                command -q bat && bat --language=yaml --style=plain --color=always || cat

        case edit
            test -z "$file" && begin; echo "  Usage: ansible-vault-smart edit <file>"; return 1; end
            EDITOR="${EDITOR:-nvim}" ansible-vault edit $file

        case rekey
            test -z "$file" && begin; echo "  Usage: ansible-vault-smart rekey <file>"; return 1; end
            ansible-vault rekey $file
            and echo $_an_green"  ✓ Rekeyed: $file"$_an_reset

        case new create
            set -l new_file $argv[2]
            test -z "$new_file" && read -P "  New vault file name: " new_file
            test -z "$new_file" && return 1
            ansible-vault create $new_file
            and echo $_an_green"  ✓ Vault created: $new_file"$_an_reset

        case encrypt-string
            set -l var_name $argv[2]
            test -z "$var_name" && read -P "  Variable name: " var_name
            ansible-vault encrypt_string --vault-id default --name "$var_name"

        case '*'
            echo "  Usage: ansible-vault-smart <encrypt|decrypt|view|edit|rekey|new|encrypt-string>"
    end
end

# ─── ansible-inventory-view: Rich inventory display ───────────────────────────
function ansible-inventory-view --description "Display Ansible inventory in rich format"
    set -l inventory $argv[1]

    set -l inv_cmd ansible-inventory
    test -n "$inventory" && set inv_cmd $inv_cmd -i $inventory

    set -l view_type $argv[2]
    test -z "$view_type" && set view_type list

    echo ""
    echo $_an_bold$_an_ansible"  🗂️  Ansible Inventory"$_an_reset
    echo ""

    switch $view_type
        case list
            eval $inv_cmd --list 2>/dev/null | \
                command -q python3 && python3 -m json.tool | \
                command -q bat && bat --language=json --style=plain --color=always || cat

        case graph
            eval $inv_cmd --graph 2>/dev/null | while read -l line
                if string match -q '@*:' $line
                    echo "  "$_an_bold$_an_cyan$line$_an_reset
                else if string match -q '  |--*' $line
                    echo "  "$_an_green$line$_an_reset
                else
                    echo "  "$_an_dim$line$_an_reset
                end
            end

        case hosts
            eval $inv_cmd --list 2>/dev/null | \
                command -q python3 && python3 -c "
import json, sys
data = json.load(sys.stdin)
hosts = data.get('_meta', {}).get('hostvars', {})
for host, vars in sorted(hosts.items()):
    ip = vars.get('ansible_host', vars.get('ansible_ip', ''))
    user = vars.get('ansible_user', '')
    print(f'  {host:<30} {ip:<20} {user}')
" || eval $inv_cmd --host all 2>/dev/null
    end
    echo ""
end

# ─── ansible-role-new: Scaffold a new Ansible role ────────────────────────────
function ansible-role-new --description "Scaffold a new Ansible role with full structure"
    set -l name $argv[1]

    if test -z "$name"
        read -P "  Role name: " name
    end
    test -z "$name" && return 1

    set -l role_dir "roles/$name"

    if test -d $role_dir
        echo $_an_yellow"  ⚠  Role already exists: $role_dir"$_an_reset
        return 1
    end

    echo ""
    echo $_an_cyan"  🎭 Creating role: $name"$_an_reset

    # Create structure
    ansible-galaxy role init --role-skeleton /dev/null $role_dir 2>/dev/null || \
    begin
        # Manual scaffold
        for subdir in tasks handlers templates files vars defaults meta tests
            mkdir -p "$role_dir/$subdir"
        end

        # tasks/main.yml
        printf '---\n# Tasks for role: %s\n# Generated by ASH DOTFILES v5.0\n\n- name: "Include OS-specific variables"\n  ansible.builtin.include_vars:\n    file: "{{ ansible_os_family }}.yml"\n  ignore_errors: true\n\n- name: "Main task"\n  ansible.builtin.debug:\n    msg: "Role %s running on {{ inventory_hostname }}"\n' \
            $name $name > "$role_dir/tasks/main.yml"

        # defaults/main.yml
        printf '---\n# Default variables for role: %s\n\n%s_enabled: true\n%s_version: "latest"\n' \
            $name $name $name > "$role_dir/defaults/main.yml"

        # vars/main.yml
        printf '---\n# Variables for role: %s (override defaults here)\n' \
            $name > "$role_dir/vars/main.yml"

        # handlers/main.yml
        printf '---\n# Handlers for role: %s\n\n- name: "restart %s"\n  ansible.builtin.service:\n    name: "%s"\n    state: restarted\n' \
            $name $name $name > "$role_dir/handlers/main.yml"

        # meta/main.yml
        printf '---\ngalaxy_info:\n  role_name: %s\n  author: %s\n  description: ""\n  min_ansible_version: "2.14"\n  platforms:\n    - name: Ubuntu\n      versions: ["22.04", "24.04"]\n    - name: EL\n      versions: ["9"]\ndependencies: []\n' \
            $name $USER > "$role_dir/meta/main.yml"

        # README.md
        printf '# Ansible Role: %s\n\n## Requirements\n\n## Role Variables\n\n## Dependencies\n\n## Example Playbook\n\n```yaml\n- hosts: all\n  roles:\n    - %s\n```\n' \
            $name $name > "$role_dir/README.md"

        # tests/test.yml
        printf '---\n- hosts: localhost\n  remote_user: root\n  roles:\n    - %s\n' \
            $name > "$role_dir/tests/test.yml"
    end

    echo ""
    for f in (find $role_dir -type f | sort)
        echo "  "$_an_green"✓"$_an_reset" $f"
    end

    echo ""
    echo $_an_green"  ✓ Role created: $role_dir"$_an_reset
    echo ""
end

# ─── ansible-galaxy-smart: Enhanced galaxy operations ─────────────────────────
function ansible-galaxy-smart --description "Enhanced ansible-galaxy operations"
    set -l action $argv[1]

    switch $action
        case install
            # Install from requirements.yml if no arg given
            if test (count $argv) -lt 2
                for req_file in requirements.yml requirements.yaml
                    if test -f $req_file
                        echo $_an_cyan"  📦 Installing from $req_file..."$_an_reset
                        ansible-galaxy install -r $req_file --force 2>/dev/null
                        ansible-galaxy collection install -r $req_file --force 2>/dev/null
                        return
                    end
                end
                echo "  Usage: ansible-galaxy-smart install [role|collection]"
                return 1
            end
            ansible-galaxy install $argv[2..-1]

        case update
            echo $_an_cyan"  🔄 Updating all roles..."$_an_reset
            for req_file in requirements.yml requirements.yaml
                if test -f $req_file
                    ansible-galaxy install -r $req_file --force
                    ansible-galaxy collection install -r $req_file --force
                    return
                end
            end
            echo "  No requirements.yml found"

        case list roles
            echo ""
            echo $_an_bold$_an_ansible"  🎭 Installed Roles"$_an_reset
            echo ""
            ansible-galaxy list 2>/dev/null | while read -l line
                echo "  "$_an_dim$line$_an_reset
            end

        case list-collections collections
            echo ""
            echo $_an_bold$_an_ansible"  📦 Installed Collections"$_an_reset
            echo ""
            ansible-galaxy collection list 2>/dev/null | while read -l line
                echo "  "$_an_dim$line$_an_reset
            end

        case search
            test (count $argv) -lt 2 && begin; echo "  Usage: ansible-galaxy-smart search <query>"; return 1; end
            ansible-galaxy search $argv[2..-1]

        case '*'
            echo "  Usage: ansible-galaxy-smart <install|update|list|collections|search>"
    end
end

# ─── ansible-adhoc: Run ad-hoc commands interactively ─────────────────────────
function ansible-adhoc --description "Run Ansible ad-hoc commands"
    set -l pattern   $argv[1]
    set -l module    $argv[2]
    set -l args      $argv[3]
    set -l inventory $argv[4]

    if test -z "$pattern"
        read -P "  Host pattern [all]: " pattern
        test -z "$pattern" && set pattern all
    end

    if test -z "$module"
        if command -q fzf
            set module (
                printf 'ping\nshell\ncommand\ncopy\nfile\nservice\npackage\nuser\ngroup\ncron\nfetch\narchive\nunarchive\ngit\ntemplate\nlineinfile\nblockinfile\nget_url\nuri\ndebug\nsetup\n' |
                fzf --border-label "  🔴 Select Module " \
                    --border rounded \
                    --prompt "  📦 " \
                    --pointer "▶" \
                    --no-multi
            )
            test -z "$module" && return 0
        else
            read -P "  Module [shell]: " module
            test -z "$module" && set module shell
        end
    end

    if test -z "$args" && test "$module" = shell || test "$module" = command
        read -P "  Command: " args
    end

    set -l adhoc_cmd ansible $pattern -m $module
    test -n "$args"      && set adhoc_cmd $adhoc_cmd -a "$args"
    test -n "$inventory" && set adhoc_cmd $adhoc_cmd -i $inventory

    echo ""
    echo $_an_ansible"  🔴 $pattern — $module"(test -n "$args" && echo ": $args")$_an_reset
    echo ""
    eval $adhoc_cmd $argv[5..-1]
end

# ─── ansible-info: Ansible environment dashboard ──────────────────────────────
function ansible-info --description "Show Ansible environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l ansible_red (set_color EE0000)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$ansible_red"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$ansible_red"  ║     🔴  Ansible Environment Dashboard                ║"$reset
    echo $bold$ansible_red"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:     "$reset $cyan(ansible --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Python:      "$reset $dim(ansible --version 2>/dev/null | grep 'python' | head -1 | awk '{print $NF}')$reset
    echo "  "$bold"Config:      "$reset $dim$ANSIBLE_CONFIG$reset
    echo "  "$bold"Roles path:  "$reset $dim$ANSIBLE_ROLES_PATH$reset
    echo "  "$bold"Collections: "$reset $dim$ANSIBLE_COLLECTIONS_PATH$reset
    echo "  "$bold"Forks:       "$reset $cyan$ANSIBLE_FORKS$reset
    echo ""

    # Vault
    if test -n "$ANSIBLE_VAULT_PASSWORD_FILE"
        echo "  "$bold"Vault:       "$reset $green"configured "$dim"($ANSIBLE_VAULT_PASSWORD_FILE)"$reset
    end

    # Project detection
    if __ash_ansible_is_project
        echo "  "$green"✓ Ansible project detected"$reset

        # Count playbooks
        set -l pb_count (count *.yml *.yaml 2>/dev/null | grep -v '^0$' | head -1)
        test -n "$pb_count" && echo "  Playbooks:   $pb_count"

        # Roles
        if test -d roles
            set -l role_count (count roles/*/ 2>/dev/null)
            echo "  Roles:       "$role_count
        end
    end

    echo ""
    echo "  "$bold"Tools:"$reset
    for tool in ansible-lint molecule mitogen ara yamllint
        command -q $tool && echo "    "$green"✓ "$reset$tool
    end
    echo ""
end

# ─── ansible-lint-smart: Run ansible-lint ─────────────────────────────────────
function ansible-lint-smart --description "Run ansible-lint on project"
    command -q ansible-lint || begin
        echo $_an_yellow"  💡 Install: pip install ansible-lint"$_an_reset
        return 1
    end

    echo ""
    echo $_an_cyan"  🔍 Running ansible-lint..."$_an_reset
    echo ""

    if test -f .ansible-lint
        ansible-lint $argv
    else
        ansible-lint --profile production $argv
    end

    set -l rc $status
    echo ""
    test $rc -eq 0 \
        && echo $_an_green"  ✓ No issues found"$_an_reset \
        || echo $_an_yellow"  ⚠ Lint issues found"$_an_reset
    echo ""
    return $rc
end

# ─── ansible-molecule: Molecule test wrapper ──────────────────────────────────
function ansible-molecule --description "Run Molecule tests for role"
    command -q molecule || begin
        echo $_an_yellow"  💡 Install: pip install molecule"$_an_reset
        return 1
    end

    set -l action $argv[1]
    test -z "$action" && set action test

    echo ""
    echo $_an_cyan"  🧪 molecule $action"$_an_reset
    echo ""
    molecule $action $argv[2..-1]
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ap      'ansible-play'
abbr --add apc     'ansible-check'
abbr --add aping   'ansible-ping'
abbr --add afacts  'ansible-facts'
abbr --add ainfo   'ansible-info'
abbr --add alint   'ansible-lint-smart'
abbr --add amol    'ansible-molecule'
abbr --add aadhoc  'ansible-adhoc'
abbr --add ainv    'ansible-inventory-view'
abbr --add ainvg   'ansible-inventory-view "" graph'

# Vault
abbr --add ave     'ansible-vault-smart encrypt'
abbr --add avd     'ansible-vault-smart decrypt'
abbr --add avv     'ansible-vault-smart view'
abbr --add ave2    'ansible-vault-smart edit'
abbr --add avs     'ansible-vault-smart encrypt-string'

# Galaxy
abbr --add agi     'ansible-galaxy-smart install'
abbr --add agu     'ansible-galaxy-smart update'
abbr --add agl     'ansible-galaxy-smart list'
abbr --add agc     'ansible-galaxy-smart collections'
abbr --add ags     'ansible-galaxy-smart search'

# Role
abbr --add arnew   'ansible-role-new'
abbr --add arls    'ansible-galaxy list'

# Direct ansible commands
abbr --add ans     'ansible'
abbr --add ansall  'ansible all'
abbr --add anspb   'ansible-playbook'
abbr --add ansinv  'ansible-inventory'
abbr --add ansdoc  'ansible-doc'
abbr --add anscfg  'ansible-config'
abbr --add ansver  'ansible --version'