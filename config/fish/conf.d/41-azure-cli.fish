# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Azure CLI Ultra Configuration                      ║
# ║  az CLI with subscription mgmt, resources, AKS, Functions & full ecosystem  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_azure_loaded && exit 0
set --global _ash_azure_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

command -q az || exit 0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_azure_log       "$HOME/.local/share/ash/logs/azure.log"
set --global _ash_azure_cache     "$HOME/.local/share/ash/cache/azure"
set --global _ash_azure_cache_ttl 300

mkdir -p (dirname $_ash_azure_log) 2>/dev/null
mkdir -p $_ash_azure_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _az_reset   (set_color normal)
set -g _az_bold    (set_color --bold)
set -g _az_cyan    (set_color cyan)
set -g _az_green   (set_color green)
set -g _az_yellow  (set_color yellow)
set -g _az_red     (set_color red)
set -g _az_blue    (set_color 0078D4)   # Azure blue
set -g _az_dim     (set_color brblack)
set -g _az_purple  (set_color magenta)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Config ────────────────────────────────────────────────────────────────────
set --export AZURE_CONFIG_DIR     "$HOME/.azure"
set --export AZURE_DEFAULTS_GROUP ""
set --export AZURE_DEFAULTS_LOCATION ""

# ── Output format ─────────────────────────────────────────────────────────────
set --export AZURE_CORE_OUTPUT    json

# Disable survey prompts
set --export AZURE_CORE_SURVEY_MESSAGE false

# Disable CLI telemetry
set --export AZURE_CORE_COLLECT_TELEMETRY false

# ── Shell completions ──────────────────────────────────────────────────────────
# Source az completions for fish
if test -f "$HOME/.azure/az.completion.fish"
    source "$HOME/.azure/az.completion.fish"
else
    # Generate on demand
    az completion --shell fish 2>/dev/null > "$HOME/.azure/az.completion.fish" 2>/dev/null
    test -f "$HOME/.azure/az.completion.fish" && source "$HOME/.azure/az.completion.fish"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 CACHING HELPERS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __az_cached --description "Cached az CLI command output"
    set -l key   $argv[1]
    set -l cmd   $argv[2..-1]
    set -l cache "$_ash_azure_cache/$key"

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        test $age -lt $_ash_azure_cache_ttl && cat $cache && return
    end

    set -l result (eval $cmd 2>/dev/null)
    echo $result > $cache 2>/dev/null
    echo $result
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DYNAMIC COMPLETION SOURCES                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __az_subscriptions --description "List Azure subscriptions"
    __az_cached subscriptions \
        "az account list --query '[].{id:id,name:name}' --output tsv 2>/dev/null"
end

function __az_resource_groups --description "List Azure resource groups"
    __az_cached rgroups \
        "az group list --query '[].name' --output tsv 2>/dev/null"
end

function __az_locations --description "List Azure locations"
    __az_cached locations \
        "az account list-locations --query '[].name' --output tsv 2>/dev/null"
end

function __az_vm_list --description "List Azure VMs"
    az vm list \
        --query '[].{name:name,rg:resourceGroup,status:powerState}' \
        --output tsv 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, $2, $3}'
end

function __az_aks_clusters --description "List AKS clusters"
    az aks list \
        --query '[].{name:name,rg:resourceGroup,status:powerState.code}' \
        --output tsv 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, $2, $3}'
end

function __az_storage_accounts --description "List Azure Storage accounts"
    __az_cached storage \
        "az storage account list --query '[].name' --output tsv 2>/dev/null"
end

function __az_function_apps --description "List Azure Function apps"
    az functionapp list \
        --query '[].{name:name,rg:resourceGroup,state:state}' \
        --output tsv 2>/dev/null | \
        awk '{printf "%s\t%s (%s)\n", $1, $2, $3}'
end

