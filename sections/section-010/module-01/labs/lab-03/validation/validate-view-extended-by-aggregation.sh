#!/usr/bin/env bash
# Check: the lease right came from a labelled ClusterRole that view aggregates,
# not from an edit of view itself or from a new binding.
set -uo pipefail

fail=0

selector="$(kubectl get clusterrole view -o jsonpath='{.aggregationRule.clusterRoleSelectors[0].matchLabels}' 2>/dev/null || true)"
if ! echo "$selector" | grep -q 'aggregate-to-view'; then
  echo "FAIL: the view ClusterRole no longer has its aggregationRule"
  fail=1
fi

extension="$(kubectl get clusterrole -l rbac.authorization.k8s.io/aggregate-to-view=true -o json | jq -r '
  .items[]
  | select(.metadata.name != "view")
  | select(any(.rules[]?; (.resources // []) | index("leases")))
  | .metadata.name' | head -n 1)"
if [ -z "$extension" ]; then
  echo "FAIL: no ClusterRole labelled aggregate-to-view=true grants leases"
  fail=1
fi

if ! kubectl get clusterrole view -o jsonpath='{.rules[*].resources[*]}' | grep -qw leases; then
  echo "FAIL: the view ClusterRole has not aggregated the leases rule"
  fail=1
fi

binding_role="$(kubectl -n starfleet get rolebinding developers-view -o jsonpath='{.roleRef.name}' 2>/dev/null || true)"
if [ "$binding_role" != "view" ]; then
  echo "FAIL: the developers-view RoleBinding must still point at view (found: '${binding_role}')"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: view was extended through aggregation ($extension)"
fi
exit "$fail"
