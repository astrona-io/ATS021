#!/usr/bin/env bash
# Shared live-state helpers. Sourced by the grading scripts.
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }
field() { kubectl -n starfleet get "$1" "$2" -o "jsonpath=$3"; }
expect_field() {
  local actual
  actual="$(field "$1" "$2" "$3")" || fail "Cannot read $1/$2"
  [ "$actual" = "$4" ] || fail "$1/$2 $3 must be $4; got $actual"
}
http_code() {
  kubectl -n "$1" exec "deploy/$2" -c "$2" -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$3" 2>/dev/null || true
}
expect_code() {
  local namespace="$1" client="$2" url="$3" expected="$4" actual="" attempt
  for attempt in $(seq 1 10); do
    actual="$(http_code "$namespace" "$client" "$url")"
    [ "$actual" != "$expected" ] || return 0
    sleep 3
  done
  fail "$client to $url: expected $expected; got ${actual:-no response}"
}
require_meshed_shuttle() {
  local containers
  containers="$(kubectl -n starfleet get pods -l app=shuttle -o 'jsonpath={.items[*].spec.containers[*].name} {.items[*].spec.initContainers[*].name}')"
  [[ "$containers" == *linkerd-proxy* ]] || fail 'shuttle must have a Linkerd proxy'
}
