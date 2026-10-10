#!/usr/bin/env bash
# Environment prep for the "Require Mutual TLS And Authorize Callers With Istio"
# playground (`ats-021-playground-020-01`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. puts `istioctl` 1.31.1 on the PATH,
#   2. installs the Istio control plane with the `minimal` profile (istiod only),
#   3. applies the Starfleet workloads (`starfleet` has sidecar injection on),
#   4. waits until every workload is ready.
# No PeerAuthentication and no AuthorizationPolicy are created: the mesh starts
# in the default PERMISSIVE mode on purpose.
set -euo pipefail

ISTIO_VERSION="1.31.1"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$PATH:$BIN_DIR"

have_version=""
command -v istioctl >/dev/null 2>&1 && \
  have_version=$(istioctl version --remote=false 2>/dev/null | awk '/client version/{print $3}')
if [ "$have_version" != "$ISTIO_VERSION" ]; then
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "[playground] Downloading istioctl ${ISTIO_VERSION}..."
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) ASSET="osx-arm64" ;;
    Darwin-x86_64) ASSET="osx" ;;
    Linux-aarch64|Linux-arm64) ASSET="linux-arm64" ;;
    *) ASSET="linux-amd64" ;;
  esac
  curl -fsSL -o "$WORK/istioctl.tgz" \
    "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-${ASSET}.tar.gz"
  tar -xzf "$WORK/istioctl.tgz" -C "$WORK"
  install -m 0755 "$WORK/istioctl" "$BIN_DIR/istioctl"
  export PATH="$BIN_DIR:$PATH"
fi
istioctl version --remote=false

echo "[playground] Installing the Istio control plane (minimal profile)..."
istioctl install --set profile=minimal -y
kubectl -n istio-system rollout status deployment/istiod --timeout=300s

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[playground] Applying the Starfleet workloads..."
kubectl apply -f "$SCRIPT_DIR/../manifests/starfleet.yaml"
for d in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$d" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[playground] Ready."
