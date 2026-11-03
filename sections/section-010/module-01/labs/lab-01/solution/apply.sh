#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl delete clusterrolebinding legacy-agent-admin

# The aggregation controller fills the view role within a few seconds.
for i in $(seq 1 30); do
  if kubectl get clusterrole view -o jsonpath='{.rules[*].resources[*]}' | grep -qw leases; then
    break
  fi
  sleep 2
done
echo "[solution] Applied."
