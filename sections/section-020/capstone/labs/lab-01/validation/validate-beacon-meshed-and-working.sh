#!/usr/bin/env bash
# Check: beacon has a sidecar and keeps working under STRICT. Its pods must have
# the istio-proxy container, and a GET from beacon to scout returns 200.
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

for _ in $(seq 1 20); do
  proxies="$(kubectl -n starfleet get pods -l app=beacon --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.metadata.deletionTimestamp}{"|"}{.spec.initContainers[*].name}{"\n"}{end}' 2>/dev/null || true)"
  active="$(printf '%s\n' "$proxies" | grep -c '^|' || true)"
  with_proxy="$(printf '%s\n' "$proxies" | grep -c '^|.*istio-proxy' || true)"
  if [ "$active" -ge 1 ] && [ "$active" -eq "$with_proxy" ]; then
    break
  fi
  sleep 3
done
if [ "$active" -lt 1 ] || [ "$active" -ne "$with_proxy" ]; then
  echo "FAIL: beacon has no running pod, or a running pod without the istio-proxy sidecar"
  fail=1
fi
expect_code "beacon GET to scout" 200 starfleet beacon beacon http://scout.starfleet/

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon has a sidecar and reaches scout"
fi
exit "$fail"