function __az_acr_registries --description "List Azure Container Registries"
    az acr list \
        --query '[].{name:name,rg:resourceGroup}' \
        --output tsv 2>/dev/null | \
        awk '{printf "%s\t%s\n", $1, $2}'
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔐 AUTH & SUBSCRIPTION MANAGEMENT                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── az-login: Smart Azure login ─────────────────────────────────────────────
function az-login --description "Login to Azure CLI"
    set -l type $argv[1]
    test -z "$type" && set type interactive

    switch $type
        case interactive
            echo ""
            echo $_az_cyan"  🔐 Azure interactive login..."$_az_reset
            az login

        case device
            echo ""
            echo $_az_cyan"  🔐 Azure device code login..."$_az_reset
            az login --use-device-code

        case service-principal sp
            set -l tenant   $argv[2]
            set -l client   $argv[3]
            set -l secret   $argv[4]

            if test -z "$tenant" || test -z "$client"
                read -P "  Tenant ID:     " tenant
                read -P "  Client ID:     " client
                read -P "  Client secret: " secret
            end

            az login --service-principal \
                --tenant $tenant \
                --username $client \
                --password $secret
            and echo $_az_green"  ✓ Service principal login"$_az_reset

        case msi managed-identity
            az login --identity
            and echo $_az_green"  ✓ Managed identity login"$_az_reset

        case status
            az account show --output table 2>/dev/null

        case logout
            az logout
            and echo $_az_yellow"  ✓ Logged out"$_az_reset

        case '*'
            echo "  Usage: az-login [interactive|device|sp|msi|status|logout]"
    end
end

# ─── az-sub: Switch Azure subscription ────────────────────────────────────────
function az-sub --description "Switch Azure subscription with fuzzy picker"
    set -l sub $argv[1]

    if test -z "$sub"
        command -q fzf || begin; az account list --output table; return; end

        set sub (
            az account list \
                --query '[].{name:name,id:id,state:state,isDefault:isDefault}' \
                --output tsv 2>/dev/null |
            fzf --ansi \
                --border-label "  🔵 Select Azure Subscription " \
                --border rounded \
                --prompt "  🔵 " \
                --pointer "▶" \
                --preview 'az account show --subscription {2} --output yaml 2>/dev/null | bat --language=yaml --style=plain --color=always 2>/dev/null || cat' \
                --preview-window 'right:45%:border-rounded:wrap' \
                --header "  Current: (az account show --query name -o tsv 2>/dev/null)  " \
                --header-first \
            | awk '{print $2}'
        )
        test -z "$sub" && return 0
    end

    az account set --subscription $sub
    and begin
        set -l name (az account show --query name --output tsv 2>/dev/null)
        echo ""
        echo $_az_green"  ✓ Subscription: $name"$_az_reset
        rm -f "$_ash_azure_cache/rgroups" 2>/dev/null
        echo ""
    end
end

# ─── az-whoami: Show current Azure identity ───────────────────────────────────
function az-whoami --description "Show current Azure identity"
    set -l reset (set_color normal)
    set -l bold  (set_color --bold)
    set -l blue  (set_color 0078D4)
    set -l cyan  (set_color cyan)
    set -l green (set_color green)
    set -l dim   (set_color brblack)

    echo ""
    echo $bold$blue"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$blue"  ║     🔵  Azure Identity                                ║"$reset
    echo $bold$blue"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    set -l account (az account show --output json 2>/dev/null)

    if test -n "$account" && command -q jq
        echo "  "$bold"Account:      "$reset $cyan(echo $account | jq -r '.user.name // "unknown"')$reset
        echo "  "$bold"Subscription: "$reset $cyan(echo $account | jq -r '.name')$reset
        echo "  "$bold"Sub ID:       "$reset $dim(echo $account | jq -r '.id')$reset
        echo "  "$bold"Tenant:       "$reset $dim(echo $account | jq -r '.tenantId')$reset
        echo "  "$bold"Environment:  "$reset $dim(echo $account | jq -r '.environmentName')$reset
        echo "  "$bold"State:        "$reset (
            set -l state (echo $account | jq -r '.state')
            test "$state" = Enabled && echo $_az_green$state$reset || echo $_az_yellow$state$reset
        )
    else
        echo "  "$_az_yellow"Not logged in. Run: az-login"$_az_reset
    end
    echo ""
