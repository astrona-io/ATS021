#!/usr/bin/env bash
# Check: the beacon Deployment still exists, all replicas are available, every
# running pod has the four settings restricted requires, and the Service has
# an endpoint. A label set while the old pod keeps running fails here.
set -uo pipefail

fail=0

desired="$(kubectl -n orbit get deployment beacon -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
available="$(kubectl -n orbit get deployment beacon -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
if [ -z "$desired" ] || [ "${desired:-0}" -lt 1 ]; then
  echo "FAIL: the beacon Deployment is missing or scaled to zero"
  exit 1
fi
if [ "${available:-0}" != "$desired" ]; then
  echo "FAIL: beacon has ${available:-0} of $desired replicas available"
  fail=1
fi

problems="$(kubectl -n orbit get pods -l app=beacon -o json | jq -r '
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
  echo "FAIL: running beacon pods do not meet restricted:"
  echo "$problems" | sed 's/^/  /'
  fail=1
fi

endpoints="$(kubectl -n orbit get endpoints beacon -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)"
if [ -z "$endpoints" ]; then
  echo "FAIL: the beacon Service has no ready endpoint"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon meets restricted, is available and is served"
fi
exit "$fail"
