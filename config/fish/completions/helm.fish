# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⛵  HELM — FISH COMPLETIONS v5.0 OMEGA                                     ║
# ║  Ultra Premium • Dynamic Releases • Chart Search • Multi-Repo • Live State  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guards ─────────────────────────────────────────────────────────────────────
function __helm_no_subcommand
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            completion create dependency env get history inspect install \
            lint list package plugin pull push registry repo rollback \
            search show status template test uninstall upgrade verify \
            version help
            return 1
        end
    end
    return 0
end

function __helm_sub_is --argument-names sub
    contains -- "$sub" (commandline -poc)
end

function __helm_seen_flag --argument-names flag
    contains -- "$flag" (commandline -poc)
end

function __helm_pos --argument-names n
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

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC DATA SOURCES
# ══════════════════════════════════════════════════════════════════════════════

# ── Deployed releases ──────────────────────────────────────────────────────────
function __helm_releases
    helm list --all-namespaces --short 2>/dev/null
end

function __helm_releases_with_desc
    helm list --all-namespaces \
        --output table \
        --no-headers 2>/dev/null | \
        awk '{printf "%s\t%s  %s  %s\n", $1, $2, $8, $9}'
end

# ── Releases in a namespace ────────────────────────────────────────────────────
function __helm_releases_ns
    set -l ns_arg ""
    if __helm_seen_flag -n; or __helm_seen_flag --namespace
        set -l tokens (commandline -poc)
        for i in (seq (count $tokens))
            if contains -- $tokens[$i] -n --namespace
                set ns_arg "--namespace=$tokens[(math $i + 1)]"
                break
            end
        end
    end
    helm list $ns_arg --short 2>/dev/null
end

# ── Repositories ───────────────────────────────────────────────────────────────
function __helm_repos
    helm repo list --output json 2>/dev/null | \
        python3 -c '
import json, sys
try:
    repos = json.load(sys.stdin)
    for r in repos:
        print(str(r["name"]) + "\t" + str(r["url"]))
except:
    pass
' 2>/dev/null
end

function __helm_repo_names
    helm repo list --short 2>/dev/null
end

# ── Charts from all repos ──────────────────────────────────────────────────────
function __helm_charts
    # Search all repos for charts (uses local cache)
    helm search repo "" --output json 2>/dev/null | \
        python3 -c '
import json, sys
try:
    charts = json.load(sys.stdin)
    for c in charts:
        name = c.get("name", "")
        desc = c.get("description", "")[:50]
        ver  = c.get("version", "")
        print(name + "\t" + ver + " — " + desc)
except:
    pass
' 2>/dev/null | head -200
end

# ── Charts in a specific repo ──────────────────────────────────────────────────
function __helm_repo_charts --argument-names repo
    test -z "$repo"; and return
    helm search repo "$repo/" --output json 2>/dev/null | \
        python3 -c '
import json, sys
try:
    charts = json.load(sys.stdin)
    for c in charts:
        name = c["name"].split("/")[-1]
        desc = c.get("description","")[:50]
        print(name + "\t" + desc)
except:
    pass
' 2>/dev/null
end

# ── Namespaces ─────────────────────────────────────────────────────────────────
function __helm_namespaces
    kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
        2>/dev/null | sort
end

# ── Kube contexts ──────────────────────────────────────────────────────────────
function __helm_contexts
    kubectl config get-contexts -o name 2>/dev/null | sort
end

# ── Release history ────────────────────────────────────────────────────────────
function __helm_history --argument-names release
    test -z "$release"; and return
    helm history "$release" --max 20 --output table 2>/dev/null | \
        awk 'NR>1 {printf "%s\t%s %s\n", $1, $4, $5}'
end

# ── Values files ───────────────────────────────────────────────────────────────
function __helm_values_files
    find . -maxdepth 1 -name "values.yaml" -o -name "values*.yaml" -o -name "values*.yml" -o -name "custom*.yaml" -o -name "*.values.yaml" 2>/dev/null | sed 's|^\./||'
    test -d values; and find values -type f 2>/dev/null
end

# ── Chart directories / tarballs ───────────────────────────────────────────────
function __helm_chart_paths
    find . -maxdepth 1 -name "*.tgz" -o -name "*.tar.gz" 2>/dev/null | sed 's|^\./||'
    find . -maxdepth 2 -name "Chart.yaml" 2>/dev/null | while read -l f
        set -l dir (dirname "$f")
        if test "$dir" = "."
            echo "."
        else
            echo (string replace "./" "" "$dir")/
        end
    end
end

# ── Installed plugins ──────────────────────────────────────────────────────────
function __helm_plugins
    helm plugin list --short 2>/dev/null
end

# ── OCI / registry targets ────────────────────────────────────────────────────
function __helm_registries
    # Read from helm config
    set -l config_file "$HOME/.config/helm/config.json"
    if test -f "$config_file"
        env config_file="$config_file" python3 -c '
import json, os
try:
    cfg = os.environ.get("config_file")
    with open(cfg) as f:
        data = json.load(f)
    for reg in data.get("auths", {}).keys():
        print(reg)
except:
    pass
' 2>/dev/null
    end
    printf '%s\t%s\n' \
        "oci://registry-1.docker.io/bitnamicharts" "Bitnami" \
        "oci://ghcr.io"                            "GitHub Container Registry" \
        "oci://registry.hub.docker.com"            "Docker Hub"
