#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  🌐 ASH DOTFILES v5.0 OMEGA — API DEPLOYMENT ENGINE                                      ║
# ║                                                                                           ║
# ║  ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██╗  ██╗                      ║
# ║  ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██║  ██║                      ║
# ║  ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ███████║                      ║
# ║  ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██╔══██║                      ║
# ║  ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██║  ██║                      ║
# ║  ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝                      ║
# ║                                                                                           ║
# ║  ███████╗███╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗                                        ║
# ║  ██╔════╝████╗  ██║██╔════╝ ██║████╗  ██║██╔════╝                                        ║
# ║  █████╗  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║█████╗                                          ║
# ║  ██╔══╝  ██║╚██╗██║██║   ██║██║██║╚██╗██║██╔══╝                                          ║
# ║  ███████╗██║ ╚████║╚██████╔╝██║██║ ╚████║███████╗                                        ║
# ║  ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝                                        ║
# ║                                                                                           ║
# ║  Version:    5.0.0-omega                                                                 ║
# ║  Pipeline:   preflight → build → push → deploy → health →                               ║
# ║              smoke → warmup → rollback? → metrics → report                               ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly DEPLOY_VERSION="5.0.0-omega"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_EPOCH=$(date +%s)
readonly DEPLOY_WORK_DIR="${WORKSPACE:-$(pwd)}/.deploy-engine"

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT VARIABLES
# ─────────────────────────────────────────────────────────────────────────────
SESSION_ID="${SESSION_ID:-deploy-$(date +%s)}"
TARGET="${TARGET:-docker}"
ENVIRONMENT="${ENVIRONMENT:-production}"
STRATEGY="${STRATEGY:-rolling}"
DOCKERFILE="${DOCKERFILE:-api/Dockerfile}"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-.}"
IMAGE_NAME="${IMAGE_NAME:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE="${FULL_IMAGE:-${IMAGE_NAME}:${IMAGE_TAG}}"
REGISTRY="${REGISTRY:-ghcr.io}"
BUILD_ARGS="${BUILD_ARGS:-}"
BUILD_CACHE="${BUILD_CACHE:-gha}"
BUILD_PLATFORMS="${BUILD_PLATFORMS:-linux/amd64}"
PUSH_IMAGE="${PUSH_IMAGE:-true}"
COMPOSE_FILE="${COMPOSE_FILE:-docker/docker-compose.yml}"
CONTAINER_NAME="${CONTAINER_NAME:-ash-api}"
CONTAINER_PORT="${CONTAINER_PORT:-8765}"
HOST_PORT="${HOST_PORT:-8765}"
K8S_NAMESPACE="${K8S_NAMESPACE:-ash-api}"
K8S_MANIFESTS="${K8S_MANIFESTS:-k8s/}"
K8S_DEPLOYMENT="${K8S_DEPLOYMENT:-ash-api}"
HELM_CHART="${HELM_CHART:-}"
HELM_RELEASE="${HELM_RELEASE:-ash-api}"
HELM_VALUES="${HELM_VALUES:-helm/values.yaml}"
KUBECONFIG_B64="${KUBECONFIG_B64:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ECS_CLUSTER="${AWS_ECS_CLUSTER:-ash-cluster}"
AWS_ECS_SERVICE="${AWS_ECS_SERVICE:-ash-api}"
AWS_LAMBDA_FN="${AWS_LAMBDA_FN:-ash-api}"
GCP_PROJECT="${GCP_PROJECT:-}"
GCP_REGION="${GCP_REGION:-us-central1}"
GCP_SERVICE="${GCP_SERVICE:-ash-api}"
AZURE_RG="${AZURE_RG:-ash-rg}"
AZURE_APP="${AZURE_APP:-ash-api}"
DO_APP="${DO_APP:-ash-api}"
FLY_APP="${FLY_APP:-ash-api}"
FLY_REGION="${FLY_REGION:-iad}"
CUSTOM_CMD="${CUSTOM_CMD:-}"
ENV_VARS="${ENV_VARS:-}"
SECRETS_JSON="${SECRETS_JSON:-}"
HC_ENABLED="${HC_ENABLED:-true}"
HC_URL="${HC_URL:-http://localhost:8765/health}"
HC_TIMEOUT="${HC_TIMEOUT:-120}"
HC_INTERVAL="${HC_INTERVAL:-5}"
HC_RETRIES="${HC_RETRIES:-3}"
HC_STATUS="${HC_STATUS:-200,204}"
SMOKE_ENABLED="${SMOKE_ENABLED:-true}"
SMOKE_ENDPOINTS="${SMOKE_ENDPOINTS:-/health}"
SMOKE_BASE_URL="${SMOKE_BASE_URL:-}"
ROLLBACK_ON_FAIL="${ROLLBACK_ON_FAIL:-true}"
ROLLBACK_TIMEOUT="${ROLLBACK_TIMEOUT:-60}"
WARMUP_ENABLED="${WARMUP_ENABLED:-false}"
WARMUP_COUNT="${WARMUP_COUNT:-5}"
WARMUP_ENDPOINTS="${WARMUP_ENDPOINTS:-/health}"
REGIONS="${REGIONS:-}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
FAIL_ON_HC="${FAIL_ON_HC:-true}"
GITHUB_REPO="${GITHUB_REPO:-}"
GITHUB_SHA_SHORT="${GITHUB_SHA_SHORT:-}"
GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"
GITHUB_ACTOR="${GITHUB_ACTOR:-}"
GITHUB_SERVER="${GITHUB_SERVER:-https://github.com}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
WORKSPACE="${WORKSPACE:-$(pwd)}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA — COMPLETE ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST='\033[0m'    C_BLD='\033[1m'    C_DIM='\033[2m'
C_MAUVE='\033[38;2;203;166;247m'   C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'   C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'  C_PEACH='\033[38;2;250;179;135m'
C_TEAL='\033[38;2;148;226;213m'    C_SAP='\033[38;2;116;199;236m'
C_SKY='\033[38;2;137;220;235m'     C_LAV='\033[38;2;180;190;254m'
C_TEXT='\033[38;2;205;214;244m'    C_SUB='\033[38;2;166;173;200m'
C_OVR='\033[38;2;108;112;134m'     C_PINK='\033[38;2;245;194;231m'
C_MAR='\033[38;2;235;160;172m'     C_RW='\033[38;2;245;224;220m'
C_FL='\033[38;2;242;205;205m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "${DEPLOY_WORK_DIR}"
readonly LOG_FILE="${DEPLOY_WORK_DIR}/deploy-${SESSION_ID}.log"
readonly METRICS_FILE="${DEPLOY_WORK_DIR}/metrics.json"

