#!/usr/bin/env bash
# Reference end state, run only by `astrona test`.
set -euo pipefail
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Mesh the namespace: the annotation applies to new pods only, so restart every Deployment.
kubectl annotate namespace starfleet linkerd.io/inject=enabled --overwrite
for name in scout-v1 scout-v2 shuttle caller; do
  kubectl -n starfleet rollout restart "deployment/$name"
done
for name in scout-v1 scout-v2 shuttle caller; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
# Server, repaired MeshTLSAuthentication and the weighted HTTPRoute.
kubectl apply -f "$LAB_DIR/solution/solution.yaml"
