#!/usr/bin/env bash
# Starting state for the Istio capstone. Environment only: it installs Istio 1.31.1
# (minimal profile) and the Starfleet workloads. It creates no
# PeerAuthentication and no AuthorizationPolicy: the mesh starts in PERMISSIVE
# mode with no policy, on purpose.
set -euo pipefail

ISTIO_VERSION="1.31.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  echo "[lab] Downloading istioctl ${ISTIO_VERSION}..."
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

echo "[lab] Installing the Istio control plane (minimal profile)..."
istioctl install --set profile=minimal -y
kubectl -n istio-system rollout status deployment/istiod --timeout=300s

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle caller beacon; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
for name in drifter drifter-plain; do
  kubectl -n outpost rollout status "deployment/$name" --timeout=180s
done
echo "[lab] Ready."
