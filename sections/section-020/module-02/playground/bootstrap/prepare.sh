#!/usr/bin/env bash
# Environment prep for the "Require Mutual TLS And Authorize Callers With
# Linkerd" playground (`ats-021-playground-020-02`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. puts the `linkerd` CLI edge-26.10.1 on the PATH,
#   2. installs the Gateway API CRDs Linkerd's policy needs, the Linkerd CRDs,
#      the control plane and the viz extension,
#   3. applies the Starfleet workloads (`starfleet` has proxy injection on),
#   4. waits until every workload is ready.
# No Server and no AuthorizationPolicy are created, and the default inbound
# policy stays all-unauthenticated: drifter can reach scout at the start.
set -euo pipefail

LINKERD_VERSION="edge-26.10.1"
GATEWAY_API_VERSION="v1.4.0"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$PATH:$BIN_DIR"

have_version=""
command -v linkerd >/dev/null 2>&1 && \
  have_version=$(linkerd version --client --short 2>/dev/null || true)
if [ "$have_version" != "$LINKERD_VERSION" ]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) ASSET="darwin-arm64" ;;
    Darwin-x86_64) ASSET="darwin" ;;
    Linux-aarch64|Linux-arm64) ASSET="linux-arm64" ;;
    *) ASSET="linux-amd64" ;;
  esac
  echo "[playground] Downloading linkerd ${LINKERD_VERSION}..."
  curl -fsSL -o "$BIN_DIR/linkerd" \
    "https://github.com/linkerd/linkerd2/releases/download/${LINKERD_VERSION}/linkerd2-cli-${LINKERD_VERSION}-${ASSET}"
  chmod 0755 "$BIN_DIR/linkerd"
  export PATH="$BIN_DIR:$PATH"
fi
linkerd version --client

echo "[playground] Installing Gateway API CRDs ${GATEWAY_API_VERSION} (used by Linkerd policy)..."
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

echo "[playground] Installing Linkerd..."
linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check --wait 5m

echo "[playground] Installing the viz extension..."
linkerd viz install | kubectl apply -f -
linkerd viz check --wait 5m

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[playground] Applying the Starfleet workloads..."
kubectl apply -f "$SCRIPT_DIR/../manifests/starfleet.yaml"
for d in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$d" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[playground] Ready."
