#!/usr/bin/env bash
# Check: in outpost (environment=sandbox), a Deployment above the limit is
# accepted, and the API server returns a warning. The grader uses
# --dry-run=server, so nothing is stored.
set -uo pipefail

fail=0
out=""

for _ in $(seq 1 15); do
  out="$(kubectl -n outpost create deployment grader-six --image=curlimages/curl:8.22.0 --replicas=6 --dry-run=server -o name 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '^Warning:'; then
    break
  fi
  sleep 3
done

if [ "$rc" -ne 0 ]; then
  echo "FAIL: a Deployment with 6 replicas in outpost was rejected, but sandbox namespaces only warn: $(printf '%s' "$out" | tail -2)"
  exit 1
fi
if ! printf '%s' "$out" | grep -q '^Warning:'; then
  echo "FAIL: a Deployment with 6 replicas in outpost was accepted without a warning"
  fail=1
fi

# Within the limit, there must be no warning.
quiet="$(kubectl -n outpost create deployment grader-two --image=curlimages/curl:8.22.0 --replicas=2 --dry-run=server -o name 2>&1)"
if printf '%s' "$quiet" | grep -q '^Warning:'; then
  echo "FAIL: a Deployment with 2 replicas in outpost got a warning"
  fail=1
fi

# The binding for the sandbox must warn, not deny.
if ! kubectl get validatingadmissionpolicybindings -o json | jq -e '[.items[] | select(.spec.validationActions | index("Warn"))] | length > 0' >/dev/null; then
  echo "FAIL: no ValidatingAdmissionPolicyBinding with the action Warn exists"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: outpost accepts a Deployment above the limit and returns a warning"
fi
exit "$fail"