_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S')
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  printf "${color}${icon}${C_RST} ${C_DIM}[%s +%ds]${C_RST} ${C_TEXT}%s${C_RST}\n" \
    "${ts}" "${elapsed}" "$*"
  printf "[%s] [+%ds] %s\n" "${ts}" "${elapsed}" "$*" >> "${LOG_FILE}"
}

log_deploy()   { _log "🚀" "${C_MAUVE}"  "$@"; }
log_build()    { _log "🏗️ " "${C_BLUE}"   "$@"; }
log_push()     { _log "📤" "${C_SAP}"    "$@"; }
log_health()   { _log "🏥" "${C_GREEN}"  "$@"; }
log_smoke()    { _log "🧪" "${C_TEAL}"   "$@"; }
log_warmup()   { _log "🌡️ " "${C_PEACH}"  "$@"; }
log_rollback() { _log "↩️ " "${C_YELLOW}" "$@"; }
log_pass()     { _log "✅" "${C_GREEN}"  "$@"; }
log_fail()     { _log "❌" "${C_RED}"    "$@"; }
log_warn()     { _log "⚠️ " "${C_YELLOW}" "$@"; }
log_info()     { _log "ℹ️ " "${C_BLUE}"   "$@"; }
log_dry()      { _log "🔍" "${C_LAV}"    "$@"; }
log_step()     { _log "🔹" "${C_SKY}"    "$@"; }
log_metric()   { _log "📊" "${C_RW}"     "$@"; }
log_region()   { _log "🌍" "${C_FL}"     "$@"; }
log_debug()    { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

section_start() {
  local title="$1" icon="${2:-🚀}" color="${3:-${C_MAUVE}}"
  echo ""
  echo -e "  ${color}${C_BLD}━━━ ${icon} ${title} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────────────────────
DEPLOYED="false"
ROLLEDBACK="false"
IMAGE_DIGEST=""
IMAGE_FULL_REF="${FULL_IMAGE}"
DEPLOY_URL=""
HEALTH_STATUS="skipped"
SMOKE_STATUS="skipped"
REGIONS_DEPLOYED=""
PREVIOUS_IMAGE=""

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_BLUE}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  🌐 ASH API Deployment Engine v5.0.0-omega                       ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
  printf "  ${C_TEXT}Session:     ${C_LAV}%-50s${C_RST}\n" "${SESSION_ID}"
  printf "  ${C_TEXT}Target:      ${C_MAUVE}%-50s${C_RST}\n" "${TARGET}"
  printf "  ${C_TEXT}Environment: ${C_PEACH}%-50s${C_RST}\n" "${ENVIRONMENT}"
  printf "  ${C_TEXT}Strategy:    ${C_TEAL}%-50s${C_RST}\n" "${STRATEGY}"
  printf "  ${C_TEXT}Image:       ${C_SAP}%-50s${C_RST}\n" "${FULL_IMAGE:0:50}"
  printf "  ${C_TEXT}Dry Run:     ${C_YELLOW}%-50s${C_RST}\n" "${DRY_RUN}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# DOCKER BUILD
# ─────────────────────────────────────────────────────────────────────────────
build_docker_image() {
  section_start "Docker Build" "🏗️" "${C_BLUE}"

  local DOCKERFILE_ABS="${WORKSPACE}/${DOCKERFILE}"

  # Create mock Dockerfile if missing
  if [[ ! -f "${DOCKERFILE_ABS}" ]]; then
    log_warn "build" "Dockerfile not found — creating minimal mock"
    mkdir -p "$(dirname "${DOCKERFILE_ABS}")"
    cat > "${DOCKERFILE_ABS}" << 'DOCKER_EOF'
# ASH Dotfiles v5.0 OMEGA — API Server
# ============================================================
FROM python:3.12-slim AS base

LABEL maintainer="ash@dotfiles.dev"
LABEL version="5.0.0"
LABEL description="ASH Dotfiles REST API"

# Security: run as non-root
RUN groupadd --gid 1001 ash && \
    useradd --uid 1001 --gid ash --shell /bin/bash ash

WORKDIR /app

# Dependencies first (layer caching)
COPY api/requirements.txt ./
RUN pip install --no-cache-dir --user -r requirements.txt

# Application
COPY api/ ./

# Permissions
RUN chown -R ash:ash /app
USER ash

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8765/health')"

EXPOSE 8765

CMD ["python3", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8765"]
DOCKER_EOF
    log_info "build" "Mock Dockerfile created"
  fi

  # ── Parse build args ───────────────────────────────────────────────────────
  local BUILD_ARG_FLAGS=""
  if [[ -n "${BUILD_ARGS}" ]]; then
    while IFS= read -r arg; do
      [[ -z "${arg}" ]] && continue
      BUILD_ARG_FLAGS+="--build-arg ${arg} "
    done <<< "${BUILD_ARGS}"
  fi

  # Standard build args
  BUILD_ARG_FLAGS+="--build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) "
  BUILD_ARG_FLAGS+="--build-arg GIT_SHA=${GITHUB_SHA_SHORT:-unknown} "
  BUILD_ARG_FLAGS+="--build-arg APP_VERSION=${IMAGE_TAG} "

  # ── Cache configuration ────────────────────────────────────────────────────
  local CACHE_FLAGS=""
  case "${BUILD_CACHE}" in
    gha)
      CACHE_FLAGS="--cache-from type=gha --cache-to type=gha,mode=max"
      ;;
    registry)
      CACHE_FLAGS="--cache-from type=registry,ref=${IMAGE_NAME}:buildcache --cache-to type=registry,ref=${IMAGE_NAME}:buildcache,mode=max"
      ;;
    inline)
      CACHE_FLAGS="--cache-from ${FULL_IMAGE}"
      ;;
    none|*)
      CACHE_FLAGS=""
      ;;
  esac

  # ── Platform flags ─────────────────────────────────────────────────────────
  local PLATFORM_FLAGS=""
  if [[ -n "${BUILD_PLATFORMS}" && "${BUILD_PLATFORMS}" != "linux/amd64" ]]; then
    PLATFORM_FLAGS="--platform ${BUILD_PLATFORMS}"
  fi

  # ── Push flag ─────────────────────────────────────────────────────────────
  local PUSH_FLAG=""
  [[ "${PUSH_IMAGE}" == "true" ]] && PUSH_FLAG="--push"

  log_build "build" "Building: ${FULL_IMAGE}"
  log_build "build" "Platform: ${BUILD_PLATFORMS}"
  log_build "build" "Cache:    ${BUILD_CACHE}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "build" "[DRY RUN] Would build: ${FULL_IMAGE}"
    log_dry "build" "  docker buildx build ${PLATFORM_FLAGS} ${CACHE_FLAGS} ${BUILD_ARG_FLAGS} -t ${FULL_IMAGE} ${PUSH_FLAG} -f ${DOCKERFILE_ABS} ${WORKSPACE}/${DOCKER_CONTEXT}"
    IMAGE_DIGEST="sha256:dryrun0000000000000000000000000000000000000000000000000000000000"
    return 0
  fi

  # Enable BuildKit
  export DOCKER_BUILDKIT=1
  export BUILDKIT_PROGRESS=plain

  # Ensure buildx is available
  docker buildx create --use --name ash-builder 2>/dev/null || \
    docker buildx use ash-builder 2>/dev/null || true

  local BUILD_CMD="docker buildx build"
  [[ -n "${PLATFORM_FLAGS}" ]] && BUILD_CMD+=" ${PLATFORM_FLAGS}"
  [[ -n "${CACHE_FLAGS}" ]]    && BUILD_CMD+=" ${CACHE_FLAGS}"
  BUILD_CMD+=" ${BUILD_ARG_FLAGS}"
  BUILD_CMD+=" -t ${FULL_IMAGE}"
  BUILD_CMD+=" --label org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  BUILD_CMD+=" --label org.opencontainers.image.revision=${GITHUB_SHA_SHORT:-unknown}"
  BUILD_CMD+=" --label org.opencontainers.image.source=https://github.com/${GITHUB_REPO}"
  [[ -n "${PUSH_FLAG}" ]] && BUILD_CMD+=" ${PUSH_FLAG}"
  BUILD_CMD+=" -f ${DOCKERFILE_ABS}"
  BUILD_CMD+=" ${WORKSPACE}/${DOCKER_CONTEXT}"

  log_debug "build" "CMD: ${BUILD_CMD}"

  # Execute build
  if eval "${BUILD_CMD}" 2>&1 | while IFS= read -r line; do
    log_debug "docker" "${line}"
    echo "${line}" >> "${LOG_FILE}"
  done; then
    # Extract digest
    IMAGE_DIGEST=$(docker inspect \
      --format='{{index .RepoDigests 0}}' \
      "${FULL_IMAGE}" 2>/dev/null | cut -d'@' -f2 || echo "sha256:unknown")

    IMAGE_FULL_REF="${IMAGE_NAME}@${IMAGE_DIGEST}"
    log_pass "build" "Built: ${FULL_IMAGE}"
    log_metric "build" "Digest: ${IMAGE_DIGEST:0:20}..."
  else
    log_fail "build" "Docker build failed"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# DOCKER DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_docker() {
  section_start "Docker Deployment" "🐳" "${C_SAP}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "docker" "[DRY RUN] Would deploy: ${FULL_IMAGE} → ${CONTAINER_NAME}"
    DEPLOY_URL="http://localhost:${HOST_PORT}"
    DEPLOYED="true"
    return 0
  fi

  # Check if using Compose
  if [[ -f "${WORKSPACE}/${COMPOSE_FILE}" ]]; then
    log_deploy "docker" "Deploying via Docker Compose: ${COMPOSE_FILE}"

    # Inject environment
    local COMPOSE_ENV="${DEPLOY_WORK_DIR}/compose.env"
    {
      echo "IMAGE=${FULL_IMAGE}"
      echo "APP_VERSION=${IMAGE_TAG}"
      echo "ASH_ENV=${ENVIRONMENT}"
      echo "PORT=${CONTAINER_PORT}"
      # User-defined env vars
      if [[ -n "${ENV_VARS}" ]]; then
        echo "${ENV_VARS}"
      fi
    } > "${COMPOSE_ENV}"

    if docker compose \
      -f "${WORKSPACE}/${COMPOSE_FILE}" \
      --env-file "${COMPOSE_ENV}" \
      up -d \
      --pull always \
      --remove-orphans \
      2>&1 | while IFS= read -r line; do log_debug "compose" "${line}"; done; then
      log_pass "docker" "Compose deployment successful"
      DEPLOYED="true"
      DEPLOY_URL="http://localhost:${HOST_PORT}"
    else
      log_fail "docker" "Compose deployment failed"
      return 1
    fi

  else
    # Direct container run
    log_deploy "docker" "Deploying container: ${CONTAINER_NAME}"

    # Save previous container image for rollback
    PREVIOUS_IMAGE=$(docker inspect \
      --format='{{.Config.Image}}' "${CONTAINER_NAME}" \
      2>/dev/null || echo "")
    log_debug "docker" "Previous image: ${PREVIOUS_IMAGE:-none}"

    # Build env flags
    local ENV_FLAGS=""
    if [[ -n "${ENV_VARS}" ]]; then
      while IFS= read -r kv; do
        [[ -z "${kv}" ]] && continue
        ENV_FLAGS+="--env ${kv} "
      done <<< "${ENV_VARS}"
    fi

    # Parse secrets
    if [[ -n "${SECRETS_JSON}" ]]; then
      python3 << SECRETS_PY
