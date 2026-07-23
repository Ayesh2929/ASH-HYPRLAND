#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗                              ║
# ║  ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗                             ║
# ║  ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝                             ║
# ║  ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗                             ║
# ║  ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║                             ║
# ║  ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝                             ║
# ║   █████╗ ██████╗ ██████╗ ██████╗     ███████╗                                  ║
# ║  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗    ██╔════╝                                  ║
# ║  ███████║██████╔╝██████╔╝██████╔╝    ███████╗                                  ║
# ║  ██╔══██║██╔══██╗██╔══██╗██╔══██╗    ╚════██║                                  ║
# ║  ██║  ██║██████╔╝██████╔╝██║  ██║    ███████║                                  ║
# ║  ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝    ╚══════╝                                  ║
# ║                                                                                  ║
# ║   🐳 DOCKER & K8S ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                      ║
# ║   Docker • Compose • Podman • Kubernetes • Helm • k9s                           ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_docker_initialized && exit 0
set -g __ash_abbr_docker_initialized 1

command -sq docker || command -sq podman || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐳 DOCKER — Core commands
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a d      "docker"

# ── Containers ────────────────────────────────────────────────────────────────
abbr -a dps    "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
abbr -a dpsa   "docker ps --all --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}'"
abbr -a dpsl   "docker ps --latest"
abbr -a dpsq   "docker ps --quiet"
abbr -a dpsaq  "docker ps --all --quiet"

abbr -a drun   "docker run --interactive --tty --rm"
abbr -a drund  "docker run --detach"
abbr -a drunp  "docker run --interactive --tty --rm --publish"
abbr -a drunv  "docker run --interactive --tty --rm --volume"
abbr -a drune  "docker run --interactive --tty --rm --env"
abbr -a drunn  "docker run --interactive --tty --rm --network=host"

abbr -a dex    "docker exec --interactive --tty"
abbr -a dexr   "docker exec --interactive --tty --user=root"
abbr -a dexsh  "docker exec --interactive --tty -- sh"
abbr -a dexb   "docker exec --interactive --tty -- bash"
abbr -a dexf   "docker exec --interactive --tty -- fish"

abbr -a dstart "docker start"
abbr -a dstop  "docker stop"
abbr -a drest  "docker restart"
abbr -a dkill  "docker kill"
abbr -a drm    "docker rm"
abbr -a drmf   "docker rm --force"
abbr -a drmaq  "docker rm (docker ps --all --quiet) 2>/dev/null"  # Remove all stopped
abbr -a dpause "docker pause"
abbr -a dunpause "docker unpause"
abbr -a datt   "docker attach"
abbr -a dwait  "docker wait"
abbr -a drename "docker rename"

# ── Logs ──────────────────────────────────────────────────────────────────────
abbr -a dlogs  "docker logs --follow --timestamps"
abbr -a dlogst "docker logs --follow --timestamps --tail=100"
abbr -a dlogsp "docker logs --follow --timestamps --since=1h"

# ── Inspect ───────────────────────────────────────────────────────────────────
abbr -a dinsp  "docker inspect"
abbr -a dinspj "docker inspect --format='{{json .}}' | jq"
abbr -a dtop   "docker top"
abbr -a dstat  "docker stats --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"
abbr -a dstatf "docker stats"
abbr -a dport  "docker port"
abbr -a ddiff  "docker diff"
abbr -a dcp    "docker cp"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖼️  IMAGES — Build & registry
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a dim    "docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}'"
abbr -a dima   "docker images --all"
abbr -a dimd   "docker images --filter=dangling=true"

abbr -a dbuild "docker build --progress=plain"
abbr -a dbuildx "docker buildx build --progress=plain"
abbr -a dbuildnc "docker build --no-cache --progress=plain"
abbr -a dbuildt "docker build --tag"

