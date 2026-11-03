#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/solution.yaml"
# Remove the label that keeps the sidecar out. The Deployment rolls new pods.
kubectl -n starfleet patch deployment beacon --type=json \
  -p='[{"op":"remove","path":"/spec/template/metadata/labels/sidecar.istio.io~1inject"}]'
kubectl -n starfleet rollout status deployment/beacon --timeout=180s
echo "[solution] Applied."
