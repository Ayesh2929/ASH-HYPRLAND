# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏗️   TERRAFORM — FISH COMPLETIONS v5.0 OMEGA                               ║
# ║  Ultra Premium • Dynamic Resources • Live State • Multi-Workspace           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
#  GUARDS & HELPERS
# ══════════════════════════════════════════════════════════════════════════════

function __tf_no_subcommand
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            apply console destroy fmt force-unlock get graph import init \
            login logout metadata output plan providers refresh show \
            state taint test untaint validate version workspace \
            -help -version -chdir
            return 1
        end
    end
    return 0
end

function __tf_sub_is --argument-names sub
    contains -- "$sub" (commandline -poc)
end

function __tf_seen_flag --argument-names flag
    contains -- "$flag" (commandline -poc)
end

function __tf_pos --argument-names n
    set -l tokens (commandline -poc)
    set -l pos 0
    for t in $tokens[2..]
        if not string match -qr '^-' $t
            set pos (math $pos + 1)
            if test "$pos" -eq "$n"
                echo $t
                return
            end
        end
    end
end

function __tf_in_dir
    # True if we're in a terraform project directory
    test -f main.tf; or test -f terraform.tf; or test -f versions.tf; \
        or test -d .terraform; or test -f .terraform.lock.hcl
end

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC DATA SOURCES
# ══════════════════════════════════════════════════════════════════════════════

# ── Workspaces ─────────────────────────────────────────────────────────────────
function __tf_workspaces
    if not __tf_in_dir; return; end
    terraform workspace list 2>/dev/null | \
        string replace -r '^\*?\s+' '' | \
        string match -rv '^$' | \
        while read -l ws
            set -l active (terraform workspace show 2>/dev/null)
            if test "$ws" = "$active"
                printf "%s\t★ Active workspace\n" "$ws"
            else
                printf "%s\tWorkspace\n" "$ws"
            end
        end
end

# ── State resources ────────────────────────────────────────────────────────────
function __tf_state_resources
    if not __tf_in_dir; return; end
    terraform state list 2>/dev/null | \
        while read -l r
            # Color-code by type
            set -l rtype (string split "." "$r")[1]
            printf "%s\t%s\n" "$r" "$rtype"
        end
end

# ── State resources (modules only) ────────────────────────────────────────────
function __tf_state_modules
    terraform state list 2>/dev/null | \
        string match -r '^module\.' | \
        string replace -r '\.[^.]+$' '' | \
        sort -u
end

# ── Output names ──────────────────────────────────────────────────────────────
function __tf_outputs
    if not __tf_in_dir; return; end
    terraform output 2>/dev/null | \
        awk -F' = ' '{printf "%s\tOutput value\n", $1}'
end

# ── Variables from .tf files ──────────────────────────────────────────────────
function __tf_variables
    if not __tf_in_dir; return; end
    find . -maxdepth 1 -name "*.tf" -type f 2>/dev/null | xargs grep -h 'variable "' 2>/dev/null | \
        sed 's/variable "\(.*\)".*/\1/' | \
        while read -l v
            printf "%s\tTF variable\n" "$v"
        end
end

# ── Provider names ─────────────────────────────────────────────────────────────
function __tf_providers
    if not __tf_in_dir; return; end
    terraform providers 2>/dev/null | \
        grep -o 'registry.terraform.io/[^"]*' | \
        awk -F'/' '{print $NF}' | \
        sort -u
    # Common providers fallback
    printf '%s\t%s\n' \
        aws          "Amazon Web Services" \
        azurerm      "Microsoft Azure" \
        google       "Google Cloud Platform" \
        kubernetes   "Kubernetes" \
        helm         "Helm charts" \
        docker       "Docker containers" \
        vault        "HashiCorp Vault" \
        consul       "HashiCorp Consul" \
        github       "GitHub" \
        gitlab       "GitLab" \
        cloudflare   "Cloudflare" \
        datadog      "Datadog" \
        newrelic     "New Relic" \
        pagerduty    "PagerDuty" \
        digitalocean "DigitalOcean" \
        linode       "Linode" \
        hcloud       "Hetzner Cloud" \
        ovh          "OVH Cloud" \
        null         "Null provider" \
        random       "Random provider" \
        local        "Local provider" \
        tls          "TLS provider" \
        time         "Time provider" \
        http         "HTTP provider" \
        archive      "Archive provider" \
        external     "External data source"