end

# ─── az-rg: Resource group management ─────────────────────────────────────────
function az-rg --description "Azure resource group management"
    set -l action   $argv[1]
    set -l rg_name  $argv[2]
    set -l location $argv[3]

    switch $action
        case ls list
            echo ""
            echo $_az_bold$_az_blue"  📁 Resource Groups"$_az_reset
            echo ""
            az group list \
                --query '[].{name:name,location:location,state:properties.provisioningState}' \
                --output table 2>/dev/null | \
            while read -l line
                if string match -q 'Name*' $line
                    echo "  "$_az_bold$_az_blue$line$_az_reset
                else if string match -q '*Succeeded*' $line
                    echo "  "$_az_green$line$_az_reset
                else
                    echo "  "$_az_dim$line$_az_reset
                end
            end
            echo ""

        case create new
            test -z "$rg_name"  && read -P "  Resource group name: " rg_name
            test -z "$rg_name"  && return 1
            test -z "$location" && set location (az-pick-location)
            test -z "$location" && return 1

            az group create --name $rg_name --location $location
            and echo $_az_green"  ✓ Created: $rg_name ($location)"$_az_reset

        case delete rm
            test -z "$rg_name" && begin; echo "  Usage: az-rg delete <name>"; return 1; end
            echo $_az_red"  ⚠  Deleting resource group and ALL resources: $rg_name"$_az_reset
            read -P "  Type the name to confirm: " confirm
            test "$confirm" = "$rg_name" || begin; echo "  Cancelled."; return 0; end

            az group delete --name $rg_name --yes --no-wait
            and echo $_az_yellow"  ✓ Deletion initiated: $rg_name"$_az_reset

        case switch use
            if test -z "$rg_name" && command -q fzf
                set rg_name (
                    __az_resource_groups |
                    fzf --border-label "  📁 Select Resource Group " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶"
                )
                test -z "$rg_name" && return 0
            end
            az configure --defaults group=$rg_name
            set --export AZURE_DEFAULTS_GROUP $rg_name
            echo $_az_green"  ✓ Default resource group: $rg_name"$_az_reset

        case '*'
            echo "  Usage: az-rg <list|create|delete|switch>"
    end
end

function az-pick-location --description "Interactively pick an Azure location"
    if command -q fzf
        __az_locations |
        fzf --border-label "  🌍 Select Azure Location " \
            --border rounded \
            --prompt "  🌍 " \
            --pointer "▶" \
            --no-multi
    else
        read -P "  Azure location (e.g. eastus): " location
        echo $location
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖥️  VIRTUAL MACHINES                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── az-vm-ls: List Azure VMs ─────────────────────────────────────────────────
function az-vm-ls --description "List Azure Virtual Machines"
    set -l rg $argv[1]
    set -l flag ""
    test -n "$rg" && set flag "--resource-group $rg"

    echo ""
    echo $_az_bold$_az_blue"  🖥️  Azure Virtual Machines"$_az_reset
    echo ""

    eval az vm list $flag \
        --show-details \
        --query '[].{name:name,rg:resourceGroup,size:hardwareProfile.vmSize,os:storageProfile.osDisk.osType,state:powerState,ip:publicIps}' \
        --output table 2>/dev/null | \
    while read -l line
        if string match -q 'Name*' $line
            echo "  "$_az_bold$_az_blue$line$_az_reset
        else if string match -q '*running*' $line
            echo "  "$_az_green$line$_az_reset
        else if string match -q '*deallocated*' $line || string match -q '*stopped*' $line
            echo "  "$_az_dim$line$_az_reset
        else
            echo "  "$_az_yellow$line$_az_reset
        end
    end
    echo ""
end

