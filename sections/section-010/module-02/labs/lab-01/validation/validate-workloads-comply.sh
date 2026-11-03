#!/usr/bin/env bash
# Check: scout, probe and shuttle still exist, every replica is available, and
# every running pod has the four settings the restricted level requires.
# Reading the pods catches a namespace label that was set while the old,
# non-compliant pods kept running.
set -uo pipefail

fail=0

for name in scout probe shuttle; do
  desired="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
  available="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ -z "$desired" ] || [ "${desired:-0}" -lt 1 ]; then
    echo "FAIL: Deployment $name is missing or scaled to zero"
    fail=1
    continue
  fi
  if [ "${available:-0}" != "$desired" ]; then
    echo "FAIL: Deployment $name has ${available:-0} of $desired replicas available"
    fail=1
  fi

  problems="$(kubectl -n starfleet get pods -l "app=$name" -o json | jq -r '
    .items[]
    | select(.metadata.deletionTimestamp == null)
    | . as $pod
    | ($pod.spec.securityContext // {}) as $psc
    | ($pod.spec.containers + ($pod.spec.initContainers // []))[]
    | (.securityContext // {}) as $csc
    | [
        (if ($csc.allowPrivilegeEscalation == false) then empty else "allowPrivilegeEscalation is not false" end),
        (if (($csc.capabilities.drop // []) | index("ALL")) then empty else "capabilities do not drop ALL" end),
        (if (($csc.runAsNonRoot // $psc.runAsNonRoot) == true) then empty else "runAsNonRoot is not true" end),
        (if ((($csc.seccompProfile.type // $psc.seccompProfile.type) // "") | IN("RuntimeDefault","Localhost")) then empty else "seccompProfile is not RuntimeDefault" end),
        (if ($csc.privileged == true) then "privileged" else empty end)
      ]
    | select(length > 0)
    | $pod.metadata.name + "/" + .[]' 2>/dev/null)"
  if [ -n "$problems" ]; then
    echo "FAIL: running pods of $name do not meet restricted:"
    echo "$problems" | sed 's/^/  /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout, probe and shuttle meet restricted and are available"
fi
exit "$fail"
