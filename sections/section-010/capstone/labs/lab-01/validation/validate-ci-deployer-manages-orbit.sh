#!/usr/bin/env bash
# Check: ci-deployer can manage Deployments and Services in orbit, proved by
# can-i and by real requests to the API server.
set -uo pipefail

SA="system:serviceaccount:orbit:ci-deployer"
fail=0

for resource in deployments.apps services; do
  for verb in get list watch create update patch delete; do
    answer="$(kubectl auth can-i "$verb" "$resource" -n orbit --as="$SA" 2>/dev/null || true)"
    if [ "$answer" != "yes" ]; then
      echo "FAIL: ci-deployer cannot $verb $resource in orbit"
      fail=1
    fi
  done
done

if ! kubectl -n orbit annotate deployment beacon lab.astrona.io/checked-by=grader --overwrite --as="$SA" >/dev/null 2>&1; then
  echo "FAIL: ci-deployer could not change the beacon Deployment"
  fail=1
fi
if ! kubectl -n orbit annotate service beacon lab.astrona.io/checked-by=grader --overwrite --as="$SA" >/dev/null 2>&1; then
  echo "FAIL: ci-deployer could not change the beacon Service"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: ci-deployer manages Deployments and Services in orbit"
fi
exit "$fail"