end

# ── Terraform var files ────────────────────────────────────────────────────────
function __tf_var_files
    find . -maxdepth 1 -name "*.tfvars" -o -name "*.tfvars.json" 2>/dev/null | sed 's|^\./||' | \
        while read -l f
            printf "%s\tVariable file\n" "$f"
        end
    test -d environments; and find environments -maxdepth 2 -name "terraform.tfvars" -o -name "*.tfvars" 2>/dev/null
    test -d vars; and find vars -maxdepth 1 -name "*.tfvars" 2>/dev/null
end

# ── State files ────────────────────────────────────────────────────────────────
function __tf_state_files
    find . -maxdepth 1 -name "*.tfstate" -o -name "*.tfstate.backup" 2>/dev/null | sed 's|^\./||'
    test -d .terraform; and find .terraform -maxdepth 1 -name "*.tfstate" 2>/dev/null
end

# ── Backend types ─────────────────────────────────────────────────────────────
function __tf_backends
    printf '%s\t%s\n' \
        local       "Local filesystem (default)" \
        s3          "Amazon S3 + DynamoDB lock" \
        azurerm     "Azure Blob Storage" \
        gcs         "Google Cloud Storage" \
        consul      "HashiCorp Consul" \
        remote      "Terraform Cloud / Enterprise" \
        http        "HTTP REST backend" \
        kubernetes  "Kubernetes secret" \
        pg          "PostgreSQL" \
        cos         "Tencent COS" \
        oss         "Alibaba OSS" \
        swift       "OpenStack Swift"
end

# ── Plan files ────────────────────────────────────────────────────────────────
function __tf_plan_files
    find . -maxdepth 1 -name "*.tfplan" -o -name "*.plan" -o -name "plan.out" -o -name "*.binary" 2>/dev/null | sed 's|^\./||'
    test -d plans; and find plans -maxdepth 1 -name "*.tfplan" 2>/dev/null
end

# ── Resource types from providers ─────────────────────────────────────────────
function __tf_resource_types
    find . -maxdepth 1 -name "*.tf" -type f 2>/dev/null | xargs grep -h 'resource "' 2>/dev/null | \
        sed 's/resource "\([^"]*\)".*/\1/' | \
        sort -u | \
        while read -l r
            printf "%s\tResource type\n" "$r"
        end
end

# ── Data source types ─────────────────────────────────────────────────────────
function __tf_data_sources
    find . -maxdepth 1 -name "*.tf" -type f 2>/dev/null | xargs grep -h 'data "' 2>/dev/null | \
        sed 's/data "\([^"]*\)".*/\1/' | \
        sort -u | \
        while read -l d
            printf "%s\tData source\n" "$d"
        end
end

# ── Module names ───────────────────────────────────────────────────────────────
function __tf_modules
    find . -maxdepth 1 -name "*.tf" -type f 2>/dev/null | xargs grep -h 'module "' 2>/dev/null | \
        sed 's/module "\([^"]*\)".*/\1/' | \
        sort -u | \
        while read -l m
            printf "module.%s\tModule\n" "$m"
        end
end

# ── Lock ID ───────────────────────────────────────────────────────────────────
function __tf_lock_id
    if test -f .terraform/terraform.tfstate
        python3 -c '
import json
try:
    with open(".terraform/terraform.tfstate") as f:
        data = json.load(f)
    print(data.get("serial", ""))
except:
    pass
' 2>/dev/null
    end
end

# ── Parallelism values ────────────────────────────────────────────────────────
function __tf_parallelism
    printf '%s\t%s\n' \
        10   "Default (10 concurrent ops)" \
        1    "Sequential (debug)" \
        5    "Conservative" \
        20   "Aggressive" \
        50   "Maximum"
end

# ── Log levels ────────────────────────────────────────────────────────────────
function __tf_log_levels
    printf '%s\t%s\n' \
        TRACE   "Most verbose — all internal calls" \
        DEBUG   "Debug messages" \
        INFO    "Informational messages" \
        WARN    "Warnings only" \
        ERROR   "Errors only" \
        JSON    "JSON structured logging (TRACE level)"
end

# ── Refresh modes ─────────────────────────────────────────────────────────────
function __tf_refresh_modes
    printf '%s\t%s\n' \
        "true"  "Refresh state before plan/apply (default)" \
        "false" "Don't refresh — use cached state" \
        "only"  "Only refresh, don't plan"
