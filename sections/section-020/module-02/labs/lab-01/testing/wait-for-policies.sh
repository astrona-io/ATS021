#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# proxies enforce the policies, so the graders do not race the control plane.
set -uo pipefail

for i in $(seq 1 30); do
  code="$(kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout.starfleet 2>/dev/null || true)"
  if [ "$code" = "403" ]; then
    echo "[testing] policies are active."
    exit 0
  fi
  sleep 2
done
echo "[testing] policies were not active in time." >&2
exit 1