end

# ══════════════════════════════════════════════════════════════════════════════
#  TOP-LEVEL SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l helm_commands \
    "install\t🚀 Install a chart" \
    "upgrade\t⬆️  Upgrade a release" \
    "uninstall\t🗑️  Uninstall a release" \
    "rollback\t↩️  Roll back a release" \
    "list\t📋 List releases" \
    "history\t📜 Fetch release history" \
    "status\t📊 Display release status" \
    "get\t🔍 Get release info" \
    "show\t👁️  Show chart info" \
    "search\t🔍 Search charts" \
    "repo\t📦 Manage chart repos" \
    "registry\t🏗️  Manage OCI registries" \
    "pull\t⬇️  Pull chart to local" \
    "push\t⬆️  Push chart to OCI registry" \
    "package\t📦 Package chart as tgz" \
    "create\t✨ Create a new chart" \
    "lint\t✔️  Lint a chart" \
    "template\t📄 Render templates locally" \
    "dependency\t🔗 Manage chart dependencies" \
    "verify\t🔐 Verify chart provenance" \
    "test\t🧪 Run chart tests" \
    "diff\t🔍 Diff releases (plugin)" \
    "plugin\t🔌 Manage Helm plugins" \
    "env\t🌍 Show Helm env vars" \
    "completion\t🐟 Shell completions" \
    "version\t📌 Print version"

complete -c helm -f -n __helm_no_subcommand -a "$helm_commands"

# ── Global flags ───────────────────────────────────────────────────────────────
complete -c helm -l help           -s h  -d "Help"                               -f
complete -c helm -l namespace      -s n  -d "Kubernetes namespace"               -f \
    -a "(__helm_namespaces)"
complete -c helm -l kube-context         -d "kubeconfig context"                 -f \
    -a "(__helm_contexts)"
complete -c helm -l kubeconfig           -d "Path to kubeconfig"                 -F
complete -c helm -l kube-apiserver       -d "API server address"                 -f
complete -c helm -l kube-token           -d "Bearer token"                       -f
complete -c helm -l kube-as              -d "Impersonate as user"                -f
complete -c helm -l kube-as-group        -d "Impersonate as group"               -f
complete -c helm -l kube-as-uid          -d "Impersonate as UID"                 -f
complete -c helm -l kube-ca-file         -d "CA file for cluster"               -F
complete -c helm -l kube-insecure-skip-tls-verify -d "Skip TLS verify"          -f
complete -c helm -l kube-tls-server-name -d "TLS server name"                   -f
complete -c helm -l registry-config      -d "Registry config path"              -F
complete -c helm -l repository-cache     -d "Chart cache path"                  -F
complete -c helm -l repository-config    -d "Repo config path"                  -F
complete -c helm -l debug                -d "Enable verbose output"              -f
complete -c helm -l burst-limit          -d "Client-side throttle limit"         -f
complete -c helm -l qps                  -d "Queries per second"                 -f

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL
# ══════════════════════════════════════════════════════════════════════════════

# install <release-name> <chart>
complete -c helm -n "__helm_sub_is install; and test (count (commandline -poc)) -le 2" \
    -f -d "Release name (or --generate-name)"

complete -c helm -n "__helm_sub_is install; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_charts)" -d "Chart (repo/name or path)"
complete -c helm -n "__helm_sub_is install; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_chart_paths)" -d "Local chart"

# install flags
complete -c helm -n "__helm_sub_is install" \
    -s f -l values         -d "Values YAML file(s)"                         -F \
    -a "(__helm_values_files)"
complete -c helm -n "__helm_sub_is install" \
    -l set                 -d "Set value (key=val)"                          -f
complete -c helm -n "__helm_sub_is install" \
    -l set-string          -d "Set string value"                             -f
complete -c helm -n "__helm_sub_is install" \
    -l set-file            -d "Set value from file"                          -F
complete -c helm -n "__helm_sub_is install" \
    -l set-json            -d "Set JSON value"                               -f
complete -c helm -n "__helm_sub_is install" \
    -l set-literal         -d "Set literal string value"                     -f
complete -c helm -n "__helm_sub_is install" \
    -s n -l namespace      -d "Namespace to install into"                    -f \
    -a "(__helm_namespaces)"
complete -c helm -n "__helm_sub_is install" \
    -l create-namespace    -d "Create namespace if not present"              -f
complete -c helm -n "__helm_sub_is install" \
    -l generate-name -g    -d "Auto-generate release name"                   -f
complete -c helm -n "__helm_sub_is install" \
    -l name-template       -d "Release name template"                        -f
complete -c helm -n "__helm_sub_is install" \
    -l dry-run             -d "Simulate install"                             -f \
    -a "client\tClient-side server\tServer-side"
complete -c helm -n "__helm_sub_is install" \
    -l atomic              -d "Rollback on failure"                          -f
complete -c helm -n "__helm_sub_is install" \
    -l wait                -d "Wait until ready"                             -f
complete -c helm -n "__helm_sub_is install" \
    -l wait-for-jobs       -d "Wait for Jobs to complete"                    -f
complete -c helm -n "__helm_sub_is install" \
    -l timeout             -d "Time to wait (e.g. 5m0s)"                    -f \
    -a "1m 2m 5m 10m 30m 1h"
