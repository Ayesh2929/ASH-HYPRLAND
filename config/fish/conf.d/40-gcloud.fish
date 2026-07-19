# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Google Cloud CLI Ultra Configuration               ║
# ║  gcloud, gsutil, bq, kubectl GKE, project mgmt & full GCP ecosystem        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_gcloud_loaded && exit 0
set --global _ash_gcloud_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION & SDK ROOT                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_gcloud_find_sdk --description "Locate Google Cloud SDK root"
    # Explicit CLOUDSDK_ROOT_DIR
    if test -n "$CLOUDSDK_ROOT_DIR" && test -f "$CLOUDSDK_ROOT_DIR/bin/gcloud"
        echo $CLOUDSDK_ROOT_DIR; return
    end

    # Common installation locations
    for candidate in \
        "$HOME/.local/share/google-cloud-sdk" \
        "$HOME/google-cloud-sdk" \
        "/usr/lib/google-cloud-sdk" \
        "/opt/google-cloud-sdk" \
        "/snap/google-cloud-sdk/current" \
        (command -v gcloud 2>/dev/null | xargs -r dirname | xargs -r dirname 2>/dev/null)
        if test -f "$candidate/bin/gcloud"
            echo $candidate; return
        end
    end

    echo ""
end

set --global _ash_gcloud_sdk (__ash_gcloud_find_sdk)

# Exit if gcloud not available
if test -z "$_ash_gcloud_sdk" && not command -q gcloud
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_gcloud_log      "$HOME/.local/share/ash/logs/gcloud.log"
set --global _ash_gcloud_cache    "$HOME/.local/share/ash/cache/gcloud"
set --global _ash_gcloud_cache_ttl 300

mkdir -p (dirname $_ash_gcloud_log) 2>/dev/null
mkdir -p $_ash_gcloud_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _gc_reset   (set_color normal)
set -g _gc_bold    (set_color --bold)
set -g _gc_cyan    (set_color cyan)
set -g _gc_green   (set_color green)
set -g _gc_yellow  (set_color yellow)
set -g _gc_red     (set_color red)
set -g _gc_blue    (set_color 4285F4)   # Google blue
set -g _gc_gred    (set_color EA4335)   # Google red
set -g _gc_gyel    (set_color FBBC05)   # Google yellow
set -g _gc_ggrn    (set_color 34A853)   # Google green
set -g _gc_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── SDK paths ─────────────────────────────────────────────────────────────────
if test -n "$_ash_gcloud_sdk"
    set --export CLOUDSDK_ROOT_DIR $_ash_gcloud_sdk
    fish_add_path --append --global "$_ash_gcloud_sdk/bin"
end

# ── Config directory (XDG-aware) ──────────────────────────────────────────────
set --export CLOUDSDK_CONFIG         "$HOME/.config/gcloud"
set --export CLOUDSDK_CORE_PASS_CREDENTIALS_TO_GSUTIL true

# ── Performance settings ──────────────────────────────────────────────────────
set --export CLOUDSDK_METRICS_ENABLED false    # Disable usage metrics
set --export CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK false
set --export GOOGLE_CLOUD_CLI_DISABLE_RPCS true

# ── Python for gcloud ─────────────────────────────────────────────────────────
set --export CLOUDSDK_PYTHON python3
set --export CLOUDSDK_PYTHON_ARGS "-S"

# ── Application Default Credentials ───────────────────────────────────────────
if test -f "$HOME/.config/gcloud/application_default_credentials.json"
    set --export GOOGLE_APPLICATION_CREDENTIALS \
        "$HOME/.config/gcloud/application_default_credentials.json"
end

# ── Disable update prompts (use gcloud components update manually) ─────────────
set --export CLOUDSDK_CORE_DISABLE_PROMPTS false

# ── Shell completions ──────────────────────────────────────────────────────────
if test -f "$_ash_gcloud_sdk/completion.fish.inc"
    source "$_ash_gcloud_sdk/completion.fish.inc"
else if test -f "$HOME/.config/fish/completions/gcloud.fish"
    # Already installed
    true
else
    # Generate on first run
    gcloud completion fish 2>/dev/null | source
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 CACHING HELPERS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __gc_cached --description "Return cached result or compute and cache"
    set -l key   $argv[1]
    set -l cmd   $argv[2..-1]
    set -l cache "$_ash_gcloud_cache/$key"

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        test $age -lt $_ash_gcloud_cache_ttl && cat $cache && return
    end

    set -l result (eval $cmd 2>/dev/null)
    echo $result > $cache 2>/dev/null
    echo $result
