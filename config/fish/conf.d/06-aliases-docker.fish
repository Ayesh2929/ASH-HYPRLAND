#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗     █████╗ ██╗               ║
# ║  ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗   ██╔══██╗██║               ║
# ║  ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝   ███████║██║               ║
# ║  ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗   ██╔══██║██║               ║
# ║  ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║   ██║  ██║███████╗          ║
# ║  ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝  ╚═╝╚══════╝          ║
# ║                                                                                  ║
# ║   🐳 DOCKER & CONTAINER ALIASES — ASH Dotfiles v5.0 OMEGA                      ║
# ║   Docker • Compose • Podman • Kubernetes • Registry • Cleanup                   ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_aliases_docker_initialized && exit 0
set -g __ash_aliases_docker_initialized 1

# Skip entirely if neither docker nor podman installed
command -sq docker || command -sq podman || exit 0

# ── Runtime detection ─────────────────────────────────────────────────────────
# Prefer docker; fall back to podman (compatible CLI)
set -g __ash_container_runtime docker
command -sq docker || set -g __ash_container_runtime podman

# Podman Docker compatibility alias
if not command -sq docker && command -sq podman
    alias docker "podman"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐳 DOCKER CORE — Container lifecycle
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias d        "docker"

# ── Containers ────────────────────────────────────────────────────────────────
alias dps      "docker ps \
                  --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
alias dpsa     "docker ps \
                  --all \
                  --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}'"
alias dpsl     "docker ps \
                  --latest"                         # Most recent container

alias drun     "docker run \
                  --interactive \
                  --tty \
                  --rm"                             # Ephemeral interactive run
alias drund    "docker run \
                  --detach"                         # Run in background
alias drunp    "docker run \
                  --interactive \
                  --tty \
                  --rm \
                  --publish"                        # Run with port binding
alias drunv    "docker run \
                  --interactive \
                  --tty \
                  --rm \
                  --volume"                         # Run with volume mount

alias dex      "docker exec \
                  --interactive \
                  --tty"                            # Execute in running container
alias dexr     "docker exec \
                  --interactive \
                  --tty \
                  --user=root"                      # Execute as root
alias dexsh    "docker exec \
                  --interactive \
                  --tty \
                  -- sh"                            # Shell in container (sh)
alias dexbash  "docker exec \
                  --interactive \
                  --tty \
                  -- bash"                          # Shell (bash)
alias dexfish  "docker exec \
                  --interactive \
                  --tty \
                  -- fish"                          # Shell (fish)

alias dstart   "docker start"
alias dstop    "docker stop"
alias drestart "docker restart"
alias dpause   "docker pause"
alias dunpause "docker unpause"
alias dkill    "docker kill"
alias drm      "docker rm"
alias drmf     "docker rm \
                  --force"                          # Force remove running container
alias datt     "docker attach"

# ── Container inspection ──────────────────────────────────────────────────────
alias dinsp    "docker inspect"
alias dlogs    "docker logs \
                  --follow \
                  --timestamps"
alias dlogst   "docker logs \
                  --follow \
                  --timestamps \
                  --tail=100"
alias dtop     "docker top"
alias dstats   "docker stats \
                  --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}'"
alias dstatsf  "docker stats"                       # All containers stats
alias dport    "docker port"
alias ddiff    "docker diff"                        # Filesystem changes
alias dcp      "docker cp"                          # Copy files to/from container
alias drename  "docker rename"
alias dwait    "docker wait"                        # Wait for container to stop


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖼️  IMAGES — Build, pull, push, manage
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dim      "docker images \
                  --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}'"
alias dima     "docker images \
                  --all"
alias dimd     "docker images \
                  --filter=dangling=true"           # Dangling (untagged) images

alias dbuild   "docker build \
                  --progress=plain"
alias dbuildx  "docker buildx build \
                  --progress=plain"
alias dbuildnc "docker build \
                  --no-cache \
                  --progress=plain"                 # No cache build

