#!/usr/bin/env bash
# Starting state for the Linkerd capstone. Environment only: it installs the
# Gateway API CRDs v1.4.0, Linkerd edge-26.10.1 and the Starfleet workloads.
# The starfleet namespace has no proxy injection annotation, no Server and no
# HTTPRoute, and the MeshTLSAuthentication names the wrong service account, on
# purpose. The faults are the material; do not fix them here.
set -euo pipefail

LINKERD_VERSION="edge-26.10.1"
GATEWAY_API_VERSION="v1.4.0"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

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
  echo "[lab] Downloading linkerd ${LINKERD_VERSION}..."
  curl -fsSL -o "$BIN_DIR/linkerd" \
    "https://github.com/linkerd/linkerd2/releases/download/${LINKERD_VERSION}/linkerd2-cli-${LINKERD_VERSION}-${ASSET}"
  chmod 0755 "$BIN_DIR/linkerd"
  export PATH="$BIN_DIR:$PATH"
fi

echo "[lab] Installing Gateway API CRDs ${GATEWAY_API_VERSION}..."
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=60s

echo "[lab] Installing Linkerd..."
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check --wait 5m

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout-v1 scout-v2 shuttle caller; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[lab] Ready."
