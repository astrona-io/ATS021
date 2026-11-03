#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
for i in $(seq 1 60); do
  if kubectl get crd k8sdisallowedtags.constraints.gatekeeper.sh >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8sdisallowedtags.constraints.gatekeeper.sh --timeout=60s
kubectl apply -f "$DIR/constraints.yaml"
echo "[solution] Applied."