end

function __gc_invalidate --description "Invalidate gcloud cache"
    rm -f "$_ash_gcloud_cache/$argv[1]" 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DYNAMIC COMPLETION SOURCES                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __gc_projects --description "List GCP projects"
    __gc_cached projects \
        "gcloud projects list --format='value(projectId)' 2>/dev/null"
end

function __gc_configs --description "List gcloud configurations"
    gcloud config configurations list --format='value(name)' 2>/dev/null
end

function __gc_regions --description "List GCP compute regions"
    __gc_cached regions \
        "gcloud compute regions list --format='value(name)' 2>/dev/null"
end

function __gc_zones --description "List GCP compute zones"
    __gc_cached zones \
        "gcloud compute zones list --format='value(name)' 2>/dev/null"
end

function __gc_instances --description "List GCP compute instances"
    gcloud compute instances list \
        --format='value(name,zone.basename(),status)' 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, $2, $3}'
end

function __gc_gke_clusters --description "List GKE clusters"
    gcloud container clusters list \
        --format='value(name,location,status)' 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, $2, $3}'
end

function __gc_buckets --description "List GCS buckets"
    __gc_cached buckets--(gcloud config get project 2>/dev/null) \
        "gsutil ls 2>/dev/null | string replace 'gs://' '' | string replace '/' ''"
end

function __gc_cloud_run_services --description "List Cloud Run services"
    gcloud run services list \
        --format='value(metadata.name,status.address.url)' 2>/dev/null | \
        awk '{printf "%s\t%s\n", $1, $2}'
end

function __gc_functions --description "List Cloud Functions"
    gcloud functions list \
        --format='value(name,status)' 2>/dev/null | \
        awk '{printf "%s\t%s\n", $1, $2}'
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 PROJECT & CONFIG MANAGEMENT                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-project: Switch active GCP project ───────────────────────────────────
function gcp-project --description "Switch active GCP project with fuzzy picker"
    set -l project $argv[1]

    if test -z "$project"
        command -q fzf || begin
            gcloud projects list
            return
        end

        set project (
            gcloud projects list \
                --format='table(projectId,name,projectNumber)' 2>/dev/null |
            tail -n +2 |
            fzf --ansi \
                --border-label "  ☁️  Select GCP Project " \
                --border rounded \
                --prompt "  🔵 " \
                --pointer "▶" \
                --preview 'gcloud projects describe {1} 2>/dev/null | bat --language=yaml --style=plain --color=always 2>/dev/null || cat' \
                --preview-window 'right:45%:border-rounded:wrap' \
                --header "  Current: (gcloud config get project 2>/dev/null)  " \
                --header-first \
            | awk '{print $1}'
        )
        test -z "$project" && return 0
    end

    gcloud config set project $project 2>/dev/null
    set --export CLOUDSDK_CORE_PROJECT $project
    set --export GOOGLE_CLOUD_PROJECT   $project
    set --export GCLOUD_PROJECT         $project

    # Invalidate project-scoped caches
    __gc_invalidate "buckets--$project"

    echo ""
    echo $_gc_green"  ✓ GCP Project: $project"$_gc_reset
    echo ""

    # Show project details
    gcloud projects describe $project \
        --format='table(projectId,name,lifecycleState)' 2>/dev/null
    echo ""
end