end

# ══════════════════════════════════════════════════════════════════════════════
#  TOP-LEVEL SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l tf_commands \
    "init\t🚀 Initialize working directory" \
    "validate\t✔️  Validate configuration files" \
    "plan\t📋 Generate execution plan" \
    "apply\t✅ Apply the execution plan" \
    "destroy\t💣 Destroy managed infrastructure" \
    "fmt\t🎨 Format configuration files" \
    "show\t👁️  Show state or plan" \
    "output\t📤 Show output values" \
    "refresh\t🔄 Update state from real resources" \
    "state\t🗄️  State management" \
    "workspace\t🏢 Workspace management" \
    "import\t⬇️  Import existing resource into state" \
    "taint\t🏷️  Mark resource for recreation" \
    "untaint\t✨ Remove taint from resource" \
    "get\t⬇️  Download modules" \
    "graph\t📊 Generate dependency graph" \
    "providers\t📦 Show providers info" \
    "console\t🖥️  Interactive console" \
    "force-unlock\t🔓 Release stuck state lock" \
    "login\t🔑 Login to Terraform Cloud" \
    "logout\t🚪 Logout from Terraform Cloud" \
    "metadata\t📖 Metadata commands" \
    "test\t🧪 Execute module tests" \
    "version\t📌 Show Terraform version" \
    "-help\t❓ Show help" \
    "-version\t📌 Show version"

complete -c terraform -f -n __tf_no_subcommand -a "$tf_commands"

# ── Global flags ───────────────────────────────────────────────────────────────
complete -c terraform -l help    -s h -d "Show help for any command"          -f
complete -c terraform -l version -s v -d "Show Terraform version"             -f
complete -c terraform -o chdir        -d "Switch to directory before command" -F

# ══════════════════════════════════════════════════════════════════════════════
#  INIT
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is init" \
    -o backend               -d "Configure backend" -f \
    -a "true\tEnable backend false\tDisable backend"
complete -c terraform -n "__tf_sub_is init" \
    -o backend-config        -d "Backend config override" -f
complete -c terraform -n "__tf_sub_is init" \
    -o force-copy            -d "No prompts when copying state"             -f
complete -c terraform -n "__tf_sub_is init" \
    -o from-module           -d "Copy from module source"                   -f
complete -c terraform -n "__tf_sub_is init" \
    -o get                   -d "Download modules" -f \
    -a "true false"
complete -c terraform -n "__tf_sub_is init" \
    -o get-plugins           -d "Download plugins" -f \
    -a "true false"
complete -c terraform -n "__tf_sub_is init" \
    -o input                 -d "Ask for input" -f \
    -a "true\tPrompt for input false\tNo prompts"
complete -c terraform -n "__tf_sub_is init" \
    -o lock                  -d "Lock provider versions" -f \
    -a "true false"
complete -c terraform -n "__tf_sub_is init" \
    -o lock-timeout          -d "Duration to retry lock"                    -f \
    -a "0s 30s 1m 5m"
complete -c terraform -n "__tf_sub_is init" \
    -o no-color              -d "Disable color output"                      -f
complete -c terraform -n "__tf_sub_is init" \
    -o plugin-dir            -d "Plugin directory path"                     -F
complete -c terraform -n "__tf_sub_is init" \
    -o reconfigure           -d "Reconfigure backend (ignore existing)"     -f
complete -c terraform -n "__tf_sub_is init" \
    -o migrate-state         -d "Migrate state to new backend"              -f
complete -c terraform -n "__tf_sub_is init" \
    -o upgrade               -d "Upgrade modules and plugins"               -f
complete -c terraform -n "__tf_sub_is init" \
    -o lockfile              -d "Lockfile mode" -f \
    -a "readonly\tReadonly (don't modify) update\tUpdate lockfile"
complete -c terraform -n "__tf_sub_is init" \
    -o json                  -d "JSON output format"                        -f
complete -c terraform -n "__tf_sub_is init" \
    -o test-directory        -d "Directory with tests"                      -F

# ══════════════════════════════════════════════════════════════════════════════
#  VALIDATE
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is validate" \
    -o json                  -d "Output as JSON"                            -f
