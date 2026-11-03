#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet delete rolebinding pipeline-runner-edit --ignore-not-found
kubectl -n outpost delete rolebinding pipeline-runner-edit --ignore-not-found
echo "[solution] Applied."
