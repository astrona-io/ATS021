#!/usr/bin/env bash
# Check: a pod without the team label is refused in starfleet, a pod with the
# label is accepted there, and a pod without the label is still accepted in
# outpost. The grader uses --dry-run=server, so every admission webhook runs
# and nothing is stored.
set -uo pipefail

fail=0

# expect_rejected <description> <namespace> <labels>
# Retries for about 60 seconds, because Gatekeeper needs a few seconds to load a new constraint.
expect_rejected() {
  local description="$1" namespace="$2" labels="$3"
  for _ in $(seq 1 20); do
    if ! kubectl -n "$namespace" run grader-pod --image=curlimages/curl:8.22.0 --labels="$labels" --dry-run=server -o name >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was accepted, but it must be rejected"
  fail=1
}

# expect_accepted <description> <namespace> <labels>
expect_accepted() {
  local description="$1" namespace="$2" labels="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(kubectl -n "$namespace" run grader-pod --image=curlimages/curl:8.22.0 --labels="$labels" --dry-run=server -o name 2>&1)"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -2)"
  fail=1
}

expect_rejected "a pod with the label app=grader-pod and no team label in starfleet" starfleet "app=grader-pod"
expect_accepted "a pod with the labels app=grader-pod and team=grader in starfleet" starfleet "app=grader-pod,team=grader"
expect_accepted "a pod with the label app=grader-pod and no team label in outpost" outpost "app=grader-pod"

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet refuses pods without the team label, labelled pods and outpost are accepted"
fi
exit "$fail"