# ─── gcp-config: Manage gcloud configurations ─────────────────────────────────
function gcp-config --description "Manage gcloud named configurations"
    set -l action $argv[1]
    set -l name   $argv[2]

    switch $action
        case ls list
            set -l reset (set_color normal)
            set -l bold  (set_color --bold)
            set -l cyan  (set_color cyan)
            set -l green (set_color green)
            set -l dim   (set_color brblack)

            echo ""
            echo $bold$_gc_blue"  ☁️  gcloud Configurations"$reset
            echo ""

            gcloud config configurations list \
                --format='table(name,is_active,properties.core.project,properties.core.account,properties.compute.region)' \
                2>/dev/null | \
            while read -l line
                if string match -q 'NAME*' $line
                    echo "  "$bold$_gc_blue$line$reset
                else if string match -q '*True*' $line
                    echo "  "$green$line$reset
                else
                    echo "  "$dim$line$reset
                end
            end
            echo ""

        case switch use activate
            if test -z "$name" && command -q fzf
                set name (
                    __gc_configs |
                    fzf --border-label "  ⚙️  Select Configuration " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                        --preview 'gcloud config configurations describe {} 2>/dev/null | bat --language=yaml --style=plain --color=always 2>/dev/null || cat' \
                        --preview-window 'right:50%:border-rounded'
                )
                test -z "$name" && return 0
            end
            gcloud config configurations activate $name 2>/dev/null
            and echo $_gc_green"  ✓ Configuration: $name"$_gc_reset

        case new create
            test -z "$name" && read -P "  Configuration name: " name
            test -z "$name" && return 1
            gcloud config configurations create $name 2>/dev/null
            and echo $_gc_green"  ✓ Created: $name"$_gc_reset

        case delete rm
            test -z "$name" && begin; echo "  Usage: gcp-config delete <name>"; return 1; end
            read -P "  Delete '$name'? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            gcloud config configurations delete $name 2>/dev/null
            and echo $_gc_yellow"  ✓ Deleted: $name"$_gc_reset

        case describe show
            test -z "$name" && set name (gcloud config configurations list --filter=is_active=true --format='value(name)' 2>/dev/null)
            gcloud config configurations describe $name 2>/dev/null | \
                command -q bat && bat --language=yaml --style=plain --color=always || cat

        case '*'
            echo "  Usage: gcp-config <list|switch|new|delete|describe>"
    end
end

# ─── gcp-login: Authentication management ─────────────────────────────────────
function gcp-login --description "Login to Google Cloud"
    set -l type $argv[1]
    test -z "$type" && set type user

    switch $type
        case user
            echo $_gc_cyan"  🔐 Logging in (user)..."$_gc_reset
            gcloud auth login --update-adc

        case service-account sa
            set -l key_file $argv[2]
            if test -z "$key_file"
                read -P "  Service account key file: " key_file
            end
            test -f "$key_file" || begin; echo $_gc_red"  ✗ Key file not found: $key_file"$_gc_reset; return 1; end
            gcloud auth activate-service-account --key-file=$key_file
            and echo $_gc_green"  ✓ Service account activated"$_gc_reset

        case adc application-default
            echo $_gc_cyan"  🔐 Setting application default credentials..."$_gc_reset
            gcloud auth application-default login

        case print token
            gcloud auth print-access-token

        case status
            gcloud auth list 2>/dev/null

        case revoke logout
            gcloud auth revoke --all 2>/dev/null
            and echo $_gc_yellow"  ✓ All credentials revoked"$_gc_reset

        case '*'
            echo "  Usage: gcp-login [user|sa <key>|adc|print|status|revoke]"
    end
end

# ─── gcp-whoami: Show current GCP identity ────────────────────────────────────
function gcp-whoami --description "Show current GCP identity and configuration"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l blue   (set_color 4285F4)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$blue"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$blue"  ║     ☁️   Google Cloud Identity                        ║"$reset
    echo $bold$blue"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    set -l account (gcloud config get account 2>/dev/null)
    set -l project (gcloud config get project 2>/dev/null)
    set -l region  (gcloud config get compute/region 2>/dev/null)
    set -l zone    (gcloud config get compute/zone 2>/dev/null)
    set -l config  (gcloud config configurations list --filter=is_active=true --format='value(name)' 2>/dev/null)

    echo "  "$bold"Account:       "$reset $cyan$account$reset
    echo "  "$bold"Project:       "$reset $cyan$project$reset
    echo "  "$bold"Region:        "$reset $dim(test -n "$region" && echo $region || echo "not set")$reset
    echo "  "$bold"Zone:          "$reset $dim(test -n "$zone"   && echo $zone   || echo "not set")$reset
    echo "  "$bold"Configuration: "$reset $green$config$reset
    echo ""

    # Billing account
    set -l billing (gcloud billing projects describe $project \
        --format='value(billingAccountName)' 2>/dev/null | \
        string replace 'billingAccounts/' '')
    test -n "$billing" && echo "  "$bold"Billing:       "$reset $dim$billing$reset

    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖥️  COMPUTE ENGINE                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-vm-ls: Rich VM listing ───────────────────────────────────────────────