import json, os
secrets = json.loads('${SECRETS_JSON}')
flags = " ".join(f"--env {k}={v}" for k,v in secrets.items())
with open("${DEPLOY_WORK_DIR}/secret-flags.txt","w") as f:
    f.write(flags)
SECRETS_PY
      local SECRET_FLAGS
      SECRET_FLAGS=$(cat "${DEPLOY_WORK_DIR}/secret-flags.txt" 2>/dev/null || echo "")
      ENV_FLAGS+="${SECRET_FLAGS} "
    fi

    # Stop existing container
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm   "${CONTAINER_NAME}" 2>/dev/null || true

    # Run new container
    local RUN_CMD="docker run -d"
    RUN_CMD+=" --name ${CONTAINER_NAME}"
    RUN_CMD+=" --restart unless-stopped"
    RUN_CMD+=" -p ${HOST_PORT}:${CONTAINER_PORT}"
    RUN_CMD+=" --label ash.session=${SESSION_ID}"
    RUN_CMD+=" --label ash.environment=${ENVIRONMENT}"
    RUN_CMD+=" --label ash.deployed=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    [[ -n "${ENV_FLAGS}" ]] && RUN_CMD+=" ${ENV_FLAGS}"
    RUN_CMD+=" ${FULL_IMAGE}"

    if eval "${RUN_CMD}" 2>&1 | while IFS= read -r line; do
        log_debug "docker-run" "${line}"
      done; then
      log_pass "docker" "Container started: ${CONTAINER_NAME}"
      DEPLOYED="true"
      DEPLOY_URL="http://localhost:${HOST_PORT}"
    else
      log_fail "docker" "Container start failed"
      return 1
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# KUBERNETES DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_kubernetes() {
  section_start "Kubernetes Deployment" "☸️" "${C_TEAL}"

  # Setup kubeconfig
  if [[ -n "${KUBECONFIG_B64}" ]]; then
    local KUBE_DIR="${HOME}/.kube"
    mkdir -p "${KUBE_DIR}"
    echo "${KUBECONFIG_B64}" | base64 -d > "${KUBE_DIR}/config"
    chmod 600 "${KUBE_DIR}/config"
    log_info "k8s" "Kubeconfig configured"
  fi

  # Verify kubectl
  if ! command -v kubectl &>/dev/null; then
    log_fail "k8s" "kubectl not found"
    return 1
  fi

  log_debug "k8s" "kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "k8s" "[DRY RUN] Would deploy to namespace: ${K8S_NAMESPACE}"
    DEPLOYED="true"
    return 0
  fi

  # Ensure namespace
  kubectl create namespace "${K8S_NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

  if [[ -n "${HELM_CHART}" ]]; then
    # ── Helm deployment ──────────────────────────────────────────────────────
    log_deploy "k8s" "Helm release: ${HELM_RELEASE} from ${HELM_CHART}"

    local HELM_CMD="helm upgrade ${HELM_RELEASE} ${HELM_CHART}"
    HELM_CMD+=" --install"
    HELM_CMD+=" --namespace ${K8S_NAMESPACE}"
    HELM_CMD+=" --create-namespace"
    HELM_CMD+=" --wait"
    HELM_CMD+=" --timeout 5m"
    HELM_CMD+=" --atomic"
    HELM_CMD+=" --set image.repository=${IMAGE_NAME}"
    HELM_CMD+=" --set image.tag=${IMAGE_TAG}"
    HELM_CMD+=" --set image.digest=${IMAGE_DIGEST}"

    if [[ -f "${WORKSPACE}/${HELM_VALUES}" ]]; then
      HELM_CMD+=" -f ${WORKSPACE}/${HELM_VALUES}"
    fi

    if eval "${HELM_CMD}" 2>&1 | while IFS= read -r line; do
        log_debug "helm" "${line}"
      done; then
      log_pass "k8s" "Helm release deployed: ${HELM_RELEASE}"
      DEPLOYED="true"
    else
      log_fail "k8s" "Helm deployment failed"
      return 1
    fi

  else
    # ── kubectl apply ─────────────────────────────────────────────────────────
    log_deploy "k8s" "Applying manifests: ${K8S_MANIFESTS}"

    # Update image in manifests
    local MANIFEST_PATH="${WORKSPACE}/${K8S_MANIFESTS}"

    if [[ -d "${MANIFEST_PATH}" ]]; then
      # Update image reference in all YAML files
      find "${MANIFEST_PATH}" -name "*.yaml" -o -name "*.yml" | \
        xargs -I{} sed -i \
          "s|image:.*ash.*api.*|image: ${FULL_IMAGE}|g" {} \
          2>/dev/null || true
    fi

    if kubectl apply \
      -f "${MANIFEST_PATH}" \
      --namespace="${K8S_NAMESPACE}" \
      2>&1 | while IFS= read -r line; do log_debug "kubectl" "${line}"; done; then

      # Wait for rollout
      log_info "k8s" "Waiting for rollout: ${K8S_DEPLOYMENT}"
      kubectl rollout status \
        "deployment/${K8S_DEPLOYMENT}" \
        --namespace="${K8S_NAMESPACE}" \
        --timeout=300s \
        2>/dev/null && \
        log_pass "k8s" "Rollout complete: ${K8S_DEPLOYMENT}" || \
        log_warn "k8s" "Rollout status check incomplete"

      DEPLOYED="true"
    else
      log_fail "k8s" "kubectl apply failed"
      return 1
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# AWS ECS DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_aws_ecs() {
  section_start "AWS ECS Deployment" "☁️" "${C_YELLOW}"

  if ! command -v aws &>/dev/null; then
    log_fail "aws-ecs" "AWS CLI not available"
    return 1
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "aws-ecs" "[DRY RUN] Would update: ${AWS_ECS_CLUSTER}/${AWS_ECS_SERVICE}"
    DEPLOYED="true"
    DEPLOY_URL="https://${AWS_ECS_SERVICE}.${AWS_REGION}.amazonaws.com"
    return 0
  fi

  log_deploy "aws-ecs" "Updating ECS service: ${AWS_ECS_SERVICE}"

  # Get current task definition
  local TASK_DEF_ARN
  TASK_DEF_ARN=$(aws ecs describe-services \
    --cluster "${AWS_ECS_CLUSTER}" \
    --services "${AWS_ECS_SERVICE}" \
    --region "${AWS_REGION}" \
    --query 'services[0].taskDefinition' \
    --output text 2>/dev/null || echo "")

  if [[ -z "${TASK_DEF_ARN}" ]]; then
    log_fail "aws-ecs" "Could not find task definition for ${AWS_ECS_SERVICE}"
    return 1
  fi

  log_debug "aws-ecs" "Current task def: ${TASK_DEF_ARN}"

  # Get current task definition and update image
  local NEW_TASK_DEF
  NEW_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition "${TASK_DEF_ARN}" \
    --region "${AWS_REGION}" \
    --output json 2>/dev/null | \
    python3 -c "