complete -c helm -n "__helm_sub_is install" \
    -l no-hooks            -d "Disable hooks"                                -f
complete -c helm -n "__helm_sub_is install" \
    -l render-subchart-notes -d "Render sub-chart NOTES.txt"                -f
complete -c helm -n "__helm_sub_is install" \
    -l replace             -d "Re-use the release name"                      -f
complete -c helm -n "__helm_sub_is install" \
    -l repo                -d "Chart repository URL"                         -f
complete -c helm -n "__helm_sub_is install" \
    -l version             -d "Chart version"                                -f
complete -c helm -n "__helm_sub_is install" \
    -l devel               -d "Use development versions"                     -f
complete -c helm -n "__helm_sub_is install" \
    -l username            -d "Chart repo username"                          -f
complete -c helm -n "__helm_sub_is install" \
    -l password            -d "Chart repo password"                          -f
complete -c helm -n "__helm_sub_is install" \
    -l ca-file             -d "CA file for TLS"                              -F
complete -c helm -n "__helm_sub_is install" \
    -l cert-file           -d "Client cert for TLS"                          -F
complete -c helm -n "__helm_sub_is install" \
    -l key-file            -d "Client key for TLS"                           -F
complete -c helm -n "__helm_sub_is install" \
    -l insecure-skip-tls-verify -d "Skip TLS verify"                        -f
complete -c helm -n "__helm_sub_is install" \
    -l plain-http          -d "Use HTTP instead of HTTPS"                    -f
complete -c helm -n "__helm_sub_is install" \
    -l pass-credentials    -d "Pass credentials to all domains"              -f
complete -c helm -n "__helm_sub_is install" \
    -l skip-crds           -d "Skip CRD installation"                        -f
complete -c helm -n "__helm_sub_is install" \
    -l enable-dns          -d "Enable DNS in template"                       -f
complete -c helm -n "__helm_sub_is install" \
    -l description         -d "Release description"                          -f
complete -c helm -n "__helm_sub_is install" \
    -l dependency-update   -d "Update dependencies before install"          -f
complete -c helm -n "__helm_sub_is install" \
    -l disable-openapi-validation -d "Disable OpenAPI validation"           -f
complete -c helm -n "__helm_sub_is install" \
    -l hide-notes          -d "Don't print NOTES.txt"                        -f
complete -c helm -n "__helm_sub_is install" \
    -l hide-secret         -d "Hide secrets in dry run output"               -f
complete -c helm -n "__helm_sub_is install" \
    -l post-renderer       -d "Exec for post-rendering"                      -f
complete -c helm -n "__helm_sub_is install" \
    -l post-renderer-args  -d "Args for post-renderer"                       -f
complete -c helm -n "__helm_sub_is install" \
    -l take-ownership      -d "Adopt existing resources"                     -f
complete -c helm -n "__helm_sub_is install" \
    -l verify              -d "Verify provenance"                            -f
complete -c helm -n "__helm_sub_is install" \
    -l keyring             -d "Path to keyring"                              -F
complete -c helm -n "__helm_sub_is install" \
    -s o -l output         -d "Output format"                                -f \
    -a "table\tTable json\tJSON yaml\tYAML"

# ══════════════════════════════════════════════════════════════════════════════
#  UPGRADE
# ══════════════════════════════════════════════════════════════════════════════

# upgrade <release> <chart>
complete -c helm -n "__helm_sub_is upgrade; and test (count (commandline -poc)) -le 2" \
    -f -a "(__helm_releases_with_desc)" -d "Release name"

complete -c helm -n "__helm_sub_is upgrade; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_charts)" -d "Chart"
complete -c helm -n "__helm_sub_is upgrade; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_chart_paths)" -d "Local chart"

# upgrade flags (many shared with install)
complete -c helm -n "__helm_sub_is upgrade" \
    -s f -l values          -d "Values file"                                -F \
    -a "(__helm_values_files)"
complete -c helm -n "__helm_sub_is upgrade" \
    -l set                  -d "Set value"                                  -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l set-string           -d "Set string value"                           -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l set-file             -d "Set value from file"                        -F
complete -c helm -n "__helm_sub_is upgrade" \
    -l set-json             -d "Set JSON value"                             -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l set-literal          -d "Set literal string"                         -f
complete -c helm -n "__helm_sub_is upgrade" \
    -s i -l install         -d "Install if not present"                     -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l create-namespace     -d "Create namespace if absent"                 -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l dry-run              -d "Simulate upgrade"                           -f \
    -a "client server"
complete -c helm -n "__helm_sub_is upgrade" \
    -l atomic               -d "Rollback on failure"                        -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l wait                 -d "Wait until ready"                           -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l wait-for-jobs        -d "Wait for Jobs"                              -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l timeout              -d "Timeout"                                    -f \
    -a "1m 2m 5m 10m 30m 1h"