function gcp-vm-ls --description "List GCP Compute Engine instances"
    set -l zone   $argv[1]
    set -l filter ""
    test -n "$zone" && set filter "--zones=$zone" || set filter "--all"

    echo ""
    echo $_gc_bold$_gc_blue"  🖥️  Compute Engine Instances"$_gc_reset
    echo ""

    gcloud compute instances list $filter \
        --format='table(name,zone.basename(),machineType.basename(),status,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP,networkInterfaces[0].networkIP:label=INTERNAL_IP)' \
        2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_gc_bold$_gc_blue$line$_gc_reset
        else if string match -q '*RUNNING*' $line
            echo "  "$_gc_green$line$_gc_reset
        else if string match -q '*TERMINATED*' $line
            echo "  "$_gc_dim$line$_gc_reset
        else
            echo "  "$_gc_yellow$line$_gc_reset
        end
    end
    echo ""
end

# ─── gcp-vm-ssh: SSH into a GCP VM ────────────────────────────────────────────
function gcp-vm-ssh --description "SSH into GCP Compute Engine instance"
    set -l instance $argv[1]
    set -l zone     $argv[2]

    if test -z "$instance" && command -q fzf
        set -l selection (
            __gc_instances |
            fzf --ansi \
                --border-label "  🖥️  Select Instance " \
                --border rounded \
                --prompt "  🔌 " \
                --pointer "▶" \
                --preview 'echo {1} {2}' \
                --preview-window 'down:2:border-rounded' \
                --header '  Enter:SSH  Ctrl-S:SSM (IAP)  '
        )
        set instance (echo $selection | awk '{print $1}')
        set zone     (echo $selection | awk '{print $2}' | string replace '(' '' | string replace ')' '')
        test -z "$instance" && return 0
    end

    set -l ssh_cmd gcloud compute ssh $instance $argv[3..-1]
    test -n "$zone" && set ssh_cmd $ssh_cmd --zone $zone

    echo $_gc_cyan"  🔌 SSH: $instance"(test -n "$zone" && echo " ($zone)")$_gc_reset
    eval $ssh_cmd
end

# ─── gcp-vm-start/stop ────────────────────────────────────────────────────────
function gcp-vm-start --description "Start GCP Compute Engine instance"
    set -l instance $argv[1]
    set -l zone     $argv[2]

    test -z "$instance" && begin; echo "  Usage: gcp-vm-start <name> [zone]"; return 1; end

    set -l cmd "gcloud compute instances start $instance"
    test -n "$zone" && set cmd "$cmd --zone $zone"

    eval $cmd
    and echo $_gc_green"  ✓ Starting: $instance"$_gc_reset
end

function gcp-vm-stop --description "Stop GCP Compute Engine instance"
    set -l instance $argv[1]
    set -l zone     $argv[2]

    test -z "$instance" && begin; echo "  Usage: gcp-vm-stop <name> [zone]"; return 1; end

    echo $_gc_yellow"  ⏹  Stopping: $instance"$_gc_reset
    read -P "  Confirm? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    set -l cmd "gcloud compute instances stop $instance"
    test -n "$zone" && set cmd "$cmd --zone $zone"
    eval $cmd
    and echo $_gc_green"  ✓ Stopped"$_gc_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ☸️  GKE — KUBERNETES ENGINE                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-gke-auth: Authenticate kubectl for GKE cluster ───────────────────────
function gcp-gke-auth --description "Authenticate kubectl for a GKE cluster"
    set -l cluster  $argv[1]
    set -l location $argv[2]

    if test -z "$cluster" && command -q fzf
        set -l selection (
            __gc_gke_clusters |
            fzf --ansi \
                --border-label "  ☸️  Select GKE Cluster " \
                --border rounded \
                --prompt "  ☸  " \
                --pointer "▶" \
                --preview 'echo "Cluster: {1}\nLocation: {2}"' \
                --preview-window 'down:3:border-rounded' \
                --header '  Enter:auth kubectl  '
        )
        set cluster  (echo $selection | awk '{print $1}')
        set location (echo $selection | awk '{print $2}' | string replace '(' '' | string replace ')' '')
        test -z "$cluster" && return 0
    end

    set -l auth_cmd "gcloud container clusters get-credentials $cluster"
    test -n "$location" && set auth_cmd "$auth_cmd --region $location"

    echo ""
    echo $_gc_cyan"  ☸️  Authenticating kubectl for: $cluster"$_gc_reset
    eval $auth_cmd
    and echo $_gc_green"  ✓ kubectl configured"$_gc_reset
    echo ""