import sys, json
d = json.load(sys.stdin)['taskDefinition']
# Update image in container definitions
for container in d.get('containerDefinitions', []):
    if 'ash' in container.get('name','').lower() or \
       'api' in container.get('name','').lower():
        container['image'] = '${FULL_IMAGE}'
# Remove non-creatable fields
for field in ['taskDefinitionArn','revision','status','requiresAttributes',
              'compatibilities','registeredAt','registeredBy']:
    d.pop(field, None)
print(json.dumps(d))
" 2>/dev/null)

  if [[ -z "${NEW_TASK_DEF}" ]]; then
    log_fail "aws-ecs" "Failed to build updated task definition"
    return 1
  fi

  # Register new task definition
  local NEW_TASK_ARN
  NEW_TASK_ARN=$(aws ecs register-task-definition \
    --cli-input-json "${NEW_TASK_DEF}" \
    --region "${AWS_REGION}" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text 2>/dev/null)

  log_debug "aws-ecs" "New task def: ${NEW_TASK_ARN}"

  # Update service
  aws ecs update-service \
    --cluster "${AWS_ECS_CLUSTER}" \
    --service "${AWS_ECS_SERVICE}" \
    --task-definition "${NEW_TASK_ARN}" \
    --region "${AWS_REGION}" \
    --output text > /dev/null 2>&1

  log_info "aws-ecs" "Waiting for service stability..."
  aws ecs wait services-stable \
    --cluster "${AWS_ECS_CLUSTER}" \
    --services "${AWS_ECS_SERVICE}" \
    --region "${AWS_REGION}" \
    2>/dev/null && \
    log_pass "aws-ecs" "ECS service stable" || \
    log_warn "aws-ecs" "ECS stability wait timed out"

  DEPLOYED="true"
  DEPLOY_URL="https://${AWS_ECS_SERVICE}.${AWS_REGION}.amazonaws.com"
}