complete -c helm -n "__helm_sub_is upgrade" \
    -l cleanup-on-fail      -d "Delete new resources on failure"            -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l force                -d "Force resource updates"                     -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l no-hooks             -d "Disable hooks"                              -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l render-subchart-notes -d "Render sub-chart NOTES.txt"               -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l repo                 -d "Chart repo URL"                             -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l version              -d "Chart version"                              -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l devel                -d "Include development versions"               -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l reset-values         -d "Reset to chart defaults"                    -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l reuse-values         -d "Reuse last release values"                  -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l reset-then-reuse-values -d "Reset then reuse values"                -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l history-max          -d "Max revision history"                       -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l skip-crds            -d "Skip CRD install"                          -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l dependency-update    -d "Update chart dependencies"                 -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l disable-openapi-validation -d "Disable schema validation"           -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l hide-notes           -d "Don't print NOTES.txt"                     -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l hide-secret          -d "Hide secrets in dry run"                   -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l post-renderer        -d "Post render exec"                          -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l post-renderer-args   -d "Post render args"                          -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l take-ownership       -d "Adopt existing resources"                  -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l verify               -d "Verify provenance"                         -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l username             -d "Repo username"                             -f
complete -c helm -n "__helm_sub_is upgrade" \
    -l password             -d "Repo password"                             -f
complete -c helm -n "__helm_sub_is upgrade" \
    -s o -l output          -d "Output format"                             -f \
    -a "table json yaml"

# ══════════════════════════════════════════════════════════════════════════════
#  UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is uninstall" \
    -f -a "(__helm_releases_with_desc)"

complete -c helm -n "__helm_sub_is uninstall" \
    -l dry-run              -d "Simulate uninstall"                         -f
complete -c helm -n "__helm_sub_is uninstall" \
    -l no-hooks             -d "Disable uninstall hooks"                    -f
complete -c helm -n "__helm_sub_is uninstall" \
    -l keep-history         -d "Keep release history"                       -f
complete -c helm -n "__helm_sub_is uninstall" \
    -l wait                 -d "Wait until deleted"                         -f
complete -c helm -n "__helm_sub_is uninstall" \
    -l timeout              -d "Timeout for uninstall"                      -f \
    -a "1m 5m 10m"
complete -c helm -n "__helm_sub_is uninstall" \
    -l cascade              -d "Cascade deletion mode" -f \
    -a "background foreground orphan"
complete -c helm -n "__helm_sub_is uninstall" \
    -l ignore-not-found     -d "Ignore not found errors"                    -f
complete -c helm -n "__helm_sub_is uninstall" \
    -l description          -d "Release description"                        -f

# ══════════════════════════════════════════════════════════════════════════════
#  ROLLBACK
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is rollback; and test (count (commandline -poc)) -le 2" \
    -f -a "(__helm_releases_with_desc)"

# Revision completion (after release name)
complete -c helm -n "__helm_sub_is rollback; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_history (__helm_pos 1))" -d "Revision"

complete -c helm -n "__helm_sub_is rollback" \
    -l cleanup-on-fail      -d "Delete new resources on fail"               -f
complete -c helm -n "__helm_sub_is rollback" \
    -l dry-run              -d "Simulate rollback"                          -f
complete -c helm -n "__helm_sub_is rollback" \
    -l force                -d "Force resource updates"                     -f
complete -c helm -n "__helm_sub_is rollback" \
    -l no-hooks             -d "Disable rollback hooks"                     -f
complete -c helm -n "__helm_sub_is rollback" \
    -l recreate-pods        -d "Restart pods for the release"               -f
complete -c helm -n "__helm_sub_is rollback" \
    -l timeout              -d "Timeout"                                    -f \
    -a "1m 5m 10m"
complete -c helm -n "__helm_sub_is rollback" \
    -l wait                 -d "Wait until ready"                           -f
complete -c helm -n "__helm_sub_is rollback" \
    -l wait-for-jobs        -d "Wait for Jobs"                              -f
complete -c helm -n "__helm_sub_is rollback" \
    -l history-max          -d "Max revisions to keep"                      -f

# ══════════════════════════════════════════════════════════════════════════════
#  LIST
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is list" \
    -s A -l all-namespaces  -d "All namespaces"                             -f
complete -c helm -n "__helm_sub_is list" \
    -s a -l all             -d "All releases (any state)"                   -f
complete -c helm -n "__helm_sub_is list" \
    -l deployed             -d "Deployed releases only"                     -f
complete -c helm -n "__helm_sub_is list" \
    -l failed               -d "Failed releases only"                       -f
complete -c helm -n "__helm_sub_is list" \
    -l pending              -d "Pending releases only"                      -f
complete -c helm -n "__helm_sub_is list" \
    -l superseded           -d "Superseded releases"                        -f
complete -c helm -n "__helm_sub_is list" \
    -l uninstalled          -d "Uninstalled releases"                       -f
complete -c helm -n "__helm_sub_is list" \
    -l uninstalling         -d "Uninstalling releases"                      -f
complete -c helm -n "__helm_sub_is list" \
    -s d -l date            -d "Sort by release date"                       -f
complete -c helm -n "__helm_sub_is list" \
    -s r -l reverse         -d "Reverse sort"                               -f
complete -c helm -n "__helm_sub_is list" \
    -s q -l short           -d "Only names"                                 -f
complete -c helm -n "__helm_sub_is list" \
    -l max               -m -d "Max releases to show"                       -f
complete -c helm -n "__helm_sub_is list" \
    -l offset               -d "Page offset"                                -f
complete -c helm -n "__helm_sub_is list" \
    -l filter            -f -d "Filter (regex)"                             -f
complete -c helm -n "__helm_sub_is list" \
    -l selector          -l -d "Label selector"                             -f
