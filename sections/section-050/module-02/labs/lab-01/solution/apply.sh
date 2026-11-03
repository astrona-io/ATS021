#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml" 2>&1 | grep -v '^Warning: kyverno.io/v1 ClusterPolicy is deprecated' || true
echo "[solution] Applied."