alias dpull    "docker pull"
alias dpush    "docker push"
alias dtag     "docker tag"
alias drmi     "docker rmi"
alias drmid    "docker rmi \
                  (docker images --filter=dangling=true -q) 2>/dev/null"  # Remove dangling
alias dsave    "docker save \
                  --output"                         # Export image: dsave img.tar IMAGE
alias dload    "docker load \
                  --input"                          # Import image: dload img.tar
alias dexport  "docker export \
                  --output"                         # Export container fs
alias dhist    "docker history"                     # Image layer history
alias dmanifest "docker manifest inspect"           # Image manifest
alias dsearch  "docker search \
                  --format 'table {{.Name}}\t{{.Description}}\t{{.Stars}}\t{{.IsOfficial}}'"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🗄️  VOLUMES — Persistent data management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dvl      "docker volume ls"
alias dvc      "docker volume create"
alias dvi      "docker volume inspect"
alias dvrm     "docker volume rm"
alias dvprune  "docker volume prune \
                  --filter label!=keep"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 NETWORKS — Docker networking
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dnl      "docker network ls"
alias dnc      "docker network create"
alias dni      "docker network inspect"
alias dnrm     "docker network rm"
alias dncon    "docker network connect"
alias dndis    "docker network disconnect"
alias dnprune  "docker network prune"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎼 DOCKER COMPOSE — Multi-container orchestration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dc       "docker compose"

# ── Lifecycle ─────────────────────────────────────────────────────────────────
alias dcu      "docker compose up"
alias dcud     "docker compose up \
                  --detach"                         # Start in background
alias dcudb    "docker compose up \
                  --detach \
                  --build"                          # Rebuild + start detached
alias dcub     "docker compose up \
                  --build"                          # Rebuild + start
alias dcd      "docker compose down"
alias dcdv     "docker compose down \
                  --volumes"                        # Down + remove volumes
alias dcdr     "docker compose down \
                  --remove-orphans"                 # Down + remove orphans
alias dcstart  "docker compose start"
alias dcstop   "docker compose stop"
alias dcrestart "docker compose restart"
alias dcpause  "docker compose pause"
alias dcunpause "docker compose unpause"
alias dckill   "docker compose kill"

# ── Build ─────────────────────────────────────────────────────────────────────
alias dcb      "docker compose build"
alias dcbp     "docker compose build \
                  --parallel"                       # Parallel build
alias dcbnc    "docker compose build \
                  --no-cache"                       # No-cache build
alias dcpull   "docker compose pull"

# ── Logs & monitoring ─────────────────────────────────────────────────────────
alias dcl      "docker compose logs \
                  --follow \
                  --timestamps"
alias dclt     "docker compose logs \
                  --follow \
                  --timestamps \
                  --tail=100"
alias dcls     "docker compose ps \
                  --format 'table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
alias dclsa    "docker compose ps \
                  --all"
alias dcstats  "docker compose stats"
alias dctop    "docker compose top"

# ── Execution & debugging ─────────────────────────────────────────────────────
alias dce      "docker compose exec"
alias dcer     "docker compose exec \
                  --user=root"
alias dcrun    "docker compose run \
                  --rm"
alias dcrunr   "docker compose run \
                  --rm \
                  --user=root"

# ── Config & info ─────────────────────────────────────────────────────────────
alias dcconf   "docker compose config"
alias dcconfs  "docker compose config \
                  --services"                       # List service names
alias dcconff  "docker compose config \
                  --format json \
                  | jq"                             # Pretty-print config
alias dcver    "docker compose version"
alias dcport   "docker compose port"
alias dcinsp   "docker compose images"              # Images used by services

# ── Maintenance ───────────────────────────────────────────────────────────────
alias dcclean  "docker compose down \
                  --volumes \
                  --remove-orphans \
                  --rmi local"                      # Full cleanup


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP — Prune dangling/unused resources
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dprune   "docker system prune \
                  --all \
                  --volumes \
                  --force"                          # ⚠️  Full system prune
alias dprunes  "docker system prune \
                  --force"                          # Safe prune (no volumes)
