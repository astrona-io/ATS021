#!/usr/bin/env bash
# Check: a pod that uses the latest tag is refused in starfleet. The grader
# uses --dry-run=server, so every admission webhook runs and nothing is stored.
set -uo pipefail

fail=0

# expect_rejected <description> <namespace> <image>
# Retries for about 60 seconds, because Gatekeeper needs a few seconds to load a new constraint.
expect_rejected() {
  local description="$1" namespace="$2" image="$3"
  for _ in $(seq 1 20); do
    if ! kubectl -n "$namespace" run grader-latest --image="$image" --dry-run=server -o name >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was accepted, but it must be rejected"
  fail=1
}

expect_rejected "a pod with image curlimages/curl:latest in starfleet" starfleet curlimages/curl:latest
expect_rejected "a pod with image ghcr.io/stefanprodan/podinfo:latest in starfleet" starfleet ghcr.io/stefanprodan/podinfo:latest

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet refuses pods that use the latest tag"
fi
exit "$fail"