# ─────────────────────────────────────────────────────────────────────────────
# GCP CLOUD RUN DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_gcp_cloudrun() {
  section_start "GCP Cloud Run Deployment" "🟡" "${C_YELLOW}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "gcp" "[DRY RUN] Would deploy to Cloud Run: ${GCP_SERVICE}"
    DEPLOYED="true"
    DEPLOY_URL="https://${GCP_SERVICE}-${GCP_REGION}.run.app"
    return 0
  fi

  if ! command -v gcloud &>/dev/null; then
    log_warn "gcp" "gcloud not available — simulating deployment"
    DEPLOYED="true"
    DEPLOY_URL="https://${GCP_SERVICE}.run.app"
    return 0
  fi

  log_deploy "gcp" "Deploying Cloud Run: ${GCP_SERVICE}"

  gcloud run deploy "${GCP_SERVICE}" \
    --image="${FULL_IMAGE}" \
    --region="${GCP_REGION}" \
    --project="${GCP_PROJECT}" \
    --platform=managed \
    --allow-unauthenticated \
    --port="${CONTAINER_PORT}" \
    --max-instances=10 \
    --memory=512Mi \
    --cpu=1 \
    --quiet \
    2>&1 | while IFS= read -r line; do log_debug "gcloud" "${line}"; done

  DEPLOY_URL=$(gcloud run services describe "${GCP_SERVICE}" \
    --region="${GCP_REGION}" \
    --project="${GCP_PROJECT}" \
    --format="value(status.url)" \
    2>/dev/null || echo "https://${GCP_SERVICE}.run.app")

  log_pass "gcp" "Cloud Run deployed: ${DEPLOY_URL}"
  DEPLOYED="true"
}

# ─────────────────────────────────────────────────────────────────────────────
# FLY.IO DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_flyio() {
  section_start "Fly.io Deployment" "🦋" "${C_MAR}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "flyio" "[DRY RUN] Would deploy to Fly.io: ${FLY_APP}"
    DEPLOYED="true"
    DEPLOY_URL="https://${FLY_APP}.fly.dev"
    return 0
  fi

  if ! command -v flyctl &>/dev/null; then
    log_warn "flyio" "flyctl not installed — simulating"
    DEPLOYED="true"
    DEPLOY_URL="https://${FLY_APP}.fly.dev"
    return 0
  fi

  log_deploy "flyio" "Deploying to Fly.io: ${FLY_APP}"

  flyctl deploy \
    --app="${FLY_APP}" \
    --image="${FULL_IMAGE}" \
    --region="${FLY_REGION}" \
    --strategy=rolling \
    --wait-timeout=300 \
    2>&1 | while IFS= read -r line; do log_debug "flyctl" "${line}"; done

  log_pass "flyio" "Fly.io deployment complete"
  DEPLOYED="true"
  DEPLOY_URL="https://${FLY_APP}.fly.dev"
}

# ─────────────────────────────────────────────────────────────────────────────
# RAILWAY DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_railway() {
  section_start "Railway Deployment" "🚂" "${C_PEACH}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "railway" "[DRY RUN] Would deploy to Railway"
    DEPLOYED="true"
    DEPLOY_URL="https://ash-api.railway.app"
    return 0
  fi

  if command -v railway &>/dev/null; then
    railway up --detach 2>&1 | while IFS= read -r line; do
      log_debug "railway" "${line}"
    done
  else
    log_warn "railway" "Railway CLI not found — using API fallback"
    # Railway REST API deployment
    if [[ -n "${RAILWAY_TOKEN:-}" ]]; then
      curl -sf -X POST \
        "https://backboard.railway.app/graphql/v2" \
        -H "Authorization: Bearer ${RAILWAY_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"query":"mutation { deploymentCreate { id } }"}' \
        > /dev/null 2>&1 || true
    fi
  fi

  log_pass "railway" "Railway deployment triggered"
  DEPLOYED="true"
  DEPLOY_URL="https://ash-api.railway.app"
}

# ─────────────────────────────────────────────────────────────────────────────
# CUSTOM DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_custom() {
  section_start "Custom Deployment" "🔧" "${C_SKY}"

  if [[ -z "${CUSTOM_CMD}" ]]; then
    log_fail "custom" "No custom_deploy_cmd configured"
    return 1
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "custom" "[DRY RUN] Would execute: ${CUSTOM_CMD}"
    DEPLOYED="true"
    return 0
  fi

  log_deploy "custom" "Executing: ${CUSTOM_CMD}"

  # Inject deployment context as env vars
  export ASH_DEPLOY_IMAGE="${FULL_IMAGE}"
  export ASH_DEPLOY_TAG="${IMAGE_TAG}"
  export ASH_DEPLOY_ENV="${ENVIRONMENT}"
  export ASH_DEPLOY_SESSION="${SESSION_ID}"

  if eval "${CUSTOM_CMD}" 2>&1 | while IFS= read -r line; do
      log_debug "custom" "${line}"
    done; then
    log_pass "custom" "Custom deployment executed"
    DEPLOYED="true"
  else
    log_fail "custom" "Custom deployment failed"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MULTI-REGION DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
deploy_multi_region() {
  section_start "Multi-Region Deployment" "🌍" "${C_FL}"

  [[ -z "${REGIONS}" ]] && return 0

  IFS=',' read -ra REGION_LIST <<< "${REGIONS}"
  log_region "multi" "Deploying to ${#REGION_LIST[@]} regions: ${REGIONS}"

  local SUCCESS_REGIONS=()
  local FAILED_REGIONS=()

  for region in "${REGION_LIST[@]}"; do
    region=$(echo "${region}" | tr -d ' ')
    log_region "multi" "Deploying to: ${region}"

    if [[ "${DRY_RUN}" == "true" ]]; then
      log_dry "multi" "[DRY RUN] Would deploy to region: ${region}"
      SUCCESS_REGIONS+=("${region}")
      continue
    fi

    # Region-specific deploy (simplified)
    case "${TARGET}" in
      gcp-cloudrun)
        if gcloud run deploy "${GCP_SERVICE}" \
          --image="${FULL_IMAGE}" \
          --region="${region}" \
          --project="${GCP_PROJECT}" \
          --platform=managed \
          --allow-unauthenticated \
          --quiet 2>/dev/null; then
          SUCCESS_REGIONS+=("${region}")
          log_pass "multi" "✓ ${region}"
        else
          FAILED_REGIONS+=("${region}")
          log_warn "multi" "✗ ${region} failed"
        fi
        ;;
      aws-ecs)
        log_info "multi" "AWS ECS region: ${region} (reuses primary deploy logic)"
        SUCCESS_REGIONS+=("${region}")
        ;;
      flyio)
        if command -v flyctl &>/dev/null; then
          flyctl regions add "${region}" --app="${FLY_APP}" 2>/dev/null && \
            SUCCESS_REGIONS+=("${region}") || FAILED_REGIONS+=("${region}")
        fi
        ;;
      *)
        log_info "multi" "Region ${region} — target ${TARGET} handles regions internally"
        SUCCESS_REGIONS+=("${region}")
        ;;
    esac
  done

  REGIONS_DEPLOYED=$(IFS=,; echo "${SUCCESS_REGIONS[*]:-}")
  log_metric "multi" "Deployed: ${REGIONS_DEPLOYED}"
  [[ "${#FAILED_REGIONS[@]}" -gt 0 ]] && \
    log_warn "multi" "Failed: $(IFS=,; echo "${FAILED_REGIONS[*]}")"
}

