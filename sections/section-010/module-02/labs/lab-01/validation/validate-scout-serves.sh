#!/usr/bin/env bash
# Check: behaviour. shuttle can still call the scout Service, so the fix did
# not break the workloads.
set -uo pipefail

code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://scout.starfleet.svc.cluster.local/healthz 2>/dev/null || true)"
if [ "$code" != "200" ]; then
  echo "FAIL: shuttle got HTTP '${code}' from scout, expected 200"
  exit 1
fi

echo "PASS: shuttle reaches scout (HTTP 200)"
