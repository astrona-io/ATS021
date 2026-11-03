#!/usr/bin/env bash
# Check: ci-deployer can read, create and change Deployments in starfleet,
# proved by the API server's answer to a real request, not only by can-i.
set -uo pipefail

SA="system:serviceaccount:starfleet:ci-deployer"
fail=0

for verb in get list watch create update patch; do
  answer="$(kubectl auth can-i "$verb" deployments.apps -n starfleet --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "yes" ]; then
    echo "FAIL: ci-deployer cannot $verb deployments in starfleet"
    fail=1
  fi
done

if ! kubectl -n starfleet annotate deployment scout lab.astrona.io/checked-by=grader --overwrite --as="$SA" >/dev/null 2>&1; then
  echo "FAIL: ci-deployer could not change the scout Deployment"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: ci-deployer can manage Deployments in starfleet"
fi
exit "$fail"