alias dcprune  "docker container prune \
                  --force"                          # Stopped containers
alias diprune  "docker image prune \
                  --all \
                  --force"                          # Unused images
alias dvprune  "docker volume prune \
                  --force"                          # Unused volumes
alias dnprune  "docker network prune \
                  --force"                          # Unused networks
alias dsize    "docker system df \
                  --verbose"                        # Docker disk usage


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 REGISTRY — Authentication & image management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias dlogin   "docker login"
alias dlogout  "docker logout"
alias dlogingh "docker login ghcr.io"               # GitHub Container Registry
alias dlogindh "docker login registry.hub.docker.com" # Docker Hub
alias dlogingcr "docker login gcr.io"               # Google Container Registry
alias dloginecr "aws ecr get-login-password \
                   --region us-east-1 \
                 | docker login \
                   --username AWS \
                   --password-stdin"                # AWS ECR login


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧊 PODMAN — Rootless container extras
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq podman
    alias pod      "podman pod"
    alias podls    "podman pod ls"
    alias podps    "podman pod ps"
    alias podc     "podman pod create"
    alias podrm    "podman pod rm"
    alias podstart "podman pod start"
    alias podstop  "podman pod stop"
    alias podlogs  "podman pod logs \
                      --follow"
    alias podkube  "podman generate kube"            # Generate Kubernetes YAML
    alias podmach  "podman machine"                  # Podman machine (VM) management
    alias podmachi "podman machine init"
    alias podmachs "podman machine start"
    alias podmacht "podman machine stop"
    alias podmachls "podman machine list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ☸️  KUBERNETES — kubectl + helm + k9s
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq kubectl
    alias k        "kubectl"

    # ── Resources ─────────────────────────────────────────────────────────────
    alias kg       "kubectl get"
    alias kga      "kubectl get all \
                      --all-namespaces"
    alias kgp      "kubectl get pods \
                      --all-namespaces \
                      --output=wide"
    alias kgpa     "kubectl get pods \
                      --all-namespaces \
                      --output=wide"
    alias kgpw     "kubectl get pods \
                      --watch"
    alias kgs      "kubectl get services \
                      --all-namespaces"
    alias kgd      "kubectl get deployments \
                      --all-namespaces"
    alias kgn      "kubectl get nodes \
                      --output=wide"
    alias kgns     "kubectl get namespaces"
    alias kgcm     "kubectl get configmaps"
    alias kgsec    "kubectl get secrets"
    alias kging    "kubectl get ingress \
                      --all-namespaces"
    alias kgpvc    "kubectl get persistentvolumeclaims \
                      --all-namespaces"
    alias kgpv     "kubectl get persistentvolumes"
    alias kgcj     "kubectl get cronjobs \
                      --all-namespaces"
    alias kgj      "kubectl get jobs \
                      --all-namespaces"
    alias kgst     "kubectl get statefulsets \
                      --all-namespaces"
    alias kgds     "kubectl get daemonsets \
                      --all-namespaces"
    alias kghpa    "kubectl get hpa \
                      --all-namespaces"

    # ── Describe ──────────────────────────────────────────────────────────────
    alias kd       "kubectl describe"
    alias kdp      "kubectl describe pod"
    alias kdn      "kubectl describe node"
    alias kds      "kubectl describe service"
    alias kdd      "kubectl describe deployment"

    # ── Logs ──────────────────────────────────────────────────────────────────
    alias kl       "kubectl logs \
                      --follow \
                      --timestamps"
    alias klt      "kubectl logs \
                      --follow \
                      --timestamps \
                      --tail=100"
    alias klp      "kubectl logs \
                      --follow \
                      --timestamps \
                      --previous"                   # Previous container logs
    alias kla      "kubectl logs \
                      --follow \
                      --timestamps \
                      --all-containers"             # All containers in pod

    # ── Execute ───────────────────────────────────────────────────────────────
    alias ke       "kubectl exec \
                      --stdin \
                      --tty"
    alias kesh     "kubectl exec \
                      --stdin \
                      --tty \
                      -- sh"
    alias kebash   "kubectl exec \
                      --stdin \
                      --tty \
                      -- bash"

    # ── Apply & Delete ────────────────────────────────────────────────────────
    alias ka       "kubectl apply \
                      --filename"
    alias kar      "kubectl apply \
                      --recursive \
                      --filename"
    alias kak      "kubectl apply \
                      --kustomize"
    alias kdel     "kubectl delete"
    alias kdelf    "kubectl delete \
                      --filename"
    alias kdelp    "kubectl delete pod \
                      --grace-period=0 \
                      --force"                      # Force delete stuck pod

    # ── Context & namespace ───────────────────────────────────────────────────
    alias kctx     "kubectl config use-context"
    alias kctxl    "kubectl config get-contexts"
    alias kctxc    "kubectl config current-context"
    alias kns      "kubectl config set-context \
                      --current \
                      --namespace"                  # Switch namespace
    alias knsl     "kubectl get namespaces"

    # Shortcuts with kubectx/kubens if installed
    command -sq kubectx && alias kctx "kubectx"
    command -sq kubens  && alias kns  "kubens"

    # ── Scale & rollout ───────────────────────────────────────────────────────
    alias kscale   "kubectl scale"
    alias kroll    "kubectl rollout"
    alias krollst  "kubectl rollout status"
    alias krollh   "kubectl rollout history"
    alias krollu   "kubectl rollout undo"           # Rollback deployment
    alias krollr   "kubectl rollout restart"        # Rolling restart

    # ── Port forward ──────────────────────────────────────────────────────────
    alias kpf      "kubectl port-forward"

    # ── Config maps & secrets ─────────────────────────────────────────────────
    alias kcreate  "kubectl create"
    alias kpatch   "kubectl patch"
    alias klabel   "kubectl label"
    alias kanno    "kubectl annotate"

    # ── Cluster info ─────────────────────────────────────────────────────────
    alias kinfo    "kubectl cluster-info"
    alias kver     "kubectl version"
    alias ktop     "kubectl top"
    alias ktopp    "kubectl top pods \
                      --all-namespaces"
    alias ktopm    "kubectl top nodes"

    # ── Resource usage ────────────────────────────────────────────────────────
    alias kres     "kubectl api-resources \
                      --verbs=list \
                      --namespaced"

    # ── Debug ────────────────────────────────────────────────────────────────
    alias kdebug   "kubectl run debug-pod \
                      --image=busybox \
                      --restart=Never \
                      --rm \
                      --stdin \
                      --tty \
                      -- sh"
    alias kdebugn  "kubectl debug \
                      --it \
                      --image=busybox"              # Debug node
