# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Terraform Ultra Configuration                      ║
# ║  Infrastructure as Code with workspace mgmt, security & full IaC ecosystem ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_terraform_loaded && exit 0
set --global _ash_terraform_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Support terraform, tofu (OpenTofu fork), and terragrunt
function __ash_tf_detect_binary --description "Detect best Terraform-compatible binary"
    for bin in terraform tofu
        command -q $bin && echo $bin && return
    end
    echo ""
end

set --global _ash_tf_bin (__ash_tf_detect_binary)

test -z "$_ash_tf_bin" && exit 0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_tf_log      "$HOME/.local/share/ash/logs/terraform.log"
set --global _ash_tf_cache    "$HOME/.local/share/ash/cache/terraform"
set --global _ash_tf_plans    "$HOME/.local/share/ash/terraform/plans"

mkdir -p (dirname $_ash_tf_log) 2>/dev/null
mkdir -p $_ash_tf_cache 2>/dev/null
mkdir -p $_ash_tf_plans 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _tf_reset   (set_color normal)
set -g _tf_bold    (set_color --bold)
set -g _tf_cyan    (set_color cyan)
set -g _tf_green   (set_color green)
set -g _tf_yellow  (set_color yellow)
set -g _tf_red     (set_color red)
set -g _tf_blue    (set_color blue)
set -g _tf_purple  (set_color 844FBA)   # Terraform purple
set -g _tf_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core settings ─────────────────────────────────────────────────────────────
set --export CHECKPOINT_DISABLE    1     # Disable version check phone home
set --export TF_CLI_ARGS_plan      "-compact-warnings"
set --export TF_CLI_ARGS_apply     "-compact-warnings"
set --export TF_INPUT              0     # Non-interactive mode (override per-cmd)
set --export TF_IN_AUTOMATION      0     # Not in CI by default

# Plugin cache (share providers across projects — huge disk saver)
set --export TF_PLUGIN_CACHE_DIR   "$HOME/.terraform.d/plugin-cache"
mkdir -p $TF_PLUGIN_CACHE_DIR 2>/dev/null

# Log levels: TRACE | DEBUG | INFO | WARN | ERROR | JSON | OFF
set --export TF_LOG               "WARN"
set --export TF_LOG_PATH          "$_ash_tf_log"

# Terragrunt (if installed)
if command -q terragrunt
    set --export TERRAGRUNT_TFPATH $_ash_tf_bin
    set --export TERRAGRUNT_NO_AUTO_INIT false
    set --export TERRAGRUNT_PARALLELISM 10
end

# tfenv / tofuenv support
for tfenv_dir in "$HOME/.tfenv" "$HOME/.tofuenv"
    if test -d "$tfenv_dir/bin" && not contains "$tfenv_dir/bin" $PATH
        fish_add_path --prepend --global "$tfenv_dir/bin"
    end
end

# ── Shell completions ──────────────────────────────────────────────────────────
complete -c terraform -f
$_ash_tf_bin -install-autocomplete 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 PROJECT DETECTION                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_tf_is_project --description "Check if current dir has Terraform files"
    count *.tf 2>/dev/null | grep -qv '^0$' && return 0
    test -f terragrunt.hcl && return 0
    test -f .terraform.lock.hcl && return 0
    return 1
end

function __ash_tf_current_workspace --description "Get current Terraform workspace"
    test -f .terraform/environment && \
        cat .terraform/environment 2>/dev/null || echo "default"
end

function __ash_tf_on_dir_change --on-variable PWD \
    --description "Show Terraform context on directory change"
    __ash_tf_is_project || return

    set -l ws (__ash_tf_current_workspace)
    set -l cache_key (echo (pwd) | md5sum | awk '{print $1}')
    set -l cache_file "$_ash_tf_cache/ws-$cache_key"

    # Only notify if workspace changed
    if test -f $cache_file && test (cat $cache_file) = "$ws"
        return
    end

    echo $ws > $cache_file

    set -l ws_color $_tf_green
    test "$ws" = production && set ws_color $_tf_red
    test "$ws" = prod       && set ws_color $_tf_red

    echo $_tf_dim"  🏗️  Terraform workspace: "$ws_color$ws$_tf_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  CORE TERRAFORM WORKFLOW FUNCTIONS                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── tf: Alias with safety wrapper ────────────────────────────────────────────