# ─── az-vm-ssh: SSH into Azure VM ─────────────────────────────────────────────
function az-vm-ssh --description "SSH into an Azure VM"
    set -l vm $argv[1]
    set -l rg $argv[2]

    if test -z "$vm" && command -q fzf
        set -l selection (
            __az_vm_list |
            fzf --ansi \
                --border-label "  🖥️  Select Azure VM " \
                --border rounded \
                --prompt "  🔌 " \
                --pointer "▶" \
                --header '  Enter:SSH  Ctrl-B:Bastion  '
        )
        set vm (echo $selection | awk '{print $1}')
        set rg (echo $selection | awk '{print $2}' | string replace '(' '' | string replace ')' '')
        test -z "$vm" && return 0
    end

    set -l ssh_cmd "az ssh vm --name $vm"
    test -n "$rg" && set ssh_cmd "$ssh_cmd --resource-group $rg"

    echo $_az_cyan"  🔌 SSH: $vm"(test -n "$rg" && echo " ($rg)")$_az_reset
    eval $ssh_cmd $argv[3..-1]
end

# ─── az-vm-control: Start/stop/restart ────────────────────────────────────────
function az-vm-control --description "Control Azure VM power state"
    set -l action $argv[1]
    set -l vm     $argv[2]
    set -l rg     $argv[3]

    if test -z "$vm" && command -q fzf
        set -l selection (
            __az_vm_list |
            fzf --border-label "  🖥️  $action VM " \
                --border rounded \
                --prompt "  " \
                --pointer "▶"
        )
        set vm (echo $selection | awk '{print $1}')
        set rg (echo $selection | awk '{print $2}' | string replace '(' '' | string replace ')' '')
    end

    test -z "$vm" && begin; echo "  Usage: az-vm-control <start|stop|restart> <name> [rg]"; return 1; end

    set -l cmd_flag ""
    switch $action
        case stop
            echo $_az_yellow"  ⏹  Stopping: $vm"$_az_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            set cmd_flag "stop --no-wait"
        case start
            set cmd_flag "start"
        case restart reboot
            set cmd_flag "restart"
    end

    eval az vm $cmd_flag --name $vm (test -n "$rg" && echo "--resource-group $rg") $argv[4..-1]
    and echo $_az_green"  ✓ $action: $vm"$_az_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ☸️  AKS — KUBERNETES SERVICE                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── az-aks-ls: List AKS clusters ─────────────────────────────────────────────
function az-aks-ls --description "List Azure Kubernetes Service clusters"
    echo ""
    echo $_az_bold$_az_blue"  ☸️  AKS Clusters"$_az_reset
    echo ""

    az aks list \
        --query '[].{name:name,rg:resourceGroup,version:currentKubernetesVersion,status:powerState.code,nodes:agentPoolProfiles[0].count}' \
        --output table 2>/dev/null | \
    while read -l line
        if string match -q 'Name*' $line
            echo "  "$_az_bold$_az_blue$line$_az_reset
        else if string match -q '*Running*' $line
            echo "  "$_az_green$line$_az_reset
        else
            echo "  "$_az_yellow$line$_az_reset
        end
    end
    echo ""
end

# ─── az-aks-auth: Configure kubectl for AKS ───────────────────────────────────
function az-aks-auth --description "Configure kubectl credentials for AKS cluster"
    set -l cluster $argv[1]
    set -l rg      $argv[2]
    set -l admin   $argv[3]

    if test -z "$cluster" && command -q fzf
        set -l selection (
            __az_aks_clusters |
            fzf --ansi \
                --border-label "  ☸️  Select AKS Cluster " \
                --border rounded \
                --prompt "  ☸  " \
                --pointer "▶" \
                --preview 'echo "Cluster: {1}\nGroup: {2}"' \
                --preview-window 'down:3:border-rounded'
        )
        set cluster (echo $selection | awk '{print $1}')
        set rg      (echo $selection | awk '{print $2}' | string replace '(' '' | string replace ')' '')
        test -z "$cluster" && return 0
    end

    test -z "$cluster" && begin; echo "  Usage: az-aks-auth <cluster> [rg] [--admin]"; return 1; end
    test -z "$rg"      && set rg (az aks list --query "[?name=='$cluster'].resourceGroup" --output tsv 2>/dev/null)

    set -l auth_cmd "az aks get-credentials --name $cluster --resource-group $rg --overwrite-existing"
    test "$admin" = --admin && set auth_cmd "$auth_cmd --admin"

    echo ""
    echo $_az_cyan"  ☸️  Configuring kubectl: $cluster"$_az_reset
    eval $auth_cmd
    and echo $_az_green"  ✓ kubectl configured"$_az_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 AZURE FUNCTIONS & APP SERVICE                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── az-func-ls: List Function apps ───────────────────────────────────────────
