#!/usr/bin/env bash
# Check: scout refuses everything except GET from shuttle. A caller with a valid
# identity (the probe service account) and a POST from shuttle both get 403.
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

expect_code "caller (probe identity) GET to scout" 403 starfleet caller caller http://scout.starfleet/
expect_code "shuttle POST to scout" 403 starfleet shuttle shuttle -X POST -d hi http://scout.starfleet/echo

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout refuses other identities and other methods"
fi
exit "$fail"
