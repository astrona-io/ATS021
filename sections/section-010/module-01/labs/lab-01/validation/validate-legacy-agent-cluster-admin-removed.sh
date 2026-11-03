#!/usr/bin/env bash
# Check: legacy-agent has no binding to cluster-admin anywhere, and the
# service account still exists (deleting it is not the fix).
set -uo pipefail

SA="system:serviceaccount:starfleet:legacy-agent"
fail=0

if ! kubectl -n starfleet get serviceaccount legacy-agent >/dev/null 2>&1; then
  echo "FAIL: the legacy-agent service account was deleted; remove its grant instead"
  fail=1
fi

bound="$(kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[]
  | select(.roleRef.name=="cluster-admin")
  | select(any(.subjects[]?; .kind=="ServiceAccount" and .name=="legacy-agent"))
  | .kind + "/" + .metadata.name')"
if [ -n "$bound" ]; then
  echo "FAIL: legacy-agent is still bound to cluster-admin by: $bound"
  fail=1
fi

for check in "delete nodes" "get secrets --all-namespaces" "create clusterrolebindings"; do
  # shellcheck disable=SC2086
  answer="$(kubectl auth can-i $check --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: legacy-agent is still allowed to: $check"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: legacy-agent no longer has cluster-admin"
fi
exit "$fail"
