#!/usr/bin/env bash
# Check: legacy-agent can still read pods in starfleet, and only that.
# A ClusterRoleBinding to view or to a pod-reading ClusterRole fails the
# outpost check.
set -uo pipefail

SA="system:serviceaccount:starfleet:legacy-agent"
fail=0

for verb in get list watch; do
  answer="$(kubectl auth can-i "$verb" pods -n starfleet --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "yes" ]; then
    echo "FAIL: legacy-agent cannot $verb pods in starfleet"
    fail=1
  fi
done

if ! kubectl -n starfleet get pods --as="$SA" >/dev/null 2>&1; then
  echo "FAIL: legacy-agent could not list pods in starfleet"
  fail=1
fi

expect_no() {
  local description="$1"
  shift
  local answer
  answer="$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: legacy-agent is allowed to $description"
    fail=1
  fi
}

expect_no "list pods in outpost" list pods -n outpost
expect_no "read secrets in starfleet" get secrets -n starfleet
expect_no "list services in starfleet" list services -n starfleet
expect_no "delete pods in starfleet" delete pods -n starfleet

if [ "$fail" -eq 0 ]; then
  echo "PASS: legacy-agent reads pods in starfleet and nothing else"
fi
exit "$fail"
