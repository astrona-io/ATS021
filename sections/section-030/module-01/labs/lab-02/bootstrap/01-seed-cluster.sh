#!/usr/bin/env bash
# Environment only: no policy or graded Pod is created.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Install the same Kyverno CLI version on the learner's terminal.
BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) ASSET="darwin_arm64" ;;
  Darwin-x86_64) ASSET="darwin_x86_64" ;;
  Linux-aarch64|Linux-arm64) ASSET="linux_arm64" ;;
  Linux-x86_64) ASSET="linux_x86_64" ;;
  *) echo "Unsupported Kyverno CLI platform" >&2; exit 1 ;;
esac
curl -fsSL -o "$WORK/kyverno.tgz" \
  "https://github.com/kyverno/kyverno/releases/download/v1.19.1/kyverno-cli_v1.19.1_${ASSET}.tar.gz"
tar -xzf "$WORK/kyverno.tgz" -C "$WORK"
install -m 0755 "$WORK/kyverno" "$BIN_DIR/kyverno"
kyverno version

kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.19.1/install.yaml
for controller in admission background reports cleanup; do
  kubectl -n kyverno rollout status "deployment/kyverno-${controller}-controller" --timeout=300s
done
kubectl wait --for=condition=Established crd/namespacedmutatingpolicies.policies.kyverno.io --timeout=120s
# Controller availability can precede webhook registration.
for webhook in kyverno-policy-validating-webhook-cfg kyverno-policy-mutating-webhook-cfg; do
  for attempt in $(seq 1 60); do
    if kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration -o name | grep -q "/${webhook}$"; then break; fi
    if [ "$attempt" -eq 60 ]; then echo "Webhook ${webhook} did not register" >&2; exit 1; fi
    sleep 2
  done
done
kubectl apply -f "$DIR/manifests/lab-start.yaml"
mkdir -p /tmp/kyverno-team-test
cp "$DIR/manifests/offline/"* /tmp/kyverno-team-test/
echo "[lab] Ready. Offline fixtures are in /tmp/kyverno-team-test."
