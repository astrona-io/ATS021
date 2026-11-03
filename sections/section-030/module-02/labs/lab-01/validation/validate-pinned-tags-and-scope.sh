#!/usr/bin/env bash
# Check: a pinned tag is accepted in starfleet, and the latest tag is still
# accepted in outpost (the second constraint only records, it does not deny).
set -uo pipefail

fail=0

# expect_accepted <description> <namespace> <image>
expect_accepted() {
  local description="$1" namespace="$2" image="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(kubectl -n "$namespace" run grader-pinned --image="$image" --dry-run=server -o name 2>&1)"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -2)"
  fail=1
}

expect_accepted "a pod with image curlimages/curl:8.22.0 in starfleet" starfleet curlimages/curl:8.22.0
expect_accepted "a pod with image curlimages/curl:latest in outpost" outpost curlimages/curl:latest

if [ "$fail" -eq 0 ]; then
  echo "PASS: pinned tags are accepted, and outpost is not blocked"
fi
exit "$fail"
