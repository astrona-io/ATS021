#!/usr/bin/env bash
# Check: in starfleet (environment=production), a new Deployment above 5 replicas
# and a scale of scout to 9 replicas are rejected; 5 replicas are accepted.
# The grader uses --dry-run=server, so nothing is stored.
set -uo pipefail

fail=0

# expect_rejected <description> <command...>
# Retries for about 45 seconds, because the API server needs a few seconds to use a new policy.
expect_rejected() {
  local description="$1"
  shift
  for _ in $(seq 1 15); do
    if ! "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was accepted, but it must be rejected"
  fail=1
}

expect_accepted() {
  local description="$1" out=""
  shift
  if ! out="$("$@" 2>&1)"; then
    echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -2)"
    fail=1
  fi
}

expect_rejected "a new Deployment with 6 replicas in starfleet" \
  kubectl -n starfleet create deployment grader-six --image=curlimages/curl:8.22.0 --replicas=6 --dry-run=server -o name
expect_rejected "kubectl scale of scout to 9 replicas (the deployments/scale subresource)" \
  kubectl -n starfleet scale deployment scout --replicas=9 --dry-run=server
expect_rejected "a patch of scout to 9 replicas" \
  kubectl -n starfleet patch deployment scout --type=merge -p '{"spec":{"replicas":9}}' --dry-run=server

expect_accepted "a new Deployment with 5 replicas in starfleet" \
  kubectl -n starfleet create deployment grader-five --image=curlimages/curl:8.22.0 --replicas=5 --dry-run=server -o name

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet rejects more than 5 replicas on create, patch and scale"
fi
exit "$fail"
