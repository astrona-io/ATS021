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
# Every pod of the Deployment labelled app=<name> must carry the Linkerd proxy.
require_meshed() {
  local app="$1" pod_names pod containers
  pod_names="$(kubectl -n starfleet get pods -l "app=$app" --field-selector=status.phase=Running -o 'jsonpath={.items[*].metadata.name}')"
  [ -n "$pod_names" ] || fail "No running pod for app=$app"
  for pod in $pod_names; do
    containers="$(kubectl -n starfleet get pod "$pod" -o 'jsonpath={.spec.containers[*].name} {.spec.initContainers[*].name}')"
    [[ "$containers" == *linkerd-proxy* ]] || fail "$pod (app=$app) must have a Linkerd proxy; annotate the namespace and restart the Deployment"
  done
}