function az-func-ls --description "List Azure Function apps"
    echo ""
    echo $_az_bold$_az_blue"  🚀 Function Apps"$_az_reset
    echo ""

    az functionapp list \
        --query '[].{name:name,rg:resourceGroup,runtime:siteConfig.linuxFxVersion,state:state,url:defaultHostName}' \
        --output table 2>/dev/null | \
    while read -l line
        if string match -q 'Name*' $line
            echo "  "$_az_bold$_az_blue$line$_az_reset
        else if string match -q '*Running*' $line
            echo "  "$_az_green$line$_az_reset
        else
            echo "  "$_az_yellow$line$_az_reset
        end
    end
    echo ""
end

# ─── az-func-logs: Stream Function app logs ────────────────────────────────────
function az-func-logs --description "Stream Azure Function app logs"
    set -l func_app $argv[1]
    set -l rg       $argv[2]

    if test -z "$func_app" && command -q fzf
        set -l selection (
            __az_function_apps |
            fzf --border-label "  🚀 Select Function App " \
                --border rounded \
                --prompt "  📋 " \
                --pointer "▶"
        )
        set func_app (echo $selection | awk '{print $1}')
        set rg       (echo $selection | awk '{print $2}' | string replace '(' '' | string replace ')' '')
        test -z "$func_app" && return 0
    end

    set -l log_cmd "az webapp log tail --name $func_app"
    test -n "$rg" && set log_cmd "$log_cmd --resource-group $rg"

    echo $_az_cyan"  📋 Streaming logs: $func_app"$_az_reset
    eval $log_cmd
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📦 CONTAINER REGISTRY (ACR)                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── az-acr-login: Login to Azure Container Registry ──────────────────────────
function az-acr-login --description "Login Docker to Azure Container Registry"
    set -l registry $argv[1]

    if test -z "$registry" && command -q fzf
        set registry (
            __az_acr_registries |
            fzf --border-label "  📦 Select ACR " \
                --border rounded \
                --prompt "  🐳 " \
                --pointer "▶" \
            | awk '{print $1}'
        )
        test -z "$registry" && return 0
    end

    echo ""
    echo $_az_cyan"  🔐 Logging into ACR: $registry"$_az_reset
    az acr login --name $registry
    and echo $_az_green"  ✓ ACR login successful"$_az_reset
    echo ""
end