function tf --wraps=$_ash_tf_bin --description "Terraform with safety checks"
    set -l cmd $argv[1]

    # Safety: warn on production destroy
    if test "$cmd" = destroy || test "$cmd" = apply
        set -l ws (__ash_tf_current_workspace)
        if test "$ws" = production || test "$ws" = prod
            echo ""
            echo $_tf_red"  ⚠  PRODUCTION WORKSPACE: $ws"$_tf_reset
            echo $_tf_yellow"  Command: $_ash_tf_bin $argv"$_tf_reset
            echo ""
            read -P "  Type 'yes' to confirm: " confirm
            test "$confirm" = yes || begin; echo "  Cancelled."; return 1; end
        end
    end

    $_ash_tf_bin $argv
end

# ─── tf-init: Initialize with module download ─────────────────────────────────
function tf-init --description "Terraform init with upgrade and backend config"
    set -l reconfigure $argv[1]

    echo ""
    echo $_tf_purple"  🏗️  Terraform init..."$_tf_reset
    echo ""

    set -l init_args -upgrade

    if test "$reconfigure" = "--reconfigure"
        set init_args $init_args -reconfigure
    end

    $_ash_tf_bin init $init_args $argv[2..-1]
    set -l rc $status

    if test $rc -eq 0
        echo ""
        echo $_tf_green"  ✓ Initialized"$_tf_reset
        set -l ws (__ash_tf_current_workspace)
        echo "  Workspace: "$_tf_cyan$ws$_tf_reset
    else
        echo $_tf_red"  ✗ Init failed"$_tf_reset
    end
    echo ""
    return $rc
end

# ─── tf-plan-save: Plan with saved output ─────────────────────────────────────
function tf-plan-save --description "Create a saved Terraform plan file"
    __ash_tf_is_project || begin
        echo $_tf_red"  ✗ No Terraform files in current directory"$_tf_reset
        return 1
    end

    set -l env   $argv[1]
    test -z "$env" && set env (__ash_tf_current_workspace)

    set -l ts       (date +%Y%m%d-%H%M%S)
    set -l plan_dir "$_ash_tf_plans/(basename $PWD)"
    set -l plan_file "$plan_dir/$env-$ts.tfplan"
    mkdir -p $plan_dir

    echo ""
    echo $_tf_purple"  📋 Planning: $env ($ts)"$_tf_reset
    echo ""

    set -l plan_vars ""
    if test -f "environments/$env.tfvars"
        set plan_vars "-var-file=environments/$env.tfvars"
    else if test -f "$env.tfvars"
        set plan_vars "-var-file=$env.tfvars"
    end

    TF_INPUT=0 $_ash_tf_bin plan \
        $plan_vars \
        -out=$plan_file \
        -detailed-exitcode \
        $argv[2..-1]

    set -l rc $status

    switch $rc
        case 0
            echo ""
            echo $_tf_green"  ✓ No changes (infrastructure up to date)"$_tf_reset
        case 2
            echo ""
            echo $_tf_yellow"  ✓ Plan saved: $plan_file"$_tf_reset
            set -l plan_size (du -sh $plan_file 2>/dev/null | awk '{print $1}')
            echo "  Size: "$_tf_dim$plan_size$_tf_reset

            # Show summary
            echo ""
            echo "_tf_bold"  Changes Summary:"$_tf_reset
            $_ash_tf_bin show -json $plan_file 2>/dev/null | \
                command -q python3 && python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    changes = data.get('resource_changes', [])
    adds = sum(1 for c in changes if 'create' in c.get('change', {}).get('actions', []))
    upds = sum(1 for c in changes if 'update' in c.get('change', {}).get('actions', []))
    dels = sum(1 for c in changes if 'delete' in c.get('change', {}).get('actions', []))
    print(f'    + Add:    {adds}')
    print(f'    ~ Update: {upds}')
    print(f'    - Delete: {dels}')