abbr -a dpull  "docker pull"
abbr -a dpush  "docker push"
abbr -a dtag   "docker tag"
abbr -a drmi   "docker rmi"
abbr -a drmid  "docker rmi (docker images --filter=dangling=true -q) 2>/dev/null"
abbr -a dsave  "docker save --output"
abbr -a dload  "docker load --input"
abbr -a dhist  "docker history"
abbr -a dsrch  "docker search --format 'table {{.Name}}\t{{.Stars}}\t{{.IsOfficial}}'"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🗄️  VOLUMES & NETWORKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Volumes
abbr -a dvl    "docker volume ls"
abbr -a dvc    "docker volume create"
abbr -a dvi    "docker volume inspect"
abbr -a dvrm   "docker volume rm"
abbr -a dvprune "docker volume prune --force"

# Networks
abbr -a dnl    "docker network ls"
abbr -a dnc    "docker network create"
abbr -a dni    "docker network inspect"
abbr -a dnrm   "docker network rm"
abbr -a dncon  "docker network connect"
abbr -a dndis  "docker network disconnect"
abbr -a dnprune "docker network prune --force"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP — Prune resources
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a dprune  "docker system prune --all --volumes --force"
abbr -a dprunes "docker system prune --force"
abbr -a dcprune "docker container prune --force"
abbr -a diprune "docker image prune --all --force"
abbr -a dsize   "docker system df --verbose"
abbr -a dclean  "docker system prune --all --volumes --force && docker network prune --force"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎼 DOCKER COMPOSE — Multi-service orchestration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a dc      "docker compose"

# ── Lifecycle ─────────────────────────────────────────────────────────────────
abbr -a dcu     "docker compose up"
abbr -a dcud    "docker compose up --detach"
abbr -a dcudb   "docker compose up --detach --build"
abbr -a dcub    "docker compose up --build"
abbr -a dcudf   "docker compose up --detach --force-recreate"
abbr -a dcd     "docker compose down"
abbr -a dcdv    "docker compose down --volumes"
abbr -a dcdr    "docker compose down --remove-orphans"
abbr -a dcdvr   "docker compose down --volumes --remove-orphans"
abbr -a dcstart "docker compose start"
abbr -a dcstop  "docker compose stop"
abbr -a dcrest  "docker compose restart"
abbr -a dcpause "docker compose pause"
abbr -a dcup    "docker compose unpause"
abbr -a dckill  "docker compose kill"

# ── Build ─────────────────────────────────────────────────────────────────────
abbr -a dcb     "docker compose build"
abbr -a dcbp    "docker compose build --parallel"
abbr -a dcbnc   "docker compose build --no-cache"
abbr -a dcpull  "docker compose pull"

# ── Monitoring ────────────────────────────────────────────────────────────────
abbr -a dcl     "docker compose logs --follow --timestamps"
abbr -a dclt    "docker compose logs --follow --timestamps --tail=100"
abbr -a dcls    "docker compose ps --format 'table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
abbr -a dclsa   "docker compose ps --all"
abbr -a dcstat  "docker compose stats"
abbr -a dctop   "docker compose top"

# ── Execution ─────────────────────────────────────────────────────────────────
abbr -a dce     "docker compose exec"
abbr -a dcer    "docker compose exec --user=root"
abbr -a dcrun   "docker compose run --rm"
abbr -a dcrunr  "docker compose run --rm --user=root"

# ── Config ────────────────────────────────────────────────────────────────────
abbr -a dcconf  "docker compose config"
abbr -a dcconfs "docker compose config --services"
abbr -a dcver   "docker compose version"
abbr -a dcport  "docker compose port"
abbr -a dcinsp  "docker compose images"