complete -c terraform -n "__tf_sub_is validate" \
    -o no-color              -d "Disable color output"                      -f
complete -c terraform -n "__tf_sub_is validate" \
    -o test-directory        -d "Directory containing test files"           -F

# ══════════════════════════════════════════════════════════════════════════════
#  PLAN
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is plan" \
    -o compact-warnings      -d "Compact warning messages"                  -f
complete -c terraform -n "__tf_sub_is plan" \
    -o destroy               -d "Plan destroy (opposite of apply)"          -f
complete -c terraform -n "__tf_sub_is plan" \
    -o detailed-exitcode     -d "Exit 2 if plan has changes"               -f
complete -c terraform -n "__tf_sub_is plan" \
    -o generate-config-out   -d "Write generated config to file"           -F
complete -c terraform -n "__tf_sub_is plan" \
    -o input                 -d "Ask for input" -f -a "true false"
complete -c terraform -n "__tf_sub_is plan" \
    -o json                  -d "JSON streaming output"                     -f
complete -c terraform -n "__tf_sub_is plan" \
    -o lock                  -d "Lock state file" -f -a "true false"
complete -c terraform -n "__tf_sub_is plan" \
    -o lock-timeout          -d "Duration to retry lock"                    -f \
    -a "0s 30s 1m 5m 10m"
complete -c terraform -n "__tf_sub_is plan" \
    -o no-color              -d "Disable color output"                      -f
complete -c terraform -n "__tf_sub_is plan" \
    -o out                   -d "Save plan to file"                         -F
complete -c terraform -n "__tf_sub_is plan" \
    -o parallelism           -d "Limit concurrent operations"               -f \
    -a "(__tf_parallelism)"
complete -c terraform -n "__tf_sub_is plan" \
    -o refresh               -d "Refresh state before plan" -f \
    -a "(__tf_refresh_modes)"
complete -c terraform -n "__tf_sub_is plan" \
    -o refresh-only          -d "Only refresh — don't plan changes"        -f
complete -c terraform -n "__tf_sub_is plan" \
    -o replace               -d "Force replacement of resource" -f \
    -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is plan" \
    -o state                 -d "Path to state file"                        -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is plan" \
    -o target                -d "Target specific resource(s)"               -f \
    -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is plan" \
    -o var                   -d "Set variable value (key=value)"            -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is plan" \
    -o var-file              -d "Variable file path"                        -F \
    -a "(__tf_var_files)"
complete -c terraform -n "__tf_sub_is plan" \
    -o module-depth          -d "Depth of modules to expand in output"      -f \
    -a "0 1 2 -1"

# ══════════════════════════════════════════════════════════════════════════════
#  APPLY
# ══════════════════════════════════════════════════════════════════════════════

# apply can take a plan file as argument
complete -c terraform -n "__tf_sub_is apply; and test (count (commandline -poc)) -le 2" \
    -f -a "(__tf_plan_files)" -d "Saved plan file"

complete -c terraform -n "__tf_sub_is apply" \
    -o auto-approve          -d "Skip interactive approval"                 -f
complete -c terraform -n "__tf_sub_is apply" \
    -o backup                -d "Backup state file path"                    -F
complete -c terraform -n "__tf_sub_is apply" \
    -o compact-warnings      -d "Compact warning messages"                  -f
complete -c terraform -n "__tf_sub_is apply" \
    -o destroy               -d "Destroy (inverse apply)"                   -f
complete -c terraform -n "__tf_sub_is apply" \
    -o input                 -d "Ask for input" -f -a "true false"
complete -c terraform -n "__tf_sub_is apply" \
    -o json                  -d "JSON streaming output"                     -f
complete -c terraform -n "__tf_sub_is apply" \
    -o lock                  -d "Lock state file" -f -a "true false"
complete -c terraform -n "__tf_sub_is apply" \
    -o lock-timeout          -d "Duration to retry lock"                    -f \
    -a "0s 30s 1m 5m 10m"
complete -c terraform -n "__tf_sub_is apply" \
    -o no-color              -d "Disable color output"                      -f
complete -c terraform -n "__tf_sub_is apply" \
    -o parallelism           -d "Limit concurrent ops"                      -f \
    -a "(__tf_parallelism)"
complete -c terraform -n "__tf_sub_is apply" \
    -o refresh               -d "Refresh state" -f \
    -a "(__tf_refresh_modes)"
