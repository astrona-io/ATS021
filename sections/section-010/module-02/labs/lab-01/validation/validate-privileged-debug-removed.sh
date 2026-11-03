#!/usr/bin/env bash
# Check: the privileged-debug Deployment and its pods are gone.
set -uo pipefail

fail=0

if kubectl -n starfleet get deployment privileged-debug >/dev/null 2>&1; then
  echo "FAIL: the privileged-debug Deployment still exists in starfleet"
  fail=1
fi

# A pod that is already shutting down (deletionTimestamp set) does not count.
remaining="$(kubectl -n starfleet get pods -l app=privileged-debug -o json 2>/dev/null \
  | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | .metadata.name' || true)"
if [ -n "$remaining" ]; then
  echo "FAIL: privileged-debug pods are still present: $remaining"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: privileged-debug is removed"
fi
exit "$fail"