end

# ─── gcp-gke-ls: List GKE clusters ───────────────────────────────────────────
function gcp-gke-ls --description "List GKE clusters in current project"
    echo ""
    echo $_gc_bold$_gc_blue"  ☸️  GKE Clusters"$_gc_reset
    echo ""

    gcloud container clusters list \
        --format='table(name,location,currentMasterVersion,status,currentNodeCount)' \
        2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_gc_bold$_gc_blue$line$_gc_reset
        else if string match -q '*RUNNING*' $line
            echo "  "$_gc_green$line$_gc_reset
        else
            echo "  "$_gc_yellow$line$_gc_reset
        end
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 CLOUD RUN                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-run-ls: List Cloud Run services ──────────────────────────────────────
function gcp-run-ls --description "List Cloud Run services"
    set -l region $argv[1]
    set -l flag ""
    test -n "$region" && set flag "--region=$region" || set flag "--all-regions"

    echo ""
    echo $_gc_bold$_gc_blue"  🚀 Cloud Run Services"$_gc_reset
    echo ""

    gcloud run services list $flag \
        --format='table(metadata.name,status.address.url,metadata.namespace,status.conditions[0].type)' \
        2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_gc_bold$_gc_blue$line$_gc_reset
        else if string match -q '*Ready*' $line
            echo "  "$_gc_green$line$_gc_reset
        else
            echo "  "$_gc_yellow$line$_gc_reset
        end
    end
    echo ""
end

# ─── gcp-run-deploy: Deploy to Cloud Run ──────────────────────────────────────
function gcp-run-deploy --description "Deploy container to Cloud Run"
    set -l service $argv[1]
    set -l image   $argv[2]
    set -l region  $argv[3]

    test -z "$service" && read -P "  Service name: " service
    test -z "$service" && return 1
    test -z "$image"   && read -P "  Container image: " image
    test -z "$image"   && return 1
    test -z "$region"  && set region (gcloud config get compute/region 2>/dev/null; or echo "us-central1")

    echo ""
    echo $_gc_cyan"  🚀 Deploying: $service → $region"$_gc_reset
    echo ""

    set -l ts (date +%s)
    gcloud run deploy $service \
        --image $image \
        --region $region \
        --platform managed \
        --allow-unauthenticated \
        $argv[4..-1]

    set -l elapsed (math (date +%s) - $ts)
    and echo $_gc_green"  ✓ Deployed ($elapsed"s")"$_gc_reset
end

# ─── gcp-run-logs: Tail Cloud Run service logs ────────────────────────────────
function gcp-run-logs --description "Tail Cloud Run service logs"
    set -l service $argv[1]
    set -l region  $argv[2]

    if test -z "$service" && command -q fzf
        set service (
            __gc_cloud_run_services |
            fzf --border-label "  🚀 Select Cloud Run Service " \
                --border rounded \
                --prompt "  📋 " \
                --pointer "▶" \
            | awk '{print $1}'
        )
        test -z "$service" && return 0
    end

    set -l logs_cmd "gcloud logging read"
    set -l filter   "resource.type=cloud_run_revision AND resource.labels.service_name=$service"
    test -n "$region" && set filter "$filter AND resource.labels.location=$region"

    gcloud logging tail "$filter" \
        --format='value(timestamp,severity,textPayload)' 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🪣 CLOUD STORAGE                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-storage-ls: List GCS buckets/objects ─────────────────────────────────
function gcp-storage-ls --description "List GCS buckets or browse contents"
    set -l target $argv[1]

    if test -z "$target"
        echo ""
        echo $_gc_bold$_gc_blue"  🪣 Cloud Storage Buckets"$_gc_reset
        echo ""
        gsutil ls -L 2>/dev/null | grep -E '^gs:|Location:|Storage class:' | \
        while read -l line
            if string match -q 'gs:*' $line
                echo ""
                echo "  "$_gc_cyan$line$_gc_reset
            else
                echo "    "$_gc_dim$line$_gc_reset
            end
        end
        echo ""
    else
        gsutil ls -la "gs://$target" $argv[2..-1]
    end
end