end

# ── Helm ──────────────────────────────────────────────────────────────────────
if command -sq helm
    alias h        "helm"
    alias hl       "helm list \
                      --all-namespaces"
    alias hi       "helm install"
    alias hu       "helm upgrade \
                      --install"
    alias hr       "helm uninstall"
    alias hs       "helm search repo"
    alias hsh      "helm search hub"
    alias hrep     "helm repo"
    alias hrepa    "helm repo add"
    alias hrepup   "helm repo update"
    alias hrepl    "helm repo list"
    alias hst      "helm status"
    alias hh       "helm history"
    alias hrb      "helm rollback"
    alias hval     "helm show values"
    alias htemp    "helm template"
    alias hlint    "helm lint"
    alias hdryrun  "helm upgrade \
                      --install \
                      --dry-run \
                      --debug"
end

# ── k9s (Kubernetes TUI) ──────────────────────────────────────────────────────
command -sq k9s && begin
    alias k9      "k9s"
    alias k9ns    "k9s \
                     --namespace"
    alias k9ctx   "k9s \
                     --context"
    alias k9all   "k9s \
                     --all-namespaces"
    alias k9ro    "k9s \
                     --readonly"
end

# lazydocker
command -sq lazydocker \
    && alias lzd "lazydocker"

# ── Cleanup ───────────────────────────────────────────────────────────────────
set -e __ash_container_runtime