except:
    pass
" 2>/dev/null

        case 1
            echo $_tf_red"  ✗ Plan failed"$_tf_reset
    end
    echo ""
    return $rc
end

# ─── tf-apply-plan: Apply a saved plan ────────────────────────────────────────
function tf-apply-plan --description "Apply a saved Terraform plan file"
    set -l plan_file $argv[1]

    if test -z "$plan_file"
        # Interactive picker of saved plans
        set -l plan_dir "$_ash_tf_plans/(basename $PWD)"
        if test -d $plan_dir && command -q fzf
            set plan_file (
                ls -t $plan_dir/*.tfplan 2>/dev/null |
                fzf --ansi \
                    --border-label "  🏗️  Select Plan " \
                    --border rounded \
                    --prompt "  📋 " \
                    --pointer "▶" \
                    --preview "$_ash_tf_bin show {} 2>/dev/null | head -50" \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --header '  Enter:apply  '
            )
            test -z "$plan_file" && return 0
        else
            echo "  Usage: tf-apply-plan <plan-file>"
            return 1
        end
    end

    if not test -f $plan_file
        echo $_tf_red"  ✗ Plan file not found: $plan_file"$_tf_reset
        return 1
    end

    # Safety: show what will be applied
    echo ""
    echo $_tf_purple"  🚀 Applying plan: $plan_file"$_tf_reset
    echo ""

    $_ash_tf_bin show $plan_file 2>/dev/null | head -40
    echo ""

    read -P "  Apply this plan? [y/N] " confirm
    string match -qi 'y*' $confirm || begin; echo "  Cancelled."; return 0; end

    set -l ts (date +%s)
    $_ash_tf_bin apply $plan_file
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)

    echo ""
    if test $rc -eq 0
        echo $_tf_green"  ✓ Apply complete ($elapsed"s")"$_tf_reset
    else
        echo $_tf_red"  ✗ Apply failed"$_tf_reset
    end
    echo ""
    return $rc
end

# ─── tf-workspace-smart: Smart workspace management ───────────────────────────
function tf-workspace-smart --description "Smart Terraform workspace management"
    set -l action $argv[1]
    set -l ws     $argv[2]

    switch $action
        case ls list
            echo ""
            echo $_tf_purple"  🗂️  Terraform Workspaces"$_tf_reset
            echo ""
            $_ash_tf_bin workspace list 2>/dev/null | while read -l line
                if string match -q '* *' $line
                    echo "  "$_tf_green"▶ "(string replace '* ' '' $line)$_tf_reset" (current)"
                else
                    echo "    "$_tf_dim$line$_tf_reset
                end
            end
            echo ""

        case switch use select
            if test -z "$ws" && command -q fzf
                set ws (
                    $_ash_tf_bin workspace list 2>/dev/null |
                    string replace '* ' '' |
                    string trim |
                    fzf --border-label "  🗂️  Select Workspace " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                        --header "  Current: (__ash_tf_current_workspace)  "
                )
                test -z "$ws" && return 0
            end

            # Safety check
            if test "$ws" = production || test "$ws" = prod
                echo ""
                echo $_tf_red"  ⚠  Switching to PRODUCTION workspace!"$_tf_reset
                read -P "  Confirm? [y/N] " confirm
                string match -qi 'y*' $confirm || return 0
            end

            $_ash_tf_bin workspace select $ws
            and echo $_tf_green"  ✓ Workspace: $ws"$_tf_reset

        case new create
            test -z "$ws" && read -P "  New workspace name: " ws
            test -z "$ws" && return 1
            $_ash_tf_bin workspace new $ws
            and echo $_tf_green"  ✓ Created workspace: $ws"$_tf_reset

        case delete rm
            test -z "$ws" && begin; echo "  Usage: tf-workspace-smart delete <name>"; return 1; end
            read -P "  Delete workspace '$ws'? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            $_ash_tf_bin workspace delete $ws
            and echo $_tf_yellow"  ✓ Deleted workspace: $ws"$_tf_reset

        case '*'
            echo "  Usage: tf-workspace-smart <list|switch|new|delete> [name]"
    end
end

# ─── tf-state-smart: Interactive state management ─────────────────────────────
function tf-state-smart --description "Interactive Terraform state management"
    set -l action $argv[1]

    switch $action
        case ls list
            if command -q fzf
                $_ash_tf_bin state list 2>/dev/null | fzf --ansi \
                    --border-label "  🗃️  State Resources " \
                    --border rounded \
                    --prompt "  📋 " \
                    --multi \
                    --preview "$_ash_tf_bin state show {} 2>/dev/null | head -30" \
                    --preview-window 'right:50%:border-rounded:wrap' \
                    --header '  Tab:multi  Enter:select  Ctrl-D:show  '
            else
                $_ash_tf_bin state list 2>/dev/null
            end

        case show
            set -l resource $argv[2]
            if test -z "$resource" && command -q fzf
                set resource (
                    $_ash_tf_bin state list 2>/dev/null |
                    fzf --border-label "  🔍 Show Resource " \
                        --border rounded \
                        --prompt "  " \
                        --preview "$_ash_tf_bin state show {} 2>/dev/null | head -30" \
                        --preview-window 'right:55%:border-rounded:wrap'
                )
                test -z "$resource" && return 0
            end
            $_ash_tf_bin state show $resource 2>/dev/null | \
                command -q bat && bat --language=hcl --style=plain --color=always || cat

        case mv move rename
            test (count $argv) -lt 3 && begin; echo "  Usage: tf-state-smart mv <from> <to>"; return 1; end
            echo $_tf_yellow"  Moving: $argv[2] → $argv[3]"$_tf_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            $_ash_tf_bin state mv $argv[2] $argv[3]
            and echo $_tf_green"  ✓ Moved"$_tf_reset

        case rm remove
            set -l resource $argv[2]
            if test -z "$resource" && command -q fzf
                set resource (
                    $_ash_tf_bin state list 2>/dev/null |
                    fzf --border-label "  ⚠  Remove from State " \
                        --border rounded \
                        --prompt "  🗑  " \
                        --header '  This removes from state only (not real infra)  '
                )
                test -z "$resource" && return 0
            end
            echo $_tf_yellow"  Removing from state: $resource"$_tf_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            $_ash_tf_bin state rm $resource
            and echo $_tf_green"  ✓ Removed from state"$_tf_reset

        case import
            test (count $argv) -lt 3 && begin; echo "  Usage: tf-state-smart import <resource> <id>"; return 1; end
            echo $_tf_cyan"  Importing: $argv[2] (id: $argv[3])"$_tf_reset
            $_ash_tf_bin import $argv[2] $argv[3]
            and echo $_tf_green"  ✓ Imported"$_tf_reset

        case backup
            set -l backup_file "terraform-state-backup-"(date +%Y%m%d%H%M%S)".json"
            $_ash_tf_bin state pull > $backup_file 2>/dev/null
            and echo $_tf_green"  ✓ State backed up: $backup_file"$_tf_reset

        case '*'
            echo "  Usage: tf-state-smart <list|show|mv|rm|import|backup>"
    end
end

# ─── tf-validate-full: Comprehensive validation ────────────────────────────────
function tf-validate-full --description "Full Terraform validation: validate + fmt + security"
    echo ""
    echo $_tf_purple"  🔍 Full Terraform validation..."$_tf_reset
    echo ""

    set -l errors 0

    # Format check
    $_ash_tf_bin fmt -check -recursive . 2>/dev/null
    and echo $_tf_green"  ✓ fmt"$_tf_reset \
    || begin; echo $_tf_yellow"  ⚠ fmt (run: tf-fmt)"$_tf_reset; set errors (math $errors + 1); end

    # Validate
    $_ash_tf_bin validate 2>/dev/null
    and echo $_tf_green"  ✓ validate"$_tf_reset \
    || begin; echo $_tf_red"  ✗ validate failed"$_tf_reset; set errors (math $errors + 1); end

    # tfsec security scan
    if command -q tfsec
        tfsec . --no-color 2>/dev/null | tail -5
        and echo $_tf_green"  ✓ tfsec security"$_tf_reset \
        || begin; echo $_tf_yellow"  ⚠ tfsec warnings"$_tf_reset; end
    end

    # checkov
    if command -q checkov
        checkov -d . --quiet 2>/dev/null
        and echo $_tf_green"  ✓ checkov"$_tf_reset \
        || begin; echo $_tf_yellow"  ⚠ checkov warnings"$_tf_reset; end
    end

    # terrascan
    if command -q terrascan
        terrascan scan 2>/dev/null
        and echo $_tf_green"  ✓ terrascan"$_tf_reset
    end

    echo ""
    test $errors -eq 0 \
        && echo $_tf_green"  ✓ All validations passed"$_tf_reset \
        || echo $_tf_red"  ✗ $errors validation(s) failed"$_tf_reset
    echo ""
    return $errors
end

# ─── tf-costs: Estimate infrastructure costs ──────────────────────────────────
function tf-costs --description "Estimate Terraform infrastructure costs with infracost"
    if not command -q infracost
        echo $_tf_yellow"  💡 Install infracost: https://www.infracost.io"$_tf_reset
        return 1
    end

    echo ""
    echo $_tf_purple"  💰 Estimating infrastructure costs..."$_tf_reset
    echo ""

    infracost breakdown --path . --format table 2>/dev/null
end

# ─── tf-graph: Generate dependency graph ──────────────────────────────────────
function tf-graph --description "Generate and visualize Terraform dependency graph"
    set -l format $argv[1]
    test -z "$format" && set format svg

    echo ""
    echo $_tf_cyan"  📊 Generating dependency graph..."$_tf_reset

    if command -q dot
        set -l output_file "terraform-graph.$format"
        $_ash_tf_bin graph 2>/dev/null | dot -T$format -o $output_file
        and begin
            echo $_tf_green"  ✓ Graph: $output_file"$_tf_reset
            command -q xdg-open && xdg-open $output_file 2>/dev/null
        end
    else
        echo $_tf_yellow"  💡 Install graphviz for visualization"$_tf_reset
        $_ash_tf_bin graph 2>/dev/null
    end
    echo ""
end

# ─── tf-info: Rich Terraform environment info ─────────────────────────────────
function tf-info --description "Show Terraform environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l purple (set_color 844FBA)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$purple"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$purple"  ║     🏗️   Terraform Environment Dashboard              ║"$reset
    echo $bold$purple"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Binary:      "$reset $cyan$_ash_tf_bin$reset
    echo "  "$bold"Version:     "$reset $dim($_ash_tf_bin --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Plugin cache:"$reset $dim$TF_PLUGIN_CACHE_DIR$reset
    set -l cache_size (du -sh $TF_PLUGIN_CACHE_DIR 2>/dev/null | awk '{print $1}')
    test -n "$cache_size" && echo "  "$bold"Cache size:  "$reset $cyan$cache_size$reset
    echo ""

    if __ash_tf_is_project
        echo "  "$green"✓ Terraform project detected"$reset
        echo "  "$bold"Workspace:   "$reset $cyan(__ash_tf_current_workspace)$reset

        # Count resources
        if test -f .terraform.lock.hcl
            set -l provider_count (grep -c 'provider "' .terraform.lock.hcl 2>/dev/null)
            echo "  "$bold"Providers:   "$reset $cyan$provider_count$reset
        end

        # Count .tf files
        set -l tf_count (count *.tf 2>/dev/null)
        echo "  "$bold".tf files:   "$reset $cyan$tf_count$reset

        # Backend type
        for cfg in *.tf
            set -l backend (grep -oP '(?<=backend ")[^"]+' $cfg 2>/dev/null | head -1)
            if test -n "$backend"
                echo "  "$bold"Backend:     "$reset $dim$backend$reset
                break
            end
        end
    end

    echo ""
    echo "  "$bold"Tools:"$reset
    for tool in tfsec checkov terrascan infracost terragrunt tfenv
        if command -q $tool
            echo "    "$green"✓ "$reset$tool" "($dim(command -v $tool)$reset)
        end
    end
    echo ""
end

# ─── tf-fmt: Format all .tf files ─────────────────────────────────────────────
function tf-fmt --description "Format all Terraform files recursively"
    echo ""
    echo $_tf_cyan"  🎨 Formatting Terraform files..."$_tf_reset
    $_ash_tf_bin fmt -recursive . 2>/dev/null
    and echo $_tf_green"  ✓ All files formatted"$_tf_reset
    echo ""
end

# ─── tf-destroy-safe: Safe destroy with backup ────────────────────────────────
function tf-destroy-safe --description "Terraform destroy with state backup first"
    echo ""
    echo $_tf_red"  ⚠  TERRAFORM DESTROY — This will DELETE infrastructure!"$_tf_reset
    echo ""

    # Backup state first
    set -l backup "state-pre-destroy-"(date +%Y%m%d%H%M%S)".json"
    $_ash_tf_bin state pull > $backup 2>/dev/null
    echo $_tf_yellow"  ✓ State backed up: $backup"$_tf_reset

    read -P "  Type 'destroy' to confirm: " confirm
    test "$confirm" = destroy || begin; echo "  Cancelled."; return 0; end

    $_ash_tf_bin destroy -auto-approve $argv
    and echo $_tf_green"  ✓ Infrastructure destroyed"$_tf_reset
    or  echo $_tf_red"  ✗ Destroy failed (state backup: $backup)"$_tf_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add tf      'tf'
abbr --add tfi     'tf-init'
abbr --add tfir    'tf-init --reconfigure'
abbr --add tfp     'tf-plan-save'
abbr --add tfa     'tf-apply-plan'
abbr --add tfaa    "$_ash_tf_bin apply -auto-approve"
abbr --add tfd     'tf-destroy-safe'
abbr --add tfv     "$_ash_tf_bin validate"
abbr --add tffmt   'tf-fmt'
abbr --add tfchk   'tf-validate-full'
abbr --add tfo     "$_ash_tf_bin output"
abbr --add tfoj    "$_ash_tf_bin output -json"
abbr --add tfr     "$_ash_tf_bin refresh"
abbr --add tfg     'tf-graph'

# State
abbr --add tfs     'tf-state-smart list'
abbr --add tfss    'tf-state-smart show'
abbr --add tfsb    'tf-state-smart backup'
abbr --add tfsm    'tf-state-smart mv'
abbr --add tfsrm   'tf-state-smart rm'
abbr --add tfsi    'tf-state-smart import'

# Workspace
abbr --add tfw     'tf-workspace-smart list'
abbr --add tfws    'tf-workspace-smart switch'
abbr --add tfwn    'tf-workspace-smart new'
abbr --add tfwd    'tf-workspace-smart delete'

# Info
abbr --add tfinfo  'tf-info'
abbr --add tfcost  'tf-costs'
abbr --add tfver   "$_ash_tf_bin --version"
abbr --add tfprov  "$_ash_tf_bin providers"
abbr --add tflck   "$_ash_tf_bin force-unlock"

# Terragrunt
abbr --add tg     'terragrunt'
abbr --add tgp    'terragrunt plan'
abbr --add tga    'terragrunt apply'
abbr --add tgd    'terragrunt destroy'
abbr --add tgra   'terragrunt run-all'
abbr --add tgrap  'terragrunt run-all plan'
abbr --add tgraa  'terragrunt run-all apply'