# ─── gcp-storage-sync: Smart sync to/from GCS ─────────────────────────────────
function gcp-storage-sync --description "Sync files to/from Google Cloud Storage"
    set -l src  $argv[1]
    set -l dest $argv[2]

    if test -z "$src" || test -z "$dest"
        echo "  Usage: gcp-storage-sync <src> <dest>"
        echo "  Examples:"
        echo "    gcp-storage-sync ./dist gs://my-bucket/app"
        echo "    gcp-storage-sync gs://my-bucket/data ./local"
        return 1
    end

    echo ""
    echo $_gc_cyan"  📤 Syncing: $src → $dest"$_gc_reset
    echo ""

    gsutil -m rsync -r $argv[3..-1] $src $dest
    and echo $_gc_green"  ✓ Sync complete"$_gc_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 BIGQUERY                                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-bq: Smart BigQuery wrapper ───────────────────────────────────────────
function gcp-bq --description "BigQuery query with smart formatting"
    set -l query $argv[1]
    set -l format $argv[2]
    test -z "$format" && set format pretty

    if test -z "$query"
        read -P "  SQL query: " query
    end
    test -z "$query" && return 1

    echo ""
    echo $_gc_cyan"  📊 Running BigQuery..."$_gc_reset
    echo ""

    bq query \
        --use_legacy_sql=false \
        --format=$format \
        "$query" $argv[3..-1]
end

# ─── gcp-bq-ls: List BQ datasets ──────────────────────────────────────────────
function gcp-bq-ls --description "List BigQuery datasets and tables"
    set -l dataset $argv[1]

    echo ""
    if test -z "$dataset"
        echo $_gc_bold$_gc_blue"  📊 BigQuery Datasets"$_gc_reset
        echo ""
        bq ls --format=pretty 2>/dev/null
    else
        echo $_gc_bold$_gc_blue"  📊 Tables in: $dataset"$_gc_reset
        echo ""
        bq ls --format=pretty $dataset 2>/dev/null
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔑 IAM & SECURITY                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-iam-ls: List IAM bindings ────────────────────────────────────────────
function gcp-iam-ls --description "List IAM policy for current project"
    set -l project (gcloud config get project 2>/dev/null)

    echo ""
    echo $_gc_bold$_gc_blue"  🔑 IAM Policy: $project"$_gc_reset
    echo ""

    gcloud projects get-iam-policy $project \
        --format='table(bindings.role,bindings.members)' 2>/dev/null | \
    while read -l line
        if string match -q 'ROLE*' $line
            echo "  "$_gc_bold$_gc_blue$line$_gc_reset
        else
            echo "  "$_gc_dim$line$_gc_reset
        end
    end
    echo ""
end