complete -c helm -n "__helm_sub_is list" \
    -l no-headers           -d "No header row"                              -f
complete -c helm -n "__helm_sub_is list" \
    -s o -l output          -d "Output format" -f \
    -a "table\tTable json\tJSON yaml\tYAML"

# ══════════════════════════════════════════════════════════════════════════════
#  STATUS
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is status" \
    -f -a "(__helm_releases_with_desc)"

complete -c helm -n "__helm_sub_is status" \
    -l revision             -d "Specific revision"                          -f \
    -a "(__helm_history (__helm_pos 1))"
complete -c helm -n "__helm_sub_is status" \
    -s o -l output          -d "Output format" -f \
    -a "table json yaml"
complete -c helm -n "__helm_sub_is status" \
    -l show-desc            -d "Show release description"                   -f
complete -c helm -n "__helm_sub_is status" \
    -l show-resources       -d "Show Kubernetes resources"                  -f

# ══════════════════════════════════════════════════════════════════════════════
#  GET
# ══════════════════════════════════════════════════════════════════════════════

set -l get_sub \
    "all\t📦 Get all info" \
    "hooks\t🪝 Get hooks" \
    "manifest\t📄 Get manifest" \
    "metadata\t📋 Get metadata" \
    "notes\t📝 Get NOTES.txt" \
    "values\t⚙️  Get values"

complete -c helm -n "__helm_sub_is get; and not __helm_seen_flag all hooks manifest metadata notes values" \
    -f -a "$get_sub"

for get_cmd in all hooks manifest metadata notes values
    complete -c helm -n "__helm_sub_is get; and __helm_seen_flag $get_cmd" \
        -f -a "(__helm_releases_with_desc)"
end

complete -c helm -n "__helm_sub_is get" \
    -l revision             -d "Specific revision"                          -f
complete -c helm -n "__helm_sub_is get; and __helm_seen_flag values" \
    -s a -l all             -d "All values (user + chart defaults)"         -f
complete -c helm -n "__helm_sub_is get" \
    -s o -l output          -d "Output format" -f \
    -a "table json yaml"

# ══════════════════════════════════════════════════════════════════════════════
#  SHOW
# ══════════════════════════════════════════════════════════════════════════════

set -l show_sub \
    "all\t📦 All chart info" \
    "chart\t📊 Chart metadata" \
    "crds\t⚙️  CRD definitions" \
    "readme\t📖 README.md" \
    "values\t⚙️  Default values"

complete -c helm -n "__helm_sub_is show; and not __helm_seen_flag all chart crds readme values" \
    -f -a "$show_sub"

for show_cmd in all chart crds readme values
    complete -c helm -n "__helm_sub_is show; and __helm_seen_flag $show_cmd" \
        -f -a "(__helm_charts)" -d "Chart"
    complete -c helm -n "__helm_sub_is show; and __helm_seen_flag $show_cmd" \
        -f -a "(__helm_chart_paths)" -d "Local chart"
end

complete -c helm -n "__helm_sub_is show" \
    -l version              -d "Chart version"                              -f
complete -c helm -n "__helm_sub_is show" \
    -l devel                -d "Include dev versions"                       -f
complete -c helm -n "__helm_sub_is show" \
    -l repo                 -d "Chart repo URL"                             -f
complete -c helm -n "__helm_sub_is show" \
    -l username             -d "Repo username"                              -f
complete -c helm -n "__helm_sub_is show" \
    -l password             -d "Repo password"                              -f
complete -c helm -n "__helm_sub_is show" \
    -l ca-file              -d "CA cert file"                               -F
complete -c helm -n "__helm_sub_is show" \
    -l cert-file            -d "Client cert"                                -F
complete -c helm -n "__helm_sub_is show" \
    -l key-file             -d "Client key"                                 -F
complete -c helm -n "__helm_sub_is show" \
    -l insecure-skip-tls-verify -d "Skip TLS verify"                       -f
complete -c helm -n "__helm_sub_is show" \
    -l plain-http           -d "Use HTTP"                                   -f
complete -c helm -n "__helm_sub_is show" \
    -l pass-credentials     -d "Pass credentials everywhere"               -f
complete -c helm -n "__helm_sub_is show" \
    -l jsonpath             -d "JSONPath filter"                            -f

# ══════════════════════════════════════════════════════════════════════════════
#  SEARCH
# ══════════════════════════════════════════════════════════════════════════════

set -l search_sub \
    "repo\t📦 Search chart repos" \
    "hub\t🌐 Search Artifact Hub"

complete -c helm -n "__helm_sub_is search; and not __helm_seen_flag repo hub" \
    -f -a "$search_sub"

complete -c helm -n "__helm_sub_is search; and __helm_seen_flag repo" \
    -f -a "(__helm_charts)"

complete -c helm -n "__helm_sub_is search" \
    -l devel                -d "Include development versions"               -f
complete -c helm -n "__helm_sub_is search" \
    -l version              -d "Chart version constraint"                   -f
complete -c helm -n "__helm_sub_is search" \
    -l regexp           -r  -d "Use regexp for search"                      -f
complete -c helm -n "__helm_sub_is search" \
    -l versions             -d "Show all versions"                          -f
complete -c helm -n "__helm_sub_is search" \
    -l max-col-width        -d "Max column width"                           -f
complete -c helm -n "__helm_sub_is search" \
    -s o -l output          -d "Output format" -f \
    -a "table json yaml"
