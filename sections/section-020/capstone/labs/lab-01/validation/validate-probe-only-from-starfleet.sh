#!/usr/bin/env bash
# Check: probe answers callers from starfleet and refuses the meshed drifter
# from outpost. STRICT alone does not stop drifter, because it has a sidecar.
set -uo pipefail

fail=0

# http_code <namespace> <deployment> <container> <curl arguments...>
# Prints the HTTP status, or 000 when the connection failed.
http_code() {
  local namespace="$1" deployment="$2" container="$3"
  shift 3
  kubectl -n "$namespace" exec "deploy/$deployment" -c "$container" -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$@" 2>/dev/null || true
}

# expect_code <description> <expected code> <namespace> <deployment> <container> <curl arguments...>
# Retries for about 30 seconds, because the sidecars need a few seconds to get a new policy.
expect_code() {
  local description="$1" expected="$2" got=""
  shift 2
  for _ in $(seq 1 10); do
    got="$(http_code "$@")"
    if [ "$got" = "$expected" ]; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description: expected $expected, got ${got:-no answer}"
  fail=1
}

expect_code "shuttle GET to probe" 200 starfleet shuttle shuttle http://probe.starfleet/get
expect_code "caller GET to probe" 200 starfleet caller caller http://probe.starfleet/get
expect_code "drifter (outpost identity) GET to probe" 403 outpost drifter drifter http://probe.starfleet/get

if [ "$fail" -eq 0 ]; then
  echo "PASS: probe is reachable only from starfleet"
fi
exit "$fail"
