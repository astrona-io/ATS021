#!/usr/bin/env bash
# Check: the developers group can list Leases in starfleet, still cannot read
# Secrets, and has no rights in outpost.
set -uo pipefail

fail=0
as_dev=(--as=dev-anna --as-group=developers)

answer="$(kubectl auth can-i list leases.coordination.k8s.io -n starfleet "${as_dev[@]}" 2>/dev/null || true)"
if [ "$answer" != "yes" ]; then
  echo "FAIL: developers cannot list leases in starfleet"
  fail=1
fi

if ! kubectl -n starfleet get leases "${as_dev[@]}" >/dev/null 2>&1; then
  echo "FAIL: the API server refused a leases list from dev-anna"
  fail=1
fi

answer="$(kubectl auth can-i get secrets -n starfleet "${as_dev[@]}" 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: developers can read secrets in starfleet"
  fail=1
fi

answer="$(kubectl auth can-i list leases.coordination.k8s.io -n outpost "${as_dev[@]}" 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: developers can list leases in outpost"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: developers can list leases in starfleet only"
fi
exit "$fail"