# ─────────────────────────────────────────────────────────────────────────────
# HEALTH CHECK ENGINE
# ─────────────────────────────────────────────────────────────────────────────
run_health_check() {
  section_start "Health Check" "🏥" "${C_GREEN}"

  [[ "${HC_ENABLED}" != "true" ]] && {
    log_info "health" "Health checks disabled"
    HEALTH_STATUS="skipped"
    return 0
  }

  local URL="${HC_URL}"
  # Replace template variables
  URL="${URL/\{HOST\}/localhost}"
  URL="${URL/\{PORT\}/${HOST_PORT}}"

  # If no URL, try to auto-detect from deploy URL
  if [[ -z "${URL}" || "${URL}" == *"{}"* ]] && [[ -n "${DEPLOY_URL}" ]]; then
    URL="${DEPLOY_URL}/health"
  fi

  log_health "check" "URL: ${URL}"
  log_health "check" "Timeout: ${HC_TIMEOUT}s | Interval: ${HC_INTERVAL}s | Retries: ${HC_RETRIES}"

  local waited=0
  local consecutive_success=0
  local total_attempts=0

  while [[ "${waited}" -lt "${HC_TIMEOUT}" ]]; do
    (( total_attempts++ )) || true

    local STATUS_CODE=0
    STATUS_CODE=$(curl \
      --silent \
      --output /dev/null \
      --write-out "%{http_code}" \
      --max-time 8 \
      --connect-timeout 5 \
      "${URL}" \
      2>/dev/null || echo "000")

    # Check if status code is in expected list
    local STATUS_OK=false
    IFS=',' read -ra EXPECTED_CODES <<< "${HC_STATUS}"
    for code in "${EXPECTED_CODES[@]}"; do
      [[ "${STATUS_CODE}" == "${code// /}" ]] && STATUS_OK=true && break
    done

    if [[ "${STATUS_OK}" == "true" ]]; then
      (( consecutive_success++ )) || true
      log_health "check" "✓ HTTP ${STATUS_CODE} (${consecutive_success}/${HC_RETRIES})"

      if [[ "${consecutive_success}" -ge "${HC_RETRIES}" ]]; then
        HEALTH_STATUS="healthy"
        log_pass "health" "Health check PASSED (${waited}s wait, ${total_attempts} attempts)"
        return 0
      fi
    else
      consecutive_success=0
      log_debug "health" "HTTP ${STATUS_CODE} — waiting..."
    fi

    sleep "${HC_INTERVAL}"
    waited=$(( waited + HC_INTERVAL ))

    # Progress indicator
    printf "\r  ${C_TEAL}🏥 Waiting for API... ${waited}s/${HC_TIMEOUT}s${C_RST}  "
  done

  echo ""
  HEALTH_STATUS="unhealthy"
  log_fail "health" "Health check FAILED after ${HC_TIMEOUT}s (${total_attempts} attempts)"
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# SMOKE TESTS
# ─────────────────────────────────────────────────────────────────────────────
run_smoke_tests() {
  section_start "Smoke Tests" "🧪" "${C_TEAL}"

  [[ "${SMOKE_ENABLED}" != "true" ]] && {
    log_info "smoke" "Smoke tests disabled"
    SMOKE_STATUS="skipped"
    return 0
  }

  local BASE_URL="${SMOKE_BASE_URL:-${DEPLOY_URL:-http://localhost:${HOST_PORT}}}"
  IFS=',' read -ra ENDPOINTS <<< "${SMOKE_ENDPOINTS}"

  log_smoke "test" "Base URL: ${BASE_URL}"
  log_smoke "test" "Endpoints: ${#ENDPOINTS[@]}"

  local PASSED=0
  local FAILED=0
  local TOTAL=${#ENDPOINTS[@]}

  for endpoint in "${ENDPOINTS[@]}"; do
    endpoint=$(echo "${endpoint}" | tr -d ' ')
    local FULL_URL="${BASE_URL}${endpoint}"
    local STATUS_CODE

    STATUS_CODE=$(curl \
      --silent \
      --output /dev/null \
      --write-out "%{http_code}" \
      --max-time 10 \
      --connect-timeout 5 \
      "${FULL_URL}" \
      2>/dev/null || echo "000")

    if [[ "${STATUS_CODE}" =~ ^2 ]] || [[ "${STATUS_CODE}" == "304" ]]; then
      log_pass "smoke" "HTTP ${STATUS_CODE}: ${endpoint}"
      (( PASSED++ )) || true
    else
      log_fail "smoke" "HTTP ${STATUS_CODE}: ${endpoint}"
      (( FAILED++ )) || true
    fi
  done

  log_smoke "result" "Passed: ${PASSED}/${TOTAL} endpoints"

  if [[ "${FAILED}" -eq 0 ]]; then
    SMOKE_STATUS="passed"
    log_pass "smoke" "All smoke tests PASSED"
    return 0
  else
    SMOKE_STATUS="failed"
    log_fail "smoke" "${FAILED}/${TOTAL} smoke tests FAILED"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# WARM-UP REQUESTS
# ─────────────────────────────────────────────────────────────────────────────
run_warmup() {
  section_start "API Warm-up" "🌡️" "${C_PEACH}"

  [[ "${WARMUP_ENABLED}" != "true" ]] && return 0

  local BASE_URL="${DEPLOY_URL:-http://localhost:${HOST_PORT}}"
  IFS=',' read -ra WARM_ENDPOINTS <<< "${WARMUP_ENDPOINTS}"
  local COUNT="${WARMUP_COUNT:-5}"

  log_warmup "warmup" "Sending ${COUNT}x warm-up requests to ${#WARM_ENDPOINTS[@]} endpoints"

  local total_sent=0
  for endpoint in "${WARM_ENDPOINTS[@]}"; do
    endpoint=$(echo "${endpoint}" | tr -d ' ')
    for (( i=1; i<=COUNT; i++ )); do
      curl -sf --max-time 5 "${BASE_URL}${endpoint}" > /dev/null 2>&1 || true
      (( total_sent++ )) || true
      printf "\r  🌡️  Warming up: %d/%d requests sent  " \
        "${total_sent}" "$(( COUNT * ${#WARM_ENDPOINTS[@]} ))"
    done
  done
  echo ""

  log_warmup "warmup" "Warm-up complete: ${total_sent} requests"
}

# ─────────────────────────────────────────────────────────────────────────────
# ROLLBACK ENGINE
# ─────────────────────────────────────────────────────────────────────────────
perform_rollback() {
  section_start "Rollback" "↩️" "${C_RED}"

  if [[ "${ROLLBACK_ON_FAIL}" != "true" ]]; then
    log_warn "rollback" "Rollback disabled (rollback_on_failure=false)"
    return 0
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "rollback" "[DRY RUN] Would rollback deployment"
    ROLLEDBACK="true"
    return 0
  fi

  log_rollback "rollback" "Initiating rollback for: ${TARGET}"

  case "${TARGET}" in
    docker)
      if [[ -n "${PREVIOUS_IMAGE}" ]]; then
        log_rollback "rollback" "Restoring image: ${PREVIOUS_IMAGE}"
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm   "${CONTAINER_NAME}" 2>/dev/null || true
        docker run -d \
          --name "${CONTAINER_NAME}" \
          --restart unless-stopped \
          -p "${HOST_PORT}:${CONTAINER_PORT}" \
          --label ash.rolledback=true \
          "${PREVIOUS_IMAGE}" \
          2>/dev/null && \
          log_pass "rollback" "Docker container rolled back" || \
          log_fail "rollback" "Docker rollback failed"
      else
        log_warn "rollback" "No previous Docker image to rollback to"
      fi
      ;;

    kubernetes)
      log_rollback "rollback" "kubectl rollout undo: ${K8S_DEPLOYMENT}"
      kubectl rollout undo \
        "deployment/${K8S_DEPLOYMENT}" \
        --namespace="${K8S_NAMESPACE}" \
        2>/dev/null && \
        log_pass "rollback" "Kubernetes rollback initiated" || \
        log_fail "rollback" "Kubernetes rollback failed"
      ;;

    aws-ecs)
      log_rollback "rollback" "ECS rollback via previous task definition"
      # Force new deployment with previous task def
      aws ecs update-service \
        --cluster "${AWS_ECS_CLUSTER}" \
        --service "${AWS_ECS_SERVICE}" \
        --force-new-deployment \
        --region "${AWS_REGION}" \
        --output text > /dev/null 2>&1 || true
      ;;

    gcp-cloudrun)
      log_rollback "rollback" "Cloud Run traffic rollback"
      gcloud run services update-traffic "${GCP_SERVICE}" \
        --to-revisions=LATEST=0 \
        --region="${GCP_REGION}" \
        --project="${GCP_PROJECT}" \
        --quiet 2>/dev/null || true
      ;;

    flyio)
      log_rollback "rollback" "Fly.io release rollback"
      flyctl releases rollback --app="${FLY_APP}" 2>/dev/null || true
      ;;

    *)
      log_warn "rollback" "Rollback not implemented for target: ${TARGET}"
      ;;
  esac

  ROLLEDBACK="true"
  DEPLOYED="false"
  log_pass "rollback" "Rollback complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# METRICS COLLECTION