complete -c helm -n "__helm_sub_is search; and __helm_seen_flag hub" \
    -l endpoint             -d "Artifact Hub endpoint"                      -f
complete -c helm -n "__helm_sub_is search; and __helm_seen_flag hub" \
    -l list-repo-url        -d "Print repo URLs"                            -f
complete -c helm -n "__helm_sub_is search; and __helm_seen_flag hub" \
    -l max-col-width        -d "Max column width"                           -f

# ══════════════════════════════════════════════════════════════════════════════
#  REPO
# ══════════════════════════════════════════════════════════════════════════════

set -l repo_sub \
    "add\t➕ Add chart repository" \
    "index\t🗂️  Generate index file" \
    "list\t📋 List repos" \
    "remove\t🗑️  Remove repository" \
    "update\t🔄 Update all repos" \
    "search\t🔍 Search in repos"

complete -c helm -n "__helm_sub_is repo; and not __helm_seen_flag add index list remove update search" \
    -f -a "$repo_sub"

# repo add <name> <url>
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add; and test (count (commandline -poc)) -eq 3" \
    -f -d "Repo name (alias)"

complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l username              -d "Repo username"                             -f
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l password              -d "Repo password"                             -f
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l pass-credentials      -d "Pass credentials always"                  -f
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l force-update          -d "Force update if exists"                    -f
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l no-update             -d "Don't update if exists"                    -f
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l ca-file               -d "CA cert"                                   -F
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l cert-file             -d "Client cert"                               -F
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l key-file              -d "Client key"                                -F
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l insecure-skip-tls-verify -d "Skip TLS verify"                       -f
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag add" \
    -l allow-deprecated-repos -d "Allow deprecated repos"                  -f

# repo remove — complete repo names
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag remove" \
    -f -a "(__helm_repo_names)"

# repo update — complete repo names
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag update" \
    -f -a "(__helm_repo_names)"
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag update" \
    -l fail-on-repo-update-fail -d "Fail if any repo update fails"         -f

# repo list output
complete -c helm -n "__helm_sub_is repo; and __helm_seen_flag list" \
    -s o -l output          -d "Output format" -f -a "table json yaml"

# ══════════════════════════════════════════════════════════════════════════════
#  REGISTRY
# ══════════════════════════════════════════════════════════════════════════════

set -l registry_sub \
    "login\t🔑 Authenticate to OCI registry" \
    "logout\t🚪 Logout from OCI registry"

complete -c helm -n "__helm_sub_is registry; and not __helm_seen_flag login logout" \
    -f -a "$registry_sub"

complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login logout" \
    -f -a "(__helm_registries)"

complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -s u -l username         -d "Username"                                  -f
complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -s p -l password         -d "Password"                                  -f
complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -l password-stdin        -d "Read password from stdin"                  -f
complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -l ca-file               -d "CA cert"                                   -F
complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -l cert-file             -d "Client cert"                               -F
complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -l key-file              -d "Client key"                                -F
complete -c helm -n "__helm_sub_is registry; and __helm_seen_flag login" \
    -l insecure              -d "Allow insecure HTTP"                       -f

# ══════════════════════════════════════════════════════════════════════════════
#  PULL
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is pull" \
    -f -a "(__helm_charts)"

complete -c helm -n "__helm_sub_is pull" \
    -l repo                  -d "Chart repo URL"                            -f
complete -c helm -n "__helm_sub_is pull" \
    -l version               -d "Chart version"                             -f
complete -c helm -n "__helm_sub_is pull" \
    -l devel                 -d "Include dev versions"                      -f
complete -c helm -n "__helm_sub_is pull" \
    -l destination           -d "Save directory"                            -F
complete -c helm -n "__helm_sub_is pull" \
    -l prov                  -d "Fetch provenance file"                     -f
complete -c helm -n "__helm_sub_is pull" \
    -l untar                 -d "Extract tarball"                           -f
complete -c helm -n "__helm_sub_is pull" \
    -l untardir              -d "Untar directory"                           -F
complete -c helm -n "__helm_sub_is pull" \
    -l verify                -d "Verify provenance"                         -f
complete -c helm -n "__helm_sub_is pull" \
    -l keyring               -d "Path to keyring"                           -F
complete -c helm -n "__helm_sub_is pull" \
    -l username              -d "Repo username"                             -f
complete -c helm -n "__helm_sub_is pull" \
    -l password              -d "Repo password"                             -f
complete -c helm -n "__helm_sub_is pull" \
    -l ca-file               -d "CA cert"                                   -F
complete -c helm -n "__helm_sub_is pull" \
    -l cert-file             -d "Client cert"                               -F
complete -c helm -n "__helm_sub_is pull" \
    -l key-file              -d "Client key"                                -F
complete -c helm -n "__helm_sub_is pull" \
    -l insecure-skip-tls-verify -d "Skip TLS verify"                       -f
complete -c helm -n "__helm_sub_is pull" \
    -l pass-credentials      -d "Pass credentials to all"                  -f
complete -c helm -n "__helm_sub_is pull" \
    -l plain-http            -d "Use HTTP"                                  -f

# ══════════════════════════════════════════════════════════════════════════════
#  PUSH
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is push" \
    -f -a "(__helm_chart_paths)" -d "Chart package"