# ─── az-acr-ls: List ACR registries and images ────────────────────────────────
function az-acr-ls --description "List ACR registries and repositories"
    set -l registry $argv[1]

    echo ""
    if test -z "$registry"
        echo $_az_bold$_az_blue"  📦 Container Registries"$_az_reset
        echo ""
        az acr list \
            --query '[].{name:name,rg:resourceGroup,sku:sku.name,loginServer:loginServer}' \
            --output table 2>/dev/null | \
        while read -l line
            string match -q 'Name*' $line \
                && echo "  "$_az_bold$_az_blue$line$_az_reset \
                || echo "  "$_az_dim$line$_az_reset
        end
    else
        echo $_az_bold$_az_blue"  📦 Repositories in $registry"$_az_reset
        echo ""
        az acr repository list \
            --name $registry \
            --output table 2>/dev/null | \
            while read -l line; echo "  "$_az_dim$line$_az_reset; end
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🗄️  STORAGE                                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── az-storage-ls: List storage accounts and containers ──────────────────────
function az-storage-ls --description "List Azure Storage accounts and containers"
    set -l account $argv[1]

    echo ""
    if test -z "$account"
        echo $_az_bold$_az_blue"  🗄️  Storage Accounts"$_az_reset
        echo ""
        az storage account list \
            --query '[].{name:name,rg:resourceGroup,kind:kind,replication:sku.replicationtype}' \
            --output table 2>/dev/null | \
        while read -l line
            string match -q 'Name*' $line \
                && echo "  "$_az_bold$_az_blue$line$_az_reset \
                || echo "  "$_az_dim$line$_az_reset
        end
    else
        echo $_az_bold$_az_blue"  🗄️  Containers in $account"$_az_reset
        echo ""
        az storage container list \
            --account-name $account \
            --query '[].{name:name,public:properties.publicAccess}' \
            --output table 2>/dev/null | \
        while read -l line
            string match -q 'Name*' $line \
                && echo "  "$_az_bold$_az_blue$line$_az_reset \
                || echo "  "$_az_dim$line$_az_reset
        end
    end
    echo ""
end

# ─── az-info: Complete Azure environment dashboard ────────────────────────────
function az-info --description "Show complete Azure environment information"
    set -l reset (set_color normal)
    set -l bold  (set_color --bold)
    set -l blue  (set_color 0078D4)
    set -l cyan  (set_color cyan)
    set -l green (set_color green)
    set -l dim   (set_color brblack)

    echo ""
    echo $bold$blue"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$blue"  ║     🔵  Azure CLI Dashboard                           ║"$reset
    echo $bold$blue"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"CLI Version: "$reset $dim(az --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Config dir:  "$reset $dim$AZURE_CONFIG_DIR$reset
    echo ""

    az-whoami
end

# ─── az-resources: List resources in group ────────────────────────────────────
function az-resources --description "List resources in a resource group"
    set -l rg $argv[1]

    if test -z "$rg" && command -q fzf
        set rg (
            __az_resource_groups |
            fzf --border-label "  📁 Select Resource Group " \
                --border rounded \
                --prompt "  " \
                --pointer "▶"
        )
        test -z "$rg" && return 0
    end

    echo ""
    echo $_az_bold$_az_blue"  📦 Resources: $rg"$_az_reset
    echo ""

    az resource list \
        --resource-group $rg \
        --query '[].{name:name,type:type,location:location}' \
        --output table 2>/dev/null | \
    while read -l line
        string match -q 'Name*' $line \
            && echo "  "$_az_bold$_az_blue$line$_az_reset \
            || echo "  "$_az_dim$line$_az_reset
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Auth & Subscription
abbr --add azl     'az-login'
abbr --add azw     'az-whoami'
abbr --add azs     'az-sub'
abbr --add azrg    'az-rg list'
abbr --add azrgs   'az-rg switch'
abbr --add azrgn   'az-rg create'
abbr --add azinfo  'az-info'
abbr --add azres   'az-resources'

# VM
abbr --add azvm    'az-vm-ls'
abbr --add azvmssh 'az-vm-ssh'
abbr --add azvmst  'az-vm-control start'
abbr --add azvmsp  'az-vm-control stop'
abbr --add azvmrb  'az-vm-control restart'

# AKS
abbr --add azaks   'az-aks-ls'
abbr --add azaksa  'az-aks-auth'

# Functions
abbr --add azfunc  'az-func-ls'
abbr --add azflogs 'az-func-logs'

# ACR
abbr --add azacr   'az-acr-ls'
abbr --add azacrl  'az-acr-login'

# Storage
abbr --add azst    'az-storage-ls'

# Direct az
abbr --add azver   'az --version'
abbr --add azupd   'az upgrade'
abbr --add azext   'az extension list'
abbr --add azexta  'az extension add'