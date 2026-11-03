#!/usr/bin/env bash
# Check: scout runs 8 replicas, which is above the limit. A request that lowers
# the count (8 to 6, or 8 to 3) must still be accepted, so teams can bring an old
# object under the rule step by step. A label change must be accepted too.
set -uo pipefail

fail=0

# expect_accepted <description> <command...>
# Retries for about 30 seconds, in case the policy was just applied.
expect_accepted() {
  local description="$1" out=""
  shift
  for _ in $(seq 1 10); do
    if out="$("$@" 2>&1)"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -2)"
  fail=1
}

replicas="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
if [ "$replicas" != "8" ]; then
  echo "FAIL: scout must still run 8 replicas for this check, found ${replicas:-none}; do not change the workload"
  fail=1
fi

expect_accepted "scale scout from 8 to 6 replicas" \
  kubectl -n starfleet scale deployment scout --replicas=6 --dry-run=server
expect_accepted "scale scout from 8 to 3 replicas" \
  kubectl -n starfleet scale deployment scout --replicas=3 --dry-run=server
expect_accepted "a label change on scout" \
  kubectl -n starfleet label deployment scout tier=backend --overwrite --dry-run=server

# The policy must exist and be bound, or the checks above prove nothing.
if ! kubectl get validatingadmissionpolicybindings -o json | jq -e '[.items[] | select(.spec.validationActions | index("Deny"))] | length > 0' >/dev/null; then
  echo "FAIL: no ValidatingAdmissionPolicyBinding with the action Deny exists"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout can be scaled down and labelled, but not raised"
fi
exit "$fail"
