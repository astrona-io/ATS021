#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# aggregation controller has copied the lease rule into the view role, and
# the authorizer cache has the new bindings.
set -euo pipefail

for i in $(seq 1 30); do
  if [ "$(kubectl auth can-i list leases.coordination.k8s.io -n starfleet --as=dev-anna --as-group=developers 2>/dev/null || true)" = "yes" ]; then
    echo "[testing] view role aggregated."
    exit 0
  fi
  sleep 2
done
echo "[testing] view role was not aggregated in time." >&2
exit 1