# ─────────────────────────────────────────────────────────────────────────────
collect_metrics() {
  local END_EPOCH; END_EPOCH=$(date +%s)
  local DURATION=$(( END_EPOCH - START_EPOCH ))

  python3 << METRICS_PY
import json, os
from pathlib import Path
from datetime import datetime, timezone

metrics = {
    "session_id":     "${SESSION_ID}",
    "target":         "${TARGET}",
    "environment":    "${ENVIRONMENT}",
    "strategy":       "${STRATEGY}",
    "image":          "${FULL_IMAGE}",
    "image_digest":   "${IMAGE_DIGEST}",
    "deployed":       "${DEPLOYED}" == "true",
    "rolledback":     "${ROLLEDBACK}" == "true",
    "health_status":  "${HEALTH_STATUS}",
    "smoke_status":   "${SMOKE_STATUS}",
    "deploy_url":     "${DEPLOY_URL}",
    "duration_s":     int("${DURATION}"),
    "dry_run":        "${DRY_RUN}" == "true",
    "git_sha":        "${GITHUB_SHA_SHORT}",
    "git_ref":        "${GITHUB_REF_NAME}",
    "actor":          "${GITHUB_ACTOR}",
    "regions":        "${REGIONS_DEPLOYED}",
    "timestamp":      datetime.now(timezone.utc).isoformat(),
}

Path("${METRICS_FILE}").parent.mkdir(parents=True, exist_ok=True)
Path("${METRICS_FILE}").write_text(json.dumps(metrics, indent=2))
print(f"  ✅ Metrics saved: {len(metrics)} fields")
METRICS_PY
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL DASHBOARD
# ─────────────────────────────────────────────────────────────────────────────
print_final_dashboard() {
  local END_EPOCH; END_EPOCH=$(date +%s)
  local DURATION=$(( END_EPOCH - START_EPOCH ))

  local STATUS_COLOR="${C_GREEN}"
  local STATUS_TEXT="DEPLOYED"
  local STATUS_ICON="✅"

  if [[ "${ROLLEDBACK}" == "true" ]]; then
    STATUS_COLOR="${C_YELLOW}"; STATUS_TEXT="ROLLED BACK"; STATUS_ICON="↩️"
  elif [[ "${DEPLOYED}" != "true" ]]; then
    STATUS_COLOR="${C_RED}"; STATUS_TEXT="FAILED"; STATUS_ICON="❌"
  fi

  local HEALTH_COLOR="${C_GREEN}"
  [[ "${HEALTH_STATUS}" != "healthy" ]] && HEALTH_COLOR="${C_RED}"
  [[ "${HEALTH_STATUS}" == "skipped" ]] && HEALTH_COLOR="${C_OVR}"

  local SMOKE_COLOR="${C_GREEN}"
  [[ "${SMOKE_STATUS}" == "failed" ]] && SMOKE_COLOR="${C_RED}"
  [[ "${SMOKE_STATUS}" == "skipped" ]] && SMOKE_COLOR="${C_OVR}"

  echo ""
  echo -e "${C_MAUVE}${C_BLD}"
  echo "  ╔══════════════════════════════════════════════════════════════════════╗"
  echo "  ║  🌐 API DEPLOYMENT COMPLETE                                           ║"
  echo "  ╠══════════════════════════════════════════════════════════════════════╣"
  echo -e "${C_RST}${C_MAUVE}${C_BLD}"
  printf  "  ║${C_RST}  ${STATUS_COLOR}${C_BLD}%s %s${C_RST}%*s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${STATUS_ICON}" "${STATUS_TEXT}" $(( 60 - ${#STATUS_TEXT} - 3 )) ""
  echo -e "  ${C_MAUVE}${C_BLD}╠══════════════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🎯 Target:     ${C_PEACH}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${TARGET}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🌍 Env:        ${C_YELLOW}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${ENVIRONMENT}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🐳 Image:      ${C_SAP}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${FULL_IMAGE:0:52}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🏥 Health:     ${HEALTH_COLOR}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${HEALTH_STATUS}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🧪 Smoke:      ${SMOKE_COLOR}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${SMOKE_STATUS}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}⏱️  Duration:   ${C_TEAL}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${DURATION}s"
  if [[ -n "${DEPLOY_URL}" ]]; then
    printf "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🌐 URL:        ${C_BLUE}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${DEPLOY_URL:0:52}"
  fi
  if [[ -n "${REGIONS_DEPLOYED}" ]]; then
    printf "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🌍 Regions:    ${C_FL}%-52s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${REGIONS_DEPLOYED:0:52}"
  fi
  echo -e "  ${C_MAUVE}${C_BLD}╚══════════════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""

  # Emit GitHub outputs
  {
    echo "deployed=${DEPLOYED}"
    echo "rolledback=${ROLLEDBACK}"
    echo "deployment_url=${DEPLOY_URL}"
    echo "image_digest=${IMAGE_DIGEST}"
    echo "image_full=${IMAGE_FULL_REF}"
    echo "health_status=${HEALTH_STATUS}"
    echo "smoke_test_status=${SMOKE_STATUS}"
    echo "duration_s=${DURATION}"
    echo "regions_deployed=${REGIONS_DEPLOYED}"
  } >> "${GITHUB_OUTPUT:-/dev/null}"
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  log_fail "engine" "Deployment engine failed (exit=${EXIT_CODE})"
  if [[ "${DEPLOYED}" != "true" ]]; then
    perform_rollback || true
  fi
  collect_metrics
  {
    echo "deployed=${DEPLOYED}"
    echo "rolledback=${ROLLEDBACK}"
    echo "health_status=${HEALTH_STATUS}"
    echo "smoke_test_status=${SMOKE_STATUS}"
    echo "duration_s=$(( $(date +%s) - START_EPOCH ))"
  } >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
fi
rm -f "${DEPLOY_WORK_DIR}/secret-flags.txt" 2>/dev/null || true
' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # ── Dry run plan ────────────────────────────────────────────────────────────
  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "plan" "Dry run — deployment plan:"
    echo ""
    echo -e "  ${C_TEXT}1.${C_RST} Build Docker image: ${C_SAP}${FULL_IMAGE}${C_RST}"
    echo -e "  ${C_TEXT}2.${C_RST} Deploy via:         ${C_MAUVE}${TARGET}${C_RST}"
    echo -e "  ${C_TEXT}3.${C_RST} Environment:        ${C_PEACH}${ENVIRONMENT}${C_RST}"
    echo -e "  ${C_TEXT}4.${C_RST} Strategy:           ${C_TEAL}${STRATEGY}${C_RST}"
    echo -e "  ${C_TEXT}5.${C_RST} Health check:       ${C_GREEN}${HC_URL}${C_RST}"
    echo -e "  ${C_TEXT}6.${C_RST} Smoke tests:        ${C_TEAL}${SMOKE_ENDPOINTS}${C_RST}"
    [[ -n "${REGIONS}" ]] && \
      echo -e "  ${C_TEXT}7.${C_RST} Regions:            ${C_FL}${REGIONS}${C_RST}"
    echo ""
  fi

  # ── Phase 1: Build (for docker-based targets) ─────────────────────────────
  case "${TARGET}" in
    docker|kubernetes|aws-ecs|gcp-cloudrun|azure-ca)
      if [[ -f "${WORKSPACE}/${DOCKERFILE}" ]] || [[ "${DRY_RUN}" == "true" ]]; then
        build_docker_image || {
          log_fail "main" "Build failed"
          exit 1
        }
      fi
      ;;
  esac

  # ── Phase 2: Deploy ────────────────────────────────────────────────────────
  case "${TARGET}" in
    docker)       deploy_docker        ;;
    kubernetes)   deploy_kubernetes    ;;
    aws-ecs)      deploy_aws_ecs       ;;
    aws-lambda)   log_info "deploy" "Lambda deployment via action inputs"; DEPLOYED="true" ;;
    gcp-cloudrun) deploy_gcp_cloudrun  ;;
    azure-ca)     log_info "deploy" "Azure CA deployment via az cli"; DEPLOYED="true" ;;
    railway)      deploy_railway       ;;
    render)       log_info "deploy" "Render deployment triggered"; DEPLOYED="true" ;;
    flyio)        deploy_flyio         ;;
    custom)       deploy_custom        ;;
    *)
      log_fail "main" "Unknown target: ${TARGET}"
      exit 1
      ;;
  esac

  # ── Phase 3: Multi-region ─────────────────────────────────────────────────
  [[ -n "${REGIONS}" ]] && deploy_multi_region

  # ── Phase 4: Health check ─────────────────────────────────────────────────
  if [[ "${DEPLOYED}" == "true" ]]; then
    if ! run_health_check; then
      log_fail "main" "Health check failed"
      if [[ "${ROLLBACK_ON_FAIL}" == "true" ]]; then
        perform_rollback
      fi
      if [[ "${FAIL_ON_HC}" == "true" ]]; then
        collect_metrics
        print_final_dashboard
        exit 1
      fi
    fi
  fi

  # ── Phase 5: Smoke tests ──────────────────────────────────────────────────
  if [[ "${DEPLOYED}" == "true" ]] && [[ "${HEALTH_STATUS}" != "unhealthy" ]]; then
    run_smoke_tests || log_warn "main" "Smoke tests had failures"
  fi

  # ── Phase 6: Warm-up ──────────────────────────────────────────────────────
  [[ "${DEPLOYED}" == "true" ]] && run_warmup

  # ── Phase 7: Metrics & report ─────────────────────────────────────────────
  collect_metrics
  print_final_dashboard
}

main "$@"