complete -c terraform -n "__tf_sub_is apply" \
    -o refresh-only          -d "Only refresh — apply no changes"           -f
complete -c terraform -n "__tf_sub_is apply" \
    -o replace               -d "Force replace resource"                    -f \
    -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is apply" \
    -o state                 -d "Path to state file"                        -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is apply" \
    -o state-out             -d "Write state to alternate path"             -F
complete -c terraform -n "__tf_sub_is apply" \
    -o target                -d "Target specific resource(s)"               -f \
    -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is apply" \
    -o var                   -d "Set variable (key=value)"                  -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is apply" \
    -o var-file              -d "Variable file"                             -F \
    -a "(__tf_var_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  DESTROY
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is destroy" \
    -o auto-approve          -d "Skip interactive approval"                 -f
complete -c terraform -n "__tf_sub_is destroy" \
    -o backup                -d "Backup state file path"                    -F
complete -c terraform -n "__tf_sub_is destroy" \
    -o compact-warnings      -d "Compact warnings"                          -f
complete -c terraform -n "__tf_sub_is destroy" \
    -o input                 -d "Ask for input" -f -a "true false"
complete -c terraform -n "__tf_sub_is destroy" \
    -o json                  -d "JSON output"                               -f
complete -c terraform -n "__tf_sub_is destroy" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is destroy" \
    -o lock-timeout          -d "Lock retry duration"                       -f \
    -a "0s 30s 1m 5m"
complete -c terraform -n "__tf_sub_is destroy" \
    -o no-color              -d "Disable color"                             -f
complete -c terraform -n "__tf_sub_is destroy" \
    -o parallelism           -d "Concurrent ops limit"                      -f \
    -a "(__tf_parallelism)"
complete -c terraform -n "__tf_sub_is destroy" \
    -o refresh               -d "Refresh state" -f -a "true false"
complete -c terraform -n "__tf_sub_is destroy" \
    -o state                 -d "State file path"                           -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is destroy" \
    -o state-out             -d "Output state file"                         -F
complete -c terraform -n "__tf_sub_is destroy" \
    -o target                -d "Destroy specific resource"                 -f \
    -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is destroy" \
    -o var                   -d "Variable value"                            -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is destroy" \
    -o var-file              -d "Variable file"                             -F \
    -a "(__tf_var_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  FMT
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is fmt" \
    -f -a "(__tf_in_dir; and find . -name '*.tf' -type f 2>/dev/null | sed 's|^\./||')" -d "HCL file"

complete -c terraform -n "__tf_sub_is fmt" \
    -o check                 -d "Check formatting (exit 1 if wrong)"        -f
complete -c terraform -n "__tf_sub_is fmt" \
    -o diff                  -d "Show diff of formatting changes"           -f
complete -c terraform -n "__tf_sub_is fmt" \
    -o list                  -d "List files with formatting problems" -f \
    -a "true false"
complete -c terraform -n "__tf_sub_is fmt" \
    -o no-color              -d "Disable color"                             -f
complete -c terraform -n "__tf_sub_is fmt" \
    -o recursive             -d "Format files in subdirectories"            -f
complete -c terraform -n "__tf_sub_is fmt" \
    -o write                 -d "Write formatted output to source" -f \
    -a "true\tWrite changes false\tDon't write (dry run)"

# ══════════════════════════════════════════════════════════════════════════════
#  SHOW
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is show" \
    -f -a "(__tf_plan_files)" -d "Plan file"
complete -c terraform -n "__tf_sub_is show" \
    -f -a "(__tf_state_files)" -d "State file"

complete -c terraform -n "__tf_sub_is show" \
    -o json                  -d "Output as JSON"                            -f
complete -c terraform -n "__tf_sub_is show" \
    -o no-color              -d "Disable color"                             -f

# ══════════════════════════════════════════════════════════════════════════════
#  OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is output" \
    -f -a "(__tf_outputs)" -d "Output name"

complete -c terraform -n "__tf_sub_is output" \
    -o json                  -d "Output as JSON"                            -f
complete -c terraform -n "__tf_sub_is output" \
    -o no-color              -d "Disable color"                             -f
complete -c terraform -n "__tf_sub_is output" \
    -o raw                   -d "Print raw string (no quotes)"              -f
