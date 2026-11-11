#!/usr/bin/env bash
set -euo pipefail
for i in $(seq 1 30); do
  code="$(kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout.starfleet/env 2>/dev/null || true)"
  if [ "$code" = "403" ]; then
    echo "[testing] policies are active."
    exit 0
  fi
  sleep 2
done
echo "[testing] policies were not active in time." >&2
exit 1