# ── Full cleanup ──────────────────────────────────────────────────────────────
abbr -a dcclean "docker compose down --volumes --remove-orphans --rmi local"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧊 PODMAN — Rootless containers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq podman && not command -sq docker
    abbr -a pd     "podman"
    abbr -a pdps   "podman ps --all"
    abbr -a pdrun  "podman run --interactive --tty --rm"
    abbr -a pdex   "podman exec --interactive --tty"
    abbr -a pdbuild "podman build"
    abbr -a pdpull "podman pull"
    abbr -a pdpush "podman push"
    abbr -a pdrm   "podman rm"
    abbr -a pdrmi  "podman rmi"
    abbr -a pdlogs "podman logs --follow"
    abbr -a pdinsp "podman inspect"
    abbr -a pdstat "podman stats"
    abbr -a pdkube "podman generate kube"     # Generate Kubernetes YAML
    abbr -a pdmach "podman machine"
    abbr -a pdmi   "podman machine init"
    abbr -a pdms   "podman machine start"
    abbr -a pdmt   "podman machine stop"
    abbr -a pdml   "podman machine list"
    abbr -a pdmss  "podman machine ssh"
    abbr -a pdclean "podman system prune --all --volumes --force"
    abbr -a pdsize "podman system df"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ☸️  KUBERNETES — kubectl abbreviations
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq kubectl
    abbr -a k      "kubectl"

    # ── Get resources ─────────────────────────────────────────────────────────
    abbr -a kg     "kubectl get"
    abbr -a kga    "kubectl get all --all-namespaces"
    abbr -a kgp    "kubectl get pods --all-namespaces --output=wide"
    abbr -a kgpw   "kubectl get pods --watch"
    abbr -a kgpn   "kubectl get pods --namespace"
    abbr -a kgs    "kubectl get services --all-namespaces"
    abbr -a kgd    "kubectl get deployments --all-namespaces"
    abbr -a kgn    "kubectl get nodes --output=wide"
    abbr -a kgns   "kubectl get namespaces"
    abbr -a kgcm   "kubectl get configmaps"
    abbr -a kgsec  "kubectl get secrets"
    abbr -a kging  "kubectl get ingress --all-namespaces"
    abbr -a kgpvc  "kubectl get persistentvolumeclaims --all-namespaces"
    abbr -a kgpv   "kubectl get persistentvolumes"
    abbr -a kgcj   "kubectl get cronjobs --all-namespaces"
    abbr -a kgj    "kubectl get jobs --all-namespaces"
    abbr -a kgst   "kubectl get statefulsets --all-namespaces"
    abbr -a kgds   "kubectl get daemonsets --all-namespaces"
    abbr -a kghpa  "kubectl get hpa --all-namespaces"
    abbr -a kgrs   "kubectl get replicasets --all-namespaces"
    abbr -a kgsvc  "kubectl get services"
    abbr -a kgep   "kubectl get endpoints"
    abbr -a kgev   "kubectl get events --sort-by='.lastTimestamp'"
    abbr -a kgsa   "kubectl get serviceaccounts"
    abbr -a kgrb   "kubectl get rolebindings --all-namespaces"
    abbr -a kgcrb  "kubectl get clusterrolebindings"

    # ── JSON output ───────────────────────────────────────────────────────────
    abbr -a kgpj   "kubectl get pods --output=json | jq"
    abbr -a kgnj   "kubectl get nodes --output=json | jq"
    abbr -a kgdj   "kubectl get deployments --output=json | jq"

    # ── Describe ──────────────────────────────────────────────────────────────
    abbr -a kd     "kubectl describe"
    abbr -a kdp    "kubectl describe pod"
    abbr -a kdn    "kubectl describe node"
    abbr -a kds    "kubectl describe service"
    abbr -a kdd    "kubectl describe deployment"
    abbr -a kdcm   "kubectl describe configmap"
    abbr -a kdsec  "kubectl describe secret"

    # ── Logs ──────────────────────────────────────────────────────────────────
    abbr -a kl     "kubectl logs --follow --timestamps"
    abbr -a klt    "kubectl logs --follow --timestamps --tail=100"
    abbr -a klp    "kubectl logs --follow --timestamps --previous"
    abbr -a kla    "kubectl logs --follow --timestamps --all-containers"
    abbr -a kls    "kubectl logs --follow --since=1h"

    # ── Execute ───────────────────────────────────────────────────────────────
    abbr -a ke     "kubectl exec --stdin --tty"
    abbr -a kesh   "kubectl exec --stdin --tty -- sh"
    abbr -a kebash "kubectl exec --stdin --tty -- bash"
    abbr -a kefish "kubectl exec --stdin --tty -- fish"

    # ── Apply & Delete ────────────────────────────────────────────────────────
    abbr -a ka     "kubectl apply --filename"
    abbr -a kar    "kubectl apply --recursive --filename"
    abbr -a kak    "kubectl apply --kustomize"
    abbr -a kdel   "kubectl delete"
    abbr -a kdelf  "kubectl delete --filename"
    abbr -a kdelp  "kubectl delete pod --grace-period=0 --force"
    abbr -a kdeld  "kubectl delete deployment"
    abbr -a kdels  "kubectl delete service"
    abbr -a kdelns "kubectl delete namespace"

    # ── Context & Namespace ───────────────────────────────────────────────────
    abbr -a kctx   "kubectl config use-context"
    abbr -a kctxl  "kubectl config get-contexts"
    abbr -a kctxc  "kubectl config current-context"
    abbr -a kctxd  "kubectl config delete-context"
    abbr -a kns    "kubectl config set-context --current --namespace"
    abbr -a knsl   "kubectl get namespaces"
    abbr -a kcfg   "kubectl config view"
    abbr -a kcfgm  "kubectl config view --minify"

    # kubectx/kubens (if installed — faster switching)
    command -sq kubectx && abbr -a kctx "kubectx"
    command -sq kubens  && abbr -a kns  "kubens"

    # ── Scale & Rollout ───────────────────────────────────────────────────────
    abbr -a kscale "kubectl scale"
    abbr -a kscaled "kubectl scale deployment"
    abbr -a kroll  "kubectl rollout"
    abbr -a krollst "kubectl rollout status"
    abbr -a krollh "kubectl rollout history"
    abbr -a krollu "kubectl rollout undo"
    abbr -a krollr "kubectl rollout restart"
    abbr -a krolla "kubectl rollout restart deployment --all"

    # ── Port Forward ──────────────────────────────────────────────────────────
    abbr -a kpf    "kubectl port-forward"
    abbr -a kpfp   "kubectl port-forward pod"
    abbr -a kpfs   "kubectl port-forward service"

    # ── Cluster Info ──────────────────────────────────────────────────────────
    abbr -a kinfo  "kubectl cluster-info"
    abbr -a kver   "kubectl version"
    abbr -a kcomp  "kubectl version --short"
    abbr -a ktop   "kubectl top"
    abbr -a ktopp  "kubectl top pods --all-namespaces"
    abbr -a ktopm  "kubectl top nodes"

    # ── Patch & Label ─────────────────────────────────────────────────────────
    abbr -a kpatch "kubectl patch"
    abbr -a klabel "kubectl label"
    abbr -a kanno  "kubectl annotate"
    abbr -a ktaint "kubectl taint"

    # ── Debug ─────────────────────────────────────────────────────────────────
    abbr -a kdebug "kubectl run debug-pod --image=busybox --restart=Never --rm --stdin --tty -- sh"
    abbr -a kdbg   "kubectl debug --it --image=nicolaka/netshoot"

    # ── Create & Generate ─────────────────────────────────────────────────────
    abbr -a kcreate "kubectl create"
    abbr -a kcrns   "kubectl create namespace"
    abbr -a kcrsec  "kubectl create secret generic"
    abbr -a kcrcm   "kubectl create configmap"
    abbr -a kgen    "kubectl create --dry-run=client --output=yaml"

    # ── Diff & Dry-run ────────────────────────────────────────────────────────
    abbr -a kdiff   "kubectl diff --filename"
    abbr -a kdry    "kubectl apply --dry-run=client --filename"
    abbr -a kdrysvr "kubectl apply --dry-run=server --filename"

    # ── Misc ──────────────────────────────────────────────────────────────────
    abbr -a kres    "kubectl api-resources"
    abbr -a kresv   "kubectl api-versions"
    abbr -a kexp    "kubectl explain"
    abbr -a kwho    "kubectl auth whoami"
    abbr -a kcan    "kubectl auth can-i"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⛵ HELM — Package manager for Kubernetes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq helm
    abbr -a h      "helm"
    abbr -a hl     "helm list --all-namespaces"
    abbr -a hla    "helm list --all --all-namespaces"
    abbr -a hlf    "helm list --failed --all-namespaces"

    abbr -a hi     "helm install"
    abbr -a hu     "helm upgrade --install"
    abbr -a hur    "helm upgrade --install --reset-values"
    abbr -a hr     "helm uninstall"
    abbr -a hrb    "helm rollback"

    abbr -a hs     "helm search repo"
    abbr -a hsh    "helm search hub"

    abbr -a hrep   "helm repo"
    abbr -a hrepa  "helm repo add"
    abbr -a hrepup "helm repo update"
    abbr -a hrepl  "helm repo list"
    abbr -a hreprm "helm repo remove"

    abbr -a hst    "helm status"
    abbr -a hh     "helm history"
    abbr -a hval   "helm show values"
    abbr -a htemp  "helm template"
    abbr -a hlint  "helm lint"
    abbr -a hdry   "helm upgrade --install --dry-run --debug"
    abbr -a hget   "helm get"
    abbr -a hgetv  "helm get values"
    abbr -a hgeta  "helm get all"

    abbr -a henv   "helm env"
    abbr -a hplug  "helm plugin list"
    abbr -a hcomp  "helm completion fish | source"

    # Helm secrets (if plugin installed)
    abbr -a hsec   "helm secrets"
    abbr -a hsecd  "helm secrets decrypt"
    abbr -a hsece  "helm secrets encrypt"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖥️  K9S — Kubernetes TUI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq k9s
    abbr -a k9     "k9s"
    abbr -a k9ns   "k9s --namespace"
    abbr -a k9ctx  "k9s --context"
    abbr -a k9all  "k9s --all-namespaces"
    abbr -a k9ro   "k9s --readonly"
    abbr -a k9log  "k9s --logLevel=debug"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 MINIKUBE / KIND — Local Kubernetes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq minikube
    abbr -a mk     "minikube"
    abbr -a mkst   "minikube start"
    abbr -a mksp   "minikube stop"
    abbr -a mkdel  "minikube delete"
    abbr -a mkstat "minikube status"
    abbr -a mkssh  "minikube ssh"
    abbr -a mkdash "minikube dashboard"
    abbr -a mkimg  "minikube image load"
    abbr -a mkip   "minikube ip"
    abbr -a mklog  "minikube logs --follow"
    abbr -a mkaddon "minikube addons"
    abbr -a mktunnel "minikube tunnel"
    abbr -a mkdocker "eval (minikube docker-env)"
end

if command -sq kind
    abbr -a kd     "kind"
    abbr -a kdcr   "kind create cluster"
    abbr -a kddel  "kind delete cluster"
    abbr -a kdls   "kind get clusters"
    abbr -a kdload "kind load docker-image"
    abbr -a kdkube "kind get kubeconfig"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 REGISTRY — Authentication
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a dlogin   "docker login"
abbr -a dlogout  "docker logout"
abbr -a dlogingh "docker login ghcr.io"
abbr -a dlogindh "docker login"
abbr -a dlogingcr "docker login gcr.io"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛠️  CONTAINER TOOLS — lazydocker, ctop, dive
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq lazydocker && abbr -a lzd   "lazydocker"
command -sq ctop       && abbr -a ctop  "ctop"
command -sq dive       && abbr -a dive  "dive"
command -sq hadolint   && abbr -a dlint "hadolint"
command -sq trivy      && begin
    abbr -a trivy  "trivy"
    abbr -a trivyi "trivy image"
    abbr -a trivyfs "trivy filesystem ."
    abbr -a trivyr "trivy repo"
end
command -sq skopeo     && begin
    abbr -a sk     "skopeo"
    abbr -a skinsp "skopeo inspect docker://"
    abbr -a skcopy "skopeo copy"
end