complete -c helm -n "__helm_sub_is push" \
    -f -a "(__helm_registries)" -d "OCI registry"

complete -c helm -n "__helm_sub_is push" \
    -l ca-file               -d "CA cert"                                   -F
complete -c helm -n "__helm_sub_is push" \
    -l cert-file             -d "Client cert"                               -F
complete -c helm -n "__helm_sub_is push" \
    -l key-file              -d "Client key"                                -F
complete -c helm -n "__helm_sub_is push" \
    -l insecure-skip-tls-verify -d "Skip TLS verify"                       -f
complete -c helm -n "__helm_sub_is push" \
    -l plain-http            -d "Use HTTP"                                  -f
complete -c helm -n "__helm_sub_is push" \
    -l sign                  -d "Sign chart"                                -f
complete -c helm -n "__helm_sub_is push" \
    -l key                   -d "Signing key name"                          -f
complete -c helm -n "__helm_sub_is push" \
    -l keyring               -d "Path to keyring"                           -F

# ══════════════════════════════════════════════════════════════════════════════
#  TEMPLATE
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is template; and test (count (commandline -poc)) -le 2" \
    -f -d "Release name"

complete -c helm -n "__helm_sub_is template; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_charts)" -d "Chart"
complete -c helm -n "__helm_sub_is template; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__helm_chart_paths)" -d "Local chart"

complete -c helm -n "__helm_sub_is template" \
    -s f -l values           -d "Values file"                               -F \
    -a "(__helm_values_files)"
complete -c helm -n "__helm_sub_is template" \
    -l set                   -d "Set value"                                 -f
complete -c helm -n "__helm_sub_is template" \
    -l set-string            -d "Set string value"                          -f
complete -c helm -n "__helm_sub_is template" \
    -l set-file              -d "Set value from file"                       -F
complete -c helm -n "__helm_sub_is template" \
    -l set-json              -d "Set JSON value"                            -f
complete -c helm -n "__helm_sub_is template" \
    -l show-only             -d "Only show specific templates"              -f
complete -c helm -n "__helm_sub_is template" \
    -l output-dir            -d "Write to directory"                        -F
complete -c helm -n "__helm_sub_is template" \
    -l release-name          -d "Include release name in output"            -f
complete -c helm -n "__helm_sub_is template" \
    -l is-upgrade            -d "Set HELM_IS_UPGRADE flag"                  -f
complete -c helm -n "__helm_sub_is template" \
    -l validate              -d "Validate against cluster"                  -f
complete -c helm -n "__helm_sub_is template" \
    -l include-crds          -d "Include CRDs"                              -f
complete -c helm -n "__helm_sub_is template" \
    -l skip-crds             -d "Skip CRDs"                                 -f
complete -c helm -n "__helm_sub_is template" \
    -l no-hooks              -d "Skip hook templates"                       -f
complete -c helm -n "__helm_sub_is template" \
    -l api-versions          -d "API versions for validation"               -f
complete -c helm -n "__helm_sub_is template" \
    -l kube-version          -d "Kubernetes version"                        -f
complete -c helm -n "__helm_sub_is template" \
    -s a -l generate-name    -d "Auto-generate name"                        -f
complete -c helm -n "__helm_sub_is template" \
    -l version               -d "Chart version"                             -f
complete -c helm -n "__helm_sub_is template" \
    -l repo                  -d "Chart repo URL"                            -f
complete -c helm -n "__helm_sub_is template" \
    -l devel                 -d "Include dev versions"                      -f
complete -c helm -n "__helm_sub_is template" \
    -l dependency-update     -d "Update dependencies"                       -f
complete -c helm -n "__helm_sub_is template" \
    -l post-renderer         -d "Post render exec"                          -f
complete -c helm -n "__helm_sub_is template" \
    -l post-renderer-args    -d "Post render args"                          -f
complete -c helm -n "__helm_sub_is template" \
    -l disable-openapi-validation -d "Skip OpenAPI validation"             -f

# ══════════════════════════════════════════════════════════════════════════════
#  LINT
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is lint" \
    -f -a "(__helm_chart_paths)" -d "Chart path"

complete -c helm -n "__helm_sub_is lint" \
    -s f -l values           -d "Values file"                               -F \
    -a "(__helm_values_files)"
complete -c helm -n "__helm_sub_is lint" \
    -l set                   -d "Set value"                                 -f
complete -c helm -n "__helm_sub_is lint" \
    -l set-string            -d "Set string"                                -f
complete -c helm -n "__helm_sub_is lint" \
    -l set-file              -d "Set from file"                             -F
complete -c helm -n "__helm_sub_is lint" \
    -l set-json              -d "Set JSON"                                  -f
complete -c helm -n "__helm_sub_is lint" \
    -l with-subcharts        -d "Lint sub-charts"                           -f
complete -c helm -n "__helm_sub_is lint" \
    -l quiet             -q  -d "Only show errors"                          -f
complete -c helm -n "__helm_sub_is lint" \
    -l strict                -d "Fail on warnings"                          -f
complete -c helm -n "__helm_sub_is lint" \
    -l kube-version          -d "Kubernetes version for validation"         -f
complete -c helm -n "__helm_sub_is lint" \
    -l api-versions          -d "API versions for validation"               -f

# ══════════════════════════════════════════════════════════════════════════════
#  DEPENDENCY
# ══════════════════════════════════════════════════════════════════════════════