complete -c terraform -n "__tf_sub_is output" \
    -o state                 -d "Path to state file"                        -F \
    -a "(__tf_state_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  REFRESH
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is refresh" \
    -o backup                -d "Backup state file"                         -F
complete -c terraform -n "__tf_sub_is refresh" \
    -o compact-warnings      -d "Compact warnings"                          -f
complete -c terraform -n "__tf_sub_is refresh" \
    -o input                 -d "Ask for input" -f -a "true false"
complete -c terraform -n "__tf_sub_is refresh" \
    -o json                  -d "JSON output"                               -f
complete -c terraform -n "__tf_sub_is refresh" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is refresh" \
    -o lock-timeout          -d "Lock retry"                                -f \
    -a "0s 30s 1m"
complete -c terraform -n "__tf_sub_is refresh" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is refresh" \
    -o parallelism           -d "Concurrent ops"                            -f \
    -a "(__tf_parallelism)"
complete -c terraform -n "__tf_sub_is refresh" \
    -o state                 -d "State file"                                -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is refresh" \
    -o state-out             -d "Output state"                              -F
complete -c terraform -n "__tf_sub_is refresh" \
    -o target                -d "Target resource"                           -f \
    -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is refresh" \
    -o var                   -d "Variable value"                            -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is refresh" \
    -o var-file              -d "Variable file"                             -F \
    -a "(__tf_var_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  IMPORT
# ══════════════════════════════════════════════════════════════════════════════

# import <resource_address> <id>
complete -c terraform -n "__tf_sub_is import; and test (count (commandline -poc)) -le 2" \
    -f -a "(__tf_state_resources)" -d "Resource address"

complete -c terraform -n "__tf_sub_is import" \
    -o allow-missing-config  -d "Allow import with no config"               -f
complete -c terraform -n "__tf_sub_is import" \
    -o backup                -d "Backup state file"                         -F
complete -c terraform -n "__tf_sub_is import" \
    -o config                -d "Config directory path"                     -F
complete -c terraform -n "__tf_sub_is import" \
    -o generate-config-out   -d "Write generated HCL to file"               -F
complete -c terraform -n "__tf_sub_is import" \
    -o input                 -d "Ask for input" -f -a "true false"
complete -c terraform -n "__tf_sub_is import" \
    -o json                  -d "JSON output"                               -f
complete -c terraform -n "__tf_sub_is import" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is import" \
    -o lock-timeout          -d "Lock retry"                                -f \
    -a "0s 30s 1m"
complete -c terraform -n "__tf_sub_is import" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is import" \
    -o parallelism           -d "Concurrent ops"                            -f \
    -a "(__tf_parallelism)"
complete -c terraform -n "__tf_sub_is import" \
    -o state                 -d "State file"                                -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is import" \
    -o state-out             -d "Output state"                              -F
