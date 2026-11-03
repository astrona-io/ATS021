#!/usr/bin/env bash
# Check: ci-deployer has no more than it needs. Rejects the plausible wrong
# fixes: cluster-admin, edit, admin, a wildcard Role, or a ClusterRoleBinding.
set -uo pipefail

SA="system:serviceaccount:starfleet:ci-deployer"
fail=0

expect_no() {
  local description="$1"
  shift
  local answer
  answer="$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: ci-deployer is allowed to $description"
    fail=1
  fi
}

expect_no "delete deployments in starfleet" delete deployments.apps -n starfleet
expect_no "read secrets in starfleet" get secrets -n starfleet
expect_no "create pods in starfleet" create pods -n starfleet
expect_no "do anything in starfleet" '*' '*' -n starfleet
expect_no "list deployments in outpost" list deployments.apps -n outpost
expect_no "list deployments in every namespace" list deployments.apps --all-namespaces
expect_no "delete nodes" delete nodes

# The API server's real answer to a delete request (dry run still authorizes).
if kubectl -n starfleet delete deployment probe --dry-run=server --as="$SA" >/dev/null 2>&1; then
  echo "FAIL: the API server accepted a delete of the probe Deployment from ci-deployer"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: ci-deployer has only the Deployment rights in starfleet"
fi
exit "$fail"