set -l dep_sub \
    "build\t🔨 Build chart dependencies" \
    "list\t📋 List dependencies" \
    "update\t🔄 Update dependencies"

complete -c helm -n "__helm_sub_is dependency; and not __helm_seen_flag build list update" \
    -f -a "$dep_sub"

for dep_cmd in build list update
    complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag $dep_cmd" \
        -f -a "(__helm_chart_paths)" -d "Chart path"
end

complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag build" \
    -l skip-refresh          -d "Skip refreshing repos"                     -f
complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag build" \
    -l verify                -d "Verify packages"                           -f
complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag build" \
    -l keyring               -d "Path to keyring"                           -F

complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag update" \
    -l skip-refresh          -d "Skip refreshing repos"                     -f
complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag update" \
    -l verify                -d "Verify packages"                           -f
complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag update" \
    -l keyring               -d "Path to keyring"                           -F

complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag list" \
    -l max-col-width         -d "Max column width"                          -f
complete -c helm -n "__helm_sub_is dependency; and __helm_seen_flag list" \
    -s o -l output           -d "Output format" -f \
    -a "table json yaml"

# ══════════════════════════════════════════════════════════════════════════════
#  PACKAGE
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is package" \
    -f -a "(__helm_chart_paths)" -d "Chart path"

complete -c helm -n "__helm_sub_is package" \
    -s d -l destination      -d "Output directory"                          -F
complete -c helm -n "__helm_sub_is package" \
    -l dependency-update     -d "Update deps before packaging"              -f
complete -c helm -n "__helm_sub_is package" \
    -l version               -d "Override chart version"                    -f
complete -c helm -n "__helm_sub_is package" \
    -l app-version           -d "Override appVersion"                       -f
complete -c helm -n "__helm_sub_is package" \
    -l sign                  -d "Sign the chart"                            -f
complete -c helm -n "__helm_sub_is package" \
    -l key                   -d "Signing key name"                          -f
complete -c helm -n "__helm_sub_is package" \
    -l keyring               -d "Keyring path"                              -F
complete -c helm -n "__helm_sub_is package" \
    -l passphrase-file       -d "File with key passphrase"                  -F

# ══════════════════════════════════════════════════════════════════════════════
#  CREATE
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is create" \
    -f -d "Chart name"

complete -c helm -n "__helm_sub_is create" \
    -s p -l starter          -d "Starter chart name or path"                -F

# ══════════════════════════════════════════════════════════════════════════════
#  HISTORY
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is history" \
    -f -a "(__helm_releases_with_desc)"

complete -c helm -n "__helm_sub_is history" \
    -l max                   -d "Max revisions"                             -f
complete -c helm -n "__helm_sub_is history" \
    -s o -l output           -d "Output format" -f \
    -a "table json yaml"

# ══════════════════════════════════════════════════════════════════════════════
#  TEST
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is test" \
    -f -a "(__helm_releases_with_desc)"

complete -c helm -n "__helm_sub_is test" \
    -l filter                -d "Filter test by name"                       -f
complete -c helm -n "__helm_sub_is test" \
    -l logs                  -d "Dump pod logs on failure"                  -f
complete -c helm -n "__helm_sub_is test" \
    -l timeout               -d "Timeout for tests"                         -f \
    -a "1m 5m 10m 30m"

# ══════════════════════════════════════════════════════════════════════════════
#  PLUGIN
# ══════════════════════════════════════════════════════════════════════════════

set -l plugin_sub \
    "install\t⬇️  Install plugin" \
    "list\t📋 List plugins" \
    "uninstall\t🗑️  Remove plugin" \
    "update\t🔄 Update plugin"

complete -c helm -n "__helm_sub_is plugin; and not __helm_seen_flag install list uninstall update" \
    -f -a "$plugin_sub"

complete -c helm -n "__helm_sub_is plugin; and __helm_seen_flag install" \
    -f -d "Plugin URL or path"
complete -c helm -n "__helm_sub_is plugin; and __helm_seen_flag install" \
    -l version               -d "Plugin version"                            -f

for plugin_cmd in uninstall update
    complete -c helm -n "__helm_sub_is plugin; and __helm_seen_flag $plugin_cmd" \
        -f -a "(__helm_plugins)"
end

# ══════════════════════════════════════════════════════════════════════════════
#  COMPLETION
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is completion" \
    -f -a "bash\tBash fish\tFish zsh\tZsh powershell\tPowerShell"

complete -c helm -n "__helm_sub_is completion" \
    -l no-descriptions       -d "Disable completion descriptions"           -f

# ══════════════════════════════════════════════════════════════════════════════
#  VERIFY / DIFF / ENV
# ══════════════════════════════════════════════════════════════════════════════

complete -c helm -n "__helm_sub_is verify" \
    -f -a "(__helm_chart_paths)"
complete -c helm -n "__helm_sub_is verify" \
    -l keyring               -d "Path to keyring"                           -F

complete -c helm -n "__helm_sub_is diff" \
    -f -a "(__helm_releases_with_desc)"
complete -c helm -n "__helm_sub_is diff" \
    -f -a "(__helm_charts)"

complete -c helm -n "__helm_sub_is env" \
    -l unset                 -d "Unset variable"                            -f
