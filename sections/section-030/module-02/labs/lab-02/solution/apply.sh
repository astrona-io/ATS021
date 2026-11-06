#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.astrona/bin:$PATH"

kubectl apply -f "$DIR/solution.yaml"
for i in $(seq 1 60); do
  if kubectl get crd k8sstarfleetworkloadrules.constraints.gatekeeper.sh >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8sstarfleetworkloadrules.constraints.gatekeeper.sh --timeout=60s
kubectl apply -f "$DIR/constraint.yaml"

# The repaired chart replaces the copy on the terminal, then the release is upgraded from it.
rm -rf "$HOME/resources/probe"
cp -R "$DIR/probe" "$HOME/resources/probe"
helm lint "$HOME/resources/probe"
helm template probe "$HOME/resources/probe" -n starfleet >/dev/null
helm upgrade --install probe "$HOME/resources/probe" -n starfleet --wait=watcher --timeout 180s
kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[solution] Applied."
