#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/solution.yaml"
kubectl annotate namespace starfleet config.linkerd.io/default-inbound-policy=all-authenticated --overwrite
# The proxies read the annotation when they start, so restart every workload.
for name in scout probe shuttle caller; do
  kubectl -n starfleet rollout restart "deployment/$name"
done
for name in scout probe shuttle caller; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[solution] Applied."