complete -c terraform -n "__tf_sub_is import" \
    -o var                   -d "Variable value"                            -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is import" \
    -o var-file              -d "Variable file"                             -F \
    -a "(__tf_var_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  TAINT / UNTAINT
# ══════════════════════════════════════════════════════════════════════════════

for taint_cmd in taint untaint
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -f -a "(__tf_state_resources)" -d "Resource address"

    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o allow-missing         -d "No error if not found"                 -f
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o backup                -d "Backup state file"                     -F
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o json                  -d "JSON output"                           -f
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o lock                  -d "Lock state" -f -a "true false"
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o lock-timeout          -d "Lock retry"                            -f
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o no-color              -d "No color"                              -f
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o state                 -d "State file"                            -F \
        -a "(__tf_state_files)"
    complete -c terraform -n "__tf_sub_is $taint_cmd" \
        -o state-out             -d "Output state"                          -F
end

# ══════════════════════════════════════════════════════════════════════════════
#  STATE
# ══════════════════════════════════════════════════════════════════════════════

set -l state_sub \
    "list\t📋 List resources in state" \
    "show\t👁️  Show resource in state" \
    "mv\t➡️  Move resource in state" \
    "rm\t🗑️  Remove resource from state" \
    "pull\t⬇️  Pull state from remote" \
    "push\t⬆️  Push state to remote" \
    "replace-provider\t🔄 Replace provider in state"

complete -c terraform -n "__tf_sub_is state; and not __tf_seen_flag \
    list show mv rm pull push replace-provider" \
    -f -a "$state_sub"

# state list
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag list" \
    -o id                    -d "Filter by ID attribute"                    -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag list" \
    -o state                 -d "State file path"                           -F \
    -a "(__tf_state_files)"

# state show
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag show" \
    -f -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag show" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag show" \
    -o state                 -d "State file"                                -F \
    -a "(__tf_state_files)"

# state mv
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -f -a "(__tf_state_resources)" -d "Source resource"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o backup                -d "Backup state file"                         -F
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o backup-out            -d "Backup output state"                       -F
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o dry-run               -d "Preview without changes"                   -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o ignore-remote-version -d "Ignore remote state version"               -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o lock-timeout          -d "Lock retry"                                -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o state                 -d "Source state file"                         -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag mv" \
    -o state-out             -d "Destination state file"                    -F

# state rm
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -f -a "(__tf_state_resources)"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o backup                -d "Backup state file"                         -F
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o dry-run               -d "Preview removals"                          -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o ignore-remote-version -d "Ignore remote version"                     -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o lock-timeout          -d "Lock retry"                                -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag rm" \
    -o state                 -d "State file"                                -F \
    -a "(__tf_state_files)"

# state push flags
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag push" \
    -f -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag push" \
    -o force                 -d "Force push even if lineages differ"        -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag push" \
    -o ignore-remote-version -d "Ignore remote version"                     -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag push" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag push" \
    -o lock-timeout          -d "Lock retry"                                -f

# state pull flags
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag pull" \
    -o ignore-remote-version -d "Ignore remote version"                     -f

# state replace-provider
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o auto-approve          -d "Skip approval"                             -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o backup                -d "Backup state"                              -F
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o ignore-remote-version -d "Ignore remote version"                     -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o lock-timeout          -d "Lock retry"                                -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is state; and __tf_seen_flag replace-provider" \
    -o state                 -d "State file"                                -F \
    -a "(__tf_state_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  WORKSPACE
# ══════════════════════════════════════════════════════════════════════════════

set -l ws_sub \
    "list\t📋 List workspaces" \
    "show\t👁️  Show current workspace" \
    "new\t✨ Create new workspace" \
    "select\t🔄 Switch workspace" \
    "delete\t🗑️  Delete workspace"

complete -c terraform -n "__tf_sub_is workspace; and not __tf_seen_flag \
    list show new select delete" \
    -f -a "$ws_sub"

# workspace select / delete: complete workspace names
for ws_cmd in select delete
    complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag $ws_cmd" \
        -f -a "(__tf_workspaces)"
end

# workspace new
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag new" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag new" \
    -o lock-timeout          -d "Lock retry"                                -f
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag new" \
    -o state                 -d "Copy from state file"                      -F \
    -a "(__tf_state_files)"

# workspace select
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag select" \
    -o or-create             -d "Create if it doesn't exist"                -f
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag select" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag select" \
    -o lock-timeout          -d "Lock retry"                                -f

# workspace delete
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag delete" \
    -o force                 -d "Delete even with resources"                -f
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag delete" \
    -o lock                  -d "Lock state" -f -a "true false"
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag delete" \
    -o lock-timeout          -d "Lock retry"                                -f

# workspace list
complete -c terraform -n "__tf_sub_is workspace; and __tf_seen_flag list" \
    -o no-color              -d "No color"                                  -f

# ══════════════════════════════════════════════════════════════════════════════
#  GRAPH
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is graph" \
    -o plan                  -d "Plan file to create graph from"            -F \
    -a "(__tf_plan_files)"
complete -c terraform -n "__tf_sub_is graph" \
    -o draw-cycles           -d "Highlight cycles in graph"                 -f
complete -c terraform -n "__tf_sub_is graph" \
    -o module-depth          -d "Module expansion depth"                    -f \
    -a "0 1 2 -1"
complete -c terraform -n "__tf_sub_is graph" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is graph" \
    -o type                  -d "Graph type" -f \
    -a "plan\tPlan graph plan-destroy\tDestroy plan apply\tApply validate\tValidate"

# ══════════════════════════════════════════════════════════════════════════════
#  PROVIDERS
# ══════════════════════════════════════════════════════════════════════════════

set -l providers_sub \
    "lock\t🔒 Lock provider versions" \
    "mirror\t🪞 Mirror providers locally" \
    "schema\t📖 Print provider schema"

complete -c terraform -n "__tf_sub_is providers; and not __tf_seen_flag lock mirror schema" \
    -f -a "$providers_sub"

# providers lock
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag lock" \
    -f -a "(__tf_providers)"
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag lock" \
    -o fs-mirror             -d "Local mirror directory"                    -F
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag lock" \
    -o net-mirror            -d "Network mirror URL"                        -f
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag lock" \
    -o platform              -d "Target platform" -f \
    -a "linux_amd64\tLinux x86_64 linux_arm64\tLinux ARM64 darwin_amd64\tMacOS Intel darwin_arm64\tMacOS Apple Silicon windows_amd64\tWindows x86_64"

# providers mirror
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag mirror" \
    -f -a "(__tf_providers)"
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag mirror" \
    -o platform              -d "Target platform" -f \
    -a "linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64"

# providers schema
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag schema" \
    -o json                  -d "Output as JSON"                            -f
complete -c terraform -n "__tf_sub_is providers; and __tf_seen_flag schema" \
    -o no-color              -d "No color"                                  -f

# ══════════════════════════════════════════════════════════════════════════════
#  GET
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is get" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is get" \
    -o update                -d "Update previously-downloaded modules"      -f
complete -c terraform -n "__tf_sub_is get" \
    -o json                  -d "JSON output"                               -f
complete -c terraform -n "__tf_sub_is get" \
    -o test-directory        -d "Test directory"                            -F

# ══════════════════════════════════════════════════════════════════════════════
#  TEST
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is test" \
    -o cloud-run             -d "Run tests in Terraform Cloud"              -f
complete -c terraform -n "__tf_sub_is test" \
    -o compact-warnings      -d "Compact warnings"                          -f
complete -c terraform -n "__tf_sub_is test" \
    -o filter                -d "Filter test files by name" -f \
    -a "(find . -maxdepth 1 -name '*.tftest.hcl' 2>/dev/null; test -d tests; and find tests -maxdepth 1 -name '*.tftest.hcl' 2>/dev/null)"
complete -c terraform -n "__tf_sub_is test" \
    -o json                  -d "JSON output"                               -f
complete -c terraform -n "__tf_sub_is test" \
    -o no-color              -d "No color"                                  -f
complete -c terraform -n "__tf_sub_is test" \
    -o test-directory        -d "Tests directory"                           -F
complete -c terraform -n "__tf_sub_is test" \
    -o var                   -d "Variable value"                            -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is test" \
    -o var-file              -d "Variable file"                             -F \
    -a "(__tf_var_files)"
complete -c terraform -n "__tf_sub_is test" \
    -o verbose               -d "Verbose output"                            -f

# ══════════════════════════════════════════════════════════════════════════════
#  CONSOLE
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is console" \
    -o plan                  -d "Plan file to load"                         -F \
    -a "(__tf_plan_files)"
complete -c terraform -n "__tf_sub_is console" \
    -o state                 -d "State file"                                -F \
    -a "(__tf_state_files)"
complete -c terraform -n "__tf_sub_is console" \
    -o var                   -d "Variable value"                            -f \
    -a "(__tf_variables)"
complete -c terraform -n "__tf_sub_is console" \
    -o var-file              -d "Variable file"                             -F \
    -a "(__tf_var_files)"

# ══════════════════════════════════════════════════════════════════════════════
#  FORCE-UNLOCK
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is force-unlock" \
    -f -d "Lock ID"
complete -c terraform -n "__tf_sub_is force-unlock" \
    -o force                 -d "Don't prompt for confirmation"             -f

# ══════════════════════════════════════════════════════════════════════════════
#  METADATA
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is metadata; and not __tf_seen_flag functions" \
    -f -a "functions\t📖 List available functions"

complete -c terraform -n "__tf_sub_is metadata; and __tf_seen_flag functions" \
    -o json                  -d "JSON output"                               -f

# ══════════════════════════════════════════════════════════════════════════════
#  LOGIN / LOGOUT
# ══════════════════════════════════════════════════════════════════════════════

complete -c terraform -n "__tf_sub_is login" \
    -f -a "app.terraform.io\tTerraform Cloud" -d "Hostname"
complete -c terraform -n "__tf_sub_is logout" \
    -f -a "app.terraform.io\tTerraform Cloud" -d "Hostname"
