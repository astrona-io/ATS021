#!/usr/bin/env bash
# Check: no binding gives ci-deployer cluster-admin, and the service account
# still exists (deleting it is not the fix).
set -uo pipefail

fail=0

if ! kubectl -n orbit get serviceaccount ci-deployer >/dev/null 2>&1; then
  echo "FAIL: the ci-deployer service account was deleted; remove its grant instead"
  fail=1
fi

bound="$(kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[]
  | select(.roleRef.name=="cluster-admin")
  | select(any(.subjects[]?; .kind=="ServiceAccount" and .name=="ci-deployer"))
  | .kind + "/" + .metadata.name')"
if [ -n "$bound" ]; then
  echo "FAIL: ci-deployer is still bound to cluster-admin by: $bound"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: ci-deployer no longer has cluster-admin"
fi
exit "$fail"