# ─── gcp-sa: Service account management ───────────────────────────────────────
function gcp-sa --description "Service account management"
    set -l action $argv[1]
    set -l name   $argv[2]

    switch $action
        case ls list
            echo ""
            echo $_gc_bold$_gc_blue"  🤖 Service Accounts"$_gc_reset
            echo ""
            gcloud iam service-accounts list \
                --format='table(displayName,email,disabled)' 2>/dev/null | \
            while read -l line
                if string match -q 'DISPLAY*' $line
                    echo "  "$_gc_bold$_gc_blue$line$_gc_reset
                else
                    echo "  "$_gc_dim$line$_gc_reset
                end
            end
            echo ""

        case key create
            test -z "$name" && begin; echo "  Usage: gcp-sa key <sa-email>"; return 1; end
            set -l key_file "$name-key-"(date +%Y%m%d)".json"
            gcloud iam service-accounts keys create $key_file --iam-account $name
            and echo $_gc_green"  ✓ Key created: $key_file"$_gc_reset

        case impersonate
            test -z "$name" && begin; echo "  Usage: gcp-sa impersonate <sa-email>"; return 1; end
            gcloud config set auth/impersonate_service_account $name
            and echo $_gc_yellow"  ⚠ Impersonating: $name"$_gc_reset

        case stop-impersonate
            gcloud config unset auth/impersonate_service_account
            and echo $_gc_green"  ✓ Stopped impersonation"$_gc_reset

        case '*'
            echo "  Usage: gcp-sa <list|key|impersonate|stop-impersonate>"
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📋 LOGGING & MONITORING                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-logs: Stream Cloud Logging ───────────────────────────────────────────
function gcp-logs --description "Stream Google Cloud Logging"
    set -l filter  $argv[1]
    set -l limit   $argv[2]
    test -z "$limit" && set limit 50

    if test -z "$filter"
        # Interactive filter builder
        set -l resource_type (
            printf 'gce_instance\ncloud_run_revision\nk8s_container\ncloud_function\napp_engine\nglobal\n' |
            fzf --border-label "  📋 Resource Type " \
                --border rounded \
                --prompt "  " \
                --no-multi \
                --header '  Enter:select  '
        )
        test -n "$resource_type" && set filter "resource.type=$resource_type"
    end

    echo ""
    echo $_gc_cyan"  📋 Cloud Logging"(test -n "$filter" && echo ": $filter")$_gc_reset
    echo ""

    if test -n "$filter"
        gcloud logging tail "$filter" \
            --format='value(timestamp,severity,resource.type,textPayload)' 2>/dev/null
    else
        gcloud logging read --limit=$limit \
            --format='table(timestamp,severity,resource.type,textPayload)' 2>/dev/null
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  💰 BILLING & COSTS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gcp-costs: Show billing summary ──────────────────────────────────────────
function gcp-costs --description "Show GCP billing information"
    set -l project (gcloud config get project 2>/dev/null)

    echo ""
    echo $_gc_bold$_gc_blue"  💰 GCP Billing: $project"$_gc_reset
    echo ""

    # Billing account
    set -l billing (gcloud billing projects describe $project \
        --format='value(billingEnabled,billingAccountName)' 2>/dev/null)

    if test -n "$billing"
        echo "  "$_gc_dim$billing$_gc_reset
    else
        echo "  "$_gc_yellow"Billing API not enabled or no billing account linked"$_gc_reset
    end
    echo ""
end

# ─── gcp-info: Full GCP environment dashboard ─────────────────────────────────
function gcp-info --description "Show complete GCP environment information"
    set -l reset (set_color normal)
    set -l bold  (set_color --bold)
    set -l blue  (set_color 4285F4)
    set -l cyan  (set_color cyan)
    set -l green (set_color green)
    set -l dim   (set_color brblack)

    echo ""
    echo $bold$blue"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$blue"  ║     ☁️   Google Cloud Dashboard                       ║"$reset
    echo $bold$blue"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"SDK Version:  "$reset $dim(gcloud --version 2>/dev/null | head -1)$reset
    echo "  "$bold"SDK Root:     "$reset $dim$_ash_gcloud_sdk$reset
    echo "  "$bold"Config dir:   "$reset $dim$CLOUDSDK_CONFIG$reset
    echo ""

    gcp-whoami
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Auth & Config
abbr --add gcw     'gcp-whoami'
abbr --add gcp     'gcp-project'
abbr --add gcc     'gcp-config list'
abbr --add gccs    'gcp-config switch'
abbr --add gcl     'gcp-login'
abbr --add gcla    'gcp-login adc'
abbr --add gcls    'gcp-login status'
abbr --add gcinfo  'gcp-info'

# Compute
abbr --add gcvls   'gcp-vm-ls'
abbr --add gcvssh  'gcp-vm-ssh'
abbr --add gcvst   'gcp-vm-start'
abbr --add gcvsp   'gcp-vm-stop'

# GKE
abbr --add gckls   'gcp-gke-ls'
abbr --add gckauth 'gcp-gke-auth'

# Cloud Run
abbr --add gcrls   'gcp-run-ls'
abbr --add gcrdep  'gcp-run-deploy'
abbr --add gcrlogs 'gcp-run-logs'

# Storage
abbr --add gcsls   'gcp-storage-ls'
abbr --add gcssync 'gcp-storage-sync'

# BigQuery
abbr --add gcbq    'gcp-bq'
abbr --add gcbqls  'gcp-bq-ls'

# IAM
abbr --add gciam   'gcp-iam-ls'
abbr --add gcsa    'gcp-sa list'
abbr --add gcsakey 'gcp-sa key'

# Logs
abbr --add gclogs  'gcp-logs'

# Costs
abbr --add gccost  'gcp-costs'

# Direct gcloud
abbr --add gcver   'gcloud --version'
abbr --add gcupd   'gcloud components update'
abbr --add gccomp  'gcloud components install'
abbr --add gcregion 'gcloud config set compute/region'
abbr --add gczone  'gcloud config set compute/zone'