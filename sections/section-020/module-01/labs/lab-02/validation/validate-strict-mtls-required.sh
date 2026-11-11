#!/usr/bin/env bash
# Check: starfleet requires mTLS. A client without a sidecar is refused for
# both scout and probe, and a client with a sidecar still gets through.
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

# drifter has no sidecar. STRICT resets its connection, so curl reports 000.
expect_code "drifter (no sidecar) reached scout in plain text" 000 outpost drifter drifter http://scout.starfleet/
expect_code "drifter (no sidecar) reached probe in plain text" 000 outpost drifter drifter http://probe.starfleet/get
# shuttle has a sidecar and probe has no policy, so this must stay open.
expect_code "shuttle cannot reach probe over mTLS" 200 starfleet shuttle shuttle http://probe.starfleet/get

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet refuses plain text and keeps serving mesh clients"
fi
exit "$fail"
