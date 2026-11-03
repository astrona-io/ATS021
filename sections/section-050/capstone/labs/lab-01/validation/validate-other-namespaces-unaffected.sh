#!/usr/bin/env bash
# Check: starfleet and default are not restricted, the namespace labels are unchanged and Kyverno runs.
set -uo pipefail

fail=0
exhausted=0
DIGEST="sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da"

# try_image <namespace> <image>: a server-side dry run of a Deployment, so every
# admission webhook runs and nothing is stored. Prints the combined output.
try_image() {
  kubectl -n "$1" create deployment grader-image-test --image="$2" --dry-run=server -o name 2>&1
}

# expect_rejected <namespace> <image> <why>
# Retries for about 45 seconds, because Kyverno needs a few seconds to register
# a policy change. After one request used up its retries, later ones try once.
expect_rejected() {
  local ns="$1" image="$2" why="$3" tries=15
  [ "$exhausted" -eq 1 ] && tries=1
  for _ in $(seq 1 "$tries"); do
    if ! try_image "$ns" "$image" >/dev/null; then
      return 0
    fi
    [ "$tries" -gt 1 ] && sleep 3
  done
  exhausted=1
  echo "FAIL: the image $image was accepted in $ns, but it must be rejected ($why)"
  fail=1
}

# expect_accepted <namespace> <image> <why>
expect_accepted() {
  local ns="$1" image="$2" why="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(try_image "$ns" "$image")"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: the image $image was rejected in $ns, but it must be accepted ($why): $(printf "%s" "$out" | tail -2)"
  fail=1
}

label_of() {
  kubectl get namespace "$1" -o jsonpath="{.metadata.labels.environment}" 2>/dev/null
}

[ "$(label_of starfleet)" = "development" ] || { echo "FAIL: the namespace starfleet must keep the label environment=development"; fail=1; }
[ "$(label_of starfleet-prod)" = "production" ] || { echo "FAIL: the namespace starfleet-prod must keep the label environment=production"; fail=1; }
[ -z "$(label_of default)" ] || { echo "FAIL: the namespace default must not have an environment label"; fail=1; }

ready="$(kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "${ready:-0}" -ge 1 ] || { echo "FAIL: the Kyverno admission controller is not running"; fail=1; }

expect_accepted starfleet ghcr.io/stefanprodan/podinfo:6.15.0 "development needs no digest"
expect_accepted default nginx:latest "a namespace without an environment label is not covered"

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet and default are not restricted, labels are unchanged and Kyverno runs"
fi
exit "$fail"
